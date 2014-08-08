/**
 * This service handles the running of scripts and handling their results
 * acts as a wrapper on the client side that handles requests and responses of scripts
 */
var computationServiceURL = '/WeaveAnalystServices/ComputationalServlet';

angular.module('aws.bioWeave')
.service('runScriptService', ['$q', '$rootScope', function($q, scope){
	var that = this;
	this.data= {};
	
	/**
	 * this function takes a list of algorithm Objects and their respective scripts and runs them in their respective engines (R, Python, STATA etc)
	 */
	this.runScript = function(algorithmObjects, scriptNames){
		console.log("reached the runService", algorithmObjects, scriptNames);
	};
	
	
	
	
}]);
