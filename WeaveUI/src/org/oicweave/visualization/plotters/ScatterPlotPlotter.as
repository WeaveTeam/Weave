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

package org.oicweave.visualization.plotters
{
	import flash.display.BitmapData;
	
	import org.oicweave.data.AttributeColumns.AlwaysDefinedColumn;
	import org.oicweave.data.AttributeColumns.DynamicColumn;
	import org.oicweave.primitives.Bounds2D;
	import org.oicweave.core.LinkableBoolean;
	import org.oicweave.core.LinkableNumber;
	import org.oicweave.visualization.plotters.styles.SolidFillStyle;
	
	/**
	 * ScatterPlotPlotter
	 * 
	 * @author adufilie
	 */
	public class ScatterPlotPlotter extends AbstractSimplifiedPlotter
	{
		public function ScatterPlotPlotter()
		{
			super(CircleGlyphPlotter);
			//circlePlotter.fillStyle.lock();
			registerSpatialProperties(xColumn, yColumn);
			registerNonSpatialProperties(colorColumn, radiusColumn, minScreenRadius, maxScreenRadius, defaultScreenRadius, alphaColumn, enabledSizeBy);
		}

		// the private plotter being simplified
		public function get defaultScreenRadius():LinkableNumber {return circlePlotter.defaultScreenRadius;}
		private function get circlePlotter():CircleGlyphPlotter { return internalPlotter as CircleGlyphPlotter; }
		public function get enabledSizeBy():LinkableBoolean {return circlePlotter.enabledSizeBy; }
		public function get minScreenRadius():LinkableNumber { return circlePlotter.minScreenRadius; }
		public function get maxScreenRadius():LinkableNumber { return circlePlotter.maxScreenRadius; }
		public function get xColumn():DynamicColumn { return circlePlotter.dataX; }
		public function get yColumn():DynamicColumn { return circlePlotter.dataY; }
		public function get alphaColumn():AlwaysDefinedColumn { return (circlePlotter.fillStyle.internalObject as SolidFillStyle).alpha; }
		public function get colorColumn():AlwaysDefinedColumn { return (circlePlotter.fillStyle.internalObject as SolidFillStyle).color; }
		public function get radiusColumn():DynamicColumn { return circlePlotter.screenRadius; }
	}
}

