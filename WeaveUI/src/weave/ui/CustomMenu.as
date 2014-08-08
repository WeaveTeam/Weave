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
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BitmapFilterType;
	import flash.filters.GradientGlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import mx.controls.Menu;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.controls.menuClasses.IMenuItemRenderer;
	import mx.core.mx_internal;
	import mx.events.MenuEvent;
	import mx.managers.PopUpManager;
	
	import weave.compiler.StandardLib;
	import weave.primitives.Bounds2D;
	
	use namespace mx_internal;
	
	/**
	 * Automatically scrolls the menu with the mouse when it would otherwise appear off-screen.
	 */
	public class CustomMenu extends Menu
	{
		override public function show(xShow:Object=null, yShow:Object=null):void
		{
			this.scrollRect = null;
			super.show(xShow, yShow);
			this.callLater(initAutoScroll, [this]);
		}
		
		/**
		 * Code copied from Menu.as and modified to create instances of CustomMenu.
		 */
		override mx_internal function openSubMenu(row:IListItemRenderer):void
		{
			// check to see if the menu exists, if not create it
			if (!IMenuItemRenderer(row).menu)
			{
				var r:Menu = getRootMenu();
				var menu:Menu = new CustomMenu();
				menu.parentMenu = this;
				menu.owner = this;
				menu.showRoot = showRoot;
				menu.dataDescriptor = r.dataDescriptor;
				menu.styleName = r;
				menu.labelField = r.labelField;
				menu.labelFunction = r.labelFunction;
				menu.iconField = r.iconField;
				menu.iconFunction = r.iconFunction;
				menu.itemRenderer = r.itemRenderer;
				menu.rowHeight = r.rowHeight;
				menu.scaleY = r.scaleY;
				menu.scaleX = r.scaleX;
				
				// if there's data and it has children then add the items
				if (row.data && 
					_dataDescriptor.isBranch(row.data) &&
					_dataDescriptor.hasChildren(row.data))
				{
					menu.dataProvider = _dataDescriptor.getChildren(row.data);
				}
				menu.sourceMenuBar = sourceMenuBar;
				menu.sourceMenuBarItem = sourceMenuBarItem;
				
				IMenuItemRenderer(row).menu = menu;
				PopUpManager.addPopUp(menu, r, false);
			}
			
			super.openSubMenu(row);
		}
		
		private static const shadowSprites:Dictionary = new Dictionary(true); // Menu -> Sprite
		private static const shadowBlurY:Number = 10;
		private static const shadowStrength:Number = 2;
		private static const scrollShadow:GradientGlowFilter = new GradientGlowFilter(0, 90, [0, 0], [0, 1], [0, 255], 0, shadowBlurY, shadowStrength, BitmapFilterQuality.HIGH, BitmapFilterType.OUTER);
		private static const stageBounds:Bounds2D = new Bounds2D();
		private static const visibleBounds:Bounds2D = new Bounds2D();
		private static const visibleRect:Rectangle = new Rectangle();
		
		public static function initAutoScroll(menu:Menu):void
		{
			var shadowSprite:Sprite = shadowSprites[menu];
			if (!shadowSprite)
			{
				// reduces the vertical space between separators and other items in the menu
				menu.variableRowHeight = true;
				menu.invalidateSize();
				
				// init auto scroll
				menu.addEventListener(MouseEvent.MOUSE_MOVE, autoScroll);
				menu.addEventListener(MenuEvent.MENU_SHOW, function(event:MenuEvent):void { initAutoScroll(event.menu); });
				
				// add a sprite for a shadow to indicate when there are more menu items below or above
				shadowSprites[menu] = shadowSprite = new Sprite();
				shadowSprite.filters = [scrollShadow];
				menu.addChild(shadowSprite);
			}
			menu.scrollRect = null;
			menu.callLater(autoScroll, [menu]);
		}
		
		/**
		 * @param eventOrMenu Either a Menu or a MouseEvent dispatched from a Menu.
		 */
		private static function autoScroll(eventOrMenu:Object):void
		{
			var menu:Menu = eventOrMenu as Menu || Menu(Event(eventOrMenu).currentTarget);
			var shadowSprite:Sprite = shadowSprites[menu];
			
			if (!menu.parent)
				return;
			
			var global:Point = menu.parent.localToGlobal(new Point(menu.x, menu.y));
			visibleBounds.setRectangle(global.x, global.y, menu.measuredWidth, menu.measuredHeight);
			stageBounds.setRectangle(0, 0, menu.stage.stageWidth, menu.stage.stageHeight);
			stageBounds.constrainBounds(visibleBounds, false);
			visibleBounds.getRectangle(visibleRect);
			
			// The itemHeight offsets are used to align minMouseY and maxMouseY
			// with the middle of the first and last menu items.
			var numItems:int = menu.getListContentHolder() ? menu.getListContentHolder().listItems.length : 0;
			var firstItemHeight:Number = numItems > 0 ? menu.indexToItemRenderer(0).height : 0;
			var lastItemHeight:Number = numItems > 0 ? menu.indexToItemRenderer(numItems - 1).height : 0;
			var minMouseY:Number = Math.ceil(visibleBounds.getYNumericMin() + firstItemHeight / 2); // starting at middle of first item
			var maxMouseY:Number = Math.floor(visibleBounds.getYNumericMax() - lastItemHeight / 2); // ending at middle of last item
			
			// calculate the distance we should scroll
			var scrollMaxDistance:Number = menu.measuredHeight - visibleRect.height;
			var scrollDistance:Number = StandardLib.scale(menu.stage.mouseY, minMouseY, maxMouseY, 0, scrollMaxDistance);
			scrollDistance = StandardLib.constrain(Math.round(scrollDistance), 0, scrollMaxDistance) || 0; // avoid NaN
			
			// adjust scrollRect for new visible height
			var scrollOffset:Number = global.y - visibleRect.y;
			menu.scrollRect = new Rectangle(
				0,
				scrollOffset + scrollDistance,
				menu.measuredWidth,
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
				shadowSprite.graphics.lineTo(menu.measuredWidth, lineY);
			}
			if (scrollDistance < scrollMaxDistance)
			{
				// hint that there are more items below
				lineY = scrollDistance + visibleRect.height;
				shadowSprite.graphics.moveTo(0, lineY);
				shadowSprite.graphics.lineTo(menu.measuredWidth, lineY);
			}
		}
	}
}
