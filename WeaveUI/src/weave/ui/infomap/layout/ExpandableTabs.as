package weave.ui.infomap.layout
{
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.TabNavigator;
	import mx.containers.VBox;
	
	import weave.api.registerLinkableChild;
	
	/**
	 * This Class provides an expandable UI view
	 * 
	 * */
	public class ExpandableTabs extends TabNavigator 
	{
		public function ExpandableTabs()
		{
			super();
			
			firstTab = new VBox();
			firstTab.label = "New Query";
			this.addChild(firstTab);
			
			
			// create the special '+' tab
			addTabButton = new VBox();
			addTabButton.label = "+";
			this.addEventListener(Event.CHANGE, handleTabChange);
			this.addChild(addTabButton);
		}		
		
		private var firstTab:VBox;
		private var addTabButton:VBox;
		
		private function handleTabChange(e:Event):void
		{
			// check if the last tab is being clicked
			if(e.currentTarget.selectedIndex == this.length - 1)
			{
				var newTab:VBox =  addNewTab("New Query");
				
				// set the current tab focus to the newly created tab
				this.selectedChild = newTab;		
			}
		}
				
		public function addNewTab(tabName:String):VBox
		{
			var tab:VBox = new VBox();
			tab.label = tabName;
			this.addChildAt(tab, this.length - 1);
			return tab;
		}
	}
	
}