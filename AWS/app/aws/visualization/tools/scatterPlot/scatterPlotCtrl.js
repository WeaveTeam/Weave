AnalysisModule.controller("ScatterPlotCtrl", function($scope, queryService, WeaveService) {
	$scope.service = queryService;
	$scope.WeaveService = WeaveService;
	
	$scope.$watch(function(){
		return queryService.queryObject.ScatterPlotTool;
	}, function(){
		WeaveService.ScatterPlotTool(queryService.queryObject.ScatterPlotTool);
	}, true);
});