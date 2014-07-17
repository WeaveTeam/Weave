analysis_mod.controller("MapCtrl", function($scope, queryService){
	
	$scope.service = queryService;
	
	queryService.getGeometryDataColumnsEntities(true);
});