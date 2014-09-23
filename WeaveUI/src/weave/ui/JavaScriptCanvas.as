package weave.ui
{
	import weave.compiler.StandardLib;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableString;
	import weave.api.newLinkableChild;

	import mx.containers.Canvas;
	import mx.controls.Image;

	import flash.events.Event;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.utils.Dictionary;
	import flash.events.TimerEvent;

	public class JavaScriptCanvas extends Canvas implements ILinkableObject
	{
		private var buffers:Vector.<Image> = new Vector.<Image>(2, true);
		private var buffer_index:int = 0;
		private var last_update:int = 0;
		private var buffer_dirty:Dictionary = new Dictionary();

		private static const MIN_FRAME_INTERVAL:int = 1000/30;

		public const elementId:LinkableString = newLinkableChild(this, LinkableString);


		public function JavaScriptCanvas()
		{
			super();
		}
		
		override protected function createChildren():void
		{
			buffers[0] = new Image();
			buffers[1] = new Image();

			buffer_dirty[buffers[0]] = false;
			buffer_dirty[buffers[1]] = false;

			buffers[0].addEventListener(Event.COMPLETE, readFromCanvas);
			buffers[1].addEventListener(Event.COMPLETE, readFromCanvas);
			addEventListener(Event.ENTER_FRAME, readFromCanvas);

			addChild(buffers[0]);
			addChild(buffers[1]);

			super.createChildren();

			last_update = getTimer();
		}

		public function readFromCanvas(evt:Event = null):void
		{
			var target:Image = evt.target as Image;

			if (target)
				buffer_dirty[target] = false;

			var interval:int = getTimer() - last_update;

			if (!elementId.value ||interval < MIN_FRAME_INTERVAL || buffer_dirty[buffers[buffer_index]])
			{
				return;
			}

			var content:String;

			last_update = getTimer();

			buffer_index = (buffer_index + 1) % 2;

			buffer_dirty[buffers[buffer_index]] = true;
			
			WeaveAPI.StageUtils.callLater(this, updateImage);
		}

		public function updateImage():void
		{
			var content:String;
			var current_buffer:Image = buffers[buffer_index];
			
			if (!elementId.value)
			{
				buffer_dirty[current_buffer] = false;
				return;
			}

			content = JavaScript.exec(
				{elementId: elementId.value},
				"var canvas = document.getElementById(elementId);",
				"return canvas && canvas.toDataURL && canvas.toDataURL().split(',').pop();");

			if (!content) 
			{
				buffer_dirty[current_buffer] = false;
				return;
			}

			setChildIndex(current_buffer, 1);

			current_buffer.source = StandardLib.atob(content);

			
		}
	}
}