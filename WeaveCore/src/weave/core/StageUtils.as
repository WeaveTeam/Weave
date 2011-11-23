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
	
	import mx.core.Application;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.reportError;
	
	/**
	 * This is an all-static class that allows you to add callbacks that will be called when an event occurs on the stage.
	 * 
	 * WARNING: These callbacks will trigger on every mouse and keyboard event that occurs on the stage.
	 *          Developers should not add any callbacks that run computationally expensive code.
	 * 
	 * @author adufilie
	 */
	public class StageUtils
	{
		// begin static code block
		{
			initialize();
		}
		// end static code block
		
		/**
		 * This is the last keyboard event that occurred on the stage.
		 * This variable is set while callbacks are running and is cleared immediately after.
		 */
		public static function get keyboardEvent():KeyboardEvent
		{
			return _event as KeyboardEvent;
		}
		/**
		 * This is the last mouse event that occurred on the stage.
		 * This variable is set while callbacks are running and is cleared immediately after.
		 */
		public static function get mouseEvent():MouseEvent
		{
			return _event as MouseEvent;
		}
		/**
		 * This is the last event that occurred on the stage.
		 * This variable is set while callbacks are running and is cleared immediately after.
		 */
		public static function get event():Event
		{
			return _event as Event;
		}
		private static var _event:Event = null; // returned by get event()
		
		/**
		 * @return The current pressed state of the ctrl key.
		 */
		public static function get shiftKey():Boolean
		{
			return _shiftKey;
		}
		private static var _shiftKey:Boolean = false; // returned by get shiftKey()
		/**
		 * @return The current pressed state of the ctrl key.
		 */
		public static function get altKey():Boolean
		{
			return _altKey;
		}
		private static var _altKey:Boolean = false; // returned by get altKey()
		/**
		 * @return The current pressed state of the ctrl key.
		 */
		public static function get ctrlKey():Boolean
		{
			return _ctrlKey;
		}
		private static var _ctrlKey:Boolean = false; // returned by get ctrlKey()
		
		/**
		 * @return The current pressed state of the mouse button.
		 */
		public static function get mouseButtonDown():Boolean
		{
			return _mouseButtonDown;
		}
		private static var _mouseButtonDown:Boolean = false; // returned by get mouseButtonDown()
		
		/**
		 * @return true if the mouse moved since the last frame.
		 */
		public static function get mouseMoved():Boolean
		{
			if (!_stage)
				return false;
			return _stage.mouseX != _lastMousePoint.x || _stage.mouseY != _lastMousePoint.y;
		}
		
		/**
		 * This is the total time it took to process the previous frame.
		 */
		public static function get previousFrameElapsedTime():int
		{
			return _previousFrameElapsedTime;
		}
		
		/**
		 * This is the amount of time the current frame has taken to process so far.
		 */
		public static function get currentFrameElapsedTime():int
		{
			return getTimer() - _currentFrameStartTime;
		}
		
		/**
		 * This function can be used to ensure the flash interface is reasonably responsive during long asynchronous computations.
		 * If this function returns true, it is recommended to use StageUtils.callLater() to delay asynchronous processing until the next frame.
		 * @return A value of true if the currentFrameElapsedTime has reached the maxComputationTimePerFrame threshold.
		 */
		public static function get shouldCallLater():Boolean
		{
			return currentFrameElapsedTime > maxComputationTimePerFrame;
		}
		
		/**
		 * This is the recommended upper bound of computation time per frame.
		 * The "get shouldCallLater()" function uses this value along with currentFrameElapsedTime to determine its recommendation.
		 */
		public static const maxComputationTimePerFrame:int = 100;

		/**
		 * This function gets called on ENTER_FRAME events.
		 */
		private static function handleEnterFrame():void
		{
			var currentTime:int = getTimer();
			_previousFrameElapsedTime = currentTime - _currentFrameStartTime;
			_currentFrameStartTime = currentTime;
			// update mouse coordinates
			_lastMousePoint.x = _stage.mouseX;
			_lastMousePoint.y = _stage.mouseY;
			
			var args:Array;
			var stackTrace:String;
			var calls:Array;
			var i:int;

			// first run the functions that cannot be delayed more than one frame.
			if (_callLaterSingleFrameDelayArray.length > 0)
			{
				calls = _callLaterSingleFrameDelayArray;
				_callLaterSingleFrameDelayArray = [];
				for (i = 0; i < calls.length; i++)
				{
					// args: (relevantContext:Object, method:Function, parameters:Array = null, allowMultipleFrameDelay:Boolean = true)
					args = calls[i] as Array;
					stackTrace = _stackTraceMap[args];
					// don't call the function if the relevantContext was disposed of.
					if (!WeaveAPI.SessionManager.objectWasDisposed(args[0]))
						(args[1] as Function).apply(null, args[2]);
				}
			}
			
			if (_callLaterArray.length > 0)
			{
				//trace("handle ENTER_FRAME, " + _callLaterArray.length + " callLater functions, " + currentFrameElapsedTime + " ms elapsed this frame");
				// Make a copy of the function calls and clear the static array before executing any functions.
				// This allows the static array to be filled up as a result of executing the functions,
				// and prevents from newly added functions from being called until the next frame.
				calls = _callLaterArray;
				_callLaterArray = [];
				for (i = 0; i < calls.length; i++)
				{
					// if elapsed time reaches threshold, call everything else later
					if (getTimer() - _currentFrameStartTime > maxComputationTimePerFrame)
					{
						// To preserve the order they were added, put the remaining callLater
						// functions for this frame in front of any others that may have been added.
						var j:int = calls.length;
						while (--j >= i)
							_callLaterArray.unshift(calls[j]);
						break;
					}
					// args: (relevantContext:Object, method:Function, parameters:Array = null, allowMultipleFrameDelay:Boolean = true)
					args = calls[i] as Array;
					stackTrace = _stackTraceMap[args]; // check this for debugging where the call came from
					// don't call the function if the relevantContext was disposed of.
					if (!WeaveAPI.SessionManager.objectWasDisposed(args[0]))
						(args[1] as Function).apply(null, args[2]);
				}
			}
		}
		private static var _currentFrameStartTime:int = getTimer(); // this is the result of getTimer() on the last ENTER_FRAME event.
		private static var _previousFrameElapsedTime:int = 0; // this is the amount of time it took to process the previous frame.
		
		/**
		 * This calls a function in a future ENTER_FRAME event.  The function call will be delayed
		 * further frames if the maxComputationTimePerFrame time limit is reached in a given frame.
		 * @param relevantContext This parameter may be null.  If the relevantContext object gets disposed of, the specified method will not be called.
		 * @param method The function to call later.
		 * @param parameters The parameters to pass to the function.
		 */
		public static function callLater(relevantContext:Object, method:Function, parameters:Array = null, allowMultipleFrameDelay:Boolean = true):void
		{
			//trace("call later @",currentFrameElapsedTime);
			if (allowMultipleFrameDelay)
				_callLaterArray.push(arguments);
			else
				_callLaterSingleFrameDelayArray.push(arguments);
			
			_stackTraceMap[arguments] = new Error("Stack trace").getStackTrace();
		}
		
		private static const _stackTraceMap:Dictionary = new Dictionary(true);
		
		/**
		 * This is an array of functions with parameters that will be executed the next time handleEnterFrame() is called.
		 * This array gets populated by callLater().
		 */
		private static var _callLaterSingleFrameDelayArray:Array = [];
		
		/**
		 * This is an array of functions with parameters that will be executed the next time handleEnterFrame() is called.
		 * This array gets populated by callLater().
		 */
		private static var _callLaterArray:Array = [];
		
		/**
		 * This function gets called when a mouse click event occurs.
		 */
		private static function handleMouseDown():void
		{
			// remember the mouse down point for handling POINT_CLICK_EVENT callbacks.
			_lastMouseDownPoint.x = mouseEvent.stageX;
			_lastMouseDownPoint.y = mouseEvent.stageY;
		}
		/**
		 * This function gets called when a mouse click event occurs.
		 */
		private static function handleMouseClick():void
		{
			// if the mouse down point is the same as the mouse click point, trigger the POINT_CLICK_EVENT callbacks.
			if (_lastMouseDownPoint.x == mouseEvent.stageX && _lastMouseDownPoint.y == mouseEvent.stageY)
			{
				var cc:ICallbackCollection = _callbackCollections[POINT_CLICK_EVENT] as ICallbackCollection;
				cc.triggerCallbacks();
				cc.resumeCallbacks(true);
			}
		}
		
		public static function getSupportedEventTypes():Array
		{
			return _eventTypes.concat();
		}
		
		/**
		 * This is a list of supported events.
		 */
		private static const _eventTypes:Array = [ 
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
		private static var _callbackCollectionsInitialized:Boolean = false; // This is true after the callback collections have been created.
		private static var _listenersInitialized:Boolean = false; // This is true after the mouse listeners have been added.
		
		/**
		 * This timer is only used if initialize() is attempted before the stage is accessible.
		 */
		private static const _initializeTimer:Timer = new Timer(0, 1);

		/**
		 * This is a mapping from an event type to a callback collection associated with it.
		 * Event types are those defined in static constants of the MouseEvent class.
		 */
		private static const _callbackCollections:Object = {};
		
		/**
		 * initialize static callback collections.
		 */
		private static function initialize(event:TimerEvent = null):void
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
				addEventCallback(MouseEvent.MOUSE_DOWN, null, handleMouseDown);
				addEventCallback(MouseEvent.CLICK, null, handleMouseClick);
			}
			
			// initialize the mouse event listeners if possible and necessary
			if (!_listenersInitialized && Application.application != null && Application.application.stage != null)
			{
				// save a pointer to the stage.
				_stage = Application.application.stage;
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
		 * @return An event listener function for the given eventType that updates static variables and runs event callbacks.
		 */
		private static function generateListeners(eventType:String):void
		{
			var cc:ICallbackCollection = _callbackCollections[eventType] as ICallbackCollection;

			var captureListener:Function = function (event:Event):void
			{
				// set static variables
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
				// clear static _event variable
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
		 * This Array is used to keep strong references to the generated listeners so that they can be added with weak references.
		 * The weak references only matter when this code is loaded as a sub-application and later unloaded.
		 */		
		private static const _generatedListeners:Array = [];
		
		/**
		 * WARNING: These callbacks will trigger on every mouse event that occurs on the stage.
		 *          Developers should not add any callbacks that run computationally expensive code.
		 * 
		 * This function will add a callback using the given function and parameters.
		 * Any callback previously added for the same function will be overwritten.
		 * @param eventType The name of the event to add a callback for, one of the static values in the MouseEvent class.
		 * @param callback The function to call when an event of the specified type is dispatched from the stage.
		 * @param parameters An array of parameters that will be used as parameters to the callback function.
		 * @param runCallbackNow If this is set to true, the callback will be run immediately after it is added.
		 */
		public static function addEventCallback(eventType:String, relevantContext:Object, callback:Function, parameters:Array = null, runCallbackNow:Boolean = false):void
		{
			var cc:ICallbackCollection = _callbackCollections[eventType] as ICallbackCollection;
			if (cc != null)
			{
				cc.addImmediateCallback(relevantContext, callback, parameters, runCallbackNow);
			}
			else
			{
				reportError("(StageUtils) Unsupported event: "+eventType);
			}
		}
		
		/**
		 * @param eventType The name of the event to remove a callback for, one of the static values in the MouseEvent class.
		 * @param callback The function to remove from the list of callbacks.
		 */
		public static function removeEventCallback(eventType:String, callback:Function):void
		{
			var cc:ICallbackCollection = _callbackCollections[eventType] as ICallbackCollection;
			if (cc != null)
				cc.removeCallback(callback);
		}

		/**
		 * This is a pointer to the stage.  This is null until initialize() is successfully called.
		 */
		private static var _stage:Stage = null;
		
		/**
		 * This object contains the stage coordinates of the mouse for the current frame.
		 */
		private static const _lastMousePoint:Point = new Point(NaN, NaN);
		
		/**
		 * This is the stage location of the last mouse-down event.
		 */
		private static const _lastMouseDownPoint:Point = new Point(NaN, NaN);
		
		/**
		 * This is a special pseudo-event supported by StageUtils.
		 * Callbacks added to this event will only trigger when the mouse was clicked and released at the same screen location.
		 */
		public static const POINT_CLICK_EVENT:String = "pointClick";
	}
}
