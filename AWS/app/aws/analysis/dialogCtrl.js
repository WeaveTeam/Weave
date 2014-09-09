AnalysisModule.controller('DialogController', function ($scope, $modal, queryService) {
	$scope.opts = {
		 backdrop: false,
          backdropClick: true,
          dialogFade: true,
          keyboard: true,
          templateUrl: 'aws/analysis/myModalContent.html',
          controller: 'DialogInstanceCtrl',
          resolve:
          {
                     // projectEntered: function() {return angular.copy(projectEntered);},
                     // queryTitleEntered : function(){return angular.copy(queryTitleEntered);}
          }
	};

    $scope.saveVisualizations = function (projectEntered, queryTitleEntered) {
    	
    	$modal.open($scope.opts).then(function(params) {
    	  if(params){
    		  console.log("finally got project as ", params.projectEntered);
    		  console.log("qo", params.queryTitleEntered);
    		  queryService.getSessionState(params);
    	  }
      });
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
