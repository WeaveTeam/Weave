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
							console.log("stats", resultData);
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
dataStatsModule.controller('dataStatsCtrl', function($scope, queryService, statisticsService){
	$scope.queryService = queryService;
	$scope.statisticsService = statisticsService;
	
	//this is the table selected for which its columns and their respective data statistics will be shown
	$scope.datatableSelected = queryService.queryObject.dataTable.title;
	
	statisticsService.calculateStats(queryService.cache.numericalColumns, true);

	$scope.$watch(function(){
		console.log("$scope.statisticsService.dataObject.calculatedStats", $scope.statisticsService.dataObject.calculatedStats);
		return $scope.statisticsService.dataObject.calculatedStats;
	}, function(){
		if($scope.statisticsService.dataObject.calculatedStats.length > 0){
			var data = [];
			var oneStat = $scope.statisticsService.dataObject.calculatedStats[0];//hack
			for(var x = 0 ; x < oneStat.length; x++){//16
				var colName = $scope.statisticsService.dataObject.calculatedStats[0][x];//TODO handle hard coded part?//todo get these from script metadata(json)
				var colMax = $scope.statisticsService.dataObject.calculatedStats[1][x];
				var colMin = $scope.statisticsService.dataObject.calculatedStats[2][x];
				var colMean = $scope.statisticsService.dataObject.calculatedStats[3][x];
				var colVar = $scope.statisticsService.dataObject.calculatedStats[4][x];
				
				data.push({
					columnName : colName,
					columnMax : colMax,
					columnMin : colMin,
					columnMean : colMean,
					columnVar : colVar
					
				});
					
			}
			//console.log("data", data);
			setData(data);
		}
	});
	
	var setData = function(data){
		//console.log("returnedStats", data);
		$scope.statsData = data;
	};
	
	$scope.statsData = [];//the array that gets populated by the Column statistics
	//defines the main grid that displays descriptive column statistics
	$scope.statsGrid = { 
	        data: 'statsData',
	        enableRowSelection: true,
	        enableCellEdit: true,
	        columnDefs: [{field:'columnName', displayName:'Column', enableCellEdit: false},//todo get these from script metadata
	                     {field:'columnMax', displayName:'Maximum', enableCellEdit: false},
	                     {field:'columnMin', displayName:'Minimum', enableCellEdit: false}, 
	                     {field:'columnMean', displayName:'Mean', enableCellEdit: false},
	                     {field:'columnVar', displayName:'Variance', enableCellEdit: false}],
	        multiSelect : false
	 };
});
