/**
 * directive for addition of a Barchart visualization widget which communicates with the BarChart tool in Weave
 */
weave_mod.directive('bar-Chart', ['queryService', function factory(queryService, WeaveService){
	
	var directiveDefnObj= {
			restrict: 'EA',
			scope : {
				
					
			},
			templateUrl: 'src/visualization/tools/barChart/bar_chart.tpl.html',
			controller : function($scope, queryService, WeaveService){
				
				$scope.queryService = queryService;
				$scope.WeaveService = WeaveService;
				
				$scope.toolName = "";
				
				$scope.toolProperties = {
					enabled : false,
					title : "",
					showAllLabels : false,
					sort : "",
					label : "",
					negErr : "",
					posErr :"",
					heights: ""
				};
			},
			link: function(scope, elem, attrs){
								
			}//end of link function
	};
	
	return directiveDefnObj;
}]);