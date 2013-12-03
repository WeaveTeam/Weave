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
	
	if(queryObject.hasOwnProperty("FilteredColumnRequest") &&
	   queryObject.hasOwnProperty("scriptSelected") ) {
		this.rRequestObject = {
				FilteredColumnRequest : queryObject.FilteredColumnRequest,
				scriptName : queryObject.scriptSelected
		};			

	}
	
	if(queryObject.hasOwnProperty("ColorColumn")) {
		this.ColorColumn = queryObject.ColorColumn;
	}

	this.keyType = "";
	
	this.visualizations = [];
	
	if (queryObject.hasOwnProperty("MapTool")) {
		this.keyType = queryObject.MapTool.keyType;
		this.visualizations.push(
				{
					type : "MapTool",
					parameters : queryObject.MapTool
				}
		);
	}	
	
	if (queryObject.hasOwnProperty("ScatterPlotTool")) {
		this.visualizations.push(
				{
					type : "ScatterPlotTool",
					parameters : queryObject.ScatterPlotTool
				}
		);
	}	
	if (queryObject.hasOwnProperty("BarChartTool")) {
		this.visualizations.push(
				{
					type : "BarChartTool",
					parameters : queryObject.BarChartTool
				}
		);
	}	
	
	if (queryObject.hasOwnProperty("DataTable")) {
		this.visualizations.push(
				{
					type : "DataTable",
					parameters : queryObject.DataTable
				}
		);
	}	
	
	 //testing

	//this.weaveClient = new aws.WeaveClient($('#weave')[0]);

	// check what type of computation engine we have, to create the appropriate
	// computation client
	this.ComputationEngine = null;
	if(queryObject.ComputationEngine == 'r' || queryObject.ComputationEngine == 'R') {
		this.ComputationEngine = new aws.RClient(this.rRequestObject);
	}// else if (queryObject.scriptType == 'stata') {
//		// computationEngine = new aws.StataClient();

	this.resultDataSet = "";

};

//testing
var newWeaveWindow;

/**
 * This function is the golden evaluator of the query.
 * 1- run the scripts against the data
 * 2- send the results to weave
 * 3- call weave, create the visualizations and set the parameters
 */
aws.QueryHandler.prototype.runQuery = function() {

	// step 1
	var that = this;
	//testing new Weave Window
	newWeaveWindow = window.open("SeparateWindow.html",
			"abc","toolbar=yes, fullscreen = yes, scrollbars=yes, resizable=yes");
	
	//newWeaveWindow.JSON.abc = "123 " + newWeaveWindow.JSON.abc;
	//console.log("variable abc " + newWeaveWindow.JSON.abc);
	//testing
	aws.window = newWeaveWindow;
	
	this.ComputationEngine.run("runScriptWithFilteredColumns", function(result) {	
		aws.timeLogString = "";
		that.resultDataSet = result[0].value;//get rid of hard coded (for later)
		console.log(that.resultDataSet);
		// aws.timeLogString = result[1].value;
		$("#LogBox").append('<p>' + aws.timeLogString + '</p>');
		
		newWeaveWindow.workOnData.call(that, result[0].value);
		
		// step 2
		//var dataSourceName = that.weaveClient.addCSVDataSourceFromString(that.resultDataSet, "", that.keyType, "fips");
		//var dataSourceName = that.weaveClient.addCSVDataSource(that.resultDataSet, "", that.keyType, "fips");
		
		// step 3
//		for (var i in that.visualizations) {
//			that.weaveClient.newVisualization(that.visualizations[i], dataSourceName);
//			aws.timeLogString = aws.reportTime(that.visualizations[i].type + ' added');
//			$("#LogBox").append('<p>' + aws.timeLogString + '</p>');
//		}
//		
//		if (that.ColorColumn) {
//			that.weaveClient.setColorAttribute(that.ColorColumn, dataSourceName);
//			aws.timeLogString = aws.reportTime('color column added');
//			$("#LogBox").append('<p>' + aws.timeLogString + '</p>');		
//		}	
	});
};

aws.QueryHandler.prototype.clearWeave = function () {
	newWeaveWindow.client.clearWeave();
};

aws.QueryHandler.prototype.updateVisualizations = function(visualizations,keyType) {

	newWeaveWindow.updating(visualizations);
	console.log("calling updating");

};
