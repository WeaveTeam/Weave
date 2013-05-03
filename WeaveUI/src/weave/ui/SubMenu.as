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
	import mx.utils.ArrayUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.reportError;
	import weave.primitives.Bounds2D;
	import weave.services.beans.RResult;
	
	/**
	 * This class adds a submenu to any UI Compnent.
	 * Contructor takes a parent UIComponent and a String array of event listeners
	 * Use the addSubMenuItem function to add menu items
	 * 
	 * @author skolman
	 * @author adufilie
	 */
	public class SubMenu extends Menu
	{
		/**
		 * Adds a submenu to any UI Compnent.
		 * Contructor takes a parent UIComponent and a String array of event listeners
		 * Use the addSubMenuItem function to add menu items
		 * @param uiParentComponent The UIComponent to add the submenu to.
		 * @param openMenuEventTypes A list of event types which will toggle the submenu.
		 * @param closeMenuEventTypes A list of event types which will close the submenu.
		 */
		public function SubMenu(uiParent:UIComponent, openMenuEventTypes:Array = null, closeMenuEventTypes:Array = null)
		{
			if (uiParent == null)
				throw new Error("uiParent cannot be null");
			
			_uiParent = uiParent;
			
			var type:String;
			for each (type in openMenuEventTypes)
				_uiParent.addEventListener(type, openSubMenu);
			for each (type in closeMenuEventTypes)
				_uiParent.addEventListener(type, closeSubMenu);
			
			includeInLayout = false;
			tabEnabled = false;
			owner = DisplayObjectContainer(WeaveAPI.topLevelApplication);
			showRoot = false; //test this
		}
		
		private var _uiParent:UIComponent = null;
		
		//		private var subMenu:Menu;
		
		private var subMenuDataProvider:Array = [];
		
		/**
		 * Adds an item to the menu.
		 * @param label The Label string to show when the menu is open
		 * @param listener The function to call when the item is clicked.
		 * @param params An Array of parameters to pass to the listener function.
		 */
		public function addSubMenuItem(label:String,listener:Function,params:Array=null):void
		{
			var menuItem:SubMenuItem = null;
			
			/* Check if there is already a menu item with same label*/
			for each(var obj:Object in subMenuDataProvider)
			{
				if(obj.label && obj.label == label)
				{
					menuItem = obj as SubMenuItem;
					break;
				}
			}
			
			/* if not then create new SubMenuItem*/
			if(menuItem ==null)
			{
				menuItem = new SubMenuItem();
				menuItem.label = label;
				subMenuDataProvider.push(menuItem);
			}
			
			menuItem.listener = listener;
			menuItem.params = params;
			
			addEventListener(MenuEvent.ITEM_CLICK,handleSubMenuItemClick);
			
			addEventListener(MenuEvent.MENU_HIDE,function():void{toggleSubMenu = false;});
			
			
		}
		
		/**
		 * Adds a menu item with submenu items
		 * @param parentLabel The label of the parent menu
		 * @param childLabels An array of labels for each submenu item
		 * @param childListeners An array of functions to call when the respective submenu item is clicked. Assumes same order as childLabels.
		 * @param childParams An Array of array of parameters to pass to the respective listener functions. Assumes same order as childLabels.
		 * */
		public function addSubSubMenuItems(parentLabel:String,childLabels:Array,childListeners:Array,childParams:Array=null):void
		{
			var parentItem:Object = null;
			
			for each(var obj:Object in subMenuDataProvider)
			{
				if(obj.label && obj.label == parentLabel)
				{
					parentItem = obj;
					break;
				}
			}
			var children:Array = [];
			if(parentItem && parentItem.children)
				children= parentItem.children as Array;
			var temp:Array = [];
			for (var i:int =0; i< childLabels.length; i++)
			{
				if(children.length>0)
				{
					for(var j:int =0; j < children.length; j++)
					{
						if(children[j].label==childLabels[i])
							(parentItem.children as Array).splice(j,1);
					}
				}
				var menuItem:SubMenuItem = new SubMenuItem();
				menuItem.label = childLabels[i];
				menuItem.listener = childListeners[i];
				if(childParams && childParams[i])
					menuItem.params = childParams[i];
				temp.push(menuItem);
			}
			
			temp = children.concat(temp);
			/* If parentItem doesn't exist create new parent with label and children else concatenate children*/
			if(!parentItem)
			{
				parentItem= new Object();
				parentItem.label = parentLabel;
				parentItem.children = temp;
				subMenuDataProvider.push(parentItem);
			}
			else
			{
				if(parentItem.children is Array)
				{
					parentItem.children = temp;
				}
				else
				{
					reportError("Error adding items to node submenu");
				}
			}
			
			addEventListener(MenuEvent.ITEM_CLICK,handleSubMenuItemClick);
			
			addEventListener(MenuEvent.MENU_HIDE,function():void{toggleSubMenu = false;});
		}
		
		/**
		 * Removes all menu items
		 */ 
		public function removeAllSubMenuItems():void
		{
			subMenuDataProvider = []; 
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
			
			//			if(subMenuDataProvider.length == 0)
			//				subMenu = Menu.createMenu(_uiParent,new SubMenuItem(),false);
			
			
			showSubMenu();
			
			
		}
		
		private function closeSubMenu(event:Event):void
		{
			hide();
		}
		
		public function showSubMenu():void
		{
			var menuLocation:Point = _uiParent.localToGlobal(new Point(0,_uiParent.height));
			
			var stage:Stage = WeaveAPI.topLevelApplication.stage;
			var tempBounds:Bounds2D = new Bounds2D();
			tempBounds.setBounds(0, 0, stage.stageWidth, stage.stageHeight);
			
			var xMin:Number = tempBounds.getXNumericMin();
			var yMin:Number = tempBounds.getYNumericMin();
			var xMax:Number = tempBounds.getXNumericMax();
			var yMax:Number = tempBounds.getYNumericMax();
			
			setStyle("openDuration",0);
			popUpMenu(this, _uiParent, subMenuDataProvider);
			show(menuLocation.x, menuLocation.y);
			
			if (menuLocation.x < xMin)
				menuLocation.x = xMin;
			else if(menuLocation.x + width > xMax)
				menuLocation.x = xMax - width;
			
			if (menuLocation.y < yMin)
				menuLocation.y = yMin + _uiParent.height;
			else if (menuLocation.y + height > yMax)
				menuLocation.y -= height + _uiParent.height;
			
			move(menuLocation.x,menuLocation.y);
		}
		
	}
}

internal class SubMenuItem
{
	public var label:String;
	public var listener:Function;
	public var params:Array;
}
