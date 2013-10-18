/**
 * DataDialog Module DataDialogCtrl - Controls dialog button and closure.
 * DataDialogConnectCtrl - Manages the content of the Dialog.
 */
angular.module('aws.DataDialog', []).controller('DataDialogCtrl', function($scope, $dialog, queryService) {

    queryService.getDataTableList().then(function(result) {
    	console.log("this executes");
    	queryService.queryObject.dataTable = angular.fromJson(result[0]);
    });
    
    $scope.dataTable = queryService.queryObject.dataTable;
    
    $scope.$watch(function() {
    	return queryService.queryObject.dataTable;
    }, function() {
    	$scope.dataTable = queryService.queryObject.dataTable; 
    });
    	
    $scope.opts = {
		backdrop : false,
		keyboard : true,
		backdropClick : true,
		templateUrl : 'tpls/dataDialog.tpls.html',
		controller : 'DataDialogConnectCtrl'
	};

	$scope.openDialog = function(partial) {
		if (partial) {
			$scope.opts.templateUrl = 'tpls/' + partial + '.tpls.html';
		}
		var d = $dialog.dialog($scope.opts);
		d.open();
	};
})

.controller('DataDialogConnectCtrl', function($scope, queryService, dialog) {
	$scope.close = function() {
		dialog.close();
	};

	$scope.dataTableList = queryService.getDataTableList();
	
	$scope.$watch(function() {
		return $scope.dataTable;
	}, 
	function() {
		queryService.queryObject.dataTable = angular.fromJson($scope.dataTable);
	});
});