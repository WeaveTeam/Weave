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

package weave.visualization.plotters
{
	import flash.display.BitmapData;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.visualization.plotters.styles.SolidFillStyle;
	
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

		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// sorted by color first
			recordKeys.sort(sortByColor);
			// then by radius
			recordKeys.sort(sortBySize, Array.DESCENDING);
			super.drawPlot(recordKeys, dataBounds, screenBounds, destination );
		}
		
		/**
		 * This function sorts record keys based on their colorColumn values
		 * @param key1 First record key (a)
		 * @param key2 Second record key (b)
		 * @return Sort value: 0: (a == b), -1: (a < b), 1: (a > b)
		 * 
		 */			
		private function sortByColor(key1:IQualifiedKey, key2:IQualifiedKey):int
		{
			var a:Number = colorColumn.getValueFromKey(key1, Number);
			var b:Number = colorColumn.getValueFromKey(key2, Number);
			if( a < b ) return -1; 
			else if( a > b ) return 1 ;
			else return 0 ;
		}
		
		/**
		 * This function sorts record keys based on their radiusColumn values
		 * @param key1 First record key (a)
		 * @param key2 Second record key (b)
		 * @return Sort value: 0: (a == b), -1: (a < b), 1: (a > b)
		 * 
		 */			
		private function sortBySize(key1:IQualifiedKey, key2:IQualifiedKey):int
		{
			var a:Number = radiusColumn.getValueFromKey(key1, Number);
			var b:Number = radiusColumn.getValueFromKey(key2, Number);
			if( a < b ) return -1;
			else if( a > b ) return 1;
			else return 0;
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

