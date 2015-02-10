/**
 * QueryImportExportCtrl. This controller manages query import and exports.
 */
var QueryObject = angular.module("aws.queryObject", []);

QueryObject.controller("QueryImportExportCtrl", function($scope, queryService, WeaveService) {
	
	//structure for file upload
	$scope.queryObjectUploaded = {
			file : {
				content : "",
				filename : ""
			}
	};

	//Handles the download of a query object
	$scope.exportQuery = function() {
		if(WeaveService.weave)
		{
			queryService.queryObject.sessionState = WeaveService.weave.path().getState();
		}
		
		var blob = new Blob([ angular.toJson(queryService.queryObject, true) ], {
			type : "text/plain;charset=utf-8"
		});
		saveAs(blob, "QueryObject.json");//TODO add a dialog to allow saving file name
	};
	
	//chunk of code that runs when a QO is imported
	$scope.$watch('queryObjectUploaded.file', function(n, o) {
		if($scope.queryObjectUploaded.file.content)
		{
			queryService.queryObject = angular.fromJson($scope.queryObjectUploaded.file.content);
			if(WeaveService.weave)
			{
				WeaveService.weave.path().state(queryService.queryObject.sessionState);
				delete queryService.queryObject.sessionState;
			}
		}
    }, true);
});