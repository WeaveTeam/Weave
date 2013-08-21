/**
 * Left Panel Module LeftPanelCtrl - Manages the model for the left panel.
 */
angular.module("aws.leftPanel", []).controller("LeftPanelCtrl",
		function($scope, $location, queryobj, $q) {
			$scope.isActive = function(route) {
				return route == $location.path();
			};
			$scope.uploadQuery = function() {

			};
			$scope.$on('newQueryLoaded', function(e) {
				$scope.$safeApply(function() {
					if ($scope.jsonText) {
						//queryobj = $scope.jsonText;
						queryobj.setQueryObject($scope.jsonText);
					}
				});
			});

			// Show logic for the Busy Indicator
			$scope.shouldShow = false;
			var setCount = function(res) {
				$scope.shouldShow = res;
			};
			aws.addBusyListener(setCount);

		});

function saveJSON(query) {
	var blob = new Blob([ JSON.stringify(query, undefined, 2) ], {
		type : "text/plain;charset=utf-8"
	});
	saveAs(blob, "Query Object.txt");
}
