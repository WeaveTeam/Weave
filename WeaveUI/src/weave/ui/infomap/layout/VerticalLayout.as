package weave.ui.infomap.layout
{
	import flash.display.Graphics;
	import flash.utils.Dictionary;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.data.KeySets.KeyFilter;
	import weave.ui.infomap.ui.DocThumbnailComponent;
	
	public class VerticalLayout implements IInfoMapNodeLayout
	{
		public function VerticalLayout ()
		{
		}
		
		public function get name():String
		{
			return 'Vertical';
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
		private var _subset:KeyFilter = Weave.root.getObject(Weave.DEFAULT_SUBSET_KEYFILTER) as KeyFilter;
		
		public function plotThumbnails():void
		{
			//don't plot thumbnails till the base layout has been drawn
			if(!baseLayoutDrawn)
				return;
			
			var thumbNailsToPlot:Dictionary = new Dictionary();
			
			//this image is used to a show a tooltip of information about the node. 
			//For now it shows the number of documents found.
			_parentNodeHandler.nodeBase.infoImg.visible = true;
//			_parentNodeHandler.nodeBase.infoImg.toolTip = thumbs.length.toString() + " documents found";
			
			var startX:Number = _parentNodeHandler.nodeBase.x;
			var startY:Number = _parentNodeHandler.nodeBase.y;
			
			//offet to  be below node base
			startY = startY + _parentNodeHandler.nodeBase.height;
			
			var includedKeys:Array = _subset.included.keys;
			var excludedKeys:Array = _subset.excluded.keys;
			
			
			var dictKey:*;
			
			//add all thumbanils to dictionary and set it all to false
			for each(var t:DocThumbnailComponent in _parentNodeHandler.thumbnails.getObjects())
			{
				thumbNailsToPlot[t] = false;
				t.visible = false;
			}
			
			//add only included keys from subset
			if(includedKeys.length>0)
			{
				for each (var iKey:IQualifiedKey in includedKeys)
				{
					var includedThumbnail:DocThumbnailComponent = _parentNodeHandler.thumbnails.getObject(iKey.localName) as DocThumbnailComponent;
					
					if(includedThumbnail)
					{
						thumbNailsToPlot[includedThumbnail] = true;
						includedThumbnail.visible = true;						
					}
				}
			}else //else set all thumbnails to be added
			{
				for (dictKey in thumbNailsToPlot)
				{
					thumbNailsToPlot[dictKey] = true;
					(dictKey as DocThumbnailComponent).visible = true;
				}
			}
			
			//remove excluded keys if any
			if(excludedKeys.length >0)
			{
				for each(var xKey:IQualifiedKey in excludedKeys)
				{
					var excludedThumbnail:DocThumbnailComponent = _parentNodeHandler.thumbnails.getObject(xKey.localName) as DocThumbnailComponent;
					
					if(excludedThumbnail)
					{
						thumbNailsToPlot[excludedThumbnail] = false;
						excludedThumbnail.visible = false;
					}
					
				}
			}
			
			
			var thumbnailsToPlotArray:Array = [];
			//add all thumbnails to be plotted to an array
			for (dictKey in thumbNailsToPlot)
			{
				if(thumbNailsToPlot[dictKey])
					thumbnailsToPlotArray.push(dictKey);
			}
			
			for(var i:int; i<thumbnailsToPlotArray.length ;i++)
			{
				var thumbnail:DocThumbnailComponent = thumbnailsToPlotArray[i];
				//if the thumbnail already exists use previous x,y values
				if(!thumbnail.hasBeenMoved.value)
				{
					
					thumbnail.imageWidth.value = thumbnailSize;
					thumbnail.imageHeight.value = thumbnailSize;
					thumbnail.imageAlpha.value = 0.75;
					thumbnail.y = startY;			
					thumbnail.x = startX;
					
					startY = startY + 5;
				}
			}	
		}
		
	}
}