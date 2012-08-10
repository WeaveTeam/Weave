package weave.ui.infomap.layout
{
	import flash.display.Graphics;
	import flash.utils.Dictionary;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableNumber;
	import weave.data.KeySets.KeyFilter;
	import weave.ui.infomap.ui.DocThumbnailComponent;
	
	public class GridLayout implements IInfoMapNodeLayout
	{
		public function GridLayout()
		{
			thumbnailSpacing.addGroupedCallback(this,function():void{plotThumbnails(_lastThumbnailsPlotted);});
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
			if(_parentNodeHandler == null ||_parentNodeHandler.nodeBase.keywordTextArea ==null)
				return;
			
//			_parentNodeHandler.nodeBase.keywordTextArea.toolTip = _parentNodeHandler.query.keywords.value;
			_parentNodeHandler.nodeBase.keywordTextArea.setStyle("textAlign","center");
			
			
			
			baseLayoutDrawn = true;
		}
		
		public const thumbnailSpacing:LinkableNumber = registerLinkableChild(this,new LinkableNumber(15));
		public function get thumbnailSpacingValue():Number
		{
			return thumbnailSpacing.value;
		}
		public function set thumbnailSpacingValue(value:Number):void
		{
			thumbnailSpacing.value = value;
		}
		
//		private var thumbnailSize:int = 25;
		private var _subset:KeyFilter = Weave.root.getObject(Weave.DEFAULT_SUBSET_KEYFILTER) as KeyFilter;
		
		private var _lastThumbnailsPlotted:Array = [];
		public function plotThumbnails(thumbnails:Array,reDraw:Boolean=false):void
		{
			//don't plot thumbnails till the base layout has been drawn
			if(!baseLayoutDrawn)
				return;
			_lastThumbnailsPlotted = thumbnails;
			
			//this image is used to a show a tooltip of information about the node. 
			//For now it shows the number of documents found.
//			_parentNodeHandler.nodeBase.infoImg.visible = true;
//			_parentNodeHandler.nodeBase.infoImg.toolTip = thumbnails.length.toString() + " documents found" ;
			
//			if(_parentNodeHandler.query.sources.value)
//				_parentNodeHandler.nodeBase.infoImg.toolTip += " sourced from : " + _parentNodeHandler.query.sources.value;
			
			var startX:Number = 0;//_parentNodeHandler.nodeBase.x;
			var startY:Number = 0;//_parentNodeHandler.nodeBase.y;
			
			//offet to  be below node base
//			startY = startY + _parentNodeHandler.nodeBase.height;
			
			var temp:Array = [];
			for (var i:int = 0; i < thumbnails.length; i++)
			{
				if(!thumbnails[i].hasBeenMoved.value)
				{
					temp.push(thumbnails[i])
				}else
				{
					//if they have been moved, then draw them as it is without using a layout algorithm
//					thumbnails[i].imageWidth.value = thumbnailSize;
//					thumbnails[i].imageHeight.value = thumbnailSize;
					
					thumbnails[i].x = thumbnails[i].xPos.value;
					thumbnails[i].y = thumbnails[i].yPos.value;
				}
			}
			
			var gridSize:Number = Math.ceil(Math.sqrt(temp.length));
			
			var count:int = 0;
			
			var nextY:int = startY;
			for(var row:int=0; row<gridSize; row++)
			{
				var nextX:int = startX;
				for(var col:int=0; col<gridSize; col++)
				{
					if(count>=temp.length)
						return;
					var thumbnail:DocThumbnailComponent = temp[count];
					
					count++;
					
//					thumbnail.imageWidth.value = thumbnailSize;
//					thumbnail.imageHeight.value = thumbnailSize;
					
					thumbnail.y = nextY;			
					thumbnail.x = nextX;
					
					thumbnail.xPos.value = nextX;
					thumbnail.yPos.value = nextY;
					
					nextX = nextX + thumbnailSpacing.value;
				}
				nextY = nextY + thumbnailSpacing.value;
			}
			
		}
		
	}
}