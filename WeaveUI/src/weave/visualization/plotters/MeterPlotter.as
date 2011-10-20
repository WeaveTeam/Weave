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
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import mx.controls.Alert;
	
	import weave.Weave;
	import weave.api.newLinkableChild;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.KeySets.KeySet;
	import weave.primitives.Bounds2D;
	
	/**
	 * This abstract class contains functionality common to any "meter tool" such as the thermometer and the gauge.
	 * This functionality includes the ability to select which input drives the single value shown by the tool plotter.
	 * 
	 * @author Curran Kelleher
	 */
	public class MeterPlotter extends AbstractPlotter
	{
		//These constants are possible values of inputMode.
		public const PROBE_MODE:Number = 0;
		public const COLUMN_AVERAGE_MODE:Number = 1;
		
		//the sessioned number controlling the input mode
		private const inputMode:LinkableNumber = newLinkableChild(this, LinkableNumber, updateMode); 
		
		//the column whose value drives this meter 
		public const meterColumn:DynamicColumn = newSpatialProperty(DynamicColumn);
		
//		private var mode:Number = PROBE_MODE;
		public function MeterPlotter()
		{
			//this line causes only the currently probed records to be drawn.			
			setKeySource(Weave.root.getObject(Weave.DEFAULT_PROBE_KEYSET) as KeySet);
		}
		
		private function updateMode():void{
			Alert.show("in updateMode"); 
		}
		
		/**
		 * Returns true when there exists a valid value for the meter to display, false if not. 
		 */
		protected function meterValueExists(recordKeys:Array):Boolean{
			return recordKeys.length>0;
		}
	}
}


