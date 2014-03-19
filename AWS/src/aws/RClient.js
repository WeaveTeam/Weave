goog.require('aws');
goog.provide('aws.RClient');

//var rServiceURL = '/WeaveServices/RService';
var rServiceURL = '/WeaveServices/AWSRService';

//parameters sent from the QueryHandler.js
/** 
 * @param {aws.rRequestObject} rRequestObject collection of parameters required to execute the computational script; also given by the QueryHandler.js
 * @constructor 
 */
aws.RClient = function(rRequestObject){

	this.rRequestObject = rRequestObject;

};

//define get methods for both objects

// these variabes should be changed to this.resultString inside the constructor.
// because declaring it like this makes it global. but we can leave for now.
var resultString = "notReplacedYet";

//var callbk = function(result){
//	console.log(result);
//	resultString = result;
//	timeLogString = resultString[1].value;
//	try{
//		$("#LogBox").append(timeLogString);
//	}catch(e){
//		//ignore
//	}
//};
aws.RClient.prototype.run = function(type, callback) {
	
	if (type == "SQLData") {
		this.runScriptOnSQLdata(callback);
	} else if (type == "JavaSQLData") {
		this.runScriptWithFilteredColumns(callback);
	}
	if (type == "runScriptWithFilteredColumns") {
		this.runScriptWithFilteredColumns(callback);
	}
	//return resultString;
};

/**
 * This function calls the clearCache function on the servlet.
 * We do not need an instance of a RClient to call this function.
 * 
 */	
aws.RClient.clearCache = function() {
	aws.queryService(rServiceURL,'clearCache', null, null);
};

/**
 * This function calls the getListOfScripts function on the servlet
 * it will get the list of files in the directory
 * @param {Function} callback callback function
 */
aws.RClient.getListOfScripts = function(callback) {
	aws.queryService(rServiceURL, 'getListOfScripts', null, callback);
};

aws.RClient.getScript = function(scriptName, callback){
  aws.queryService(rServiceURL, 'getScript', [scriptName], callback);
};

aws.RClient.saveMetadata = function(scriptName, metadata, callback){
  aws.queryService(rServiceURL, 'saveMetadata', [scriptName, metadata], callback);
};
/**
 *  This function mirrors the runScriptOnSQLServer function on the RService. It runs a script using R and fetching the data from the database.
 * 
 *  @param {Function} callback function that handles the servlet result
 *
 */
aws.RClient.prototype.runScriptOnSQLdata = function(callback){
	aws.queryService(rServiceURL,'runScriptwithScriptMetadata',[this.connectionObject, this.rRequestObject], callback);
};

/**
 * This will call the getScriptMetadata function on the RService and asynchronously return script metadata information loaded form a json file
 * 
 * @param {String} scriptName the name of the script that we are looking the metadata for
 * @param {Function} callback function that handles the servlet result
 * 
 */
aws.RClient.getScriptMetadata = function(scriptName, callback) {
	aws.queryService(rServiceURL, 'getScriptMetadata', [scriptName], callback);
};


/*-----------------CALLBACKS------------------------------------------------------------------*/
//stores the connection to be used in later R servlet calls
aws.RClient.prototype.storeConnection= function(result, queryId){
	this.connectionObject = result;
};

//writes results to the database if they do not exist in the database
aws.RClient.prototype.writeResultsToDatabase = function(requestObject,displayWritingStatus){
	aws.queryService(rServiceURL, 'writeResultsToDatabase',requestObject, displayWritingStatus);
};

aws.RClient.prototype.displayWritingStatus = function(result, queryId){
	
};


aws.RClient.prototype.retriveResultsFromDatabase = function(requestObject){
	//identify the id of requestObject
	//check for the existence of a connection
	//construct a query and pull out the results using point # 1
	//display in viz
};

/**
 *  This function mirrors the runScriptWithFilteredColumns function on the RService. It runs a script using R and getting the filtered columns using Java..
 * 
 *  @param {Function} callback function that handles the servlet result
 *	@return void.
 *
 */
aws.RClient.prototype.runScriptWithFilteredColumns = function(callback) {
	aws.queryService(rServiceURL, 'runScriptWithFilteredColumns', this.rRequestObject, callback);
};
