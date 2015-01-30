AnalysisModule.controller("MapCtrl", function($scope,$filter, AnalysisService, queryService, WeaveService){
	
	$scope.service = queryService;
	
	$scope.service.getGeometryDataColumnsEntities(true);
	
	
	//select2-sortable handlers
	$scope.getItemId = function(item) {
		return item.id;
	};
	
	$scope.getItemText = function(item) {
		return item.title;
	};
	
	//geometry layers
	$scope.getGeometryLayers = function(term, done) {
		var values = $scope.service.cache.geometryColumns;
		done($filter('filter')(values, {title:term}, 'title'));
	};
	
	$scope.$watch('tool', function() {
		if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
			WeaveService.MapTool($scope.tool, $scope.toolId);
	}, true);
	
});