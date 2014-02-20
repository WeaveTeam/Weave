/**
 * Left Panel Module LeftPanelCtrl - Manages the model for the left panel.
 */
angular.module("aws.leftPanel", []).controller("LeftPanelCtrl",
		function($scope, $location, queryService, $q) {
			
			$scope.isActive = function(route) {
				return route == $location.path();
			};
			
			$scope.queryObject = angular.toJson(queryService.queryObject, true);

			
			$scope.$watch(function () {
				return queryService.queryObject;
			},function() {
				$scope.queryObject = angular.toJson(queryService.queryObject, true);
			}, true);
			
			$scope.$watch(function() { return $scope.queryObject; }, function() {
				queryService.queryObject = angular.fromJson($scope.queryObject);
			}, true);
			
			$scope.shouldShow = false;
				var setCount = function(res) {
				$scope.shouldShow = res;
			};
			aws.addBusyListener(setCount);

		});

/**
 * QueryImportExportCtrl. This controller manages query import and exports.
 */
angular.module("aws.QueryImportExport", []).controller("QueryImportExportCtrl", function($scope, queryService) {
			

			$scope.exportQueryObject = function() {
				var blob = new Blob([ JSON.stringify(queryService.queryObject, undefined, 2) ], {
					type : "text/plain;charset=utf-8"
				});
				saveAs(blob, "QueryObject.json");
			};
			
			$scope.importQueryObject = function() {
			};
			
			$scope.$on('newQueryLoaded', function(e) {
                $scope.$safeApply(function() {
                  queryService.queryObject = e.targetScope.jsonText;
                });
			});
});


function saveJSON(query) {
	var blob = new Blob([ JSON.stringify(query, undefined, 2) ], {
		type : "text/plain;charset=utf-8"
	});
	saveAs(blob, "QueryObject.json");
}
