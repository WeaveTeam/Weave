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
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.collections.ArrayCollection;
	import mx.containers.HBox;
	import mx.containers.Panel;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.controls.Spacer;
	import mx.events.ListEvent;
	
	import weave.Weave;
	import weave.api.copySessionState;
	import weave.api.core.ILinkableObject;
	import weave.api.disposeObjects;
	import weave.api.linkBindableProperty;
	import weave.data.KeySets.KeySet;
	import weave.ui.AlertTextBox;
	import weave.ui.AlertTextBoxEvent;
	import weave.ui.CustomContextMenuManager;
	import weave.utils.ProbeTextUtils;
	
	public class SearchEngineUtils
	{
		private static var _globalProbeKeySet:KeySet = null; // pointer to global probe key set
		private static const _localProbeKeySet:KeySet = new KeySet(); // local object to store last non-empty probe set
		
		/**
		 * @param context Any object created as a descendant of a Weave instance.
		 * @param destination The display object to add the context menu items to.
		 * @return true on success 
		 */		
		public static function createContextMenuItems(destination:DisplayObject):Boolean
		{
			if(!destination.hasOwnProperty("contextMenu") )
				return false;
				
			if(!Weave.properties.enableSearchForRecord.value)
				return false;
			
			_globalProbeKeySet = Weave.root.getObject(Weave.DEFAULT_PROBE_KEYSET) as KeySet;
				
			var destinationContextMenu:ContextMenu = destination["contextMenu"] as ContextMenu;
			
			destinationContextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, handleContextMenuOpened);
						
			addSearchQueryContextMenuItem(<recordQuery queryServiceName=" "	rootURL=""/>, destination);
			
			return true;	
		}
		
		private static var _searchQueryContextMenuItems:Array = [];
		// Add a context menu item for searching for a given probed record in a search engine.
		public static function addSearchQueryContextMenuItem(description:XML, destination:DisplayObject):void
		{	
			if(!destination.hasOwnProperty("contextMenu") )
				return;
				
			var destinationContextMenu:ContextMenu = destination["contextMenu"] as ContextMenu;
			
						
			// When set, includeData will put the data descriptors shown in probing into the search criteria
			var includeData:Boolean     = description.@includeData != undefined;
			// Service name is what is shown to the user in the context menu so they know what engine they are seaching with
			var serviceName:String      = description.@queryServiceName;
			// Separator before allows a separator to be added to cre
			var separatorBefore:Boolean = description.@separatorBefore != undefined;

			
			var sq:ContextMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination(
					"Search for Record" + (includeData ? " and Data" : "") + " online" + serviceName, 
					destination, 
					handleSearchQueryContextMenuItemSelect,
					"3 searchMenuItems"
				);
			_searchQueryContextMenuItems.push( {contextMenu:sq, description:description} );
		}
		
		private static function handleContextMenuOpened(event:ContextMenuEvent):void
		{
			copySessionState(_globalProbeKeySet, _localProbeKeySet);
			
			for each (var c:Object in _searchQueryContextMenuItems)
			{
				(c.contextMenu as ContextMenuItem).enabled = _localProbeKeySet.keys.length > 0;
			}
		}
		
		private static function handleSearchQueryContextMenuItemSelect(event:ContextMenuEvent):void
		{
			var probeText:String = ProbeTextUtils.getProbeText(_localProbeKeySet, null, 1);
			if (probeText == null)
				return;
			// get first line of text only
			var query:String = probeText.split('\n')[0];
			for each(var c:Object in _searchQueryContextMenuItems)
			{
				var currentContextMenuItem:ContextMenuItem = (c.contextMenu as ContextMenuItem);
				if(currentContextMenuItem  == event.currentTarget)
				{
					if(currentContextMenuItem.enabled)
					{
						var combobox:ComboBox = new ComboBox(); //ComboBox to hold the service names
						var urlAlert:AlertTextBox = AlertTextBox.show("Custom URL",null);
						var hbox:HBox = new HBox();						
						var label:Label = new Label();
						var detailsButton:Button = new Button();
						
						detailsButton.toggle = true;
						detailsButton.label = "Show Details";
						detailsButton.toolTip = "Click to display the URL used for this service"
						urlAlert.alertVBox.removeChild(urlAlert.textBox);
						detailsButton.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void {																	
							if(detailsButton.selected) 
								urlAlert.alertVBox.addChildAt(urlAlert.textBox,2);
							else 								
								urlAlert.alertVBox.removeChild(urlAlert.textBox);							
						});
						
						hbox.toolTip = "Please select a service from the dropdown menu";
						urlAlert.textBox.toolTip = "This is the URL used to search for the record";
						label.text = "Select a service: ";
						
						hbox.addChild(label); hbox.addChild(combobox); hbox.addChild(detailsButton);
						urlAlert.alertVBox.addChildAt(hbox,0 );
						urlAlert.alertVBox.addChildAt(new Spacer(),0);
						
						try { // don't throw error if string is empty
							// replace any combinations of linefeeds and newlines with one newline character for consistency
							Weave.properties.searchServiceURLs.value = Weave.properties.searchServiceURLs.value.replace(/[\r\n]+/g,"\n");
							fillCBoxDataProvider(combobox);
							urlAlert.textInput = combobox.selectedItem.url;
						} catch (e:Error) {} 
						combobox.addEventListener(ListEvent.CHANGE, function(e:ListEvent):void{
							urlAlert.textInput = combobox.selectedItem.url;
						});
						urlAlert.addEventListener(AlertTextBoxEvent.BUTTON_CLICKED, function (e:AlertTextBoxEvent):void {
							if( !e.confirm ) return ;
							//append queried record's name to the end of the url
							navigateToURL(new URLRequest(urlAlert.textInput + query), "_blank");							
						});						
					}
				}
			}
		}
		
		private static function fillCBoxDataProvider(cbox:ComboBox):void
		{
			/* Example string in session state for Weave.properties.searchServiceURLs
			<searchServiceURLs>Wikipedia|http://en.wikipedia.org/wiki/Special:Search?search=
			Google|http://www.google.com/search?q=
			Google Images|http://images.google.com/images?q=
			Google Maps|http://maps.google.com/maps?t=h&amp;q=</searchServiceURLs>
			*/
			var services:Array = Weave.properties.searchServiceURLs.value.split("\n");
			var serviceObjects:Array = [] ;
			var serviceString:Array;
			for( var i:int = 0; i < services.length; i++ ) 
			{
				try{
					var obj:Object = new Object();
					serviceString = (services[i] as String).split( '|');
					obj.name = serviceString[0];
					obj.url = serviceString[1];
					serviceObjects.push(obj);
				} catch(error:Error){}
			}						
			cbox.dataProvider = new ArrayCollection(serviceObjects);
			//display only service name field in combobox
			cbox.labelField = 'name';		
		}		
	}
}