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

package weave.menus
{
	import flash.display.DisplayObject;
	
	import mx.managers.PopUpManager;
	
	import weave.Weave;
	import weave.api.detectLinkableObjectChange;
	import weave.data.KeySets.KeyFilter;
	import weave.ui.AlertTextBox;
	import weave.ui.AlertTextBoxEvent;
	import weave.ui.SelectionManager;
	import weave.ui.SubsetManager;
	import weave.ui.SubsetSelector;

	public class SubsetsMenu extends WeaveMenuItem
	{
		public static function getItemLabel(item:Object):String
		{
			var subset:KeyFilter = item as KeyFilter || (item as WeaveMenuItem).data as KeyFilter;
			return lang("{0} ({1})",
				Weave.savedSubsetsKeyFilters.getName(subset),
				getRecordsText(subset)
			);
		}
		
		public static function copyItemState(item:Object):void
		{
			var subset:KeyFilter = item as KeyFilter || (item as WeaveMenuItem).data as KeyFilter;
			WeaveAPI.SessionManager.copySessionState(subset, Weave.defaultSubsetKeyFilter);
		}
		
		public static function getRecordsText(keyFilter:KeyFilter):String
		{
			if (keyFilter.includeMissingKeys.value)
				return lang("{0} excluded records", keyFilter.excluded.keys.length);
			else
				return lang("{0} records", keyFilter.included.keys.length);
		}
		
		public static function subsetActive():Boolean
		{
			// a subset is available when the included or excluded keys are of length 1 or more
			return Weave.defaultSubsetKeyFilter.included.keys.length > 0 || Weave.defaultSubsetKeyFilter.excluded.keys.length > 0;
		}
		
		/**
		 * Handle saving of a new subset the user has created
		 **/
		public static function saveSubset():void
		{
			var alertBox:AlertTextBox = AlertTextBox.show(lang("Subset Name"), lang("Please enter a name for the subset: "));
			
			alertBox.addEventListener(AlertTextBoxEvent.BUTTON_CLICKED, 
				function (e:AlertTextBoxEvent):void 
				{
					// if the user clicked cancel, then we will just return from here and save nothing
					if( !e.confirm ) return;
					
					var name:String = e.textInput;
					Weave.savedSubsetsKeyFilters.requestObjectCopy(name, Weave.defaultSubsetKeyFilter);
					var _subsetSelector:SubsetSelector = Weave.root.getObject("SubsetSelector") as SubsetSelector;
					if( _subsetSelector )
						_subsetSelector.selectItem(name); // once saved, auto select the subset in the tool
				}
			);
		}
		
		public function SubsetsMenu()
		{
			var cachedItems:Array;
			super({
				shown: Weave.properties.enableSubsetsMenu,
				label: lang("Subsets"),
				children: function(menu:WeaveMenuItem):Array {
					if (detectLinkableObjectChange(menu, Weave.savedSubsetsKeyFilters))
						cachedItems = createItems([
							{
								shown: Weave.properties.enableCreateSubsets,
								label: lang("Create subset from selected records"),
								click: function():void {
									Weave.defaultSubsetKeyFilter.replaceKeys(false, true, Weave.defaultSelectionKeySet.keys);
									Weave.defaultSelectionKeySet.clearKeys();
								},
								enabled: SelectionsMenu.selectionActive
							},{
								shown: [Weave.properties.enableCreateSubsets, Weave.properties.enableSaveCurrentSubset],
								label: lang("Create and save subset from selected records"),
								click: function():void {
									Weave.defaultSubsetKeyFilter.replaceKeys(false, true, Weave.defaultSelectionKeySet.keys);
									Weave.defaultSelectionKeySet.clearKeys();
									saveSubset();
								},
								enabled: [subsetActive, SelectionsMenu.selectionActive]
							},{
								shown: Weave.properties.enableRemoveSubsets,
								label: lang("Remove selected records from subset"),
								click: function():void {
									// we will use the selected records as excluded keys and clear the current selection which is no longer valid
									Weave.defaultSubsetKeyFilter.excludeKeys(Weave.defaultSelectionKeySet.keys);
									Weave.defaultSelectionKeySet.clearKeys();
								},
								enabled: SelectionsMenu.selectionActive
							},{
								shown: Weave.properties.enableShowAllRecords,
								label: lang("Show all records"),
								click: function():void {
									Weave.defaultSubsetKeyFilter.replaceKeys(true, true);
									Weave.defaultSelectionKeySet.clearKeys();
								},
								enabled: subsetActive
							},
							TYPE_SEPARATOR,
							{
								shown: Weave.properties.enableSaveCurrentSubset,
								label: lang("Save current subset..."),
								click: saveSubset,
								enabled: subsetActive
							},{
								shown: Weave.properties.enableManageSavedSubsets,
								label: lang("Manage saved subsets..."),
								click: function():void {
									// when a user clicks this option we will create the SelectionManager as a popup 
									var popup:SelectionManager = PopUpManager.createPopUp(WeaveAPI.topLevelApplication as DisplayObject, SubsetManager) as SubsetManager;
									
									// this makes it so the popup is not draggable
									//popup.isPopUp = false;
									
									PopUpManager.centerPopUp(popup);
								},
								enabled: function():Boolean {
									// we can manage subsets when there is at least one saved subset
									return Weave.savedSubsetsKeyFilters.getNames().length > 0;
								}
							},{
								shown: [{not: Weave.properties.dashboardMode}, Weave.properties.enableSubsetSelectionBox],
								label: lang("Subset Selector Tool"),
								click: function():void {
									Weave.root.requestObject("SubsetSelector", SubsetSelector, false);
								}
							},
							TYPE_SEPARATOR,
							Weave.savedSubsetsKeyFilters.getObjects().map(function(subset:Object, ..._):* {
								return {label: getItemLabel, click: copyItemState, data: subset};
							})
						]);
					
					return cachedItems;
				}
			});
		}
	}
}
