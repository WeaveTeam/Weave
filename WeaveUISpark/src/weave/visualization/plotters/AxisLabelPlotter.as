/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.visualization.plotters
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.ISelectableAttributes;
	import weave.api.ui.IPlotter;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableFunction;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.utils.BitmapText;
	import weave.utils.ColumnUtils;
	import weave.utils.LinkableTextFormat;
	
	/**
	 * AxisLabelPlotter
	 * 
	 * @author kmanohar
	 */
	public class AxisLabelPlotter extends AbstractPlotter implements ISelectableAttributes
	{
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, AxisLabelPlotter, "Axis labels");
		
		public function AxisLabelPlotter()
		{
			setSingleKeySource(text);
			registerLinkableChild(this, LinkableTextFormat.defaultTextFormat); // redraw when text format changes
		}
		
		public function getSelectableAttributes():Array
		{
			return [text];
		}
		
		public function getSelectableAttributeNames():Array
		{
			return ['Label text'];
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
		
		public const labelFunction:LinkableFunction = registerLinkableChild(this, new LinkableFunction('string', true, false, ['number', 'string', 'column']));

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
			else if (isFinite(offset.value) && _begin < _offset && _offset < _end)
				drawLabel(_offset, dataBounds, screenBounds, destination);

			if (_begin <= _end && ((_end - _offset) % _interval == 0 || _interval == 0))
				drawLabel(_end, dataBounds, screenBounds, destination);
		}
		
		private function drawLabel(number:Number, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			bitmapText.text = ColumnUtils.deriveStringFromNumber(text, number) || StandardLib.formatNumber(number);
			try
			{
				if (labelFunction.value)
					bitmapText.text = labelFunction.apply(null, [number, bitmapText.text, text]);
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
		[Deprecated] public function set horizontal(value:Boolean):void { alongXAxis.value = value; }
	}
}
