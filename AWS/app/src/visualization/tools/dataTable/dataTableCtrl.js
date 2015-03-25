/**
 * controls the datatable visualization tool  widget
 */

AnalysisModule.controller("DataTableCtrl", function($scope, WeaveService) {

	$scope.WeaveService = WeaveService;

	$scope.$watch('tool', function() {
		if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
			WeaveService.DataTableTool($scope.tool, $scope.toolId);
	}, true);
}); 