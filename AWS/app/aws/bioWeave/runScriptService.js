/**
 * 
 */
var scriptManagementURL = '/WeaveAnalystServices/ScriptManagementServlet';
angular.module('aws.bioWeave')
.service("runScriptService",  ['$q', '$rootScope', function($q, scope){
	
	var that = this;
	this.data = {};
	this.data.chosenAlgorithms = [];//represents the list of algorithms in the algorithm cart, Algorithms which will be executed
	
	/**
     * This function wraps the async aws getListOfAlgoObjects function into an angular defer/promise
     * gets the list of algorithm objects from the aws-config/Algorithms
     */
	
	this.getListOfAlgoObjects = function(){
		var deferred = $q.defer();
		aws.queryService(scriptManagementURL, 'getListOfAlgoObjects', null, function(result){
			that.data.listOfAlgoObjects = result;
			
			console.log("got algoobject list", that.data.listOfAlgoObjects);
	        
				scope.$safeApply(function() {
					deferred.resolve(result);
				});
			
			});
	};
	
	this.getAlgorithmMetadata = function(algoName){
		console.log("getting metadata for", algoName);
		var deferred = $q.defer();
		aws.queryService(scriptManagementURL, 'getAlgorithmMetadata', [algoName], function(result){
			that.data.algorithmMetadataObjects = result;
			
			console.log("got algoobject list", that.data.listOfAlgoObjects);
			
			scope.$safeApply(function() {
				deferred.resolve(result);
			});
			
		});
		
	};
	
	/**
	 * This function adds algorithms to the algorithm cart
     */
	this.add_algorithmObject = function(id) {
		if($.inArray(id, this.data.chosenAlgorithms) == -1)//add only if not added previously
		{
			this.data.chosenAlgorithms.push(id);
	
		}
		else
			alert(id + " has already been added");
		console.log("chosen", this.data.chosenAlgorithms);
	};
		
	/**
	 * This function removes algorithms from the algorithm cart
     */
	this.remove_algorithmObject = function(id){
		this.data.chosenAlgorithms.splice($.inArray(id, this.data.chosenAlgorithms), 1);//TODO find faster way of doing this (see slight lag)
		console.log("updated", this.data.chosenAlgorithms);
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