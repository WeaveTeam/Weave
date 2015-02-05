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
	import weave.data.KeySets.KeySet;
	import weave.ui.AlertTextBox;
	import weave.ui.AlertTextBoxEvent;
	import weave.ui.SelectionManager;
	import weave.ui.SelectionSelector;

	public class SelectionsMenu extends WeaveMenuItem
	{
		public static function selectionActive():Boolean
		{
			return Weave.defaultSelectionKeySet.keys.length > 0;
		}
		public static function getItemLabel(item:Object):String
		{
			var keySet:KeySet = item as KeySet || (item as WeaveMenuItem).data as KeySet;
			return lang("{0} ({1})", Weave.savedSelectionKeySets.getName(keySet), getRecordsText(keySet));
		}
		public static function copyItemState(item:Object):void
		{
			var keySet:KeySet = item as KeySet || (item as WeaveMenuItem).data as KeySet;
			WeaveAPI.SessionManager.copySessionState(keySet, Weave.defaultSelectionKeySet);
		}
		public static function getRecordsText(item:Object):String
		{
			var keySet:KeySet = item as KeySet || (item as WeaveMenuItem).data as KeySet;
			return lang("{0} records", keySet.keys.length);
		}
		
		/**
		 * Save the current selection
		 */
		public static function saveSelection():void
		{
			// create a text-input alert box for the user to enter the new name for the selection
			var alertBox:AlertTextBox = AlertTextBox.show(lang("Selection Name"), lang("Please enter a name for the selection: "));
			
			alertBox.addEventListener(AlertTextBoxEvent.BUTTON_CLICKED, function (e:AlertTextBoxEvent):void {
				// if the user clicked cancel, do nothing
				if( !e.confirm )
					return;
				var name:String = e.textInput;
				Weave.savedSelectionKeySets.requestObjectCopy(name, Weave.defaultSelectionKeySet);
				var _selectionSelector:SelectionSelector = Weave.root.getObject("SelectionSelector") as SelectionSelector;
				if( _selectionSelector )
					_selectionSelector.selectItem(name);
			});
		}
		
		public function SelectionsMenu()
		{
			var cachedItems:Array;
			super({
				shown: Weave.properties.enableSelectionsMenu,
				label: lang("Selections"),
				children: function(menu:WeaveMenuItem):Array {
					if (detectLinkableObjectChange(menu, Weave.savedSelectionKeySets))
						cachedItems = createItems([
							{
								shown: Weave.properties.enableSaveCurrentSelection,
								label: lang("Save current selection..."),
								click: saveSelection,
								enabled: selectionActive
							},{
								shown: Weave.properties.enableClearCurrentSelection,
								label: lang("Clear current selection"),
								click: Weave.defaultSelectionKeySet.clearKeys,
								enabled: selectionActive
							},
							TYPE_SEPARATOR,
							{
								shown: Weave.properties.enableManageSavedSelections,
								label: lang("Manage saved selections..."),
								click: function():void {
									// create the SelectionManager as a modal PopUp
									var popup:SelectionManager = PopUpManager.createPopUp(WeaveAPI.topLevelApplication as DisplayObject, SelectionManager) as SelectionManager;
									// this will disable dragging of this popup
									popup.isPopUp = false;
									PopUpManager.centerPopUp(popup);
								},
								enabled: function():Boolean { return Weave.savedSelectionKeySets.getNames().length > 0; }
							},{
								shown: [{not: Weave.properties.dashboardMode}, Weave.properties.enableSelectionSelectorBox],
								label: lang("Selection Selector Tool"),
								click: function():void {
									Weave.root.requestObject("SelectionSelector", SelectionSelector, false);
								}
							},
							TYPE_SEPARATOR,
							Weave.savedSelectionKeySets.getObjects().map(function(selection:Object, ..._):* {
								return {label: getItemLabel, click: copyItemState, data: selection};
							})
						]);
					
					return cachedItems;
				}
			});
		}
	}
}
