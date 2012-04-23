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

package
{
	import weave.api.WeaveAPI;
	import weave.api.core.IErrorManager;
	import weave.api.core.IExternalSessionStateInterface;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.IProgressIndicator;
	import weave.api.core.ISessionManager;
	import weave.api.core.IStageUtils;
	import weave.api.data.IAttributeColumnCache;
	import weave.api.data.ICSVParser;
	import weave.api.data.IProjectionManager;
	import weave.api.data.IQualifiedKeyManager;
	import weave.api.data.IStatisticsCache;
	import weave.api.services.IURLRequestUtils;
	import weave.core.ErrorManager;
	import weave.core.ExternalSessionStateInterface;
	import weave.core.LinkableHashMap;
	import weave.core.ProgressIndicator;
	import weave.core.SessionManager;
	import weave.core.SessionStateLog;
	import weave.core.StageUtils;
	import weave.core.WeaveXMLDecoder;
	import weave.data.AttributeColumnCache;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.CSVParser;
	import weave.data.DataSources.CSVDataSource;
	import weave.data.DataSources.DBFDataSource;
	import weave.data.DataSources.WFSDataSource;
	import weave.data.DataSources.WeaveDataSource;
	import weave.data.DataSources.XLSDataSource;
	import weave.data.ProjectionManager;
	import weave.data.QKeyManager;
	import weave.data.StatisticsCache;
	import weave.editors.AxisLabelPlotterEditor;
	import weave.editors.CSVDataSourceEditor;
	import weave.editors.DBFDataSourceEditor;
	import weave.editors.DynamicColumnEditor;
	import weave.editors.GeometryLabelPlotterEditor;
	import weave.editors.GeometryPlotterEditor;
	import weave.editors.GridLinePlotterEditor;
	import weave.editors.SessionHistorySlider;
	import weave.editors.WFSDataSourceEditor;
	import weave.editors.WMSPlotterEditor;
	import weave.editors.WeaveDataSourceEditor;
	import weave.editors.XLSDataSourceEditor;
	import weave.primitives.ColorRamp;
	import weave.services.URLRequestUtils;
	import weave.ui.ColorRampEditor;
	import weave.utils.EditorManager;
	import weave.visualization.plotters.AxisLabelPlotter;
	import weave.visualization.plotters.GeometryLabelPlotter;
	import weave.visualization.plotters.GeometryPlotter;
	import weave.visualization.plotters.GridLinePlotter;
	import weave.visualization.plotters.WMSPlotter;
	import weave.visualization.tools.MapTool;
	import weave.visualization.tools.MapToolEditor;

	/**
	 * Referencing this class will register WeaveAPI singleton implementations.
	 * 
	 * @author adufilie
	 */
	public class _InitializeWeave
	{
		/**
		 * Register singleton implementations for WeaveAPI framework classes
		 */
		WeaveAPI.registerSingleton(ISessionManager, SessionManager);
		WeaveAPI.registerSingleton(IStageUtils, StageUtils);
		WeaveAPI.registerSingleton(IErrorManager, ErrorManager);
		WeaveAPI.registerSingleton(IExternalSessionStateInterface, ExternalSessionStateInterface);
		WeaveAPI.registerSingleton(IProgressIndicator, ProgressIndicator);
		WeaveAPI.registerSingleton(IAttributeColumnCache, AttributeColumnCache);
		WeaveAPI.registerSingleton(IStatisticsCache, StatisticsCache);
		WeaveAPI.registerSingleton(IQualifiedKeyManager, QKeyManager);
		WeaveAPI.registerSingleton(IProjectionManager, ProjectionManager);
		WeaveAPI.registerSingleton(IURLRequestUtils, URLRequestUtils);
		WeaveAPI.registerSingleton(ICSVParser, CSVParser);
		WeaveAPI.registerSingleton(ILinkableHashMap, LinkableHashMap);
		
		/**
		 * Register all ILinkableObjectEditor implementations.
		 */
		//EditorManager.registerEditor(WeaveProperties, WeavePropertiesEditor);
		
		EditorManager.registerEditor(DynamicColumn, DynamicColumnEditor);
		
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
		
		EditorManager.registerEditor(ColorRamp, ColorRampEditor);
		EditorManager.registerEditor(MapTool, MapToolEditor);
		
		EditorManager.registerEditor(SessionStateLog, SessionHistorySlider);
		
		/**
		 * Include these packages in WeaveXMLDecoder so they will not need to be specified in the XML session state.
		 */
		WeaveXMLDecoder.includePackages(
			"weave",
			"weave.core",
			"weave.data",
			"weave.data.AttributeColumns",
			"weave.data.BinClassifiers",
			"weave.data.BinningDefinitions",
			"weave.data.ColumnReferences",
			"weave.data.DataSources",
			"weave.data.KeySets",
			"weave.editors",
			"weave.primitives",
			"weave.Reports",
			"weave.test",
			"weave.ui",
			"weave.utils",
			"weave.visualization",
			"weave.visualization.tools",
			"weave.visualization.layers",
			"weave.visualization.plotters",
			"weave.visualization.plotters.styles"
		);
	}
}
