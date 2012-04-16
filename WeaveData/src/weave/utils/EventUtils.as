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

package weave.utils
{
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.newDisposableChild;
	import weave.api.objectWasDisposed;
	import weave.core.CallbackCollection;
	
	/**
	 * Static functions related to event callbacks.
	 * @author adufilie
	 */
	public class EventUtils
	{
		/**
		 * This function sets up a two-way binding.  Upon calling this function, the value from the primary host's property will be copied to the secondary host's property.
		 * @param primaryHost The first host.
		 * @param primaryProperty The name of the property on the first host.
		 * @param secondaryHost The second host.
		 * @param secondaryProperty The name of a property on the second host.
		 */		
		public static function doubleBind(primaryHost:Object, primaryProperty:String, secondaryHost:Object, secondaryProperty:String):void
		{
			BindingUtils.bindSetter(function(primaryValue:Object):void {
				if (secondaryHost[secondaryProperty] !== primaryValue)
					secondaryHost[secondaryProperty] = primaryValue;
			}, primaryHost, primaryProperty);
			BindingUtils.bindSetter(function(secondaryValue:Object):void {
				if (primaryHost[primaryProperty] !== secondaryValue)
					primaryHost[primaryProperty] = secondaryValue;
			}, secondaryHost, secondaryProperty);
		}
		
		public static function addDelayedEventCallback(eventDispatcher:Object, event:String, callback:Function, delay:int = 500):void
		{
			eventDispatcher.addEventListener(event, generateDelayedCallback(eventDispatcher, callback, delay));
		}
		
		/**
		 * This function generates a delayed version of a callback.
		 * @param relevantContext If this is not null, then the callback will be removed when the relevantContext object is disposed via SessionManager.dispose().  This parameter is typically a 'this' pointer.
		 * @param callback The callback function.
		 * @param delay The number of milliseconds to delay before running the callback.
		 * @param passDelayedParameters If this is set to true, the most recent parameters passed to the delayed callback will be passed to the original callback when it is called.  If this is set to false, no parameters will be passed to the original callback.
		 * @return A wrapper around the callback that remembers the parameters and delays calling the original callback.
		 */
		public static function generateDelayedCallback(relevantContext:Object, callback:Function, delay:int = 500, passDelayedParameters:Boolean = false):Function
		{
			var _timer:Timer = new Timer(delay, 1);
			var _delayedThisArg:Object;
			var _delayedParams:Array;
			// this function gets called immediately and delays calling the original callback
			var delayedCallback:Function = function(...params):void
			{
				_timer.stop();
				_timer.start();
				// remember the params passed to this delayedCallback
				_delayedThisArg = this;
				_delayedParams = params;
			};
			// this function gets called when the timer completes
			var callback_apply:Function = function(..._):void
			{
				// call the original callback with the params passed to delayedCallback
				if (!objectWasDisposed(relevantContext))
					callback.apply(_delayedThisArg, passDelayedParameters ? _delayedParams : null);
			};
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, callback_apply);
			
			return delayedCallback;
		}
		
		/*
		private static const bindCallbackCollectionCache:Dictionary2D = new Dictionary2D(true, true); // (bindableParent, bindablePropertyName) -> BindCallbackManager
		public static function getBindablePropertyCallbackCollection(bindableParent:Object, bindablePropertyName:String):ICallbackCollection
		{
			var manager:BindCallbackManager = bindCallbackCollectionCache.get(bindableParent, bindablePropertyName);
			if (!manager)
			{
				manager = new BindCallbackManager(bindableParent, bindablePropertyName);
				bindCallbackCollectionCache.set(bindableParent, bindablePropertyName, manager);
			}
			return manager.callbackCollection;
		}
		
		private static const eventCallbackCollectionCache:Dictionary2D = new Dictionary2D(true, true); // (dispatcher, eventType) -> ICallbackCollection
		public static function getEventCallbackCollection(dispatcher:IEventDispatcher, eventType:String):ICallbackCollection
		{
			var cc:ICallbackCollection = eventCallbackCollectionCache.get(dispatcher, eventType);
			if (!cc)
			{
				cc = newDisposableChild(dispatcher, CallbackCollection);
				bindCallbackCollectionCache.set(dispatcher, eventType, cc);
				dispatcher.addEventListener(eventType, function(event:Event):void { cc.triggerCallbacks(); });
			}
			return cc;
		}
		*/
	}
}
/*
import mx.binding.utils.BindingUtils;
import mx.binding.utils.ChangeWatcher;

import weave.api.core.ICallbackCollection;
import weave.api.newDisposableChild;
import weave.core.CallbackCollection;

internal class BindCallbackManager
{
	public function BindCallbackManager(bindableParent:Object, bindablePropertyName:String)
	{
		callbackCollection = newDisposableChild(bindableParent, CallbackCollection);
		var trigger:Function = function(value:*):void { callbackCollection.triggerCallbacks(); };
		changeWatcher = BindingUtils.bindSetter(trigger, bindableParent, bindablePropertyName);
	}
	
	public var changeWatcher:ChangeWatcher;
	public var callbackCollection:ICallbackCollection;
}
*/