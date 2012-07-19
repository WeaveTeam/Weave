// modified from http://www.frishy.com/2007/09/autoscrolling-for-flex-tree/
package weave.ui {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	
	import mx.containers.Canvas;
	import mx.controls.Label;
	import mx.controls.List;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.effects.easing.Back;
	
	import weave.utils.BitmapText;
	import weave.utils.BitmapUtils;
	import weave.utils.EventUtils;
	import weave.utils.PlotterUtils;
	
	public class CustomLabel extends UIComponent
	{
		public function CustomLabel(){
			super();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			addChild(l);
//			addChild(labelBitmap);
		}
		
		public var labelBitmap:Bitmap = new Bitmap();
		public var l:Label = new Label();
		
		public function renderLabel():void
		{
			PlotterUtils.setBitmapDataSize(labelBitmap,l.textWidth+10,l.textHeight+10);
			l.validateNow();
			labelBitmap.bitmapData.draw(l);
		}
		
		public function renderLabelAndDiscard():void
		{
			renderLabel();
			graphics.beginBitmapFill(labelBitmap.bitmapData);
			graphics.drawRect(0, 0, labelBitmap.bitmapData.width, labelBitmap.bitmapData.height);
			graphics.endFill();

			removeChild(l);
		}
	}
}