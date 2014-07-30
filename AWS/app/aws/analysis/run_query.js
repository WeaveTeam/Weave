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
analysis_mod.controller('ModalDemoCtrl', [ '$scope', '$modal', '$log', function ($scope, $modal, $log) {
    $scope.items = ['item1', 'item2', 'item3'];
    console.log("reached the modal controller", $modal);
    $scope.open = function () {
      var modalInstance = $modal.open({
        templateUrl: 'aws/analysis/myModalContent.html',
        controller: 'ModalInstanceCtrl',
        resolve: {
          items: function () {
            return $scope.items;
          }
        }
      });
    
//      modalInstance.result.then(function (selectedItem) {
//        $scope.selected = selectedItem;
//      }, function () {
//        $log.info('Modal dismissed at: ' + new Date());
//      });
    };
  }])
  .controller('ModalInstanceCtrl', [ '$scope', '$modalInstance', 'items', function ($scope, $modalInstance, items) {
    $scope.items = items;
    $scope.selected = {
      item: $scope.items[0]
    };
  
    $scope.ok = function () {
      $modalInstance.close($scope.selected.item);
    };
  
    $scope.cancel = function () {
      $modalInstance.dismiss('cancel');
    };
  }]);
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