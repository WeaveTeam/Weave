analysis_mod.controller("RunQueryCtrl", function($scope, queryService) {

	$scope.runQuery = function() {
		queryHandler = new aws.QueryHandler(queryService.queryObject);

		// doesn't work to remove weave instance -> $scope.weaveInstancePanel = "";
		// Probably need to put a broadcast event here? to tell weave instance panel to die.
		queryHandler.runQuery();
	};

	$scope.updateVisualizations = function() {
		if (queryHandler) {
			queryHandler.updateVisualizations(queryService.queryObject);
		}
	};

	$scope.clearWeave = function() {
		if (queryHandler != undefined) {
			queryHandler.clearSessionState();
		}
	};
});

analysis_mod.controller("ColorColumnCtrl", function($scope, queryService) {

	queryService.queryObject.ColorColumn = {
		enabled : false,
		selected : ""
	};

	$scope.options = [];

	$scope.$watch(function() {
		return queryService.dataObject.scriptMetadata;
	}, function() {
		if (queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			$scope.options = [];
			if (queryService.dataObject.scriptMetadata.hasOwnProperty("outputs")) {
				var outputs = queryService.dataObject.scriptMetadata.outputs;
				for (var i = 0; i < outputs.length; i++) {
					$scope.options.push(outputs[i].param);
				}
			}
		}
	});

	/*** double binding *****/
	$scope.$watch('enabled', function() {
		if ($scope.enabled != undefined) {
			queryService.queryObject.ColorColumn.enabled = $scope.enabled;
		}
	});

	$scope.$watch(function() {
		return queryService.queryObject.ColorColumn.enabled;
	}, function() {
		$scope.enabled = queryService.queryObject.ColorColumn.enabled;
	});

	$scope.$watch('selected', function() {
		if ($scope.selected != undefined) {
			queryService.queryObject.ColorColumn.enabled = true;
			queryService.queryObject.ColorColumn.selected = $scope.selected;
		}

	});

	$scope.$watch(function() {
		return queryService.queryObject.ColorColumn.selected;
	}, function() {
		$scope.selected = queryService.queryObject.ColorColumn.selected;
	});

});

analysis_mod.controller("QueryImportExportCtrl", function($scope, queryService) {

	$scope.exportQueryObject = function() {
		var blob = new Blob([JSON.stringify(queryService.queryObject, undefined, 2)], {
			type : "text/plain;charset=utf-8"
		});
		saveAs(blob, "QueryObject.json");
	};

	$scope.importQueryObject = function() {
	};

	$scope.$on('fileUploaded', function(e) {
		$scope.$safeApply(function() {
			queryService.queryObject = e.targetScope.file;
		});
	});

});


function saveJSON(query) {
	var blob = new Blob([ JSON.stringify(query, undefined, 2) ], {
		type : "text/plain;charset=utf-8"
	});
	saveAs(blob, "QueryObject.json");
}