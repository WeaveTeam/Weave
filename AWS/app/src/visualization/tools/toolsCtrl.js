AnalysisModule.controller("toolsCtrl", function($scope, queryService, WeaveService, AnalysisService){
	
	$scope.queryService = queryService;
	$scope.WeaveService = WeaveService;
	$scope.AnalysisService = AnalysisService;
	
	$scope.removeTool = function(index) {
		WeaveService.weave.path(AnalysisService.weaveTools[index].id).remove();
		delete queryService.queryObject[AnalysisService.weaveTools[index].id];
		AnalysisService.weaveTools.splice(index, 1);
	};

});