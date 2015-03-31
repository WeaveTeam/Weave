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
	import weave.core.ClassUtils;
	import weave.core.WeaveXMLDecoder;
	import weave.visualization.plotters.AxisLabelPlotter;
	import weave.visualization.plotters.BackgroundTextPlotter;
	import weave.visualization.plotters.CustomGlyphPlotter;
	import weave.visualization.plotters.EquationPlotter;
	import weave.visualization.plotters.GeometryLabelPlotter;
	import weave.visualization.plotters.GeometryPlotter;
	import weave.visualization.plotters.GeometryRelationPlotter;
	import weave.visualization.plotters.GridLinePlotter;
	import weave.visualization.plotters.Histogram2DPlotter;
	import weave.visualization.plotters.ImageGlyphPlotter;
	import weave.visualization.plotters.LineChartPlotter;
	import weave.visualization.plotters.OldParallelCoordinatesPlotter;
	import weave.visualization.plotters.RectanglePlotter;
	import weave.visualization.plotters.ScatterPlotPlotter;
	import weave.visualization.plotters.SimpleGlyphPlotter;
	import weave.visualization.plotters.SimpleParallelCoordinatesPlotter;
	import weave.visualization.plotters.SingleImagePlotter;
	import weave.visualization.plotters.WMSPlotter;

	/**
	 * Referencing this class will register WeaveAPI singleton implementations.
	 * 
	 * @author adufilie
	 */
	public class _InitializeWeaveUISpark
	{
		/**
		 * Register all ILinkableObjectEditor implementations.
		 */
		
		// reference these tools so they will run their static initialization code
		([
			AxisLabelPlotter,
			BackgroundTextPlotter,
			CustomGlyphPlotter,
			EquationPlotter,
			GeometryLabelPlotter,
			GeometryPlotter,
			GeometryRelationPlotter,
			GridLinePlotter,
			Histogram2DPlotter,
			ImageGlyphPlotter,
			LineChartPlotter,
			SimpleParallelCoordinatesPlotter,
			RectanglePlotter,
			ScatterPlotPlotter,
			SimpleGlyphPlotter,
			SingleImagePlotter,
			WMSPlotter
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
			"weave.visualization.layers.filters",
			"weave.visualization.plotters",
			"weave.visualization.plotters.styles"
		);
		
		ClassUtils.registerDeprecatedClass("weave.visualization.plotters.ParallelCoordinatesPlotter", OldParallelCoordinatesPlotter);
	}
}
