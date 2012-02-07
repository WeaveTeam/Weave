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
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import weave.Weave;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.utils.ColumnUtils;
	import weave.visualization.plotters.styles.DynamicFillStyle;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * CirclePlotter
	 * 
	 * @author adufilie
	 */
	public class CircleGlyphPlotter extends AbstractGlyphPlotter
	{
		public function CircleGlyphPlotter()
		{
			init();
		}
		private function init():void
		{
			// initialize default line & fill styles
			lineStyle.requestLocalObject(SolidLineStyle, false);
			var fill:SolidFillStyle = fillStyle.requestLocalObject(SolidFillStyle, false);
			fill.color.internalDynamicColumn.requestGlobalObject(Weave.DEFAULT_COLOR_COLUMN, ColorColumn, false);
		}

		public const minScreenRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(3, isFinite));
		public const maxScreenRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(12, isFinite));
		public const defaultScreenRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(5, isFinite));
		public const enabledSizeBy:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		/**
		 * This is the radius of the circle, in screen coordinates.
		 */
		public const screenRadius:DynamicColumn = newLinkableChild(this, DynamicColumn);
		/**
		 * This is the line style used to draw the outline of the rectangle.
		 */
		public const lineStyle:DynamicLineStyle = newLinkableChild(this, DynamicLineStyle);
		/**
		 * This is the fill style used to fill the rectangle.
		 */
		public const fillStyle:DynamicFillStyle = newLinkableChild(this, DynamicFillStyle);

		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void			
		{			
			var graphics:Graphics = tempShape.graphics;
			
			// project data coordinates to screen coordinates and draw graphics			
			var radius:Number = ColumnUtils.getNorm(screenRadius, recordKey);
			
			tempPoint.x = getXFromRecordKey(recordKey);			
			tempPoint.y = getYFromRecordKey(recordKey);
			
			dataBounds.projectPointTo(tempPoint, screenBounds);
			
			lineStyle.beginLineStyle(recordKey, graphics);			
			fillStyle.beginFillStyle(recordKey, graphics);			
			if (enabledSizeBy.value == true)			
			{				
				radius = minScreenRadius.value + (radius *(maxScreenRadius.value - minScreenRadius.value));
			}				
			else				
			{				
				radius = defaultScreenRadius.value;				
			}			
			if (screenRadius.internalColumn != null && isNaN(radius)) // missing screenRadius value			
			{				
				radius = defaultScreenRadius.value;				
				//draw a square for missing values
				graphics.drawRect(tempPoint.x - radius, tempPoint.y - radius, radius * 2, radius * 2);				
			} 				
			else if(isNaN(radius)) // no screenRadius column				
			{				
				graphics.drawCircle(tempPoint.x, tempPoint.y, defaultScreenRadius.value );				
			}				
			else {				
				graphics.drawCircle(tempPoint.x, tempPoint.y, radius);			
			}			
			graphics.endFill();			
		}
		private static const tempPoint:Point = new Point(); // reusable object
	}
}
