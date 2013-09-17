package weave.ui.infomap.ui
{
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.states.OverrideBase;
	
	import weave.api.core.ILinkableHashMap;
	import weave.api.disposeObjects;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.data.KeySets.KeySet;

	public class GoogleSearchListView extends AbstractListView
	{
		public function GoogleSearchListView() {}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			view.width = 500;
			view.height = 250;
		}
		
		public var googleSearchList:InfoMapsGoogleSearchList = new InfoMapsGoogleSearchList();
		
		override public function redrawList():void
		{
			googleSearchList.dataProvider = null;
			updateList();
		}
		
		override protected function updateList():void
		{
			if(keys.length == 0)
			{
				googleSearchList.dataProvider = [];
				updateIndexText(); 
				return;
			}
			var includedKeys:Array = keys;
			
			var listMaxLength:int = 10;
			
			var temp:Array = [];
			
			if(includedKeys.length < startIndex.value + listMaxLength)
				listMaxLength = includedKeys.length - startIndex.value;
			
			for(var idx:int=0+startIndex.value; idx<startIndex.value+listMaxLength; idx++)
			{
				temp.push(includedKeys[idx]);
			}
			if(!view.contains(googleSearchList))
			{
				view.removeAllChildren();
				view.addChild(googleSearchList);
			}
			if(googleSearchList.dataProvider == null || (StandardLib.arrayCompare(temp,(googleSearchList.dataProvider as ArrayCollection).source) != 0))
			{
				googleSearchList.dataProvider = temp;
			}
			navBox.percentWidth = 100;
			
			navBox.y = view.y + view.height;
			if(!nextButton || !prevButton)
			{
				return;
			}
			
			updateIndexText(); 
		}
		
		private var _keys:KeySet = registerLinkableChild(this, new KeySet());
		override public function set keys(value:Array):void {
			if(_keys != null)
			{
				disposeObjects(_keys);
			}
			
			_keys = registerLinkableChild(this,new KeySet());
			_keys.replaceKeys(value);

			startIndex.value = 0;
			startIndex.triggerCallbacks();
		}
		
		override public function get keys():Array {
			return _keys.keys;
		}
		
		override protected function handleFilterChanges():void {}
		override protected function handleFilterLabelClick(event:MouseEvent):void {}
		override public function removeFilter(name:String):void {}
		override public function applyFilter(name:String,keys:Array):void {}
	}
}