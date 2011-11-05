/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/
package weave.ui.colormap.colormapEditor
{
	import flash.events.Event;
	
	import mx.containers.Canvas;
	import mx.controls.Alert;
	import mx.controls.ColorPicker;
	import mx.controls.HSlider;
	import mx.events.ColorPickerEvent;
	import mx.events.ResizeEvent;
	import mx.events.SliderEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.reportError;
	import weave.core.ErrorManager;
	import weave.primitives.ColorRamp;

	public class ColormapSlider extends Canvas
	{
		private var slider:HSlider = new HSlider();	
		private var colorPickerCanvas:Canvas = new Canvas();
		private var dummyPicker:ColorPicker = new ColorPicker();
		public function ColormapSlider()
		{
			super();
			addChild(slider);
			
			slider.liveDragging = true;
			
			addEventListener(ResizeEvent.RESIZE, handleCanvasResize);
			
			this.horizontalScrollPolicy = "off";
			this.verticalScrollPolicy = "off";
			
			this.setStyle("borderStyle", "solid");
			this.setStyle("borderColor", 0x000000);
			
			this.height = 80;
			
			addChild(colorPickerCanvas);
			colorPickerCanvas.percentHeight = 100;
			colorPickerCanvas.percentWidth = 100;
			
			colorPickerCanvas.addChild(new ColorPicker());
			colorPickerCanvas.horizontalScrollPolicy = "off";
			colorPickerCanvas.verticalScrollPolicy = "off";
			
			slider.addEventListener(SliderEvent.CHANGE, handleSliderChange);
			
			colorRamp.addImmediateCallback(this, handleColorRampChange, null, true);
		}
		
		private function handleCanvasResize(event:Event):void
		{
			slider.x = 25; 
			slider.width = this.width - 50;
		}
		
		private function handleColorRampChange():void
		{
			thumbCount = colorRamp.value.children().length();
			validateDisplayList();
			
			for (var i:int = 0; i < thumbCount; i++)
				setThumbProperties( i, getColorNodeAt(i) );
		}
		
		[Inspectable]
		public function set thumbCount(value:int):void
		{
			slider.thumbCount = value;
			
			slider.validateNow();
			
			thumbProperties.length = value;
			
			colorPickerCanvas.removeAllChildren();
			
			for (var i:int = 0; i < slider.thumbCount; i++)
			{
				var colorPicker:ColorPicker = new ColorPicker();
				colorPicker.addEventListener(ColorPickerEvent.CHANGE, handleColorChange);
				colorPickerCanvas.addChild( colorPicker );
			}
		}

		public const colorRamp:ColorRamp = new ColorRamp();
		
		private function getColorNodeAt(index:int):XML
		{
			return colorRamp.value.children()[index];
		}
		
		private function handleColorChange(event:ColorPickerEvent):void
		{
			getColorNodeAt( colorPickerCanvas.getChildIndex(event.currentTarget as ColorPicker) ).@color = event.color;
			colorRamp.detectChanges();
		}
		
		private var thumbProperties:Array = [];
		public function setThumbProperties(index:int, properties:XML):void
		{
			try {
				thumbProperties[index] = properties;
				
				(colorPickerCanvas.getChildAt(index) as ColorPicker).selectedColor = properties.@color;
				slider.getThumbAt(index).x = properties.@position * slider.width;
				updateColorPickerPosition(index);
			} catch (error:Error) {
			 	//Errors from SDK should not be ignored.
				reportError(error);
			}
		}
		public function getThumbPercent(index:int):Number
		{
			return slider.getThumbAt(index).x / slider.width;
		}
		public function get thumbCount():int
		{
			return slider.thumbCount;
		}
		
		private function handleSliderChange(event:SliderEvent):void
		{
			updateColorPickerPosition(event.thumbIndex);
			
			try {
				colorRamp.value.children()[event.thumbIndex].@position = getThumbPercent(event.thumbIndex);
				colorRamp.detectChanges();
			} catch (error:Error) {
			 	//Errors from SDK should not be ignored.
				reportError(error);
			}
		}
		
		private function updateColorPickerPosition(thumbIndex:int):void
		{
			try {
				var picker:ColorPicker = colorPickerCanvas.getChildAt(thumbIndex) as ColorPicker;

				picker.x = slider.getThumbAt(thumbIndex).x + slider.getThumbAt(thumbIndex).width/2 + picker.width/2;
				picker.y = slider.getThumbAt(thumbIndex).y + slider.getThumbAt(thumbIndex).height;
			} catch (error:Error) {
			 	//Errors from SDK should not be ignored.
				reportError(error);
			}
		}
	}
}