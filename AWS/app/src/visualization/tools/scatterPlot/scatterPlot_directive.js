/**
 * directive for addition of a Scatter plot visualization widget which communicates with the Scatter Plot tool in Weave 
 */
var blah;
weave_mod.directive('scatter-Plot', ['WeaveService', function(WeaveService){
	
	var directiveDefnObject = {
			restrict : 'EA',
			scope : {
				
			},
			templateUrl : 'src/visualization/tools/scatterPlot/scatter_plot.tpl.html',
			
			controller : function($scope, WeaveService){

				$scope.WeaveService = WeaveService;

				$scope.$watch('tool', function() {
					if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
						WeaveService.ScatterPlotTool($scope.tool, $scope.toolId);
				}, true);
			},
			
			link : function(scope, elem, attrs){
				
			}
	};
	
	return directiveDefnObject;
}]);