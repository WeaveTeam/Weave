/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weavejs.core
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.core.IProgressIndicator;
	import weavejs.utils.DebugUtils;
	import weavejs.utils.JS;
	import weavejs.utils.StandardLib;

	public class ProgressIndicator implements IProgressIndicator
	{
		public static var debug:Boolean = false;
		
		/**
		 * For debugging, returns debugIds for active tasks.
		 */
		public function debugTasks():Array
		{
			var result:Array = [];
			var tasks:Array = JS.mapKeys(map_task_progress);
			for each (var task:Object in tasks)
				result.push(DebugUtils.debugId(task));
			return result;
		}
		public function getDescriptions():Array
		{
			var result:Array = [];
			var tasks:Array = JS.mapKeys(map_task_progress);
			for each (var task:Object in tasks)
			{
				var desc:String = map_task_description.get(task) || "Unnamed task";
				if (desc)
					result.push(DebugUtils.debugId(task) + " (" + StandardLib.roundSignificant(100 * map_task_progress.get(task), 3) + "%) " + desc);
			}
			return result.sort();
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
			var cc:ICallbackCollection = WeaveAPI.SessionManager.getCallbackCollection(this);
			cc.delayCallbacks();
			
			if (taskToken is JS.Promise && map_task_progress.get(taskToken) === undefined)
			{
				var remove:Function = removeTask.bind(this, taskToken);
				taskToken.then(remove, remove);
			}
			
			map_task_description.set(taskToken, description);
			
			// add task before WeaveAPI.SessionManager.assignBusyTask()
			updateTask(taskToken, NaN); // NaN is used as a special case when adding the task
			
			if (busyObject)
				WeaveAPI.SessionManager.assignBusyTask(taskToken, busyObject);
			
			cc.resumeCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasTask(taskToken:Object):Boolean
		{
			return map_task_progress.get(taskToken) !== undefined;
		}
		
		/**
		 * @inheritDoc
		 */
		public function updateTask(taskToken:Object, progress:Number):void
		{
			// if this token isn't in the Dictionary yet, increase count
			if (map_task_progress.get(taskToken) === undefined)
			{
				// expecting NaN from addTask()
				if (!isNaN(progress))
					throw new Error("updateTask() called, but task was not previously added with addTask()");
				if (debug)
					map_task_stackTrace.set(taskToken, new Error("Stack trace"));
				
				// increase count when new task is added
				_taskCount++;
				_maxTaskCount++;
			}
			
			if (map_task_progress.get(taskToken) !== progress)
			{
				map_task_progress.set(taskToken, progress);
				WeaveAPI.SessionManager.getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeTask(taskToken:Object):void
		{
			// if the token isn't in the dictionary, do nothing
			if (map_task_progress['delete'](taskToken) === undefined)
				return;

			var stackTrace:String = map_task_stackTrace['delete'](taskToken); // check this when debugging
			
			map_task_progress['delete'](taskToken);
			map_task_description['delete'](taskToken);
			map_task_stackTrace['delete'](taskToken);
			_taskCount--;
			// reset max count when count drops to 1
			if (_taskCount == 1)
				_maxTaskCount = _taskCount;
			
			WeaveAPI.SessionManager.unassignBusyTask(taskToken);

			WeaveAPI.SessionManager.getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function getNormalizedProgress():Number
		{
			// add up the percentages
			var sum:Number = 0;
			for (var task:Object in map_task_progress)
			{
				var stackTrace:String = map_task_stackTrace.get(task); // check this when debugging
				var progress:Number = map_task_progress.get(task);
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
		private var map_task_progress:Object = new JS.Map();
		private var map_task_description:Object = new JS.Map();
		private var map_task_stackTrace:Object = new JS.Map();
		
		public function test():void
		{
			for(var i:Object in map_task_progress)
			{
				var stackTrace:String = map_task_stackTrace.get(i); // check this when debugging
				var description:String = map_task_description.get(i);
				var args:Array = [DebugUtils.debugId(i), description, stackTrace];
				JS.log.apply(JS, args);
			}
		}
	}
}
