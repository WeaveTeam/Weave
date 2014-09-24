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
 * @return The current WeavePath object.
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
 * @param plotterName (Optional) The name of an existing or new plotter.
 *                    If omitted, the default plotter name ("plot") will be used.
 * @param plotterType (Optional) The type of plotter to request if it doesn't exist yet.
 * @return A new WeavePath object which remembers the current WeavePath as its parent.
 */
weave.WeavePath.prototype.pushPlotter = function(plotterName, plotterType)
{
	var tool = this.weave.path(this._path[0]);
	if (!checkType(tool, 'weave.visualization.tools.SimpleVisTool'))
		this._failMessage('pushLayerSettings', "Not a compatible visualization tool", this._path);
	
	if (!plotterName)
		plotterName = checkType(this, 'weave.visualization.layers.LayerSettings') ? this._path[this._path.length - 1] : 'plot';
	
	var result = tool.push('children', 'visualization', 'plotManager', 'plotters', plotterName);
	result._parent = this;
    if (plotterType)
        result.request(plotterType);
    return result;
};

/**
 * This is a shortcut for pushing the path to a LayerSettings object from the current path, which should reference a visualization tool.
 * @param plotterName (Optional) The name of an existing plotter.
 *                    If omitted, either the plotter at the current path or the default plotter ("plot") will be used.
 * @return A new WeavePath object which remembers the current WeavePath as its parent.
 */
weave.WeavePath.prototype.pushLayerSettings = function(plotterName)
{
	var tool = this.weave.path(this._path[0]);
	if (!checkType(tool, 'weave.visualization.tools.SimpleVisTool'))
		this._failMessage('pushLayerSettings', "Not a compatible visualization tool", this._path);
	
	if (!plotterName)
		plotterName = checkType(this, 'weave.api.ui.IPlotter') ? this._path[this._path.length - 1] : 'plot';
	
	var result = tool.push('children', 'visualization', 'plotManager', 'layerSettings', plotterName);
	result._parent = this;
	return result;
};
