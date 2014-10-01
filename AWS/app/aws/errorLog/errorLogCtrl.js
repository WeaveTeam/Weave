/**
 * controller for the error log that is universal to all tabs
 * Also includes the service for logging errors
 */

var errorLogModule = angular.module('aws.errorLog', []);

errorLogModule.controller('analystErrorLogCtrl', function($scope, $modal, errorLogService){
	$scope.errorLogService = errorLogService;
	$scope.openErrorLog = function(){
		$modal.open($scope.errorLogService.errorLogModalOptions);
	};
});

errorLogModule.controller('errorLogInstanceCtrl', function($rootScope, $scope, $modalInstance, errorLogService){
	$scope.logs = errorLogService.logs;
	
	$scope.close = function () {
		 $modalInstance.close();
	 };
});


errorLogModule.service('errorLogService',[function(){
	
	this.errorLogModalOptions = {//TODO find out how to push error log to bottom of page
			 backdrop: true,
	         backdropClick: true,
	         dialogFade: true,
	         keyboard: true,
	         templateUrl: 'aws/errorLog/analystErrorLog.html',
	         controller: 'errorLogInstanceCtrl',
	         windowClass : 'erroLog-modal'
		};
	
	this.logs = "";
	/**
	 *this is the function that will be used over all tabs to log errors to the error log
	 *@param the string you want to log to the error log
	 */
	this.logInErrorLog = function(error){
		this.logs= this.logs.concat("\n" + error + new Date().toLocaleTimeString());
	};
	
}]);
