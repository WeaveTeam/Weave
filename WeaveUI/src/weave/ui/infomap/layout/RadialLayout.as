package weave.ui.infomap.layout
{
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.ui.infomap.ui.DocThumbnailComponent;
	import weave.ui.infomap.ui.NodeControlComponent;

	public class RadialLayout implements IInfoMapNodeLayout
	{
		public function RadialLayout()
		{
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
			
			graphics.lineStyle(0,0,0);
			graphics.beginFill(0,0);
			graphics.drawCircle(0,0,radius.value);
			
			_parentNodeHandler.nodeControl.keywordTextArea.text = _parentNodeHandler.node.keywords.value;
			_parentNodeHandler.nodeControl.keywordTextArea.toolTip = _parentNodeHandler.node.keywords.value;
			_parentNodeHandler.nodeControl.x = - (radius.value/2) - 20; //TODO: the value 20 should be replaced by an offset
			_parentNodeHandler.nodeControl.keywordTextArea.setStyle("textAlign","center");
			
			baseLayoutDrawn = true;
		}
		
		
		
		private var thumbnailSize:int = 50;
		
		public function plotThumbnails():void
		{
			//don't plot thumbnails till the base layout has been drawn
			if(!baseLayoutDrawn)
				return;
			
			var centerPoint:Point = new Point(0,0);
			var thumbs:Array = _parentNodeHandler.thumbnails.getObjects();
			var location:Array = getNPointsOnCircle(centerPoint,radius.value,thumbs.length);	
			
			//this image is used to a show a tooltip of information about the node. 
			//For now it shows the number of documents found.
			_parentNodeHandler.nodeControl.infoImg.visible = true;
			_parentNodeHandler.nodeControl.infoImg.toolTip = thumbs.length.toString() + " documents found";
			
			
			for(var i:int; i<thumbs.length ;i++)
			{
				var thumbnail:DocThumbnailComponent = thumbs[i];
				
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
