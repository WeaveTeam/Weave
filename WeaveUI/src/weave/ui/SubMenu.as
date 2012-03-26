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
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.controls.Menu;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.MenuEvent;
	
	import weave.primitives.Bounds2D;
	
	/**
	 * This class adds a submenu to any UI Compnent.
	 * Contructor takes a parent UIComponent and a String array of event listeners
	 * Use the addSubMenuItem function to add menu items
	 * 
	 * @author skolman
	 * @author adufilie
	 */
	public class SubMenu
	{
		/**
		 * Adds a submenu to any UI Compnent.
		 * Contructor takes a parent UIComponent and a String array of event listeners
		 * Use the addSubMenuItem function to add menu items
		 * @param uiParentComponent The UIComponent to add the submenu to.
		 * @param openMenuEventTypes A list of event types which will toggle the submenu.
		 * @param closeMenuEventTypes A list of event types which will close the submenu.
		 */
		public function SubMenu(uiParent:UIComponent, openMenuEventTypes:Array, closeMenuEventTypes:Array = null)
		{
			_uiParent = uiParent;
			
			var type:String;
			for each (type in openMenuEventTypes)
				_uiParent.addEventListener(type, openSubMenu);
			for each (type in closeMenuEventTypes)
				_uiParent.addEventListener(type, closeSubMenu);
		}
		
		private var _uiParent:UIComponent = null;
		
		private var subMenuItem:Menu;
		
		private var subMenuDataProvider:Array = [];
		
		/**
		 * Adds an item to the menu.
		 * @param label The Label string to show when the menu is open
		 * @param listener The function to call when the item is clicked.
		 * @param params An Array of parameters to pass to the listener function.
		 */
		public function addSubMenuItem(label:String,listener:Function,params:Array=null):void
		{
			var menuItem:SubMenuItem = new SubMenuItem();
			menuItem.label = label;
			menuItem.listener = listener;
			menuItem.params = params;
			
			subMenuDataProvider.push(menuItem);
			
			subMenuItem = Menu.createMenu(_uiParent,subMenuDataProvider,false);
			
			
			subMenuItem.addEventListener(MenuEvent.ITEM_CLICK,handleSubMenuItemClick);
			
			subMenuItem.addEventListener(MenuEvent.MENU_HIDE,function():void{toggleSubMenu = false;});
			
			
		}
		
		private function handleSubMenuItemClick(event:MenuEvent):void
		{
			var item:SubMenuItem = event.item as SubMenuItem;
			item.listener.apply(null, item.params);
		}
		
		private var toggleSubMenu:Boolean =  false;
		private function openSubMenu(event:Event = null):void
		{
			// work around bug where menu doesn't open on mouseDown
			if (event && event.type == MouseEvent.MOUSE_DOWN)
			{
				_uiParent.callLater(openSubMenu);
				return;
			}
			
			if(toggleSubMenu)
			{
				toggleSubMenu = false;
				return;
			}
			
			toggleSubMenu = true;
			
			if(subMenuDataProvider.length == 0)
				subMenuItem = Menu.createMenu(_uiParent,new SubMenuItem(),false);
			
			var menuLocation:Point = _uiParent.contentToGlobal(new Point(0,_uiParent.height));
			
			var stage:Stage = Application.application.stage;
			var tempBounds:Bounds2D = new Bounds2D();
			tempBounds.setBounds(stage.x, stage.y, stage.stageWidth, stage.stageHeight);
			
			var xMin:Number = tempBounds.getXNumericMin();
			var yMin:Number = tempBounds.getYNumericMin();
			var xMax:Number = tempBounds.getXNumericMax();
			var yMax:Number = tempBounds.getYNumericMax();
			
			subMenuItem.setStyle("openDuration",0);
			subMenuItem.show(menuLocation.x,menuLocation.y);
				
			if (menuLocation.x < xMin)
				menuLocation.x = xMin;
			else if(menuLocation.x + subMenuItem.width > xMax)
				menuLocation.x = xMax - subMenuItem.width;
			
			if (menuLocation.y < yMin)
				menuLocation.y = yMin + _uiParent.height;
			else if (menuLocation.y > yMax)
				menuLocation.y = yMax - subMenuItem.height - _uiParent.height;
			
			subMenuItem.move(menuLocation.x,menuLocation.y);
				
		}
		
		private function closeSubMenu(event:Event):void
		{
			subMenuItem.hide();
		}
	}
}

internal class SubMenuItem
{
	public var label:String;
	public var listener:Function;
	public var params:Array;
}
