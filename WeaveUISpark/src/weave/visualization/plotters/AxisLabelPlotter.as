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
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import weave.api.WeaveAPI;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotter;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableFunction;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.utils.BitmapText;
	import weave.utils.LinkableTextFormat;
	
	/**
	 * AxisLabelPlotter
	 * 
	 * @author kmanohar
	 */
	public class AxisLabelPlotter extends AbstractPlotter
	{
		WeaveAPI.registerImplementation(IPlotter, AxisLabelPlotter, "Axis labels");
		
		public function AxisLabelPlotter()
		{
			setSingleKeySource(text);
			registerLinkableChild(this, LinkableTextFormat.defaultTextFormat); // redraw when text format changes
		}
				
		private const bitmapText:BitmapText = new BitmapText();
		private const matrix:Matrix = new Matrix();

		private static const tempPoint:Point = new Point(); // reusable object

		public const alongXAxis:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(true));
		public const begin:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const end:LinkableNumber = newSpatialProperty(LinkableNumber);
		
		public const interval:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const offset:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		public const color:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000000));
		public const text:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const textFormatAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.HORIZONTAL_ALIGN_LEFT));
		public const hAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.HORIZONTAL_ALIGN_CENTER));
		public const vAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.VERTICAL_ALIGN_MIDDLE));
		public const angle:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0));
		public const hideOverlappingText:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
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
			
			LinkableTextFormat.defaultTextFormat.copyTo(bitmapText.textFormat);
			bitmapText.textFormat.color = color.value;
			bitmapText.angle = angle.value;
			bitmapText.verticalAlign = vAlign.value;
			bitmapText.horizontalAlign = hAlign.value;
			bitmapText.maxWidth = maxWidth.value;
			bitmapText.textFormat.align = textFormatAlign.value;
			
			var _begin:Number = numericMax(begin.value, alongXAxis.value ? dataBounds.getXMin() : dataBounds.getYMin());
			var _end:Number = numericMin(end.value, alongXAxis.value ? dataBounds.getXMax() : dataBounds.getYMax());
			var _interval:Number = Math.abs(interval.value);
			var _offset:Number = offset.value || 0;
			
			var scale:Number = alongXAxis.value
				? dataBounds.getXCoverage() / screenBounds.getXCoverage()
				: dataBounds.getYCoverage() / screenBounds.getYCoverage();
			
			if (_begin < _end && ((_begin - _offset) % _interval == 0 || _interval == 0))
				drawLabel(_begin, dataBounds, screenBounds, destination);
			
			if (_interval > scale)
			{
				var first:Number = _begin - (_begin - _offset) % _interval;
				if (first <= _begin)
					first += _interval;
				for (var i:int = 0, number:Number = first; number < _end; number = first + _interval * ++i)
					drawLabel(number, dataBounds, screenBounds, destination);
			}
			
			if (_begin <= _end && ((_end - _offset) % _interval == 0 || _interval == 0))
				drawLabel(_end, dataBounds, screenBounds, destination);
		}
		
		private function drawLabel(number:Number, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			bitmapText.text = StandardLib.formatNumber(number);
			try
			{
				if (labelFunction.value)
					bitmapText.text = labelFunction.apply(null, [number, bitmapText.text]);
			}
			catch (e:Error)
			{
				return;
			}
			
			if (alongXAxis.value)
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
		
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			output.reset();
			if (alongXAxis.value)
				output.setXRange(begin.value, end.value);
			else
				output.setYRange(begin.value, end.value);
		}
		
		private function numericMin(userValue:Number, systemValue:Number):Number
		{
			return userValue < systemValue ? userValue : systemValue; // if userValue is NaN, returns systemValue
		}
		
		private function numericMax(userValue:Number, systemValue:Number):Number
		{
			return userValue > systemValue ? userValue : systemValue; // if userValue is NaN, returns systemValue
		}
		
		// backwards compatibility
		[Deprecated] public function set start(value:Number):void { begin.value = offset.value = value; }
	}
}
