/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package
{
	import weave.api.ui.IEditorManager;
	import weave.api.ui.ISelectableAttributes;
	import weave.core.ClassUtils;
	import weave.core.SessionStateLog;
	import weave.core.WeaveXMLDecoder;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.DataSources.CKANDataSource;
	import weave.data.DataSources.CSVDataSource;
	import weave.data.DataSources.CensusDataSource;
	import weave.data.DataSources.DBFDataSource;
	import weave.data.DataSources.GeoJSONDataSource;
	import weave.data.DataSources.GraphMLDataSource;
	import weave.data.DataSources.SocrataDataSource;
	import weave.data.DataSources.TransposedDataSource;
	import weave.data.DataSources.WFSDataSource;
	import weave.data.DataSources.WeaveDataSource;
	import weave.data.DataSources.XLSDataSource;
	import weave.data.KeySets.NumberDataFilter;
	import weave.data.KeySets.StringDataFilter;
	import weave.data.Transforms.ForeignDataMappingTransform;
	import weave.data.Transforms.GroupedDataTransform;
	import weave.data.Transforms.PartitionDataTransform;
	import weave.editors.AxisLabelPlotterEditor;
	import weave.editors.CKANDataSourceEditor;
	import weave.editors.CSVDataSourceEditor;
	import weave.editors.CensusDataSourceEditor;
	import weave.editors.DBFDataSourceEditor;
	import weave.editors.DynamicColumnEditor;
	import weave.editors.ForeignDataMappingTransformEditor;
	import weave.editors.GeoJSONDataSourceEditor;
	import weave.editors.GeometryLabelPlotterEditor;
	import weave.editors.GeometryPlotterEditor;
	import weave.editors.GeometryRelationPlotterEditor;
	import weave.editors.GraphMLDataSourceEditor;
	import weave.editors.GridLinePlotterEditor;
	import weave.editors.GroupedDataTransformEditor;
	import weave.editors.ImageGlyphPlotterEditor;
	import weave.editors.NumberDataFilterEditor;
	import weave.editors.PartitionDataTransformEditor;
	import weave.editors.ScatterPlotPlotterEditor;
	import weave.editors.SessionHistorySlider;
	import weave.editors.SingleImagePlotterEditor;
	import weave.editors.SocrataDataSourceEditor;
	import weave.editors.StringDataFilterEditor;
	import weave.editors.TransposedDataSourceEditor;
	import weave.editors.WFSDataSourceEditor;
	import weave.editors.WMSPlotterEditor;
	import weave.editors.WeaveDataSourceEditor;
	import weave.editors.XLSDataSourceEditor;
	import weave.primitives.ColorRamp;
	import weave.ui.AttributeMenuTool;
	import weave.ui.ColorRampEditor;
	import weave.ui.DataFilterTool;
	import weave.ui.FontControl;
	import weave.ui.RTextEditor;
	import weave.ui.SchafersMissingDataTool;
	import weave.ui.SessionStateEditor;
	import weave.ui.annotation.SessionedTextBox;
	import weave.utils.LinkableTextFormat;
	import weave.visualization.plotters.AxisLabelPlotter;
	import weave.visualization.plotters.GeometryLabelPlotter;
	import weave.visualization.plotters.GeometryPlotter;
	import weave.visualization.plotters.GeometryRelationPlotter;
	import weave.visualization.plotters.GridLinePlotter;
	import weave.visualization.plotters.ImageGlyphPlotter;
	import weave.visualization.plotters.ScatterPlotPlotter;
	import weave.visualization.plotters.SingleImagePlotter;
	import weave.visualization.plotters.WMSPlotter;
	import weave.visualization.tools.AdvancedTableTool;
	import weave.visualization.tools.ColorBinLegendTool;
	import weave.visualization.tools.ColormapHistogramTool;
	import weave.visualization.tools.CompoundBarChartTool;
	import weave.visualization.tools.CompoundRadVizTool;
	import weave.visualization.tools.CustomGraphicsTool;
	import weave.visualization.tools.CustomTool;
	import weave.visualization.tools.CytoscapeWebTool;
	import weave.visualization.tools.DataStatisticsTool;
	import weave.visualization.tools.DataStatisticsToolEditor;
	import weave.visualization.tools.DimensionSliderTool;
	import weave.visualization.tools.GaugeTool;
	import weave.visualization.tools.GraphTool;
	import weave.visualization.tools.Histogram2DTool;
	import weave.visualization.tools.HistogramTool;
	import weave.visualization.tools.KeyMappingTool;
	import weave.visualization.tools.LayerSettingsTool;
	import weave.visualization.tools.LineChartTool;
	import weave.visualization.tools.MapTool;
	import weave.visualization.tools.ParallelCoordinatesTool;
	import weave.visualization.tools.PieChartHistogramTool;
	import weave.visualization.tools.PieChartTool;
	import weave.visualization.tools.RInterfaceTool;
	import weave.visualization.tools.RadVizTool;
	import weave.visualization.tools.RadVizToolEditor;
	import weave.visualization.tools.RamachandranPlotTool;
	import weave.visualization.tools.ScatterPlotTool;
	import weave.visualization.tools.TableTool;
	import weave.visualization.tools.ThermometerTool;
	import weave.visualization.tools.TimeSliderTool;
	import weave.visualization.tools.TransposedTableTool;
	import weave.visualization.tools.TreeTool;

	/**
	 * Referencing this class will register other classes in this library with WeaveAPI.
	 * 
	 * @author adufilie
	 */
	public class _InitializeWeaveUI
	{
		[Embed(source="WeavePathUI.js", mimeType="application/octet-stream")]
		public static const WeavePathUI:Class;

		private static var _:* = function():void
		{
			SessionStateEditor.initializeShortcuts();
			
			var em:IEditorManager = WeaveAPI.EditorManager;
			
			/**
			 * Register all ILinkableObjectEditor implementations.
			 */
			//em.registerEditor(WeaveProperties, WeavePropertiesEditor);
			
			em.registerEditor(LinkableTextFormat, FontControl);
			em.registerEditor(DynamicColumn, DynamicColumnEditor);
			
			em.registerEditor(WeaveDataSource, WeaveDataSourceEditor);
			em.registerEditor(WFSDataSource, WFSDataSourceEditor);
			em.registerEditor(XLSDataSource, XLSDataSourceEditor);
			em.registerEditor(DBFDataSource, DBFDataSourceEditor);
			em.registerEditor(CensusDataSource, CensusDataSourceEditor);
			em.registerEditor(CSVDataSource, CSVDataSourceEditor);
			em.registerEditor(GraphMLDataSource, GraphMLDataSourceEditor);
			em.registerEditor(TransposedDataSource, TransposedDataSourceEditor);
            em.registerEditor(GroupedDataTransform, GroupedDataTransformEditor);
			em.registerEditor(PartitionDataTransform, PartitionDataTransformEditor);
			em.registerEditor(ForeignDataMappingTransform, ForeignDataMappingTransformEditor);
			em.registerEditor(CKANDataSource, CKANDataSourceEditor);
			em.registerEditor(SocrataDataSource, SocrataDataSourceEditor);
			em.registerEditor(GeoJSONDataSource, GeoJSONDataSourceEditor);
			
			em.registerEditor(StringDataFilter, StringDataFilterEditor);
			em.registerEditor(NumberDataFilter, NumberDataFilterEditor);
			
			em.registerEditor(GeometryRelationPlotter, GeometryRelationPlotterEditor);
			em.registerEditor(GeometryLabelPlotter, GeometryLabelPlotterEditor);
			em.registerEditor(GeometryPlotter, GeometryPlotterEditor);
			em.registerEditor(WMSPlotter, WMSPlotterEditor);
			em.registerEditor(GridLinePlotter, GridLinePlotterEditor);
			em.registerEditor(AxisLabelPlotter, AxisLabelPlotterEditor);
			em.registerEditor(ImageGlyphPlotter, ImageGlyphPlotterEditor);
			em.registerEditor(SingleImagePlotter, SingleImagePlotterEditor);
			em.registerEditor(ScatterPlotPlotter, ScatterPlotPlotterEditor);
			
			em.registerEditor(ColorRamp, ColorRampEditor);
	        em.registerEditor(RadVizTool, RadVizToolEditor);
			em.registerEditor(DataStatisticsTool, DataStatisticsToolEditor);
			
			em.registerEditor(SessionStateLog, SessionHistorySlider);
			
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
				DataFilterTool,
				AdvancedTableTool,
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
				TableTool,
				ThermometerTool,
				TimeSliderTool,
				TransposedTableTool,
				RamachandranPlotTool,
				DataStatisticsTool,
				RInterfaceTool,
				TreeTool,
				KeyMappingTool,
				LayerSettingsTool,
				ParallelCoordinatesTool
			]);
			
			/**
			 * Include these packages in WeaveXMLDecoder so they will not need to be specified in the XML session state.
			 */
			WeaveXMLDecoder.includePackages(
				"weave.application",
				"weave.editors",
				"weave.editors.managers",
				"weave.menus",
				"weave.ui",
				"weave.ui.annotation",
				"weave.ui.collaboration",
				"weave.ui.controlBars",
				"weave.ui.CustomDataGrid",
				"weave.utils",
				"weave.visualization",
				"weave.visualization.tools",
				"weave.visualization.layers",
				"weave.visualization.plotters",
				"weave.visualization.plotters.styles"
			);
			
			ClassUtils.registerDeprecatedClass("EmptyTool", CustomTool);
			ClassUtils.registerDeprecatedClass("WMSPlotter2", WMSPlotter);
			ClassUtils.registerDeprecatedClass("SessionedTextArea", SessionedTextBox);
			ClassUtils.registerDeprecatedClass("weave.visualization.tools.DataTableTool", AdvancedTableTool);
			ClassUtils.registerDeprecatedClass("weave.api.ui.IObjectWithSelectableAttributes", ISelectableAttributes);
		}();
	}
}
