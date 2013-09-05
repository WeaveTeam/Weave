package weave.ui.infomap.ui
{
	import mx.collections.ArrayCollection;
	import mx.states.OverrideBase;
	
	import weave.compiler.StandardLib;

	public class DocumentListView extends AbstractListView
	{
		public function DocumentListView()
		{
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			view.width = 500;
			view.height = 250;
		}
		
		public var docList:InfoMapsDocumentsList = new InfoMapsDocumentsList();
		
		override public function redrawList():void
		{
			docList.dataProvider = null;
			updateList();
		}
		
		override protected function updateList():void
		{
			if(keys.length == 0)
			{
				docList.dataProvider = [];
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
			if(!view.contains(docList))
			{
				view.removeAllChildren();
				view.addChild(docList);
				docList.parentNode = parentNode;
			}
			if(docList.dataProvider == null || (StandardLib.arrayCompare(temp,(docList.dataProvider as ArrayCollection).source) != 0))
			{
				docList.dataProvider = temp;
			}
			navBox.percentWidth = 100;
			
			navBox.y = view.y + view.height;
			if(!nextButton || !prevButton)
			{
				return;
			}
			
			updateIndexText(); 
		}
	}
}