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
			thumbnailSpacing.addGroupedCallback(this,function():void{plotThumbnails(_lastThumbnailsPlotted);});
		}
		
		public function get name():String
		{
			return 'Radial';
		}
		
//		public const radius:LinkableNumber = registerLinkableChild(this,new LinkableNumber(100));
		
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
//			graphics.drawCircle(0,0,thumbnailSpacing.value);
			
//			_parentNodeHandler.nodeBase.keywordTextArea.text = _parentNodeHandler.query.keywords.value;
//			_parentNodeHandler.nodeBase.keywordTextArea.toolTip = _parentNodeHandler.query.keywords.value;
			_parentNodeHandler.nodeBase.x = - (thumbnailSpacing.value/2) - 20; //TODO: the value 20 should be replaced by an offset
			_parentNodeHandler.nodeBase.keywordTextArea.setStyle("textAlign","center");
			
			baseLayoutDrawn = true;
		}
		
		private var _lastThumbnailsPlotted:Array = [];
		
		public const thumbnailSpacing:LinkableNumber = registerLinkableChild(this,new LinkableNumber(100));
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
		
		public function plotThumbnails(thumbnails:Array,reDraw:Boolean=false):void
		{
			//don't plot thumbnails till the base layout has been drawn
			if(!baseLayoutDrawn)
				return;
			_lastThumbnailsPlotted = thumbnails;
			
			
			var centerPoint:Point = new Point(_parentNodeHandler.nodeBase.x+ _parentNodeHandler.nodeBase.width/2,_parentNodeHandler.nodeBase.height/2);
			
			//this image is used to a show a tooltip of information about the node. 
//			_parentNodeHandler.nodeBase.infoImg.toolTip = thumbnails.length.toString() + " documents found" ;
			
//			if(_parentNodeHandler.query.sources.value)
//				_parentNodeHandler.nodeBase.infoImg.toolTip += " sourced from : " + _parentNodeHandler.query.sources.value;
			
			
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
			
			var location:Array = getNPointsOnCircle(centerPoint,thumbnailSpacing.value,temp.length);	
			
			for(var j:int=0; j<temp.length ;j++)
			{
				
				var thumbnail:DocThumbnailComponent = temp[j];
//				thumbnail.imageWidth.value = thumbnailSize;
//				thumbnail.imageHeight.value = thumbnailSize;
				var imgPosition:Point = location[j] as Point;
				thumbnail.y = imgPosition.y-(thumbnail.width/2);			
				thumbnail.x = imgPosition.x-(thumbnail.height/2);
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
