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

package weave.ui.controlBars
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BitmapFilterType;
	import flash.filters.GradientGlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;
	
	import mx.controls.Menu;
	import mx.controls.MenuBar;
	import mx.core.ClassFactory;
	import mx.core.mx_internal;
	import mx.events.MenuEvent;
	
	import weave.compiler.StandardLib;
	
	use namespace mx_internal;
	
	public class CustomMenuBar extends MenuBar
	{
		public function CustomMenuBar()
		{
			this.addEventListener(MenuEvent.MENU_SHOW, handleMenuShow);
			this.addEventListener(MenuEvent.MENU_HIDE, handleMenuHide);
			this.menuBarItemRenderer = new ClassFactory(CustomMenuBarItem);
		}
		
		override public function styleChanged(styleProp:String):void
		{
			// Fixes bug where styleChanged() stores menuBarItems.length into a local
			// variable and then calls getMenuAt(), which modifies menuBarItems.length.
			if (menuBarItems.length)
				getMenuAt(0);
			super.styleChanged(styleProp);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			// fixes bug where old menu doesn't go away.
			// We can't call Menu.hide() because it will still affect the MenuBar
			// even though the MenuBar no longer manages the old Menu.
			if (oldMenus != menus)
			{
				for each (var menu:Menu in oldMenus)
				{
					if (menu && menu.parent)
					{
						// fixes display bug where MenuBar item does not display as active
						setTimeout(fixMenuBarItemState, 1);
						menus = oldMenus;
						usingOldMenus = true;
					}
				}
			}
			oldMenus = menus;
		}
		
		private var oldMenus:Array = null;
		private var usingOldMenus:Boolean = false;
		
		private function fixMenuBarItemState():void
		{
			try {
				menuBarItems[selectedIndex].menuBarItemState = 'itemDownSkin';
			} catch (e:Error) { }
		}
		private function handleMenuHide(event:MenuEvent):void
		{
			// fixes bug where menu stops working after setting menus = oldMenus
			if (usingOldMenus)
			{
				menus.length = 0;
				usingOldMenus = false;
			}
		}
		
		private function handleMenuShow(event:MenuEvent):void
		{
			// tip taken from : http://blog.flexexamples.com/2010/02/19/setting-a-variable-row-height-on-an-mx-menubar-control-in-flex/
			// this will reduce the vertical space between separators and other items in the menu
			event.menu.variableRowHeight = true;
			event.menu.invalidateSize();
			
			// prevent the menu from appearing off-screen.
			event.menu.callLater(repositionMenu, [event.menu]);
		}
		
		private const menuMouseListeners:Dictionary = new Dictionary(true);
		private const itemHeight:int = 20;
		private const scrollShadow:GradientGlowFilter = new GradientGlowFilter(0, 90, [0, 0], [0, 1], [0, 255], 0, itemHeight / 2, 2, BitmapFilterQuality.HIGH, BitmapFilterType.OUTER);
		private function repositionMenu(menu:Menu):void
		{
			if (!menu.parent)
				return;
			
			// always make the menu appear below the menu bar
			var global:Point = this.localToGlobal(new Point(0, this.height));
			menu.y = menu.parent.globalToLocal(global).y;
			
			var listener:Function = menuMouseListeners[menu] as Function;
			if (listener == null)
			{
				// add a sprite for a shadow to indicate when there are more menu items below or above
				var sprite:Sprite = new Sprite();
				sprite.filters = [scrollShadow];
				menu.addChild(sprite);
				
				// add an event listener that will automatically scroll the menu
				listener = function(..._):void
				{
					var visibleHeight:Number = Math.min(menu.height, stage.stageHeight - global.y);
					var menuMouseY:Number = stage.mouseY - global.y;
					var maxScroll:Number = menu.height - visibleHeight;
					
					// The itemHeight offsets are used to align the minimum and maximum scroll positions with the middle of the first and last menu items.
					var scrollPos:Number = Math.round((menuMouseY - itemHeight / 2) / (visibleHeight - itemHeight) * maxScroll);
					scrollPos = StandardLib.constrain(scrollPos, 0, maxScroll) || 0; // avoid NaN
					menu.scrollRect = new Rectangle(0, scrollPos, menu.width, visibleHeight);
					
					// update shadow graphics
					sprite.graphics.clear();
					sprite.graphics.lineStyle(1, 0, 1, true);
					if (scrollPos > 0)
					{
						// hint that there are more items above
						sprite.graphics.moveTo(0, scrollPos - 1);
						sprite.graphics.lineTo(menu.width, scrollPos - 1);
					}
					if (scrollPos < maxScroll)
					{
						// hint that there are more items below
						sprite.graphics.moveTo(0, scrollPos + visibleHeight);
						sprite.graphics.lineTo(menu.width, scrollPos + visibleHeight);
					}
				};
				menu.addEventListener(MouseEvent.MOUSE_MOVE, listener);
				menuMouseListeners[menu] = listener;
			}
			listener(); // scroll now
		}
	}
}
