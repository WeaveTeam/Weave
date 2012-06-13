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
package weave.ui.collaboration
{
	import flash.display.DisplayObject;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import weave.api.WeaveAPI;
	import weave.api.reportError;
	import weave.api.ui.ICollabCursorManager;
	
	/**
	 * A manager for the cursors in collaboration.
	 * 
	 * @author jfallon
	 */
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
			var localArray:Array = new Array();
			if( cursorList != null )
			{
				for( var i:String in cursorList )
					localArray.push(i);
			}
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
						if( cursorList[mouseID] == null )
							return;
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