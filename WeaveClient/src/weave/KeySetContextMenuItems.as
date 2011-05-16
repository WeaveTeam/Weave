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

package weave
{
	import flash.display.DisplayObject;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.core.Application;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	import mx.rpc.AsyncToken;
	
	import weave.Weave;
	import weave.api.copySessionState;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IDataRowSource;
	import weave.data.KeySets.KeyFilter;
	import weave.data.KeySets.KeySet;
	import weave.services.DelayedAsyncResponder;
	import weave.services.WeaveDataServlet;
	import weave.ui.CustomContextMenuManager;
	import weave.ui.RecordDataTable;
	import weave.utils.ProbeTextUtils;
	
	/**
	 * TODO: this code should be moved into the multiVisLayer class
	 * This code does not work when KeySets other than the default ones are used in the keySetCollection object.
	 * The menu item functions should know what multiVisLayer is relevant to the context menu.
	 * 
	 * @author abaumann
	 * @author adufilie
	 */
	public class KeySetContextMenuItems
	{
		private static var _createSubsetCMI:ContextMenuItem = null;
		private static var _addToSubsetCMI:ContextMenuItem = null;
		private static var _removeFromSubsetCMI:ContextMenuItem = null;
		private static var _showAllRecordsCMI:ContextMenuItem = null;
		private static var _viewRecordCMI:ContextMenuItem = null;
		
		//todo: get these from the active visualization instead?
		private static var subset:KeyFilter = Weave.root.getObject(Weave.DEFAULT_SUBSET_KEYFILTER) as KeyFilter;
		private static var selection:KeySet = Weave.root.getObject(Weave.DEFAULT_SELECTION_KEYSET) as KeySet;
		
		private static var   _globalProbeKeySet:KeySet = null;        // pointer to global probe key set
		private static const _localProbeKeySet:KeySet = new KeySet(); // local object to store last non-empty probe set
		
		private static const groupName:String = "2 subsetMenuItems";
		
		private static const SUBSET_CREATE_SELECTION_CAPTION:String = "subset from selected record(s)";
		private static const SUBSET_CREATE_PROBE_CAPTION:String     = "subset from probed record(s)";
		private static const SUBSET_REMOVE_SELECTION_CAPTION:String = "selected record(s) from subset";
		private static const SUBSET_REMOVE_PROBE_CAPTION:String     = "probed record(s) from subset";
		
		/**
		 * @param context Any object created as a descendant of a Weave instance.
		 * @param destination The display object to add the context menu items to.
		 * @return true on success 
		 */		
		public static function createContextMenuItems(destination:DisplayObject):Boolean
		{
			if(!destination.hasOwnProperty("contextMenu") )
				return false;
			
			_globalProbeKeySet = Weave.root.getObject(Weave.DEFAULT_PROBE_KEYSET) as KeySet;
			
			var contextMenu:ContextMenu = destination["contextMenu"] as ContextMenu;

			// Add an event listener to this context menu for when it opens up -- this is where we will determine whether or not
			// these subset menu items should be active
			contextMenu.addEventListener(
					ContextMenuEvent.MENU_SELECT,
					function (e:ContextMenuEvent):void
					{
						copySessionState(_globalProbeKeySet, _localProbeKeySet);
						
						var usingIncludedKeys:Boolean = subset.included.keys.length > 0;
						var usingExcludedKeys:Boolean = subset.excluded.keys.length > 0;
						var includeMissingKeys:Boolean = subset.includeMissingKeys.value;
						var usingSubset:Boolean = includeMissingKeys ? usingExcludedKeys : true;
						var usingSelection:Boolean = _localProbeKeySet.keys.length > 0 || selection.keys.length > 0;
						
						// create subset only if we have something selected
						_createSubsetCMI.enabled   		= usingSelection;

						// first check to see if there is a selection - if so make subset from selection
						if(selection.keys.length > 0)
						{
							_removeFromSubsetCMI.caption = "Remove " + SUBSET_REMOVE_SELECTION_CAPTION;
							_createSubsetCMI.caption     = "Create " + SUBSET_CREATE_SELECTION_CAPTION;
						}
						// if there is not a selection and something is probed, then use it for the subset 
						else if(_localProbeKeySet.keys.length > 0)
						{
							_viewRecordCMI.enabled = true;
							_viewRecordCMI.caption = "Show data for probed record" + ((_localProbeKeySet.keys.length > 1)? "s" : "" );
							_removeFromSubsetCMI.caption = "Remove " + SUBSET_REMOVE_PROBE_CAPTION;
							_createSubsetCMI.caption     = "Create " + SUBSET_CREATE_PROBE_CAPTION;
						}
						if(_localProbeKeySet.keys.length <= 0 ) _viewRecordCMI.enabled = false;
						
						// add to subset only if we have a subset already and we have something selected
						//_addToSubsetCMI.enabled    		= usingSelection && usingSubset;
						// remove from subset only if we have something selected
						_removeFromSubsetCMI.enabled   	= usingSelection;
						// show all only if we have a subset already
						_showAllRecordsCMI.enabled 		= usingSubset;
					}
				);

			// create and add the create subset context menu item
			_createSubsetCMI = CustomContextMenuManager.createAndAddMenuItemToDestination(
					"Create " + SUBSET_CREATE_SELECTION_CAPTION, 
					destination,
					function (e:Event):void
					{
						if(selection.keys.length > 0)
						{
							subset.replaceKeys(false, true, selection.keys, null);
							selection.clearKeys();
						}
							// if there is not a selection and something is probed, then use it for the subset 
						else if(_localProbeKeySet.keys.length > 0)
						{
							subset.replaceKeys(false, true, _localProbeKeySet.keys, null);
						}
					},
					groupName
				);

			// create and add the add to subset context menu item
//			_addToSubsetCMI = CustomContextMenuManager.createAndAddMenuItemToDestination(
//					"Add Selected to Subset", 
//					destination,
//					function (e:Event):void
//					{
//						if (subset.keyType != selection.keyType)
//							subset.replaceKeys(false, selection.keyType, selection.keys, null);
//						else
//						{
//							subset.includeMissingKeys.value = false;
//							subset.includeKeys(selection.keys);
//						}
//						selection.clearKeys();
//					},
//					groupName
//				);

			// create and add the create remove from subset context menu item
			_removeFromSubsetCMI = CustomContextMenuManager.createAndAddMenuItemToDestination(
					"Remove " + SUBSET_REMOVE_SELECTION_CAPTION, 
					destination,
					function (e:Event):void
					{
						if(selection.keys.length > 0)
						{
							subset.excludeKeys(selection.keys);
							selection.clearKeys();
						}
						// if there is not a selection and something is probed, then use it for the subset 
						else if(_localProbeKeySet.keys.length > 0)
						{
							subset.excludeKeys(_localProbeKeySet.keys);
						}
						
					},
					groupName
				);

			// create and add the show all records context menu item														   
			_showAllRecordsCMI = CustomContextMenuManager.createAndAddMenuItemToDestination(
					"Show All Records", 
					destination,
					function (e:Event):void
					{
						subset.replaceKeys(true, true, null);
					},
					groupName
				);

			// create and add the view record(s) context menu item
			_viewRecordCMI = CustomContextMenuManager.createAndAddMenuItemToDestination(
				"Show data for probed record",
				destination,
				function (e:Event):void
				{
					var dataSources:Array = Weave.root.getObjects(IDataRowSource);
					
					var recordTable:RecordDataTable = new RecordDataTable();
					for each (var datasource:IDataRowSource in dataSources)
					{
						var token:AsyncToken = datasource.getRows(_localProbeKeySet.keys);
						DelayedAsyncResponder.addResponder(token, recordTable.handleGetRowResult, recordTable.handleGetRowFault);
					}
					recordTable.addEventListener(FlexEvent.CREATION_COMPLETE,
						function(e:FlexEvent):void
						{
							(e.target as RecordDataTable).setProbedKeySet(_localProbeKeySet);
						});
					PopUpManager.addPopUp(recordTable, Application.application as DisplayObject);
				},
				groupName
				);
			
        	return true;
        }
		
	}
}
