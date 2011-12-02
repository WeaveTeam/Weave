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
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	
	/**
	 * Static functions related to event callbacks.
	 * @author adufilie
	 */
	public class EventUtils
	{
		/**
		 * This maps a bindable parent to a Dictionary.
		 * That Dictionary maps a callback function to a change watcher that calls it.
		 */
		private static const bindableParentCallbackMap:Dictionary = new Dictionary(true); // weak keys = GC-friendly
		
		public static function addBindCallback(bindableParent:Object, bindablePropertyName:String, callback:Function, callbackParameters:Array = null):void
		{
			removeBindCallback(bindableParent, bindablePropertyName, callback);
			
			var callbackMap:Object = bindableParentCallbackMap[bindableParent];
			if (callbackMap == null)
				bindableParentCallbackMap[bindableParent] = callbackMap = new Dictionary(); // strong references to keys because they will be inline functions
			callbackMap[callback] = BindingUtils.bindSetter(
					function(value:*):void{ callback.apply(null, callbackParameters); },
					bindableParent, bindablePropertyName
				);
		}
		
		public static function removeBindCallback(bindableParent:Object, bindablePropertyName:String, callback:Function):void
		{
			var callbackMap:Object = bindableParentCallbackMap[bindableParent];
			if (callbackMap == null)
				return;
			var cw:ChangeWatcher = callbackMap[callback] as ChangeWatcher;
			if (cw == null)
				return;
			cw.unwatch();
			delete callbackMap[callback];
		}
		
		public static function addEventCallback(eventDispatcher:Object, event:String, callback:Function, params:Array = null):void
		{
			eventDispatcher.addEventListener(event, function(event:Event):void { callback.apply(null, params); } );
		}
		
		public static function addDelayedCallback(eventDispatcher:Object, event:String, callback:Function, delay:int = 500):void
		{
			eventDispatcher.addEventListener(event, generateDelayedCallback(callback, [], delay));
		}
		
		/**
		 * This function generates a delayed version of a callback.
		 * @param callback The callback function
		 * @param callbackParams If this is specified, parameters passed to the generated wrapper function will be ignored and these parameters will be used instead when calling the callback.
		 * @param delay The number of milliseconds to delay before running the callback.
		 * @return A wrapper around the callback that remembers the parameters and delays calling the original callback.
		 */
		public static function generateDelayedCallback(callback:Function, callbackParams:Array = null, delay:int = 500):Function
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
				callback.apply(_delayedThisArg, callbackParams || _delayedParams);
			};
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, callback_apply);
			
			return delayedCallback;
		}
	}
}
