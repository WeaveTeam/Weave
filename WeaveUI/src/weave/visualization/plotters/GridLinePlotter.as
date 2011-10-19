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
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.primitives.Bounds2D;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * This plotter displays externally specified grid lines
	 * 
	 * @author kmanohar
	 */
	public class GridLinePlotter extends AbstractPlotter
	{
		public function GridLinePlotter()
		{
			init();
		}



		private function init():void
		{
			start.value = 0;
			end.value = 1;
			interval.value = .2;
			
			horizontal.value = false;
		}
		
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const horizontal:LinkableBoolean = newSpatialProperty(LinkableBoolean);
		
		public const start:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const end:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const interval:LinkableNumber = newSpatialProperty(LinkableNumber);
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			var bounds:IBounds2D = getReusableBounds();
			bounds.setBounds(-1,-1,1,1);
			return bounds;
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			// there are no keys
			return [];
		}
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var graphics:Graphics = tempShape.graphics;
			graphics.clear();
			
			var _start:Number = start.value;
			var _end:Number = end.value;
			var _interval:Number = interval.value;
			
			if(!_interval)// if interval is 0 return to avoid infinite loop
				return;
			
			var ymin:Number =  screenBounds.getYMin();
			var ymax:Number =  screenBounds.getYMax();
			
			var xmin:Number = screenBounds.getXMin();
			var xmax:Number =  screenBounds.getXMax();
			
			lineStyle.beginLineStyle(recordKeys[0],graphics);
			
			for( var i:Number = _start; i <= _end; i+= _interval)
			{
				tempPoint.x = tempPoint.y = i;				
				dataBounds.projectPointTo(tempPoint, screenBounds);
				
				if(horizontal.value)
				{
					graphics.moveTo(xmin, tempPoint.y);
					graphics.lineTo(xmax, tempPoint.y);
				} else {										
					graphics.moveTo(tempPoint.x, ymin);
					graphics.lineTo(tempPoint.x, ymax);
				}
			}
			
			destination.draw(tempShape);
		}
		
		private const tempPoint:Point = new Point();
	}
}
