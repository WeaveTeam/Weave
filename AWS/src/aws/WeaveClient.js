goog.require('aws');
goog.provide('aws.WeaveClient');
	

/**
 * This is the constructor for the weave client class.
 *  we initialize the properties here. 
 * @param {Weave} weave An instance of weave
 * @constructor
 */
aws.WeaveClient = function (weave) {

	// the weave client only has this weave property.
	/** @type {Weave} */
	this.weave = weave;
};

/**
 * This function should be the public function 
 * 
 * @param {string} dataSourceName The name of the data source where the data will come from.
 * 
 */
aws.WeaveClient.prototype.newVisualization = function (visualization, dataSourceName) {
	
	
	var parameters = visualization["parameters"];
	var toolName;
	switch(visualization.type) {
		case 'maptool':
			toolName = this.newMap(parameters["weaveEntityId"], parameters["title"], parameters["keyType"]);
			this.setPosition(toolName, "0%", "0%");
			break;
		case 'scatterplot':
			toolName = this.newScatterPlot(parameters["xColumnName"], parameters["yColumnName"], dataSourceName);
			break;
		case 'datatable':
			toolName = this.newDatatable(parameters, dataSourceName);
			this.setPosition(toolName, "50%", "0%");
			break;
		case 'barchart' :
			toolName = this.newBarChart(parameters["sort"], parameters["label"], parameters["height"], dataSourceName);
			this.setPosition(toolName, "0%", "50%");
			break;
		default:
			return;
}
	
};

	
/**
 * This function accesses the weave instance and create a new map, regardless of whether or not 
 * there is an existing map
 * TODO : add projection parameter and dataType parameters, as well as a layer parameter.
 * @param {number} entityId The entityId of the geometry column.
 * @param {string} title the Title for the datasource
 * @param {string} keyType the weave keyType
 * @return {string} The name of the MapTool that was created. Visualizations are created at the root of the HashMap.
 * 		   
 */
aws.WeaveClient.prototype.newMap = function (entityId, title, keyType){

	/** @type {string} */
	var toolName = this.weave.path().getValue('generateUniqueName("MapTool")');
	
	this.weave.requestObject([toolName], 'MapTool');
	aws.reportTime("New Map added");


	//state plot layer
	/** @type {WeavePath} */
	var stPlot = this.weave.path([toolName, 'children','visualization','plotManager','plotters','statelayer','geometryColumn','internalDynamicColumn'])
						   .push('internalObject').request('ReferencedColumn')
						   .push('dynamicColumnReference', null).request('HierarchyColumnReference');

	//TODO: setting session state uses brfss projection from WeaveDataSource (hard coded for now)
	stPlot.state({dataSourceName :"WeaveDataSource",
		  		  hierarchyPath : '<attribute keyType="' + keyType + '" weaveEntityId="' + entityId + '" title= "' + title + '" projection="EPSG:2964" dataType="geometry"/>'});
	
	//labellayer

	return toolName;
};

/**
 * This function accesses the weave instance and create a new scatter plot, regardless of wether or not 
 * there is an existing scatter plot.
 * 
 * @param {string} xColumnName A column for the X value on the scatter plot.
 * @param {string} yColumnName A column for the Y value on the scatter plot.
 * @param {string} dataSourceName
 *
 * @return The name of the created map.
 * 		  
 */
aws.WeaveClient.prototype.newScatterPlot = function (xColumnName, yColumnName, dataSourceName) {
	
	/** @type {string} */
	var toolName = this.weave.path().getValue('generateUniqueName("ScatterPlotTool")');//returns a string
	this.weave.requestObject([toolName], 'ScatterPlotTool');
	aws.reportTime("New ScatterPlot added");
	
	var columnPathX = [toolName,'children','visualization', 'plotManager','plotters','plot','dataX'] ;
	var columnPathY = [toolName,'children','visualization', 'plotManager','plotters','plot','dataY'] ;
	
	this.setCSVColumn(dataSourceName,columnPathX, xColumnName );//setting the X column
	this.setCSVColumn(dataSourceName, columnPathY, yColumnName );//setting the Y column
	
	return toolName;
};

/**
 * This function accesses the weave instance and create a new data table, regardless of wether or not
 * there is an existing data table.
 * 
 * @param {Array.<string>} columnNames Array of columns to put in the table
 * @param {string} dataSourceName the name of datasource to pull data from
 * 
 * @return The name of the created data table.
 */
aws.WeaveClient.prototype.newDatatable = function(columnNames, dataSourceName){

	var toolName = this.weave.path().getValue('generateUniqueName("DataTableTool")');//returns a string
	this.weave.requestObject([toolName], 'DataTableTool');
	
	//loop through the columns requested
	for (var i in columnNames)
		{
			this.setCSVColumn(dataSourceName, [toolName,'columns',columnNames[i]], columnNames[i]);
			
		}
	return toolName;
};

/**
 * This function accesses the weave instance and create a new bar chart, regardless of wether or not 
 * there is an existing bar chart.
 * 
 * @param {string} label the column name used for label.
 * @param {string} sort a column name used for the barchart sort column.
 * @param {Array.<string>} heights an array of heights columns used for the barchart heights.
 * @param {string} dataSourceName name of the datasource to pick columns from
 * @return the name of the created bar chart.
 * 		   
 */
aws.WeaveClient.prototype.newBarChart = function (label, sort, heights, dataSourceName) {
	
	var toolName = this.weave.path().getValue('generateUniqueName("CompoundBarChartTool")');//returns a string
	this.weave.requestObject([toolName], 'CompoundBarChartTool');
	
	//setting the label column
	var labelPath = this.weave.path([toolName, 'children','visualization', 'plotManager','plotters', 'plot']);
	labelPath.push('labelColumn', null).request('ReferencedColumn').push('dynamicColumnReference', null).request('HierarchyColumnReference')
		   .state({dataSourceName : dataSourceName,
				   hierarchyPath : label});
		   
    var sortColumnPath = this.weave.path([toolName, 'children','visualization', 'plotManager','plotters', 'plot']);
    sortColumnPath.push('labelColumn', null).request('ReferencedColumn').push('dynamicColumnReference', null).request('HierarchyColumnReference')
	   			  .state({dataSourceName : dataSourceName,
	   				  	  hierarchyPath : sort});
    
    // We clear the content of height columns before setting a new one.
    var heightPath = this.weave.path([toolName, 'children', 'visualization', 'plotManager', 'plotters', 'plot', 'heightColumns'])
    						   .state(null);
    
    for (var i in heights)
	{
		this.setCSVColumn(dataSourceName, [toolName,'children', 'visualization', 'plotManager', 'plotters', 'plot', 'heightColumns', heights[i]], heights[i]);
	}
	return toolName;
};



/**
 * This function accesses the weave instance and sets the position of a given visualization
 * If there is no such panel the behavior is unknown.
 * 
 * @param {string} toolName the name of the tool.
 * @param {string} posX the new X position of the panel in percent form.
 * @param {string} posY the new Y position of the panel in percent form.
 * 
 * @return void
 * 
 */
aws.WeaveClient.prototype.setPosition = function (toolName, posX, posY) {
	
	this.weave.path([toolName]).push('panelX').state(posX).pop().push('panelY').state(posY);
};

/**
 * This function right now is meant to extend the capabilities of the weave client at runtime
 * it will update a given visualization using the provided call back function
 * 
 * @param {string} toolName the name of the tool.
 *
 * @return void
 * TODO // is this function necessary??
 */
aws.WeaveClient.prototype.updateVisualization = function(toolName, update) {
	update(toolName);
};

/**
 * This function accesses the weave instance and creates a new csv data source from string.
 * 
 * @param {string} csvDataString CSV data source in string format.
 * @param {string} dataSourceName the name of the data source.
 * @param {string} keyType the key type
 * @param {string} keyColName the key column name
 * @return The name of the created data source.
 * 
 */
aws.WeaveClient.prototype.addCSVDataSourceFromString = function (csvDataString, dataSourceName, keyType, keyColName) {
	
	if (dataSourceName == "") {
		 dataSourceName = this.weave.path().getValue('generateUniqueName("CSVDataSource")');
	}

	this.weave.path(dataSourceName)
		.request('CSVDataSource')
		.vars({data: csvDataString})
		.exec('setCSVDataString(data)');
		this.weave.path(dataSourceName).state({keyType : keyType,
											  keyColName : keyColName});
	
	return dataSourceName;
	
};


/**
 * This function sets the session state of a column from another in the Weava instance
 * @param {string} csvDataSourceName CSV Datasource to choose column from
 * @param {WeavePathArray} columnPath relative path of the column
 * @param {string} columnName name of the column
 * @return void
 */
aws.WeaveClient.prototype.setCSVColumn = function (csvDataSourceName, columnPath, columnName){
	this.weave.path([csvDataSourceName])
			  .vars({i:columnName, p:columnPath})
			  .exec('putColumn(i,p)');
};

/**
 * This function accesses the weave instance and sets the global color attribute column
 * 
 * @param {string} colorColumnName
 * @param {string} csvDataSource // TODO specify the type
 * 
 * @return void
 */
aws.WeaveClient.prototype.setColorAttribute = function(colorColumnName, csvDataSource) {
	
	this.setCSVColumn(csvDataSource,['defaultColorDataColumn', 'internalDynamicColumn'], colorColumnName);
};

/**
 * This function accesses the weave instance and creates a new data source.
 * 
 * @param {string} dataSource
 * @param {string} dataSourceName
 * @return void
 * 
 */
aws.WeaveClient.prototype.addCSVDataSource = function (dataSource, dataSourceName) {

	if (dataSourceName == "") {
		this.weave.path(this.weave.path().getValue('generateUniqueName("CSVDataSource")')).request('CSVDataSource')
		 .vars({data: dataSource})
		 .exec('setCSVData(data)');
	}
	
	else {
		this.weave.path([dataSourceName]).request('CSVDataSource')
		 .vars({data: dataSource})
		 .exec('setCSVData(data)');
	}	
		
};

/**
 * this function can be added as a callback to any visualization to get a log of time for every interaction involving that tool
 * @param {string} message to append; activity to report time for
 * 
 */
aws.WeaveClient.prototype.reportToolInteractionTime = function(message){
	
	var time = aws.reportTime();
	
	this.weave.evaluateExpression([], "WeaveAPI.ProgressIndictor.getNormalizedProgress()", {},['weave.api.WeaveAPI']); 
	
	console.log(time);
	try{
		$("#LogBox").append(time + message + "\n");
	}catch(e){
		//ignore
	}
	
};
