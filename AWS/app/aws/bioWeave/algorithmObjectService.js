/**
 * 
 */
var scriptManagementURL = '/WeaveAnalystServices/ScriptManagementServlet';
angular.module('aws.bioWeave')
.service("algorithmObjectService",  ['$q', '$rootScope', 'runScriptService', function($q, scope, runScriptService){
	
	var that = this;
	this.data = {};
	this.data.chosenAlgorithms = [];//represents the list of algorithms in the algorithm cart, Algorithms which will be executed
	//will serve as a temp cache to store metadata objects before executing the algorithms, so that we dont have to make a server call everytime
	this.data.algorithmMetadataObjects= [];
	
	
	/**
     * This function wraps the async aws getListOfAlgoObjects function into an angular defer/promise
     * gets the list of algorithm objects from the aws-config/Algorithms
     */
	
	this.getListOfAlgoObjects = function(){
		var deferred = $q.defer();
		aws.queryService(scriptManagementURL, 'getListOfAlgoObjects', null, function(result){
			that.data.listOfAlgoObjects = result;
			//console.log("got algoobject list", that.data.listOfAlgoObjects);
				scope.$safeApply(function() {
					deferred.resolve(result);
				});
			
			});
	};
	
	
	/**
     * This function wraps the async aws getAlgorithmMetadata function into an angular defer/promise
     * the metadata object helps in dynamic building of the UI for entering every algorithm's parameters
     */
	this.getAlgorithmMetadata = function(algoName){
		var match = false;
		var matchedObject = {};
		if(this.data.algorithmMetadataObjects.length == 0)
			{
				this.getAlgorithmMetadataFromServer(algoName);
			}//first time cache is empty 
			
		if(this.data.algorithmMetadataObjects.length > 0)//checking in the cache
		{	
			for(var i in this.data.algorithmMetadataObjects)//loop over the titles and check for match
				{
					if(algoName.match(this.data.algorithmMetadataObjects[i].title))
						{
							match = true;
							matchedObject = this.data.algorithmMetadataObjects[i];
							break;
						}
				}
			
			if(match == true)
				{
					this.data.currentMetObj = matchedObject;
				}
			else
				{
					this.getAlgorithmMetadataFromServer(algoName);
				}
			
		}
			
		
	};
	
	
	this.getAlgorithmMetadataFromServer = function(algoName){
		var deferred = $q.defer();
		aws.queryService(scriptManagementURL, 'getAlgorithmMetadata', [algoName], function(result){
			//that.data.algorithmMetadataObjects = result;
			
			var algoMetadataObject = {};
			algoMetadataObject.algoName = result.algoName;
			algoMetadataObject.title = result.title;
			algoMetadataObject.ComputationEngine = result.ComputationEngine;
			algoMetadataObject.inputParams = result.inputParams;
			algoMetadataObject.outputs = result.outputs;
			
			//adding it to the list
			that.data.algorithmMetadataObjects.push(algoMetadataObject);
			
			//console.log("current list of metadata objects", that.data.algorithmMetadataObjects);
			//console.log("received from server", algoMetadataObject.title);
			
			//this object will be used to build the dynamic UI for parameter input
			that.data.currentMetObj = algoMetadataObject;
			
			scope.$safeApply(function() {
				deferred.resolve(result);
			});
			
		});
	};
	
	/**
	 * this function collects the corresponding scripts depending on the algorithm Object
	 * for eg for algoX collect algoX.R or algoX.py
	 */
	this.getScripts= function(algoNames){
		console.log("inputoBjects", algoNames);
		
		var deferred = $q.defer();
		aws.queryService(scriptManagementURL, 'getScriptFiles', [algoNames], function(result){
			
			console.log("got scripts", result);
			
			runScriptService.runScript(that.data.algorithmMetadataObjects ,result);
			
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
			this.data.chosenAlgorithms.splice(0,0,id);//so that the latest one is added at the top of the list
	
		}
		else
			alert(id + " has already been added");
	};
		
	
	
	/**
	 * This function removes algorithms from the algorithm cart
     */
	this.remove_algorithmObject = function(id){
		this.data.chosenAlgorithms.splice($.inArray(id, this.data.chosenAlgorithms), 1);//TODO find faster way of doing this (see slight lag)
		this.data.currentMetObj = {};//cleans the input panel
	};
		
}]);
