analysis_mod.controller("RunQueryCtrl", function($scope, queryService) {

	$scope.runQuery = function() {
		queryHandler = new aws.QueryHandler(queryService.queryObject);
		
		// doesn't work to remove weave instance -> $scope.weaveInstancePanel = "";
		// Probably need to put a broadcast event here? to tell weave instance panel to die.
		queryHandler.runQuery();
	};

	$scope.updateVisualizations = function() {
		if (queryHandler) {
			queryHandler.updateVisualizations(queryService.queryObject);
		}
	};

	$scope.clearSessionState = function() {
		if (queryHandler != undefined) {
			queryHandler.clearSessionState();
		}
	};
	
//	$scope.saveVisualization = function(){
//		queryService.getSessionState();
//	};
});
analysis_mod.controller('DialogController', function ($scope, $dialog) {
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

analysis_mod.controller("QueryImportExportCtrl", function($scope, queryService) {

	$scope.exportQueryObject = function() {
		var blob = new Blob([JSON.stringify(queryService.queryObject, undefined, 2)], {
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