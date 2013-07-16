goog.require('aws.client');
goog.provide('aws.RClient');

var rServiceURL = '/WeaveServices/RService';
var adminServiceURL = '/WeaveServices/AdminService';

var connectionObject;

/**
 *  This function mirrors the runScriptOnSQLServer function on the RService. It runs a script using R and fetching the data from the database.
 * 
 *  @param {Object} connectionObject the connection info to allow R to connect to the database retrieved from Admin Service
 *  @param {Object} requestObject the collection of parameters chosen by User via UI
 *
 */
aws.RClient.runScriptOnSQLdata = function(connectionObject, requestObject,displayResultsInViz){
	aws.queryService(rServiceURL,'runScriptOnSQLOnServer',[connectionObject, requestObject],displayResultsInViz);
};

/**
 *  This function returns the connection from the AdminServie servlet
 * 
 *  @param {string} user 
 *  @param {string} passwd
 *  @param {Function} storeConnection once the connection has been retrieved, it is stored for further Rservice servlet calls
 *
 */
aws.RClient.getConnectionObject = function(user, passwd,storeConnection){
	aws.queryService(adminServiceURL, 'getConnectionInfo',[user, passwd, user],storeConnection);
};


/*-----------------CALLBACKS------------------------------------------------------------------*/
//stores the connection to be used in later R servlet calls
aws.RClient.storeConnection= function(result, queryId){
	connectionObject = result;
};

//writes results to the database if they do not exist in the database
aws.RClient.writeResultsToDatabase = function(requestObject,displayWritingStatus){
	aws.queryService(rServiceURL, 'writeResultsToDatabase',requestObject, displayWritingStatus);
};

aws.RClient.displayWritingStatus = function(result, queryId){
	
};

aws.RClient.displayResultsInViz = function(requestObject){
	//1. check if the result property of the request object has been successfully added(done in Rservice servlet)
	//2. write the columns to the database
	//3. retrieve the results from the database if already in db
	//4. add the required viz to Weave
};

aws.RClient.retriveResultsFromDatabase = function(requestObject){
	//identify the id of requestObject
	//check for the existence of a connection
	//construct a query and pull out the results using point # 1
	//display in viz
};
