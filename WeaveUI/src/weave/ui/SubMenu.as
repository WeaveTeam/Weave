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
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.controls.Menu;
	import mx.core.UIComponent;
	import mx.events.MenuEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.reportError;
	import weave.primitives.Bounds2D;
	
	/**
	 * This class adds a submenu to any UI Compnent.
	 * Add menu items to the menuItems Array.
	 * 
	 * @author skolman
	 * @author adufilie
	 */
	public class SubMenu extends Menu
	{
		/**
		 * Adds a submenu to any UI Compnent.
		 * @param uiParentComponent The UIComponent to add the submenu to.
		 * @param openMenuEventTypes A list of event types which will toggle the submenu. Default is [MouseEvent.MOUSE_DOWN]. Supply an empty Array for no events.
		 * @param closeMenuEventTypes A list of event types which will close the submenu. Default is [MouseEvent.MOUSE_DOWN]. Supply an empty Array for no events.
		 * @param menuItems An Array of SubMenuItem objects.
		 */
		public function SubMenu(uiParent:UIComponent, openMenuEventTypes:Array = null, closeMenuEventTypes:Array = null, menuItems:Array = null)
		{
			if (uiParent == null)
				throw new Error("uiParent cannot be null");
			
			_uiParent = uiParent;
			
			if (!openMenuEventTypes)
				openMenuEventTypes = [MouseEvent.MOUSE_DOWN];
			if (!closeMenuEventTypes)
				closeMenuEventTypes = [MouseEvent.MOUSE_DOWN];
			
			var type:String;
			for each (type in openMenuEventTypes)
			{
				if (closeMenuEventTypes && closeMenuEventTypes.indexOf(type) >= 0)
					_uiParent.addEventListener(type, toggleSubMenu);
				else
					_uiParent.addEventListener(type, openSubMenu);
			}
			for each (type in closeMenuEventTypes)
			{
				if (openMenuEventTypes && openMenuEventTypes.indexOf(type) < 0)
					_uiParent.addEventListener(type, closeSubMenu);
			}
			
			includeInLayout = false;
			tabEnabled = false;
			owner = DisplayObjectContainer(WeaveAPI.topLevelApplication);
			showRoot = false; //test this
			
			addEventListener(MenuEvent.ITEM_CLICK, handleSubMenuItemClick);
			if (menuItems)
				this.menuItems = menuItems;
		}
		
		/**
		 * An Array of SubMenuItem objects to display in the menu.
		 */
		public var menuItems:Array = [];
		
		private var _uiParent:UIComponent = null;
		
		private function handleSubMenuItemClick(event:MenuEvent):void
		{
			var item:SubMenuItem = event.item as SubMenuItem;
			item.listener.apply(null, item.params);
		}
		
		private function toggleSubMenu(event:Event = null):void
		{
			if (visible)
				hide();
			else
				openSubMenu(event);
		}
		
		private function openSubMenu(event:Event = null):void
		{
			// work around bug where menu doesn't open on mouseDown
			if (event && event.type == MouseEvent.MOUSE_DOWN)
			{
				_uiParent.callLater(openSubMenu);
				return;
			}
			
			showSubMenu();
		}
		
		private function closeSubMenu(event:Event):void
		{
			hide();
		}
		
		public function showSubMenu():void
		{
			if (!menuItems)
				return;
			
			var menuLocation:Point = _uiParent.localToGlobal(new Point(0, _uiParent.height));
			
			var stage:Stage = WeaveAPI.topLevelApplication.stage;
			tempBounds.setBounds(0, 0, stage.stageWidth, stage.stageHeight);
			
			var xMin:Number = tempBounds.getXNumericMin();
			var yMin:Number = tempBounds.getYNumericMin();
			var xMax:Number = tempBounds.getXNumericMax();
			var yMax:Number = tempBounds.getYNumericMax();
			
			setStyle("openDuration", 0);
			popUpMenu(this, _uiParent, menuItems.filter(SubMenuItem.isItemShown));
			show(menuLocation.x, menuLocation.y);
			
			if (menuLocation.x < xMin)
				menuLocation.x = xMin;
			else if(menuLocation.x + width > xMax)
				menuLocation.x = xMax - width;
			
			if (menuLocation.y < yMin)
				menuLocation.y = yMin + _uiParent.height;
			else if (menuLocation.y + height > yMax)
				menuLocation.y -= height + _uiParent.height;
			
			move(menuLocation.x, menuLocation.y);
			setFocus();
		}
		
		private const tempBounds:Bounds2D = new Bounds2D();
	}
}
