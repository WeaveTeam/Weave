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
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.core.IProgressIndicator;
	import weave.api.getCallbackCollection;
	import weave.utils.Dictionary2D;

	/**
	 * This is an implementation of IProgressIndicator.
	 * @author adufilie
	 */
	public class ProgressIndicator implements IProgressIndicator
	{
//		private const _assignedTasks:Dictionary2D = new Dictionary2D(true, true);
//		
//		public function assignTask(owner:ILinkableObject, taskToken:Object):void
//		{
//			while (owner)
//			{
//				_assignedTasks.set(owner, taskToken, true)
//				owner = WeaveAPI.SessionManager.getLinkableOwner(owner);
//			}
//		}
//		
//		/**
//		 * A linkable object is considered busy if a task has been assigned to it or one of its descendants.
//		 * @param linkableObject
//		 * @return 
//		 * 
//		 */		
//		public function linkableObjectIsBusy(linkableObject:Object):Boolean
//		{
//			return false;
//		}

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
		public function addTask(taskToken:Object):void
		{
			updateTask(taskToken, 0);
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasTask(taskToken:Object):Boolean
		{
			return _taskToProgressMap[taskToken] !== undefined;
		}
		
		/**
		 * @inheritDoc
		 */
		public function updateTask(taskToken:Object, percent:Number):void
		{
			// if this token isn't in the Dictionary yet, increase count
			if (_taskToProgressMap[taskToken] === undefined)
			{
				if (CallbackCollection.debug)
					_taskToStackTraceMap[taskToken] = new Error("Stack trace").getStackTrace();
				_taskCount++;
				_maxTaskCount++;
			}
			if (!isFinite(percent))
				percent = 0.5; // undetermined
			_taskToProgressMap[taskToken] = percent;
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeTask(taskToken:Object):void
		{
			// if the token isn't in the dictionary, do nothing
			if (_taskToProgressMap[taskToken] === undefined)
				return;
			
			var stackTrace:String = _taskToStackTraceMap[taskToken]; // check this when debugging
			
			delete _taskToProgressMap[taskToken];
			delete _taskToStackTraceMap[taskToken];
			_taskCount--;
			// reset max count when count drops to 1
			if (_taskCount == 1)
				_maxTaskCount = _taskCount;
			
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function getNormalizedProgress():Number
		{
			// add up the percentages
			var sum:Number = 0;
			for each (var percentage:Number in _taskToProgressMap)
				sum += percentage;
			// make any pending requests that no longer exist count as 100% done
			sum += _maxTaskCount - _taskCount;
			// divide by the max count to get overall percentage
			return sum / _maxTaskCount;
		}

		private var _taskCount:int = 0;
		private var _maxTaskCount:int = 0;
		private const _taskToProgressMap:Dictionary = new Dictionary();
		private const _taskToStackTraceMap:Dictionary = new Dictionary();
	}
}
