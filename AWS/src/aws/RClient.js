goog.require('aws');
goog.provide('aws.RClient');

var rServiceURL = '/WeaveServices/RService';
var adminServiceURL = '/WeaveServices/AdminService';

//parameters sent from the QueryHandler.js
/** 
 * @param {Object} connectionObject required for R to make a connection to the db; given by the QueryHandler.js
 * @constructor {Object} rDataRequestObject collection of parameters required to execute the computational script; also given by the QueryHandler.js
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
 *  This function mirrors the runScriptOnSQLServer function on the RService. It runs a script using R and fetching the data from the database.
 * 
 *  @param {Function} callback function that handles the servlet result
 *	@return void.
 *
 */
aws.RClient.prototype.runScriptOnSQLdata = function(callback){
	aws.queryService(rServiceURL,'runScriptOnSQLColumns',[this.connectionObject, this.rDataRequestObject], callback);
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


