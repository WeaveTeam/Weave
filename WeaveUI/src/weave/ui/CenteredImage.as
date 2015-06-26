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

package weave.ui
{
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	
	import mx.controls.Image;
	import mx.core.mx_internal;
	
	import weave.utils.DrawUtils;
	
	use namespace mx_internal;

	/**
	 * Added functionality: Content is centered and not scaled,
	 * and mouse events are captured in the full width,height of the CenteredImage.
	 * 
	 * @author adufilie
	 */
	public class CenteredImage extends Image
	{
		public function CenteredImage()
		{
			super();
			super.scaleContent = false;
		}
		
		override public function set scaleContent(value:Boolean):void
		{
			// not allowed
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if (contentHolder)
			{
				_scrollRect.x = (contentWidth - unscaledWidth) / 2;
				_scrollRect.y = (contentHeight - unscaledHeight) / 2;
				_scrollRect.width = unscaledWidth;
				_scrollRect.height = unscaledHeight;
				
				var g:Graphics = graphics;
				g.clear();
				DrawUtils.clearLineStyle(g);
				g.beginFill(0,0);
				g.drawRect(_scrollRect.x, _scrollRect.y, _scrollRect.width, _scrollRect.height);
				g.endFill();
				
				scrollRect = _scrollRect;
			}
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		private const _scrollRect:Rectangle = new Rectangle();
	}
}
