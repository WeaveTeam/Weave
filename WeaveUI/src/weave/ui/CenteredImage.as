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

package weave.ui
{
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	
	import mx.controls.Image;
	import mx.core.mx_internal;
	
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
				g.lineStyle(0,0,0);
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
