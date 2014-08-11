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
	import flash.utils.getQualifiedClassName;
	
	import mx.core.UIComponent;
	import mx.events.MenuEvent;
	
	import weave.compiler.StandardLib;
	import weave.menus.WeaveMenuItem;
	
	/**
	 * This class adds a submenu to any UI Compnent.
	 * 
	 * @author skolman
	 * @author adufilie
	 */
	public class SubMenu extends CustomMenu
	{
		/**
		 * Adds a submenu to any UI Component.
		 * @param uiParentComponent The UIComponent to add the submenu to.
		 * @param dataProvider Either a single WeaveMenuItem
		 *                     or an Array of WeaveMenuItems (or params to pass to the WeaveMenuItem constructor)
		 *                     or a Function returning such an Array.
		 */
		public function SubMenu(uiParent:UIComponent, dataProvider:Object = null)
		{
			if (uiParent == null)
				throw new Error("uiParent cannot be null");
			
			_uiParent = uiParent;
			
			setSubMenuEvents([MouseEvent.MOUSE_DOWN], [MouseEvent.MOUSE_DOWN, Event.REMOVED_FROM_STAGE]);
			
			includeInLayout = false;
			tabEnabled = false;
			owner = DisplayObjectContainer(WeaveAPI.topLevelApplication);
			showRoot = false; //test this
			
			addEventListener(MenuEvent.ITEM_CLICK, handleSubMenuItemClick);
			this.dataProvider = dataProvider;
		}
		
		private var _eventListeners:Object = {};
		
		/**
		 * Sets up event listeners that show and hide the SubMenu.
		 * @param openEvents A list of event types which will toggle the submenu.
		 *                   Default is [MouseEvent.MOUSE_DOWN].
		 *                   Supply an empty Array for no events.
		 * @param closeEvents A list of event types which will close the submenu.
		 *                    Default is [MouseEvent.MOUSE_DOWN, Event.REMOVED_FROM_STAGE].
		 *                    Supply an empty Array for no events.
		 */
		public function setSubMenuEvents(openEvents:Array, closeEvents:Array):void
		{
			var type:String;
			var func:Function;
			
			// remove previous event listeners
			for (type in _eventListeners)
				for each (func in _eventListeners[type])
					_uiParent.removeEventListener(type, func);
			
			// reset event listener mapping
			_eventListeners = {};
			var array:Array;
			for each (type in openEvents)
			{
				array = _eventListeners[type] || (_eventListeners[type] = []);
				if (closeEvents && closeEvents.indexOf(type) >= 0)
					array.push(toggleSubMenu);
				else
					array.push(openSubMenu);
			}
			for each (type in closeEvents)
			{
				array = _eventListeners[type] || (_eventListeners[type] = []);
				if (openEvents && openEvents.indexOf(type) < 0)
					array.push(closeSubMenu);
			}
			
			// add new event listeners
			for (type in _eventListeners)
				for each (func in _eventListeners[type])
					_uiParent.addEventListener(type, func);
		}
		
		private var _uiParent:UIComponent = null;
		
		private function handleSubMenuItemClick(event:MenuEvent):void
		{
			var item:WeaveMenuItem = event.item as WeaveMenuItem;
			if (item)
				item.runClickFunction();
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
		
		private var rootItem:WeaveMenuItem;
		
		override public function set dataProvider(value:Object):void
		{
			if (getQualifiedClassName(value) == 'Object')
				value = new WeaveMenuItem(value);
			if (value is Array || value is Function)
				value = new WeaveMenuItem({children: value});
			rootItem = value as WeaveMenuItem;
			super.dataProvider = value;
		}
		
		public function showSubMenu():void
		{
			if (!dataProvider)
				return;
			
			var stage:Stage = WeaveAPI.StageUtils.stage;
			var xMin:Number = 0;
			var yMin:Number = 0;
			var xMax:Number = stage.stageWidth;
			var yMax:Number = stage.stageHeight;
			
			var parentGlobal:Point = _uiParent.localToGlobal(new Point(0, 0));
			var parentHeight:Number = _uiParent.height;
			
			setStyle("openDuration", 0);
			popUpMenu(this, _uiParent, rootItem || dataProvider);
			
			// first show menu below parent so the width and height get calculated
			show(parentGlobal.x, parentGlobal.y + parentHeight);
			
			var global:Point = this.parent.localToGlobal(new Point(x, y));
			// make sure we are on stage in x coordinates
			global.x = StandardLib.constrain(global.x, xMin, xMax - measuredWidth);
			// if we extend below the stage and there is more room above, move above the parent
			var moreRoomAbove:Boolean = parentGlobal.y - yMin > yMax - (parentGlobal.y + parentHeight);
			var extendsBelowStage:Boolean = global.y + measuredHeight > yMax;
			if (moreRoomAbove && extendsBelowStage)
				global.y -= measuredHeight + parentHeight;
			
			// move to adjusted position
			var parentLocal:Point = parent.globalToLocal(global);
			move(parentLocal.x, parentLocal.y);
			
			setFocus();
		}
	}
}
