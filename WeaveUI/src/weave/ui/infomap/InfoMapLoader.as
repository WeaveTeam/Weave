package weave.ui.infomap
{
	import flash.display.DisplayObject;
	import flash.events.ContextMenuEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import weave.Weave;
	import weave.data.KeySets.KeySet;
	import weave.ui.CustomContextMenuManager;
	import weave.ui.infomap.ui.InfoMapPanel;
	import weave.utils.ProbeTextUtils;

	public class InfoMapLoader
	{
		public function InfoMapLoader()
		{
		}
		
		private static const INFOMAP_CAPTION:String = "Open InfoMap";
		private static var _infoMapMenuItem:ContextMenuItem = null;
		private static var _selectedKeySet:KeySet = null;
		
		/**
		 * this function is called when the menu is opened. Use this function to change the menu 
		 * text based on the context it is opened it
		 **/
		private static function handleContextMenuOpened(e:ContextMenuEvent):void
		{	
			_infoMapMenuItem.enabled = _selectedKeySet.keys.length > 0;
		}
		
		public static function openPanel():void
		{
			var panel:InfoMapPanel = Weave.root.requestObject("InfoMapPanel",InfoMapPanel,false);
			//show infomap panel
			panel.restorePanel();
			Weave.root.setNameOrder(["InfoMapPanel"]);
		}
		
		public static function openPanelWithName(mapName:String):void
		{
			var panel:InfoMapPanel = Weave.root.requestObject(mapName,InfoMapPanel,false);
			panel.title = mapName;
			//show infomap panel
			panel.restorePanel();
			Weave.root.setNameOrder([mapName]);
		}
		
		/**
		 * Creates a menu item
		 **/
		public static function createContextMenuItems(destination:DisplayObject):Boolean
		{
			if(!destination.hasOwnProperty("contextMenu") )
				return false;
			
			_selectedKeySet = Weave.root.getObject(Weave.DEFAULT_SELECTION_KEYSET) as KeySet;
			
			// Add a listener to this destination context menu for when it is opened
			var contextMenu:ContextMenu = destination["contextMenu"] as ContextMenu;
			contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, handleContextMenuOpened);
			
			_infoMapMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination(INFOMAP_CAPTION,destination,handleMenutItemClick,"3 searchMenuItems");				
			return true;
		}
		private static var _keywords:String = "";
		
		private static function handleMenutItemClick(event:ContextMenuEvent):void
		{
			var panel:InfoMapPanel = Weave.root.requestObject("InfoMapPanel",InfoMapPanel,false);
			
			var keys:Array = _selectedKeySet.keys;
			var probeString:String = "";
			var temp:Array = [];
			probeString = ProbeTextUtils.getProbeText(_selectedKeySet);
			
			//TODO: May want to consider removing numbers
			var regEx:RegExp = /[a-zA-Z]+/g;				
			temp =  probeString.match(regEx);
			
			var dict:Dictionary = new Dictionary();
			
			for each(var word:String in temp)
			{
				if(dict[word] == undefined)
					dict[word] = word;
			}
			
			var uniqueTemp:Array = []
			for each(var prop:String in dict)
			{
				uniqueTemp.push(prop);	
			}
			// joins all keywords using comma
			_keywords = uniqueTemp.join(",");
			
			panel.addInfoMapNode(_keywords);
			
			//show infomap panel
			panel.restorePanel();
			Weave.root.setNameOrder(["InfoMapPanel"]);
		}
	}
}