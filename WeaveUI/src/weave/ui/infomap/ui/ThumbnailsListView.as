package weave.ui.infomap.ui
{
	import flash.events.MouseEvent;
	
	import weave.api.data.IQualifiedKey;
	import weave.ui.infomap.layout.NodeHandler;

	public class ThumbnailsListView extends AbstractListView
	{
		public function ThumbnailsListView()
		{
		}
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			view.width = _gridSize * _imageSize + 25;
			view.height = _gridSize * _imageSize + 25;
		}
		private var _gridSize:int = 3;
		private var _imageSize:int = 50;
		
		override public function redrawList():void
		{
			updateList();
		}
		
		override protected function updateList():void
		{
			if(keys.length == 0)
			{
				updateIndexText(); 
				return;
			}
			var includedKeys:Array = keys;
			
			var listMaxLength:int = 10;
			
			var temp:Array = [];
			
			for each(var child:DocThumbnailComponent in view.getChildren())
			{
				if(child)
				{
					child.removeEventListener(MouseEvent.ROLL_OUT,handleMouseRollOut);
					child.removeEventListener(MouseEvent.ROLL_OVER,handleMouseRollOver);
				}
			}
			
			view.removeAllChildren();
			
			var nextX:Number = 0;
			var nextY:Number = 0;
			var count:int = startIndex.value;
			var doc:DocThumbnailComponent = null;
			for (var i:int = 0; i<_gridSize; i++)
			{
				if(count >= includedKeys.length)
					break;
				
				for(var j:int = 0; j< _gridSize; j++)
				{
					if(count >= includedKeys.length)
						break;
					doc = parentNode.thumbnails.getObject((includedKeys[count] as IQualifiedKey).localName) as DocThumbnailComponent;
					//						trace(debugId(doc));
					var pos:Object = doc.pos.getSessionState();
					if(!pos || isNaN(pos.x) || isNaN(pos.y))
					{
						view.addChild(doc);
						doc.positionThumbnail(nextX,nextY);
						doc.addEventListener(MouseEvent.ROLL_OVER,handleMouseRollOver);
						doc.addEventListener(MouseEvent.ROLL_OUT,handleMouseRollOut);
						nextX += doc.width;
					}
					
					count++;
				}
				nextX = 0;
				nextY += doc.height;
				
				//					if(doc)
				//						_imageSize = doc.width;
				navBox.width = _imageSize * (_gridSize);
			}
			
			navBox.y = view.y + view.height + filterStatus.y + filterStatus.height;
			if(!nextButton || !prevButton)
			{
				return;
			}
			
			updateIndexText(); 
		}
		
		private function handleMouseRollOver(event:MouseEvent):void
		{
			DocumentSummaryComponent.show(stage.mouseX,stage.mouseY,event.target.docURL.value,view,view.parent.parent as NodeHandler);
		}
		
		private function handleMouseRollOut(event:MouseEvent):void
		{
			DocumentSummaryComponent.hide();
		}
	}
}