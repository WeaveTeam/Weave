package weave.ui
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import mx.containers.Canvas;
	import mx.controls.Image;
	
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableString;

	public class JavaScriptCanvas extends Canvas implements ILinkableObject
	{
		private var buffers:Vector.<Image> = new Vector.<Image>(2, true);
		private var back_buffer:Image;
		private var last_update:int = 0;
		private var rendering:Boolean = false;
		private var prev_ascii:String;

		private static const MIN_FRAME_INTERVAL:int = 1000/30;

		public const elementId:LinkableString = newLinkableChild(this, LinkableString);

		public function JavaScriptCanvas()
		{
			super();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			WeaveAPI.StageUtils.addEventCallback(Event.ENTER_FRAME, this, handleEnterFrame);
			
			for (var i:int = 0; i < buffers.length; i++)
			{
				buffers[i] = new Image();
				buffers[i].addEventListener(Event.COMPLETE, handleImageComplete);
				addChild(buffers[i]);
			}

			addChild(buffers[1]);
			
			back_buffer = buffers[0];
			last_update = getTimer();
		}

		public function handleEnterFrame():void
		{
			var interval:int = getTimer() - last_update;
			if (rendering || interval < MIN_FRAME_INTERVAL || !elementId.value)
				return;

			rendering = true;
			last_update = getTimer();
			WeaveAPI.StageUtils.callLater(this, updateImage);
		}

		public function updateImage():void
		{
			if (!elementId.value)
			{
				for each (var buffer:Image in buffers)
					buffer.visible = false;
				rendering = false;
				return;
			}

			var ascii:String = JavaScript.exec(
				{elementId: elementId.value},
				"var canvas = document.getElementById(elementId);",
				"return canvas && canvas.toDataURL && canvas.toDataURL().split(',').pop();"
			);
			if (!ascii || ascii === prev_ascii)
			{
				rendering = false;
				return;
			}
			prev_ascii = ascii;
			var bytes:ByteArray = StandardLib.atob(ascii);
			WeaveAPI.StageUtils.callLater(this, setSource, [bytes]);
		}
		
		private function setSource(content:ByteArray):void
		{
			back_buffer.source = content;
		}
		
		private function handleImageComplete(event:Event):void
		{
			if (event.target === back_buffer)
			{
				for each (var buffer:Image in buffers)
					buffer.visible = buffer === back_buffer;
				back_buffer = buffers[buffers.indexOf(buffer) ^ 1];
				rendering = false;
			}
		}
	}
}
