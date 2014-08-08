AnalysisModule.controller("BarChartCtrl", function($scope, queryService, WeaveService){

	$scope.service = queryService;
	
	$scope.setTitle = WeaveService.BarChartTool.setTitle;
	$scope.setHeights = WeaveService.BarChartTool.setHeightColumns;
	$scope.setSort = WeaveService.BarChartTool.setSortColumn;
	$scope.setLabel = WeaveService.BarChartTool.setLabelColumn;

});