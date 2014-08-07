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
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import mx.core.UIComponentGlobals;
	import mx.core.mx_internal;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.core.IStageUtils;
	import weave.api.reportError;
	import weave.compiler.StandardLib;
	import weave.utils.DebugTimer;
	import weave.utils.DebugUtils;
	
	use namespace mx_internal;
	
	/**
	 * This allows you to add callbacks that will be called when an event occurs on the stage.
	 * 
	 * WARNING: These callbacks will trigger on every mouse and keyboard event that occurs on the stage.
	 *          Developers should not add any callbacks that run computationally expensive code.
	 * 
	 * @author adufilie
	 */
	public class StageUtils implements IStageUtils
	{
		public function StageUtils()
		{
			eventManager.throttledMouseMoveInterval = maxComputationTimePerFrame;
			addEventCallback(Event.ENTER_FRAME, null, handleCallLater);
			addEventCallback(Event.RENDER, null, handleCallLater);
		}
		
		private const eventManager:EventManager = new EventManager();
		
		public static function get debug_fps():Boolean { return EventCallbackCollection.debug_fps; }
		public static function set debug_fps(value:Boolean):void { EventCallbackCollection.debug_fps = value; }
		public static var debug_async_stack:Boolean = false;
		public static var debug_delayTasks:Boolean = false; // set this to true to delay async tasks
		public static var debug_callLater:Boolean = false; // set this to true to delay async tasks
		public var averageFrameTime:int = 0;
		
		private const frameTimes:Array = [];
		private const _stackTraceMap:Dictionary = new Dictionary(true); // used by callLater to remember stack traces
		private const _taskElapsedTime:Dictionary = new Dictionary(true);
		private const _taskStartTime:Dictionary = new Dictionary(true);
		private var _currentTaskStopTime:int = 0; // set on enterFrame, used by _iterateTask
		
		/**
		 * This is a special pseudo-event type supported by StageUtils.
		 * Callbacks added to this event will only trigger when the mouse was clicked and released at the same screen location.
		 */
		public static function get POINT_CLICK_EVENT():String { return EventCallbackCollection.POINT_CLICK_EVENT; }
		
		/**
		 * This is a special pseudo-event type supported by StageUtils.
		 * Callbacks added to this event will only trigger when the mouse was clicked and released at the same screen location.
		 */
		public static function get THROTTLED_MOUSE_MOVE_EVENT():String { return EventCallbackCollection.THROTTLED_MOUSE_MOVE_EVENT; }
		
		/**
		 * This is an Array of "callLater queues", each being an Array of function invocations to be done later.
		 * The Arrays get populated by callLater().
		 * There are four nested Arrays corresponding to the four priorities (0, 1, 2, 3) defined by static constants in WeaveAPI.
		 */
		private const _priorityCallLaterQueues:Array = [[], [], [], []];
		private var _activePriority:uint = WeaveAPI.TASK_PRIORITY_0_IMMEDIATE + 1; // task priority that is currently being processed
		private var _activePriorityElapsedTime:uint = 0; // elapsed time for active task priority
		private const _priorityAllocatedTimes:Array = [int.MAX_VALUE, 300, 200, 100]; // An Array of allocated times corresponding to callLater queues.
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
			eventManager.throttledMouseMoveInterval = value;
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
		[Bindable] public var maxComputationTimePerFrame:uint = 100;
		
		/**
		 * @inheritDoc
		 */
		public function get stage():Stage
		{
			return eventManager.stage;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get keyboardEvent():KeyboardEvent
		{
			return eventManager.event as KeyboardEvent;
		}
		/**
		 * @inheritDoc
		 */
		public function get mouseEvent():MouseEvent
		{
			return eventManager.event as MouseEvent;
		}
		/**
		 * @inheritDoc
		 */
		public function get event():Event
		{
			return eventManager.event as Event;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get eventTime():int
		{
			return eventManager.eventTime;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get shiftKey():Boolean
		{
			return eventManager.shiftKey;
		}
		/**
		 * @inheritDoc
		 */
		public function get altKey():Boolean
		{
			return eventManager.altKey;
		}
		/**
		 * @inheritDoc
		 */
		public function get ctrlKey():Boolean
		{
			return eventManager.ctrlKey;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get mouseButtonDown():Boolean
		{
			return eventManager.mouseButtonDown;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get pointClicked():Boolean
		{
			return eventManager.pointClicked;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get previousFrameElapsedTime():int
		{
			return eventManager.previousFrameElapsedTime;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get currentFrameElapsedTime():int
		{
			return getTimer() - eventManager.currentFrameStartTime;
		}
		
		private static var _time:int;
		private static var _times:Array = [];
		public static function debugTime(str:String):int
		{
			var now:int = getTimer();
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
			_time = getTimer();
		}
		
		/**
		 * This function gets called during ENTER_FRAME and RENDER events.
		 */
		private function handleCallLater():void
		{
			// sanity check
			if (maxComputationTimePerFrame == 0)
				maxComputationTimePerFrame = 100;

			var maxComputationTime:uint = eventManager.useDeactivatedFrameRate ? _deactivatedMaxComputationTimePerFrame : maxComputationTimePerFrame;
			if (!eventManager.event)
			{
				reportError("StageUtils.handleCallLater(): _event is null. This should never happen.");
				return;
			}
			if (eventManager.event.type == Event.ENTER_FRAME)
			{
				resetDebugTime();
				
				if (debug_fps)
				{
					frameTimes.push(previousFrameElapsedTime);
					if (StandardLib.sum(frameTimes) >= 1000)
					{
						averageFrameTime = StandardLib.mean(frameTimes);
						var fps:Number = StandardLib.roundSignificant(1000 / averageFrameTime, 2);
						trace(fps,'fps; max computation time',maxComputationTime);
						frameTimes.length = 0;
					}
				}
				
				if (eventManager.previousFrameElapsedTime > 3000)
					trace('Previous frame took', eventManager.previousFrameElapsedTime, 'ms');
			}
			
			if (UIComponentGlobals.callLaterSuspendCount > 0)
				return;

			// The variables countdown and lastPriority are used to avoid running newly-added tasks immediately.
			// This avoids wasting time on async tasks that do nothing and return early, adding themselves back to the queue.

			var args:Array;
			var args2:Array; // this is set to args[2]
			var stackTrace:String;
			var now:int;
			var allStop:int = eventManager.currentFrameStartTime + maxComputationTime;

			_currentTaskStopTime = allStop; // make sure _iterateTask knows when to stop

			// first run the functions that should be called before anything else.
			var queue:Array = _priorityCallLaterQueues[WeaveAPI.TASK_PRIORITY_0_IMMEDIATE] as Array;
			var countdown:int;
			for (countdown = queue.length; countdown > 0; countdown--)
			{
				if (debug_callLater)
					DebugTimer.begin();
				
				now = getTimer();
				// stop when max computation time is reached for this frame
				if (now > allStop)
					return;
				
				// args: (relevantContext:Object, method:Function, parameters:Array, priority:uint)
				args = queue.shift();
				stackTrace = _stackTraceMap[args];
				
//				WeaveAPI.SessionManager.unassignBusyTask(args);
				
				// don't call the function if the relevantContext was disposed.
				if (!WeaveAPI.SessionManager.objectWasDisposed(args[0]))
				{
					args2 = args[2] as Array;
					if (args2 != null && args2.length > 0)
						(args[1] as Function).apply(null, args2);
					else
						(args[1] as Function)();
				}
				
				if (debug_callLater)
					DebugTimer.end(stackTrace);
			}
			
//			trace('-------');
			
			var minPriority:int = WeaveAPI.TASK_PRIORITY_0_IMMEDIATE + 1;
			var lastPriority:int = _activePriority == minPriority ? _priorityCallLaterQueues.length - 1 : _activePriority - 1;
			var pStart:int = getTimer();
			var pAlloc:int = int(_priorityAllocatedTimes[_activePriority]);
			if (eventManager.useDeactivatedFrameRate)
				pAlloc = pAlloc * _deactivatedMaxComputationTimePerFrame / maxComputationTimePerFrame;
			var pStop:int = Math.min(allStop, pStart + pAlloc - _activePriorityElapsedTime); // continue where we left off
			queue = _priorityCallLaterQueues[_activePriority] as Array;
			countdown = queue.length;
			while (true)
			{
				if (debug_callLater)
					DebugTimer.begin();
				
				now = getTimer();
				if (countdown == 0 || now > pStop)
				{
					// add the time we just spent on this priority
					_activePriorityElapsedTime += now - pStart;
					
					// if max computation time was reached for this frame or we have visited all priorities, stop now
					if (now > allStop || _activePriority == lastPriority)
					{
						if (debug_fps)
							trace('spent',currentFrameElapsedTime,'ms');
						return;
					}
					
					// see if there are any entries left in the queues (except for the immediate queue)
					var remaining:int = 0;
					for (var i:int = minPriority; i < _priorityCallLaterQueues.length; i++)
						remaining += (_priorityCallLaterQueues[i] as Array).length;
					// stop if no more entries
					if (remaining == 0)
						break;
					
					// switch to next priority, reset elapsed time
					_activePriority++;
					_activePriorityElapsedTime = 0;
					if (_activePriority == _priorityCallLaterQueues.length)
						_activePriority = minPriority;
					pStart = now;
					pAlloc = int(_priorityAllocatedTimes[_activePriority]);
					if (eventManager.useDeactivatedFrameRate)
						pAlloc = pAlloc * _deactivatedMaxComputationTimePerFrame / maxComputationTimePerFrame;
					pStop = Math.min(allStop, pStart + pAlloc);
					queue = _priorityCallLaterQueues[_activePriority] as Array;
					countdown = queue.length;
					
					// restart loop to check stopping condition
					continue;
				}
				
				countdown--;
				
//				trace('p',_activePriority,pElapsed,'/',pAlloc);
				_currentTaskStopTime = pStop; // make sure _iterateTask knows when to stop
				
				// call the next function in the queue
				// args: (relevantContext:Object, method:Function, parameters:Array, priority:uint)
				args = queue.shift() as Array;
				stackTrace = _stackTraceMap[args]; // check this for debugging where the call came from
				
//				WeaveAPI.SessionManager.unassignBusyTask(args);
				
				// don't call the function if the relevantContext was disposed.
				if (!WeaveAPI.SessionManager.objectWasDisposed(args[0]))
				{
					// TODO: PROFILING: check how long this function takes to execute.
					// if it takes a long time (> 1000 ms), something's wrong...
					args2 = args[2] as Array;
					if (args2 != null && args2.length > 0)
						(args[1] as Function).apply(null, args2);
					else
						(args[1] as Function)();
				}
				
				if (debug_callLater)
					DebugTimer.end(stackTrace);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function callLater(relevantContext:Object, method:Function, parameters:Array = null, priority:uint = 2):void
		{
			if (method == null)
			{
				reportError('StageUtils.callLater(): received null "method" parameter');
				return;
			}
			
//			WeaveAPI.SessionManager.assignBusyTask(arguments, relevantContext as ILinkableObject);
			
			if (priority >= _priorityCallLaterQueues.length)
			{
				reportError("Invalid priority value: " + priority);
				priority = WeaveAPI.TASK_PRIORITY_2_BUILDING;
			}
			//trace("call later @",currentFrameElapsedTime);
			_priorityCallLaterQueues[priority].push(arguments);
			
			if (debug_async_stack)
				_stackTraceMap[arguments] = new Error("This is the stack trace from when callLater() was called.").getStackTrace();
		}
		
		/**
		 * This will generate an iterative task function that is the combination of a list of tasks to be completed in order.
		 * @param iterativeTasks An Array of iterative task functions.
		 * @return A single iterative task function that invokes the other tasks to completion in order.
		 *         The function will accept a stopTime:int parameter which when set to -1 will
		 *         reset the task counter to zero so the compound task will start from the first task again.
		 * @see #startTask
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
				
				var iterate:Function = iterativeTasks[iTask] as Function;
				var progress:Number;
				if (iterate.length)
				{
					progress = iterate(stopTime);
				}
				else
				{
					while ((progress = iterate()) < 1 && getTimer() < stopTime) { }
				}
				var totalProgress:Number = (iTask + progress) / iterativeTasks.length;
				if (progress == 1)
					iTask++;
				return totalProgress;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function startTask(relevantContext:Object, iterativeTask:Function, priority:uint, finalCallback:Function = null):void
		{
			// do nothing if task already active
			if (WeaveAPI.ProgressIndicator.hasTask(iterativeTask))
				return;
			
			if (priority >= _priorityCallLaterQueues.length)
			{
				reportError("Invalid priority value: " + priority);
				priority = WeaveAPI.TASK_PRIORITY_2_BUILDING;
			}
			
			if (debug_async_stack)
			{
				_stackTraceMap[iterativeTask] = debugId(iterativeTask) + ' ' + DebugUtils.getCompactStackTrace(new Error("Stack trace"));
				_taskStartTime[iterativeTask] = getTimer();
				_taskElapsedTime[iterativeTask] = 0;
			}
			WeaveAPI.ProgressIndicator.addTask(iterativeTask, relevantContext as ILinkableObject);
			
			var useTimeParameter:Boolean = iterativeTask.length > 0;
			
			// Set relevantContext as null for callLater because we always want _iterateTask to be called later.
			// This makes sure that the task is removed when the actual context is disposed.
			callLater(null, _iterateTask, [relevantContext, iterativeTask, priority, finalCallback, useTimeParameter], priority);
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
				WeaveAPI.ProgressIndicator.removeTask(task);
				return;
			}

			var debug_time:int = debug_async_stack ? getTimer() : -1;
			var stackTrace:String = debug_async_stack ? _stackTraceMap[task] : null;
			
			var progress:* = undefined;
			// iterate on the task until _currentTaskStopTime is reached
			var time:int;
			while ((time = getTimer()) <= _currentTaskStopTime)
			{
				// perform the next iteration of the task
				if (useTimeParameter)
					progress = task(_currentTaskStopTime) as Number;
				else
					progress = task() as Number;
				
				if (progress === null || isNaN(progress) || progress < 0 || progress > 1)
				{
					reportError("Received unexpected result from iterative task (" + progress + ").  Expecting a number between 0 and 1.  Task cancelled.");
					if (debug_async_stack)
					{
						trace(stackTrace);
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
					trace(getTimer() - time, stackTrace);
					// this is incorrect behavior, but we can put a breakpoint here
					if (useTimeParameter)
						progress = task(_currentTaskStopTime) as Number;
					else
						progress = task() as Number;
				}
				if (progress == 1)
				{
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
			if (false && debug_async_stack)
			{
				var start:int = int(_taskStartTime[task]);
				var elapsed:int = int(_taskElapsedTime[task]) + (time - debug_time);
				_taskElapsedTime[task] = elapsed;
				trace(elapsed,'/',(time-start),'=',StandardLib.roundSignificant(elapsed / (time - start), 2),stackTrace);
			}
			
			// max computation time reached without finishing the task, so update the progress indicator and continue the task later
			if (progress !== undefined)
				WeaveAPI.ProgressIndicator.updateTask(task, progress);
			
			// Set relevantContext as null for callLater because we always want _iterateTask to be called later.
			// This makes sure that the task is removed when the actual context is disposed.
			callLater(null, _iterateTask, arguments, priority);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getSupportedEventTypes():Array
		{
			return EventCallbackCollection.eventTypes.concat();
		}
		
		/**
		 * @inheritDoc
		 */
		public function addEventCallback(eventType:String, relevantContext:Object, callback:Function, runCallbackNow:Boolean = false):void
		{
			var cc:ICallbackCollection = eventManager.callbackCollections[eventType] as ICallbackCollection;
			if (cc != null)
			{
				cc.addImmediateCallback(relevantContext, callback, runCallbackNow);
			}
			else
			{
				reportError("(StageUtils) Unsupported event: "+eventType);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeEventCallback(eventType:String, callback:Function):void
		{
			var cc:ICallbackCollection = eventManager.callbackCollections[eventType] as ICallbackCollection;
			if (cc != null)
				cc.removeCallback(callback);
		}
	}
}

import flash.display.Stage;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Point;
import flash.utils.getTimer;
import flash.utils.setTimeout;

import weave.core.CallbackCollection;

/**
 * Manages a set of EventCallbackCollections.
 * @see #callbackCollections
 */
internal class EventManager
{
	public function EventManager()
	{
		// create a new callback collection for each type of event
		for each (var type:String in EventCallbackCollection.eventTypes)
			callbackCollections[type] = WeaveAPI.SessionManager.registerDisposableChild(WeaveAPI.globalHashMap, new EventCallbackCollection(this, type));
		
		waitForStage();
	}

	private function waitForStage(event:TimerEvent = null):void
	{
		if (!WeaveAPI.topLevelApplication || !WeaveAPI.topLevelApplication.stage)
		{
			// try again later
			setTimeout(waitForStage, 0);
			return;
		}
		
		// ready to add event listeners
		stage = WeaveAPI.topLevelApplication.stage;
		for (var type:String in callbackCollections)
			(callbackCollections[type] as EventCallbackCollection).listenToStage(stage);
	}
	
	/**
	 * This is a mapping from event type to corresponding EventCallbackCollection.
	 */
	public const callbackCollections:Object = {};
	
	public var stage:Stage;
	public var event:Event = null; // the current event
	public var eventTime:int = 0;
	public var shiftKey:Boolean = false;
	public var altKey:Boolean = false;
	public var ctrlKey:Boolean = false;
	public var mouseButtonDown:Boolean = false;
	public var currentFrameStartTime:int = getTimer(); // this is the result of getTimer() on the last ENTER_FRAME event.
	public var previousFrameElapsedTime:int = 0; // this is the amount of time it took to process the previous frame.
	public var pointClicked:Boolean = false;
	
	public var deactivated:Boolean = true; // true when application is deactivated
	public var useDeactivatedFrameRate:Boolean = false; // true when deactivated and framerate drop detected
	
	public const lastMouseDownPoint:Point = new Point(NaN, NaN); // stage coords of last mouseDown event
	public const lastThrottledMousePoint:Point = new Point(NaN, NaN); // stage coords of mouse for last throttled mouseMove event
	public var triggeredThrottledMouseThisFrame:Boolean = false; // set to false on enterFrame, set to true on throttled mouse move
	public var nextThrottledMouseMoveTime:int = 0; // time threshold before triggering throttled mouse move again
	public var throttledMouseMoveInterval:int = 100; // time threshold before triggering throttled mouse move again
}

/**
 * Helper class for event callbacks.
 * @see #listenToStage()
 */
internal class EventCallbackCollection extends CallbackCollection
{
	public static var debug_fps:Boolean = false;
	
	/**
	 * This is a special pseudo-event type.
	 * Callbacks added to this event will only trigger when the mouse was clicked and released at the same screen location.
	 */
	public static const POINT_CLICK_EVENT:String = "pointClick";
	
	/**
	 * This is a special pseudo-event type.
	 * Callbacks added to this event will only trigger when the mouse was clicked and released at the same screen location.
	 */
	public static const THROTTLED_MOUSE_MOVE_EVENT:String = "throttledMouseMove";
	
	/**
	 * This is a list of supported event types.
	 */
	public static const eventTypes:Array = [
		POINT_CLICK_EVENT, THROTTLED_MOUSE_MOVE_EVENT,
		MouseEvent.CLICK, MouseEvent.DOUBLE_CLICK,
		MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_MOVE,
		MouseEvent.MOUSE_OUT, MouseEvent.MOUSE_OVER,
		MouseEvent.MOUSE_UP, MouseEvent.MOUSE_WHEEL,
		MouseEvent.ROLL_OUT, MouseEvent.ROLL_OVER,
		Event.ACTIVATE, Event.DEACTIVATE,
		KeyboardEvent.KEY_DOWN, KeyboardEvent.KEY_UP,
		Event.ENTER_FRAME, Event.FRAME_CONSTRUCTED, Event.EXIT_FRAME, Event.RENDER
	];
	
	/**
	 * @param eventManager The EventManager instance to use as a variable buffer.
	 * @param eventType The event type corresponding to this callback collection.
	 */
	public function EventCallbackCollection(eventManager:EventManager, eventType:String)
	{
		super(setEvent);
		
		this.eventManager = eventManager;
		this.eventType = eventType;
	}

	private var eventManager:EventManager;
	private var eventType:String;
	
	/**
	 * This is the _preCallback
	 */
	private function setEvent(event:Event):void
	{
		eventManager.event = event;
	}
	
	/**
	 * This function remembers the previous event value, runs callbacks using the new event value,
	 * then restores the previous event value. This is necessary because it is possible for a popup
	 * browser window to interrupt Flash with requests in the middle of an event.
	 */
	private function runEventCallbacks(event:Event):void
	{
		var previousEvent:Event = eventManager.event; // remember previous value
		_runCallbacksImmediately(event); // make sure event is set before each immediate callback
		_preCallback(previousEvent); // restore the previous value
	}
	
	/**
	 * Call this when the stage is available to set up event listeners.
	 */
	public function listenToStage(stage:Stage):void
	{
		// do not create event listeners for these meta events
		if (eventType == POINT_CLICK_EVENT || eventType == THROTTLED_MOUSE_MOVE_EVENT)
			return;

		// Add a listener to the capture phase so the callbacks will run before the target gets the event.
		stage.addEventListener(eventType, captureListener, true, 0, true); // use capture phase
		
		// If the target is the stage, the capture listener won't be called, so add
		// an additional listener that runs callbacks when the stage is the target.
		stage.addEventListener(eventType, stageListener, false, 0, true); // do not use capture phase
		
		// when callbacks are disposed, remove the listeners
		addDisposeCallback(null, function():void {
			stage.removeEventListener(eventType, captureListener, true);
			stage.removeEventListener(eventType, stageListener, false);
		});
	}
	
	private function stageListener(event:Event):void
	{
		if (event.target == eventManager.stage)
			captureListener(event);
	};
	
	/**
	 * This function is responsible for setting all event-related variables and determining when to trigger meta events.
	 */
	private function captureListener(event:Event):void
	{
		// avoid handling redundant events generated by SystemManager
		if (event.cancelable)
			return;
		
		// detect deactivated framerate (when app is hidden)
		if (eventManager.deactivated && eventType == Event.ENTER_FRAME)
		{
			var wasted:int = getTimer() - eventManager.eventTime;
			if (debug_fps)
				trace('wasted', wasted);
			eventManager.useDeactivatedFrameRate = wasted > 100;
		}
		
		// set event variables
		if (eventManager.event != null)
		{
			trace(eventManager.event.type, 'was interrupted by', event.type);
		}
		eventManager.eventTime = getTimer();
		
		var stageX:Number = eventManager.stage.mouseX;
		var stageY:Number = eventManager.stage.mouseY;
		
		if (eventType == Event.ENTER_FRAME)
		{
			eventManager.previousFrameElapsedTime = eventManager.eventTime - eventManager.currentFrameStartTime;
			eventManager.currentFrameStartTime = eventManager.eventTime;
			eventManager.triggeredThrottledMouseThisFrame = false;
		}
		else if (eventType == Event.ACTIVATE || eventType == Event.DEACTIVATE)
		{
			if (debug_fps)
				trace(eventType);
			eventManager.deactivated = eventType == Event.DEACTIVATE;
			eventManager.useDeactivatedFrameRate = false;
		}
		
		var keyboardEvent:KeyboardEvent = event as KeyboardEvent;
		if (keyboardEvent)
		{
			eventManager.altKey = keyboardEvent.altKey;
			eventManager.shiftKey = keyboardEvent.shiftKey;
			eventManager.ctrlKey = keyboardEvent.ctrlKey;
		}
		
		var handleThrottledMouseMove:Boolean = false;
		var mouseEvent:MouseEvent = event as MouseEvent;
		if (mouseEvent)
		{
			// Ignore this event if stageX is undefined.
			// It seems that whenever we get a mouse event with undefined coordinates,
			// we always get a duplicate event right after that defines the coordinates.
			// The ctrlKey,altKey,shiftKey properties always seem to be false when the coordinates are NaN.
			if (isNaN(mouseEvent.stageX))
				return; // do nothing when coords are undefined
			
			eventManager.altKey = mouseEvent.altKey;
			eventManager.shiftKey = mouseEvent.shiftKey;
			eventManager.ctrlKey = mouseEvent.ctrlKey;
			eventManager.mouseButtonDown = mouseEvent.buttonDown;
			
			if (eventType == MouseEvent.MOUSE_DOWN)
			{
				// remember the mouse down point for handling POINT_CLICK_EVENT callbacks.
				eventManager.lastMouseDownPoint.x = mouseEvent.stageX;
				eventManager.lastMouseDownPoint.y = mouseEvent.stageY;
			}
			if (eventType == MouseEvent.CLICK || eventType == MouseEvent.MOUSE_UP)
				eventManager.pointClicked = mouseEvent.stageX == eventManager.lastMouseDownPoint.x && mouseEvent.stageY == eventManager.lastMouseDownPoint.y;
			
			// Always handle throttled mouse move prior to a non-move mouse event so throttled
			// mouse callbacks know about the movement before the other mouse event callbacks.
			// Also, handle throttled mouse move on a move event if at least one frame and enough
			// time has passed since the previous throttled mouse move.
			if (eventType != MouseEvent.MOUSE_MOVE || (!eventManager.triggeredThrottledMouseThisFrame && eventManager.eventTime >= eventManager.nextThrottledMouseMoveTime))
				handleThrottledMouseMove = true;
		}
		else // not a mouse event
		{
			// Handle throttled mouse move on a non-mouse event if at least one frame and enough
			// time has passed since the previous throttled mouse move.
			if (!eventManager.triggeredThrottledMouseThisFrame && eventManager.eventTime >= eventManager.nextThrottledMouseMoveTime)
				handleThrottledMouseMove = true;
		}
		
		// handle mouse move events before triggering throttled mouse move callbacks
		if (eventType == MouseEvent.MOUSE_MOVE)
			runEventCallbacks(event);
		
		// Handle throttled mouse move after regular mouse move, before other non-move mouse events.
		// Don't trigger throttled mouse move callbacks if the mouse hasn't moved.
		if (handleThrottledMouseMove && (stageX != eventManager.lastThrottledMousePoint.x || stageY != eventManager.lastThrottledMousePoint.y))
		{
			eventManager.triggeredThrottledMouseThisFrame = true;
			(eventManager.callbackCollections[THROTTLED_MOUSE_MOVE_EVENT] as EventCallbackCollection).runEventCallbacks(event);
			eventManager.lastThrottledMousePoint.x = stageX;
			eventManager.lastThrottledMousePoint.y = stageY;
			eventManager.nextThrottledMouseMoveTime = eventManager.eventTime + eventManager.throttledMouseMoveInterval;
		}
		
		// handle point click meta event
		if (eventType == MouseEvent.CLICK && eventManager.pointClicked)
			(eventManager.callbackCollections[POINT_CLICK_EVENT] as EventCallbackCollection).runEventCallbacks(event);
		
		// finally, trigger callbacks for non-mouse-move events
		if (eventType != MouseEvent.MOUSE_MOVE)
			runEventCallbacks(event);
	};
}
