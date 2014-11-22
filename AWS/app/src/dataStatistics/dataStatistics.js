/**
 * controllers and service for the 'Data' tab
 */

var dataStatsModule = angular.module('aws.dataStatistics', []);

//************************SERVICE
dataStatsModule.service('statisticsService', ['queryService', 'QueryHandlerService','computationServiceURL', function(queryService, QueryHandlerService, computationServiceURL ){
	
	this.dataObject= {};
	this.dataObject.calculatedStats = [];
	
	this.calculateStats = function(numericalColumns, forceUpdate){
		
		
		var statsInputs = QueryHandlerService.handleScriptOptions(numericalColumns);//will return int[] ids
		if(statsInputs){
			//hack fix this
			statsInputs[0].names.push('columndata');
			statsInputs[0].type = 'DataColumnMatrix';
			//getting the data
			QueryHandlerService.getDataFromServer(statsInputs, null).then(function(success){
				
				//executing the stats script
				if(success){
					QueryHandlerService.runScript("getStatistics").then(function(resultData){
						if(resultData){
							//display in grid
						}
					});
				}
					
			});
		}
			
			
	};
	
  
}]);


//********************CONTROLLERS
dataStatsModule.controller('dataStatsCtrl', function($scope, queryService, statisticsService){
	$scope.queryService = queryService;
	$scope.statisticsService = statisticsService;
	
	//this is the table selected for which its columns and their respective data statistics will be shown
	$scope.datatableSelected = queryService.queryObject.dataTable.title;
//	if($scope.datatableSelected || angular.isUndefined($scope.datatableSelected)|| $scope.datatableSelected == null)
//		$scope.datatableSelected = "Select a data table in the Analysis tab";
//
	
	$scope.$watch('datatableSelected', function(){
		if($scope.datatableSelected)
			{
				console.log(queryService.cache.numericalColumns);
				if(queryService.cache.numericalColumns.length > 0)
					statisticsService.calculateStats(queryService.cache.numericalColumns, true);
			}
	});
	
	$scope.statsData = [];//the array that gets populated by the Column statistics
	//defines the main grid that displays descriptive column statistics
	$scope.statsGrid = { 
	        data: 'statsData',
	        enableRowSelection: true,
	        enableCellEdit: true,
	        columnDefs: [{field:'columnName', displayName:'Column', enableCellEdit: false},
	                     {field:'columnMin', displayName:'Minimum', enableCellEdit: false}, 
	                     {field:'columnMax', displayName:'Maximum', enableCellEdit: false},
	                     {field:'columnMean', displayName:'Mean', enableCellEdit: false},
	                     {field:'columnVar', displayName:'Variance', enableCellEdit: false},
	                     {field:'columnMissing', displayName:'MssingValues', enableCellEdit: false}],
	        multiSelect : false
	 };
});
