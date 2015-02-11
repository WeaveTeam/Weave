/**
 * directive for addition of a Barchart visualization widget which communicates with the BarChart tool in Weave
 */
weave_mod.directive('bar-Chart', ['queryService', function factory(queryService, WeaveService){
	
	var directiveDefnObj= {
			restrict: 'EA',
			scope : {
				
					
			},
			templateUrl: 'src/visualization/tools/barChart/bar_chart.tpl.html',
			controller : function($scope, WeaveService){
				
				$scope.WeaveService = WeaveService;
				
				$scope.$watch('tool', function() {
					if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
						WeaveService.BarChartTool($scope.tool, $scope.toolId);
				}, true);
			},
			link: function(scope, elem, attrs){
								
			}//end of link function
	};
	
	return directiveDefnObj;
}]);