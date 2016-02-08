/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.core
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.IDisposableObject;

	/**
	 * @private
	 */
	internal class CallbackEntry implements IDisposableObject
	{
		/**
		 * @param context The "this" argument for the callback function. When the context is disposed, this callback entry will be disposed.
		 * @param callback The callback function.
		 */
		public function CallbackEntry(context:Object, callback:Function)
		{
			this.context = context;
			this.callback = callback;
			
			if (context)
				WeaveAPI.SessionManager.registerDisposableChild(context, this);
			
			if (WeaveAPI.debugAsyncStack)
				addCallback_stackTrace = new Error(STACK_TRACE_ADD);
		}
		
		/**
		 * This is the context in which the callback function is relevant.
		 * When the context is disposed, the callback should not be called anymore.
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
		 * Note that it IS possible for this to go above 1 if an external JavaScript popup interrupts our code.
		 */
		public var recursionCount:uint = 0;
		/**
		 * This is 0 if the callback was added with alwaysCallLast=false, or 1 for alwaysCallLast=true
		 */	
		public var schedule:int = 0;
		/**
		 * This is a stack trace from when the callback was added.
		 */
		public var addCallback_stackTrace:Error = null;
		/**
		 * This is a stack trace from when the callback was removed.
		 */
		public var removeCallback_stackTrace:Error = null;
		
		/**
		 * Call this when the callback entry is no longer needed.
		 */
		public function dispose():void
		{
			if (WeaveAPI.debugAsyncStack && callback != null)
				removeCallback_stackTrace = new Error(STACK_TRACE_REMOVE);
			
			context = null;
			callback = null;
		}
		
		public static const STACK_TRACE_ADD:String = "This is the stack trace from when the callback was added.";
		public static const STACK_TRACE_REMOVE:String = "This is the stack trace from when the callback was removed.";
	}
}
