goog.provide('aws.QueryHandler');

goog.require('aws');
//goog.require('aws.RClient');
//goog.require('aws.StataClient');
//goog.require('aws.WeaveClient');
var tryParseJSON = function(jsonString){
    try {
        var o = JSON.parse(jsonString);

        // Handle non-exception-throwing cases:
        // Neither JSON.parse(false) or JSON.parse(1234) throw errors, hence the type-checking,
        // but... JSON.parse(null) returns 'null', and typeof null === "object", 
        // so we must check for that, too.
        if (o && typeof o === "object" && o !== null) {
            return o;
        }
    }
    catch (e) { }

    return false;
};
/**
 * This class is designed to receive a query object and interpret its content.
 * 
 * @constructor
 * 
 * @param {aws.queryObject} queryObject. The query object obtained from the UI, or alternatively, from a file.
 *
 **/
var columns;
var computationServiceURL = '/WeaveAnalystServices/ComputationalServlet';
aws.QueryHandler = function(queryObject)
{
	// the idea here is that we "parse" the query Object into smaller entities (brokers) and use them as needed.
	/**@type {string}*/
	this.title = queryObject.title;
	this.queryObject = queryObject;
	
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
	
	var scriptInputs = {};
	
	for(var key in queryObject.scriptOptions) {
		var input = queryObject.scriptOptions[key];
		//console.log(typeof input);
		switch(typeof input) {
			case 'array': // array of columns
				scriptInputs[key] = $.map(input, function(inputVal) {
					return { id : JSON.parse(inputVal).id };
				});
				break;
			case 'string' :
				var inputVal = tryParseJSON(input);
				if(inputVal) {  // column input
					scriptInputs[key] = { id : inputVal.id };
				} else { // regular string
					scriptInputs[key] = input;
				}
				break;
			case 'number' : // regular number
				scriptInputs[key] = input;
				break;
			case 'boolean' : // boolean 
				scriptInputs[key] = input;
				break;
			default:
				console.log("unknown script input type");
		}
	}

	this.rRequestObject.inputs = scriptInputs;
	
	var nestedFilterRequest = {and : []};
	
	if(queryObject.hasOwnProperty("GeographyFilter")) {
			var geoQuery = {};
			var stateId = "";
			var countyId = "";
			
			if(queryObject.GeographyFilter.stateColumn.id) {
				stateId = queryObject.GeographyFilter.stateColumn.id;
			}
			if(queryObject.GeographyFilter.countyColumn.id) {
				countyId = queryObject.GeographyFilter.countyColumn.id;
			}

			geoQuery.or = [];
			
			if(queryObject.GeographyFilter.hasOwnProperty("filters")) {
				if(Object.keys(queryObject.GeographyFilter.filters).length !== 0) {
					for(var key in queryObject.GeographyFilter.filters) {
						var index = geoQuery.or.push({ and : [
						                                      {cond : { 
						                                    	  f : stateId, 
						                                    	  v : [key] 
						                                      }
						                                      },
						                                      {cond: {
						                                    	  f : countyId, 
						                                    	  v : []
						                                      }
						                                      }
						                                      ]
						});
						for(var i in queryObject.GeographyFilter.filters[key].counties) {
							var countyFilterValue = "";
							for(var key2 in queryObject.GeographyFilter.filters[key].counties[i]) {
								countyFilterValue = key2;
							}
							geoQuery.or[index-1].and[1].cond.v.push(countyFilterValue);
						}
					}
					if(geoQuery.or.length) {
						nestedFilterRequest.and.push(geoQuery);
					}
				}
			}
	}
	
	if(queryObject.hasOwnProperty("TimePeriodFilter")) {
			var timePeriodQuery = {};
			var yearId = queryObject.TimePeriodFilter.yearColumn.id;
			var monthId = queryObject.TimePeriodFilter.monthColumn.id;
			
			timePeriodQuery.or = [];
			
			for(var key in queryObject.TimePeriodFilter.filters) {
				var index = timePeriodQuery.or.push({ and : [
				                                             {cond : { 
				                                            	 f : yearId, 
				                                            	 v : [key] 
				                                             }
				                                             },
				                                             {cond: {
				                                            	 f : monthId, 
				                                            	 v : []
				                                             }
				                                             }
				                                             ]
				});
				for(var i in queryObject.TimePeriodFilter.filters[key].months) {
					var monthFilterValue = "";
					for(var key2 in queryObject.TimePeriodFilter.filters[key].months[i]) {
						monthFilterValue = key2;
					}
					timePeriodQuery.or[index-1].and[1].cond.v.push(monthFilterValue);
				}
			}
			
			if(timePeriodQuery.or.length) {
				nestedFilterRequest.and.push(timePeriodQuery);
			}
	}
	
	if(queryObject.hasOwnProperty("ByVariableFilter")) {
		var byVarQuery = {and : []};

		for(var i in queryObject.ByVariableFilter) {
			
			if(queryObject.ByVariableFilter[i].hasOwnProperty("column")) {
				var cond = {f : queryObject.ByVariableFilter[i].column.id };
				
				if(queryObject.ByVariableFilter[i].hasOwnProperty("filters")) {
					cond.v = [];
					for (var j in queryObject.ByVariableFilter[i].filters) {
						cond.v.push(queryObject.ByVariableFilter[i].filters[j].value);
					}
					byVarQuery.and.push({cond : cond});
				} else if (queryObject.ByVariableFilter[i].hasOwnProperty("ranges")) {
					cond.r = [];
					for (var j in queryObject.ByVariableFilter[i].filters) {
						cond.r.push(queryObject.ByVariableFilter[i].filters[j]);
					}
					byVarQuery.and.push({cond : cond});
				} 
			}
		}

		if(byVarQuery.and.length) {
			nestedFilterRequest.and.push(byVarQuery);
		}
	}	
	
	
	
	if(nestedFilterRequest.and.length) {
		this.rRequestObject.filters = nestedFilterRequest;
	}
	
	this.keyType = "";
	this.ColorColumn = queryObject.ColorColumn;
	
	if(queryObject.hasOwnProperty("ColorColumn")) {
		if(queryObject.ColorColumn.enabled) {
			this.ColorColumn = queryObject.ColorColumn.selected;
		}
	}

	this.visualizations = [];
	
	if (queryObject.hasOwnProperty("MapTool")) {
		if(queryObject.MapTool.enabled) {
			this.keyType = queryObject.MapTool.geometryLayer.keyType;
			this.visualizations.push(
					{
						type : "MapTool",
						parameters : queryObject.MapTool.geometryLayer,
						title : queryObject.MapTool.title,
						enableTitle : queryObject.MapTool.enableTitle,
						labelLayer : queryObject.MapTool.labelLayer
					}
			);
		}
	}	
	
	if (queryObject.hasOwnProperty("ScatterPlotTool")) {
		if(queryObject.ScatterPlotTool.enabled) {
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
		if(queryObject.BarChartTool.enabled) {
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
			var colNames= [];
			console.log("queryObject.dataTable.columns", queryObject.dataTable.columns);
			for(i in queryObject.dataTable.columns){
				colNames[i] = queryObject.dataTableTool.columns[i].param;
				console.log("columns", colNames[i]);
			}
			
			this.visualizations.push(
					{
						type : "DataTable",
						parameters : colNames
					}
			);
			console.log("columnNames", columns);
		}
	}
	
	this.currentVisualizations = {};
	console.log("query", angular.toJson(this.queryObject));
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
		newWeaveWindow.log("Running Query...");
	};

	aws.queryService(computationServiceURL, 'runScript', [this.rRequestObject.scriptName, this.rRequestObject.inputs, this.rRequestObject.filters], function(result){	

		newWeaveWindow.log("Load Time : " + result.times[0]/1000 + " secs,  Analysis Time: " + result.times[1]/1000 + " secs");
		newWeaveWindow.workOnData(that, result.data);

	});
};

aws.QueryHandler.prototype.clearSessionState = function () {
	//$("#LogBox").html('');
	if(newWeaveWindow) {
		//newWeaveWindow.clearWeave(this);
		console.log("reached query handler");
		newWeaveWindow.clearSessionState();
	}
};

aws.QueryHandler.prototype.updateVisualizations = function(queryObject) {
	this.visualizations = [];
	
	if(queryObject.hasOwnProperty("ColorColumn")) {
		if(queryObject.ColorColumn.enabled == true) {
			this.ColorColumn = queryObject.ColorColumn.selected;
		}
	}

	if (queryObject.hasOwnProperty("MapTool")) {
		if(queryObject.MapTool.enabled == true) {
			this.keyType = queryObject.MapTool.keyType;
			this.visualizations.push(
					{
						type : "MapTool",
						parameters : queryObject.MapTool.selected,
						title : queryObject.MapTool.title,
						enableTitle : queryObject.MapTool.enableTitle,
						labelLayer : queryObject.MapTool.labelLayer
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
