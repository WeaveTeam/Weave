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
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	
	import weave.WeaveProperties;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableFunction;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	
	/**
	 * AxisLabelPlotter
	 * 
	 * @author kmanohar
	 */
	public class AxisLabelPlotter extends AbstractPlotter
	{
		public function AxisLabelPlotter()
		{
			hideOverlappingText.value = false;
			xScreenOffset.value = 0;
			yScreenOffset.value = 0;
			setKeySource(text);
			horizontal.value = true;
		}
				
		private const bitmapText:BitmapText = new BitmapText();
		private const matrix:Matrix = new Matrix();

		private static const tempPoint:Point = new Point(); // reusable object

		public const start:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const end:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const interval:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		public const horizontal:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		public const text:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const font:LinkableString = registerLinkableChild(this, new LinkableString(WeaveProperties.DEFAULT_FONT_FAMILY, WeaveProperties.verifyFontFamily));
		public const size:LinkableNumber = registerLinkableChild(this, new LinkableNumber(WeaveProperties.DEFAULT_FONT_SIZE));
		public const color:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000000));
		public const bold:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const italic:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const underline:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const hAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.HORIZONTAL_ALIGN_CENTER));
		public const vAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.VERTICAL_ALIGN_CENTER));
		public const angle:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0));
		public const hideOverlappingText:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		public const xScreenOffset:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const yScreenOffset:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const maxWidth:LinkableNumber = registerLinkableChild(this, new LinkableNumber(80));
		
		public const labelFunction:LinkableFunction = registerLinkableChild(this, new LinkableFunction('string',false,false, ['number', 'string']));

		/**
		 * Draws the graphics onto BitmapData.
		 */
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var textWasDrawn:Array = [];
			var reusableBoundsObjects:Array = [];
			var bounds:IBounds2D;
			
			var graphics:Graphics = tempShape.graphics;
			graphics.clear();
			
			var _start:Number = start.value;
			var _end:Number = end.value;
			var _interval:Number = Math.abs(interval.value) * StandardLib.sign(_end - _start);
			
			var i:int;
			var numLines:Number = Math.abs((_end - _start) / _interval);
			var array:Array = StandardLib.getNiceNumbersInRange(_start, _end, numLines);
						
			bitmapText.textFormat.color = color.value;
			bitmapText.angle = angle.value;
			bitmapText.verticalAlign = vAlign.value;
			bitmapText.horizontalAlign = hAlign.value;
			bitmapText.maxWidth = maxWidth.value - xScreenOffset.value;
			
			// init text format			
			var f:TextFormat = bitmapText.textFormat;
			f.font = font.value;
			f.size = size.value;
			f.color = color.value;
			f.bold = bold.value;
			f.italic = italic.value;
			f.underline = underline.value;
			
			dataBounds.projectPointTo(tempPoint, screenBounds);			
			if (!horizontal.value)
			{
				// if there will be more grid lines than pixels, don't bother drawing anything
				if (numLines > screenBounds.getYCoverage())
					return;
				
				for (i = 0; i <= numLines; i++)
				{
					tempPoint.x = dataBounds.getXMin();
					tempPoint.y = _start + _interval * i;
					
					bitmapText.text = array[i].toString();
					if(labelFunction.value)
						bitmapText.text = labelFunction.apply(null, [array[i], bitmapText.text]);
					
					dataBounds.projectPointTo(tempPoint, screenBounds);
					bitmapText.x = tempPoint.x;
					bitmapText.y = tempPoint.y;
										
					bitmapText.draw(destination);
				}
			}
			else
			{										
				// if there will be more grid lines than pixels, don't bother drawing anything
				if (numLines > screenBounds.getXCoverage())
					return;
				for (i = 0; i <= numLines; i++)
				{
					tempPoint.x = _start + _interval * i;
					tempPoint.y = dataBounds.getYMin();
					bitmapText.text = array[i].toString();
					if(labelFunction.value)
						bitmapText.text = labelFunction.apply(null, [array[i], bitmapText.text]);
					
					dataBounds.projectPointTo(tempPoint, screenBounds);
					bitmapText.x = tempPoint.x;
					bitmapText.y = tempPoint.y;
					
					bitmapText.draw(destination);
				}
			}
			
			
				if (bitmapText.angle == 0)
				{
					// draw almost-invisible rectangle behind text
					bitmapText.getUnrotatedBounds(tempBounds);
					tempBounds.getRectangle(tempRectangle);
					destination.fillRect(tempRectangle, 0x02808080);
				}
				
		}
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			var bounds:IBounds2D = getReusableBounds();
			if (horizontal.value)
				bounds.setYRange(start.value, end.value);
			else
				bounds.setXRange(start.value, end.value);
			return bounds;
		}
		
		private static const tempRectangle:Rectangle = new Rectangle(); // reusable temporary object
		private static const tempBounds:IBounds2D = new Bounds2D(); // reusable temporary object
	}
}
