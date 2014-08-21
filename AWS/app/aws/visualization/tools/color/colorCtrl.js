AnalysisModule.controller("ColorCtrl", function($scope, queryService, WeaveService){

	console.log("reached color controller");
	$scope.service = queryService;
	$scope.WeaveService = WeaveService;
	
	$scope.$watch(function(){
		return queryService.queryObject.ColorColumn;
	}, function(){
		WeaveService.ColorColumn(queryService.queryObject.ColorColumn);
	}, true);
	
	$scope.$watch(function(){
		return queryService.queryObject.keyColumn;
	}, function(){
		WeaveService.keyColumnName(queryService.queryObject.keyColumn);
	}, true);
});