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
	import weave.core.WeaveXMLDecoder;
	import weave.visualization.plotters.AxisLabelPlotter;
	import weave.visualization.plotters.CustomGlyphPlotter;
	import weave.visualization.plotters.GeometryLabelPlotter;
	import weave.visualization.plotters.GeometryPlotter;
	import weave.visualization.plotters.GeometryRelationPlotter;
	import weave.visualization.plotters.GridLinePlotter;
	import weave.visualization.plotters.Histogram2DPlotter;
	import weave.visualization.plotters.ImageGlyphPlotter;
	import weave.visualization.plotters.RectanglePlotter;
	import weave.visualization.plotters.ScatterPlotPlotter;
	import weave.visualization.plotters.SimpleGlyphPlotter;
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
			CustomGlyphPlotter,
			GeometryLabelPlotter,
			GeometryPlotter,
			GeometryRelationPlotter,
			GridLinePlotter,
			Histogram2DPlotter,
			ImageGlyphPlotter,
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
			"weave.visualization.plotters",
			"weave.visualization.plotters.styles"
		);
	}
}
