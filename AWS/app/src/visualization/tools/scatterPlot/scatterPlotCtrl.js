/**
 * controls the scatter plot visualization tool  widget
 */

AnalysisModule.controller("ScatterPlotCtrl", function($scope,  AnalysisService, WeaveService) {

	$scope.WeaveService = WeaveService;

	$scope.$watch('tool', function() {
		if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
			WeaveService.ScatterPlotTool($scope.tool, $scope.toolId);
	}, true);
});