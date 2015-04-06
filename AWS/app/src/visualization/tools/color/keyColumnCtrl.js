AnalysisModule.controller("keyColumnCtrl", function($scope, WeaveService){

	$scope.WeaveService = WeaveService;

	$scope.$watch('tool', function() {
		if($scope.toolId) {
			WeaveService.keyColumn($scope.tool);
		}// this gets triggered twice, the second time toolId with a undefined value.
	}, true);
	
});