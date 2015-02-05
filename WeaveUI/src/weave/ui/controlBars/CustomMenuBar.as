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
	import flash.geom.Point;
	import flash.utils.setTimeout;
	
	import mx.controls.Menu;
	import mx.controls.MenuBar;
	import mx.core.ClassFactory;
	import mx.core.mx_internal;
	import mx.events.MenuEvent;
	
	import weave.ui.CustomMenu;
	
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
			// prevent the menu from appearing off-screen.
			event.menu.callLater(repositionMenu, [event.menu]);
			CustomMenu.initAutoScroll(event.menu);
		}
		
		private function repositionMenu(menu:Menu):void
		{
			if (!menu.parent || menu.parentMenu)
				return;
			
			// always make the menu appear below the menu bar
			var global:Point = this.localToGlobal(new Point(0, this.height));
			menu.y = menu.parent.globalToLocal(global).y;
		}
	}
}
