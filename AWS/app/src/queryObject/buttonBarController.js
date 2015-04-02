/**
 * buttonBarController. This controller manages query import and exports.
 */
var QueryObject = angular.module("aws.queryObject", []);

QueryObject.controller("buttonBarController", function($scope, $modal, queryService, WeaveService, QueryHandlerService) {
	
	$scope.queryService = queryService;
	$scope.QueryHandlerService = QueryHandlerService;
	
	//structure for file upload
	$scope.queryObjectUploaded = {
			file : {
				content : "",
				filename : ""
			}
	};
	
	//options for the dialog for saving output visuals
	$scope.opts = {
			 backdrop: false,
	          backdropClick: true,
	          dialogFade: true,
	          keyboard: true,
	          templateUrl: 'src/analysis/savingOutputsModal.html',
	          controller: 'DialogInstanceCtrl',
	          resolve:
	          {
	                      projectEntered: function() {return $scope.projectEntered;},
	                      queryTitleEntered : function(){return $scope.queryTitleEntered;},
	                      userName : function(){return $scope.userName;}
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
	
	//clears the session state
	$scope.clearSessionState = function(){
		WeaveService.clearSessionState();
	};
	
	
    $scope.saveVisualizations = function (projectEntered, queryTitleEntered, userName) {
    	
    	var saveQueryObjectInstance = $modal.open($scope.opts);
    	saveQueryObjectInstance.result.then(function(params){//this takes only a single object
    	//console.log("params", params);
    		queryService.getBase64SessionState(params);
    		
    	});
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

QueryObject.controller('DialogInstanceCtrl', function ($scope, $modalInstance, projectEntered, queryTitleEntered, userName) {
	  $scope.close = function (projectEntered, queryTitleEntered, userName) {
		  var params = {
				  projectEntered : projectEntered,
				  queryTitleEntered : queryTitleEntered,
				  userName :userName
		  };
		  $modalInstance.close(params);
};
});
