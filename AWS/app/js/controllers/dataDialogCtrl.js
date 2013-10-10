/**
 * DataDialog Module DataDialogCtrl - Controls dialog button and closure.
 * DataDialogConnectCtrl - Manages the content of the Dialog.
 */
angular.module('aws.DataDialog', [ 'aws' ]).controller('DataDialogCtrl', function($scope, $dialog, queryobj, dataService) {

	$scope.opts = {
		backdrop : false,
		keyboard : true,
		backdropClick : true,
		templateUrl : 'tpls/dataDialog.tpls.html',
		controller : 'DataDialogConnectCtrl'
	};

	// sets the queryobject to be equal to the first data table by default... not sure if good choice
	 dataService.giveMeTables().then(function(result){
		 queryobj.dataTable = { id : result[0].id,
    			 title : result[0].title
    	};
    });
        
	$scope.$watch(function() {
		return queryobj.dataTable;
	}, function(oldVal, newVal) {
		$scope.dataTable = queryobj.dataTable;
	});
	
	$scope.openDialog = function(partial) {
		if (partial) {
			$scope.opts.templateUrl = 'tpls/' + partial + '.tpls.html';
		}

		var d = $dialog.dialog($scope.opts);
		d.open();
	};
})
.controller('DataDialogConnectCtrl', function($scope, queryobj, dialog, dataService) {
	
	$scope.close = function() {
		dialog.close();
	};
	
	$scope.options = dataService.giveMeTables();
		
	$scope.$watch('dataTableSelect', function(newVal, oldVal){
        	 queryobj.dataTable = angular.fromJson($scope.dataTableSelect);
	});
});