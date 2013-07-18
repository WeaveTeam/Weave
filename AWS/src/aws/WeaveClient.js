goog.require('aws.client');

goog.provide('aws.Client.WeaveClient');
	
/**
 * This is the constructor for the weave client class.
 * we initialize the properties here. 
 * 
 * @constructor
 */
aws.Client.WeaveClient = function () {
	
	this.uniqueName = "";

}

	
/**
 * This function accesses the weave instance and create a new map, regardless of wether or not 
 * there is an existing map
 * 
 * @oaram {aws.WeaveObject} weave An instance of weave
 * @param {Object} shapes an Array of geometry shapes. // TODO specify the type
 * 
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the path in the weave hashmap.
 */
aws.Client.WeaveClient.prototype.newMap = function (weave, shapes){
	weave.path().exec('generateUniqueName("MapTool"), this.uniqueName');
	weave.requestObject([weave.path().getValue(this.uniqueName)], 'MapTool');
	return weave.path().getValue(this.uniqueName);
}

/**
 * This function accesses the weave instance and create a new scatter plot, regardless of wether or not 
 * there is an existing map
 * 
 * @param {aws.WeaveObject} weave An instance of weave
 * @param {aws.Column} xColumn A column for the X value on the scatter plot. // TODO specify the type
 * @param {aws.Column} yColumn A column for the Y value on the scatter plot. // TODO specify the type
 * 
 * TODO add more parameters (optionals) for the scatterplot. e.g. point size, regression...
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the key in the weave hashmap.
 */
aws.Client.WeaveClient.prototype.newScatterPlot = function (weave, xColumn, yColumn) {
	weave.path().exec('generateUniqueName("ScatterPlotTool", this.uniqueName)');
	weave.requestObject([weave.path().getValue(this.uniqueName)], 'ScatterPlotTool');
}

/**
 * This function accesses the weave instance and create a new bar chart, regardless of wether or not 
 * there is an existing map
 * 
 * @param {aws.WeaveObject} weave An instance of weave
 * @param {aws.Column} label the column used for label. // TODO specify the type
 * @param {aws.Column} sort the column used for sort
 * @param {Array.<aws.Column>} and array of columns
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the key in the weave hashmap.
 */
aws.Client.WeaveClient.prototype.newBarChart = function (weave, label, sort, heights) {
	weave.path().exec('generateUniqueName("CompoundBarChartTool", this.uniqueName)');
	weave.requestObject([weave.path().getValue(this.uniqueName)], 'CompoundBarChartTool');
}

/**
 * This function accesses the weave instance and sets the global color attribute column
 * 
 * @param {aws.WeaveObject} weave An instance of weave
 * @param {aws.Column} colorColumn the column used for the attribute color column. // TODO specify the type
 * 
 * @return void
 */
aws.Client.WeaveClient.prototype.setColorAttribute = function(weave, colorColumn) {
	

}

/**
 * This function accesses the weave instance and sets the position of a given visualization
 * If there is no such panel on the screen, nothing happens.
 * 
 * @param {aws.WeaveObject} weave An instance of weave
 * @param {string} panel the name of the panel on the Dashboard. // TODO specify the type
 * @param {number} posX the new X position of the panel.
 * @param {number} posY the new Y position of the panel.
 * 
 * @return void
 * 
 */
aws.Client.WeaveClient.prototype.setPosition = function (weave, panel, posX, posY) {
	

}

/**
 * This function accesses the weave instance and sets the position of a given visualization
 * If there is no such panel on the screen, nothing happens.
 * 
 * @param {aws.WeaveObject} weave An instance of weave
 * @param {string} panel the name of the panel on the Dashboard. // TODO specify the type
 * @param {function(panel:string):void} callback function that performs the wanted updates.
 *
 * @return void
 * TODO // is this function necessary??
 */
aws.Cient.WeaveClient.prototype.updateVisualization = function(weave, panel, update) {
	update(panel);
}

/**
 * This function accesses the weave instance and creates a new data source.
 * 
 * @param {aws.WeaveObject} weave An instance of weave
 * @param {Array.Array.<string>} dataSource CSV data source // TODO specify the type
 *
 * @return void
 * 
 */
aws.Client.WeaveClient.prototype.addCSVDataSourceFromString = function (weave, dataSource, dataSourceName) {
	weave.path(dataSourceName)
		 .request('CSVDataSource')
		 .vars({data: dataSource})
		 .exec('setCSVDataString(data)');
}

/**
 * This function accesses the weave instance and creates a new data source.
 * 
 * @param {aws.WeaveObject} weave An instance of weave
 * @param {Array.Array.<number>} dataSource CSV data source // TODO specify the type
 *
 * @return void
 * 
 */
aws.Client.WeaveClient.prototype.addCSVDataSourceFromRows = function (weave, dataSource, dataSourceName) {
	if (dataSourceName == "") {
		weave.path().exec('generateUniqueName("CSVDataSource"), this.uniqueName');
		weave.path(weave.path().getValue(this.uniqueName)).request('CSVDataSource')
		 .vars({data: dataSource})
		 .exec('setCSVData(data)');
	}
	
	else {
		weave.path(dataSourceName).request('CSVDataSource')
		 .vars({data: dataSource})
		 .exec('setCSVData(data)');
	}	
		
}
