/* This code assumes that WeavePath.js has already been loaded. */
/* "use strict"; */

var checkType = weave.evaluateExpression(null, "(o, type) => o is type");

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
	
	if (!checkType(this, 'weave.ui.DraggablePanel'))
		this._failMessage('requestPanel', type + " is not a DraggablePanel type.", this._path);
	
	if (!usePixelValues)
	{
		x = x + '%';
		y = y + '%';
		width = width + '%';
		height = height + '%';
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
 * @param plotterName (Optional) The name of an existing or new plotter. If omitted, the default plotter name ("plot") will be used.
 * @param plotterType (Optional) The type of plotter to request if it doesn't exist yet.
 */
weave.WeavePath.prototype.pushPlotter = function(plotterName, plotterType)
{
	if (!checkType(this, 'weave.visualization.tools.SimpleVisTool'))
		this._failMessage('pushPlotter', "Not a compatible visualization tool", this._path);
	
    var path = this.push('children', 'visualization', 'plotManager', 'plotters', plotterName || 'plot');
    if (plotterType)
        path.request(plotterType);
    return path;
};

/**
 * This is a shortcut for pushing the path to a LayerSettings object from the current path, which should reference a visualization tool.
 * @param plotterName The name of an existing plotter.
 */
weave.WeavePath.prototype.pushLayerSettings = function(plotterName)
{
	if (!checkType(this, 'weave.visualization.tools.SimpleVisTool'))
		this._failMessage('pushPlotter', "Not a compatible visualization tool", this._path);
	
    var path = this.push('children', 'visualization', 'plotManager', 'layerSettings', plotterName || 'plot');
    if (plotterType)
        path.request(plotterType);
    return path;
};
