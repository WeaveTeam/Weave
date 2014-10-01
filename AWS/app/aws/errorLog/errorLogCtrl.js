/**
 * controller for the error log that is universal to all tabs
 * Also includes the service for logging errors
 */

var errorLogModule = angular.module('aws.errorLog', []);

errorLogModule.controller('analystErrorLogCtrl', function($scope, errorLogService){
	$scope.errorLogService = errorLogService;
});

errorLogModule.service('errorLogService',[function(){
	
	this.logs = "";
	this.showErrorLog = false;

	/**
	 *this is the function that will be used over all tabs to log errors to the error log
	 *@param the string you want to log to the error log
	 */
	this.logInErrorLog = function(error){
		this.logs += error + "\n" + this.logs;
	};
	
}]);
