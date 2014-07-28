/**
 * 
 */
var scriptManagementURL = '/WeaveAnalystServices/ScriptManagementServlet';
angular.module('aws.BioWeave', [])
.service("runScriptService",  ['$q', '$rootScope', function($q, scope){
	
	var that = this;
	this.data = {};
	
	this.getListOfAlgoObjects = function(){
		aws.queryService(scriptManagementURL, 'getListOfAlgoObjects', null, function(result){
			that.data.listOfAlgoObjects = result;
			
			console.log("got object list", that.data.listOfAlgoObjects);
	        
				scope.$safeApply(function() {
					deferred.resolve(result);
				});
			
			});
		};
	
//	this.runScript = function(){
//		aws.queryService(pythonURL, 'runScript', null, function(result){
//			that.data.check = result;
//        
//			scope.$safeApply(function() {
//				deferred.resolve(result);
//			});
//		
//		});
//	};
	
}]);