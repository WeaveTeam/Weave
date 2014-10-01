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

package weave.core
{
	import flash.utils.Dictionary;
	
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.core.IProgressIndicator;
	import weave.api.getCallbackCollection;
	import weave.compiler.StandardLib;

	/**
	 * This is an implementation of IProgressIndicator.
	 * @author adufilie
	 */
	public class ProgressIndicator implements IProgressIndicator
	{
		public static var debug:Boolean = false;
		
		/**
		 * For debugging, returns debugIds for active tasks.
		 */
		public function debugTasks():Array
		{
			var result:Array = [];
			for (var task:Object in _progress)
				result.push(debugId(task));
			return result;
		}
		public function getDescriptions():Array
		{
			var result:Array = [];
			for (var task:Object in _progress)
			{
				var desc:String = _description[task] || "Unnamed task";
				if (desc)
					result.push("(" + StandardLib.roundSignificant(100*_progress[task], 3) + "%) " + desc);
			}
			StandardLib.sort(result);
			return result;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getTaskCount():int
		{
			return _taskCount;
		}

		/**
		 * @inheritDoc
		 */
		public function addTask(taskToken:Object, busyObject:ILinkableObject = null, description:String = null):void
		{
			var cc:ICallbackCollection = getCallbackCollection(this);
			cc.delayCallbacks();
			
			if (taskToken is AsyncToken && _progress[taskToken] === undefined)
				(taskToken as AsyncToken).addResponder(new AsyncResponder(handleAsyncToken, handleAsyncToken, taskToken));
			
			_description[taskToken] = description;
			
			// add task before WeaveAPI.SessionManager.assignBusyTask()
			updateTask(taskToken, NaN); // NaN is used as a special case when adding the task
			
			if (busyObject)
				WeaveAPI.SessionManager.assignBusyTask(taskToken, busyObject);
			
			cc.resumeCallbacks();
		}
		
		private function handleAsyncToken(event:Object, token:AsyncToken):void
		{
			removeTask(token);
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasTask(taskToken:Object):Boolean
		{
			return _progress[taskToken] !== undefined;
		}
		
		/**
		 * @inheritDoc
		 */
		public function updateTask(taskToken:Object, progress:Number):void
		{
			// if this token isn't in the Dictionary yet, increase count
			if (_progress[taskToken] === undefined)
			{
				// expecting NaN from addTask()
				if (!isNaN(progress))
					throw new Error("updateTask() called, but task was not previously added with addTask()");
				if (debug)
					_stackTrace[taskToken] = new Error("Stack trace").getStackTrace();
				
				// increase count when new task is added
				_taskCount++;
				_maxTaskCount++;
			}
			
			if (_progress[taskToken] !== progress)
			{
				_progress[taskToken] = progress;
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeTask(taskToken:Object):void
		{
			// if the token isn't in the dictionary, do nothing
			if (_progress[taskToken] === undefined)
				return;

			var stackTrace:String = _stackTrace[taskToken]; // check this when debugging
			
			delete _progress[taskToken];
			delete _description[taskToken];
			delete _stackTrace[taskToken];
			_taskCount--;
			// reset max count when count drops to 1
			if (_taskCount == 1)
				_maxTaskCount = _taskCount;
			
			WeaveAPI.SessionManager.unassignBusyTask(taskToken);

			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function getNormalizedProgress():Number
		{
			// add up the percentages
			var sum:Number = 0;
			for (var task:Object in _progress)
			{
				var stackTrace:String = _stackTrace[task]; // check this when debugging
				var progress:Number = _progress[task];
				if (isFinite(progress))
					sum += progress;
			}
			// make any pending requests that no longer exist count as 100% done
			sum += _maxTaskCount - _taskCount;
			// divide by the max count to get overall percentage
			return sum / _maxTaskCount;
		}

		private var _taskCount:int = 0;
		private var _maxTaskCount:int = 0;
		private const _progress:Dictionary = new Dictionary();
		private const _description:Dictionary = new Dictionary();
		private const _stackTrace:Dictionary = new Dictionary();
		
		public function test():void
		{
			for(var i:Object in _progress)
			{
				var stackTrace:String = _stackTrace[i]; // check this when debugging
				var description:String = _description[i];
				trace(description, stackTrace);
			}
		}
	}
}
