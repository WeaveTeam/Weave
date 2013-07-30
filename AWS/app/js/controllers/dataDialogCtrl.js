/**
 * DataDialog Module DataDialogCtrl - Controls dialog button and closure.
 * DataDialogConnectCtrl - Manages the content of the Dialog.
 */
angular.module('aws.DataDialog', [ 'aws' ]).controller(
		'DataDialogCtrl',
		function($scope, queryobj, $dialog) {
			$scope.connection;
			
			
			if(queryobj['conn']){
				$scope.connection = queryobj['conn'];
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
	
	/*$scope.$watch(function(){
			return queryobj['conn']; 
		}, 
		function(connection){
			$scope.conn = queryobj['conn'];
	});*/
	
	$scope.$watch('conn', function(connection){
		queryobj['conn'] = $scope.conn;
	});
	$scope.$watch('entityOverride', function(oldVal, newVal){
		if(newVal != undefined){
			$scope.conn.dataTable = $scope.entityOverride;
		}
	});
	
	
//	$scope.$watch('conn', function() {
//		queryobj['conn'] = conn;
//	});
});