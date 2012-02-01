package tests
{
	import flash.events.MouseEvent;
	
	import mx.controls.Label;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.detectLinkableObjectChange;
	import weave.api.getCallbackCollection;
	import weave.api.linkBindableProperty;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.StageUtils;
	import weave.utils.EventUtils;
	
	public class LinkableLabel extends Label implements ILinkableObject
	{
		public function LinkableLabel()
		{
			super();
			this.setStyle('fontSize', '32');
			
			// set default values
			textWrapper.value = '';
			fontWeightWrapper.value = "bold";
			
			linkBindableProperty(textWrapper, this, 'text');
			linkBindableProperty(xWrapper, this, 'x');
			linkBindableProperty(yWrapper, this, 'y');
			
			colorWrapper.addImmediateCallback(this, handleColorChange);
			fontWeightWrapper.addImmediateCallback(this, handleFontWeightChange);
			
			colorWrapper.addImmediateCallback(this, redraw);
//			getCallbackCollection(this).addImmediateCallback(this, invalidateDisplayList);
			
//			this.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
//			StageUtils.addEventCallback(MouseEvent.MOUSE_UP, this, this.stopDrag);
			
//			EventUtils.addEventCallback(this, MouseEvent.MOUSE_DOWN, this.startDrag);
		}
		
//		private function handleMouseDown(event:MouseEvent):void
//		{
//			this.startDrag();
//		}
		
		public const textWrapper:LinkableString = newLinkableChild(this, LinkableString);
		public const xWrapper:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const yWrapper:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const colorWrapper:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const fontWeightWrapper:LinkableString = newLinkableChild(this, LinkableString);
		
//		public const fontWeightWrapper:LinkableString = registerLinkableChild(this, new LinkableString("bold"));
		
//		public const fontWeightWrapper:LinkableString = registerLinkableChild(this, new LinkableString("normal", verifyFontWeight));
//		private function verifyFontWeight(value:String):Boolean
//		{
//			return value == "normal" || value == "bold";
//		}
		
		private function handleFontWeightChange():void
		{
			this.setStyle('fontWeight', fontWeightWrapper.value);
		}
		private function handleColorChange():void
		{
			this.setStyle('color', colorWrapper.value);
		}
		
		private function redraw():void
		{
			//graphics.clear();
			graphics.beginFill(colorWrapper.value, 0.25);
			graphics.lineStyle(1, colorWrapper.value, 1.0);
			graphics.moveTo(0,0);
			graphics.lineTo(unscaledWidth, unscaledHeight / 2);
			graphics.lineTo(0, unscaledHeight);
			graphics.lineTo(0, 0);
			graphics.endFill();
		}
		
		private var _colorTriggerCount:uint = 0;
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
//			if (_colorTriggerCount != colorWrapper.triggerCounter)
//			{
//				handleColorChange();
//				_colorTriggerCount = colorWrapper.triggerCounter;
//			}
			
//			if (detectLinkableObjectChange(updateDisplayList, colorWrapper))
//				handleColorChange();
			
//			redraw();
		}
	}
}