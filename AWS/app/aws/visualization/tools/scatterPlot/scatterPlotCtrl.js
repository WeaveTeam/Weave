analysis_mod.controller("ScatterPlotCtrl", function($scope, queryService) {

	if(queryService.queryObject.Indicator.label) {
		$scope.title = "Scatter Plot of " + queryService.queryObject.scriptSelected.split(".")[0] + " for " +  queryService.queryObject.Indicator.label;
		$scope.enableTitle = true;
	}
	
	$scope.options = [];
	
	$scope.$watch(function(){
		return queryService.dataObject.scriptMetadata;
	}, function() {
		if(queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			$scope.options = [];
			if(queryService.dataObject.scriptMetadata.hasOwnProperty("outputs")) {
				var outputs = queryService.dataObject.scriptMetadata.outputs;
				for( var i = 0; i < outputs.length; i++) {
					$scope.options.push(outputs[i].param);
				}
			}
		}
	});

	
	$scope.$watch('enabled', function() {
		if($scope.enabled != undefined){
			queryService.queryObject.ScatterPlotTool.enabled = $scope.enabled;
		}
		
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.ScatterPlotTool.enabled;
	}, function() {
		$scope.enabled = queryService.queryObject.ScatterPlotTool.enabled;	
	});

	$scope.$watch(function(){
		return queryService.queryObject.ScatterPlotTool.X;
	}, function() {
		$scope.XSelection = queryService.queryObject.ScatterPlotTool.X;
	});

	$scope.$watch('title', function() {
		queryService.queryObject.ScatterPlotTool.title = $scope.title;
	});
	
	$scope.$watch('enableTitle', function() {
		queryService.queryObject.ScatterPlotTool.enableTitle = $scope.enableTitle;
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.ScatterPlotTool.title;
	}, function() {
		$scope.title = queryService.queryObject.ScatterPlotTool.title;
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.ScatterPlotTool.enableTitle;
	}, function() {
		$scope.enableTitle = queryService.queryObject.ScatterPlotTool.enableTitle;
	});
	
	$scope.$watch('XSelection', function() {
		if($scope.XSelection != undefined) {
			queryService.queryObject.ScatterPlotTool.X = $scope.XSelection;
		}
	});
	
	$scope.$watch(function(){
		return queryService.queryObject.ScatterPlotTool.Y;
	}, function() {
		$scope.YSelection = queryService.queryObject.ScatterPlotTool.Y;
	});

	$scope.$watch('YSelection', function() {
		if($scope.YSelection != undefined) {
			queryService.queryObject.ScatterPlotTool.Y = $scope.YSelection;
		}
	});
});