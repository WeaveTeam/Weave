var weave_mod = angular.module('aws.WeaveModule', []);
AnalysisModule.service("WeaveService", function() {
	
	this.weave;
	var ws = this;
	this.weaveWindow;
	this.dataSourceName;
	
	this.columnNames = [];
	
	this.addCSVData = function(csvData) {
		this.dataSourceName = ws.weave.path().getValue('generateUniqueName("CSVDataSource")');
	
		ws.weave.path(this.dataSourceName)
			.request('CSVDataSource')
			.vars({rows: csvData})
			.exec('setCSVData(rows)');
		
		console.log("added CSV", csvData);
	};
	
	// weave path func
	var setCSVColumn = function (columnName, propertyName){
		
		if(ws.weave && ws.weave.path) {
			if(columnName == "" || angular.isUndefined(columnName))
				return;
			this.weave.path(ws.dataSourceName)
				.getValue('putColumn')(columnName, this.push(propertyName).request('DynamicColumn').getPath());

		}
	};
	
	this.BarChartTool =  function (state) {
		var toolName = state.toolName || "BarChartTool";
		
		if(ws.weave && ws.weave.path) {
			if(!state.enabled)
				return ws.weave.path(toolName).remove();
			
			ws.weave.path(toolName)
					.request('CompoundBarChartTool')
					.state({ panelX : "0%", panelY : "50%", panelTitle : state.title, enableTitle : true, showAllLabels : state.showAllLabels })
					.push('children', 'visualization', 'plotManager', 'plotters', 'plot')
						.forEach({sortColumn : state.sort, labelColumn : state.label}, setCSVColumn)
						.forEach(
							{ heightColumns : state.heights, positiveErrorColumns : state.posErr, negativeErrorColumns : state.negErr}, 
							function(heights, name) {
								var child = this.push(name);
								child.getNames().forEach(function(n, i){
									if (!heights || i >= heights.length) child.remove(n);
								});
								child.forEach(heights, setCSVColumn);
							}
						);
		}
	};
	
	
	
	this.MapTool = function(state){
		var toolName = state.toolName || "MapTool";
		
		if(ws.weave && ws.weave.path) {
			if(!state.enabled)
				return ws.weave.path(toolName).remove();
			ws.weave.path(toolName).request('MapTool')
			.state({ panelX : "0%", panelY : "0%", panelTitle : state.title, enableTitle : true });
			//TODO get this checked and see if done correctly
			if(state.geometryLayer)
			{
				console.log("sate", state);
				var geometry = JSON.parse(state.geometryLayer);
				ws.weave.path(toolName).request('MapTool')
				.push('children', 'visualization', 'plotManager', 'plotters')
				.push('statelayer').request('weave.visualization.plotters.GeometryPlotter')
				.push('line', 'color', 'defaultValue').state('0').pop()
				.push('geometryColumn', 'internalDynamicColumn', null).request('ReferencedColumn')
				.push('dataSourceName').state('WeaveDataSource').pop()
				.push('metadata').state({
					"keyType": geometry.keyType,
					"title": geometry.title,
					"entityType": "column",
					"weaveEntityId": geometry.id,
					"projection": "EPSG:4326",
					"dataType": "geometry"
				});
				//TODO parameterize setting the keytype and keyColName
				if(state.useKeyTypeForCSV)
				{
					ws.weave.setSessionState(["CSVDataSource"], {"keyType" : geometry.keyType});
				}
				
			}
			
			if(state.labelLayer)
			{
				ws.weave.path(toolName).request('MapTool')
				.push('children', 'visualization', 'plotManager','plotters')
				.push('stateLabellayer').request('weave.visualization.plotters.GeometryLabelPlotter')
				.push('geometryColumn', 'internalDynamicColumn', null).request('ReferencedColumn')
				.push('dataSourceName').state('WeaveDataSource').pop()
				.push('metadata').state({
					"keyType": state.geometryLayer.keyType,
					"title": state.geometryLayer.title,
					"entityType": "column",
					"weaveEntityId": state.geometryLayer.id,
					"projection": "EPSG:4326",
					"dataType": "geometry"
				}).pop().pop()
				.push('text', null).request('ReferencedColumn')
				.push('dataSourceName').state(ws.dataSourceName).pop()
				.push('metadata').state({//hard coding the label layer paramterize later
					"csvColumn": state.labelLayer,
					"title": state.labelLayer,
					"keyType": state.geometryLayer.keyType
				});
			}
		}
	};
	
	
	this.ScatterPlotTool = function(state){
		var toolName = state.toolName || "ScatterPlotTool";
		if(ws.weave && ws.weave.path) {
			if(!state.enabled)
				return ws.weave.path(toolName).remove();
			ws.weave.path(toolName).request('ScatterPlotTool')
			.state({ panelX : "50%", panelY : "50%", panelTitle : state.title, enableTitle : true})
			.push('children', 'visualization','plotManager', 'plotters', 'plot')
			.forEach({dataX : state.X, dataY : state.Y}, setCSVColumn);
		}
	};
	
	
	
	this.DataTableTool = function(state){
		var toolName = state.toolName || "DataTableTool";
		
		if(ws.weave && ws.weave.path) {
			if(!state.enabled)
				return ws.weave.path(toolName).remove();
			ws.weave.path(toolName).request('DataTableTool')
			.state({ panelX : "50%", panelY : "0%", panelTitle : state.title, enableTitle : true})
			.forEach(
					{ columns : state.columns}, 
					function(heights, name) {
						var child = this.push(name);
						child.getNames().forEach(function(n, i){
							if (i >= heights.length) child.remove(n);
						});
						child.forEach(heights, setCSVColumn);
					}
			);
		}
	};
	
	
	this.ColorColumn = function(state){
		if(ws.weave && ws.weave.path) {
			console.log(state);
			if(state.column)
			{
				ws.weave.path('defaultColorDataColumn').setColumn(state.column, ws.dataSourceName);
			}
			if(state.showColorLegend)
			{
				ws.weave.path("ColorBinLegendTool").request('ColorBinLegendTool')
				.state({panelX : "80%", panelY : "0%"});
			}
		}
	};
	
	this.keyColumnName = function(keyColumn) {
		if(ws.weave && ws.weave.path) {
			if(keyColumn.name) {
				console.log("before making weave call", keyColumn.name);
				ws.weave.setSessionState(['CSVDataSource'], {keyColName : keyColumn.name});
			}
			else
			{
				if(! angular.isUndefined(ws.weave))
				ws.weave.setSessionState(['CSVDataSource'], {keyColName : "fips"});
			}
		}
	};
	
	this.getSessionState = function()
	{
		return ws.weave.path().getValue("\
		        var e = new 'mx.utils.Base64Encoder'();\
		        e.encodeBytes( Class('weave.Weave').createWeaveFileContent(true) );\
		        return e.drain();\
		    ");
	};
	
	this.setSessionHistory = function(base64encodedstring)
	{
		ws.weave.path()
		.vars({encoded: base64encodedstring})
		.getValue("\
	        var d = new 'mx.utils.Base64Decoder'();\
			var decodedStuff = d.decode(encoded);\
			var decodeBytes =  d.toByteArray();\
	      Class('weave.Weave').loadWeaveFileContent(decodeBytes);\
	    ");
	};
	
	this.clearSessionState = function(){
		ws.weave.path().state(['WeaveDataSource']);
	};
});

//goog.require('aws');
//goog.provide('aws.WeaveClient');
//	
//
///**
// * This is the constructor for the weave client class.
// *  we initialize the properties here. 
// * @param {Weave} weave An instance of weave
// * @constructor
// */
//aws.WeaveClient = function (weave) {
//
//	// the weave client only has this weave property.
//	/** @type {Weave} */
//	ws.weave = weave;
//	
//};
//
///**
// * This function should be the public function 
// * 
// * @param {string} dataSourceName The name of the data source where the data will come from.
// * 
// */
//aws.WeaveClient.prototype.newVisualization = function (visualization, dataSourceName) {
//	
//	var parameters = visualization["parameters"];
//	var toolName;
//	switch(visualization.type) {
//		case 'MapTool':
//			toolName = this.newMap(parameters["id"], parameters["title"], parameters["keyType"], visualization.labelLayer, dataSourceName);
//			this.setPosition(toolName, "0%", "0%");
//			return toolName;
//		case 'ScatterPlotTool':
//			toolName = this.newScatterPlot(parameters["X"], parameters["Y"], dataSourceName);
//			this.setPosition(toolName, "50%", "50%");
//			return toolName;
//		case 'DataTable':
//			toolName = this.newDatatable(parameters, dataSourceName);
//			this.setPosition(toolName, "50%", "0%");
//			return toolName;
//		case 'BarChartTool' :
//			toolName = this.newBarChart(parameters["sort"], parameters["label"], parameters["heights"], dataSourceName);
//			this.setPosition(toolName, "0%", "50%");
//			return toolName;
//		default:
//			return;
//}
//	
//};
//
///**
// * This function should be the public function 
// * 
// * @param {string} dataSourceName The name of the data source where the data will come from.
// * 
// */
//aws.WeaveClient.prototype.updateVisualization = function (visualization, dataSourceName) {
//	
//	var parameters = visualization["parameters"];
//	var toolName;
//	switch(visualization.type) {
//		case 'MapTool':
//			toolName = this.updateMap(visualization.toolName, parameters["id"], parameters["title"], parameters["keyType"],visualization.labelLayer, dataSourceName);
//			this.setPosition(toolName, "0%", "0%");
//			return toolName;
//		case 'ScatterPlotTool':
//			toolName = this.updateScatterPlot(visualization.toolName, parameters["X"], parameters["Y"], dataSourceName);
//			this.setPosition(toolName, "50%", "50%");
//			return toolName;
//		case 'DataTable':
//			toolName = this.updateDatatable(visualization.toolName, parameters, dataSourceName);
//			this.setPosition(toolName, "50%", "0%");
//			return toolName;
//		case 'BarChartTool' :
//			toolName = this.updateBarChart(visualization.toolName, parameters["sort"], parameters["label"], parameters["heights"], dataSourceName);
//			this.setPosition(toolName, "0%", "50%");
//			return toolName;
//		default:
//			return;
//}
//	
//};
//
//aws.WeaveClient.prototype.newMap = function (entityId, title, keyType, labelLayer, dataSourceName){
//
//	var toolName = ws.weave.path().getValue('generateUniqueName("MapTool")');
//  
//	ws.weave.path(toolName).request('MapTool');
//  
//	 ws.weave.path([toolName, 'children', 'visualization', 'plotManager', 'plotters'])
//	  .push('statelayer').request('weave.visualization.plotters.GeometryPlotter')
//	  .push('line', 'color', 'defaultValue').state('0').pop()
//	  .push('geometryColumn', 'internalDynamicColumn', null).request('ReferencedColumn')
//	  .push('dataSourceName').state('WeaveDataSource').pop()
//	  .push('metadata').state({
//	    "keyType": keyType,
//	    "title": title,
//	    "entityType": "column",
//	    "weaveEntityId": entityId,
//	    "projection": "EPSG:4326",
//	    "dataType": "geometry"
//	  }).pop().pop().pop()
//	  .push('stateLabellayer').request('weave.visualization.plotters.GeometryLabelPlotter')
//	  .push('geometryColumn', 'internalDynamicColumn', null).request('ReferencedColumn')
//	  .push('dataSourceName').state('WeaveDataSource').pop()
//	  .push('metadata').state({
//	    "keyType": keyType,
//	    "title": title,
//	    "entityType": "column",
//	    "weaveEntityId": entityId,
//	    "projection": "EPSG:4326",
//	    "dataType": "geometry"
//	  }).pop().pop()
//	  .push('text', null).request('ReferencedColumn')
//	  .push('dataSourceName').state(dataSourceName).pop()
//	  .push('metadata').state({//hard coding the label layer paramterize later
//	    "csvColumn": labelLayer,
//	    "title": labelLayer,
//	    "keyType": keyType
//	  });
//   return toolName;
//};
//
///**
// * This function accesses the weave instance and create a new scatter plot, regardless of wether or not 
// * there is an existing scatter plot.
// * 
// * @param {string} the name of the existing Map in Weave'se session state
// * @param {number} entityId The entityId of the geometry column.
// * @param {string} title the Title for the datasource
// * @param {string} keyType the weave keyType
// * @return {string} The name of the MapTool ws was created. Visualizations are created at the root of the HashMap.
// * 		  
// */
//aws.WeaveClient.prototype.updateMap = function (toolName,entityId, title, keyType, labelLayer, dataSourceName){
//	
//	if(toolName == undefined)
//		 toolName = ws.weave.path().getValue('generateUniqueName("MapTool")');
//	
//	ws.weave.path(toolName).request('MapTool');
//	
//	ws.weave.path([toolName, 'children', 'visualization', 'plotManager', 'plotters'])
//	  .push('statelayer').request('weave.visualization.plotters.GeometryPlotter')
//	  .push('line', 'color', 'defaultValue').state('0').pop()
//	  .push('geometryColumn', 'internalDynamicColumn', null).request('ReferencedColumn')
//	  .push('dataSourceName').state('WeaveDataSource').pop()
//	  .push('metadata').state({
//	    "keyType": keyType,
//	    "title": title,
//	    "entityType": "column",
//	    "weaveEntityId": entityId,
//	    "projection": "EPSG:4326",
//	    "dataType": "geometry"
//	  }).pop().pop().pop()
//	  .push('stateLabellayer').request('weave.visualization.plotters.GeometryLabelPlotter')
//	  .push('geometryColumn', 'internalDynamicColumn', null).request('ReferencedColumn')
//	  .push('dataSourceName').state('WeaveDataSource').pop()
//	  .push('metadata').state({
//	    "keyType": keyType,
//	    "title": title,
//	    "entityType": "column",
//	    "weaveEntityId": entityId,
//	    "projection": "EPSG:4326",
//	    "dataType": "geometry"
//	  }).pop().pop()
//	  .push('text', null).request('ReferencedColumn')
//	  .push('dataSourceName').state(dataSourceName).pop()
//	  .push('metadata').state({//hard coding the label layer paramterize later
//		    "csvColumn": labelLayer,
//		    "title": labelLayer,
//		    "keyType": keyType
//	  });
//
//   return toolName;
//};
//
///**
// * This function accesses the weave instance and create a new scatter plot, regardless of wether or not 
// * there is an existing scatter plot.
// * 
// * @param {string} xColumnName A column for the X value on the scatter plot.
// * @param {string} yColumnName A column for the Y value on the scatter plot.
// * @param {string} dataSourceName
// *
// * @return The name of the created scatterplot.
// * 		  
// */
//aws.WeaveClient.prototype.newScatterPlot = function (xColumnName, yColumnName, dataSourceName) {
//	
//	/** @type {string} */
//	var toolName = ws.weave.path().getValue('generateUniqueName("ScatterPlotTool")');//returns a string
//	
//	ws.weave.path(toolName).request('ScatterPlotTool');
//	
//	var columnPathX = ws.weave.path(toolName,'children','visualization', 'plotManager','plotters','plot','dataX').getPath();
//	var columnPathY = ws.weave.path(toolName,'children','visualization', 'plotManager','plotters','plot','dataY').getPath();
//	
//	this.setCSVColumn(dataSourceName,columnPathX, xColumnName );//setting the X column
//	this.setCSVColumn(dataSourceName, columnPathY, yColumnName );//setting the Y column
//	
//	return toolName;
//};
//
///**
// * This function updates the attributes of an existing scatter plot if there is one, otherwise creates a new Scatterplot
// * 
// * @param {string} toolName name of the tool in Weave's session state
// * @param {string} xColumnName A column for the X value on the scatter plot.
// * @param {string} yColumnName A column for the Y value on the scatter plot.
// * @param {string} dataSourceName
// *
// * @return The name of the scatterplot.
// * 		  
// */
//aws.WeaveClient.prototype.updateScatterPlot = function(toolName, xColumnName, yColumnName, dataSourceName){
//	/** @type {string} */
//	if(toolName == undefined)
//		toolName = ws.weave.path().getValue('generateUniqueName("ScatterPlotTool")');//returns a string
//
//	ws.weave.path(toolName).request('ScatterPlotTool');
//	
//	var columnPathX = ws.weave.path(toolName,'children','visualization', 'plotManager','plotters','plot','dataX').getPath();
//	var columnPathY = ws.weave.path(toolName,'children','visualization', 'plotManager','plotters','plot','dataY').getPath();
//	
//	this.setCSVColumn(dataSourceName,columnPathX, xColumnName );//setting the X column
//	this.setCSVColumn(dataSourceName, columnPathY, yColumnName );//setting the Y column
//	
//	return toolName;
//};
//
///**
// * This function accesses the weave instance and creates a new data table, regardless of whether or not
// * there is an existing data table.
// * 
// * @param {Array.<string>} columnNames Array of columns to put in the table
// * @param {string} dataSourceName the name of datasource to pull data from
// * 
// * @return The name of the created data table.
// */
//aws.WeaveClient.prototype.newDatatable = function(columnNames, dataSourceName){
//	
//	var toolName = ws.weave.path().getValue('generateUniqueName("DataTableTool")');//returns a string
//	//ws.weave.requestObject([toolName], 'DataTableTool');
//	ws.weave.path(toolName).request('DataTableTool');
//	
//	//loop through the columns requested
//	for (var i in columnNames)
//		{
//			var columnPath = ws.weave.path(toolName, 'columns', columnNames[i] ).getPath();
//			this.setCSVColumn(dataSourceName, columnPath, columnNames[i]);
//		}
//	
//	return toolName;
//};
//
///**
// * This function accesses the weave instance and creates a new data table, regardless of whether or not
// * there is an existing data table.
// * 
// * @param {string} toolName name of the tool in Weave's session state
// * @param {Array.<string>} columnNames Array of columns to put in the table
// * @param {string} dataSourceName the name of datasource to pull data from
// * 
// * @return The name of the created data table.
// */
//aws.WeaveClient.prototype.updateDatatable = function(toolName, columnNames, dataSourceName){
//
//	/** @type {string} */
//	if(toolName == undefined)
//		toolName = ws.weave.path().getValue('generateUniqueName("DataTableTool")');//returns a string
//	
//	//ws.weave.requestObject([toolName], 'DataTableTool');
//	ws.weave.path(toolName).request('DataTableTool');
//	
//    ws.weave.path(toolName, 'columns').state(null);
//
//	//loop through the columns requested
//	for (var i in columnNames)
//		{
//			var columnPath = ws.weave.path(toolName, 'columns', columnNames[i] ).getPath();
//			this.setCSVColumn(dataSourceName, columnPath, columnNames[i]);
//			//this.setCSVColumn(dataSourceName, [toolName,'columns',columnNames[i]], columnNames[i]);
//			
//		}
//	
//	return toolName;
//};
//	
///**
// * this function accesses the weave instance and creates a new Radviz tool
// * @param {Array.<string>} columnNames array of columns to be used as dimensional anchors
// * @param {string} dataSourceName the name of the datasource to pull the data from
// * 
// * @return the name of the created Radviz tool
// * 
// */
//
//aws.WeaveClient.prototype.newRadviz = function(columnNames, dataSourceName){
//	var toolName = ws.weave.path().getValue('generateUniqueName("RadVizTool")');//returns a string
//	//ws.weave.requestObject([toolName], 'RadVizTool');
//	ws.weave.path(toolName).request('RadVizTool');
//	
//	//populating the Dimensional Anchors
//	for(var i in columnNames){
//		var columnPath = ws.weave.path(toolName,toolName, 'children', 'visualization','plotManager', 'plotters','plot','columns',columnNames[i] ).getPath();
//		this.setCSVColumn(dataSourceName, columnPath, columnNames[i]);
//	}
//};
//	
///**
// * this function accesses the weave instance and creates a new Radviz tool
// * @param {string} toolName name of the tool in Weave's session state
// * @param {Array.<string>} columnNames array of columns to be used as dimensional anchors
// * @param {string} dataSourceName the name of the datasource to pull the data from
// * 
// * @return the name of the created Radviz tool
// * 
// */
//
//aws.WeaveClient.prototype.updateRadviz = function(toolName, columnNames, dataSourceName){
//	
//	/** @type {string} */
//	if(toolName == undefined)
//		toolName = ws.weave.path().getValue('generateUniqueName("RadVizTool")');//returns a string
//
//	ws.weave.path(toolName).request('RadVizTool');
//	
//	//populating the Dimensional Anchors
//	for(var i in columnNames){
//		var columnPath = ws.weave.path(toolName,toolName, 'children', 'visualization','plotManager', 'plotters','plot','columns',columnNames[i] ).getPath();
//		this.setCSVColumn(dataSourceName, columnPath, columnNames[i]);
//	}
//};
//
///**
// * This function accesses the weave instance and create a new bar chart, regardless of whether or not 
// * there is an existing bar chart.
// * 
// * @param {string} label the column name used for label.
// * @param {string} sort a column name used for the barchart sort column.
// * @param {Array.<string>} heights an array of heights columns used for the barchart heights.
// * @param {string} dataSourceName name of the datasource to pick columns from
// * @return the name of the created bar chart.
// * 		   
// */
//aws.WeaveClient.prototype.newBarChart = function (sort, label, heights, dataSourceName) {
//	var toolName = ws.weave.path().getValue('generateUniqueName("CompoundBarChartTool")');//returns a string
//	
//	ws.weave.path(toolName).request('CompoundBarChartTool');
//
//	var labelPath = ws.weave.path(toolName, 'children','visualization', 'plotManager','plotters', 'plot', 'labelColumn').getPath(); 
//	var sortColumnPath = ws.weave.path(toolName, 'children','visualization', 'plotManager','plotters', 'plot', 'sortColumn').getPath();
//
//	//var heightColumns = heights;
//	
//   	this.setCSVColumn(dataSourceName,labelPath, label);
//    this.setCSVColumn(dataSourceName, sortColumnPath, sort);
//
//    ws.weave.path(toolName, 'children', 'visualization', 'plotManager', 'plotters', 'plot', 'heightColumns').state('null');
//    
//    for (var i in heights)
//	{
//		var heightColumnPath = ws.weave.path(toolName, 'children', 'visualization', 'plotManager', 'plotters', 'plot', 'heightColumns',heights[i]).getPath();
//		this.setCSVColumn(dataSourceName, heightColumnPath, heights[i]);
//	}
//    
//	return toolName;
//};
//
///**
// * This function accesses the weave instance and create a new bar chart, regardless of whether or not 
// * there is an existing bar chart.
// * @param {string} toolName name of the tool in Weave's session state
// * @param {string} label the column name used for label.
// * @param {string} sort a column name used for the barchart sort column.
// * @param {Array.<string>} heights an array of heights columns used for the barchart heights.
// * @param {string} dataSourceName name of the datasource to pick columns from
// * @return the name of the created bar chart.
// * 		   
// */
//aws.WeaveClient.prototype.updateBarChart = function (toolName, sort, label, heights, dataSourceName) {
//	
//	/** @type {string} */
//	if(toolName == undefined)
//		toolName = ws.weave.path().getValue('generateUniqueName("CompoundBarChartTool")');//returns a string
//		ws.weave.path(toolName).request('CompoundBarChartTool');
//
//	var labelPath = ws.weave.path(toolName, 'children','visualization', 'plotManager','plotters', 'plot', 'labelColumn').getPath(); 
//	var sortColumnPath = ws.weave.path(toolName, 'children','visualization', 'plotManager','plotters', 'plot', 'sortColumn').getPath();
//
//	
//   	this.setCSVColumn(dataSourceName,labelPath, label);
//    this.setCSVColumn(dataSourceName, sortColumnPath, sort);
//    
//    ws.weave.path(toolName, 'children', 'visualization', 'plotManager', 'plotters', 'plot', 'heightColumns').state('null');
//
//    for (var i in heights)
//	{
//		var heightColumnPath = ws.weave.path(toolName, 'children', 'visualization', 'plotManager', 'plotters', 'plot', 'heightColumns',heights[i]).getPath();
//		this.setCSVColumn(dataSourceName, heightColumnPath, heights[i]);
//	}
//    
//	return toolName;
//};
//
///**
// * This function accesses the weave instance and sets the position of a given visualization
// * If there is no such panel the behavior is unknown.
// * 
// * @param {string} toolName the name of the tool.
// * @param {string} posX the new X position of the panel in percent form.
// * @param {string} posY the new Y position of the panel in percent form.
// * 
// * @return void
// * 
// */
//aws.WeaveClient.prototype.setPosition = function (toolName, posX, posY) {
//	
//	//ws.weave.path([toolName]).push('panelX').state(posX).pop().push('panelY').state(posY);
//	ws.weave.path(toolName).push('panelX').state(posX).pop().push('panelY').state(posY);
//};
//
//
///**
// * This function accesses the weave instance and creates a new csv data source from string.
// * 
// * 
// * @param {string} csvDataString CSV data source in string format.
// * @param {string} dataSourceName the name of the data source.
// * @param {string} keyType the key type
// * @param {string} keyColName the key column name
// * @return The name of the created data source.
// * 
// */
//aws.WeaveClient.prototype.addCSVDataSourceFromString = function (csvDataString, dataSourceName, keyType, keyColName) {
//	
//	if (dataSourceName == "") {
//		 dataSourceName = ws.weave.path().getValue('generateUniqueName("CSVDataSource")');
//	}
//
//	ws.weave.path(dataSourceName)
//		.request('CSVDataSource')
//		.vars({data: csvDataString})
//		.exec('setCSVDataString(data)');
//		ws.weave.path(dataSourceName).state({keyType : keyType,
//											  keyColName : keyColName});
//	
//	return dataSourceName;
//	
//};
//
///**
// * This function accesses the weave instance and creates a new csv data source from a two dimensional array
// * 
// * @param {Array.<Array>} csvDataMatrix a two dimensional array.
// * @param {string} dataSourceName the name of the data source.
// * @param {string} keyType the key type
// * @param {string} keyColName the key column name
// * @return The name of the created data source.
// * 
// */
//aws.WeaveClient.prototype.addCSVDataSource = function(csvDataMatrix, dataSourceName, keyType, keyColName)
//{
//	if(dataSourceName == ""){
//		dataSourceName = ws.weave.path().getValue('generateUniqueName("CSVDataSource")');
//	}
//
//	ws.weave.path(dataSourceName)
//		.request('CSVDataSource')
//		.vars({rows: csvDataMatrix})
//		.exec('setCSVData(rows)');
//		ws.weave.path(dataSourceName).state({keyType : keyType,
//											   keyColName : keyColName});
//	return dataSourceName;
//	
//};
//
///**
// * This function sets the keyType of the columns in the CSVDataSource
// * 
// * @param {string} keyType
// * @return setStatus
// */
//aws.WeaveClient.prototype.setCSVDataSouceKeyType = function(keyType){
//	ws.weave.path('CSVDataSource').push('keyType').state(keyType);
//};
//
///**
// * This function sets the session state of a column from another in the Weava instance
// * @param {string} csvDataSourceName CSV Datasource to choose column from
// * @param {WeavePathArray} columnPath relative path of the column
// * @param {string} columnName name of the column
// * @return void
// */
//aws.WeaveClient.prototype.setCSVColumn = function (csvDataSourceName, columnPath, columnName){
////	ws.weave.path([csvDataSourceName])
////			  .vars({i:columnName, p:columnPath})
////			  .exec('putColumn(i,p)');
//	
//	ws.weave.path(csvDataSourceName)
//			  .vars({i:columnName, p:columnPath})
//			  .exec('putColumn(i,p)');
//};
//
///**
// * This function accesses the weave instance and sets the global color attribute column
// * 
// * @param {string} colorColumnName
// * @param {string} csvDataSource // TODO specify the type
// * 
// * @return void
// */
//aws.WeaveClient.prototype.setColorAttribute = function(colorColumnName, csvDataSource) {
//	
//	//this.setCSVColumn(csvDataSource,['defaultColorDataColumn', 'internalDynamicColumn'], colorColumnName);
//	var colorPath = ws.weave.path('defaultColorDataColumn', 'internalDynamicColumn').getPath();
//	this.setCSVColumn(csvDataSource, colorPath, colorColumnName);
//	};
//
///**
// * This function accesses the weave instance and sets the title of a visualization tool given the tool name
// * 
// * @param {string} toolName
// * @param {boolean} enableTitle
// * @param {string} title // TODO specify the type
// * 
// * @return void
// */
//aws.WeaveClient.prototype.setVisualizationTitle = function(toolName, enableTitle, title) {
//	
//	ws.weave.path(toolName, 'enableTitle').state(enableTitle);
//	ws.weave.path(toolName, 'panelTitle').state(title);
//	
//};
//
///**
// * This function clears the visualizations before any new query is run
// * it removes everything in the session state EXCEPT for the elements in the array sent as a parameter for setSessionSate()
// * in this case everything except 'WeaveDataSource' will be removed
// * @return void
// */
//aws.WeaveClient.prototype.clearWeave = function(){
//	
//	ws.weave.path().state(['WeaveDataSource']);
//};
//
//
///**
// * this function can be added as a callback to any visualization to get a log of time for every interaction involving ws tool
// * @param {string} message to append; activity to report time for
// * 
// */
//aws.WeaveClient.prototype.reportToolInteractionTime = function(message){
//	
//	var time = aws.reportTime();
//	
//	ws.weave.evaluateExpression([], "WeaveAPI.ProgressIndictor.getNormalizedProgress()", {},['weave.api.WeaveAPI']); 
//	
//	console.log(time);
//	try{
//		$("#LogBox").append(time + message + "\n");
//	}catch(e){
//		//ignore
//	}	
//};
