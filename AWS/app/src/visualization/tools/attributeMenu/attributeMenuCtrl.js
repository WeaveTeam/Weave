/**
 * controls the attribute menu visualization tool  widget
 */

AnalysisModule.controller("AttributeMenuCtrl", function($scope, WeaveService){

	$scope.WeaveService = WeaveService;
	$scope.$watch('tool', function() {
		if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
			WeaveService.AttributeMenuTool($scope.tool, $scope.toolId);
	}, true);
});