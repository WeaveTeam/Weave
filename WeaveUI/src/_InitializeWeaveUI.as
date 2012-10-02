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
	import flash.utils.Dictionary;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.core.IErrorManager;
	import weave.api.core.IExternalSessionStateInterface;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILocaleManager;
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
	import weave.core.LocaleManager;
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
	import weave.editors.ImageGlyphPlotterEditor;
	import weave.editors.SessionHistorySlider;
	import weave.editors.WFSDataSourceEditor;
	import weave.editors.WMSPlotterEditor;
	import weave.editors.WeaveDataSourceEditor;
	import weave.editors.XLSDataSourceEditor;
	import weave.primitives.ColorRamp;
	import weave.services.URLRequestUtils;
	import weave.ui.AttributeMenuTool;
	import weave.ui.ColorRampEditor;
	import weave.ui.JRITextEditor;
	import weave.ui.RTextEditor;
	import weave.utils.EditorManager;
	import weave.visualization.plotters.AxisLabelPlotter;
	import weave.visualization.plotters.GeometryLabelPlotter;
	import weave.visualization.plotters.GeometryPlotter;
	import weave.visualization.plotters.GridLinePlotter;
	import weave.visualization.plotters.ImageGlyphPlotter;
	import weave.visualization.plotters.WMSPlotter;
	import weave.visualization.tools.ColorBinLegendTool;
	import weave.visualization.tools.ColormapHistogramTool;
	import weave.visualization.tools.CompoundBarChartTool;
	import weave.visualization.tools.CompoundRadVizTool;
	import weave.visualization.tools.CustomTool;
	import weave.visualization.tools.DataTableTool;
	import weave.visualization.tools.DimensionSliderTool;
	import weave.visualization.tools.GaugeTool;
	import weave.visualization.tools.Histogram2DTool;
	import weave.visualization.tools.HistogramTool;
	import weave.visualization.tools.LineChartTool;
	import weave.visualization.tools.MapTool;
	import weave.visualization.tools.PieChartHistogramTool;
	import weave.visualization.tools.PieChartTool;
	import weave.visualization.tools.RadVizTool;
	import weave.visualization.tools.RamachandranPlotTool;
	import weave.visualization.tools.ScatterPlotTool;
	import weave.visualization.tools.ThermometerTool;
	import weave.visualization.tools.TimeSliderTool;
	import weave.visualization.tools.TransposedTableTool;

	/**
	 * Referencing this class will register WeaveAPI singleton implementations.
	 * 
	 * @author adufilie
	 */
	public class _InitializeWeaveUI
	{
		
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
		EditorManager.registerEditor(ImageGlyphPlotter, ImageGlyphPlotterEditor);
		
		EditorManager.registerEditor(ColorRamp, ColorRampEditor);
//		EditorManager.registerEditor(HistogramTool, HistogramToolEditor);
		
		EditorManager.registerEditor(SessionStateLog, SessionHistorySlider);
		
		/**
		 * Include these packages in WeaveXMLDecoder so they will not need to be specified in the XML session state.
		 */
		WeaveXMLDecoder.includePackages(
			"weave.editors",
			"weave.ui",
			"weave.utils",
			"weave.visualization",
			"weave.visualization.tools",
			"weave.visualization.layers",
			"weave.visualization.plotters",
			"weave.visualization.plotters.styles"
		);

		// BEGIN TEMPORARY SOLUTION
		public static const toggleMap:Dictionary = new Dictionary();
		_initToggleMap();
		private static function _initToggleMap():void
		{
			var toggles:Array = [
				[Weave.properties.enableAddAttributeMenuTool, AttributeMenuTool],
				[Weave.properties.enableAddBarChart, CompoundBarChartTool],
				[Weave.properties.enableAddColormapHistogram, ColormapHistogramTool],
				[Weave.properties.enableAddColorLegend, ColorBinLegendTool],
				[Weave.properties.enableAddCompoundRadViz, CompoundRadVizTool],
				[Weave.properties.enableAddDataTable, DataTableTool],
				[Weave.properties.enableAddDimensionSliderTool, DimensionSliderTool],
				[Weave.properties.enableAddGaugeTool, GaugeTool],
				[Weave.properties.enableAddHistogram, HistogramTool],
				[Weave.properties.enableAdd2DHistogram, Histogram2DTool],
				[Weave.properties.enableAddRScriptEditor, JRITextEditor],
				[Weave.properties.enableAddLineChart, LineChartTool],
				[Weave.properties.enableAddMap, MapTool],
				[Weave.properties.enableAddPieChart, PieChartTool],
				[Weave.properties.enableAddPieChartHistogram, PieChartHistogramTool],
				[Weave.properties.enableAddRScriptEditor, RTextEditor],
				[Weave.properties.enableAddRadViz, RadVizTool],
				[Weave.properties.enableAddRamachandranPlot, RamachandranPlotTool],
				[Weave.properties.enableAddScatterplot, ScatterPlotTool],
				[Weave.properties.enableAddThermometerTool, ThermometerTool],
				[Weave.properties.enableAddTimeSliderTool, TimeSliderTool],
				[Weave.properties.enableAddDataTable, TransposedTableTool],
				[Weave.properties.enableAddCustomTool, CustomTool]
			];
			for each (var pair:Array in toggles)
				toggleMap[pair[1]] = pair[0];
		}
		// END TEMPORARY SOLUTION
	}
}
