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
	import weave.api.core.ILinkableObject;
	
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
		public static var debug:Boolean = false;
		internal var _linkableObject:ILinkableObject; // for debugging only... will be set when debug==true
		private var _lastTriggerStackTrace:String; // for debugging only... will be set when debug==true
		private var _oldEntries:Array;

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
		 * The default value is 1 to avoid being equal to a newly initialized uint=0.
		 */
		protected const DEFAULT_TRIGGER_COUNT:uint = 1;
		
		/**
		 * This value keeps track of how many times callbacks were triggered, and is returned by the public triggerCounter accessor function.
		 * The value starts at 1 to simplify code that compares the counter to a previous value.
		 * This allows the previous value to be set to zero so change will be detected the first time the counter is compared.
		 * This fixes potential bugs where the base case of zero is not considered.
		 */
		private var _triggerCounter:uint = DEFAULT_TRIGGER_COUNT;
		
		/**
		 * @inheritDoc
		 */
		public final function addImmediateCallback(relevantContext:Object, callback:Function, runCallbackNow:Boolean = false, alwaysCallLast:Boolean = false):void
		{
			if (callback == null)
				return;
			
			// remove the callback if it was previously added
			removeCallback(callback);
			
			var entry:CallbackEntry = new CallbackEntry(relevantContext, callback);
			if (alwaysCallLast)
				entry.schedule = 1;
			_callbackEntries.push(entry);

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
		 * @inheritDoc
		 */
		public final function triggerCallbacks():void
		{
			if (debug)
				_lastTriggerStackTrace = new Error(STACK_TRACE_TRIGGER).getStackTrace();
			if (_delayCount > 0)
			{
				// we still want to increase the counter even if callbacks are delayed
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
			// increase counter immediately
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
					// If _preCallback is specified, we don't want to exit the loop because that cause a loss of information.
					if (_runCallbacksCompleted && _preCallback == null)
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
						entry.dispose();
						// remove the empty callback reference from the list
						var removed:Array = _callbackEntries.splice(i--, 1); // decrease i because remaining entries have shifted
						if (debug)
							_oldEntries = _oldEntries ? _oldEntries.concat(removed) : removed;
						continue;
					}
					// if _preCallback is specified, we don't want to limit recursion because that would cause a loss of information.
					if (entry.recursionCount == 0 || _preCallback != null)
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
		 * @inheritDoc
		 */
		public final function removeCallback(callback:Function):void
		{
			// if the callback was added as a grouped callback, we need to remove the trigger function
			GroupedCallbackEntry.removeGroupedCallback(this, callback);
			
			// find the matching CallbackEntry, if any
			for (var outerLoop:int = 0; outerLoop < 2; outerLoop++)
			{
				var entries:Array = outerLoop == 0 ? _callbackEntries : _disposeCallbackEntries;
				for (var index:int = 0; index < entries.length; index++)
				{
					var entry:CallbackEntry = entries[index] as CallbackEntry;
					if (entry != null && callback === entry.callback)
					{
						// Remove the callback by setting the function pointer to null.
						// This is done instead of removing the entry because we may be looping over the _callbackEntries Array right now.
						entry.dispose();
					}
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public final function get triggerCounter():uint
		{
			return _triggerCounter;
		}
		
		/**
		 * @inheritDoc
		 */
		public final function get callbacksAreDelayed():Boolean
		{
			return _delayCount > 0
		}
		
		/**
		 * @inheritDoc
		 */
		public final function delayCallbacks():void
		{
			_delayCount++;
		}

		/**
		 * @inheritDoc
		 */
		public final function resumeCallbacks():void
		{
			if (_delayCount > 0)
				_delayCount--;

			if (_delayCount == 0 && _runCallbacksIsPending)
				triggerCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function addDisposeCallback(relevantContext:Object, callback:Function):void
		{
			// don't do anything if the dispose callback was already added
			for each (var entry:CallbackEntry in _disposeCallbackEntries)
				if (entry.callback === callback)
					return;
			
			_disposeCallbackEntries.push(new CallbackEntry(relevantContext, callback));
		}
		
		/**
		 * A list of CallbackEntry objects for when dispose() is called.
		 */		
		private var _disposeCallbackEntries:Array = [];

		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			// remove all callbacks
			if (debug)
				_oldEntries = _oldEntries ? _oldEntries.concat(_callbackEntries) : _callbackEntries.concat();
			_callbackEntries.length = 0;
			_wasDisposed = true;
			
			// run & remove dispose callbacks
			while (_disposeCallbackEntries.length)
			{
				var entry:CallbackEntry = _disposeCallbackEntries.shift() as CallbackEntry;
				if (entry.callback != null && !WeaveAPI.SessionManager.objectWasDisposed(entry.context))
					entry.callback();
			}
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
		 * @inheritDoc
		 */
		public function addGroupedCallback(relevantContext:Object, groupedCallback:Function, triggerCallbackNow:Boolean = false):void
		{
			GroupedCallbackEntry.addGroupedCallback(this, relevantContext, groupedCallback, triggerCallbackNow);
		}
	}
}

internal const STACK_TRACE_TRIGGER:String = "This is the stack trace from when the callbacks were last triggered.";
internal const STACK_TRACE_ADD:String = "This is the stack trace from when the callback was added.";
internal const STACK_TRACE_REMOVE:String = "This is the stack trace from when the callback was removed.";

import flash.events.Event;
import flash.utils.Dictionary;

import weave.api.WeaveAPI;
import weave.api.core.ICallbackCollection;
import weave.core.CallbackCollection;

/**
 * @private
 */
internal class CallbackEntry
{
	public function CallbackEntry(context:Object, callback:Function)
	{
		this.context = context;
		this.callback = callback;
		
		if (CallbackCollection.debug)
			addCallback_stackTrace = new Error(STACK_TRACE_ADD).getStackTrace();
	}
	
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
	
	/**
	 * Call this when the callback entry is no longer needed.
	 */
	public function dispose():void
	{
		if (CallbackCollection.debug && callback != null)
			removeCallback_stackTrace = new Error(STACK_TRACE_REMOVE).getStackTrace();
		
		context = null;
		callback = null;
	}
}

/**
 * @private
 */
internal class GroupedCallbackEntry extends CallbackEntry
{
	public static function addGroupedCallback(callbackCollection:ICallbackCollection, relevantContext:Object, groupedCallback:Function, triggerCallbackNow:Boolean):void
	{
		// get (or create) the shared entry for the groupedCallback
		var entry:GroupedCallbackEntry = _entryLookup[groupedCallback] as GroupedCallbackEntry;
		if (!entry)
			_entryLookup[groupedCallback] = entry = new GroupedCallbackEntry(groupedCallback);
		
		// context shouldn't be null because we use it to determine when to clean up the GroupedCallbackEntry.
		if (relevantContext == null)
			relevantContext = callbackCollection;
		
		// add this context to the list of relevant contexts
		(entry.context as Array).push(relevantContext);
		
		// make sure the actual function is not already added as a callback.
		callbackCollection.removeCallback(groupedCallback);
		
		// add the trigger function as a callback
		callbackCollection.addImmediateCallback(relevantContext, entry.trigger, triggerCallbackNow);
	}
	
	public static function removeGroupedCallback(callbackCollection:ICallbackCollection, groupedCallback:Function):void
	{
		// remove the trigger function as a callback
		var entry:GroupedCallbackEntry = _entryLookup[groupedCallback] as GroupedCallbackEntry;
		if (entry)
			callbackCollection.removeCallback(entry.trigger);
	}
	
	/**
	 * This function gets called once per frame and allows grouped callbacks to run.
	 */
	private static function _handleGroupedCallbacks():void
	{
		var i:int;
		var entry:GroupedCallbackEntry;
		
		_handlingGroupedCallbacks = true;
		{
			// Handle grouped callbacks in the order they were triggered,
			// anticipating that more may be added to the end of the list in the process.
			// This first pass does not allow grouped callbacks to call each other immediately.
			for (i = 0; i < _triggeredEntries.length; i++)
			{
				entry = _triggeredEntries[i] as GroupedCallbackEntry;
				entry.handleGroupedCallback();
			}
			
			// after all grouped callbacks have been handled once, run those which were triggered recursively and allow them to call other grouped callbacks immediately.
			_handlingRecursiveGroupedCallbacks = true;
			{
				// handle grouped callbacks that were triggered recursively
				for (i = 0; i < _triggeredEntries.length; i++)
				{
					entry = _triggeredEntries[i] as GroupedCallbackEntry;
					if (entry.triggeredAgain)
						entry.handleGroupedCallback();
				}
			}
			_handlingRecursiveGroupedCallbacks = false;
		}
		_handlingGroupedCallbacks = false;
		
		// reset for next frame
		for each (entry in _triggeredEntries)
			entry.triggered = entry.triggeredAgain = false;
		_triggeredEntries.length = 0;
	}
	
	/**
	 * True while handling grouped callbacks.
	 */
	private static var _handlingGroupedCallbacks:Boolean = false;
	
	/**
	 * True while handling grouped callbacks called recursively from other grouped callbacks.
	 */
	private static var _handlingRecursiveGroupedCallbacks:Boolean = false;
	
	/**
	 * This gets set to true when the static _handleGroupedCallbacks() callback has been added as a frame listener.
	 */
	private static var _initialized:Boolean = false;
	
	/**
	 * This maps a groupedCallback function to its corresponding GroupedCallbackEntry.
	 */
	private static const _entryLookup:Dictionary = new Dictionary();
	
	/**
	 * This is a list of GroupedCallbackEntry objects in the order they were triggered.
	 */		
	private static const _triggeredEntries:Array = [];
	
	/**
	 * Constructor
	 */
	public function GroupedCallbackEntry(groupedCallback:Function)
	{
		// context will be an array of contexts
		super([], groupedCallback);
		
		if (!_initialized)
		{
			WeaveAPI.StageUtils.addEventCallback(Event.ENTER_FRAME, null, _handleGroupedCallbacks);
			_initialized = true;
		}
	}
	
	/**
	 * If true, the callback was triggered this frame.
	 */
	public var triggered:Boolean = false;
	
	/**
	 * If true, the callback was triggered again from another grouped callback.
	 */
	public var triggeredAgain:Boolean = false;
	
	/**
	 * Marks the entry to be handled later (unless already triggered this frame).
	 * This also takes care of preventing recursion.
	 */
	public function trigger():void
	{
		// if handling recursive callbacks, call now
		if (_handlingRecursiveGroupedCallbacks)
		{
			handleGroupedCallback();
		}
		else if (!triggered)
		{
			// not previously triggered
			_triggeredEntries.push(this);
			triggered = true;
		}
		else if (_handlingGroupedCallbacks)
		{
			// triggered recursively - call later
			triggeredAgain = true;
		}
	}
	
	/**
	 * Checks the context(s) before calling groupedCallback
	 */
	public function handleGroupedCallback():void
	{
		if (!context)
			return;
		
		// first, make sure there is at least one relevant context for this callback.
		var allContexts:Array = context as Array;
		// remove the contexts that have been disposed of.
		for (var i:int = 0; i < allContexts.length; i++)
			if (WeaveAPI.SessionManager.objectWasDisposed(allContexts[i]))
				allContexts.splice(i--, 1);
		// if there are no more relevant contexts for this callback, don't run it.
		if (allContexts.length == 0)
		{
			dispose();
			delete _entryLookup[callback];
			return;
		}
		
		// avoid immediate recursion
		if (recursionCount == 0)
		{
			recursionCount++;
			callback();
			recursionCount--;
		}
		// avoid delayed recursion
		triggeredAgain = false;
	}
}
/*
weave.path('a').remove().request('LinkableString')
	.addCallback(function(){
		console.log('1');
	})
	.addCallback(function(){
		var newState = this.getState() + 'x';
		console.log(2, newState);
		this.exec("Class('flash.debugger.enterDebugger')()");
		this.state(newState);
	})
	.addCallback(function(){
		var newState = this.getState() + 'y';
		console.log(3, newState);
		this.exec("Class('flash.debugger.enterDebugger')()");
		this.state(newState);
	})
	.state('hello');
*/
