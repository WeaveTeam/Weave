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
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.juggleGroupedCallback;
	import weave.api.juggleImmediateCallback;
	import weave.api.registerDisposableChild;
	import weave.utils.WeakReference;
	
	/**
	 * This is used to juggle a single callback between linkable object targets.
	 * 
	 * @author adufilie
	 */
	public class CallbackJuggler implements IDisposableObject
	{
		public function CallbackJuggler(relevantContext:Object, callback:Function, useGroupedCallback:Boolean)
		{
			registerDisposableChild(relevantContext, this);
			this.callback = callback;
			this.useGroupedCallback = useGroupedCallback;
		}
		
		private var callback:Function;
		private var useGroupedCallback:Boolean;
		private const targetRef:WeakReference = new WeakReference();
		
		/**
		 * This is the linkable object to which the callback has been added.
		 */		
		public function get target():ILinkableObject
		{
			if (targetRef.value && WeaveAPI.SessionManager.objectWasDisposed(targetRef.value))
				targetRef.value = null;
			return targetRef.value as ILinkableObject;
		}
		
		/**
		 * This sets the new target to which the callback should be juggled.
		 * The callback will be called if the new target is different from the old one.
		 */
		public function set target(newTarget:ILinkableObject):void
		{
			var oldTarget:ILinkableObject = targetRef.value as ILinkableObject;
			
			var change:Boolean;
			if (useGroupedCallback)
				change = juggleGroupedCallback(oldTarget, newTarget, this, callback, true);
			else
				change = juggleImmediateCallback(oldTarget, newTarget, this, callback);
			
			if (change)
			{
				targetRef.value = newTarget;
				if (!useGroupedCallback)
					callback();
			}
		}
		
		public function dispose():void
		{
			callback = null;
			targetRef.value = null;
		}
	}
}
