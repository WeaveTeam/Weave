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
	
	this.rRequestObject = {};
	this.rRequestObject.scriptName = "";
	this.rRequestObject.FilteredColumnRequest = [];

	if(queryObject.hasOwnProperty("scriptSelected")) {
		if (queryObject.scriptSelected != "") {
			this.rRequestObject.scriptName = queryObject.scriptSelected;
		} else {
			console.log("no script selected");
		}
	}
	
	if(queryObject.hasOwnProperty("FilteredColumnRequest")) {
		for( var i = 0; i < queryObject.FilteredColumnRequest.length; i++) {
			this.rRequestObject.FilteredColumnRequest[i] = {
					id : -1,
					filters : []
			};
			
			if (queryObject.FilteredColumnRequest[i].hasOwnProperty("column")) {
				this.rRequestObject.FilteredColumnRequest[i].id = queryObject.FilteredColumnRequest[i].column.id;
			}
			
			if (queryObject.FilteredColumnRequest[i].hasOwnProperty("filters")) {
				if(queryObject.FilteredColumnRequest[i].filters.hasOwnProperty('enabled')) {
					if (queryObject.FilteredColumnRequest[i].filters.enabled == true) {
						var temp = [];
						if(queryObject.FilteredColumnRequest[i].filters.hasOwnProperty("filterValues")) {
							if(queryObject.FilteredColumnRequest[i].filters.filterValues[0].constructor == Object) {
								temp =  $.map(queryObject.FilteredColumnRequest[i].filters.filterValues, function(item){
									return item.value;
								});
							}
						}						
						this.rRequestObject.FilteredColumnRequest[i].filters = temp;
					} else if (queryObject.FilteredColumnRequest[i].filters.filterValues[0].constructor == Array) {
						temp = [];
						if(queryObject.FilteredColumnRequest[i].filters.hasOwnProperty("filterValues")) {
							if(queryObject.FilteredColumnRequest[i].filters.filterValues[0].constructor == Object) {
								temp =  $.map(queryObject.FilteredColumnRequest[i].filters.filterValues, function(item){
									return item;
								});
							}
						}
						this.rRequestObject.FilteredColumnRequest[i].filters = temp;
					}
				}
			}
		}
	}	
	this.keyType = "";
	
	if(queryObject.hasOwnProperty("ColorColumn")) {
		if(queryObject.ColorColumn.enabled == true) {
			this.ColorColumn = queryObject.ColorColumn.selected;
		}
	}

	this.visualizations = [];
	
	if (queryObject.hasOwnProperty("MapTool")) {
		if(queryObject.MapTool.enabled == true) {
			this.keyType = queryObject.MapTool.selected.keyType;
			this.visualizations.push(
					{
						type : "MapTool",
						parameters : queryObject.MapTool.selected
					}
			);
		}
	}	
	
	if (queryObject.hasOwnProperty("ScatterPlotTool")) {
		if(queryObject.ScatterPlotTool.enabled == true) {
			this.visualizations.push(
					{
						type : "ScatterPlotTool",
						parameters : { X : queryObject.ScatterPlotTool.X, Y : queryObject.ScatterPlotTool.Y }
					}
			);
		}
	}	
	
	if (queryObject.hasOwnProperty("BarChartTool")) {
		if(queryObject.BarChartTool.enabled == true) {
			this.visualizations.push(
					{
						type : "BarChartTool",
						parameters : { 
									   heights : queryObject.BarChartTool.heights, 
									   sort : queryObject.BarChartTool.sort, 
									   label : queryObject.BarChartTool.label 
									  }
					}
			);
		}
	}	
	
	if (queryObject.hasOwnProperty("DataTableTool")) {
		if(queryObject.DataTableTool.enabled == true) {
			this.visualizations.push(
					{
						type : "DataTable",
						parameters : queryObject.DataTableTool.selected
					}
			);
		}
	}
	
	this.currentVisualizations = {};
	
	 //testing

	//this.weaveClient = new aws.WeaveClient($('#weave')[0]);

	// check what type of computation engine we have, to create the appropriate
	// computation client
	this.ComputationEngine = null;
	if(queryObject.ComputationEngine == 'r' || queryObject.ComputationEngine == 'R') {
		//console.log(this.rRequestObject);
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
	$("#LogBox").html('');
	//testing new Weave Window
	if(!newWeaveWindow || newWeaveWindow.closed) {
		newWeaveWindow = window.open("SeparateWindow.html",
			"abc","toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
	}
	
	if(newWeaveWindow.log) {
		newWeaveWindow.log("Running Query in R...");
	};
	
	this.ComputationEngine.run("runScriptWithFilteredColumns", function(result) {	
		aws.timeLogString = "";
		that.resultDataSet = result.data[0].value;
		$("#LogBox").append('<p>' + "Data Load Time: " + result.times[0]/1000 + " seconds.\n" + '</p>');
		$("#LogBox").append("R Script Computation Time: " + result.times[1] / 1000 + " seconds." + '</p>');

		newWeaveWindow.workOnData(that, result.data[0].value);
		
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
	//$("#LogBox").html('');
	if(newWeaveWindow) {
		newWeaveWindow.clearWeave(this);
	}
};

aws.QueryHandler.prototype.updateVisualizations = function(queryObject) {
	
	this.visualizations = [];
	
	if(queryObject.hasOwnProperty("ColorColumn")) {
		if(queryObject.ColorColumn.enabled == true) {
			this.ColorColumn = queryObject.ColorColumn.selected;
		}
	}

	this.visualizations = [];
	
	if (queryObject.hasOwnProperty("MapTool")) {
		if(queryObject.MapTool.enabled == true) {
			this.keyType = queryObject.MapTool.keyType;
			this.visualizations.push(
					{
						type : "MapTool",
						parameters : queryObject.MapTool.selected
					}
			);
		}
	}	
	
	if (queryObject.hasOwnProperty("ScatterPlotTool")) {
		if(queryObject.MapTool.enabled == true) {
			this.visualizations.push(
					{
						type : "ScatterPlotTool",
						parameters : { X : queryObject.ScatterPlotTool.X, Y : queryObject.ScatterPlotTool.Y }
					}
			);
		}
	}	
	
	if (queryObject.hasOwnProperty("BarChartTool")) {
		if(queryObject.BarChartTool.enabled == true) {
			this.visualizations.push(
					{
						type : "BarChartTool",
						parameters : { 
									   heights : queryObject.BarChartTool.heights, 
									   sort : queryObject.BarChartTool.sort, 
									   label : queryObject.BarChartTool.label 
									  }
					}
			);
		}
	}	
	
	if (queryObject.hasOwnProperty("DataTableTool")) {
		if(queryObject.DataTableTool.enabled == true) {
			this.visualizations.push(
					{
						type : "DataTable",
						parameters : queryObject.DataTableTool.selected
					}
			);
		}
	}
	newWeaveWindow.updateVisualizations(this);
};
