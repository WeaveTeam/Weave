package weave.visualization.plotters
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	import mx.controls.Alert;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.getCallbackCollection;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.ErrorManager;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.data.AttributeColumns.RunningTotalColumn;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	import weave.utils.BitmapUtils;

	public class ImageCoordinatesPlotter extends AbstractPlotter
	{
		public function ImageCoordinatesPlotter()
		{
		}
		
		
		public const horizontalAlign:LinkableString =  registerLinkableChild(this,new LinkableString(BitmapText.HORIZONTAL_ALIGN_LEFT));
		public const verticalAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.VERTICAL_ALIGN_TOP));		
		
		public const dataX:LinkableNumber = registerLinkableChild(this,new LinkableNumber());
		public const dataY:LinkableNumber = registerLinkableChild(this,new LinkableNumber());
		
		public const dataWidth:LinkableNumber = registerLinkableChild(this,new LinkableNumber());
		public const dataHeight:LinkableNumber = registerLinkableChild(this,new LinkableNumber());
		
		public const imageURL:LinkableString = registerLinkableChild(this,new LinkableString(),handleImageURLChange);
		
		private var _tempDataBounds:IBounds2D;
		private var _tempScreenBounds:IBounds2D;
		private var _tempBitmapData:BitmapData;
		private var _tempMatrix:Matrix = new Matrix();
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			_tempDataBounds = dataBounds;
			_tempScreenBounds = screenBounds;
			
			var tempPoint:Point = new Point(dataX.value,dataY.value);
			
			_tempDataBounds.projectPointTo(tempPoint,_tempScreenBounds);
			
			if(_tempBitmapData == null)
				WeaveAPI.URLRequestUtils.getContent(new URLRequest(imageURL.value),handleImageRequest,handleImageFaultRequest,imageURL.value);
			else
			{
				_tempMatrix.identity();
				
				var xOffset:Number=0;
				var yOffset:Number=0;
				
				
				switch (verticalAlign.value)
				{
					default: // default vertical align: top
					case BitmapText.VERTICAL_ALIGN_TOP: 
						yOffset = 0;
						break;
					case BitmapText.VERTICAL_ALIGN_CENTER: 
						yOffset = -_tempBitmapData.height/2;
						break;
					case BitmapText.VERTICAL_ALIGN_BOTTOM:
						yOffset = -_tempBitmapData.height;
						break;
				}
				
				switch (horizontalAlign.value)
				{
					default: // default horizontal align: left
					case BitmapText.HORIZONTAL_ALIGN_LEFT: // x is aligned to left side of text
						xOffset = 0;
						break;
					case BitmapText.HORIZONTAL_ALIGN_CENTER: 
						xOffset = -_tempBitmapData.width/2;
						break;
					case BitmapText.HORIZONTAL_ALIGN_RIGHT: // x is aligned to right side of text
						xOffset = -_tempBitmapData.width;
						break;
				}
				_tempMatrix.translate(xOffset,yOffset);
				
				var scaleWidth:Number = screenBounds.getWidth() / dataBounds.getWidth()/_tempBitmapData.width*dataWidth.value;
				var scaleHeight:Number = -screenBounds.getHeight() / dataBounds.getHeight()/_tempBitmapData.height*dataHeight.value;
				if(isNaN(dataWidth.value))
				{
					scaleWidth =1;
				}
				if(isNaN(dataHeight.value))
				{
					scaleHeight = 1;
				}
				
				
				_tempMatrix.scale(scaleWidth, scaleHeight);
				
				_tempMatrix.translate(tempPoint.x,tempPoint.y);
				destination.draw(_tempBitmapData,_tempMatrix);
			}
		}
		
		private function handleImageRequest(event:ResultEvent,token:Object=null):void
		{
			
			if((WeaveAPI.SessionManager as SessionManager).objectWasDisposed(this))
					return;
			if((token as String)== imageURL.value)
			{
			_tempBitmapData = (event.result as Bitmap).bitmapData;
			getCallbackCollection(this).triggerCallbacks();
			}
			
			
		}
		
		private function handleImageFaultRequest(event:FaultEvent,token:Object=null):void
		{
			WeaveAPI.ErrorManager.reportError(event.fault);
		}
		
		private function handleImageURLChange():void
		{
			_tempBitmapData = null;
		}
	}
}