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
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import org.oicweave.api.getCallbackCollection;
	import org.oicweave.api.primitives.IBounds2D;
	import org.oicweave.core.LinkableString;
	import org.oicweave.visualization.plotters.styles.DynamicLineStyle;
	import org.oicweave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * ProbeLinePlotter
	 * 
	 * @author kmanohar
	 */
	public class ProbeLinePlotter extends AbstractPlotter
	{
		public function ProbeLinePlotter()
		{
			// initialize default line & fill styles
			lineStyle.requestLocalObject(SolidLineStyle, false);
			
		}
		
		public const lineStyle:DynamicLineStyle = newNonSpatialProperty(DynamicLineStyle);
		
		private var drawLine:Boolean = false;
		private const point1:Point = new Point();//reusable object
		private const point2:Point = new Point(); // reusable object
		private const point3:Point = new Point(); // reusable object
		
		public function clearCoordinates():void
		{
			drawLine = false;
			getCallbackCollection(this).triggerCallbacks();
		}
		public function setCoordinates(x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number):void
		{
			point1.x = x1;
			point1.y = y1;
			point2.x = x2;
			point2.y = y2;
			point3.x = x3;
			point3.y = y3;
			drawLine = true;
			getCallbackCollection(this).triggerCallbacks();
		}
		
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if(drawLine)
			{
				var graphics:Graphics = tempShape.graphics;
				graphics.clear();
				
				//HORIZONTAL PROBE LINE
				
				graphics.beginFill(0xff0000);
				graphics.lineStyle(1,0xff0000);
				if(point2.x || point2.y)
				{
					dataBounds.projectPointTo(point1, screenBounds);
					
					// Start at X axis
					graphics.moveTo(point1.x, point1.y);
					
					dataBounds.projectPointTo(point2, screenBounds);
					graphics.drawCircle(point1.x, point1.y,2);
					graphics.moveTo(point1.x, point1.y);
					
					// Finish line at point
					graphics.lineTo(point2.x, point2.y);
					graphics.drawCircle(point2.x,point2.y,2);
					//trace(coordinate, screenBounds, dataBounds);
					
				}
				if( point3.x || point3.y)
				{
					graphics.moveTo(point2.x, point2.y);
					dataBounds.projectPointTo(point3, screenBounds);
					
					graphics.lineTo(point3.x, point3.y);
					graphics.drawCircle(point3.x, point3.y, 2);
				}
				
				graphics.endFill();
				destination.draw(tempShape); 
			}
		}
		
	}
}