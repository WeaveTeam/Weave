package weave.ui.infomap
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.events.FlexEvent;

	public class InfoMapUIForDiaplay extends Canvas
	{
		public function InfoMapUIForDiaplay(ac:ArrayCollection,keyWord:String)
		{
			createUI(ac,keyWord);
		}
		
		
		private function createUI(ac:ArrayCollection,keyWord:String):void{
			var canvasCenterPoint:Point = new Point(this.width/2,this.height/2);
			
			var location:Array = getNPointsOnCircle(canvasCenterPoint,140,ac.length);				
			for(var i:int; i<ac.length ;i++){
				var obj:Object = ac[i] as Object;					
				var img:Image = new Image();	
				img.load(obj.image);
				img.width = 100;
				img.height = 100;
				img.addEventListener(MouseEvent.MOUSE_OVER,highlightThumbnailImage);
				img.addEventListener(MouseEvent.MOUSE_OUT,removeHighlight);
				var imgPosition:Point = location[i] as Point;
				this.addChild(img);
				img.x = imgPosition.x;
				img.y = imgPosition.y;
			}	
			var keywordLabel:Label = new Label;
			keywordLabel.text = keyWord;
			keywordLabel.x = canvasCenterPoint.x;
			keywordLabel.y = canvasCenterPoint.y;	
			this.addChild(keywordLabel);
		}
		
		private function highlightThumbnailImage(event:MouseEvent):void
		{
			var img:Image = event.target as Image;
				img.width = 800;
				img.height = 800;
		}
		private function removeHighlight(event:MouseEvent):void
		{
			var img:Image = event.target as Image;
			img.width = 100;
			img.height = 100;
		}
		
		
		private function getNPointsOnCircle( center:Point, radius:Number, n:Number = 10 ) : Array
		{				
			var alpha:Number = Math.PI * 2 / n;
			var points:Array = new Array( n );				
			var i:int = -1;
			while( ++i < n )				{
				var theta:Number = alpha * i;
				var pointOnCircle:Point = new Point( Math.cos( theta ) * radius, Math.sin( theta ) * radius );
				points[ i ] = center.add( pointOnCircle );
			}				
			return points;				
		} 
	}
}