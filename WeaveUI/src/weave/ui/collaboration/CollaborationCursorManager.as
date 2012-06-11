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
		private var cursorList:Dictionary = null;
		
		public function createCursor(id:String):void
		{
			if( cursorList == null )
				cursorList = new Dictionary();
			if( cursorList[id] is CollabMouseCursor )
				return;
			cursorList[id] = CollabMouseCursor.addPopUp(WeaveAPI.topLevelApplication as DisplayObject);
			(cursorList[id] as CollabMouseCursor).alpha = 0;
		}
		
		public function getCursorIds():Array
		{
			if( cursorList == null )
				return null;
			var localArray:Array = new Array();
			for( var i:String in cursorList )
				localArray.push(i);
			return localArray;		
		}
		
		private var mouseID:String;
		private var time:Timer = null;
		
		public function setVisible(id:String, visible:Boolean, duration:uint=3000):void
		{
			if(visible && duration > 0)
			{
				(cursorList[id] as CollabMouseCursor).alpha = 1;
				mouseID = id;
				if( time != null )
					time.removeEventListener(TimerEvent.TIMER_COMPLETE, fadeMouse);
				time = new Timer(duration, 1);
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
			if( cursorList != null )
				if( cursorList[mouseID] != null )
				{
					var timer:Timer = new Timer(20, 25);
					var i:int = 0;
					timer.start();
					timer.addEventListener(TimerEvent.TIMER, function fadeCursor(e:TimerEvent):void
					{
						i++;
						(cursorList[mouseID] as CollabMouseCursor).alpha = 1 - i/25;
					});
				}
		}
		
		public function setPosition(id:String, x:Number, y:Number, duration:uint):void
		{
			if( duration > 0 )
				setVisible(id, true, duration);
			(cursorList[id] as CollabMouseCursor).setPos(x, y);
		}
		
		public function setColor(id:String, color:uint, duration:uint=1000):void
		{
			(cursorList[id] as CollabMouseCursor).fillCursor(color);
			setVisible(id, true, duration);
		}
		
		public function getColor(id:String):Number
		{
			if( cursorList[id] == null )
				return NaN;
			return (cursorList[id] as CollabMouseCursor).color;
		}
		
		public function removeCursor(id:String):void
		{
			try
			{
				(cursorList[id] as CollabMouseCursor).removePopUp();
				delete cursorList[id];
				if( getCursorIds().length == 0 )
					cursorList = null;
			}
			catch(e:Error)
			{
				reportError(e, "Could not delete specified cursor.");
			}
		}
	}
}