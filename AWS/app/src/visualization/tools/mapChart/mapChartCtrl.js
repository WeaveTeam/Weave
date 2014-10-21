AnalysisModule.controller("MapCtrl", function($scope, queryService, WeaveService){
	
	$scope.service = queryService;
	$scope.WeaveService = WeaveService;
	
	queryService.getGeometryDataColumnsEntities(true);
	
	$scope.$watch(function(){
		return queryService.queryObject.MapTool;
	}, function(){
		WeaveService.MapTool(queryService.queryObject.MapTool);
	}, true);
	
});