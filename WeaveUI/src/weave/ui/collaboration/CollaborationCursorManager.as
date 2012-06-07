package weave.ui.collaboration
{
	import flash.display.DisplayObject;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import weave.api.WeaveAPI;
	import weave.api.reportError;
	import weave.api.ui.ICollabCursorManager;
	
	public class CollaborationCursorManager implements ICollabCursorManager
	{
		public var cursorList:Dictionary = new Dictionary();
		
		public function createCursor(id:String):void
		{
			cursorList[id] = new CollabMouseCursor();
		}
		
		public function getCursorIds():Array
		{
			var localArray:Array = new Array();
			for( var i:String in cursorList )
				localArray.push(i);
			return localArray;		
		}
		
		private var mouseID:String;
		
		public function setVisible(id:String, visible:Boolean, duration:uint=1000):void
		{
			if(visible && duration > 0)
			{
				cursorList[id] = CollabMouseCursor.addPopUp(WeaveAPI.topLevelApplication as DisplayObject);
				(cursorList[id] as CollabMouseCursor).alpha = 100;
				mouseID = id;
				var time:Timer = new Timer(duration);
				time.addEventListener(TimerEvent.TIMER_COMPLETE, fadeMouse);
				time.start();
			}
			else
			{
				(cursorList[id] as CollabMouseCursor).alpha = 0;
			}
		}
		
		private function fadeMouse(event:TimerEvent):void
		{
			(cursorList[mouseID] as CollabMouseCursor).alpha = 0;
		}
		
		public function setPosition(id:String, x:Number, y:Number, duration:uint):void
		{
			(cursorList[id] as CollabMouseCursor).setPos(x, y);
			if( duration > 0 )
				setVisible(id, true, duration);
		}
		
		public function setColor(id:String, color:uint, duration:uint=1000):void
		{
			(cursorList[id] as CollabMouseCursor).fillCursor(color);
			setVisible(id, true, duration);
		}
		
		public function removeCursor(id:String):void
		{
			try
			{
				delete cursorList[id];
			}
			catch(e:Error)
			{
				reportError(e, "Could not delete specified cursor.");
			}
		}
	}
}