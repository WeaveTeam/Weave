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
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	
	/**
	 * This class manages a list of callback functions.
	 * 
	 * @author adufilie
	 */
	public class CallbackCollection implements ICallbackCollection, IDisposableObject
	{
		/**
		 * Set this to true to enable stack traces for debugging.
		 */
		public static var debug:Boolean = true;

		/**
		 * If specified, the preCallback function will be called immediately before running each callback.
		 * This means if there are five callbacks added, preCallback() gets called five times whenever
		 * _runCallbacksImmediately() is called.  An example usage of this is to make sure a relevant
		 * variable is set to the appropriate value while each callback is running.  If preCallback()
		 * takes any parameters, they must be made optional.  The preCallback function will not be called
		 * before grouped callbacks.
		 * @param preCallback An optional function to call before each immediate callback.
		 */
		public function CallbackCollection(preCallback:Function = null)
		{
			this._preCallback = preCallback;
		}

		/**
		 * This is a list of CallbackEntry objects in the order they were created.
		 */
		private var _callbackEntries:Array = new Array();

		/**
		 * If this is set to true, delayCallbacks() behaves as described.  Otherwise, delayCallbacks() has no effect.
		 */
		protected var allowDelayCallbacks:Boolean = true;

		/**
		 * This is the function that gets called immediately before every callback.
		 */
		private var _preCallback:Function = null;

		/**
		 * This is the number of times delayCallbacks() has been called without a matching call to resumeCallbacks().
		 * While this is greater than zero, effects of triggerCallbacks() will be delayed.
		 */
		private var _delayCount:uint = 0;
		
		/**
		 * If this is true, it means triggerCallbacks() has been called while delayed was true.
		 */
		private var _runCallbacksIsPending:Boolean = false;
		
		/**
		 * This is the default value of triggerCounter.
		 */		
		protected const DEFAULT_TRIGGER_COUNT:uint = 1;
		
		/**
		 * This value keeps track of how many times callbacks were triggered, and is returned by the public triggerCounter accessor function.
		 * The value starts at 1 to simplify code that compares the counter to a previous value.
		 * This allows the previous value to be set to zero so change will be detected the first time the counter is compared.
		 * This fixes potential bugs where the base case of zero is not considered.
		 */
		private var _triggerCounter:uint = DEFAULT_TRIGGER_COUNT;
		
		private static const STACK_TRACE_ADD:String = "This is the stack trace from when the callback was added.";
		private static const STACK_TRACE_REMOVE:String = "This is the stack trace from when the callback was removed.";
		
		/**
		 * This adds the given function as a callback.  The function must not require any parameters.
		 * The callback function will not be called recursively as a result of it triggering callbacks recursively.
		 * @param relevantContext If this is not null, then the callback will be removed when the relevantContext object is disposed via SessionManager.dispose().  This parameter is typically a 'this' pointer.
		 * @param callback The function to call when callbacks are triggered.
		 * @param runCallbackNow If this is set to true, the callback will be run immediately after it is added.
		 * @param alwaysCallLast If this is set to true, the callback will be always be called after any callbacks that were added with alwaysCallLast=false.  Use this to establish the desired child-to-parent triggering order.
		 */
		public final function addImmediateCallback(relevantContext:Object, callback:Function, runCallbackNow:Boolean = false, alwaysCallLast:Boolean = false):void
		{
			if (callback == null)
				return;
			
			// remove the callback if it was previously added
			removeCallback(callback);
			
			var entry:CallbackEntry = new CallbackEntry();
			_callbackEntries.push(entry);
			entry.context = relevantContext;
			entry.callback = callback;
			entry.recursionLimit = 0;
			if (alwaysCallLast)
				entry.schedule = 1;
			
			if (debug)
				entry.addCallback_stackTrace = new Error(STACK_TRACE_ADD).getStackTrace();

			// run callback now if requested
			if (runCallbackNow)
			{
				// increase the recursion count while the function is running
				entry.recursionCount++;
				callback();
				entry.recursionCount--;
			}
		}

		/**
		 * This will trigger every callback function to be called with their saved arguments.
		 * If the delay count is greater than zero, the callbacks will not be called immediately.
		 */
		public final function triggerCallbacks():void
		{
			if (_delayCount > 0)
			{
				_triggerCounter++;
				_runCallbacksIsPending = true;
				return;
			}
			_runCallbacksImmediately();
		}
		
		/**
		 * This flag is used in _runCallbacksImmediately() to detect when a recursive call has completed running all the callbacks.
		 */
		private var _runCallbacksCompleted:Boolean;
		
		/**
		 * This function runs callbacks immediately, ignoring any delays.
		 * The preCallback function will be called with the specified preCallbackParams arguments.
		 * @param preCallbackParams The arguments to pass to the preCallback function given in the constructor.
		 */		
		protected final function _runCallbacksImmediately(...preCallbackParams):void
		{
			_triggerCounter++;
			_runCallbacksIsPending = false;
			
			// This flag is set to false before running the callbacks.  When it becomes true, the loop exits.
			_runCallbacksCompleted = false;
			
			// first run callbacks with schedule 0, then those with schedule 1
			for (var schedule:int = 0; schedule < 2; schedule++)
			{
				// run the callbacks in the order they were added
				for (var i:int = 0; i < _callbackEntries.length; i++)
				{
					// If this flag is set to true, it means a recursive call has finished running callbacks.
					// If preCallbackParams are specified, we don't want to exit the loop because that cause a loss of information.
					if (_runCallbacksCompleted && preCallbackParams.length == 0)
						break;
					
					var entry:CallbackEntry = _callbackEntries[i] as CallbackEntry;
					// if we haven't reached the matching schedule yet, skip this callback
					if (entry.schedule != schedule)
						continue;
					// Remove the entry if the context was disposed of by SessionManager.
					var shouldRemoveEntry:Boolean;
					if (entry.callback == null)
						shouldRemoveEntry = true;
					else if (entry.context is CallbackCollection) // special case
						shouldRemoveEntry = (entry.context as CallbackCollection)._wasDisposed;
					else
						shouldRemoveEntry = WeaveAPI.SessionManager.objectWasDisposed(entry.context);
					if (shouldRemoveEntry)
					{
						if (debug && entry.callback != null)
							entry.removeCallback_stackTrace = new Error(STACK_TRACE_REMOVE).getStackTrace();
						// help the garbage-collector a bit
						entry.context = null;
						entry.callback = null;
						// remove the empty callback reference from the list
						_callbackEntries.splice(i--, 1); // decrease i because remaining entries have shifted
						continue;
					}
					// if preCallbackParams are specified, we don't want to limit recursion because that would cause a loss of information.
					if (entry.recursionCount <= entry.recursionLimit || preCallbackParams.length > 0)
					{
						entry.recursionCount++; // increase count to signal that we are currently running this callback.
						if (_preCallback != null)
							_preCallback.apply(null, preCallbackParams);
						
						entry.callback();
						
						entry.recursionCount--; // decrease count because the callback finished.
					}
				}
			}

			// This flag is now set to true in case this function was called recursively.  This causes the outer call to exit its loop.
			_runCallbacksCompleted = true;
		}
		
		/**
		 * @param callback The function to remove from the list of callbacks.
		 */
		public final function removeCallback(callback:Function):void
		{
			// if the callback was added as a grouped callback, we need to remove the trigger function
			var triggerCallbackEntry:CallbackEntry = _groupedCallbackToTriggerEntryMap[callback] as CallbackEntry;
			if (triggerCallbackEntry != null)
				removeCallback(triggerCallbackEntry.callback);
			
			// find the matching CallbackEntry, if any
			for (var index:int = 0; index < _callbackEntries.length; index++)
			{
				var entry:CallbackEntry = _callbackEntries[index] as CallbackEntry;
				if (entry != null && callback === entry.callback)
				{
					// Remove the callback by setting the function pointer to null.
					// This is done instead of removing the entry because we may be looping over the _callbackEntries Array right now.
					entry.context = null;
					entry.callback = null;
					if (debug)
						entry.removeCallback_stackTrace = new Error(STACK_TRACE_REMOVE).getStackTrace();
					// done removing the callback
					return;
				}
			}
		}
		
		/**
		 * This counter gets incremented at the time that callbacks are triggered and before they are actually called.
		 * It is necessary in some situations to check this counter to determine if cached data should be used.
		 */
		public final function get triggerCounter():uint
		{
			return _triggerCounter;
		}
		
		/**
		 * While this is true, it means the delay count is greater than zero and the effects of
		 * triggerCallbacks() are delayed until resumeCallbacks() is called to reduce the delay count.
		 */
		public final function get callbacksAreDelayed():Boolean
		{
			return _delayCount > 0
		}
		
		/**
		 * This will increase the delay count by 1.  To decrease the delay count, use resumeCallbacks().
		 * As long as the delay count is greater than zero, effects of triggerCallbacks() will be delayed.
		 */
		public final function delayCallbacks():void
		{
			if (allowDelayCallbacks)
				_delayCount++;
		}

		/**
		 * This will decrease the delay count if it is greater than zero.
		 * If triggerCallbacks() was called while the delay count was greater than zero, immediate callbacks will be called now.
		 * @param undoAllDelays If this is set to true, the delay count will be set to zero.  Otherwise, the delay count will be decreased by one.
		 */
		public final function resumeCallbacks(undoAllDelays:Boolean = false):void
		{
			if (undoAllDelays)
				_delayCount = 0;
			else if (_delayCount > 0)
				_delayCount--;

			if (_delayCount == 0 && _runCallbacksIsPending)
				triggerCallbacks();
		}

		/**
		 * This will remove all callbacks.
		 * This function should only be called when this CallbackCollection is no longer needed.
		 */
		public function dispose():void
		{
			// remove all callbacks
			_callbackEntries.length = 0;
			_wasDisposed = true;
		}
		
		/**
		 * This value is used internally to remember if dispose() was called.
		 */		
		private var _wasDisposed:Boolean = false;
		
		/**
		 * This flag becomes true after dispose() is called.
		 */		
		public function get wasDisposed():Boolean
		{
			return _wasDisposed;
		}
		
		/**
		 * This is set to true while grouped callbacks are running.
		 */
		private static var _runningGroupedCallbacksNow:Boolean = false;
		
		/**
		 * This maps a grouped callback function to its corresponding CallbackEntry object containing a trigger function for that callback.
		 * A different trigger function is required for each callback because CallbackCollection will only keep one copy of the pointer to
		 * any given function.
		 */
		private static const _groupedCallbackToTriggerEntryMap:Dictionary = new Dictionary();
		
		/**
		 * This Dictionary maps a grouped callback trigger CallbackEntry to a value of true that means the callback was triggered.
		 */
		private static const _triggeredGroupedCallbackEntryMap:Dictionary = new Dictionary(true);
		
		/**
		 * This is a list of the grouped CallbackEntry objects in the order they were triggered.
		 */		
		private static const _triggeredGroupedCallbackEntryOrderedList:Array = new Array();
		
		/**
		 * This variable is false until the handleEnterFrame callback has been added through StageUtils.
		 */
		private static var _frameCallbackAdded:Boolean = false;
		
		/**
		 * This function gets called once per frame and allows grouped callbacks to run.
		 */
		private static function _handleGroupedCallbacks():void
		{
			// this flag tells all trigger functions to run their corresponding callbacks immediately
			_runningGroupedCallbacksNow = true;

			while (_triggeredGroupedCallbackEntryOrderedList.length > 0)
			{
				// run grouped callbacks in the order they were triggered
				var triggerEntry:CallbackEntry = _triggeredGroupedCallbackEntryOrderedList.shift() as CallbackEntry;
				(triggerEntry as CallbackEntry).callback();
				delete _triggeredGroupedCallbackEntryMap[triggerEntry];
			}

			_runningGroupedCallbacksNow = false;
		}

		/**
		 * This function will add a callback that will be delayed except during a scheduled time each frame.  Grouped callbacks use a central
		 * trigger list, meaning that if multiple CallbackCollections trigger the same grouped callback before the scheduled time, it will
		 * behave as if it were only triggered once.  For this reason, grouped callback functions cannot have any parameters. Adding a grouped
		 * callback to a CallbackCollection will replace any previous effects of addImmediateCallback() or addGroupedCallback() made to the
		 * same CallbackCollection.  The callback function* will not be called recursively as a result of it triggering callbacks recursively.
		 * @param relevantContext If this is not null, then the callback will be removed when the relevantContext object is disposed via SessionManager.dispose().  This parameter is typically a 'this' pointer.
		 * @param groupedCallback The callback function that will only be allowed to run during a scheduled time each frame.  It must not require any parameters.
		 * @param triggerCallbackNow If this is set to true, the callback will be triggered to run during the scheduled time after it is added.
		 */
		public function addGroupedCallback(relevantContext:Object, groupedCallback:Function, triggerCallbackNow:Boolean = false):void
		{
			if (!_frameCallbackAdded)
			{
				WeaveAPI.StageUtils.addEventCallback(Event.ENTER_FRAME, null, _handleGroupedCallbacks);
				_frameCallbackAdded = true;
			}
			
			var recursionLimit:uint = 0;
			var triggerEntry:CallbackEntry = _groupedCallbackToTriggerEntryMap[groupedCallback] as CallbackEntry;
			if (triggerEntry != null)
			{
				// add this context to the list of relevant contexts
				if (relevantContext == null) // null means never remove the callback
					triggerEntry.context = [null];
				else if (triggerEntry.context[0] != null)
					triggerEntry.context.push(relevantContext);
				// use the minimum of the existing limit and the new limit.
				triggerEntry.recursionLimit = Math.min(triggerEntry.recursionLimit, recursionLimit);
			}
			else // need to create new shared CallbackEntry for this grouped callback
			{
				triggerEntry = new CallbackEntry();
				_groupedCallbackToTriggerEntryMap[groupedCallback] = triggerEntry;
				triggerEntry.recursionLimit = recursionLimit;
				triggerEntry.context = [relevantContext]; // the context in this entry will be an array of contexts
				if (debug)
					triggerEntry.addCallback_stackTrace = new Error(STACK_TRACE_ADD).getStackTrace();
				triggerEntry.callback = function():void
				{
					if (_runningGroupedCallbacksNow)
					{
						// first, make sure there is at least one relevant context for this callback.
						var allContexts:Array = triggerEntry.context as Array;
						// remove the contexts that have been disposed of.
						for (var i:int = 0; i < allContexts.length; i++)
						{
							var context:Object = allContexts[i];
							// if there is a null context, it means the callback should never be removed.
							if (context != null && WeaveAPI.SessionManager.objectWasDisposed(context))
								allContexts.splice(i--, 1);
						}
						// if there are no more relevant contexts for this callback, don't run it.
						if (allContexts.length == 0)
						{
							triggerEntry.callback = null; // help the garbage-collector a bit
							if (debug)
								triggerEntry.removeCallback_stackTrace = new Error(STACK_TRACE_REMOVE).getStackTrace();
							delete _groupedCallbackToTriggerEntryMap[groupedCallback];
							return;
						}
						
						// this function was called as a result of calling groupedCallback().
						// enforce recursion limit now.
						if (triggerEntry.recursionCount <= triggerEntry.recursionLimit)
						{
							// increase recursion count while the function is running.
							triggerEntry.recursionCount++;
							
							groupedCallback();
							
							triggerEntry.recursionCount--;
						}
					}
					else if (_triggeredGroupedCallbackEntryMap[triggerEntry] === undefined) // if not already triggered
					{
						// set a flag to signal that this grouped callback was triggered.
						_triggeredGroupedCallbackEntryMap[triggerEntry] = true;
						_triggeredGroupedCallbackEntryOrderedList.push(triggerEntry);
					}
				};
			}
			// make sure the actual function is not already added as a callback.
			removeCallback(groupedCallback);
			
			// prevent grouped callback from running immediately because that is unexpected
			var _previouslyRunningGroupedCallbacks:Boolean = _runningGroupedCallbacksNow;
			_runningGroupedCallbacksNow = false;
			
			// add the trigger function as a callback
			addImmediateCallback(relevantContext, triggerEntry.callback, triggerCallbackNow);
			
			_runningGroupedCallbacksNow = _previouslyRunningGroupedCallbacks;
		}
	}
}

/**
 * @private
 */
internal class CallbackEntry
{
	/**
	 * This is the context in which the callback function is relevant.
	 * When the context is disposed of, the callback should not be called anymore.
	 * 
	 * Note that the context could be stored using a weak reference in an effort to make the garbage-
	 * collector take care of removing the callback, but in most situations this would not work because
	 * the callback function is typically a class member of the context object.  This means that as long
	 * as you have a strong reference to the callback function, you effectively have a strong reference
	 * to the owner of the function.  Storing the callback function as a weak reference would solve this
	 * problem, but you cannot create reliable weak references to functions due to a bug in the Flash
	 * Player.  Weak references to functions get garbage-collected even if the owner of the function still
	 * exists.
	 */	
	public var context:Object = null;
	/**
	 * This is the callback function.
	 */
	public var callback:Function = null;
	/**
	 * This is the maximum recursion depth allowed for this callback.
	 */	
	public var recursionLimit:uint = 0;
	/**
	 * This is the current recursion depth.
	 * If this is greater than zero, it means the function is currently running.
	 */
	public var recursionCount:uint = 0;
	/**
	 * This is 0 if the callback was added with alwaysCallLast=false, or 1 for alwaysCallLast=true
	 */	
	public var schedule:int = 0;
	/**
	 * This is a stack trace from when the callback was added.
	 */
	public var addCallback_stackTrace:String = null;
	/**
	 * This is a stack trace from when the callback was removed.
	 */
	public var removeCallback_stackTrace:String = null;
}
