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
			bitmapText.maxWidth = screenBounds.getXCoverage();
			bitmapText.maxHeight = screenBounds.getYCoverage();
			bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_MIDDLE;
			bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER;
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
