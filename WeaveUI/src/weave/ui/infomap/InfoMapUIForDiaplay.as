package weave.ui.infomap
{import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.events.FlexEvent;
	
	public class InfoMapUIForDiaplay extends Canvas
	{
		private var imgHighlighter:Image = new Image();
		
		public function InfoMapUIForDiaplay(ac:ArrayCollection,keyWord:String)
		{
			this.width = 400;
			this.height = 400;
			this.addEventListener(MouseEvent.MOUSE_DOWN,panel1_mouseDownHandler);
			this.addEventListener(MouseEvent.MOUSE_UP,panel1_mouseUpHandler);
			//imgHighlighter.addEventListener(MouseEvent.CLICK,openLink);			
			createUI(ac,keyWord);
		}
		
		private var dragging:Boolean = false;
		protected function panel1_mouseDownHandler(event:MouseEvent):void{			
			dragging = true;
			this.startDrag();
			imgHighlighter.width = 50;
			imgHighlighter.height = 50;
			//imgHighlighter.removeEventListener(MouseEvent.CLICK,openLink);
		}
		
		protected function panel1_mouseUpHandler(event:MouseEvent):void{
			this.stopDrag();
			dragging = false;
			//imgHighlighter.addEventListener(MouseEvent.CLICK,openLink);
		}
		
		
		private var objCollection:ArrayCollection = null;
		
		private function createUI(ac:ArrayCollection,keyWord:String):void{
			objCollection = ac;
			var canvasCenterPoint:Point = new Point(this.width/2,this.height/2);			
			var location:Array = getNPointsOnCircle(canvasCenterPoint,100,ac.length);				
			for(var i:int; i<ac.length ;i++){
				var obj:Object = ac[i] as Object;					
				var img:Image = new Image();
				img.name = String(i);
				img.load(obj.imgName);
				img.width = 50;
				img.height = 50;
				img.addEventListener(MouseEvent.MOUSE_OVER,highlightThumbnailImage);
				img.addEventListener(MouseEvent.MOUSE_OUT,removeHighlight);
				//img.addEventListener(MouseEvent.CLICK,openLink);
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
			var img:Image = event.currentTarget as Image;
			imgHighlighter = img;
			imgHighlighter.width = 200;
			imgHighlighter.height = 200;
		}
		private function removeHighlight(event:MouseEvent):void
		{
			var img:Image = event.currentTarget as Image;
			
			img.height = 50;
			img.width = 50;
		}
		
		private function openLink(event:MouseEvent):void
		{
			var img:Image = event.currentTarget as Image;
			navigateToURL(new URLRequest((objCollection[img.name] as Object).link)) ;
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