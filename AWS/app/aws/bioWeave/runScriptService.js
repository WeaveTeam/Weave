/**
 * 
 */
var pythonURL = '/WeaveAnalystServices/ComputationalServlet';

angular.module('aws.BioWeave', [])
.service("runScriptService",  ['$q', '$rootScope', function($q, scope){
	
	var that = this;
	
	this.runScript = function(){
		aws.queryService(pythonURL, 'runScript', null, function(result){
			that.data.check = result;
        
			scope.$safeApply(function() {
				deferred.resolve(result);
			});
		
		});
	};
	
}]);