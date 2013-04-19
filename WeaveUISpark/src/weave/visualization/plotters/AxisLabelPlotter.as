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
	
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableFunction;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	import weave.utils.LinkableTextFormat;
	
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
			setSingleKeySource(text);
			horizontal.value = true;
			registerLinkableChild(this, LinkableTextFormat.defaultTextFormat); // redraw when text format changes
		}
				
		private const bitmapText:BitmapText = new BitmapText();
		private const matrix:Matrix = new Matrix();

		private static const tempPoint:Point = new Point(); // reusable object

		public const start:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const end:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const interval:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		public const color:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000000));
		public const horizontal:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		public const text:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const textFormatAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.HORIZONTAL_ALIGN_LEFT));
		public const hAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.HORIZONTAL_ALIGN_CENTER));
		public const vAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.VERTICAL_ALIGN_MIDDLE));
		public const angle:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0));
		public const hideOverlappingText:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		public const xScreenOffset:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0));
		public const yScreenOffset:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0));
		public const maxWidth:LinkableNumber = registerLinkableChild(this, new LinkableNumber(80));
		public const alignToDataMax:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		public const labelFunction:LinkableFunction = registerLinkableChild(this, new LinkableFunction('string', true, false, ['number', 'string']));

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
			
			LinkableTextFormat.defaultTextFormat.copyTo(bitmapText.textFormat);
			bitmapText.textFormat.color = color.value;
			bitmapText.angle = angle.value;
			bitmapText.verticalAlign = vAlign.value;
			bitmapText.horizontalAlign = hAlign.value;
			bitmapText.maxWidth = maxWidth.value;
			bitmapText.textFormat.align = textFormatAlign.value;
			
			dataBounds.projectPointTo(tempPoint, screenBounds);
			
			// if there will be more grid lines than pixels, don't bother drawing anything
			var steps:Number = Math.abs((_end - _start) / _interval);
			if (steps > (horizontal.value ? screenBounds.getXCoverage() : screenBounds.getYCoverage()))
				return;
			for (i = 0; i <= steps; i++)
			{
				var number:Number = _start + _interval * i;
				bitmapText.text = StandardLib.formatNumber(number);
				try
				{
					if (labelFunction.value)
						bitmapText.text = labelFunction.apply(null, [number, bitmapText.text]);
				}
				catch (e:Error)
				{
					continue;
				}
				
				if (horizontal.value)
				{
					tempPoint.x = number;
					tempPoint.y = alignToDataMax.value ? dataBounds.getYMax() : dataBounds.getYMin();
				}
				else
				{
					tempPoint.x = alignToDataMax.value ? dataBounds.getXMax() : dataBounds.getXMin();
					tempPoint.y = number;
				}
				dataBounds.projectPointTo(tempPoint, screenBounds);
				bitmapText.x = tempPoint.x + xScreenOffset.value;
				bitmapText.y = tempPoint.y + yScreenOffset.value;
									
				bitmapText.draw(destination);
			}
		}
		
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			output.reset();
			if (horizontal.value)
				output.setYRange(start.value, end.value);
			else
				output.setXRange(start.value, end.value);
		}
	}
}
