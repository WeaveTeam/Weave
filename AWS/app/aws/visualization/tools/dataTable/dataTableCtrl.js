analysis_mod.controller("DataTableCtrl", function($scope, queryService) {

	queryService.queryObject.DataTableTool = {
		enhabled : false,
		selected : []

	};

	$scope.options = [];

	$scope.$watch(function() {
		return queryService.dataObject.scriptMetadata;
	}, function() {
		$scope.options = [];
		if (queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			if (queryService.dataObject.scriptMetadata.hasOwnProperty("outputs")) {
				var outputs = queryService.dataObject.scriptMetadata.outputs;
				for (var i = 0; i < outputs.length; i++) {
					$scope.options.push(outputs[i].param);
				}
			}
		}
	});
	
	if(queryService.queryObject.Indicator.label) {
		$scope.title = "Data Table of " + queryService.queryObject.scriptSelected.split(".")[0] + " for " +  queryService.queryObject.Indicator.label;
		$scope.enableTitle = true;
	}
	
	$scope.$watch('enabled', function() {
		if ($scope.enabled != undefined) {
			queryService.queryObject.DataTableTool.enabled = $scope.enabled;
		}
	});

	$scope.$watch(function() {
		return queryService.queryObject.DataTableTool.enabled;
	}, function() {
		$scope.enabled = queryService.queryObject.DataTableTool.enabled;
	});

	$scope.$watch('selected', function() {
		if ($scope.selected != undefined) {
			queryService.queryObject.DataTableTool.selected = $scope.selected;
		}

	});

	$scope.$watch(function() {
		return queryService.queryObject.DataTableTool.selected;
	}, function() {
		$scope.selected = queryService.queryObject.DataTableTool.selected;
	});

}); 