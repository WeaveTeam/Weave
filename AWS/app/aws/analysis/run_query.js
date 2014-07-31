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
          resolve:{projectEntered :function() {return angular.copy(projectEntered);}}
	};
	
    $scope.saveVisualizations = function (projectEntered) {
      var d = $dialog.dialog($scope.opts);
      d.open().then(function(projectEntered){
    	  if(projectEntered){
    		  console.log("finally got project as ", projectEntered);
    	  }
      });
      
      
    };
  })
  .controller('DialogInstanceCtrl', function ($scope, dialog, projectEntered) {
	  $scope.close = function (projectEntered) {
      dialog.close(projectEntered);
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