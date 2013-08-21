/**
 * DataDialog Module DataDialogCtrl - Controls dialog button and closure.
 * DataDialogConnectCtrl - Manages the content of the Dialog.
 */
angular.module('aws.DataDialog', [ 'aws' ]).controller(
		'DataDialogCtrl',
		function($scope, $dialog) {

			$scope.opts = {
				backdrop : true,
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

.controller('DataDialogConnectCtrl', function($scope, queryobj, dialog) {
	$scope.close = function() {
		dialog.close();
	};
	
	
	$scope.dataTableSelect = queryobj['dataTable'];
	

	$scope.$watch('dataTableSelect', function(connection){
		queryobj['dataTable'] = $scope.dataTableSelect;
	});
	$scope.$watch('entityOverride', function(newVal, oldVal){
		if(newVal != undefined){
			$scope.dataTableSelect = $scope.entityOverride;
		}
	});
	
});