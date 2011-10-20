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
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	import weave.utils.TickMarkUtils;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * 
	 * @author yluo
	 */
	public class SizeBinLegendPlotter extends AbstractPlotter
	{
		public function SizeBinLegendPlotter()
		{
			init();
		}
		private function init():void
		{
			minScreenRadius.value = 5;
			maxScreenRadius.value = 10;
			defaultScreenRadius.value = 5;
			
			for each (var child:ILinkableObject in [
				lineStyle,
				Weave.properties.axisFontSize,
				Weave.properties.axisFontColor,
				Weave.properties.axisFontFamily,
				Weave.properties.axisFontItalic,
				Weave.properties.axisFontUnderline,
				Weave.properties.axisFontBold])
			{
				registerLinkableChild(this, child);
			}
		}
		
		public const radiusColumn:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const minScreenRadius:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const maxScreenRadius:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const defaultScreenRadius:LinkableNumber = newSpatialProperty(LinkableNumber);
		
		// this is used to draw text on bitmaps
		private const bitmapText:BitmapText = new BitmapText();
		
		/**
		 * This is the line style used to draw the outline of the shape.
		 */
		public const lineStyle:SolidLineStyle = new SolidLineStyle();
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// draw nothing -- everything is in the background layer
		}
		
		private const tempPoint:Point = new Point(); // reusable temporary object
		private var XMIN:Number = 0, YMIN:Number = 0, XMAX:Number = 1, YMAX:Number = 1;		
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			return new Bounds2D(XMIN, YMIN, XMAX, YMAX);
		}
		
		private var valueMax:Number = 0, valueMin:Number = 0; // variables for min and max values in the radius column
		private var numberOfTick:Number = 0, majorInterval:Number = 0, firstMajorTickMarkValue:Number = 0;

		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var margin:int = 5;

			numberOfTick = Math.floor(screenBounds.getYCoverage() / (maxScreenRadius.value * 2.5));
			
			// calculate how many circles should be drawn
			valueMax = WeaveAPI.StatisticsCache.getMax(radiusColumn);
			valueMin = WeaveAPI.StatisticsCache.getMin(radiusColumn);
			var tempNumberOfTick:Number = numberOfTick;
			var numberOfTickReturned:Number = 0;
			
			// numberOfTickReturned might be larger than NumberOfTick set in TickMarkUtils.getNiceInterval
			// the while loop is used to find out correct setting for firstMajorTickMarkValue and majorInterval
			while (true)
			{
				numberOfTickReturned = 0;
				majorInterval = TickMarkUtils.getNiceInterval(valueMin, valueMax, tempNumberOfTick);
				firstMajorTickMarkValue = TickMarkUtils.getFirstTickValue(valueMin, majorInterval);			
				for (var tick:Number = firstMajorTickMarkValue; tick <= valueMax; tick += majorInterval)
				{
					numberOfTickReturned++;
				}
				
				if (numberOfTickReturned <= numberOfTick)
				{
					break;
				}
				else
					tempNumberOfTick = tempNumberOfTick - 1;
			}
			
			// draw the size legend		
			var yPosition:Number = screenBounds.getYNumericMin() + maxScreenRadius.value;
			var yIntervalHeight:Number = 0;
			
			if ((screenBounds.getYCoverage() - maxScreenRadius.value) > 0)
				yIntervalHeight = (screenBounds.getYCoverage() - maxScreenRadius.value) / numberOfTickReturned;
			
			for (var value:Number = firstMajorTickMarkValue; value <= valueMax; value += majorInterval)
			{
				// draw graphics
				// Normalize radius value
				var radius:Number = (value - valueMin) / (valueMax - valueMin);
				if (isNaN(radius))
					radius = defaultScreenRadius.value;
				else
					radius = minScreenRadius.value + (radius *(maxScreenRadius.value - minScreenRadius.value));
				
				var xMin:Number = screenBounds.getXNumericMin();
				var xMax:Number = screenBounds.getXNumericMax();
				
				// get y coordinate to display graphics at.
				tempPoint.y = yPosition;
				
				
				// draw circle
				var g:Graphics = tempShape.graphics;
				g.clear();
				lineStyle.beginLineStyle(null, g);
				//if (!isNaN(color))
				//	g.beginFill(color, 1.0);
				tempShape.graphics.drawCircle(xMin + margin + maxScreenRadius.value, tempPoint.y, radius);
				destination.draw(tempShape);
				
				// set up BitmapText
				bitmapText.textFormat.size = Weave.properties.axisFontSize.value;
				bitmapText.textFormat.color = Weave.properties.axisFontColor.value;
				bitmapText.textFormat.font = Weave.properties.axisFontFamily.value;
				bitmapText.textFormat.bold = Weave.properties.axisFontBold.value;
				bitmapText.textFormat.italic = Weave.properties.axisFontItalic.value;
				bitmapText.textFormat.underline = Weave.properties.axisFontUnderline.value;
				bitmapText.text = value.toString();
				bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER;
				bitmapText.x = xMin + margin + maxScreenRadius.value * 2 + margin;
				bitmapText.y = tempPoint.y;
				bitmapText.draw(destination);
				
				yPosition = yPosition + yIntervalHeight;
				
			}
		}
	}
}
