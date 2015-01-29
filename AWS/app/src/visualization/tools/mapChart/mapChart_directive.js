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
				
				$scope.queryService = queryService;
				$scope.WeaveService = WeaveService;
				$scope.toolName = "";
				
				$scope.toolProperties = {
						enabled : false,
						geometryLayer : {},
						title : "",
						useKeyTypeForCSV : true,
						labelLayer : ""
				};
				
				$scope.queryService.getGeometryDataColumnsEntities(true);
				
			}, 
			
			link : function(scope, elem, attrs){
				
			}
	};
	
	return directiveDefnObject;
	
}]);