AnalysisModule.controller("MapCtrl", function($scope, AnalysisService, queryService, WeaveService){
	
	$scope.service = queryService;
	$scope.WeaveService = WeaveService;
	$scope.AnalysisService = AnalysisService;
	
	queryService.getGeometryDataColumnsEntities(true);
	$scope.toolName = "";
	
	$scope.toolProperties = {
		enabled : false,
		geometryLayer : {},
		title : "",
		useKeyTypeForCSV : true,
		labelLayer : ""
	};
	
	// watches for toolName changes and update the weaveToolsList id
	// delete it from the queryobject if tool is deleted
	$scope.$watch('toolName', function(newVal, oldVal) {
		if(newVal != oldVal) {
			if(!newVal) {
				delete queryService.queryObject[oldVal];
			} else {
				$scope.service.queryObject.weaveToolsList[$scope.$parent.$index].id = $scope.toolName;
			}
		}
	});
	
	$scope.$watch('service.queryObject[service.queryObject.weaveToolsList[$parent.$index].id]', function() {
		if($scope.service.queryObject.weaveToolsList[$scope.$parent.$index].id) {
			$scope.toolName = $scope.service.queryObject.weaveToolsList[$scope.$parent.$index].id;
			$scope.toolProperties = queryService.queryObject[$scope.toolName];
		}
	}, true);
	
	$scope.$watch( 'toolProperties', function(newVal, oldVal){
		$scope.toolName = WeaveService.MapTool($scope.toolProperties, $scope.toolName);
		
		if($scope.toolName)	{
			queryService.queryObject[$scope.toolName] = $scope.toolProperties;
		}
	}, true);
});