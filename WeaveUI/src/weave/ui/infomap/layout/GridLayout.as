package weave.ui.infomap.layout
{
	import flash.display.Graphics;
	
	import weave.ui.infomap.ui.DocThumbnailComponent;
	
	public class GridLayout implements IInfoMapNodeLayout
	{
		public function GridLayout()
		{
		}
		
		public function get name():String
		{
			return 'Grid';
		}
		
		private var _parentNodeHandler:NodeHandler;
		public function set parentNodeHandler(value:NodeHandler):void
		{
			_parentNodeHandler = value;
		}
		
		private var baseLayoutDrawn:Boolean = false;
		public function drawBaseLayout(graphics:Graphics):void
		{
			if(_parentNodeHandler.node.keywords.value == null || _parentNodeHandler.nodeBase.keywordTextArea ==null)
				return;
			
			_parentNodeHandler.nodeBase.keywordTextArea.toolTip = _parentNodeHandler.node.keywords.value;
			_parentNodeHandler.nodeBase.keywordTextArea.setStyle("textAlign","center");
			
			
			
			baseLayoutDrawn = true;
		}
		
		private var thumbnailSize:int = 50;
		
		public function plotThumbnails():void
		{
			//don't plot thumbnails till the base layout has been drawn
			if(!baseLayoutDrawn)
				return;
			
			var thumbs:Array = _parentNodeHandler.thumbnails.getObjects();
			
			//this image is used to a show a tooltip of information about the node. 
			//For now it shows the number of documents found.
			_parentNodeHandler.nodeBase.infoImg.visible = true;
			_parentNodeHandler.nodeBase.infoImg.toolTip = thumbs.length.toString() + " documents found";
			
			var startX:Number = _parentNodeHandler.nodeBase.x;
			var startY:Number = _parentNodeHandler.nodeBase.y;
			
			var gridSize:Number = Math.round(Math.sqrt(thumbs.length));
			
			var count:int = 0;
			
			for(var row:int=0; row<gridSize; row++)
			{
				for(var col:int=0; col<gridSize; col++)
				{
					if(count>=thumbs.length)
						return;
					var thumbnail:DocThumbnailComponent = thumbs[count];
					count++;
					
					//if the thumbnail already exists use previous x,y values
					if(!thumbnail.hasBeenMoved.value)
					{
						thumbnail.imageWidth.value = thumbnailSize;
						thumbnail.imageHeight.value = thumbnailSize;
						thumbnail.imageAlpha.value = 0.75;
						
						thumbnail.y = startY;			
						thumbnail.x = startX;
						
						startY = startY + thumbnailSize;
					}
				}
				startX = startX + thumbnailSize;
			}
			
		}
		
	}
}