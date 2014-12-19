/**
 * controllers and service for the 'Data Stats' tab and its nested tabs
 */
//Module definition
var dataStatsModule = angular.module('aws.dataStatistics', []);

//*******************************Value recipes********************************************
//Correlation coefficients
dataStatsModule.value('pearsonCoeff', {label:"Pearson's Coefficent", scriptName : "getCorrelationMatrix.R"});
dataStatsModule.value('spearmanCoeff', {label : "Spearman's Coefficient", scriptName:"getSpearmanCoefficient.R"});

//value recipes to be used in result handling of non-query statistics
//Summary statistics for each numerical data columns
dataStatsModule.value('summaryStatistics', 'SummaryStatistics');

//correlation Matrices computed using diff
dataStatsModule.value('correlationMatrix', 'CorrelationMatrix');

//sparklines data i.e. bins and counts in each bin
dataStatsModule.value('sparklines', 'Sparklines');

//************************SERVICE***********************************************************
dataStatsModule.service('statisticsService', ['queryService', 'QueryHandlerService','computationServiceURL',
                                              'summaryStatistics','correlationMatrix', 'sparklines',
                                              function(queryService, QueryHandlerService, computationServiceURL, 
                                              summaryStatistics, correlationMatrix, sparklines ){
	
	var that = this;
	
	//cache object that will contain all diff analytic statistics
	this.cache= {
			summaryStats : [],
			correlationMatrix : [],
			sparklineData :{
				breaks:[],
				conuts:[]
			}
	};

	this.calculateStats = function(scriptName, numericalColumns, statToCalculate, forceUpdate){
		
		if(!forceUpdate){
			return this.cache.summaryStats;
		}
		var statsInputs = QueryHandlerService.handleScriptOptions(numericalColumns);//will return int[] ids
		if(statsInputs){
			//hack fix this
			statsInputs[0].name = statToCalculate;
			statsInputs[0].type = "DATACOLUMNMATRIX";
			//getting the data
			queryService.getDataFromServer(statsInputs, null).then(function(success){
				
				//executing the stats script
				if(success){
					queryService.runScript(scriptName).then(function(resultData){
						if(resultData){
							//handling different kinds of non -query results returned from R
							for(var x = 0; x < statsInputs.length; x++){
								
								switch (statToCalculate)
								{
									case summaryStatistics:
										that.cache.summaryStats = resultData;
										break;
									case correlationMatrix:
										that.cache.correlationMatrix = resultData;
										break;
									case sparklines:
										that.cache.sparklineData = resultData;
										console.log("sparklines", that.cache.sparklineData);
										break;
								}
									
								
							}//end of loop for statsinputs
						}
					});
				}
			});
		}
	};
	
  
}]);


//********************CONTROLLERS***************************************************************
dataStatsModule.controller('dataStatsCtrl', function($q, $scope, queryService){
	//this is the table selected for which its columns and their respective data statistics will be shown
	$scope.datatableSelected = queryService.queryObject.dataTable.title;
});

//this controller is for the Summary Stats  nested tab
dataStatsModule.controller('summaryStatsController', function($q, $scope, 
		 													  queryService, statisticsService, runQueryService, 
		 													  scriptManagementURL, summaryStatistics){
	
	$scope.queryService = queryService;
	$scope.statisticsService = statisticsService;
	$scope.columnDefinitions = [];//populates the stats grid
	
	var statsInputMetadata;

	//wrote this in the controller so that even if user edits stats metadata on the fly, no need to refresh application
	var getStatsMetadata = function(statsScript){
		var deferred = $q.defer();
		
		runQueryService.queryRequest(scriptManagementURL, 'getScriptMetadata', [statsScript], function(result){
			statsInputMetadata = result;
			$scope.$safeApply(function() {
				deferred.resolve(statsInputMetadata);
			});
		});
		
	};
	//**************************************************function calls**********************************************
	//getting the metadata which specifies the stats to be displayed
	getStatsMetadata("getStatistics.R");
	
	//calculating stats
	$scope.statisticsService.calculateStats("getStatistics.R", queryService.cache.numericalColumns, summaryStatistics, true);
	
	//calculating sparkline breaks and counts
	//$scope.statisticsService.calculateStats('getSparklines2.R', queryService.cache.numericalColumns, "Sparklines", true);
	
	//**************************************************function calls end**********************************************
	
	
	$scope.statsData = [];//the array that gets populated by the Column statistics
	//defines the main grid that displays descriptive column statistics
	$scope.statsGrid = { 
	        data: 'statsData',
	        enableRowSelection: true,
	        enableCellEdit: true,
	        columnDefs: 'columnDefinitions',
	        multiSelect : false
	 };
	
	//this function populates the Summary statistics grid
	/**
	 * @param resultData summary statistics of the numerical columns
	 * @param columns column ids of the numerical columns
	 * @param metadata script metadata for the stats script
	 */
	var constructSummaryStatsGrid = function(resultData, columns, metadata){
		if(resultData){
			var data = [];
			//getting column titles
			var columnTitles = getColumnTitles(columns);
			
			for(var x = 0; x < resultData.length; x++){// x number of numerical columns
				
				var oneStatsGridObject = {};
				for(var y = 0; y < metadata.length; y++){//x number of metadata objects
					
					if(metadata[y].param == 'ColumnName'){//since the dataprovider for this entry is different i.e. columnTitles
						oneStatsGridObject[metadata[y].param] = columnTitles[x];
						continue;
					}
					
					oneStatsGridObject[metadata[y].param] = resultData[x][y-1];
				}
				
				data.push(oneStatsGridObject);
				
				//during the last iteration TODO confirm if this is the right place for the loop
				//console.log(x);
				if(x == (resultData.length - 1)){
					$scope.columnDefitions = [];
					for(var z = 0; z < metadata.length; z++){
						
						$scope.columnDefinitions.push({
							field: metadata[z].param,
							displayName : metadata[z].param,
							enableCellEdit:false
						});
					}
					
				}
			}
			
			setData(data);
		}
	};
	
	/**
	 * this function creates the 
	 */
	var constructSparklines = function(){
		
	};
	
	
	
	//sets dataprovider of the summary stats grid
	var setData = function(data){
		$scope.statsData = data;
	};
	
	/**
	 * convenience function to get column titles
	 * @param column objects 
	 * @returns an array of respective titles
	 */
	var getColumnTitles = function(columns){
		var columnTitles = [];
		
		for(var t=0; t < columns.length; t++){
			columnTitles[t] = columns[t].title;
		}
		
		return columnTitles;
	};
	
	/*******************************************************SCOPE watches***********************************************/
	//watch for construction of the STATS DATAGRID
	$scope.$watch(function(){
		return $scope.statisticsService.cache.summaryStats;
	}, function(){
		if($scope.statisticsService.cache.summaryStats.resultData &&  $scope.queryService.cache.numericalColumns &&statsInputMetadata.inputs){
			constructSummaryStatsGrid($scope.statisticsService.cache.summaryStats.resultData,
					  				  $scope.queryService.cache.numericalColumns,
					  				  statsInputMetadata.inputs);
		}
	});
	
	//watch for construction of the SPARKLINES
	$scope.$watch(function(){
		return $scope.statisticsService.cache.sparklineData;
	}, function(){
		constructSparklines();
	});
	
});