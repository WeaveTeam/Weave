/**
 * QueryImportExportCtrl. This controller manages query import and exports.
 */
var QueryObject = angular.module("aws.queryObject", []);

QueryObject.controller("QueryImportExportCtrl", function($scope, queryService) {
			

			$scope.exportQueryObject = function() {
				var blob = new Blob([ JSON.stringify(queryService.queryObject, undefined, 2) ], {
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
