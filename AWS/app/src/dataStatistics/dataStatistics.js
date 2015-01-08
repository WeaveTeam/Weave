/**
 * controllers and service for the 'Data Stats' tab and its nested tabs
 */
//TODO create submodules corresponding to every nested tab
//Module definition
var dataStatsModule = angular.module('aws.dataStatistics', []);

//*******************************Value recipes********************************************
//Correlation coefficients
dataStatsModule.value('pearsonCoeff', {label:"Pearson's Coefficent", scriptName : "getCorrelationMatrix.R"});
dataStatsModule.value('spearmanCoeff', {label : "Spearman's Coefficient", scriptName:"getSpearmanCoefficient.R"});

//value recipes to be used in result handling of non-query statistics
//Summary statistics for each numerical data columns
dataStatsModule.value('summaryStatistics', 'SummaryStatistics');

//correlation Matrices computed using different algorithms
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
			tempSparklineData:{},//sparkline data received from server BEFORE being processed 
			sparklineData :{ breaks: [], counts: {}},
			columnTitles:[]//column titles of the current table being analyzed
	};
	
	/**
	 * convenience function to get column titles
	 * @param column objects 
	 * @returns an array of respective titles
	 */
	this.getColumnTitles = function(columns){
		
		for(var t=0; t < columns.length; t++){
			this.cache.columnTitles[t] = columns[t].title;
		}
		
		//return columnTitles;
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
										that.cache.tempSparklineData = resultData;
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
	
	$scope.$watch('dataTableSelected', function(){
		//$scope.$broadcast;
	});
	
});

//this controller is for the Summary Stats  nested tab
dataStatsModule.controller('summaryStatsController', function($q, $scope, 
		 													  queryService, statisticsService, runQueryService, d3Service,
		 													  scriptManagementURL, summaryStatistics){
	
	$scope.queryService = queryService;
	$scope.statisticsService = statisticsService;
	$scope.columnDefinitions = [];//populates the stats grid
	
	$scope.loop = [1,4];
	
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
	$scope.columnTitles = $scope.statisticsService.getColumnTitles($scope.queryService.cache.numericalColumns);
	//getting the metadata which specifies the stats to be displayed
	getStatsMetadata("getStatistics.R");
	
	//calculating stats
	//$scope.statisticsService.calculateStats("getStatistics.R", queryService.cache.numericalColumns, summaryStatistics, true);
	
	//calculating sparkline breaks and counts
	$scope.statisticsService.calculateStats('getSparklines2.R', queryService.cache.numericalColumns, "Sparklines", true);
	
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
	 * @param metadata script metadata for the stats script
	 */
	var constructSummaryStatsGrid = function(resultData, metadata){
		if(resultData){
			var data = [];
			//getting column titles
			var columnTitles = $scope.columnTitles;
			
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
	
	//sets dataprovider of the summary stats data grid
	var setData = function(data){
		$scope.statsData = data;
	};
	
	/**
	 * this function creates the sparklines for each column using breaks and counts.
	 * @param resultData: distribution information used for constructing sparklines
	 * uses the d3 library 
	 */
	var constructSparklines = function(resultData){
		//pre process the sparkline data
		var sparklineData= {breaks:[], counts:{}};
		sparklineData.breaks  = resultData[0][0];//breaks are same for all columns needed only once
		for(var x =0; x < resultData.length; x++){
			sparklineData.counts[$scope.statisticsService.cache.columnTitles[x]] = resultData[x][1];//TODO get rid of hard code
		}
		
		//$scope.statisticsService.cache.sparklineData will be used as the data provider for drawing the sparkline directives
		$scope.statisticsService.cache.sparklineData = sparklineData;
	};
	
	/*******************************************************SCOPE watches***********************************************/
	//watch for construction of the STATS DATAGRID
	$scope.$watch(function(){
		return $scope.statisticsService.cache.summaryStats;
	}, function(){
		if($scope.statisticsService.cache.summaryStats.resultData &&  $scope.queryService.cache.numericalColumns &&statsInputMetadata.inputs){
			constructSummaryStatsGrid($scope.statisticsService.cache.summaryStats.resultData,
					  				  statsInputMetadata.inputs);
		}
	});
	
	//watch for construction of the SPARKLINES
	$scope.$watch(function(){
		return $scope.statisticsService.cache.tempSparklineData;
	}, function(){
		if($scope.statisticsService.cache.tempSparklineData.resultData && $scope.queryService.cache.numericalColumns){
			constructSparklines($scope.statisticsService.cache.tempSparklineData.resultData);
		}
	});
	
	
});