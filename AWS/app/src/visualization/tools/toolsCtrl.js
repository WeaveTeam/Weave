AnalysisModule.controller("toolsCtrl", function($scope, queryService, WeaveService, AnalysisService){
	
	$scope.queryService = queryService;
	$scope.WeaveService = WeaveService;
	$scope.AnalysisService = AnalysisService;
	
	$scope.removeTool = function(index) {
		WeaveService.weave.path(queryService.queryObject.weaveToolsList[index].id).remove();
		delete queryService.queryObject[queryService.queryObject.weaveToolsList[index].id];
		queryService.queryObject.weaveToolsList.splice(index, 1);
	};

});