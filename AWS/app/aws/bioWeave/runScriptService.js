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
		
		//processing the objects to send only what is required
		for(var r in algorithmObjects)
		{
			var scriptName = scriptNames[r];
			var inputParams = algorithmObjects[r].inputParams;
			var ids = [];
			var params = [];
				
			for(var t in inputParams)
				{
					if(inputParams[t].param_name == 'input_data' ){
						ids = inputParams[t].param_user_value;
						for(var o in ids){
							var id  = angular.fromJson(ids[o]).id;
							ids[o] = id;
						}
					}
					
					else{
						params.push(inputParams[t].param_user_value);
					}
						
					
				}
			
			
			var deferred = $q.defer();
			aws.queryService(computationServiceURL, 'runScript', [scriptName, ids, params], function(result){
				
				console.log("script result returned", result);
				
				
				scope.$safeApply(function() {
					deferred.resolve(result);
				});
			});
		}
		
	};
	
	
	
	
}]);
