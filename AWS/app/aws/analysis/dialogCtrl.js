AnalysisModule.controller('DialogController', function ($scope, $modal, queryService) {
	$scope.projectEntered2 = "Hello";
	$scope.opts = {
		 backdrop: false,
          backdropClick: true,
          dialogFade: true,
          keyboard: true,
          templateUrl: 'aws/analysis/myModalContent.html',
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
    	console.log("checking", params);
    		
    	});
    };
    
  })
 .controller('DialogInstanceCtrl', function ($scope, $modalInstance, projectEntered, queryTitleEntered) {
	  $scope.close = function (projectEntered, queryTitleEntered) {
		  console.log("checking2", projectEntered, queryTitleEntered);
		  var params = {
				  projectEntered : projectEntered,
				  queryTitleEntered : queryTitleEntered
		  };
		  $modalInstance.close(params);
    };
});
