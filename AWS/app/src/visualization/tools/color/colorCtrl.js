AnalysisModule.controller("ColorCtrl", function($scope, queryService, WeaveService){

	$scope.service = queryService;
	$scope.WeaveService = WeaveService;
	
	//monitors the color column
	$scope.$watch(function(){
		return queryService.queryObject.ColorColumn;
	}, function(){
		WeaveService.ColorColumn(queryService.queryObject.ColorColumn);
	}, true);
	
	//monitors the key column
	$scope.$watch(function(){
		return queryService.queryObject.keyColumn;
	}, function(){
		WeaveService.keyColumnName(queryService.queryObject.keyColumn);
	}, true);
});