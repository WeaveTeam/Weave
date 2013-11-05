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
                     if ($scope.queryObject) {
                                queryService.queryObject = $scope.queryObject;
                     }
                });
			});
});