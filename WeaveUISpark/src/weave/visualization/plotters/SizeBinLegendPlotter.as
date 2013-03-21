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
	
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IColumnStatistics;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.ITextPlotter;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.utils.AsyncSort;
	import weave.utils.BitmapText;
	import weave.utils.LinkableTextFormat;
	import weave.utils.TickMarkUtils;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * 
	 * @author yluo
	 */
	public class SizeBinLegendPlotter extends AbstractPlotter implements ITextPlotter
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
			
			registerLinkableChild(this, LinkableTextFormat.defaultTextFormat);
		}
		
		public const radiusColumn:DynamicColumn = newSpatialProperty(DynamicColumn);
		private const radiusColumnStats:IColumnStatistics = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(radiusColumn));
		public const minScreenRadius:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const maxScreenRadius:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const defaultScreenRadius:LinkableNumber = newSpatialProperty(LinkableNumber);
		
		public const absoluteValueColorEnabled:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const absoluteValueColorMin:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		public const absoluteValueColorMax:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		
		public static const simpleRadio:String = "simple";
		public static const customRadio:String = "custom";
		public const numberOfCircles:LinkableNumber = registerLinkableChild(this, new LinkableNumber(10, verifyNumberOfCircles));
		public const customCircleRadiuses:LinkableString = newLinkableChild(this, LinkableString);
		public const typeRadio:LinkableString = registerLinkableChild(this, new LinkableString(simpleRadio));
		
		private const bitmapText:BitmapText = new BitmapText(); // This is used to draw text on bitmaps
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle); // This is the line style used to draw the outline of the shape.
		
		private function verifyNumberOfCircles(value:Number):Boolean {
			if (value < 2)
				return false;
			else
				return true;
		}
		
		private var XMIN:Number = 0, YMIN:Number = 0, XMAX:Number = 1, YMAX:Number = 1;		
		override public function getBackgroundDataBounds():IBounds2D
		{
			return new Bounds2D(XMIN, YMIN, XMAX, YMAX);
		}
		
		private const tempPoint:Point = new Point(); // Reusable temporary object
		private var valueMax:Number = 0, valueMin:Number = 0; // Variables for min and max values of the radius column
		private var circleRadiuses:Array;
		private var normalizedCircleRadiuses:Array;
		private var yInterval:Number;
		private var maxCustomRadius:Number;
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var i:int;
			var j:int;
			valueMax = radiusColumnStats.getMax();
			valueMin = radiusColumnStats.getMin();
			
			if (isNaN(valueMin) ||  isNaN(valueMax)) return; // ToDo
			
			if (typeRadio.value == simpleRadio)
			{
				circleRadiuses = new Array();
				for (i = 0; i < numberOfCircles.value; i++)
					circleRadiuses.push(StandardLib.roundSignificant(valueMin + i * (valueMax - valueMin) / (numberOfCircles.value - 1), 4));
			}
			else if (typeRadio.value == customRadio)
			{
				circleRadiuses = customCircleRadiuses.value.split(',');
				// remove bad values
				for (i = circleRadiuses.length - 1; i >= 0; i--)
				{
					var number:Number = StandardLib.asNumber(circleRadiuses[i]);
					if (!isFinite(number))
						circleRadiuses.splice(i, 1);
					else
						circleRadiuses[i] = number;
				}
				// sort numerically
				AsyncSort.sortImmediately(circleRadiuses, ObjectUtil.numericCompare);
			}

			normalizedCircleRadiuses = new Array();
			if (absoluteValueColorEnabled.value)
			{
				var absMax:Number = Math.max(Math.abs(valueMin), Math.abs(valueMax));
				for (i = 0; i < circleRadiuses.length; i++)
					normalizedCircleRadiuses.push(StandardLib.scale(Math.abs(circleRadiuses[i]), 0, absMax, 0, maxScreenRadius.value));
			}
			else
			{
				for (i = 0; i < circleRadiuses.length; i++)
				{
					// Remove invalid radius (less than 0)
					if (StandardLib.scale(circleRadiuses[i], valueMin, valueMax, minScreenRadius.value, maxScreenRadius.value) < 0)
					{
						circleRadiuses.splice(i, 1);
						i--;
					}
					else
						normalizedCircleRadiuses.push(StandardLib.scale(circleRadiuses[i], valueMin, valueMax, minScreenRadius.value, maxScreenRadius.value));
				}
			}
			
			if (normalizedCircleRadiuses.length != 0)
			{
				yInterval = screenBounds.getYCoverage() / normalizedCircleRadiuses.length;
				
				// Because of the custom circle radiuses, the real max radius needs to be determined.
				if (normalizedCircleRadiuses[0] > normalizedCircleRadiuses[normalizedCircleRadiuses.length - 1])
					maxCustomRadius = normalizedCircleRadiuses[0];
				else
					maxCustomRadius = normalizedCircleRadiuses[normalizedCircleRadiuses.length - 1];
			}
			
			// Draw size legend
			var xMargin:int = 5;
			var xMin:Number = screenBounds.getXNumericMin();
			var yPosition:Number = screenBounds.getYNumericMin() + yInterval / 2; // First y position
			var g:Graphics = tempShape.graphics;
			g.clear();
			lineStyle.beginLineStyle(null, g);
			
			for (i = 0; i < normalizedCircleRadiuses.length; i++)
			{
				tempPoint.y = yPosition;
				
				if (absoluteValueColorEnabled.value)
				{
					// Draw large circle befroe small circle for both negative (top down direction) and positive (bottom up direction)  
					if (circleRadiuses[i] < 0)
					{
						g.beginFill(absoluteValueColorMin.value, 1.0);
					}
					else
					{
						g.beginFill(absoluteValueColorMax.value, 1.0);
						yPosition = screenBounds.getYNumericMax() - yInterval / 2; // First y position from bottom
						for (j = normalizedCircleRadiuses.length - 1; j >= i; j--)
						{
							tempPoint.y = yPosition;
							tempShape.graphics.drawCircle(xMin + xMargin + maxCustomRadius, tempPoint.y, normalizedCircleRadiuses[j]);
							destination.draw(tempShape);
							
							// set up BitmapText
							LinkableTextFormat.defaultTextFormat.copyTo(bitmapText.textFormat);
							bitmapText.text = circleRadiuses[j].toString();
							bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_MIDDLE;
							bitmapText.x = xMin + xMargin + maxCustomRadius * 2 + xMargin;
							bitmapText.y = tempPoint.y;
							bitmapText.draw(destination);
							
							yPosition = yPosition - yInterval;
						}
						break;
					}
				}
				
				tempShape.graphics.drawCircle(xMin + xMargin + maxCustomRadius, tempPoint.y, normalizedCircleRadiuses[i]);
				destination.draw(tempShape);
				
				// set up BitmapText
				LinkableTextFormat.defaultTextFormat.copyTo(bitmapText.textFormat);
				bitmapText.text = circleRadiuses[i].toString();
				bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_MIDDLE;
				bitmapText.x = xMin + xMargin + maxCustomRadius * 2 + xMargin;
				bitmapText.y = tempPoint.y;
				bitmapText.draw(destination);
				
				yPosition = yPosition + yInterval;
			}
		}
	}
}
