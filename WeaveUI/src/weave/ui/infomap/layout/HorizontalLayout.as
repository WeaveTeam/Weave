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
	
	public class HorizontalLayout implements IInfoMapNodeLayout
	{
		public function HorizontalLayout()
		{
		}
		
		public function get name():String
		{
			return 'Horizontal';
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
			
			_parentNodeHandler.nodeBase.keywordTextArea.toolTip = _parentNodeHandler.previousQuery.keywords.value;
			_parentNodeHandler.nodeBase.keywordTextArea.setStyle("textAlign","center");
			
			
			
			baseLayoutDrawn = true;
		}
		
		private var thumbnailSize:int = 25;
		private var _subset:KeyFilter = Weave.root.getObject(Weave.DEFAULT_SUBSET_KEYFILTER) as KeyFilter;
		
		public const thumbnailSpacing:LinkableNumber = registerLinkableChild(this,new LinkableNumber(10));
		public function get thumbnailSpacingValue():Number
		{
			return thumbnailSpacing.value;
		}
		public function set thumbnailSpacingValue(value:Number):void
		{
			thumbnailSpacing.value = value;
		}
		
		public function plotThumbnails(thumbnails:Array,reDraw:Boolean=false):void
		{
			//don't plot thumbnails till the base layout has been drawn
			if(!baseLayoutDrawn)
				return;
			
			
			//this image is used to a show a tooltip of information about the node. 
			//For now it shows the number of documents found.
//			_parentNodeHandler.nodeBase.infoImg.visible = true;
//			_parentNodeHandler.nodeBase.infoImg.toolTip = thumbs.length.toString() + " documents found";
			
			var startX:Number = _parentNodeHandler.nodeBase.x;
			var startY:Number = _parentNodeHandler.nodeBase.y;
			
			//offet to  be below node base
			startY = startY + _parentNodeHandler.nodeBase.height;
			
			
			for(var i:int=0; i<thumbnails.length ;i++)
			{
				var thumbnail:DocThumbnailComponent = thumbnails[i];
				
				//if the thumbnail already exists use previous x,y values
				if(!thumbnail.hasBeenMoved.value)
				{
					
					thumbnail.imageWidth.value = thumbnailSize;
					thumbnail.imageHeight.value = thumbnailSize;
					thumbnail.y = startY;			
					thumbnail.x = startX;
					
					startX = startX + 25;
				}
			}	
		}
		
	}
}