AnalysisModule.controller('DialogController', function ($scope, $modal, queryService, WeaveService) {
	$scope.projectEntered2 = "Hello";
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
                      queryTitleEntered : function(){return $scope.queryTitleEntered;}
          }
	};

    $scope.saveVisualizations = function (projectEntered, queryTitleEntered) {
    	
    	var saveQueryObjectInstance = $modal.open($scope.opts);
    	saveQueryObjectInstance.result.then(function(params){//this takes only a single object
    	//console.log("params", params);
    		queryService.getSessionState(params);
    		
    	});
    };
    
  //clears the session state
	$scope.clearSessionState = function(){
		WeaveService.clearSessionState();
	};
	
    
  })
 .controller('DialogInstanceCtrl', function ($scope, $modalInstance, projectEntered, queryTitleEntered) {
	  $scope.close = function (projectEntered, queryTitleEntered) {
		  var params = {
				  projectEntered : projectEntered,
				  queryTitleEntered : queryTitleEntered
		  };
		  $modalInstance.close(params);
    };
});
