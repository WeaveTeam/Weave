AnalysisModule.controller("MapCtrl", function($scope, AnalysisService, queryService, WeaveService){
	
	$scope.service = queryService;
	
	queryService.getGeometryDataColumnsEntities(true);
	
	$scope.$watch('tool', function() {
		if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
			WeaveService.MapTool($scope.tool, $scope.toolId);
	}, true);
	
});