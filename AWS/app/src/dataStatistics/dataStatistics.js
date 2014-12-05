/**
 * controllers and service for the 'Data' tab
 */

var dataStatsModule = angular.module('aws.dataStatistics', []);

//************************SERVICE
dataStatsModule.service('statisticsService', ['queryService', 'QueryHandlerService','computationServiceURL', function(queryService, QueryHandlerService, computationServiceURL ){
	
	this.dataObject= {};
	var that = this;
	this.dataObject.calculatedStats = [];
	
	this.calculateStats = function(numericalColumns, forceUpdate){
		
		if(!forceUpdate){
			return this.dataObject.calculatedStats;
		}
		var statsInputs = QueryHandlerService.handleScriptOptions(numericalColumns);//will return int[] ids
		if(statsInputs){
			//hack fix this
			statsInputs[0].names = [];
			statsInputs[0].names.push('columndata');
			statsInputs[0].type = 'DataColumnMatrix';
			//getting the data
			QueryHandlerService.getDataFromServer(statsInputs, null).then(function(success){
				
				//executing the stats script
				if(success){
					QueryHandlerService.runScript("getStatistics.R").then(function(resultData){
						if(resultData){
							that.dataObject.calculatedStats = resultData;
						}
					});
				}
					
			});
		}
		return 	that.dataObject.calculatedStats;
			
	};
	
  
}]);


//********************CONTROLLERS
dataStatsModule.controller('dataStatsCtrl', function($q, $scope, queryService, statisticsService, runQueryService, scriptManagementURL){
	$scope.queryService = queryService;
	$scope.statisticsService = statisticsService;
	$scope.columnDefinitions = [];
	
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
	getStatsMetadata("getStatistics.R");
	
	//calculating stats
	statisticsService.calculateStats(queryService.cache.numericalColumns, true);
	

	//as soon as results are returned
	$scope.$watch(function(){
		return $scope.statisticsService.dataObject.calculatedStats;
	}, function(){
		if($scope.statisticsService.dataObject.calculatedStats.length > 0){
			var data = [];
			var oneStat = $scope.statisticsService.dataObject.calculatedStats[0];//hack
			
			for(var x = 0; x < oneStat.length; x++){
				
				var oneStatsGridObject = {};
				for(var y = 0; y < statsInputMetadata.inputs.length; y++){
					statsInputMetadata.inputs[y].value = $scope.statisticsService.dataObject.calculatedStats[y][x];
					
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
					
					console.log("columnDefs", $scope.columnDefs);
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
