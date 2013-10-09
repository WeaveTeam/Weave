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
	import weave.core.SessionStateLog;
	import weave.core.WeaveXMLDecoder;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.DataSources.CSVDataSource;
	import weave.data.DataSources.DBFDataSource;
	import weave.data.DataSources.TransposedDataSource;
	import weave.data.DataSources.WFSDataSource;
	import weave.data.DataSources.WeaveDataSource;
	import weave.data.DataSources.XLSDataSource;
	import weave.data.KeySets.NumberDataFilter;
	import weave.data.KeySets.StringDataFilter;
	import weave.editors.AxisLabelPlotterEditor;
	import weave.editors.CSVDataSourceEditor;
	import weave.editors.DBFDataSourceEditor;
	import weave.editors.DynamicColumnEditor;
	import weave.editors.GeometryLabelPlotterEditor;
	import weave.editors.GeometryPlotterEditor;
	import weave.editors.GeometryRelationPlotterEditor;
	import weave.editors.GridLinePlotterEditor;
	import weave.editors.ImageGlyphPlotterEditor;
	import weave.editors.NumberDataFilterEditor;
	import weave.editors.SessionHistorySlider;
	import weave.editors.SingleImagePlotterEditor;
	import weave.editors.StringDataFilterEditor;
	import weave.editors.TransposedDataSourceEditor;
	import weave.editors.WFSDataSourceEditor;
	import weave.editors.WMSPlotterEditor;
	import weave.editors.WeaveDataSourceEditor;
	import weave.editors.XLSDataSourceEditor;
	import weave.primitives.ColorRamp;
	import weave.ui.AttributeMenuTool;
	import weave.ui.ColorRampEditor;
	import weave.ui.DataFilter;
	import weave.ui.RTextEditor;
	import weave.ui.userControls.SchafersMissingDataTool;
	import weave.utils.EditorManager;
	import weave.visualization.plotters.AxisLabelPlotter;
	import weave.visualization.plotters.GeometryLabelPlotter;
	import weave.visualization.plotters.GeometryPlotter;
	import weave.visualization.plotters.GeometryRelationPlotter;
	import weave.visualization.plotters.GridLinePlotter;
	import weave.visualization.plotters.ImageGlyphPlotter;
	import weave.visualization.plotters.SingleImagePlotter;
	import weave.visualization.plotters.WMSPlotter;
	import weave.visualization.tools.ColorBinLegendTool;
	import weave.visualization.tools.ColormapHistogramTool;
	import weave.visualization.tools.CompoundBarChartTool;
	import weave.visualization.tools.CompoundRadVizTool;
	import weave.visualization.tools.CustomGraphicsTool;
	import weave.visualization.tools.CustomTool;
	import weave.visualization.tools.CytoscapeWebTool;
	import weave.visualization.tools.DataStatisticsTool;
	import weave.visualization.tools.DataStatisticsToolEditor;
	import weave.visualization.tools.DataTableTool;
	import weave.visualization.tools.DimensionSliderTool;
	import weave.visualization.tools.GaugeTool;
	import weave.visualization.tools.GraphTool;
	import weave.visualization.tools.Histogram2DTool;
	import weave.visualization.tools.HistogramTool;
	import weave.visualization.tools.LineChartTool;
	import weave.visualization.tools.MapTool;
	import weave.visualization.tools.PieChartHistogramTool;
	import weave.visualization.tools.PieChartTool;
	import weave.visualization.tools.RInterfaceTool;
	import weave.visualization.tools.RadVizTool;
	import weave.visualization.tools.RadVizToolEditor;
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
		private static var _:* = function():void
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
			EditorManager.registerEditor(TransposedDataSource, TransposedDataSourceEditor);
			
			EditorManager.registerEditor(StringDataFilter, StringDataFilterEditor);
			EditorManager.registerEditor(NumberDataFilter, NumberDataFilterEditor);
			
			EditorManager.registerEditor(GeometryRelationPlotter, GeometryRelationPlotterEditor);
			EditorManager.registerEditor(GeometryLabelPlotter, GeometryLabelPlotterEditor);
			EditorManager.registerEditor(GeometryPlotter, GeometryPlotterEditor);
			EditorManager.registerEditor(WMSPlotter, WMSPlotterEditor);
			EditorManager.registerEditor(GridLinePlotter, GridLinePlotterEditor);
			EditorManager.registerEditor(AxisLabelPlotter, AxisLabelPlotterEditor);
			EditorManager.registerEditor(ImageGlyphPlotter, ImageGlyphPlotterEditor);
			EditorManager.registerEditor(SingleImagePlotter, SingleImagePlotterEditor);
			
			EditorManager.registerEditor(ColorRamp, ColorRampEditor);
	//		EditorManager.registerEditor(HistogramTool, HistogramToolEditor);
	        EditorManager.registerEditor(RadVizTool, RadVizToolEditor);
			EditorManager.registerEditor(DataStatisticsTool, DataStatisticsToolEditor);
			
			EditorManager.registerEditor(SessionStateLog, SessionHistorySlider);
			
			// reference these tools so they will run their static initialization code
			([
				AttributeMenuTool,
				CompoundBarChartTool,
				ColorBinLegendTool,
				ColormapHistogramTool,
				CompoundRadVizTool,
				CustomTool,
				CustomGraphicsTool,
				CytoscapeWebTool,
				SchafersMissingDataTool,
				DataFilter,
				DataTableTool,
				GaugeTool,
				HistogramTool,
				Histogram2DTool,
				GraphTool,
				LineChartTool,
				DimensionSliderTool,
				MapTool,
				PieChartTool,
				PieChartHistogramTool,
				RadVizTool,
				RTextEditor,
				ScatterPlotTool,
				ThermometerTool,
				TimeSliderTool,
				TransposedTableTool,
				RamachandranPlotTool,
				DataStatisticsTool,
				RInterfaceTool
			]);
			
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
		}();
	}
}
