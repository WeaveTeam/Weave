package weave.visualization.plotters
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableNumber;

	public class CirclePlotter extends AbstractPlotter
	{
		public function CirclePlotter()
		{
		}
		
		public const dataX:LinkableNumber = registerLinkableChild(this,new LinkableNumber());
		public const dataY:LinkableNumber = registerLinkableChild(this,new LinkableNumber());
		
		public const radius:LinkableNumber = registerLinkableChild(this,new LinkableNumber(1));
		
		public const color:LinkableNumber = registerLinkableChild(this,new LinkableNumber(0));
		public const thickness:LinkableNumber = registerLinkableChild(this, new LinkableNumber(2));
		
		
		private var _tempDataBounds:IBounds2D;
		private var _tempScreenBounds:IBounds2D;
		
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			_tempDataBounds = dataBounds;
			_tempScreenBounds = screenBounds;
			
			if(isNaN(dataX.value) || isNaN(dataY.value) || isNaN(radius.value))
				return;
			
			var g:Graphics = tempShape.graphics;
			g.clear();
			
			//project center point 
			var centerPoint:Point = new Point(dataX.value,dataY.value);
			_tempDataBounds.projectPointTo(centerPoint,_tempScreenBounds);
			
			//project a point on the circle
			var circumferencePoint:Point = new Point(dataX.value+radius.value,dataY.value);
			_tempDataBounds.projectPointTo(circumferencePoint,_tempScreenBounds);
			
			//calculate projected distance
			var distance:Number = Point.distance(centerPoint,circumferencePoint);
			
			//draw circle
			g.lineStyle(thickness.value,color.value,1.0);
			g.drawCircle(centerPoint.x,centerPoint.y,distance);
			
			destination.draw(tempShape);
			
			
		}
		
	}
}