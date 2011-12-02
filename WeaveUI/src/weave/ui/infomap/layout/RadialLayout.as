package weave.ui.infomap.layout
{
	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.data.KeySets.KeyFilter;
	import weave.ui.infomap.ui.DocThumbnailComponent;

	public class RadialLayout implements IInfoMapNodeLayout
	{
		public function RadialLayout()
		{
		}
		
		public function get name():String
		{
			return 'Radial';
		}
		
		public const radius:LinkableNumber = registerLinkableChild(this,new LinkableNumber(100),plotThumbnails,true);
		
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
			graphics.lineStyle(0,0,0);
			graphics.beginFill(0,0);
			graphics.drawCircle(0,0,radius.value);
			
			_parentNodeHandler.nodeBase.keywordTextArea.text = _parentNodeHandler.node.keywords.value;
			_parentNodeHandler.nodeBase.keywordTextArea.toolTip = _parentNodeHandler.node.keywords.value;
			_parentNodeHandler.nodeBase.x = - (radius.value/2) - 20; //TODO: the value 20 should be replaced by an offset
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
			
			var centerPoint:Point = new Point(0,0);
			var thumbNailsToPlot:Dictionary = new Dictionary();
			
			//this image is used to a show a tooltip of information about the node. 
			//For now it shows the number of documents found.
			_parentNodeHandler.nodeBase.infoImg.visible = true;
//			_parentNodeHandler.nodeBase.infoImg.toolTip = thumbNailsToPlot.length.toString() + " documents found";
			
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
				
			var location:Array = getNPointsOnCircle(centerPoint,radius.value,thumbnailsToPlotArray.length);	
			
			for(var i:int; i<thumbnailsToPlotArray.length ;i++)
			{
				
				var thumbnail:DocThumbnailComponent = thumbnailsToPlotArray[i];
				//if the thumbnail already exists use previous x,y values
				if(!thumbnail.hasBeenMoved.value)
				{
					
					thumbnail.imageWidth.value = thumbnailSize;
					thumbnail.imageHeight.value = thumbnailSize;
					thumbnail.imageAlpha.value = 0.75;
					var imgPosition:Point = location[i] as Point;
					thumbnail.y = imgPosition.y-(thumbnailSize/2);			
					thumbnail.x = imgPosition.x-(thumbnailSize/2);
				}
			}	
		}
		
		/**
		 * @private
		 * This function calculates the points on the circle to plot the thumbnails on 
		 * based on the radius and total number of thumnails to draw.
		 * 
		 * @param center The center of the circle
		 * @param radius The raidus of the circle
		 * @param n The total number of documents/thumbnails to plot
		 * 
		 * @return an array of points
		 **/
		private function getNPointsOnCircle( center:Point, radius:Number, n:Number = 10 ) : Array
		{				
			//solution obtained from http://stackoverflow.com/questions/2169656/dynamically-spacing-numbers-around-a-circle
			var p:Number = Math.PI * 2 / n;
			var points:Array = new Array( n );				
			var i:int = -1;
			while( ++i < n )				{
				var theta:Number = p * i;
				var pointOnCircle:Point = new Point( Math.cos( theta ) * radius, Math.sin( theta ) * radius );
				points[ i ] = center.add( pointOnCircle );
			}				
			return points;				
		}
		
		
	}
}
