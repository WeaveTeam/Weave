package weave.visualization.plotters
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	import mx.controls.Alert;
	import mx.core.BitmapAsset;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.getCallbackCollection;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.core.ErrorManager;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.data.AttributeColumns.RunningTotalColumn;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	import weave.utils.BitmapUtils;

	public class SingleImagePlotter extends AbstractPlotter
	{
		public function SingleImagePlotter()
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
		private var imageBitmapData:BitmapData;
		private var translationMatrix:Matrix = new Matrix();
		
		[Embed(source='/weave/resources/images/red-circle.png')]
		private var defaultImageSource:Class;
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			_tempDataBounds = dataBounds;
			_tempScreenBounds = screenBounds;
			
			if(isNaN(dataX.value) || isNaN(dataY.value) )
				return;
			
			if(imageBitmapData == null)
			{
				if(imageURL.value)
					WeaveAPI.URLRequestUtils.getContent(new URLRequest(imageURL.value),handleImageRequest,handleImageFaultRequest,imageURL.value);
				else
				{
					var image:BitmapAsset = new defaultImageSource() as BitmapAsset;
					
					imageBitmapData = image.bitmapData;
					plotBitmapData(destination);
				}
			}
			else
			{
				plotBitmapData(destination);
			}
		}
		
		private function plotBitmapData(destination:BitmapData):void
		{
			var tempPoint:Point = new Point(dataX.value,dataY.value);
			_tempDataBounds.projectPointTo(tempPoint,_tempScreenBounds);
			
			
			translationMatrix.identity();
			
			
			var xOffset:Number=0;
			var yOffset:Number=0;
			
			
			switch (verticalAlign.value)
			{
				default: // default vertical align: top
				case BitmapText.VERTICAL_ALIGN_TOP: 
					yOffset = 0;
					break;
				case BitmapText.VERTICAL_ALIGN_CENTER: 
					yOffset = -imageBitmapData.height/2;
					break;
				case BitmapText.VERTICAL_ALIGN_BOTTOM:
					yOffset = -imageBitmapData.height;
					break;
			}
			
			switch (horizontalAlign.value)
			{
				default: // default horizontal align: left
				case BitmapText.HORIZONTAL_ALIGN_LEFT: // x is aligned to left side of text
					xOffset = 0;
					break;
				case BitmapText.HORIZONTAL_ALIGN_CENTER: 
					xOffset = -imageBitmapData.width/2;
					break;
				case BitmapText.HORIZONTAL_ALIGN_RIGHT: // x is aligned to right side of text
					xOffset = -imageBitmapData.width;
					break;
			}
			translationMatrix.translate(xOffset,yOffset);
			
			var scaleWidth:Number = _tempScreenBounds.getWidth() / _tempDataBounds.getWidth()/imageBitmapData.width*dataWidth.value;
			var scaleHeight:Number = -_tempScreenBounds.getHeight() / _tempDataBounds.getHeight()/imageBitmapData.height*dataHeight.value;
			if(isNaN(dataWidth.value))
			{
				scaleWidth =1;
			}
			if(isNaN(dataHeight.value))
			{
				scaleHeight = 1;
			}
			
			translationMatrix.scale(scaleWidth, scaleHeight);
			
			translationMatrix.translate(tempPoint.x,tempPoint.y);
			destination.draw(imageBitmapData,translationMatrix);
		}
		
		private function handleImageRequest(event:ResultEvent,token:Object=null):void
		{
			
			if((WeaveAPI.SessionManager as SessionManager).objectWasDisposed(this))
					return;
			if((token as String)== imageURL.value)
			{
			imageBitmapData = (event.result as Bitmap).bitmapData;
			getCallbackCollection(this).triggerCallbacks();
			}
			
			
		}
		
		private function handleImageFaultRequest(event:FaultEvent,token:Object=null):void
		{
			reportError(event);
		}
		
		private function handleImageURLChange():void
		{
			imageBitmapData = null;
		}
	}
}