/**
 * directive for addition of a Scatter plot visualization widget which communicates with the Scatter Plot tool in Weave 
 */

weave_mod.directive('scatter-Plot', ['queryService', 'WeaveService', function(queryService, WeaveService){
	
	var directiveDefnObject = {
			restrict : 'EA',
			scope : {
				
			},
			templateUrl : 'src/visualization/tools/scatterPlot/scatter_plot.tpl.html',
			
			controller : function($scope, queryService, WeaveService){

				$scope.queryService = queryService;
				$scope.WeaveService = WeaveService;
				$scope.toolName = "";
				
				$scope.toolProperties = {
					enabled : false,
					title : false,
					X : "",
					Y : ""
				};
			},
			
			link : function(scope, elem, attrs){
				
			}
	};
	
	return directiveDefnObject;
}]);