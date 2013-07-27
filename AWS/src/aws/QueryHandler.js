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
	
	this.computationInfo = {
	     scriptType : queryObject.scriptType,
	     scriptName : queryObject.scriptName,
	     scriptLocation : queryObject.scriptLocation
	};
	
	this.dbConnectionInfo = queryObject.conn;
	this.weaveOptions = queryObject.weaveOptions;
	
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
	
	// step 1
	if(this.computation.scriptType == 'r') {
		computationEngine = new aws.Client.RClient(this.dbConnectionInfo, this.rRequestObject);
	} else if (this.computation.scriptType == 'stata') {
		// computationEngine = new aws.Client.StataClient();
	}
	
	// step 2
	var result = computationEngine.run(); // this should be a 2D array data set regardless of the computation engine
	var weaveClient = new aws.Client.WeaveClient(this.weave);
	
	// step 3
	// TODO provide a way to store the result directly on the data base?
	// How do I tell the UI what results were returned?
	weaveClient.addCSVDataSource(result);
	
	// step 4
	for (visualization in this.WeaveOptions.visualizations) {
		weaveClient.newVisualization(visualization);
	}
	
	if (this.WeaveOptions.colorColumn) {
		weaveClient.setColorAttribute(this.WeaveOptions.colorColumn);
	}	
}
