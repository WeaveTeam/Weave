goog.require('aws.client');
goog.provide('aws.WeaveClient');
	

/**
 * This is the constructor for the weave client class.
 *  we initialize the properties here. 
 * @param {aws.WeaveObject} weave An instance of weave
 * @constructor
 */
aws.WeaveClient = function (weave) {

	// the weave client only has this weave property.
	this.weave = weave;
};

/**
 * This function should be the public function 
 * 
 * @param {Object} visualization. A visualization object containing a title and appropriate parameters.
 * 
 * 
 */
aws.WeaveClient.prototype.newVisualization = function (visualization, dataSourceName) {
	
	var parameters = visualization.parameters;
	var toolName;
	switch(visualization.type) {
		case 'maptool':
			toolName = this.newMap(parameters.weaveEntityId, parameters.title, parameters.keyType);
			this.setPosition(toolName, "0%", "0%");
			break;
		case 'scatterplot':
			toolName = this.newScatterPlot(parameters.xColumnName, parameters.yColumnName, parameters.sizeColumnName, dataSourceName);
			break;
		case 'datatable':
			toolName = this.newDatatable( parameters, dataSourceName);
			this.setPosition(toolName, "50%", "0%");
			break;
		case 'barchart' :
			toolName = this.newBarChart("", "", parameters, dataSourceName);
			this.setPosition(toolName, "0%", "50%");
			break;
		default:
			return;
}
	
};

	
/**
 * This function accesses the weave instance and create a new map, regardless of whether or not 
 * there is an existing map
 * TO DO : figure out which plotter according to geometry and label layer
 * @param {Object} geometry an Array of geometry shapes. // TODO specify the type
 * @param String
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the path in the weave hashmap.
 */
aws.WeaveClient.prototype.newMap = function (entityId, title, keyType){

	var toolName = this.weave.path().getValue('generateUniqueName("MapTool")');
	this.weave.requestObject([toolName], 'MapTool');
	aws.reportTime("New Map added");
	
	
	//state plot layer
	var stateLayerPath = this.weave.path([toolName, 'children','visualization','plotManager','plotters']);
	stateLayerPath.push('statelayer').request('weave.visualization.plotters.GeometryPlotter');
	
	var stPlot = this.weave.path([toolName, 'children','visualization','plotManager','plotters','statelayer','geometryColumn','internalDynamicColumn'])
						   .push('internalObject').request('ReferencedColumn')
						   .push('dynamicColumnReference', null).request('HierarchyColumnReference');
	
	//TODO: setting session state uses brfss projection from WeaveDataSource (hard coded for now)
	stPlot.state('dataSourceName','WeaveDataSource')
		  .state('hierarchyPath', '<attribute keyType="' + keyType + '" weaveEntityId="' + entityId + '" title= "' + title + '" projection="EPSG:2964" dataType="geometry"/>');
	
	return toolName;
};

/**
 * This function accesses the weave instance and create a new scatter plot, regardless of wether or not 
 * there is an existing map
 * 
 * @param {aws.Column} xColumn A column for the X value on the scatter plot. // TODO specify the type
 * @param {aws.Column} yColumn A column for the Y value on the scatter plot. // TODO specify the type
 * @param {aws.Column} sizeColumnName
 * @param {string} csvDataSource
 * TODO add more parameters (optionals) for the scatterplot. e.g. point size, regression...
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the key in the weave hashmap.
 */
aws.WeaveClient.prototype.newScatterPlot = function (xColumnName, yColumnName, sizeColumnName, csvDataSource) {

	var toolName = this.weave.path().getValue('generateUniqueName("ScatterPlotTool")');//returns a string
	this.weave.requestObject([toolName], 'ScatterPlotTool');
	aws.reportTime("New ScatterPlot added");
	
	var columnPathX = [toolName,'children','visualization', 'plotManager','plotters','plot','dataX'] ;
	var columnPathY = [toolName,'children','visualization', 'plotManager','plotters','plot','dataY'] ;
	
	this.setCSVColumn(csvDataSource,columnPathX, xColumnName );//setting the X column
	this.setCSVColumn(csvDataSource, columnPathY, yColumnName );//setting the Y column
	
	//aws.WeaveClient.prototype.setColorAttribute(colorColumnName,);// TO DO: use setCSVColumn directly?
	
	return toolName;
};

/**
 * 
 * @param columnNames array of columns to put in the table
 * @param dataSource name of datasource to pull data from
 */
aws.WeaveClient.prototype.newDatatable = function(columnNames, dataSource){
	var toolName = this.weave.path().getValue('generateUniqueName("DataTableTool")');//returns a string
	this.weave.requestObject([toolName], 'DataTableTool');
	
	//to do loop through the columns requested
	
	for (var i = 0; i < columnNames.length; i++)
		{
			this.setCSVColumn(dataSource, [toolName,'columns',columnNames[i]], columnNames[i]);
			
		}
	return toolName;
};

/**
 * This function accesses the weave instance and create a new bar chart, regardless of wether or not 
 * there is an existing map
 * 
 * @param {aws.Column} label the column used for label. // TODO specify the type
 * @param {aws.Column} sort the column used for sort
 * @param {Array.<aws.Column>} and array of columns
 * @param {string} name of the datasource to pick columns from
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the key in the weave hashmap.
 */
aws.WeaveClient.prototype.newBarChart = function (label, sort, heights, dataSourceName) {
	
	var toolName = this.weave.path().getValue('generateUniqueName("CompoundBarChartTool")');//returns a string
	this.weave.requestObject([toolName], 'CompoundBarChartTool');
	
	//setting the label column
	var labelPath = this.weave.path([toolName, 'children','visualization', 'plotManager','plotters', 'plot']);
	labelPath.push('labelColumn', null).request('ReferencedColumn').push('dynamicColumnReference', null).request('HierarchyColumnReference')
		   .state('dataSourceName', dataSourceName)
		   .state('hierarchyPath', label);
		   
    var sortColumnPath = this.weave.path([toolName, 'children','visualization', 'plotManager','plotters', 'plot']);
    sortColumnPath.push('labelColumn', null).request('ReferencedColumn').push('dynamicColumnReference', null).request('HierarchyColumnReference')
	   			  .state('dataSourceName', dataSourceName)
	   			  .state('hierarchyPath', sort);
	
    
    for (var i in heights)
	{
		this.setCSVColumn(dataSourceName, [toolName,'children', 'visualization', 'plotManager', 'plotters', 'plot', 'heightColumns', heights[i]], heights[i]);
		
	}
	return toolName;
};



/**
 * This function accesses the weave instance and sets the position of a given visualization
 * If there is no such panel on the screen, nothing happens.
 * 
 * @param {string} panel the name of the panel on the Dashboard. // TODO specify the type
 * @param {number} posX the new X position of the panel.
 * @param {number} posY the new Y position of the panel.
 * 
 * @return void
 * 
 */
aws.WeaveClient.prototype.setPosition = function (toolName, posX, posY) {
	this.weave.path(toolName).push('panelX').state(posX).pop().push('panelY').state(posY);
};

/**
 * This function accesses the weave instance and sets the position of a given visualization
 * If there is no such panel on the screen, nothing happens.
 * 
 * @param {string} panel the name of the panel on the Dashboard. // TODO specify the type
 * @param {function(panel:string):void} callback function that performs the wanted updates.
 *
 * @return void
 * TODO // is this function necessary??
 */
aws.WeaveClient.prototype.updateVisualization = function(weave, panel, update) {
	update(panel);
};

/**
 * This function accesses the weave instance and creates a new data source.
 * 
 * @param {Array.Array.<string>} dataSource CSV data source // TODO specify the type
 *
 * @return void
 * 
 */
aws.WeaveClient.prototype.addCSVDataSourceFromString = function (dataSource, dataSourceName, keyType, keyColName) {
	
	if (dataSourceName == "") {
		 dataSourceName = this.weave.path().getValue('generateUniqueName("CSVDataSource")');
	}

	this.weave.path(dataSourceName)
		.request('CSVDataSource')
		.vars({data: dataSource})
		.exec('setCSVDataString(data)');
		this.weave.path(dataSourceName).state('keyType', keyType);
		this.weave.path(dataSourceName).state('keyColName', keyColName);
	
	return dataSourceName;
	
};


/**
 * This function sets the session state of a colwumn from another in the Weava instance
 * @param {string}csvDataSourceName CSV Datasource to choose column from
 * @param {string}columnPath relative path of the column
 * @param {string}columnName name of the column
 * @return void
 */
aws.WeaveClient.prototype.setCSVColumn = function (csvDataSourceName, columnPath, columnName){
	this.weave.path(csvDataSourceName)
			  .vars({i:columnName, p:columnPath})
			  .exec('putColumn(i,p)');
};

/**
 * This function accesses the weave instance and sets the global color attribute column
 * 
 * @param {string} colorColumnName
 * @param {string}csvDataSource // TODO specify the type
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
		this.weave.path(dataSourceName).request('CSVDataSource')
		 .vars({data: dataSource})
		 .exec('setCSVData(data)');
	}	
		
};

/**
 * this function can be added as a callback to any visualization to get a log of time for every interaction involving that tool
 * @param {Object} pointer to the Weave instance
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
