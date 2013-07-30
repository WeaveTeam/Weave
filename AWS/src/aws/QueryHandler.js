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
	
	this.rRequestObject = {
		dataset : queryObject.dataTable,
		scriptPath : queryObject.scriptLocation,
		columnsToBeRetrieved : queryObject.dataColumns,
		scriptName : queryObject.scriptSelected
	};
	
	this.connectionObject = {
			user : queryObject.conn.sqluser,
			password : queryObject.conn.sqlpass,
			schema : queryObject.conn.serverType,
			host : queryObject.conn.sqlip,
			port : queryObject.conn.sqlport
	};
	
	this.visualizations = queryObject.weaveOptions.visualizations;
	
	this.colorColumn = queryObject.weaveOptions.colorColumn;
	this.weaveClient = new aws.WeaveClient(queryObject.weaveOptions.weaveObject);
	
	// check what type of computation engine we have, to create the appropriate
	// computation client
	this.computationEngine;
	if(queryObject.scriptType == 'r') {
		this.computationEngine = new aws.RClient(this.connectionObject, this.rRequestObject);
	} else if (queryObject.scriptType == 'stata') {
		// computationEngine = new aws.StataClient();
	}
	
};

var timeLogString= "";

/**
 * This function is the golden evaluator of the query.
 * 1- run the scripts against the data
 * 2- send the results to weave
 * 3- call weave, create the visualizations and set the parameters
 */
aws.QueryHandler.prototype.runQuery = function() {
	
	// step 1
		
	this.computationEngine.run("SQLData", function(result) {
		
		var resultDataSet = result[0].value;//get rid of hard coded (for later)
		//updating the log
		try{
			$("#LogBox").append(timeLogString);
		}catch(e){
			//ignore
		}
		
		// step 2
		this.weaveClient.addCSVDataSourceFromString(resultDataSet, "WOOHOO");
		// step 3
		for (var visualization in this.weaveOptions.visualizations) {
			this.weaveClient.newVisualization(visualization);
		}
		
		if (this.weaveOptions.colorColumn) {
			this.weaveClient.setColorAttribute(this.weaveOptions.colorColumn);
		}	
	});
};