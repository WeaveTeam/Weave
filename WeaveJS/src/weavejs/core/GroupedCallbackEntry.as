/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.core
{
	import weavejs.api.core.ICallbackCollection;
	import weavejs.utils.JS;

	/**
	 * @private
	 */
	internal class GroupedCallbackEntry extends CallbackEntry
	{
		public static function addGroupedCallback(callbackCollection:ICallbackCollection, relevantContext:Object, groupedCallback:Function, triggerCallbackNow:Boolean):void
		{
			// get (or create) the shared entry for the groupedCallback
			var entry:GroupedCallbackEntry = _entryLookup.get(groupedCallback);
			if (!entry)
				_entryLookup.set(groupedCallback, entry = new GroupedCallbackEntry(groupedCallback));
			
			// context shouldn't be null because we use it to determine when to clean up the GroupedCallbackEntry.
			if (relevantContext == null)
				relevantContext = callbackCollection;
			
			// add this context to the list of relevant contexts
			(entry.context as Array).push(relevantContext);
			
			// make sure the actual function is not already added as a callback.
			callbackCollection.removeCallback(groupedCallback);
			
			// add the trigger function as a callback
			// The relevantContext parameter is set to null for entry.trigger so the same callback can be added multiple times to the same
			// target using different contexts without having the side effect of losing the callback when one of those contexts is disposed.
			// The entry.trigger function will be removed once all contexts are disposed.
			callbackCollection.addImmediateCallback(null, entry.trigger, triggerCallbackNow);
		}
		
		public static function removeGroupedCallback(callbackCollection:ICallbackCollection, groupedCallback:Function):void
		{
			// remove the trigger function as a callback
			var entry:GroupedCallbackEntry = _entryLookup.get(groupedCallback);
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
					entry = _triggeredEntries[i];
					entry.handleGroupedCallback();
				}
				
				// after all grouped callbacks have been handled once, run those which were triggered recursively and allow them to call other grouped callbacks immediately.
				_handlingRecursiveGroupedCallbacks = true;
				{
					// handle grouped callbacks that were triggered recursively
					for (i = 0; i < _triggeredEntries.length; i++)
					{
						entry = _triggeredEntries[i];
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
		private static var _entryLookup:Object = new JS.Map();
		
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
				_initialized = JS.setInterval(_handleGroupedCallbacks, 0);
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
			// remove the contexts that have been disposed.
			for (var i:int = 0; i < allContexts.length; i++)
				if (Weave.wasDisposed(allContexts[i]))
					allContexts.splice(i--, 1);
			// if there are no more relevant contexts for this callback, don't run it.
			if (allContexts.length == 0)
			{
				dispose();
				_entryLookup['delete'](callback);
				return;
			}
			
			// avoid immediate recursion
			if (recursionCount == 0)
			{
				recursionCount++;
				callback.apply(allContexts[0]);
				recursionCount--;
			}
			// avoid delayed recursion
			triggeredAgain = false;
		}
	}
}
