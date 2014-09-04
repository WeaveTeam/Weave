AnalysisModule.controller('DialogController', function ($scope, $dialog, queryService) {
	$scope.opts = {
		 backdrop: false,
          backdropClick: true,
          dialogFade: true,
          keyboard: true,
          templateUrl: 'aws/analysis/myModalContent.html',
          controller: 'DialogInstanceCtrl',
          resolve:
          {
                      projectEntered: function() {return angular.copy(projectEntered);},
                      queryTitleEntered : function(){return angular.copy(queryTitleEntered);}
          }
	};

    $scope.saveVisualizations = function (projectEntered, queryTitleEntered) {
      var d = $dialog.dialog($scope.opts);
      d.open().then(function(params){//the then funcion takes only single object as param
    	  if(params){
    		  console.log("finally got project as ", params.projectEntered);
    		  console.log("qo", params.queryTitleEntered);
    		  queryService.getSessionState(params);
    	  }
      });
      
      
    };
  })
  .controller('DialogInstanceCtrl', function ($scope, dialog, projectEntered, queryTitleEntered) {
	  $scope.close = function (projectEntered, queryTitleEntered) {
		  var params = {
				  projectEntered : projectEntered,
				  queryTitleEntered : queryTitleEntered
		  };
      dialog.close(params);
    };
  });
