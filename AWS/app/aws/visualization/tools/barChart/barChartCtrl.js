AnalysisModule.controller("BarChartCtrl", function($scope, queryService, WeaveService){

	$scope.service = queryService;
	$scope.WeaveService = WeaveService;
	
	$scope.$watch(function() {
		return queryService.queryObject.BarChartTool;
	}, function (newVal, oldVal) { 
		if(newVal != oldVal) {
			WeaveService.BarChartTool(newVal);
		}
	}, true);

});