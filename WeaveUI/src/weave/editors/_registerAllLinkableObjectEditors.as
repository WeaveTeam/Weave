/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/
package weave.editors
{
	import weave.WeaveProperties;
	import weave.data.DataSources.CSVDataSource;
	import weave.data.DataSources.DBFDataSource;
	import weave.data.DataSources.WFSDataSource;
	import weave.data.DataSources.WeaveDataSource;
	import weave.data.DataSources.XLSDataSource;
	import weave.ui.settings.WeavePropertiesEditor;
	import weave.utils.EditorManager;
	import weave.visualization.plotters.AxisLabelPlotter;
	import weave.visualization.plotters.GeometryLabelPlotter;
	import weave.visualization.plotters.GeometryPlotter;
	import weave.visualization.plotters.GridLinePlotter;
	import weave.visualization.plotters.WMSPlotter;

	/**
	 * This is a temporary solution until Weave has a plugin architecture that initializes all classes automatically.
	 * When we have such a plugin architecture, each editor can register itself.
	 */	
	public function _registerAllLinkableObjectEditors():void
	{
		EditorManager.registerEditor(WeaveProperties, WeavePropertiesEditor);
		
		EditorManager.registerEditor(WeaveDataSource, WeaveDataSourceEditor);
		EditorManager.registerEditor(WFSDataSource, WFSDataSourceEditor);
		EditorManager.registerEditor(XLSDataSource, XLSDataSourceEditor);
		EditorManager.registerEditor(DBFDataSource, DBFDataSourceEditor);
		EditorManager.registerEditor(CSVDataSource, CSVDataSourceEditor);
		
		EditorManager.registerEditor(GeometryLabelPlotter, GeometryLabelPlotterEditor);
		EditorManager.registerEditor(GeometryPlotter, GeometryPlotterEditor);
		EditorManager.registerEditor(WMSPlotter, WMSPlotterEditor);
		EditorManager.registerEditor(GridLinePlotter, GridLinePlotterEditor);
		EditorManager.registerEditor(AxisLabelPlotter, AxisLabelPlotterEditor);
	}
}
