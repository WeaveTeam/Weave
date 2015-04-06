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

package weave.ui.controlBars
{
	import flash.display.DisplayObject;
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
		private static const MARGIN_WIDTH:int = 10; // same as in MenuBar.as

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
			
			// remove hard-coded margins
			for each (var item:DisplayObject in menuBarItems)
				item.x -= MARGIN_WIDTH;
			
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
		
		override protected function measure():void
		{
			super.measure();
			// remove hard-coded margins
			measuredWidth -= 2 * MARGIN_WIDTH;
			measuredMinWidth -= 2 * MARGIN_WIDTH;
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
