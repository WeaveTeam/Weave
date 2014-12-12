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
			correlationMatrix : []
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
									case 'SummaryStatistics':
										that.cache.summaryStats = resultData;
										break;
									case 'CorrelationMatrix':
										that.cache.correlationMatrix = resultData;
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


//********************CONTROLLERS
dataStatsModule.controller('dataStatsCtrl', function($q, $scope, 
													 queryService, statisticsService, runQueryService, 
													 scriptManagementURL){
	$scope.queryService = queryService;
	$scope.statisticsService = statisticsService;
	$scope.columnDefinitions = [];
	//todo getting correlation stats

	//this is the table selected for which its columns and their respective data statistics will be shown
	$scope.datatableSelected = queryService.queryObject.dataTable.title;
	
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
	//getting the metadata which specifies the stats to be displayed
	var statsInputMetadata;
	//getStatsMetadata("getStatistics.R");
	
	//calculating stats
	//statisticsService.calculateStats("getStatistics.R", queryService.cache.numericalColumns,"SummaryStatistics", true);
	

	//as soon as results are returned construction of the STATS DATAGRID
	$scope.$watch(function(){
		return $scope.statisticsService.cache.summaryStats;
	}, function(){
		if($scope.statisticsService.cache.summaryStats.length > 0){
			var data = [];
			var oneStat = $scope.statisticsService.cache.summaryStats[0];//hack
			
			for(var x = 0; x < oneStat.length; x++){
				
				var oneStatsGridObject = {};
				for(var y = 0; y < statsInputMetadata.inputs.length; y++){
					statsInputMetadata.inputs[y].value = $scope.statisticsService.cache.summaryStats[y][x];
					
					oneStatsGridObject[statsInputMetadata.inputs[y].param] = statsInputMetadata.inputs[y].value;
					
				}
				
				data.push(oneStatsGridObject);
				
				//during the last iteration TODO confirm if this is the right place for the loop
				console.log(x);
				if(x == (oneStat.length - 1)){
					$scope.columnDefitions = [];
					for(var z = 0; z < statsInputMetadata.inputs.length; z++){
						
						$scope.columnDefinitions.push({
							field: statsInputMetadata.inputs[z].param,
							displayName : statsInputMetadata.inputs[z].param,
							enableCellEdit:false
						});
					}
					
				}
			}
			
			setData(data);
		}
	});
	
	var setData = function(data){
		$scope.statsData = data;
	};
	
	$scope.statsData = [];//the array that gets populated by the Column statistics
	//defines the main grid that displays descriptive column statistics
	$scope.statsGrid = { 
	        data: 'statsData',
	        enableRowSelection: true,
	        enableCellEdit: true,
	        columnDefs: 'columnDefinitions',
	        multiSelect : false
	 };
});
