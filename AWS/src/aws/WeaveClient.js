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
 * @param
 * 
 * 
 */
aws.WeaveClient.prototype.newVisualization(visualization) {
	
	switch(visualization.type) {
		case 'MapTool':
			this.newMap(visualization.geometry);
			break;
		case 'ScatterPlotTool':
			this.newScatterPlot(visualization.xColumnName, visualization.yColumnName, visualization.sizeColumnName, visualization.csvDataSource);
			break;
		case 'DataTableTool':
			this.newDataTable
		default:
			return;
}
	
}

	
/**
 * This function accesses the weave instance and create a new map, regardless of whether or not 
 * there is an existing map
 * TO DO : figure out which plotter according to geometry and label layer
 * @param {Object} geometry an Array of geometry shapes. // TODO specify the type
 * @param String
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the path in the weave hashmap.
 */
aws.WeaveClient.prototype.newMap = function (geometry, geometryDatasource){

	var toolName = [this.weave.path().getValue('generateUniqueName("MapTool")')];
	this.weave.requestObject(toolName, 'MapTool');
	
	
	//state plot layer
	var stateLayerPath = this.weave.path([toolName, 'children','visualization','plotManager','plotters']);
	stateLayerPath.push('statelayer').request('weave.visualization.plotters.GeometryPlotter');
	
	var stPlot = this.weave.path([toolName, 'children','visualization','plotManager','plotters','statelayer','geometryColumn','internalDynamicColumn'])
						   .push('internalObject').request('ReferencedColumn')
						   .push('dynamicCOlumnReference', null).request('HierarchyColumnReference');
	
	//TO DO: setting session state uses brfss projection from WeaveDataSource (hard coded for now)
	stPlot.state('dataSourceName','WeaveDataSource')
		  .state('hierarchyPath', '<attribute keyType="US State FIPS Code" weaveEntityId="162429" title="brfss_state_2010" projection="EPSG:2964" dataType="geometry"/>');
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

	var toolName = [this.weave.path().getValue('generateUniqueName("ScatterPlotTool")')];//returns a string
	this.weave.requestObject([toolName], 'ScatterPlotTool');
	
	var columnPathX = [toolName,'children','visualization', 'plotManager','plotters','plot','dataX'] ;
	var columnPathY = [toolName,'children','visualization', 'plotManager','plotters','plot','dataY'] ;
	
	aws.WeaveClient.setCSVColumn(csvDataSource,columnPathX, xColumnName );//setting the X column
	aws.WeavClient.setCSVColumn(csvDataSource, columnPathY, yColumnName );//setting the Y column
	
	//aws.WeaveClient.prototype.setColorAttribute(colorColumnName,);// TO DO: use setCSVColumn directly?
};

/**
 * 
 * @param {string} columnPath
 * @param columnNames array of columns to put in the table
 * @param dataSource name of datasource to pull data from
 */
aws.WeaveClient.prototype.newDatatableTool = function(columnPath, columnNames, dataSource){
	var toolName = this.weave.path().getValue('generateUniqueName("DataTableTool")');//returns a string
	this.weave.requestObject([toolName], 'DataTableTool');
	
	//to do loop through the columns requested
	
	for (var i = 0; i < columnNames.length; i++)
		{
			aws.WeaveClient.setCSVColumn([toolName,'columns',columnNames[i]], dataSource, columnNames);
			
		}
	
};

/**
 * This function accesses the weave instance and create a new bar chart, regardless of wether or not 
 * there is an existing map
 * 
 * @param {aws.Column} label the column used for label. // TODO specify the type
 * @param {aws.Column} sort the column used for sort
 * @param {Array.<aws.Column>} and array of columns
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the key in the weave hashmap.
 */
aws.WeaveClient.prototype.newBarChart = function (label, sort, heights) {

	this.weave.requestObject([this.weave.path().getValue('generateUniqueName("CompoundBarChartTool")')], 'CompoundBarChartTool');
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
	
	aws.WeaveClient.setCSVColumn(['defaultColorDataColumn', 'internalDynamicColumn'], csvDataSource, colorColumnName);

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
aws.WeaveClient.prototype.setPosition = function (panel, posX, posY) {
	

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
aws.WeaveClient.prototype.addCSVDataSourceFromString = function (dataSource, dataSourceName) {
	this.weave.path(dataSourceName)
		 .request('CSVDataSource')
		 .vars({data: dataSource})
		 .exec('setCSVDataString(data)');
};


/**
 * This function sets the session state of a column from another in the Weava instance
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
 * This function accesses the weave instance and creates a new data source.
 * 
 * @param {Array<number>} dataSource CSV data source // TODO specify the type
 * @param {string} dataSource
 * @param {string} dataSourceName
 * @return void
 * 
 */
aws.WeaveClient.prototype.addCSVDataSource = function (weave, dataSource, dataSourceName) {

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
