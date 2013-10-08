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
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	
	/**
	 * This is used to juggle a single callback between linkable object targets.
	 * The callback will be triggered automatically when the target changes, even when the target becomes null.
	 * @see weave.api.#juggleImmediateCallback()
	 * @see weave.api.#juggleGroupedCallback()
	 * @author adufilie
	 */
	public class CallbackJuggler implements IDisposableObject
	{
		/**
		 * @param relevantContext The owner of this CallbackJuggler.
		 * @param callback The callback function.
		 * @param useGroupedCallback If this is set to true, a grouped callback will be used instead of an immediate callback.
		 * @see weave.api.core.ICallbackCollection#addImmediateCallback() 
		 * @see weave.api.core.ICallbackCollection#addGroupedCallback() 
		 */
		public function CallbackJuggler(relevantContext:Object, callback:Function, useGroupedCallback:Boolean)
		{
			WeaveAPI.SessionManager.registerDisposableChild(relevantContext, this);
			if (useGroupedCallback)
				_callbacks.addGroupedCallback(null, callback);
			else
				_callbacks.addImmediateCallback(null, callback);
		}
		
		private var _callbacks:ICallbackCollection = new CallbackCollection();
		private var _target:ILinkableObject;
		
		/**
		 * This is the linkable object to which the callback has been added.
		 */		
		public function get target():ILinkableObject
		{
			return _target;
		}
		
		/**
		 * This sets the new target to which the callback should be juggled.
		 * The callback will be called immediately if the new target is different from the old one.
		 */
		public function set target(newTarget:ILinkableObject):void
		{
			// do nothing if the targets are the same.
			if (_target == newTarget)
				return;
			
			if (!_callbacks)
				throw new Error("dispose() was already called on this object.");
			
			var tc:ICallbackCollection;
			
			// remove callbacks from old target
			if (_target)
			{
				tc = WeaveAPI.SessionManager.getCallbackCollection(_target);
				tc.removeCallback(_callbacks.triggerCallbacks);
				tc.removeCallback(_handleTargetDispose);
			}
			
			_target = newTarget;
			
			// add callbacks to new target
			if (_target)
			{
				tc = WeaveAPI.SessionManager.getCallbackCollection(_target);
				tc.addImmediateCallback(_callbacks, _callbacks.triggerCallbacks);
				tc.addDisposeCallback(_callbacks, _handleTargetDispose);
			}
			
			_callbacks.triggerCallbacks();
		}
		
		private function _handleTargetDispose():void
		{
			_target = null;
			_callbacks.triggerCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			_callbacks.delayCallbacks();
			target = null; // removes callbacks
			WeaveAPI.SessionManager.disposeObjects(_callbacks);
			_callbacks = null;
		}
	}
}
