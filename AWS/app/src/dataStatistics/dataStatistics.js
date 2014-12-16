/**
 * controllers and service for the 'Data' tab
 */

var dataStatsModule = angular.module('aws.dataStatistics', []);

dataStatsModule.value('pearsonCoeff', {label:"Pearson's Coefficent", scriptName : "getCorrelationMatrix.R"});
dataStatsModule.value('spearmanCoeff', {label : "Spearman's Coefficient", scriptName:"getSpearmanCoefficient.R"});

//************************SERVICE
dataStatsModule.service('statisticsService', ['queryService', 'QueryHandlerService','computationServiceURL', function(queryService, QueryHandlerService, computationServiceURL ){
	
	var that = this;
	
	//cache object that will contain all diff analytic statistics
	this.cache= {
			summaryStats : [],
			correlationMatrix : [],
			//displays the sparkline per column
			sparklineData :{
				breaks:[],//bins
				conuts:[]//frequency in each bin
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
									case 'SummaryStatistics'://TODO make string constants for all of these
										that.cache.summaryStats = resultData;
										break;
									case 'CorrelationMatrix':
										that.cache.correlationMatrix = resultData;
										break;
									case 'Sparklines':
										that.cache.sparklineData = resultData;
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
		 													  scriptManagementURL){
	
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
	$scope.statisticsService.calculateStats("getStatistics.R", queryService.cache.numericalColumns,"SummaryStatistics", true);
	
	//calculating sparkline breaks and counts
	//$scope.statisticsService.calculateStats('getSparklines.R', queryService.cache.numericalColumns, "Sparklines", true);
	
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
	//sets dataprovider of the summary stats grid
	var setData = function(data){
		$scope.statsData = data;
	};
	
	//convenience function to get column titles
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
		//constructSparklines();
	});
	
});