package weave.ui.infomap
{
	import flash.display.DisplayObject;
	import flash.events.ContextMenuEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.charts.chartClasses.InstanceCache;
	import mx.core.IFlexDisplayObject;
	import mx.managers.PopUpManager;
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.getLinkableDescendants;
	import weave.data.KeySets.KeySet;
	import weave.ui.CustomContextMenuManager;
	import weave.ui.DraggablePanel;
	import weave.ui.WizardPanel;
	import weave.ui.infomap.ui.EntitySelectionWizard;
	import weave.ui.infomap.ui.InfoMapPanel;
	import weave.utils.ColumnUtils;
	import weave.utils.ProbeTextUtils;

	public class InfoMapLoader
	{
		public function InfoMapLoader()
		{
		}
		
		private static const INFOMAP_CAPTION:String = "Send Query to InfoMap";
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
//			var titleOfClickedPanel:String = DraggablePanel.getTopPanel().title;
//			
//			var titleTerms:Array = titleOfClickedPanel.split(' ');
			
			var panel:InfoMapPanel = Weave.root.requestObject("InfoMapPanel",InfoMapPanel,false);
			
			Weave.root.setNameOrder(["InfoMapPanel"]);
			panel.restorePanel();
			
			panel.addQueryNodeUsingSelectedRecords();
			
//			var keywords:Array = extractKeywordsFromSelection();
//			
//			if(titleTerms.indexOf('Obese')>-1)
//				keywords = keywords.concat('Obese');
//			
//			panel.addInfoMapNode(keywords.join(" "));
		}
		
		/**
		 * This function extracts keywords for the selected keys from entity columns
		 * and returns an array of unique keywords
		 * */ 
		public static function extractKeywordsFromSelection():Array
		{
			var keys:Array = _selectedKeySet.keys;
			
			if(keys.length == 0)
				return[];
			
			//get all keytypes from selected keys
			var keyTypes:Dictionary = new Dictionary();
			
			for each (var key:IQualifiedKey in keys)
			{
				if(keyTypes[key.keyType] == undefined)
					keyTypes[key.keyType] = true;
			}
			
			//get all entity attribute columns of selected keytype
			var attrCols:Array = getLinkableDescendants(Weave.root,IAttributeColumn);
			var entityCols:Array = [];
			
			for each (var attrCol:IAttributeColumn in attrCols)
			{
				var entityValue:String = attrCol.getMetadata("isEntity");
				var keyType:String =  attrCol.getMetadata("keyType");
				if(entityValue == "true" && keyTypes[keyType])
				{
					entityCols.push(attrCol);
				}
			}
			
			var temp:Array = [];
			
			//extract values from entity columns
			for each(var col:IAttributeColumn in entityCols)
			{
				for each (var k:IQualifiedKey in keys)
				{
					var value:String = ColumnUtils.getString(col,k);
					if(value)
					{
						temp.push('"'+value+'"');
					}
					
					var subject:String = col.getMetadata('subject');
					
					if(subject)
					{
						temp.push(subject);
					}
				}
			}
			
			//get unique keywords from extracted values
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
			
			return uniqueTemp;
		}
	}
}