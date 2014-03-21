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
	this.rRequestObject.dataRequest = {};
	
	if(queryObject.hasOwnProperty("scriptSelected")) {
		if (queryObject.scriptSelected != "") {
			this.rRequestObject.scriptName = queryObject.scriptSelected;
		} else {
			console.log("no script selected");
		}
	}
	
	if(queryObject.hasOwnProperty("projectSelected")) {
		if (queryObject.projectSelected != "") {
			this.rRequestObject.projectName = queryObject.projectSelected;
		} else {
			console.log("no project selected");
		}
	}
	
	var scriptColumnRequest = [];
	if(queryObject.hasOwnProperty("ScriptColumnRequest")) {
		for( var i = 0; i < queryObject.ScriptColumnRequest.length; i++) {
			scriptColumnRequest.push(queryObject.ScriptColumnRequest[i].id);
		}
	}
	
	var geoFilter = {};
	// Create a filter only request where we will pass geography and time-period information.
	if(queryObject.hasOwnProperty("GeographyFilter")) {
		var geoQuery = {};
		var stateId = queryObject.GeographyFilter.stateColumn.id;
		var countyId = queryObject.GeographyFilter.countyColumn.id;
		
		geoQuery.or = [];
		for(var key in queryObject.GeographyFilter.filters) {
			for(var i in queryObject.GeographyFilter.filters[key].counties) {
				var countyFilterValue;
				for(var key2 in queryObject.GeographyFilter.filters[key].counties[i]) {
					countyFilterValue = key2;
				}
				geoQuery.or.push({and : [
				                         { id : stateId, filter : key},
				                         { id : countyId, filter : countyFilterValue }
				                         ]});
			}
		}
		geoFilter = geoQuery;
	}
	
	var timePeriodFilter = {};
	if(queryObject.hasOwnProperty("TimePeriodFilter")) {
		var timePeriodQuery = {};
		var yearId = queryObject.TimePeriodFilter.yearColumn.id;
		var monthId = queryObject.TimePeriodFilter.monthColumn.id;
		timePeriodQuery.or = [];
		for(var key in queryObject.TimePeriodFilter.filters) {
			console.log(key);
			for(var i in queryObject.TimePeriodFilter.filters[key].months) {
				var monthFilterValue;
				for(var key2 in queryObject.TimePeriodFilter.filters[key].months[i]) {
					monthFilterValue = key2;
				}
				timePeriodQuery.or.push({and : [
				                         { id : yearId, filter : key},
				                         { id : monthId, filter : monthFilterValue }
				                         ]});
			}
		}
		timePeriodFilter = timePeriodQuery;
	}
	
	var byVariableFilter = {};
	if(queryObject.hasOwnProperty("ByVariableFilter")) {
		var byVarQuery = {};
		byVarQuery.and = [];
		for(var i in queryObject.ByVariableFilter) {
			var byvar = {or : []};
			for (var j in queryObject.ByVariableFilter[i].filters) {
				byvar.or.push({
					id : queryObject.ByVariableFilter[i].column.id,
					filter : queryObject.ByVariableFilter[i].filters[j].value
				});
			}
			byVarQuery.and.push( byvar );
		}
		
		byVariableFilter = byVarQuery;
	}	
	
	var nestedFilterRequest = { and : [timePeriodFilter, byVariableFilter, geoFilter] };
	
	this.rRequestObject.dataRequest = {
			ids : scriptColumnRequest,
			NestedColumnFilter : nestedFilterRequest
	};
	
	console.log(angular.toJson(this.rRequestObject));
	
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
						parameters : queryObject.MapTool.selected,
						title : queryObject.MapTool.title,
						enableTitle : queryObject.MapTool.enableTitle
					}
			);
		}
	}	
	
	if (queryObject.hasOwnProperty("ScatterPlotTool")) {
		if(queryObject.ScatterPlotTool.enabled == true) {
			this.visualizations.push(
					{
						type : "ScatterPlotTool",
						parameters : { X : queryObject.ScatterPlotTool.X, Y : queryObject.ScatterPlotTool.Y },
						title : queryObject.ScatterPlotTool.title,
						enableTitle : queryObject.ScatterPlotTool.enableTitle
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
									  },
						title : queryObject.BarChartTool.title,
						enableTitle : queryObject.ScatterPlotTool.enableTitle
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
		newWeaveWindow = window.open("aws/visualization/weave/weave.html",
			"abc","toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
	}
	
	if(newWeaveWindow.log) {
		newWeaveWindow.log("Running Query in R...");
	};
	
	console.log(this.rRequestObject);
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
						parameters : queryObject.MapTool.selected,
						title : queryObject.MapTool.title,
						enableTitle : queryObject.MapTool.enableTitle
					}
			);
		}
	}	
	
	if (queryObject.hasOwnProperty("ScatterPlotTool")) {
		if(queryObject.ScatterPlotTool.enabled == true) {
			this.visualizations.push(
					{
						type : "ScatterPlotTool",
						parameters : { X : queryObject.ScatterPlotTool.X, Y : queryObject.ScatterPlotTool.Y },
						title : queryObject.ScatterPlotTool.title,
						enableTitle : queryObject.ScatterPlotTool.enableTitle
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
									  },
						title : queryObject.BarChartTool.title,
						enableTitle : queryObject.ScatterPlotTool.enableTitle
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
