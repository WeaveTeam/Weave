package weave.utils
{
	import flash.display.Bitmap;
	import flash.events.Event;
	
	public class ImageLoaderUtilsEvent extends Event
	{
		public static const LOAD_COMPLETE:String = "IMAGELOADER_LOAD_COMPLETE";
		public static const ERROR:String = "IMAGELOADER_ERROR";
		
		private var _bitmap:Bitmap = null;
		private var _event:Event = null;
		
		public function ImageLoaderUtilsEvent(type:String, e:Event, bitmap:Bitmap = null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			_event = e;
			_bitmap = bitmap;
		}
		
		public function get bitmap():Bitmap	{	return _bitmap;	}
		public function get event():Event	{	return _event;	}
	}
}