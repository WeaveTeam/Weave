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
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import mx.core.UIComponentGlobals;
	import mx.core.mx_internal;
	
	import weave.api.WeaveAPI;
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
			initialize();
		}
		
		private const frameTimes:Array = [];
		public var debug_async_stack:Boolean = false;
		public var debug_fps:Boolean = false; // set to true to trace the frames per second
		public var aft:int = 0;
		public var debug_delayTasks:Boolean = false; // set this to true to delay async tasks
		public var debug_callLater:Boolean = false; // set this to true to delay async tasks
		private const _stackTraceMap:Dictionary = new Dictionary(true); // used by callLater to remember stack traces
		private const _taskElapsedTime:Dictionary = new Dictionary(true);
		private const _taskStartTime:Dictionary = new Dictionary(true);
		
		private var _event:Event = null; // returned by get event()
		private var _shiftKey:Boolean = false; // returned by get shiftKey()
		private var _altKey:Boolean = false; // returned by get altKey()
		private var _ctrlKey:Boolean = false; // returned by get ctrlKey()
		private var _mouseButtonDown:Boolean = false; // returned by get mouseButtonDown()
		private var _currentFrameStartTime:int = getTimer(); // this is the result of getTimer() on the last ENTER_FRAME event.
		private var _previousFrameElapsedTime:int = 0; // this is the amount of time it took to process the previous frame.
		private var _currentTaskStopTime:int = 0; // set by used by handleEnterFrame, used by _iterateTask
		private var _pointClicked:Boolean = false;

		private var _callbackCollectionsInitialized:Boolean = false; // This is true after the callback collections have been created.
		private var _listenersInitialized:Boolean = false; // This is true after the mouse listeners have been added.
		private const _initializeTimer:Timer = new Timer(0, 1); // only used if initialize() is attempted before stage is accessible
		private const _callbackCollections:Object = {}; // mapping from event type to the ICallbackCollection associated with it
		private var _stage:Stage = null; // pointer to the Stage, null until initialize() succeeds
		private const _lastMousePoint:Point = new Point(NaN, NaN); // stage coords of mouse for current frame
		private const _lastMouseDownPoint:Point = new Point(NaN, NaN); // stage coords of last mouseDown event
		
		/**
		 * This Array is used to keep strong references to the generated listeners so that they can be added with weak references.
		 * The weak references only matter when this code is loaded as a sub-application and later unloaded.
		 */		
		private const _generatedListeners:Array = [];
		
		/**
		 * This is a list of supported event types.
		 */
		private const _eventTypes:Array = [ 
			POINT_CLICK_EVENT,
			Event.ACTIVATE, Event.DEACTIVATE,
			MouseEvent.CLICK, MouseEvent.DOUBLE_CLICK,
			MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_MOVE,
			MouseEvent.MOUSE_OUT, MouseEvent.MOUSE_OVER,
			MouseEvent.MOUSE_UP, MouseEvent.MOUSE_WHEEL,
			MouseEvent.ROLL_OUT, MouseEvent.ROLL_OVER,
			KeyboardEvent.KEY_DOWN, KeyboardEvent.KEY_UP,
			Event.ENTER_FRAME, Event.FRAME_CONSTRUCTED, Event.EXIT_FRAME, Event.RENDER
		];
		
		/**
		 * This is a special pseudo-event supported by StageUtils.
		 * Callbacks added to this event will only trigger when the mouse was clicked and released at the same screen location.
		 */
		public static const POINT_CLICK_EVENT:String = "pointClick";
		
		/**
		 * This is an Array of "callLater queues", each being an Array of function invocations to be done later.
		 * The Arrays get populated by callLater().
		 * There are four nested Arrays corresponding to the four priorities (0, 1, 2, 3) defined by static constants in WeaveAPI.
		 */
		private const _priorityCallLaterQueues:Array = [[], [], [], []];
		private var _activePriority:uint = WeaveAPI.TASK_PRIORITY_IMMEDIATE + 1; // task priority that is currently being processed
		private const _priorityElapsedTimes:Array = [0, 0, 0, 0]; // An Array of elapsed times corresponding to callLater queues.
		private const _priorityAllocatedTimes:Array = [int.MAX_VALUE, 100, 65, 35]; // An Array of allocated times corresponding to callLater queues.

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
		[Bindable] public var maxComputationTimePerFrame:uint = 100;
		
		/**
		 * @inheritDoc
		 */
		public function get keyboardEvent():KeyboardEvent
		{
			return _event as KeyboardEvent;
		}
		/**
		 * @inheritDoc
		 */
		public function get mouseEvent():MouseEvent
		{
			return _event as MouseEvent;
		}
		/**
		 * @inheritDoc
		 */
		public function get event():Event
		{
			return _event as Event;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get shiftKey():Boolean
		{
			return _shiftKey;
		}
		/**
		 * @inheritDoc
		 */
		public function get altKey():Boolean
		{
			return _altKey;
		}
		/**
		 * @inheritDoc
		 */
		public function get ctrlKey():Boolean
		{
			return _ctrlKey;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get mouseButtonDown():Boolean
		{
			return _mouseButtonDown;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get pointClicked():Boolean
		{
			return _pointClicked;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get mouseMoved():Boolean
		{
			if (!_stage)
				return false;
			return _stage.mouseX != _lastMousePoint.x || _stage.mouseY != _lastMousePoint.y;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get previousFrameElapsedTime():int
		{
			return _previousFrameElapsedTime;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get currentFrameElapsedTime():int
		{
			return getTimer() - _currentFrameStartTime;
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
		 * This function gets called on ENTER_FRAME events.
		 */
		private function handleEnterFrame():void
		{
			resetDebugTime();
			
			var currentTime:int = getTimer();
			_previousFrameElapsedTime = currentTime - _currentFrameStartTime;
			_currentFrameStartTime = currentTime;
			if (maxComputationTimePerFrame == 0)
				maxComputationTimePerFrame = 100;
			
			if (debug_fps)
			{
				frameTimes.push(previousFrameElapsedTime);
				if (frameTimes.length == 24)
				{
					aft = StandardLib.mean.apply(null, frameTimes);
					trace(Math.round(1000 / aft),'fps; max computation time',maxComputationTimePerFrame);
					frameTimes.length = 0;
				}
			}
			
			if (_previousFrameElapsedTime > 3000)
				trace(_previousFrameElapsedTime);
			
			// update mouse coordinates
			_lastMousePoint.x = _stage.mouseX;
			_lastMousePoint.y = _stage.mouseY;
			
			handleCallLater();
		}
		
		/**
		 * This function gets called during ENTER_FRAME and RENDER events.
		 */
		private function handleCallLater():void
		{
			if (UIComponentGlobals.callLaterSuspendCount > 0)
				return;

			// The variables countdown and lastPriority are used to avoid running newly-added tasks immediately.
			// This avoids wasting time on async tasks that do nothing and return early, adding themselves back to the queue.

			var args:Array;
			var stackTrace:String;
			var now:int;
			var allStop:int = _currentFrameStartTime + maxComputationTimePerFrame;

			// first run the functions that should be called before anything else.
			var queue:Array = _priorityCallLaterQueues[WeaveAPI.TASK_PRIORITY_IMMEDIATE] as Array;
			var countdown:int;
			for (countdown = queue.length; countdown > 0; countdown--)
			{
				if (debug_callLater)
					DebugTimer.begin();
				
				now = getTimer();
				// stop when max computation time is reached for this frame
				if (now > allStop)
					return;
				
				// args: (relevantContext:Object, method:Function, parameters:Array, priority:uint = 0)
				args = queue.shift();
				stackTrace = _stackTraceMap[args];
				
//				WeaveAPI.SessionManager.unassignBusyTask(args);
				
				// don't call the function if the relevantContext was disposed.
				if (!WeaveAPI.SessionManager.objectWasDisposed(args[0]))
					(args[1] as Function).apply(null, args[2]);
				
				if (debug_callLater)
					DebugTimer.end(stackTrace);
			}
			
//			trace('-------');
			
			var minPriority:int = WeaveAPI.TASK_PRIORITY_IMMEDIATE + 1;
			var lastPriority:int = _activePriority == minPriority ? _priorityCallLaterQueues.length - 1 : _activePriority - 1;
			var pStart:int = getTimer();
			var pAlloc:int = int(_priorityAllocatedTimes[_activePriority]);
			var pElapsed:int = int(_priorityElapsedTimes[_activePriority]);
			var pStop:int = Math.min(allStop, pStart + pAlloc - pElapsed);
			queue = _priorityCallLaterQueues[_activePriority] as Array;
			countdown = queue.length;
			while (true)
			{
				if (debug_callLater)
					DebugTimer.begin();
				
				now = getTimer();
				if (countdown == 0 || now > pStop)
				{
					// keep track of elapsed time for this priority
					pElapsed += now - pStart;
					_priorityElapsedTimes[_activePriority] = pElapsed;
					
					// if max computation time was reached for this frame or we have visited all priorities, stop now
					if (now > allStop || _activePriority == lastPriority)
						return;
					
					// see if there are any entries left in the queues (except for the immediate queue)
					var remaining:int = 0;
					for (var i:int = minPriority; i < _priorityCallLaterQueues.length; i++)
						remaining += (_priorityCallLaterQueues[i] as Array).length;
					// stop if no more entries
					if (remaining == 0)
						break;
					
					// reset elapsed counter for next time
					// if we went overtime, let the overflow value carry over
					pElapsed = Math.max(0, pElapsed - pAlloc);
					_priorityElapsedTimes[_activePriority] = pElapsed;
					
					// switch to next priority
					_activePriority++;
					if (_activePriority == _priorityCallLaterQueues.length)
						_activePriority = minPriority;
					pStart = now;
					pAlloc = int(_priorityAllocatedTimes[_activePriority]);
					pElapsed = int(_priorityElapsedTimes[_activePriority]);
					pStop = Math.min(allStop, pStart + pAlloc - pElapsed);
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
					
					(args[1] as Function).apply(null, args[2]);
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
//			WeaveAPI.SessionManager.assignBusyTask(arguments, relevantContext as ILinkableObject);
			
			if (priority >= _priorityCallLaterQueues.length)
			{
				reportError("Invalid priority value: " + priority);
				priority = WeaveAPI.TASK_PRIORITY_BUILDING;
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
		public function startTask(relevantContext:Object, iterativeTask:Function, priority:int, finalCallback:Function = null):void
		{
			// do nothing if task already active
			if (WeaveAPI.ProgressIndicator.hasTask(iterativeTask))
				return;
			
			if (priority <= 0)
			{
				reportError("Task priority " + priority + " is not supported.");
				priority = WeaveAPI.TASK_PRIORITY_BUILDING;
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
					progress = task.call(null, _currentTaskStopTime) as Number;
				else
					progress = task.apply() as Number;
				
				if (progress === null || isNaN(progress) || progress < 0 || progress > 1)
				{
					reportError("Received unexpected result from iterative task (" + progress + ").  Expecting a number between 0 and 1.  Task cancelled.");
					if (debug_async_stack)
					{
						trace(stackTrace);
						// this is incorrect behavior, but we can put a breakpoint here
						if (useTimeParameter)
							progress = task.call(null, _currentTaskStopTime) as Number;
						else
							progress = task.apply() as Number;
					}
					progress = 1;
				}
				if (debug_async_stack && currentFrameElapsedTime > 3000)
				{
					trace(getTimer() - time, stackTrace);
					// this is incorrect behavior, but we can put a breakpoint here
					if (useTimeParameter)
						progress = task.call(null, _currentTaskStopTime) as Number;
					else
						progress = task.apply() as Number;
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
		 * This function gets called when a mouse click event occurs.
		 */
		private function handleMouseDown():void
		{
			// remember the mouse down point for handling POINT_CLICK_EVENT callbacks.
			_lastMouseDownPoint.x = mouseEvent.stageX;
			_lastMouseDownPoint.y = mouseEvent.stageY;
		}
		/**
		 * This function gets called when a mouse click event occurs.
		 */
		private function handleMouseClick():void
		{
			// if the mouse down point is the same as the mouse click point, trigger the POINT_CLICK_EVENT callbacks.
			if (_lastMouseDownPoint.x == mouseEvent.stageX && _lastMouseDownPoint.y == mouseEvent.stageY)
			{
				var cc:ICallbackCollection = _callbackCollections[POINT_CLICK_EVENT] as ICallbackCollection;
				_pointClicked = true;
				cc.triggerCallbacks();
			}
			else
			{
				_pointClicked = false;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function getSupportedEventTypes():Array
		{
			return _eventTypes.concat();
		}
		
		/**
		 * initialize callback collections.
		 */
		private function initialize(event:TimerEvent = null):void
		{
			var type:String;
			
			// initialize callback collections if not done so already
			if (!_callbackCollectionsInitialized)
			{
				// create a new callback collection for each type of event
				for each (type in _eventTypes)
				{
					_callbackCollections[type] = new CallbackCollection();
				}
				
				// set this flag so callback collections won't be initialized again
				_callbackCollectionsInitialized = true;
				
				// add these callbacks now so they will execute before any others
				addEventCallback(Event.ENTER_FRAME, null, handleEnterFrame);
				addEventCallback(Event.RENDER, null, handleCallLater);
				addEventCallback(MouseEvent.MOUSE_DOWN, null, handleMouseDown);
				addEventCallback(MouseEvent.CLICK, null, handleMouseClick);
			}
			
			// initialize the mouse event listeners if possible and necessary
			if (!_listenersInitialized && WeaveAPI.topLevelApplication != null && WeaveAPI.topLevelApplication.stage != null)
			{
				// save a pointer to the stage.
				_stage = WeaveAPI.topLevelApplication.stage;
				// create listeners for each type of event
				for each (type in _eventTypes)
				{
					// do not create event listeners for POINT_CLICK_EVENT because it is not a real event
					if (type == POINT_CLICK_EVENT)
						continue;
					
					generateListeners(type);
				}
				_listenersInitialized = true;
			}
			
			// check again if listeners have been initialized
			if (!_listenersInitialized)
			{
				// if initialize() can't be done yet, start a timer so initialize() will be called later.
				_initializeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, initialize);
				_initializeTimer.start();
			}
		}
		/**
		 * This is for internal use only.
		 * These inline functions are generated inside this function to avoid re-use of local variables.
		 * @param eventType An event type to generate a listener function for.
		 * @return An event listener function for the given eventType that updates the event variables and runs event callbacks.
		 */
		private function generateListeners(eventType:String):void
		{
			var cc:ICallbackCollection = _callbackCollections[eventType] as ICallbackCollection;

			var captureListener:Function = function (event:Event):void
			{
				// set event variables
				_event = event;
				var mouseEvent:MouseEvent = event as MouseEvent;
				if (mouseEvent)
				{
					// Ignore this event if stageX is undefined.
					// It seems that whenever we get a mouse event with undefined coordinates,
					// we always get a duplicate event right after that defines the coordinates.
					// The ctrlKey,altKey,shiftKey properties always seem to be false when the coordinates are NaN.
					if (isNaN(mouseEvent.stageX))
						return; // do nothing when coords are undefined
					
					_altKey = mouseEvent.altKey;
					_shiftKey = mouseEvent.shiftKey;
					_ctrlKey = mouseEvent.ctrlKey;
					_mouseButtonDown = mouseEvent.buttonDown;
				}
				var keyboardEvent:KeyboardEvent = event as KeyboardEvent;
				if (keyboardEvent)
				{
					_altKey = keyboardEvent.altKey;
					_shiftKey = keyboardEvent.shiftKey;
					_ctrlKey = keyboardEvent.ctrlKey;
				}
				// run callbacks for this event type
				cc.triggerCallbacks();
				// clear _event variable
				_event = null;
			};
			
			var stageListener:Function = function(event:Event):void
			{
				if (event.target == _stage)
					captureListener(event);
			};
			
			_generatedListeners.push(captureListener, stageListener);
			
			// Add a listener to the capture phase so the callbacks will run before the target gets the event.
			_stage.addEventListener(eventType, captureListener, true, 0, true); // use capture phase
			
			// If the target is the stage, the capture listener won't be called, so add
			// an additional listener that runs callbacks when the stage is the target.
			_stage.addEventListener(eventType, stageListener, false, 0, true); // do not use capture phase
		}
		
		/**
		 * @inheritDoc
		 */
		public function addEventCallback(eventType:String, relevantContext:Object, callback:Function, runCallbackNow:Boolean = false):void
		{
			var cc:ICallbackCollection = _callbackCollections[eventType] as ICallbackCollection;
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
			var cc:ICallbackCollection = _callbackCollections[eventType] as ICallbackCollection;
			if (cc != null)
				cc.removeCallback(callback);
		}
	}
}
