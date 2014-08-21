/**
 * This service handles the running of scripts and handling their results
 * acts as a wrapper on the client side that handles requests and responses of scripts
 */
var computationURL = '/WeaveAnalystServices/ComputationalServlet';

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
			var scriptInputs = {};
			var columns = [];
			for(var key in inputParams)
				{	//handling the data
				
						var input = inputParams[key].param_user_value;
						switch(typeof input)
						{
							case  'object' :
								for (var x in input){
									var column = JSON.parse(input[x]);
									scriptInputs[column.title] = {
											id : column.id
									};
								}
							break;	
							case 'string' :
								if(inputParams[key].param_type == 'number')
									scriptInputs[inputParams[key].param_name] = parseFloat(input);
								else
									scriptInputs[inputParams[key].param_name] = input;
							break;
						}
				
				}
			
			var deferred = $q.defer();
			aws.queryService(computationURL, 'runScript', [scriptName, scriptInputs, null], function(result){
				
				console.log("script result returned", result);
				
				
				scope.$safeApply(function() {
					deferred.resolve(result);
				});
			});
		}
		
	};
	
	
	
	
}]);
