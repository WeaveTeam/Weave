AnalysisModule.controller("MapCtrl", function($scope, queryService, WeaveService){
	
	$scope.service = queryService;
	$scope.WeaveService = WeaveService;
	
	queryService.getGeometryDataColumnsEntities(true);
	
	$scope.toolProperties = {
		toolName : WeaveService.generateUniqueName("MapTool"),
		enable : false,
		geometryLayer : {},
		title : "",
		useKeyTypeForCSV : "true",
		labelLayer : ""
	};
	
	console.log($scope.toolProperties.toolName);
	
	$scope.$watch( 'toolProperties', function(){
		queryService.queryObject[$scope.toolProperties.toolName] = $scope.toolProperties;
		WeaveService.MapTool($scope.toolProperties);
	}, true);
	
});