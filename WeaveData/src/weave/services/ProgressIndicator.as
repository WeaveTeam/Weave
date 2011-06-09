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

package weave.services
{
	import flash.utils.Dictionary;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.data.IProgressIndicator;
	import weave.api.getCallbackCollection;
	import weave.core.CallbackCollection;

	/**
	 * This class is used as a central location for reporting the progress of pending asynchronous requests.
	 * 
	 * @author adufilie
	 */
	public class ProgressIndicator extends CallbackCollection implements IProgressIndicator
	{
		/**
		 * This is the number of pending requests.
		 */
		public function getTaskCount():int
		{
			return _taskCount;
		}

		/**
		 * This function will register a pending request token and increase the pendingRequestCount if necessary.
		 * 
		 * @param taskToken The object whose progress to track.
		 */
		public function addTask(taskToken:Object):void
		{
			updateTask(taskToken, 0);
		}
		
		/**
		 * This function will report the current progress of a request.
		 * 
		 * @param taskToken The object whose progress to track.
		 * @param percent The current progress of the token's request.
		 */
		public function updateTask(taskToken:Object, percent:Number):void
		{
			// if this token isn't in the Dictionary yet, increase count
			if (_taskToProgressMap[taskToken] == undefined)
			{
				_taskCount++;
				_maxTaskCount++;
			}
			_taskToProgressMap[taskToken] = percent;
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * This function will remove a previously registered pending request token and decrease the pendingRequestCount if necessary.
		 * 
		 * @param taskToken The object to remove from the progress indicator.
		 */
		public function removeTask(taskToken:Object):void
		{
			// if the token isn't in the dictionary, do nothing
			if (_taskToProgressMap[taskToken] == undefined)
				return;
			
			delete _taskToProgressMap[taskToken];
			_taskCount--;
			// reset max count when count goes to zero
			if (_taskCount == 0)
				_maxTaskCount = 0;
			
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * This function checks the overall progress of all pending requests.
		 * @return A Number between 0 and 1.
		 */
		public function getNormalizedProgress():Number
		{
			// add up the percentages
			var sum:Number = 0;
			for each (var percentage:Number in _pendingRequestToPercentMap)
				sum += percentage;
			// make any pending requests that no longer exist count as 100% done
			sum += _maxTaskCount - _taskCount;
			// divide by the max count to get overall percentage
			return sum / _maxTaskCount;
		}

		private var _taskCount:int = 0;
		private var _maxTaskCount:int = 0;
		private const _pendingRequestToPercentMap:Dictionary = new Dictionary();
		private const _taskToProgressMap:Dictionary = new Dictionary();
	}
}
