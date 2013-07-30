/**
 * DataDialog Module DataDialogCtrl - Controls dialog button and closure.
 * DataDialogConnectCtrl - Manages the content of the Dialog.
 */
angular.module('aws.DataDialog', [ 'aws' ]).controller(
		'DataDialogCtrl',
		function($scope, queryobj, $dialog) {
			$scope.connection;
			var defaults = {
				scriptLocation : 'C:\\RScripts\\',
				dataTable: 161213
				/*connectionName : 'demo',
				connectionPass : 'pass',
				serverType : 'MySQL',
				sqlip : 'localhost',
				sqlport : '3306',
				sqldbname : '',
				sqluser : 'root',
				sqlpass : 'pass'*/
			};
			
			if(queryobj['conn']){
				$scope.connection = queryobj['conn'];
			}else{
				queryobj['conn'] = defaults;
			}

			$scope.opts = {
				backdrop : true,
				keyboard : true,
				backdropClick : true,
				templateUrl : 'tpls/dataDialog.tpls.html',
				controller : 'DataDialogConnectCtrl',
				resolve : {
					conn : function() {
						return angular.copy($scope.conn);
					}
				}
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
	
	
	$scope.conn = queryobj['conn'];
	
	$scope.$watch(function(){
			return queryobj['conn']; 
		}, 
		function(connection){
			$scope.conn = queryobj['conn'];
	});
	
	$scope.$watch('conn', function(connection){
		queryobj['conn'] = $scope.conn;
	});
	$scope.$watch('entityOverride', function(){
		$scope.conn.dataTable = $scope.entityOverride;
	});
	
	
//	$scope.$watch('conn', function() {
//		queryobj['conn'] = conn;
//	});
});