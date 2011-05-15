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
package org.oicweave
{
	import flash.display.DisplayObject;
	import flash.events.ContextMenuEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import org.oicweave.Weave;
	import org.oicweave.api.copySessionState;
	import org.oicweave.api.core.ILinkableObject;
	import org.oicweave.data.KeySets.KeySet;
	import org.oicweave.ui.CustomContextMenuManager;
	import org.oicweave.utils.ProbeTextUtils;
	
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
			
			
			// Add some default context menu items to handle searching for a given record
		    addSearchQueryContextMenuItem(<recordQuery queryServiceName="WikiPedia"     rootURL="http://en.wikipedia.org/wiki/Special:Search?search="/>, destination);
		    addSearchQueryContextMenuItem(<recordQuery queryServiceName="Google"        rootURL="http://www.google.com/search?q="/>, destination);
		//	addSearchQueryContextMenuItem(<recordQuery queryServiceName="Google" 	    rootURL="http://www.google.com/search?q=" includeData="true"/>, destination);
		    addSearchQueryContextMenuItem(<recordQuery queryServiceName="Google Images" rootURL="http://images.google.com/images?q="/>, destination);
		    addSearchQueryContextMenuItem(<recordQuery queryServiceName="Google Maps"   rootURL="http://maps.google.com/maps?t=h&q="/>, destination);
			
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
					"Search for Record" + (includeData ? " and Data" : "") + " using " + serviceName, 
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
						navigateToURL(new URLRequest(c.description.@rootURL + query), "_blank");
					}
				}
			}
		}
	}
}