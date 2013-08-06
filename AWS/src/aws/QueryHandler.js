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
 * @param {aws.queryObject} queryObject. The query object obtained from the UI, or alternatively, from a file.
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
		dataset : queryObject.conn.sqldbname,
		scriptPath : queryObject.conn.scriptLocation,
		columnsToBeRetrieved : queryObject.scriptOptions,
		scriptName : queryObject.scriptSelected
	};
	
	this.connectionObject = {
			user : queryObject.conn.sqluser,
			password : queryObject.conn.sqlpass,
			schema : queryObject.conn.schema,
			host : queryObject.conn.sqlip,
			port : queryObject.conn.sqlport
	};
	
	this.visualizations = [];
	
	for (var visualization in queryObject.selectedVisualization) {
		//if (queryObject.selectedVisualization.hasOwnProperty(visualization)) {
			if (queryObject.selectedVisualization[visualization]) {
				this.visualizations.push( { type : visualization, parameters : queryObject[visualization] });
			}			
	}
	console.log(this.visualizations)	;
	this.colorColumn = queryObject.colorColumn;
	
	this.weaveClient = new aws.WeaveClient($('#weave')[0]);
	
	// check what type of computation engine we have, to create the appropriate
	// computation client
	this.computationEngine;
	if(queryObject.scriptType == 'r') {
		this.computationEngine = new aws.RClient(this.connectionObject, this.rRequestObject);
	} else if (queryObject.scriptType == 'stata') {
		// computationEngine = new aws.StataClient();
	}
	this.resultDataSet = "";
};

/**
 * This function is the golden evaluator of the query.
 * 1- run the scripts against the data
 * 2- send the results to weave
 * 3- call weave, create the visualizations and set the parameters
 */
aws.QueryHandler.prototype.runQuery = function() {
	
	// step 1
	var that = this;
	this.computationEngine.run("SQLData", function(result) {
		
		that.resultDataSet = result[0].value;//get rid of hard coded (for later)
		console.log(result[0].value);
		aws.timeLogString = result[1].value;
		console.log(result[1].value);
		$("#LogBox").append('<p>' + aws.timeLogString + '</p>');
		
		// step 2
		var dataSourceName = that.weaveClient.addCSVDataSourceFromString(that.resultDataSet, "", "US State FIPS Code", "fips");
		// step 3
		for (var i in that.visualizations) {
			that.weaveClient.newVisualization(that.visualizations[i], dataSourceName);
			aws.timeLogString = aws.reportTime(that.visualizations[i].type + ' added');
			$("#LogBox").append('<p>' + aws.timeLogString + '</p>');
		}
		
		if (that.colorColumn) {
			that.weaveClient.setColorAttribute(that.colorColumn, dataSourceName);
			aws.timeLogString = aws.reportTime('color column added');
			$("#LogBox").append('<p>' + aws.timeLogString + '</p>');		
		}	
	});
};
