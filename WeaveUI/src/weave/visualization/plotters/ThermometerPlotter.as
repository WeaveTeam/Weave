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
//	import weave.data.AttributeColumns.DynamicColumn;
//	import weave.data.StatisticsCache;
//	import weave.primitives.Bounds2D;
//	import weave.data.KeySets.KeySet;
//	import flash.display.BitmapData;
//	import flash.display.Graphics;
//	import flash.display.Shape;
//	import flash.geom.Point;	
//    import flash.display.CapsStyle;
//  import weave.Weave;
	import flash.display.BitmapData;
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	
	public class ThermometerPlotter extends MeterPlotter
	{
		
		// reusable point objects
		private const bottom:Point = new Point(), top:Point = new Point();
		
		//the radius of the thermometer bulb (circle at bottom) in pixels
		private const bulbRadius:Number = 30;
		
		//the thickness of the thermometer red center line
		private const centerLineThickness:Number = 20;
		
		//the thickness of the thermometer background center line
		private const backgroundCenterLineThickness:Number = 30;
		
		//the color to use for background elements
		private const backgroundCenterLineColor:uint = 0x777777;
		
		//the x offset (in pixels) used when drawing all shapes (so axis line is fully visible) 
		private const xOffset:Number = backgroundCenterLineThickness/2+1;
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			//compute the meter value by averaging all record values
			var meterValue:Number = 0;
			var n:Number = recordKeys.length;
			
			for (var i:int = 0; i < n; i++)//TODO handle missing values
				meterValue += meterColumn.getValueFromKey(recordKeys[i] as IQualifiedKey, Number);
			meterValue /= n;
					
			if (isFinite(meterValue))
			{
				//clear the graphics
				var graphics:Graphics = tempShape.graphics;
				graphics.clear();
				
				//project bottom point
				bottom.x = bottom.y = 0;
				dataBounds.projectPointTo(bottom, screenBounds);
				bottom.x += xOffset;
				
				//project top point (data value)
				top.x = 0;
				top.y = meterValue;
				dataBounds.projectPointTo(top, screenBounds);
				top.x += xOffset;
				
				//draw the center line (from zero to data value)
				graphics.lineStyle(centerLineThickness,0xff0000,1.0, false, "normal", CapsStyle.NONE, null, 3);
				graphics.moveTo(bottom.x, bottom.y+bulbRadius);
				graphics.lineTo(top.x, top.y);
				
				destination.draw(tempShape);
			}
		}
		
		/**
		 * This function draws the background graphics for this plotter, if applicable.
		 * An example background would be the origin lines of an axis.
		 * @param dataBounds The data coordinates that correspond to the given screenBounds.
		 * @param screenBounds The coordinates on the given sprite that correspond to the given dataBounds.
		 * @param destination The sprite to draw the graphics onto.
		 */
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var graphics:Graphics = tempShape.graphics;
			graphics.clear();
			
			//project bottom point
			bottom.x = bottom.y = 0;
			dataBounds.projectPointTo(bottom, screenBounds);
			bottom.x += xOffset;
			
			//project data max top point
			top.x = 0;
			top.y = WeaveAPI.StatisticsCache.getMax(meterColumn);
			dataBounds.projectPointTo(top, screenBounds);
			top.x += xOffset;
			
			//draw the background line (from zero to data max)
			graphics.lineStyle(backgroundCenterLineThickness,backgroundCenterLineColor);
			graphics.moveTo(bottom.x, bottom.y+bulbRadius);
			graphics.lineTo(top.x, top.y);
				
			//draw background circle
			graphics.lineStyle(5,backgroundCenterLineColor);
			graphics.beginFill(0xFF0000);
			graphics.drawCircle(bottom.x,bottom.y+bulbRadius,bulbRadius);
			graphics.endFill();
			
			destination.draw(tempShape);
		}
		
		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 * @return A Bounds2D object specifying the background data bounds.
		 */
		override public function getBackgroundDataBounds():IBounds2D
		{
			return getReusableBounds(0, 0, 1, WeaveAPI.StatisticsCache.getMax(meterColumn));
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			return [getReusableBounds(0, 0, 1, WeaveAPI.StatisticsCache.getMax(meterColumn))];
		}
	}
}


