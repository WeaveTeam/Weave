analysis_mod.controller("BarChartCtrl", function($scope, queryService){

	if(queryService.queryObject.Indicator.label) {
		$scope.title = "Bar Chart of " + queryService.queryObject.scriptSelected.split(".")[0] + " for " +  queryService.queryObject.Indicator.label;
		$scope.enableTitle = true;
	}
	
	$scope.options = [];
	
	$scope.$watch(function(){
		return queryService.dataObject.scriptMetadata;
	}, function() {
		$scope.options = [];
		if(queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			if(queryService.dataObject.scriptMetadata.hasOwnProperty("outputs")) {
				var outputs = queryService.dataObject.scriptMetadata.outputs;
				for( var i = 0; i < outputs.length; i++) {
					$scope.options.push(outputs[i].param);
				}
			}
		}
	});		
	
	if(queryService.queryObject.Indicator.label) {
		$scope.title = "Bar Chart of " + queryService.queryObject.scriptSelected.split(".")[0] + " for " +  queryService.queryObject.Indicator.label;
		$scope.enableTitle = true;
	}
	
	$scope.$watch('enabled', function() {
		if($scope.enabled != undefined) {
			queryService.queryObject.BarChartTool.enabled = $scope.enabled;
		}
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.BarChartTool.enabled;
	}, function() {
		$scope.enabled = queryService.queryObject.BarChartTool.enabled;
	});
	
	$scope.$watch('heights', function() {

		if($scope.heights != undefined) {
			queryService.queryObject.BarChartTool.heights = $scope.heights;
		}
		
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.BarChartTool.heights;
	}, function() {
		$scope.heights = queryService.queryObject.BarChartTool.heights;	
	});

	$scope.$watch(function(){
		return queryService.queryObject.BarChartTool.title;
	}, function() {
		$scope.title = queryService.queryObject.BarChartTool.title;
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.BarChartTool.enableTitle;
	}, function() {
		$scope.enableTitle = queryService.queryObject.BarChartTool.enableTitle;
	});
	
	$scope.$watch('sort', function() {
		if($scope.sort != undefined) {
			queryService.queryObject.BarChartTool.sort = $scope.sort;
		}
		
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.BarChartTool.sort;
	}, function() {
		$scope.sort = queryService.queryObject.BarChartTool.sort;	
	});
	
	$scope.$watch('label', function() {
		if($scope.label != undefined) {
			queryService.queryObject.BarChartTool.label = $scope.label;
		}
		
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.BarChartTool.label;
	}, function() {
		$scope.label = queryService.queryObject.BarChartTool.label;	
	});
	
	$scope.$watch('title', function() {
		if($scope.title != undefined) {
			queryService.queryObject.BarChartTool.title = $scope.title;
		}
	});
	
	$scope.$watch('enableTitle', function() {
		if($scope.enableTitle != undefined) {
			queryService.queryObject.BarChartTool.enableTitle = $scope.enableTitle;
		}
	});
	
});