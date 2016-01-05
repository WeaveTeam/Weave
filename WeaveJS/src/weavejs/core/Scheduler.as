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
	import weavejs.api.core.IDisposableObject;
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.core.IScheduler;
	import weavejs.util.DebugTimer;
	import weavejs.util.DebugUtils;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	
	/**
	 * This allows you to add callbacks that will be called when an event occurs on the stage.
	 * 
	 * WARNING: These callbacks will trigger on every mouse and keyboard event that occurs on the stage.
	 *          Developers should not add any callbacks that run computationally expensive code.
	 * 
	 * @author adufilie
	 */
	public class Scheduler implements IScheduler, IDisposableObject
	{
		public static var debug_fps:Boolean = false;
		public static var debug_async_time:Boolean = false;
		public static var debug_async_stack:Boolean = false;
		public static var debug_async_stack_elapsed:Boolean = false;
		public static var debug_delayTasks:Boolean = false; // set this to true to delay async tasks
		public static var debug_callLater:Boolean = false; // set this to true to delay async tasks
		public static var debug_visibility:Boolean = false; // set this to true to delay async tasks
		
		public function Scheduler()
		{
			_frameCallbacks.addImmediateCallback(this, _requestNextFrame, true);
			_frameCallbacks.addImmediateCallback(this, _handleCallLater);
			initVisibilityHandler();
		}
		
		public function get frameCallbacks():ICallbackCollection
		{
			return _frameCallbacks;
		}
		
		private const _frameCallbacks:ICallbackCollection = Weave.disposableChild(this, CallbackCollection);
		private var _nextAnimationFrame:int;
		
		private function _requestNextFrame():void
		{
			_nextAnimationFrame = JS.requestAnimationFrame(_frameCallbacks.triggerCallbacks);
		}
		
		public function dispose():void
		{
			JS.cancelAnimationFrame(_nextAnimationFrame);
		}
		
		public var averageFrameTime:int = 0;
		private var _currentFrameStartTime:int = JS.now(); // this is the result of JS.now() on the last ENTER_FRAME event.
		private var _previousFrameElapsedTime:int = 0; // this is the amount of time it took to process the previous frame.
		
		private var frameTimes:Array = [];
		private var map_task_stackTrace:Object = new JS.WeakMap(); // used by callLater to remember stack traces
		private var map_task_elapsedTime:Object = new JS.WeakMap();
		private var map_task_startTime:Object = new JS.WeakMap();
		private var _currentTaskStopTime:int = 0; // set on enterFrame, used by _iterateTask
		
		/**
		 * This is an Array of "callLater queues", each being an Array of function invocations to be done later.
		 * The Arrays get populated by callLater().
		 * There are four nested Arrays corresponding to the four priorities (0, 1, 2, 3) defined by static constants in WeaveAPI.
		 */
		private var _priorityCallLaterQueues:Array = [[], [], [], []];
		private var _activePriority:uint = WeaveAPI.TASK_PRIORITY_IMMEDIATE + 1; // task priority that is currently being processed
		private var _activePriorityElapsedTime:uint = 0; // elapsed time for active task priority
		private var _priorityAllocatedTimes:Array = [Number.MAX_VALUE, 300, 200, 100]; // An Array of allocated times corresponding to callLater queues.
		private var _deactivatedMaxComputationTimePerFrame:uint = 1000;
		
		/**
		 * This gets the maximum milliseconds spent per frame performing asynchronous tasks.
		 */
		public function getMaxComputationTimePerFrame():uint
		{
			return maxComputationTimePerFrame;
		}

		/**
		 * This sets the maximum milliseconds spent per frame performing asynchronous tasks.
		 * @param The new value.
		 */
		public function setMaxComputationTimePerFrame(value:uint):void
		{
			maxComputationTimePerFrame = value;
		}
		
		/**
		 * This will get the time allocation for a specific task priority.
		 * @param priority The task priority defined by one of the constants in WeaveAPI.
		 * @return The time allocation for the specified task priority.
		 */
		public function getTaskPriorityTimeAllocation(priority:uint):uint
		{
			return uint(_priorityAllocatedTimes[priority]);
		}
		
		/**
		 * This will set the time allocation for a specific task priority.
		 * @param priority The task priority defined by one of the constants in WeaveAPI.
		 * @param milliseconds The new time allocation for the specified task priority.
		 */
		public function setTaskPriorityTimeAllocation(priority:uint, milliseconds:uint):void
		{
			_priorityAllocatedTimes[priority] = Math.max(milliseconds, 5);
		}
		
		/**
		 * When the current frame elapsed time reaches this threshold, callLater processing will be done in later frames.
		 */
		public var maxComputationTimePerFrame:uint = 100;
		private var maxComputationTimePerFrame_noActivity:uint = 250;
		
		public function get previousFrameElapsedTime():int
		{
			return _previousFrameElapsedTime;
		}
		
		public function get currentFrameElapsedTime():int
		{
			return JS.now() - _currentFrameStartTime;
		}
		
		private static var _time:int;
		private static var _times:Array = [];
		public static function debugTime(str:String):int
		{
			var now:int = JS.now();
			var dur:int = (now - _time);
			if (dur > 100)
			{
				_times.push(dur + ' ' + str);
			}
			else
			{
				var dots:String = '...';
				var n:int = _times.length;
				if (n && _times[n - 1] != dots)
					_times.push(dots);
			}
			_time = now;
			return dur;
		}
		private static function resetDebugTime():void
		{
			_times.length = 0;
			_time = JS.now();
		}
		
		private var HIDDEN:String;
		private var VISIBILITY_CHANGE:String;
		private var deactivated:Boolean = true; // true when application is deactivated
		private var useDeactivatedFrameRate:Boolean = false; // true when deactivated and framerate drop detected
		
		private function initVisibilityHandler():void
		{
			// Set the name of the hidden property and the change event for visibility
			if (typeof JS.global.document.hidden !== "undefined")
			{
				// Opera 12.10 and Firefox 18 and later support 
				HIDDEN = "hidden";
				VISIBILITY_CHANGE = "visibilitychange";
			}
			else if (typeof JS.global.document.mozHidden !== "undefined")
			{
				HIDDEN = "mozHidden";
				VISIBILITY_CHANGE = "mozvisibilitychange";
			}
			else if (typeof JS.global.document.msHidden !== "undefined")
			{
				HIDDEN = "msHidden";
				VISIBILITY_CHANGE = "msvisibilitychange";
			}
			else if (typeof JS.global.document.webkitHidden !== "undefined")
			{
				HIDDEN = "webkitHidden";
				VISIBILITY_CHANGE = "webkitvisibilitychange";
			}
			
			if (typeof JS.global.document.addEventListener !== "undefined" && typeof JS.global.document[HIDDEN] !== "undefined")
				JS.global.document.addEventListener(VISIBILITY_CHANGE, handleVisibilityChange, false);
		}
		
		private function handleVisibilityChange():void
		{
			if (JS.global.document[HIDDEN])
				deactivated = true;
			else
				deactivated = false;
			useDeactivatedFrameRate = false;
			
			if (debug_visibility)
				JS.log('visibility change; hidden =', deactivated);
		}
		
		/**
		 * This function gets called during ENTER_FRAME and RENDER events.
		 */
		private function _handleCallLater():void
		{
			// detect deactivated framerate (when app is hidden)
			if (deactivated)
			{
				var wasted:int = JS.now() - _currentFrameStartTime;
				if (debug_fps)
					JS.log('wasted', wasted);
				useDeactivatedFrameRate = wasted > 100;
			}
			
			var prevStartTime:int = _currentFrameStartTime;
			_currentFrameStartTime = JS.now();
			_previousFrameElapsedTime = _currentFrameStartTime - prevStartTime;
			
			// sanity check
			if (maxComputationTimePerFrame == 0)
				maxComputationTimePerFrame = 100;

			var maxComputationTime:uint;
			if (useDeactivatedFrameRate)
				maxComputationTime = _deactivatedMaxComputationTimePerFrame;
//			else if (!userActivity)
//				maxComputationTime = maxComputationTimePerFrame_noActivity;
			else
				maxComputationTime = maxComputationTimePerFrame;
			
			resetDebugTime();
			
			if (debug_fps)
			{
				frameTimes.push(previousFrameElapsedTime);
				if (StandardLib.sum(frameTimes) >= 1000)
				{
					averageFrameTime = StandardLib.mean(frameTimes);
					var fps:Number = StandardLib.roundSignificant(1000 / averageFrameTime, 2);
					JS.log(fps, 'fps; max computation time', maxComputationTime);
					frameTimes.length = 0;
				}
			}
			
			if (_previousFrameElapsedTime > 3000)
				JS.log('Previous frame took', _previousFrameElapsedTime, 'ms');
			
			// The variables countdown and lastPriority are used to avoid running newly-added tasks immediately.
			// This avoids wasting time on async tasks that do nothing and return early, adding themselves back to the queue.

			var args:Array;
			var context:Object;
			var args2:Array; // this is set to args[2]
			var stackTrace:String;
			var now:int;
			var allStop:int = _currentFrameStartTime + maxComputationTime;

			_currentTaskStopTime = allStop; // make sure _iterateTask knows when to stop

			// first run the functions that should be called before anything else.
			var queue:Array = _priorityCallLaterQueues[WeaveAPI.TASK_PRIORITY_IMMEDIATE] as Array;
			var countdown:int;
			for (countdown = queue.length; countdown > 0; countdown--)
			{
				if (debug_callLater)
					DebugTimer.begin();
				
				now = JS.now();
				// stop when max computation time is reached for this frame
				if (now > allStop)
				{
					if (debug_callLater)
						DebugTimer.cancel();
					return;
				}
				
				// args: (relevantContext:Object, method:Function, parameters:Array)
				args = queue.shift();
				stackTrace = map_task_stackTrace.get(args);
				
//				WeaveAPI.SessionManager.unassignBusyTask(args);
				
				// don't call the function if the relevantContext was disposed.
				context = args[0];
				if (!WeaveAPI.SessionManager.objectWasDisposed(context))
				{
					args2 = args[2] as Array;
					if (args2 != null && args2.length > 0)
						(args[1] as Function).apply(context, args2);
					else
						(args[1] as Function).apply(context);
				}
				
				if (debug_callLater)
					DebugTimer.end(stackTrace);
			}
			
//			JS.log('-------');
			
			var minPriority:int = WeaveAPI.TASK_PRIORITY_IMMEDIATE + 1;
			var lastPriority:int = _activePriority == minPriority ? _priorityCallLaterQueues.length - 1 : _activePriority - 1;
			var pStart:int = JS.now();
			var pAlloc:int = int(_priorityAllocatedTimes[_activePriority]);
			if (useDeactivatedFrameRate)
				pAlloc = pAlloc * _deactivatedMaxComputationTimePerFrame / maxComputationTimePerFrame;
//			else if (!userActivity)
//				pAlloc = pAlloc * maxComputationTimePerFrame_noActivity / maxComputationTimePerFrame;
			var pStop:int = Math.min(allStop, pStart + pAlloc - _activePriorityElapsedTime); // continue where we left off
			queue = _priorityCallLaterQueues[_activePriority] as Array;
			countdown = queue.length;
			while (true)
			{
				if (debug_callLater)
					DebugTimer.begin();
				
				now = JS.now();
				if (countdown == 0 || now > pStop)
				{
					// add the time we just spent on this priority
					_activePriorityElapsedTime += now - pStart;
					
					// if max computation time was reached for this frame or we have visited all priorities, stop now
					if (now > allStop || _activePriority == lastPriority)
					{
						if (debug_callLater)
							DebugTimer.cancel();
						if (debug_fps)
							JS.log('spent',currentFrameElapsedTime,'ms');
						return;
					}
					
					// see if there are any entries left in the queues (except for the immediate queue)
					var remaining:int = 0;
					for (var i:int = minPriority; i < _priorityCallLaterQueues.length; i++)
						remaining += (_priorityCallLaterQueues[i] as Array).length;
					// stop if no more entries
					if (remaining == 0)
					{
						if (debug_callLater)
							DebugTimer.cancel();
						break;
					}
					
					// switch to next priority, reset elapsed time
					_activePriority++;
					_activePriorityElapsedTime = 0;
					if (_activePriority == _priorityCallLaterQueues.length)
						_activePriority = minPriority;
					pStart = now;
					pAlloc = int(_priorityAllocatedTimes[_activePriority]);
					if (useDeactivatedFrameRate)
						pAlloc = pAlloc * _deactivatedMaxComputationTimePerFrame / maxComputationTimePerFrame;
//					else if (!userActivity)
//						pAlloc = pAlloc * maxComputationTimePerFrame_noActivity / maxComputationTimePerFrame;
					pStop = Math.min(allStop, pStart + pAlloc);
					queue = _priorityCallLaterQueues[_activePriority] as Array;
					countdown = queue.length;
					
					// restart loop to check stopping condition
					if (debug_callLater)
						DebugTimer.cancel();
					continue;
				}
				
				countdown--;
				
//				JS.log('p',_activePriority,pElapsed,'/',pAlloc);
				_currentTaskStopTime = pStop; // make sure _iterateTask knows when to stop
				
				// call the next function in the queue
				// args: (relevantContext:Object, method:Function, parameters:Array)
				args = queue.shift() as Array;
				stackTrace = map_task_stackTrace.get(args); // check this for debugging where the call came from
				
//				WeaveAPI.SessionManager.unassignBusyTask(args);
				
				// don't call the function if the relevantContext was disposed.
				context = args[0];
				if (!WeaveAPI.SessionManager.objectWasDisposed(context))
				{
					// TODO: PROFILING: check how long this function takes to execute.
					// if it takes a long time (> 1000 ms), something's wrong...
					args2 = args[2] as Array;
					if (args2 != null && args2.length > 0)
						(args[1] as Function).apply(context, args2);
					else
						(args[1] as Function).apply(context);
				}
				
				if (debug_callLater)
					DebugTimer.end(stackTrace);
			}
		}
		
		public function callLater(relevantContext:Object, method:Function, parameters:Array = null):void
		{
			_callLaterPriority(WeaveAPI.TASK_PRIORITY_IMMEDIATE, relevantContext, method, parameters);
		}
		
		private function _callLaterPriority(priority:uint, relevantContext:Object, method:Function, parameters:Array = null):void
		{
			if (method == null)
			{
				JS.error('StageUtils.callLater(): received null "method" parameter');
				return;
			}
			
//			WeaveAPI.SessionManager.assignBusyTask(arguments, relevantContext as ILinkableObject);
			
			//JS.log("call later @",currentFrameElapsedTime);
			var args:Array = [relevantContext, method, parameters];
			_priorityCallLaterQueues[priority].push(args);
			
			if (debug_async_stack)
				map_task_stackTrace.set(args, new Error("This is the stack trace from when callLater() was called."));
		}
		
		/**
		 * This will generate an iterative task function that is the combination of a list of tasks to be completed in order.
		 * @param iterativeTasks An Array of iterative task functions.
		 * @return A single iterative task function that invokes the other tasks to completion in order.
		 *         The function will accept a stopTime:int parameter which when set to -1 will
		 *         reset the task counter to zero so the compound task will start from the first task again.
		 * @see #startTask()
		 */
		public static function generateCompoundIterativeTask(...iterativeTasks):Function
		{
			var iTask:int = 0;
			return function(stopTime:int):Number
			{
				if (stopTime < 0) // restart
				{
					iTask = 0;
					return 0;
				}
				if (iTask >= iterativeTasks.length)
					return 1;
				
				var i:int = iTask; // need to detect if iTask changes
				var iterate:Function = iterativeTasks[iTask] as Function;
				var progress:Number;
				if (iterate.length)
				{
					progress = iterate.call(this, stopTime);
				}
				else
				{
					while (iTask == i && (progress = iterate.call(this)) < 1 && JS.now() < stopTime) { }
				}
				// if iTask changed as a result of iterating, we need to restart
				if (iTask != i)
					return 0;
				
				var totalProgress:Number = (iTask + progress) / iterativeTasks.length;
				if (progress == 1)
					iTask++;
				return totalProgress;
			}
		}
		
		private var map_task_time:Object = new JS.WeakMap();
		
		public function startTask(relevantContext:Object, iterativeTask:Function, priority:uint, finalCallback:Function = null, description:String = null):void
		{
			// do nothing if task already active
			if (WeaveAPI.ProgressIndicator.hasTask(iterativeTask))
				return;
			
			if (debug_async_time)
			{
				if (map_task_time.get(iterativeTask))
				{
					var value:Array = map_task_time.get(iterativeTask);
					map_task_time['delete'](iterativeTask);
					JS.log('interrupted', JS.now()-map_task_time.get(iterativeTask)[0], priority, map_task_time.get(iterativeTask)[1], value);
				}
				map_task_time.set(iterativeTask, [JS.now(), new Error('Stack trace')]);
			}
			
			if (priority >= _priorityCallLaterQueues.length)
			{
				JS.error("Invalid priority value: " + priority);
				priority = WeaveAPI.TASK_PRIORITY_NORMAL;
			}
			
			if (debug_async_stack)
			{
				map_task_stackTrace.set(iterativeTask, [DebugUtils.debugId(iterativeTask), new Error("Stack trace")]);
				map_task_startTime.set(iterativeTask, JS.now());
				map_task_elapsedTime.set(iterativeTask, 0);
			}
			WeaveAPI.ProgressIndicator.addTask(iterativeTask, relevantContext as ILinkableObject, description);
			
			var useTimeParameter:Boolean = iterativeTask.length > 0;
			
			// Set relevantContext as null for callLater because we always want _iterateTask to be called later.
			// This makes sure that the task is removed when the actual context is disposed.
			_callLaterPriority(priority, null, _iterateTask, [relevantContext, iterativeTask, priority, finalCallback, useTimeParameter]);
			//_iterateTask(relevantContext, iterativeTask, priority, finalCallback);
		}
		
		/**
		 * @private
		 */
		private function _iterateTask(context:Object, task:Function, priority:int, finalCallback:Function, useTimeParameter:Boolean):void
		{
			// remove the task if the context was disposed
			if (WeaveAPI.SessionManager.objectWasDisposed(context))
			{
				if (debug_async_time && map_task_time.get(task))
				{
					var value:Array = map_task_time.get(task)
					map_task_time['delete'](task);
					JS.log('disposed', JS.now()-map_task_time.get(task)[0], priority, map_task_time.get(task)[1], value);
				}
				WeaveAPI.ProgressIndicator.removeTask(task);
				return;
			}

			var debug_time:int = debug_async_stack ? JS.now() : -1;
			var stackTrace:String = debug_async_stack ? map_task_stackTrace.get(task) : null;
			
			var progress:* = undefined;
			// iterate on the task until _currentTaskStopTime is reached
			var time:int;
			while ((time = JS.now()) <= _currentTaskStopTime)
			{
				// perform the next iteration of the task
				if (useTimeParameter)
					progress = task(_currentTaskStopTime) as Number;
				else
					progress = task() as Number;
				
				if (progress === null || isNaN(progress) || progress < 0 || progress > 1)
				{
					JS.error("Received unexpected result from iterative task (" + progress + ").  Expecting a number between 0 and 1.  Task cancelled.");
					if (debug_async_stack)
					{
						JS.log(stackTrace);
						// this is incorrect behavior, but we can put a breakpoint here
						if (useTimeParameter)
							progress = task(_currentTaskStopTime) as Number;
						else
							progress = task() as Number;
					}
					progress = 1;
				}
				if (debug_async_stack && currentFrameElapsedTime > 3000)
				{
					JS.log(JS.now() - time, stackTrace);
					// this is incorrect behavior, but we can put a breakpoint here
					if (useTimeParameter)
						progress = task(_currentTaskStopTime) as Number;
					else
						progress = task() as Number;
				}
				if (progress == 1)
				{
					if (debug_async_time && map_task_time.get(task))
					{
						var value2:Array = map_task_time.get(task);
						map_task_time['delete'](task);
						JS.log('completed', JS.now()-map_task_time.get(task)[0], priority, map_task_time.get(task)[1], value2);
					}
					// task is done, so remove the task
					WeaveAPI.ProgressIndicator.removeTask(task);
					// run final callback after task completes and is removed
					if (finalCallback != null)
						finalCallback();
					return;
				}
				
				// If the time parameter is accepted, only call the task once in succession.
				if (useTimeParameter)
					break;
				
				if (debug_delayTasks)
					break;
			}
			if (debug_async_stack && debug_async_stack_elapsed)
			{
				var start:int = int(map_task_startTime.get(task));
				var elapsed:int = int(map_task_elapsedTime.get(task)) + (time - debug_time);
				map_task_elapsedTime.set(task, elapsed);
				JS.log(elapsed,'/',(time-start),'=',StandardLib.roundSignificant(elapsed / (time - start), 2),stackTrace);
			}
			
			// max computation time reached without finishing the task, so update the progress indicator and continue the task later
			if (progress !== undefined)
				WeaveAPI.ProgressIndicator.updateTask(task, progress);
			
			// Set relevantContext as null for callLater because we always want _iterateTask to be called later.
			// This makes sure that the task is removed when the actual context is disposed.
			_callLaterPriority(priority, null, _iterateTask, JS.toArray(arguments));
		}
	}
}
