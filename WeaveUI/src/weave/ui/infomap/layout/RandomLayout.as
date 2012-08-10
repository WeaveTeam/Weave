package weave.ui.infomap.layout
{
	import flash.display.Graphics;
	import flash.utils.Dictionary;
	
	import mx.controls.Label;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableNumber;
	import weave.data.DataSources.InfoMapsDataSource;
	import weave.data.KeySets.KeyFilter;
	import weave.ui.infomap.ui.DocThumbnailComponent;
	
	public class RandomLayout implements IInfoMapNodeLayout
	{
		public function RandomLayout()
		{
			thumbnailSpacing.addGroupedCallback(this,function():void{plotThumbnails(_lastThumbnailsPlotted);});
		}
		
		public function get name():String
		{
			return 'Random';
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
			_parentNodeHandler.nodeBase.keywordTextArea.setStyle("textAlign","left");
			
			baseLayoutDrawn = true;
			source.getColumnByName("title").addImmediateCallback(this,updateTitleLabel);
			
//			getCallbackCollection(source.csvDataString).addGroupedCallback(this,updateTitleLabel);
		}
		
		public function updateTitleLabel():void
		{
			
			for each (var thumbnail:DocThumbnailComponent in _lastThumbnailsPlotted)
			{
				
				if(source.getTitleForURL(thumbnail.docURL.value))
					thumbnail.titleLabel.text = source.getTitleForURL(thumbnail.docURL.value).substring(0,100) + "...";
				
				thumbnail.titleLabel.x = - (thumbnail.titleLabel.textWidth/2);
				
				thumbnail.point.width = thumbnail.titleLabel.textWidth;	
			}
			
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
		
		public var numOfPoints:Number = 10;
		
		private var source:InfoMapsDataSource = WeaveAPI.globalHashMap.getObject(InfoMapsDataSource.SOURCE_NAME) as InfoMapsDataSource;
		
		public function plotThumbnails(thumbnails:Array,reDraw:Boolean=false):void
		{
			//don't plot thumbnails till the base layout has been drawn
			if(!baseLayoutDrawn)
				return;
			if(thumbnails.length == 0)
				return;
			_lastThumbnailsPlotted = thumbnails;
			
			//this image is used to a show a tooltip of information about the node. 
			//For now it shows the number of documents found.
//			_parentNodeHandler.nodeBase.infoImg.visible = true;
//			_parentNodeHandler.nodeBase.infoImg.toolTip = thumbnails.length.toString() + " documents found" ;
//			_parentNodeHandler.nodeBase.keywordTextArea.htmlText += "<br/><b>" +  thumbnails.length.toString() + "</b> documents found" ;
//			if(_parentNodeHandler.previousQuery.sources.value)
//			{
////				_parentNodeHandler.nodeBase.infoImg.toolTip += " sourced from : " + _parentNodeHandler.query.sources.value;
//				_parentNodeHandler.nodeBase.keywordTextArea.htmlText += "<br/><b>Sources : " +  _parentNodeHandler.previousQuery.sources.value + "</b>";
//			}
			
			_parentNodeHandler.nodeBase.keywordTextArea.validateNow();
			
			_parentNodeHandler.nodeBase.width = _parentNodeHandler.nodeBase.keywordTextArea.textWidth + 20; 
			
			var temp:Array = [];
			for (var i:int = 0; i < thumbnails.length; i++)
			{
				if(!thumbnails[i].hasBeenMoved.value)
				{
					temp.push(thumbnails[i]);
				}else
				{
					//if they have been moved, then draw them as it is without using a layout algorithm
					thumbnails[i].x = thumbnails[i].xPos.value;
					thumbnails[i].y = thumbnails[i].yPos.value;
				}
			}
			
			
			var maxWidth:Number = _parentNodeHandler.pointsCanvas.width;
			var maxHeight:Number = _parentNodeHandler.pointsCanvas.height;
			
			var nextX:int;
			var nextY:int;
			
			if(numOfPoints>temp.length)
				numOfPoints = temp.length;
			
			for (var j:int=0; j<numOfPoints; j++)
			{
				var thumbnail:DocThumbnailComponent = temp[j];
				
				nextX = Math.round(Math.random()*maxWidth*(0.75));
				nextY = Math.round(Math.random()*maxHeight);
				
				thumbnail.x = nextX;
				thumbnail.y = nextY;
				
				thumbnail.xPos.value = nextX;
				thumbnail.yPos.value = nextY;
				
				thumbnail.visible = true;
					
			}
		}
		
	}
}