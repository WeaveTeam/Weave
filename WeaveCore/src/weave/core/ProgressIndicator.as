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
	
	import weave.api.core.IProgressIndicator;

	/**
	 * This is an implementation of IProgressIndicator
	 * @inheritDoc
	 * @author adufilie
	 */
	public class ProgressIndicator extends CallbackCollection implements IProgressIndicator
	{
		public function getTaskCount():int
		{
			return _taskCount;
		}

		public function addTask(taskToken:Object):void
		{
			updateTask(taskToken, 0);
		}
		
		public function hasTask(taskToken:Object):Boolean
		{
			return _taskToProgressMap[taskToken] !== undefined;
		}
		
		public function updateTask(taskToken:Object, percent:Number):void
		{
			// if this token isn't in the Dictionary yet, increase count
			if (_taskToProgressMap[taskToken] === undefined)
			{
				_taskCount++;
				_maxTaskCount++;
			}
			if (!isFinite(percent))
				percent = 0.5; // undetermined
			_taskToProgressMap[taskToken] = percent;
			triggerCallbacks();
		}
		
		public function removeTask(taskToken:Object):void
		{
			// if the token isn't in the dictionary, do nothing
			if (_taskToProgressMap[taskToken] === undefined)
				return;
			
			delete _taskToProgressMap[taskToken];
			_taskCount--;
			// reset max count when count goes to zero
			if (_taskCount == 0)
				_maxTaskCount = 0;
			
			triggerCallbacks();
		}
		
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
	}
}
