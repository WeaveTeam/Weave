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
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BitmapFilterType;
	import flash.filters.GradientGlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.controls.Menu;
	import mx.core.mx_internal;
	
	import weave.compiler.StandardLib;
	import weave.primitives.Bounds2D;
	
	use namespace mx_internal;
	
	/**
	 * Automatically scrolls the menu with the mouse when it would otherwise appear off-screen.
	 */
	public class CustomMenu extends Menu
	{
		public function CustomMenu()
		{
			super();
			// reduces the vertical space between separators and other items in the menu
			variableRowHeight = true;
			
			// add a sprite for a shadow to indicate when there are more menu items below or above
			shadowSprite = new Sprite();
			shadowSprite.filters = [scrollShadow];
			addChild(shadowSprite);
			
			addEventListener(MouseEvent.MOUSE_MOVE, scroll);
		}
		
		private var shadowSprite:Sprite;
		private const shadowBlurY:Number = 10;
		private const shadowStrength:Number = 2;
		private const scrollShadow:GradientGlowFilter = new GradientGlowFilter(0, 90, [0, 0], [0, 1], [0, 255], 0, shadowBlurY, shadowStrength, BitmapFilterQuality.HIGH, BitmapFilterType.OUTER);
		
		override public function show(xShow:Object=null, yShow:Object=null):void
		{
			this.scrollRect = null;
			super.show(xShow, yShow);
			this.callLater(scroll);
		}
		
		private static const stageBounds:Bounds2D = new Bounds2D();
		private static const visibleBounds:Bounds2D = new Bounds2D();
		private static const visibleRect:Rectangle = new Rectangle();
		
		private function scroll(event:MouseEvent = null):void
		{
			if (!parent)
				return;
			
			var global:Point = parent.localToGlobal(new Point(x, y));
			visibleBounds.setRectangle(global.x, global.y, this.measuredWidth, this.measuredHeight);
			stageBounds.setRectangle(0, 0, stage.stageWidth, stage.stageHeight);
			stageBounds.constrainBounds(visibleBounds, false);
			visibleBounds.getRectangle(visibleRect);
			
			// The itemHeight offsets are used to align minMouseY and maxMouseY
			// with the middle of the first and last menu items.
			var numItems:int = listContent ? listContent.listItems.length : 0;
			var firstItemHeight:Number = numItems > 0 ? indexToItemRenderer(0).height : 0;
			var lastItemHeight:Number = numItems > 0 ? indexToItemRenderer(numItems - 1).height : 0;
			var minMouseY:Number = Math.ceil(visibleBounds.getYNumericMin() + firstItemHeight / 2); // starting at middle of first item
			var maxMouseY:Number = Math.floor(visibleBounds.getYNumericMax() - lastItemHeight / 2); // ending at middle of last item
			
			// calculate the distance we should scroll
			var scrollMaxDistance:Number = this.measuredHeight - visibleRect.height;
			var scrollDistance:Number = StandardLib.scale(stage.mouseY, minMouseY, maxMouseY, 0, scrollMaxDistance);
			scrollDistance = StandardLib.constrain(Math.round(scrollDistance), 0, scrollMaxDistance) || 0; // avoid NaN
			
			// adjust scrollRect for new visible height
			var scrollOffset:Number = global.y - visibleRect.y;
			this.scrollRect = new Rectangle(
				0,
				scrollOffset + scrollDistance,
				this.measuredWidth,
				visibleRect.height - scrollOffset
			);
			
			// update shadow graphics
			shadowSprite.graphics.clear();
			shadowSprite.graphics.lineStyle(1, 0, 1, true);
			var lineY:Number;
			if (scrollDistance > 0)
			{
				// hint that there are more items above
				lineY = scrollDistance - 1;
				shadowSprite.graphics.moveTo(0, lineY);
				shadowSprite.graphics.lineTo(this.measuredWidth, lineY);
			}
			if (scrollDistance < scrollMaxDistance)
			{
				// hint that there are more items below
				lineY = scrollDistance + visibleRect.height;
				shadowSprite.graphics.moveTo(0, lineY);
				shadowSprite.graphics.lineTo(this.measuredWidth, lineY);
			}
		}
	}
}
