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
	import weave.utils.BitmapText;
	import weave.utils.LinkableTextFormat;
	
	public class BackgroundTextPlotter extends AbstractPlotter
	{
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, BackgroundTextPlotter, "Background text");
		
		public const textFormat:LinkableTextFormat = newLinkableChild(this, LinkableTextFormat);
		public const textFunction:LinkableFunction = registerLinkableChild(this, new LinkableFunction('target && target.getSessionState()', true, false, ['target']));
		public const dependency:LinkableDynamicObject = newLinkableChild(this, LinkableDynamicObject);
		private const bitmapText:BitmapText = new BitmapText();
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			bitmapText.x = screenBounds.getXCenter();
			bitmapText.y = screenBounds.getYCenter();
			bitmapText.width = screenBounds.getXCoverage();
			bitmapText.height = screenBounds.getYCoverage();
			bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_MIDDLE;
			bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER;
			textFormat.copyTo(bitmapText.textFormat);
			bitmapText.textFormat.align = BitmapText.HORIZONTAL_ALIGN_CENTER;
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
