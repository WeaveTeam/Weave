AnalysisModule.controller("BarChartCtrl", function($scope, queryService, WeaveService){

	$scope.queryService = queryService;
	$scope.WeaveService = WeaveService;
	
	$scope.toolName = "";
	
	$scope.toolProperties = {
		enabled : false,
		title : "",
		showAllLabels : false,
		sort : "",
		label : "",
		negErr : "",
		posErr :"",
		heights: ""
	};
	
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
	
	$scope.$watch( 'toolProperties', function(){
		$scope.toolName = WeaveService.BarChartTool($scope.toolProperties, $scope.toolName);
		
		if($scope.toolName)	{
			queryService.queryObject[$scope.toolName] = $scope.toolProperties;
		}
		
	}, true);
});