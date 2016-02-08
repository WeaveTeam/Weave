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

package weave.application
{
	import flash.display.DisplayObject;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import weave.Weave;
	import weave.api.copySessionState;
	import weave.data.KeySets.KeyFilter;
	import weave.data.KeySets.KeySet;
	import weave.api.data.IQualifiedKey;
	import weave.ui.CustomContextMenuManager;

	import weave.data.DataSources.AnnotationDataSource;
	import weave.ui.AlertTextBox;
	import weave.ui.AlertTextBoxEvent;
	
	/**
	 * TODO: this code should be moved into the multiVisLayer class
	 * This code does not work when KeySets other than the default ones are used in the keySetCollection object.
	 * The menu item functions should know what multiVisLayer is relevant to the context menu.
	 * 
	 * @author abaumann
	 * @author adufilie
	 */
	internal class KeySetContextMenuItems
	{
		private static var _createSubsetCMI:ContextMenuItem = null;
		private static var _addToSubsetCMI:ContextMenuItem = null;
		private static var _removeFromSubsetCMI:ContextMenuItem = null;
		private static var _showAllRecordsCMI:ContextMenuItem = null;
		private static var _annotateRecordsCMI:ContextMenuItem = null;
//		private static var _viewRecordCMI:ContextMenuItem = null;
/*
// TODO: move this clustering code to the appropriate locations: DataMiningPlatter, DataStatisticsTool
		private static var _runClusteringonSubsetCMI:ContextMenuItem = null;
		private static var _doStatisticsonSubsetCMI:ContextMenuItem = null;
*/		
		//todo: get these from the active visualization instead?
		private static var subset:KeyFilter = Weave.root.getObject(Weave.DEFAULT_SUBSET_KEYFILTER) as KeyFilter;
		private static var selection:KeySet = Weave.root.getObject(Weave.DEFAULT_SELECTION_KEYSET) as KeySet;
		
		private static var   _globalProbeKeySet:KeySet = null;        // pointer to global probe key set
		private static const _localProbeKeySet:KeySet = new KeySet(); // local object to store last non-empty probe set
		
		private static const groupName:String = "1 subsetMenuItems";
		
		private static const SUBSET_CREATE_SELECTION_CAPTION:String = lang("Create subset from selected record(s)");
		private static const SUBSET_CREATE_PROBE_CAPTION:String     = lang("Create subset from highlighted record(s)");
		private static const SUBSET_REMOVE_SELECTION_CAPTION:String = lang("Remove selected record(s) from subset");
		private static const SUBSET_REMOVE_PROBE_CAPTION:String     = lang("Remove highlighted record(s) from subset");
		private static const ANNOTATE_SELECTED_RECORDS_CAPTION:String = lang("Annotate selected record(s)");
		private static const ANNOTATE_HIGHLIGHTED_RECORDS_CAPTION:String = lang("Annotate highlighted record(s)");
		
/*
		private static const SUBSET_RUN_CLUSTERING_CAPTION:String           = lang("Run clustering on subset");
		private static const SUBSET_DO_STATISTICS_CAPTION:String = lang("Compute Statistics on subset");
*/		
		private static function get _defaultAnnotationSource():AnnotationDataSource
		{
			var annotationSource:AnnotationDataSource;

			var annotationSourceList:Array = WeaveAPI.globalHashMap.getObjects(AnnotationDataSource);

			if (annotationSourceList.length)
				annotationSource = annotationSourceList[0] as AnnotationDataSource;
			else
			{
				annotationSource = WeaveAPI.globalHashMap.requestObject("Annotations", AnnotationDataSource, false);
				annotationSource.addDefaultProbeColumn();
			}

			return annotationSource;
		}
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
						_annotateRecordsCMI.enabled		= usingSelection;

/*
						_runClusteringonSubsetCMI.enabled       = usingSelection;
						_doStatisticsonSubsetCMI.enabled  = usingSelection;
*/

						// first check to see if there is a selection - if so make subset from selection
						if(selection.keys.length > 0)
						{
							_removeFromSubsetCMI.caption = SUBSET_REMOVE_SELECTION_CAPTION;
							_createSubsetCMI.caption     = SUBSET_CREATE_SELECTION_CAPTION;
							_annotateRecordsCMI.caption  = ANNOTATE_SELECTED_RECORDS_CAPTION;
/*
							_runClusteringonSubsetCMI.caption = SUBSET_RUN_CLUSTERING_CAPTION;
							_doStatisticsonSubsetCMI.caption = SUBSET_DO_STATISTICS_CAPTION;
*/
						}
						// if there is not a selection and something is probed, then use it for the subset 
						else if(_localProbeKeySet.keys.length > 0)
						{
//							_viewRecordCMI.enabled = true;
//							_viewRecordCMI.caption = lang("Show data for highlighted record" + ((_localProbeKeySet.keys.length > 1)? "s" : "" ));
							_removeFromSubsetCMI.caption = SUBSET_REMOVE_PROBE_CAPTION;
							_createSubsetCMI.caption     = SUBSET_CREATE_PROBE_CAPTION;
							_annotateRecordsCMI.caption  = ANNOTATE_HIGHLIGHTED_RECORDS_CAPTION;
						}
//						if(_localProbeKeySet.keys.length <= 0 ) _viewRecordCMI.enabled = false;
						
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
					SUBSET_CREATE_SELECTION_CAPTION, 
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
/*			
			
			_runClusteringonSubsetCMI = CustomContextMenuManager.createAndAddMenuItemToDestination(
				SUBSET_RUN_CLUSTERING_CAPTION,
				destination,
					function (e:Event):void
					{
						trace("running clustering");
						//collect selected records and send to the clustering collection to send to R
						//needed to collect the tool on which the context menu is opened
						var activeTool:DraggablePanel = CustomContextMenuManager.activePanel;
						var attrs:Array = (activeTool as SimpleVisTool).getSelectableAttributes();
						var input:LinkableHashMap;
						for(var i :int = 0; i < attrs.length; i++)
						{
							if(attrs[i] is LinkableHashMap)//picking up only the hashmap of the current opened tool
								input = attrs[i];
						}
						
						var dmTool:DataMiningPlatter = DataMiningPlatter.getPlatterInstance();
						dmTool.selectedRecords = selection.keys;
						dmTool.inputVariables = input;
						dmTool.subsetSelectedOn = true;
						FlexGlobals.topLevelApplication.visDesktop.addChild(dmTool);
						
					},
					groupName
				);
			
			_doStatisticsonSubsetCMI = CustomContextMenuManager.createAndAddMenuItemToDestination(
				SUBSET_DO_STATISTICS_CAPTION,
				destination,
				function(e:Event):void
				{
					trace("computing statistics");
					//collect selected records and send to R
					//needed to collect the tool on which the context menu is opened
					var activeTool:DraggablePanel = CustomContextMenuManager.activePanel;
					var attrs:Array = (activeTool as SimpleVisTool).getSelectableAttributes();
					var input:LinkableHashMap;
					
					for(var d:int = 0; d < attrs.length; d++)
					{
						if(attrs[d] is ILinkableHashMap)
						input = attrs[d];
					}
					
					var statTool:DataStatisticsTool = DataStatisticsTool.getStatToolInstance();
					statTool.selectedRecords = selection.keys;
					statTool.inputVariables = input;
					FlexGlobals.topLevelApplication.visDesktop.addChild(statTool);
					
				},
				groupName
				
				);
*/				
				
				
				
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
					SUBSET_REMOVE_SELECTION_CAPTION, 
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
					lang("Show All Records"), 
					destination,
					function (e:Event):void
					{
						subset.replaceKeys(true, true);
					},
					groupName
				);

			_annotateRecordsCMI = CustomContextMenuManager.createAndAddMenuItemToDestination(
					ANNOTATE_HIGHLIGHTED_RECORDS_CAPTION,
					destination,
					function (e:Event):void
					{
						var keys:Array;
						if (selection.keys.length > 0)
							keys = selection.keys;
						else if (_localProbeKeySet.keys.length > 0)
							keys = _localProbeKeySet.keys;
						
						var annotateBox:AlertTextBox = AlertTextBox.show(lang("Annotate Records"),  lang("Annotation for record(s):"), _defaultAnnotationSource.getAnnotation(keys[0]));
						annotateBox.addEventListener(AlertTextBoxEvent.BUTTON_CLICKED, function (e:AlertTextBoxEvent):void {
							if (!e.confirm) return;
							var value:String = annotateBox.textInput;
							for (var idx:int = 0; idx < keys.length; idx++)
							{
								_defaultAnnotationSource.setAnnotation(keys[idx], value);
							}
						});


					},
					groupName
				);
			/*
			// create and add the view record(s) context menu item
			_viewRecordCMI = CustomContextMenuManager.createAndAddMenuItemToDestination(
				lang("Show data for highlighted record"),
				destination,
				function (e:Event):void
				{
					var dataSources:Array = Weave.root.getObjects(IDataRowSource);
					
					var recordTable:RecordDataTable = new RecordDataTable();
					for each (var datasource:IDataRowSource in dataSources)
					{
						var token:AsyncToken = datasource.getRows(_localProbeKeySet.keys);
						addAsyncResponder(token, recordTable.handleGetRowResult, recordTable.handleGetRowFault);
					}
					recordTable.addEventListener(FlexEvent.CREATION_COMPLETE,
						function(e:FlexEvent):void
						{
							(e.target as RecordDataTable).setProbedKeySet(_localProbeKeySet);
						});
					PopUpManager.addPopUp(recordTable, WeaveAPI.topLevelApplication as DisplayObject);
				},
				groupName
				);
			*/
			return true;
		}
		
	}
}
