/**
 * QueryImportExportCtrl. This controller manages query import and exports.
 */
var QueryObject = angular.module("aws.queryObject", []);

QueryObject.controller("QueryImportExportCtrl", function($scope, queryService, $rootScope) {
			

			$scope.exportQuery = function() {
				var blob = new Blob([ angular.toJson(queryService.queryObject, true) ], {
					type : "text/plain;charset=utf-8"
				});
				saveAs(blob, "QueryObject.json");
			};
			$scope.queryObjectUploaded = {
					file : {
						content : "",
						filename : "",
					}
			};
			$scope.$watch('queryObjectUploaded.file', function(n, o) {
				if($scope.queryObjectUploaded.file.content)
				{
					queryService.queryObject = angular.fromJson($scope.queryObjectUploaded.file.content);
					$rootScope.$broadcast('queryUploaded');
				}
		    }, true);
});