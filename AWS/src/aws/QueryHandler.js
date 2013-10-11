goog.provide('aws.QueryHandler');

goog.require('aws');
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
		scriptName : queryObject.scriptSelected
	};
	this.rRequestObject["columnsToBeRetrieved"] = [];
	
	if (queryObject.scriptType == "ColumnBased") {
		for( var i = 0; i < queryObject.scriptOptions.length; i++) {
			this.rRequestObject["columnsToBeRetrieved"].push({id: queryObject.scriptOptions[i].id, filters : queryObject.scriptOptions[i].filter});
		}
	} else if (queryObject.scriptType == "ParamBased") {
		// this option gets all the columns selected from the Analysis builder section.
		this.algorithmParameters = queryObject.ParamBasedOptions;
	}
	
	
	this.connectionObject = {
	        connectionType : queryObject.conn.connectionType,
			user : queryObject.conn.sqluser,
			password : queryObject.conn.sqlpass,
			schema : queryObject.conn.schema,
			host : queryObject.conn.sqlip,
			port : queryObject.conn.sqlport,
			dsn : queryObject.conn.dsn
	};
	
	this.visualizations = [];
	
	
	for (var visualization in queryObject.selectedVisualization) {
		//if (queryObject.selectedVisualization.hasOwnProperty(visualization)) {
			if (queryObject.selectedVisualization[visualization]) {
				this.visualizations.push( { type : visualization, parameters : queryObject[visualization] });
			}			
	}
	this.colorColumn = queryObject.colorColumn;
	
	this.keyType = "";
	if (queryObject.maptool){
		if(queryObject.maptool.keyType) {
			this.keyType = queryObject.maptool.keyType;
		}
	}
	
	
	this.weaveClient = new aws.WeaveClient($('#weave')[0]);

	// check what type of computation engine we have, to create the appropriate
	// computation client
	this.computationEngine = null;
	if(queryObject.computationEngine.toLowerCase() === "r") {
		if(queryObject.scriptType === "ColumnBased") {
			this.computationEngine = new aws.RClient(this.connectionObject, this.rRequestObject);
		} else if(queryObject.scriptType === "ParamBased") {
			this.computationEngine = new aws.RClient(this.connectionObject, this.rRequestObject, this.algorithmParameters);
		}
	}// else if (queryObject.scriptType == 'stata') {
//		// computationEngine = new aws.StataClient();
//	}
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
	//clear all existing visualizations
	that.weaveClient.clearCurrentVizs();
	
	// TODO Shweta this is where we are going to call different run function based on
	// different options... 
	this.computationEngine.run("JavaSQLData", function(result) {
		
		aws.timeLogString = "";
		that.resultDataSet = result[0].value;//get rid of hard coded (for later)
		console.log(result[0].value);
		aws.timeLogString = result[1].value;
		console.log(result[1].value);
		$("#LogBox").append('<p>' + aws.timeLogString + '</p>');
		
		// step 2
		var dataSourceName = that.weaveClient.addCSVDataSourceFromString(that.resultDataSet, "", that.keyType, "fips");
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
