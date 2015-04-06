AnalysisModule.controller("ColorCtrl", function($scope, WeaveService){

	$scope.WeaveService = WeaveService;

	$scope.$watch('tool', function() {
		if($scope.toolId) {
			WeaveService.ColorColumn($scope.tool);
		}// this gets triggered twice, the second time toolId with a undefined value.
			
	}, true);
	
});