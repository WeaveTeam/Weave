goog.require('aws.client');

goog.provide('aws.Client.WeaveClient');
	
/**
 * This is the constructor for the weave client class.
 *  we initialize the properties here. 
 * @param {aws.WeaveObject} weave An instance of weave
 * @constructor
 */
aws.Client.WeaveClient = function (weave) {

	// the weave client only has this weave property.
	this.weave = weave;
}

	
/**
 * This function accesses the weave instance and create a new map, regardless of wether or not 
 * there is an existing map
 * 
 * @param {Object} shapes an Array of geometry shapes. // TODO specify the type
 * 
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the path in the weave hashmap.
 */
aws.Client.WeaveClient.prototype.newMap = function (shapes){
	this.weave.path().exec('generateUniqueName("MapTool"), this.uniqueName');
	this.weave.requestObject([this.weave.path().getValue(this.uniqueName)], 'MapTool');
	return this.weave.path().getValue(this.uniqueName);
}

/**
 * This function accesses the weave instance and create a new scatter plot, regardless of wether or not 
 * there is an existing map
 * 
 * @param {aws.Column} xColumn A column for the X value on the scatter plot. // TODO specify the type
 * @param {aws.Column} yColumn A column for the Y value on the scatter plot. // TODO specify the type
 * 
 * TODO add more parameters (optionals) for the scatterplot. e.g. point size, regression...
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the key in the weave hashmap.
 */
aws.Client.WeaveClient.prototype.newScatterPlot = function (xColumn, yColumn) {

	this.weave.requestObject([this.weave.path().getValue('generateUniqueName("ScatterPlotTool")')], 'ScatterPlotTool');

}

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
aws.Client.WeaveClient.prototype.newBarChart = function (label, sort, heights) {

	this.weave.requestObject([this.weave.path().getValue('generateUniqueName("CompoundBarChartTool")')], 'CompoundBarChartTool');
}

/**
 * This function accesses the weave instance and sets the global color attribute column
 * 
 * @param {aws.WeaveObject} weave An instance of weave
 * @param {aws.Column} colorColumn the column used for the attribute color column. // TODO specify the type
 * 
 * @return void
 */
aws.Client.WeaveClient.prototype.setColorAttribute = function(colorColumn) {
	

}

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
aws.Client.WeaveClient.prototype.setPosition = function (panel, posX, posY) {
	

}

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
aws.Client.WeaveClient.prototype.updateVisualization = function(weave, panel, update) {
	update(panel);
}

/**
 * This function accesses the weave instance and creates a new data source.
 * 
 * @param {Array.Array.<string>} dataSource CSV data source // TODO specify the type
 *
 * @return void
 * 
 */
aws.Client.WeaveClient.prototype.addCSVDataSourceFromString = function (dataSource, dataSourceName) {
	this.weave.path(dataSourceName)
		 .request('CSVDataSource')
		 .vars({data: dataSource})
		 .exec('setCSVDataString(data)');
}

/**
 * This function accesses the weave instance and creates a new data source.
 * 
 * @param {Array.Array.<number>} dataSource CSV data source // TODO specify the type
 *
 * @return void
 * 
 */
aws.Client.WeaveClient.prototype.addCSVDataSourceFromRows = function (weave, dataSource, dataSourceName) {
//	if (dataSourceName == "") {
//		this.weave.path(this.weave.path().getValue('generateUniqueName("CSVDataSource")')).request('CSVDataSource')
//		 .vars({data: dataSource})
//		 .exec('setCSVData(data)');
//	}
//	
//	else {
//		this.weave.path(dataSourceName).request('CSVDataSource')
//		 .vars({data: dataSource})
//		 .exec('setCSVData(data)');
//	}	
		
}
