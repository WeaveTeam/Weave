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
		public static var numMouses:Number = 1;
		private var cursorList:Dictionary = null;
		private var cursorQueue:Array = null;
		
		public function createCursor(id:String):void
		{
			if( cursorList == null )
				cursorList = new Dictionary();
			if( cursorQueue == null )
				cursorQueue = new Array();
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
			if( checkQueuePosition(id) != 0)
				return;
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
		//This function is used to produce the effect of the mouse fading.
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
						//Inline function for fading effect.
						i++;
						if( cursorList[mouseID] == null )
						{
							timer.stop();
							return;
						}
						(cursorList[mouseID] as CollabMouseCursor).alpha = 1 - i/25;
					});
				}
		}
		
		public function setPosition(id:String, x:Number, y:Number, duration:uint):void
		{
			if( checkQueuePosition(id) != 0)
				return;
			if( duration > 0 )
				setVisible(id, true, duration);
			(cursorList[id] as CollabMouseCursor).setPos(x, y);
		}
		
		public function setColor(id:String, color:uint, duration:uint=1000):void
		{
			if( checkQueuePosition(id) != 0 )
				return;
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
				removeFromQueue(id, "");
				delete cursorList[id];
				if( getCursorIds().length == 0 )
					cursorList = null;
			}
			catch(e:Error)
			{
				reportError(e, "Could not delete specified cursor.");
			}
		}	
		
		public function addToQueue(id:String, self:String):Array
		{
			if( cursorQueue == null )
				cursorQueue = new Array();
			for( var i:int = 0; i < cursorQueue.length; i++ )
			{
				if( cursorQueue[i] == id )
					return checkPeoplePosition(self);
			}	
			cursorQueue.push(id);
			return checkPeoplePosition(self);
		}
		
		public function removeFromQueue(id:String, self:String):Array
		{
			if( cursorQueue == null )
			{
				var testArray:Array = new Array();
				testArray.push(-1);
				return testArray;
			}
			for( var i:int = 0; i < cursorQueue.length; i++ )
			{
				if( cursorQueue[i] == id )
				{
					if( id != self )
						if( cursorList[id] != null )
							(cursorList[id] as CollabMouseCursor).alpha = 0;
					cursorQueue.splice(i, 1);
				}
			}
			return checkPeoplePosition(self);
		}
		
		/*This will return 0 if the id is an active mouse, return a number above 0 to indicate
		* position in the line to become an active mouse, or return -1 if the id is not in the queue.
		*/
		private function checkQueuePosition(id:String):Number
		{
			for( var i:int = 0; i < cursorQueue.length; i++ )
			{
				if( cursorQueue[i] == id )
				{
					if( i - numMouses < 0 )
						return 0;
					else if( i - numMouses >= 0 )
						return i - numMouses + 1;
				}
			}
			return -1;
		}
		
		private function checkPeoplePosition(id:String):Array
		{
			var array:Array = new Array();
			for( var i:int = 0; i < cursorQueue.length; i++ )
			{
				if( cursorQueue[i] == id )
				{
					if( i - numMouses < 0 )
					{
						array.push(0);
						break;
					}					
					else if( i - numMouses >= 0 )
					{
						array.push(i - numMouses + 1);
						break;
					}
				}
				else
					array.push("placeholder");
			}	
			for( var j:int = 0; j < numMouses; j++ )
				array.push(cursorQueue[j]);
			return array;
		}
	}
}