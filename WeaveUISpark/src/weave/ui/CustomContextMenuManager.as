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

package weave.ui
{
	import flash.events.ContextMenuEvent;
	import flash.ui.ContextMenuItem;
	import flash.utils.Dictionary;
	
	import weave.compiler.StandardLib;
	
	public class CustomContextMenuManager
	{
		public function CustomContextMenuManager()
		{
		}

		// (contextMenuDefinitions:Dictionary[contextMenu:ContextMenu][groupName:String]):(Array of ContextMenuItem objects)
		private static var contextMenuDefinitions:Dictionary = new Dictionary(true); // maps destination object to menu item grouping Object[String]=ContextMenuItem
		
		public static function removeAllContextMenuItems():void
		{
			contextMenuDefinitions = new Dictionary(true);
		}
		public static function addMenuItemsToDestination(menuItems:Array, destination:Object, groupName:String="mainGroup"):void
		{
			// if the destination does not have a context menu then return null, we cannot add items to an object that does not have a context menu definition
			if (!destination.hasOwnProperty("contextMenu"))
				return;
			
			if (menuItems.length == 0)
				return;
			
			
			// if we do not have a definition for this context menu, then create one
			if (contextMenuDefinitions[destination.contextMenu] == undefined)
			{
				// each context menu definition is an array of objects that define groups and the menu items that fall in these groups
				contextMenuDefinitions[destination.contextMenu] = new Object();
			}
			
			// get the groups definition now that it is created
			var groups:Object = contextMenuDefinitions[destination.contextMenu] as Object;
			
			// initialize the group if it has not yet been initialized
			if (groups[groupName] == undefined)
			{
				groups[groupName] = [];
				// since this is the first item in the list, put a separator before this item to separate it from other groups in the list
				menuItems[0].separatorBefore = true;
			}

			var menuItem:ContextMenuItem;

			// add menu items to specified group
			for each (menuItem in menuItems)
				(groups[groupName] as Array).push(menuItem);

			// get a list of the groups, then sort
			var groupNames:Array = [];
			var _groupName:String;
			for (_groupName in groups)
				groupNames.push(_groupName);
			StandardLib.sort(groupNames);
			
			// go through each menu item in each group and add these to the context menu for this destination
			var newMenuItems:Array = [];
			for each (_groupName in groupNames)
			{
				for each(menuItem in groups[_groupName])
				{
					newMenuItems.push(menuItem);
				}
			}
			
			
			
			destination.contextMenu.customItems = newMenuItems;

			/*destination.addEventListener(    Event.REMOVED_FROM_STAGE, 
										     function(e:Event):void {
												menuItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT, itemSelectListener);
										     }
			                             );
			
			destination.addEventListener(    Event.ADDED_TO_STAGE, 
										     function(e:Event):void {
												menuItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT, itemSelectListener);
												menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, itemSelectListener);	
										     }
			                             );*/
			
			return;
		}
		public static function createAndAddMenuItemToDestination(text:String, destination:Object, itemSelectListener:Function, groupName:String="mainGroup"):ContextMenuItem
		{
			// if the destination does not have a context menu then return null, we cannot add items to an object that does not have a context menu definition
			if(!destination.hasOwnProperty("contextMenu") )
				return null;
				
			// create the menu item from the passed parameters
			var menuItem:ContextMenuItem = new ContextMenuItem(text);
			menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, itemSelectListener);

			addMenuItemsToDestination([menuItem], destination, groupName);
			return menuItem;
		}

		public static var activePanel:Object;
		
		
		/*
		
		
		private var _createSubsetMenuItem:ContextMenuItem   = new ContextMenuItem("Create Subset from Selected");
		private var _addToSubsetMenuItem:ContextMenuItem    = new ContextMenuItem("Add Selected to Subset");
		private var _removeSubsetMenuItem:ContextMenuItem   = new ContextMenuItem("Remove Selected from Subset");
		private var _showAllRecordsMenuItem:ContextMenuItem = new ContextMenuItem("Show All Records");
		
		private var _wikiQuery:String = "";
		private var _wikiRecordMenuItem:ContextMenuItem       = new ContextMenuItem("Search for Record with WikiPedia");
		
		private var _googleQuery:String = "";
		private var _googleRecordMenuItem:ContextMenuItem     = new ContextMenuItem("Search for Record with Google");
		private var _googleDataQuery:String = "";
		private var _googleDataRecordMenuItem:ContextMenuItem = new ContextMenuItem("Search for Record and Data with Google");
		private var _googleImagesQuery:String = "";
		private var _googleImagesMenuItem:ContextMenuItem = new ContextMenuItem("Search for Record with Google Images");
		private var _googleMapsMenuItem:ContextMenuItem = new ContextMenuItem("Search for Record with Google Maps");
		
		private var _printToolMenuItem:ContextMenuItem = new ContextMenuItem("Print Tool Image");
		
		_createSubsetMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_addToSubsetMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_removeSubsetMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_showAllRecordsMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_wikiRecordMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_googleRecordMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_googleDataRecordMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_printToolMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleContextMenuItemSelect);
		_googleImagesMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleContextMenuItemSelect);
		_googleMapsMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleContextMenuItemSelect);
		
		this.parentApplication.contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, handleContextMenuSelect);
		
		

		if(!_menuCreated)
		{
			//hide the Flash menu
			this.parentApplication.contextMenu.hideBuiltInItems();
			
			_createSubsetMenuItem.separatorBefore = true;
			this.parentApplication.contextMenu.customItems.push(_createSubsetMenuItem);
			this.parentApplication.contextMenu.customItems.push(_addToSubsetMenuItem);
			this.parentApplication.contextMenu.customItems.push(_removeSubsetMenuItem);
			this.parentApplication.contextMenu.customItems.push(_showAllRecordsMenuItem);
			
			_wikiRecordMenuItem.separatorBefore = true;
			this.parentApplication.contextMenu.customItems.push(_wikiRecordMenuItem);
			this.parentApplication.contextMenu.customItems.push(_googleRecordMenuItem);
			this.parentApplication.contextMenu.customItems.push(_googleDataRecordMenuItem);	
			this.parentApplication.contextMenu.customItems.push(_googleImagesMenuItem);
			this.parentApplication.contextMenu.customItems.push(_googleMapsMenuItem);
			
			_printToolMenuItem.separatorBefore = true;
			this.parentApplication.contextMenu.customItems.push(_printToolMenuItem);
		
			_menuCreated = true;
		}
	}
	private function handleRemovedFromStage(event:Event):void
	{
		trace("removed from stage");
		removeMouseListeners();
		removeProbeAndSelectionCallbacks(keyType.value);
		keyType.unbind(DataRepository.defaultBindableKeyType);
		
		
		_createSubsetMenuItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_addToSubsetMenuItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_removeSubsetMenuItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_showAllRecordsMenuItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_wikiRecordMenuItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_googleRecordMenuItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_googleDataRecordMenuItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT,handleContextMenuItemSelect);
		_googleImagesMenuItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleContextMenuItemSelect);
		_printToolMenuItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleContextMenuItemSelect);
		_googleMapsMenuItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleContextMenuItemSelect);
		
		this.parentApplication.contextMenu.removeEventListener(ContextMenuEvent.MENU_SELECT, handleContextMenuSelect);
	}*/
	}
}