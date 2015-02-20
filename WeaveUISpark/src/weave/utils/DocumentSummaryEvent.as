package weave.utils
{
	import flash.events.Event;
	
	import weave.api.data.IQualifiedKey;
	
	public class DocumentSummaryEvent extends Event
	{
		public static const DISPLAY_DOCUMENT:String = "displayDocument";
		public static const HIDE_DOCUMENT:String = "hideDocument";
		public static const OPEN_DOCUMENT:String = "openDocument";
		
		public var xPos:Number;
		public var yPos:Number;
		public var docTitle:String;
		public var imageKey:IQualifiedKey;
		
		public function DocumentSummaryEvent(type:String, xPos:Number=0, yPos:Number=0, docTitle:String="", imageKey:IQualifiedKey=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.xPos = xPos;
			this.yPos = yPos;
			this.docTitle = docTitle;
			this.imageKey = imageKey;
		}
		
		public override function clone():Event
		{
			return new DocumentSummaryEvent(type, xPos, yPos, docTitle, imageKey, bubbles, cancelable);
		}
	}
}