/**
 * directive for addition of a datatable visualization widget which communicates with the datatable tool in Weave
 */
weave_mod.directive('data-Table', ['queryService', 'WeaveService',  function(WeaveService){
	
	var directiveDefnObject = {
			
			restrict : 'EA', 
			templateUrl : 'src/visualization/tools/dataTable/data_table.tpl.html',
			scope : {
				
			},
			
			controller : function(){
				$scope.WeaveService = WeaveService;
				
				$scope.$watch('tool', function() {
					if($scope.toolId) // this gets triggered twice, the second time toolId with a undefined value.
						WeaveService.DataTableTool($scope.tool, $scope.toolId);
				}, true);
			},
			
			link : function(scope, elem, attrs){
				
			}
	};
	
	return directiveDefnObject;
}]);