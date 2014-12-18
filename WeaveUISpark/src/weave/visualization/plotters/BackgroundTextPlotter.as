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
	
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.ui.IPlotter;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableFunction;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.utils.BitmapText;
	import weave.utils.LinkableTextFormat;
	
	public class BackgroundTextPlotter extends AbstractPlotter
	{
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, BackgroundTextPlotter, "Background text");
		
		public const textFormat:LinkableTextFormat = newLinkableChild(this, LinkableTextFormat);
		public const textFunction:LinkableFunction = registerLinkableChild(this, new LinkableFunction('target && target.getSessionState()', true, false, ['target']));
		public const dependency:LinkableDynamicObject = newLinkableChild(this, LinkableDynamicObject);
		public const textX:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0));
		public const textY:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0));
		public const dataWidth:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const horizontalAlign:LinkableString = registerSpatialProperty(new LinkableString(BitmapText.HORIZONTAL_ALIGN_CENTER, verifyHAlign));
		public const verticalAlign:LinkableString = registerSpatialProperty(new LinkableString(BitmapText.VERTICAL_ALIGN_MIDDLE, verifyVAlign));
		public const dataHeight:LinkableNumber = newSpatialProperty(LinkableNumber);
		
		private const bitmapText:BitmapText = new BitmapText();

		private function verifyHAlign(value:String):Boolean
		{
			return value == BitmapText.HORIZONTAL_ALIGN_LEFT
				|| value == BitmapText.HORIZONTAL_ALIGN_CENTER
				|| value == BitmapText.HORIZONTAL_ALIGN_RIGHT;
		}
		private function verifyVAlign(value:String):Boolean
		{
			return value == BitmapText.VERTICAL_ALIGN_TOP
				|| value == BitmapText.VERTICAL_ALIGN_MIDDLE
				|| value == BitmapText.VERTICAL_ALIGN_BOTTOM;
		}
		
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			var x:Number = textX.value;
			var y:Number = textY.value;
			var w:Number = dataWidth.value || 0;
			var h:Number = dataHeight.value || 0;
			
			if (horizontalAlign.value == BitmapText.HORIZONTAL_ALIGN_LEFT)
				output.setXRange(x, x + w);
			if (horizontalAlign.value == BitmapText.HORIZONTAL_ALIGN_CENTER)
				output.setCenteredXRange(x, w);
			if (horizontalAlign.value == BitmapText.HORIZONTAL_ALIGN_RIGHT)
				output.setXRange(x - w, x);
			
			if (verticalAlign.value == BitmapText.VERTICAL_ALIGN_TOP)
				output.setYRange(y - h, y);
			if (verticalAlign.value == BitmapText.VERTICAL_ALIGN_MIDDLE)
				output.setCenteredYRange(y, h);
			if (verticalAlign.value == BitmapText.VERTICAL_ALIGN_BOTTOM)
				output.setYRange(y, y + h);
		}

		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			bitmapText.x = screenBounds.getXNumericMin() + textX.value < screenBounds.getXNumericMax()- bitmapText.width ? screenBounds.getXNumericMin() + textX.value : screenBounds.getXNumericMax()- bitmapText.width; 
			bitmapText.y = screenBounds.getYNumericMin() + textY.value < screenBounds.getYNumericMax()- bitmapText.height ? screenBounds.getYNumericMin() + textY.value : screenBounds.getYNumericMax()- bitmapText.height;
			bitmapText.maxWidth = screenBounds.getXCoverage();
			bitmapText.maxHeight = screenBounds.getYCoverage();
			textFormat.copyTo(bitmapText.textFormat);
			try
			{
				bitmapText.text = textFunction.apply(this, [dependency.target]);
				bitmapText.draw(destination);
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		
	}
}
