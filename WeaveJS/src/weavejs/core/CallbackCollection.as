/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.core
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.IDisposableObject;
	import weavejs.api.core.ILinkableObject;
	
	/**
	 * This class manages a list of callback functions.
	 * 
	 * @author adufilie
	 */
	public class CallbackCollection implements ICallbackCollection, IDisposableObject
	{
		internal var _linkableObject:ILinkableObject; // for debugging only... will be set when debug==true
		private var _lastTriggerStackTrace:Error; // for debugging only... will be set when debug==true
		private var _oldEntries:Array;

		/**
		 * @param preCallback An optional function to call before each immediate callback.
		 *     If specified, the preCallback function will be called immediately before running each
		 *     callback using the parameters passed to _runCallbacksImmediately(). This means if there
		 *     are five callbacks added, preCallback() gets called five times whenever
		 *     _runCallbacksImmediately() is called.  An example usage of this is to make sure a relevant
		 *     variable is set to the appropriate value while each callback is running.  The preCallback
		 *     function will not be called before grouped callbacks.
		 */
		public function CallbackCollection(preCallback:Function = null)
		{
			this._preCallback = preCallback;
		}

		/**
		 * This is a list of CallbackEntry objects in the order they were created.
		 */
		private var _callbackEntries:Array = [];

		/**
		 * This is the function that gets called immediately before every callback.
		 */
		protected var _preCallback:Function = null;

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
		public static const DEFAULT_TRIGGER_COUNT:uint = 1;
		
		/**
		 * This value keeps track of how many times callbacks were triggered, and is returned by the public triggerCounter accessor function.
		 * The value starts at 1 to simplify code that compares the counter to a previous value.
		 * This allows the previous value to be set to zero so change will be detected the first time the counter is compared.
		 * This fixes potential bugs where the base case of zero is not considered.
		 */
		private var _triggerCounter:uint = DEFAULT_TRIGGER_COUNT;
		
		public final function addImmediateCallback(relevantContext:Object, callback:Function, runCallbackNow:Boolean = false, alwaysCallLast:Boolean = false):void
		{
			if (callback == null)
				return;
			
			// remove the callback if it was previously added
			removeCallback(relevantContext, callback);
			
			var entry:CallbackEntry = new CallbackEntry(relevantContext, callback);
			if (alwaysCallLast)
				entry.schedule = 1;
			_callbackEntries.push(entry);

			// run callback now if requested
			if (runCallbackNow)
			{
				// increase the recursion count while the function is running
				entry.recursionCount++;
				callback.apply(relevantContext || callback['this']);
				entry.recursionCount--;
			}
		}

		public final function triggerCallbacks():void
		{
			if (WeaveAPI.debugAsyncStack)
				_lastTriggerStackTrace = new Error(STACK_TRACE_TRIGGER);
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
					
					var entry:CallbackEntry = _callbackEntries[i];
					// if we haven't reached the matching schedule yet, skip this callback
					if (entry.schedule != schedule)
						continue;
					// Remove the entry if the context was disposed by SessionManager.
					var shouldRemoveEntry:Boolean;
					if (entry.callback == null)
						shouldRemoveEntry = true;
					else if (entry.context is CallbackCollection) // special case
						shouldRemoveEntry = (entry.context as CallbackCollection)._wasDisposed;
					else
						shouldRemoveEntry = WeaveAPI.SessionManager.objectWasDisposed(entry.context);
					if (shouldRemoveEntry)
					{
						Weave.dispose(entry);
						// remove the empty callback reference from the list
						var removed:Array = _callbackEntries.splice(i--, 1); // decrease i because remaining entries have shifted
						if (WeaveAPI.debugAsyncStack)
							_oldEntries = _oldEntries ? _oldEntries.concat(removed) : removed;
						continue;
					}
					// if _preCallback is specified, we don't want to limit recursion because that would cause a loss of information.
					if (entry.recursionCount == 0 || _preCallback != null)
					{
						entry.recursionCount++; // increase count to signal that we are currently running this callback.
						
						if (_preCallback != null)
							_preCallback.apply(this, preCallbackParams);
						
						entry.callback.apply(entry.context || entry.callback['this']);
						
						entry.recursionCount--; // decrease count because the callback finished.
					}
				}
			}

			// This flag is now set to true in case this function was called recursively.  This causes the outer call to exit its loop.
			_runCallbacksCompleted = true;
		}
		
		public final function removeCallback(relevantContext:Object, callback:Function):void
		{
			// if the callback was added as a grouped callback, we need to remove the trigger function
			GroupedCallbackEntry.removeGroupedCallback(this, relevantContext, callback);
			
			// find the matching CallbackEntry, if any
			for (var outerLoop:int = 0; outerLoop < 2; outerLoop++)
			{
				var entries:Array = outerLoop == 0 ? _callbackEntries : _disposeCallbackEntries;
				for (var index:int = 0; index < entries.length; index++)
				{
					var entry:CallbackEntry = entries[index];
					if (entry.callback === callback && entry.context === relevantContext)
					{
						// Remove the callback by setting the function pointer to null.
						// This is done instead of removing the entry because we may be looping over the _callbackEntries Array right now.
						Weave.dispose(entry);
					}
				}
			}
		}
		
		public final function get triggerCounter():uint
		{
			return _triggerCounter;
		}
		
		public final function get callbacksAreDelayed():Boolean
		{
			return _delayCount > 0
		}
		
		public final function delayCallbacks():void
		{
			_delayCount++;
		}

		public final function resumeCallbacks():void
		{
			if (_delayCount > 0)
				_delayCount--;

			if (_delayCount == 0)
			{
				if (_runCallbacksIsPending)
					triggerCallbacks();
				if (_wasDisposed)
					runDisposeCallbacks();
			}
		}
		
		public function addDisposeCallback(relevantContext:Object, callback:Function, allowDelay:Boolean = false):void
		{
			var entry:CallbackEntry;
			
			// don't do anything if the dispose callback was already added
			for each (entry in _disposeCallbackEntries)
				if (entry.callback === callback && entry.context === relevantContext)
					return;
			
			entry = new CallbackEntry(relevantContext, callback);
			if (allowDelay)
				entry.schedule = 1;
			_disposeCallbackEntries.push(entry);
		}
		
		/**
		 * A list of CallbackEntry objects for when dispose() is called.
		 */		
		private var _disposeCallbackEntries:Array = [];

		public function dispose():void
		{
			// remove all callbacks
			var entry:CallbackEntry;
			if (WeaveAPI.debugAsyncStack)
				_oldEntries = _oldEntries ? _oldEntries.concat(_callbackEntries) : _callbackEntries.concat();
			for each (entry in _callbackEntries)
				Weave.dispose(entry);
			_callbackEntries.length = 0;
			_wasDisposed = true;
			runDisposeCallbacks();
		}
		
		private function runDisposeCallbacks():void
		{
			// run & remove dispose callbacks
			for each (var entry:CallbackEntry in _disposeCallbackEntries)
			{
				if (entry.schedule > 0 && _delayCount > 0)
					continue;
				
				if (entry.callback != null && !WeaveAPI.SessionManager.objectWasDisposed(entry.context))
				{
					entry.callback.apply(entry.context || entry.callback['this']);
					Weave.dispose(entry);
				}
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

		public function addGroupedCallback(relevantContext:Object, groupedCallback:Function, triggerCallbackNow:Boolean = false, delayWhileBusy:Boolean = true):void
		{
			GroupedCallbackEntry.addGroupedCallback(this, relevantContext, groupedCallback, triggerCallbackNow, delayWhileBusy);
		}
		
		public static const STACK_TRACE_TRIGGER:String = "This is the stack trace from when the callbacks were last triggered.";
	}
}
