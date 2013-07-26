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
				templateUrl : 'tlps/dataDialog.tlps.html',
				controller : 'DataDialogConnectCtrl'
			};

			$scope.openDialog = function(partial) {
				if (partial) {
					$scope.opts.templateUrl = 'tlps/' + partial + '.tlps.html';
				}

				var d = $dialog.dialog($scope.opts);
				var a = aws.DataClient.getEntityChildIds(161213, function(
						result) {
					return result;
				});
				var list = aws.DataClient.getDataTableList(function(result) {
					// console.log(result);
					return result;
				});
				// console.log(list);
				d.open().then(list);

				$scope.dataTables = [];
				$scope.dataColumns = a;

			};
		})

.controller('DataDialogConnectCtrl', function($scope, $http, dialog) {
	$scope.close = function() {
		dialog.close();
	};
	$scope.conn = {
		connectionName : 'test',
		connectionPass : 'pass',
		serverType : 'MySQL',
		sqlip : '192.1.1.1',
		sqlport : '3388',
		sqldbname : 'test',
		sqluser : 'tester',
		sqlpass : 'test1'
	};
});