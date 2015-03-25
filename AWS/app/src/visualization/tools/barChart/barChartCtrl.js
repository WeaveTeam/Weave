/**
 * controls the bar chart visualization tool widget
 */

AnalysisModule.controller("BarChartCtrl", function($scope, WeaveService){

	$scope.WeaveService = WeaveService;
	$scope.$watch('tool', function() {
		if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
			WeaveService.BarChartTool($scope.tool, $scope.toolId);
	}, true);
});