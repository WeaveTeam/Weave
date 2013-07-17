// This function should have all the function we need to communicate with the Weave Javascript API.

// List of things includes.
// Create a new visualization.
// set the attributes for the visualization.

// each visualization is different, theregore we need a function for each.
// first in the line is map, barchart, scatterplot.

// just on top of my head, the parameters are.

// map: shapes[], colorColumn

// barchart: heights, color

// scatterplot: X, Y, Color

// TODO the color attribute should be global in weave.	
	
/**
 * This function accesses the weave instance and create a new map, regardless of wether or not 
 * there is an existing map
 * 
 * @param {Object} shapes an Array of geometry shapes. // TODO specify the type
 * 
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the key in the weave hashmap.
 */
function newMap(shapes){
	
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
function newScatterPlot(xColumn, yColumn) {
	
}

/**
 * This function accesses the weave instance and create a new bar chart, regardless of wether or not 
 * there is an existing map
 * 
 * @param {Object} shapes an Array of geometry shapes. // TODO specify the type
 * 
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the key in the weave hashmap.
 */
function newBarChart(heights, label, sort) {
	

}

/**
 * This function accesses the weave instance and sets the global color attribute column
 * 
 * @param {Object} shapes an Array of geometry shapes. // TODO specify the type
 * 
 * @return // should return a "pointer" to the visualization, or more precisely
 * 		   // the key in the weave hashmap.
 */
function setColorAttribute(colorColumn) {
	

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
function setPosition(panel, posX, posY) {
	

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
function updateVisualization(panel, update) {
	update(panel);
}
