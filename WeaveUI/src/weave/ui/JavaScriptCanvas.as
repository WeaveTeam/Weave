package weave.ui
{
	import weave.compiler.StandardLib;
	import weave.api.core.ILinkableObject;

	import mx.containers.Canvas;
	import mx.controls.Image;

	import flash.events.Event;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.events.TimerEvent;

	public class JavaScriptCanvas extends Canvas implements ILinkableObject
	{
		private var buffers:Vector.<Image> = new Vector.<Image>(2, true);
		private var buffer_index:int = 0;
		private var lastUpdate:int = 0;
		private var forceReadTimer:Timer;

		public var sourceId:String = null;


		public function JavaScriptCanvas()
		{
			super();
		}
		
		override protected function createChildren():void
		{
			lastUpdate = getTimer();
			forceReadTimer = new Timer(250);
			buffers[0] = new Image();
			buffers[1] = new Image();

			buffers[0].addEventListener(Event.COMPLETE, readFromCanvas);
			buffers[1].addEventListener(Event.COMPLETE, readFromCanvas);
			forceReadTimer.addEventListener(TimerEvent.TIMER, readFromCanvas);

			addChild(buffers[0]);
			addChild(buffers[1]);

			super.createChildren();

			forceReadTimer.start();
		}

		public function readFromCanvas(evt:Event):void
		{
			/* Only execute on the timer tick if we haven't loaded recently */
			if (evt.type == TimerEvent.TIMER && (getTimer() < (lastUpdate + 200)) ) return;

			if (evt.type == TimerEvent.TIMER) weaveTrace("timed out, jumpstarting canvas read");

			var content:String;

			/* TODO convert to raw ExternalInterface */
			if (sourceId) content = JavaScript.exec(
				{elementId: sourceId},
				"var canvas = document.getElementById(elementId);",
				"return canvas && canvas.toDataURL && canvas.toDataURL().split(',').pop();");

			if (sourceId && content)
			{
				setImage(content);	
			}
			

		}

		public function setImage(base64:String):void
		{
			lastUpdate = getTimer();

			setChildIndex(buffers[buffer_index], 0);

			buffer_index = (buffer_index + 1) % 2;

			buffers[buffer_index].source = StandardLib.atob(base64);
		}
	}
}