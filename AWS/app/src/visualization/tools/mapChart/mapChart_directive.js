/**
 * directive for addition of a MapTool visualization widget which communicates with the Map tool in Weave
 * 
 */

weave_mod.directive('map-Chart', ['queryService', 'WeaveService', function(queryService, WeaveService){
	
	var directiveDefnObject = {
			
			restrict : 'EA',
			scope : {
				
			}, 
			templateUrl : 'src/visualization/tools/map_chart.tpl.html', 
			controller : function($scope, queryService, WeaveService){
				
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
				
			}, 
			
			link : function(scope, elem, attrs){
				
			}
	};
	
	return directiveDefnObject;
	
}]);