goog.provide('aws.QueryHandler');

goog.require('aws.client');
goog.require('aws.RClient');
goog.require('aws.StataClient');
goog.require('aws.WeaveClient');

/**
 * This class is designed to receive a query object and interpret its content.
 * 
 * @constructor
 * 
 * @param {Object} queryObject. The query object obtained from the UI, or alternatively, from a file.
 *
 **/
aws.QueryHandler = function(queryObject)
{
	// the idea here is that we "parse" the query Object into smaller entities (brokers) and use them as needed.
	/**@type {string}*/
	this.title = queryObject.title;
	
	this.dateGenerated = queryObject.date;
	this.author = queryObject.author;
	
	this.dataset = queryObject.dataTable;
	
	this.dataColumns = queryObject.dataColumns;
	
	this.scriptName = queryObject.scriptName;
	
	this.computationInfo = {
	     scriptType : queryObject.scriptType,
	     scriptName : queryObject.scriptName,
	     scriptLocation : queryObject.scriptLocation
	};
	
	this.dbConnectionInfo = queryObject.conn;
	this.weaveOptions = queryObject.weaveOptions;
	
};

var timeLogString= "";
var checkString = "";

/**
 * after the asynchronous R call is returned, send the results to the Weave Client and update the time log
 */
aws.QueryHandler.prototype.resultHandlingCallback = function(result){
//	console.log("callback called");
//	
//	var numericalResultString = result[0].value;//get rid of hard coded (for later)
//	
//	//updating the log
//	checkString = numericalResultString;
//	timeLogString = result[1].value;//get rid of hard coded (for later)
//	try{
//		$("#LogBox").append(timeLogString);
//	}catch(e){
//		//ignore
//	}
//	
//	//only after the asynchromous call completes and result is returned, send the results to the Weave client for making into a CSVDatasource
//	//TODO make weaveClient a class member variable?
//
//	// step 3
//	// TODO provide a way to store the result directly on the data base?
//	// How do I tell the UI what results were returned?
//	//weaveClient.addCSVDataSourceFromString(numericalResultString);
	
};	


/**
 * This function is the golden evaluator of the query.
 * 1- create a new computation engine and initialize it.
 * 2- run the scripts against the data
 * 3- handle the results
 * 4- call weave, create the visualizations and set the parameters
 */
aws.QueryHandler.prototype.runQuery = function() {
	
	// check what type of computation engine we have, to create the appropriate
	// computation client
	var computationEngine;
	var visualization;
	var column;
	var columnsToBeRetrieved = this.dataColumns;
	
	var rRequestObject = {};
	rRequestObject.dataset = this.dataset;
	rRequestObject.scriptPath = this.computationInfo.scriptLocation;
	
	rRequestObject.columnsToBeRetrieved = columnsToBeRetrieved;
	rRequestObject.scriptName = this.scriptName;
	
	var connectionObject = {};
	connectionObject.user = this.dbConnectionInfo.sqluser;
	connectionObject.password = this.dbConnectionInfo.sqlpass;
	connectionObject.schema = this.dbConnectionInfo.serverType;
	connectionObject.host = this.dbConnectionInfo.sqlip;
	connectionObject.port = this.dbConnectionInfo.sqlport;
	
	// step 1
	if(this.computationInfo.scriptType == 'r') {
		computationEngine = new aws.RClient(connectionObject, rRequestObject);
		console.log(computationEngine);
	} else if (this.computationInfo.scriptType == 'stata') {
		// computationEngine = new aws.StataClient();
	}
	
	var weaveClient = new aws.WeaveClient(this.weaveOptions.weaveObject);
	
	
	computationEngine.runScriptOnSQLdata(connectionObject, rRequestObject, function(result) {
		console.log("callback called");
		
		var resultDataSet = result[0].value;//get rid of hard coded (for later)
		
		//updating the log
		try{
			$("#LogBox").append(timeLogString);
		}catch(e){
			//ignore
		}
		
		weaveClient.addCSVDataSourceFromString(resultDataSet);
		// step 4
		for (visualization in this.weaveOptions.visualizations) {
			weaveClient.newVisualization(visualization);
		}
		
		if (this.weaveOptions.colorColumn) {
			weaveClient.setColorAttribute(this.weaveOptions.colorColumn);
		}	
	}); // this should be a 2D array data set regardless of the computation engine	
};
	


