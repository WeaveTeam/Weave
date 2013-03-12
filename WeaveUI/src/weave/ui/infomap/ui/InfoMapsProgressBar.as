package weave.ui.infomap.ui
{
	import flash.events.Event;
	
	import mx.controls.ProgressBar;
	import mx.controls.ProgressBarLabelPlacement;

	public class InfoMapsProgressBar extends ProgressBar
	{
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			mouseChildren = false;
			includeInLayout = false;
			setStyle("trackHeight", 16);
			setStyle("borderColor", 0x000000);
			setStyle("color", 0xFFFFFF); //color of text
			setStyle("barColor", "haloBlue");
			setStyle("trackColors", [0x000000, 0x000000]);
			labelPlacement = ProgressBarLabelPlacement.CENTER;
			label = '';
			mode = "manual";
			minHeight = 16;
			minWidth = 135;
			x = 0;
			
			addEventListener(Event.ENTER_FRAME, handleEnterFrame);
			
		}
		
		private function handleEnterFrame(event:Event = null):void
		{
			if (parent && visible)
			{
				x = (parent.width/2) - (width/2);
				y = (parent.height/2) - (height/2);
			}
		}
		
		private var _maxProgressBarValue:int = 0;
		
		
	}
}
