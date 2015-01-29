/**
 * directive for addition of a datatable visualization widget which communicates with the datatable tool in Weave
 */
weave_mod.directive('data-Table', ['queryService', 'WeaveService',  function(queryService, WeaveService){
	
	var directiveDefnObject = {
			
			restrict : 'EA', 
			templateUrl : 'src/visualization/tools/dataTable/data_table.tpl.html',
			scope : {
				
			},
			
			controller : function(){
				$scope.queryService = queryService;
				$scope.WeaveService = WeaveService;
				
				$scope.toolName = "";
				
				$scope.toolProperties = {
					enabled : false,
					columns : []
				};
				
			},
			
			link : function(scope, elem, attrs){
				
			}
	};
	
	return directiveDefnObject;
}]);