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
	import flash.geom.Point;
	
	import weave.api.getCallbackCollection;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableString;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
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
		private const yAxis:Point = new Point();//reusable object
		private const plot:Point = new Point(); // reusable object
		private const xAxis:Point = new Point(); // reusable object
		private var yToPlot:Boolean ;
		private var xToPlot:Boolean ;
		
		public function clearCoordinates():void
		{
			drawLine = false;
			getCallbackCollection(this).triggerCallbacks();
		}
		
		public function setCoordinates(x_yAxis:Number, y_yAxis:Number, xPlot:Number, yPlot:Number, x_xAxis:Number, y_xAxis:Number, yToPlotBool:Boolean, xToPlotBool:Boolean):void
		{
			yAxis.x = x_yAxis;
			yAxis.y = y_yAxis;
			plot.x = xPlot;
			plot.y = yPlot;
			xAxis.x = x_xAxis;
			xAxis.y = y_xAxis;
			drawLine = true;
			yToPlot = yToPlotBool ;
			xToPlot = xToPlotBool ;
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
				dataBounds.projectPointTo(plot, screenBounds);
				if(yToPlot)
				{
					dataBounds.projectPointTo(yAxis, screenBounds);
					
					// Start at X axis
					graphics.moveTo(yAxis.x, yAxis.y);
					
					graphics.drawCircle(yAxis.x, yAxis.y,2);
					graphics.moveTo(yAxis.x, yAxis.y);
					
					// Finish line at point
					graphics.lineTo(plot.x, plot.y);
					
					//trace(coordinate, screenBounds, dataBounds);
				}
				graphics.drawCircle(plot.x,plot.y,2);
				
				if( xToPlot)
				{
					graphics.moveTo(plot.x, plot.y);
					dataBounds.projectPointTo(xAxis, screenBounds);
					
					graphics.lineTo(xAxis.x, xAxis.y);
					graphics.drawCircle(xAxis.x, xAxis.y, 2);
				}
				
				graphics.endFill();
				destination.draw(tempShape); 
			}
		}
		
	}
}