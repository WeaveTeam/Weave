goog.require('aws.client');
goog.provide('aws.client.RClient');

var rServiceURL = '/WeaveServices/RService';
var adminServiceURL = '/WeaveServices/AdminService';

var connectionObject;
//var displayWritingStatus;
//var displayResultsInViz;
//var storeConnection;



/**
 *  This function mirrors the runScriptOnSQLServer function on the RService. It runs a script using R and fetching the data from the database.
 * 
 *  @param {Object} connectionObject the connection info to allow R to connect to the database retrieved from Admin Service
 *  @param {Object} requestObject the collection of parameters chosen by User via UI
 * 
 *
 */
aws.client.RClient.runScriptOnSQLdata = function(connectionObject, requestObject,displayResultsInViz){
	aws.client.queryService(rServiceURL,'runScriptOnSQLOnServer',[connectionObject, requestObject],displayResultsInViz);
};

aws.client.RClient.getConnectionObject = function(user, passwd,storeConnection){
	aws.client.queryService(adminServiceURL, 'getConnectionInfo',[user, passwd],storeConnection);
};



aws.client.RClient.storeConnection= function(result, queryId){
	connectionObject = result;
};

aws.client.RClient.writeResultsToDatabase = function(requestObject,displayWritingStatus){
	aws.client.queryService(rServiceURL, 'writeResultsToDatabase',requestObject, displayWritingStatus);
};

aws.client.RClient.displayWritingStatus = function(result, queryId){
	
};

aws.client.RClient.displayResultsInViz = function(requestObject){
	//1. check if the result property of the request object has been successfully added(done in Rservice servlet)
	//2. write the columns to the database
	//3. retrieve the results from the database if already in db
	//4. add the required viz to Weave
};

aws.client.RClient.retriveResultsFromDatabase = function(requestObject){
	//identify the id of requestObject
	//check for the existence of a connection
	//construct a query and pull out the results using point # 1
	//display in viz
};
