AnalysisModule.controller("DataTableCtrl", function($scope, queryService, WeaveService) {

	$scope.service = queryService;
	$scope.WeaveService = WeaveService;
	
	$scope.$watch(function(){
		return queryService.queryObject.DataTableTool;
	}, function(){
		WeaveService.DataTableTool(queryService.queryObject.DataTableTool);
	}, true);

}); 