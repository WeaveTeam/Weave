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
	/**
	 * References all classes in the library.
	 * For use with mobile app.
	 * 
	 * @author adufilie
	 */
	public class AllClasses
	{
		import weave.visualization.plotters.AbstractPlotter;
		import weave.visualization.plotters.AbstractGlyphPlotter;
		import weave.visualization.plotters.SimpleGlyphPlotter;
		import _InitializeWeaveUISpark;
		import weave.utils.VisToolGroup;
		import weave.visualization.plotters.AnchorPlotter;
		import weave.visualization.plotters.CircleGlyphPlotter;
		import weave.visualization.plotters.CompoundBarChartPlotter;
		import weave.ui.BusyIndicator;
		import weave.ui.CustomContextMenuManager;
		import weave.visualization.layers.filters.LinkableDropShadowFilter;
		import weave.visualization.layers.InteractionController;
		import weave.visualization.plotters.MeterPlotter;
		import weave.visualization.plotters.GaugePlotter;
		import weave.utils.RadialAxis;
		import weave.visualization.plotters.BoundsPlotter;
		import weave.visualization.plotters.LinePlotter;
		import weave.visualization.plotters.RegressionLinePlotter;
		import weave.visualization.plotters.WMSPlotter;
		import weave.visualization.plotters.TextGlyphPlotter;
		import weave.utils.LinkableTextFormat;
		import weave.visualization.plotters.PieChartHistogramPlotter;
		import weave.visualization.layers.Visualization;
		import weave.visualization.plotters.ImageGlyphPlotter;
		import weave.visualization.plotters.GridLinePlotter;
		import weave.utils.TickMarkUtils;
		import weave.visualization.layers.PlotTask;
		import weave.visualization.plotters.SimpleAxisPlotter;
		import weave.visualization.layers.LayerSettings;
		import weave.utils.ResultUtils;
		import weave.visualization.plotters.styles.SolidFillStyle;
		import weave.visualization.plotters.styles.ExtendedFillStyle;
		import weave.visualization.plotters.AxisLabelPlotter;
		import weave.utils.EditorManager;
		import weave.utils.BitmapText;
		import weave.visualization.layers.LinkableEventListener;
		import weave.visualization.plotters.CirclePlotter;
		import weave.visualization.plotters.ParallelCoordinatesPlotter;
		import weave.utils.PlotUtils;
		import weave.Weave;
		import weave.visualization.plotters.CompoundRadVizPlotter;
		import weave.visualization.plotters.RamachandranBackgroundPlotter;
		import ru.etcs.utils.FontLoader;
		import weave.visualization.layers.InteractiveVisualization;
		import weave.visualization.plotters.SingleImagePlotter;
		import weave.utils.BitmapUtils;
		import weave.visualization.layers.filters.LinkableGlowFilter;
		import weave.visualization.plotters.ColorBinLegendPlotter;
		import weave.visualization.plotters.RadVizPlotter;
		import weave.visualization.plotters.Histogram2DPlotter;
		import weave.visualization.plotters.RectanglePlotter;
		import weave.visualization.layers.SimpleInteractiveVisualization;
		import weave.visualization.plotters.SizeBinLegendPlotter;
		import weave.visualization.plotters.styles.DynamicFillStyle;
		import weave.utils.DrawUtils;
		import weave.visualization.plotters.styles.DynamicLineStyle;
		import weave.visualization.plotters.styles.SolidLineStyle;
		import weave.visualization.plotters.ProbeLinePlotter;
		import weave.utils.SpatialIndex;
		import weave.visualization.plotters.GeometryPlotter;
		import weave.visualization.plotters.GraphPlotter;
		import weave.visualization.plotters.styles.ExtendedLineStyle;
		import weave.visualization.plotters.ThermometerPlotter;
		import weave.visualization.plotters.PieChartPlotter;
		import weave.visualization.plotters.AxisPlotter;
		import weave.visualization.plotters.HistogramPlotter;
		import weave.utils.PlotterUtils;
		import weave.visualization.plotters.WedgePlotter;
		import weave.visualization.plotters.AnchorPoint;
		import weave.visualization.layers.PlotManager;
		import weave.visualization.plotters.GraphLabelPlotter;
		import weave.WeaveProperties;
		import weave.visualization.plotters.StickFigureGlyphPlotter;
		import weave.utils.CustomCursorManager;
		import weave.utils.ProbeTextUtils;
		import weave.ui.PenTool;
		import weave.visualization.plotters.ScatterPlotPlotter;
		import weave.visualization.plotters.GeometryLabelPlotter;
		import weave.utils.LegendUtils;
		import weave.visualization.plotters.BarChartLegendPlotter;
		import weave.visualization.plotters.WeaveWordlePlotter;
		AbstractPlotter;
		AbstractGlyphPlotter;
		SimpleGlyphPlotter;
		_InitializeWeaveUISpark;
		VisToolGroup;
		AnchorPlotter;
		CircleGlyphPlotter;
		CompoundBarChartPlotter;
		BusyIndicator;
		CustomContextMenuManager;
		LinkableDropShadowFilter;
		InteractionController;
		MeterPlotter;
		GaugePlotter;
		RadialAxis;
		BoundsPlotter;
		LinePlotter;
		RegressionLinePlotter;
		WMSPlotter;
		TextGlyphPlotter;
		LinkableTextFormat;
		PieChartHistogramPlotter;
		Visualization;
		ImageGlyphPlotter;
		GridLinePlotter;
		TickMarkUtils;
		PlotTask;
		SimpleAxisPlotter;
		LayerSettings;
		ResultUtils;
		SolidFillStyle;
		ExtendedFillStyle;
		AxisLabelPlotter;
		EditorManager;
		BitmapText;
		LinkableEventListener;
		CirclePlotter;
		ParallelCoordinatesPlotter;
		PlotUtils;
		Weave;
		CompoundRadVizPlotter;
		RamachandranBackgroundPlotter;
		FontLoader;
		InteractiveVisualization;
		SingleImagePlotter;
		BitmapUtils;
		LinkableGlowFilter;
		ColorBinLegendPlotter;
		RadVizPlotter;
		Histogram2DPlotter;
		RectanglePlotter;
		SimpleInteractiveVisualization;
		SizeBinLegendPlotter;
		DynamicFillStyle;
		DrawUtils;
		DynamicLineStyle;
		SolidLineStyle;
		ProbeLinePlotter;
		SpatialIndex;
		GeometryPlotter;
		GraphPlotter;
		ExtendedLineStyle;
		ThermometerPlotter;
		PieChartPlotter;
		AxisPlotter;
		HistogramPlotter;
		PlotterUtils;
		WedgePlotter;
		AnchorPoint;
		PlotManager;
		GraphLabelPlotter;
		WeaveProperties;
		StickFigureGlyphPlotter;
		CustomCursorManager;
		ProbeTextUtils;
		PenTool;
		ScatterPlotPlotter;
		GeometryLabelPlotter;
		LegendUtils;
		BarChartLegendPlotter;
		WeaveWordlePlotter;
	}
}
