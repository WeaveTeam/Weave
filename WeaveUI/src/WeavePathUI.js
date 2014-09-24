/* This code assumes that WeavePath.js has already been loaded. */
/* "use strict"; */

/**
 * Requests that an panel object be created if it doesn't already exist at the current path.
 * @param type The type of panel requested.
 * @param x A numeric value for the panel X coordinate.
 * @param y A numeric value for the panel Y coordinate.
 * @param width A numeric value for the panel width.
 * @param height A numeric value for the panel height.
 * @param usePixelValues (Optional) Set this to true if the panel coordinates are given in pixels. Otherwise, they are treated as percentage values.
 */
weave.WeavePath.prototype.requestPanel = function(type, x, y, width, height, usePixelValues)
{
	this.request(type);
	
	if (!this.weave.evaluateExpression(this.getPath(), "this is DraggablePanel", null, ['weave.ui.DraggablePanel']))
		this._failMessage('requestPanel', type + " is not a DraggablePanel type.", this._path);
	
	if (!usePixelValues)
	{
		panelX = x + '%';
		panelY = y + '%';
		panelWidth = width + '%';
		panelHeight = height + '%';
	}
    return this.state({
        panelX: x,
        panelY: y,
        panelWidth: width,
        panelHeight: height
    });
};

/**
 * This is a shortcut for pushing the path to a plotter from the current path, which should reference a visualization tool.
 * @param plotterName The name of an existing or new plotter.
 * @param plotterType (Optional) The type of plotter to request if it doesn't exist yet.
 */
weave.WeavePath.prototype.pushPlotter = function(plotterName, plotterType)
{
    var path = this.push('children', 'visualization', 'plotManager', 'plotters', plotterName || 'plot');
    if (plotterType)
        path.request(plotterType);
    return path;
};
