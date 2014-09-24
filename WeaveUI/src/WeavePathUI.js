/* This code assumes that WeavePath.js has already been loaded. */
/* "use strict"; */

/**
 * Requests that an panel object be created if it doesn't already exist at the current path.
 * @param type The object type
 * @param panelX The session state for the "panelX" property.
 * @param panelY The session state for the "panelY" property.
 * @param panelWidth The session state for the "panelWidth" property.
 * @param panelHeight The session state for the "panelHeight" property.
 * @param usePixelValues (Optional) Set this to true if the panel coordinates are given in pixels. Otherwise, they are treated as percentage values.
 */
weave.WeavePath.prototype.requestPanel = function(type, panelX, panelY, panelWidth, panelHeight, usePixelValues)
{
	this.request(type);
	
	if (!this.weave.evaluateExpression(this.getPath(), "this is DraggablePanel", null, ['weave.ui.DraggablePanel']))
		this._failMessage('requestPanel', type + " is not a DraggablePanel.", this._path);
	
	if (!usePixelValues)
	{
		panelX = panelX + '%';
		panelY = panelY + '%';
		panelWidth = panelWidth + '%';
		panelHeight = panelHeight + '%';
	}
    return this.state({
        panelX: panelX,
        panelY: panelY,
        panelWidth: panelWidth,
        panelHeight: panelHeight
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
