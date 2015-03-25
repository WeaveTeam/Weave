/**
 * controls the map visualization tool widget
 */

AnalysisModule.controller("MapCtrl", function($scope,$filter, queryService, WeaveService){
	
	$scope.service = queryService;
	
	$scope.service.getGeometryDataColumnsEntities(true);
	
	$scope.tool.zoomLevel = 0;

	//geometry layers
	$scope.getGeometryLayers = function(term, done) {
		var values = $scope.service.cache.geometryColumns;
		done($filter('filter')(values, {title:term}, 'title'));
	};
	
	$scope.$watch('tool', function() {
		//console.log("map ctrl");
		if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
			WeaveService.MapTool($scope.tool, $scope.toolId);
	}, true);
	
});