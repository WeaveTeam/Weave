/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.utils
{
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.binding.utils.BindingUtils;
	
	import weave.api.objectWasDisposed;
	
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
				if (objectWasDisposed(relevantContext))
				{
					if (_timer)
					{
						_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, callback_apply);
						_timer.stop();
					}
					_timer = null;
					_delayedThisArg = null;
					_delayedParams = null;
					relevantContext = null;
					callback = null;
					callback_apply = null;
					delayedCallback = null;
				}
				else
				{
					// call the original callback with the params passed to delayedCallback
					callback.apply(_delayedThisArg, passDelayedParameters ? _delayedParams : null);
				}
			};
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, callback_apply);
			
			return delayedCallback;
		}
		
		private static const _throttledCallbacks:Dictionary = new Dictionary();
		
		public static function callLaterThrottled(relevantContext:Object, callback:Function, params:Array = null, delay:int = 500):void
		{
			if (!_throttledCallbacks[callback])
				_throttledCallbacks[callback] = generateDelayedCallback(relevantContext, callback, delay, true);
			(_throttledCallbacks[callback] as Function).apply(null, params);
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