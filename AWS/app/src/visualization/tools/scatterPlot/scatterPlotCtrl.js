AnalysisModule.controller("ScatterPlotCtrl", function($scope,  AnalysisService, queryService, WeaveService) {


	$scope.service = queryService;
	$scope.WeaveService = WeaveService;
	$scope.AnalysisService = AnalysisService;
	
	$scope.toolName = "";
	
	$scope.toolProperties = {
		enabled : false,
		title : false,
		X : "",
		Y : "",
	};
	
	$scope.$watch("$parent.$index", function() {
		if($scope.$parent.$index) {
			$scope.AnalysisService.weaveTools[$scope.$parent.$index].id = $scope.toolName;
		}
	});
	
	$scope.$watch('toolName', function(newVal, oldVal) {
		if(newVal != oldVal) {
			if(!newVal) {
				delete queryService.queryObject[oldVal];
			} else {
				$scope.AnalysisService.weaveTools[$scope.$parent.$index].id = $scope.toolName;
			}
		}
	});
	
	$scope.$watch('AnalysisService.weaveTools[$parent.$index].id', function() {
		if($scope.AnalysisService.weaveTools[$scope.$parent.$index].id) {
			$scope.toolName = $scope.AnalysisService.weaveTools[$scope.$parent.$index].id;
		}
	});
	
	$scope.$watch( 'toolProperties', function(){
		
		$scope.toolName = WeaveService.ScatterPlotTool($scope.toolProperties, $scope.toolName);
		
		if($scope.toolName)	{
			queryService.queryObject[$scope.toolName] = $scope.toolProperties;
		}
		
		$scope.$watch(function() {
			return queryService.queryObject[$scope.toolName];
		}, function(newVal, oldVal) {
			if(queryService.queryObject[$scope.toolName])
			{
				$scope.toolProperties = queryService.queryObject[$scope.toolName];
			}
		});
	}, true);
	
	
});