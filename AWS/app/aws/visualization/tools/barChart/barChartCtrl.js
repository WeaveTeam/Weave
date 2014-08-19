AnalysisModule.controller("BarChartCtrl", function($scope, queryService, WeaveService){

	$scope.service = queryService;
	$scope.WeaveService = WeaveService;
	
	$scope.$watch(function() {
		return queryService.queryObject.BarChartTool;
	}, function () { 
			WeaveService.BarChartTool(queryService.queryObject.BarChartTool);
	}, true);
});