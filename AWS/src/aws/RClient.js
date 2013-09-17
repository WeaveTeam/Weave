goog.require('aws');
goog.provide('aws.RClient');

var rServiceURL = '/WeaveServices/RService';
var adminServiceURL = '/WeaveServices/AdminService';



//parameters sent from the QueryHandler.js
/** 
 * @param {Object} connectionObject required for R to make a connection to the db; given by the QueryHandler.js
 * @constructor {aws.rDataRequestObject} rDataRequestObject collection of parameters required to execute the computational script; also given by the QueryHandler.js
 */
aws.RClient = function(connectionObject, rDataRequestObject){
	
	this.connectionObject = connectionObject;
	this.rDataRequestObject = rDataRequestObject;
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
}

/**
 * This function calls the startRServe function on the servlet
 * It finds out the right version of the OS and calls the appropriate
 * command on the server.
 * @param {Function} callback callback function
 */
aws.RClient.startRServe = function(callback) {
	// we can use the call back to handle whether or not the service was started.
	aws.queryService(rServiceURL, 'startRServe', null, callback);
}

/**
 * This function calls the stopRServe function on the servlet
 * It finds out the right version of the OS and calls the appropriate
 * command on the server.
 * @param {Function} callback callback function
 */
aws.RClient.stopRServe = function(callback) {
	// we can use the call back to handle whether or not the service was started.
	aws.queryService(rServiceURL, 'stopRServe', null, callback);
};

/**
 * This function calls the getListOfScripts function on the servlet
 * it will get the list of files in the directory
 * @param {string} directoryPath the directory where the scripts are located
 * @param {Function} callback callback function
 */
aws.RClient.getListOfScripts = function(directoryPath, callback) {
	aws.queryService(rServiceURL, 'getListOfScripts', [directoryPath], callback);
};

/**
 *  This function mirrors the runScriptOnSQLServer function on the RService. It runs a script using R and fetching the data from the database.
 * 
 *  @param {Function} callback function that handles the servlet result
 *
 */
aws.RClient.prototype.runScriptOnSQLdata = function(callback){
	aws.queryService(rServiceURL,'runScriptwithScriptMetadata',[this.connectionObject, this.rDataRequestObject], callback);
};

/**
 * This will call the getScriptMetadata function on the RService and asynchronously return script metadata information loaded form a json file
 * 
 * @param {String} folderPath the name of the folder where the script is located
 * @param {String} scriptName the name of the script that we are looking the metadata for
 * @param {Function} callback function that handles the servlet result
 * 
 */
aws.RClient.getScriptMetadata = function(folderPath, scriptName, callback) {
	aws.queryService(rServiceURL, 'getScriptMetadata', [folderPath, scriptName], callback);
};


/**
 *  This function returns the connection from the AdminServie servlet
 * 
 *  @param {string} user 
 *  @param {string} passwd
 *  @param {Function} storeConnection once the connection has been retrieved, it is stored for further Rservice servlet calls
 *
 */
aws.RClient.prototype.getConnectionObject = function(user, passwd,storeConnection){
	aws.queryService(adminServiceURL, 'getConnectionInfo',[user, passwd, user],storeConnection);
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
	aws.queryService(rServiceURL, 'runScriptWithFilteredColumns', this.rDataRequestObject, callback);
}



