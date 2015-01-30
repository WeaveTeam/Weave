AnalysisModule.controller("ColorCtrl", function($scope, queryService, WeaveService){

	$scope.WeaveService = WeaveService;

	$scope.$watch('tool', function() {
		if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
			WeaveService.ColorColumn($scope.tool);
	}, true);
	
	//monitors the key column
});