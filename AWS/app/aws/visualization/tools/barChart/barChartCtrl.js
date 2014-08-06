AnalysisModule.controller("BarChartCtrl", function($scope, queryService, WeaveService){

	$scope.service = queryService;
	
	$scope.setTitle = WeaveService.barChart.setTitle;
	$scope.setHeights = WeaveService.barChart.setHeights;
	$scope.setSort = WeaveService.barChart.setSort;
	$scope.setLabel = WeaveService.barChart.setLabel;

});