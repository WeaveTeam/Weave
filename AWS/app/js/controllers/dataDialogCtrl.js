/**
 * DataDialog Module DataDialogCtrl - Controls dialog button and closure.
 * DataDialogConnectCtrl - Manages the content of the Dialog.
 */
angular.module('aws.DataDialog', []).controller(
		'DataDialogCtrl',
		function($scope, $dialog, queryService) {

            $scope.dataTable = queryService.queryObject.dataTable;
			
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

	$scope.options = queryService.getDataTableList();
	
	$scope.dataTableSelect = queryService.queryObject.dataTable;
    
	/*************** two way binding *******************/
//	$scope.$watch(function() { return $scope.dataTableSelect}, function() {
//		queryService.queryObject.dataTable = $scope.dataTableSelect;
//	});
//	
//	$scope.$watch(function() {
//					return queryService.queryObject.datatable;
//				}, function() {
//					$scope.dataTableSelect = queryService.queryObject.datatable; 
//	});
	/****************************************************/
});