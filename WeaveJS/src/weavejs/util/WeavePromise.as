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

package weavejs.util
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.IDisposableObject;
	import weavejs.api.core.ILinkableObject;
	
	/**
	 * Use this when you need a Promise chain to depend on ILinkableObjects and resolve multiple times.
	 * 
	 * Adds support for <code>depend(...linkableObjects)</code>
	 */
	public class WeavePromise/*/<T>/*/ implements IDisposableObject
	{
		// true to conform to Promise spec, false to make Weave work correctly w/ busy status
		public static var _callNewHandlersSeparately:Boolean = false;
		
		/**
		 * @param relevantContext This parameter may be null.  If the relevantContext object is disposed, the promise will be disabled.
		 * @param resolver A function like function(resolve:Function, reject:Function):void which carries out the promise.
		 *                 If no resolver is given, setResult() or setError() should be called externally.
		 */
		public function WeavePromise(relevantContext:Object, resolver:/*/( resolve:(value?:T)=>void, reject:(error?:any)=>void ) => void/*/Function = null)
		{
			if (WeaveAPI.debugAsyncStack)
				stackTrace_created = new Error("WeavePromise created");
			
			if (relevantContext is WeavePromise)
			{
				// this is a child promise
				this.rootPromise = (relevantContext as WeavePromise).rootPromise;
				this.relevantContext = relevantContext = this.rootPromise.relevantContext;
			}
			else
			{
				// this is a new root promise
				this.rootPromise = this;
				// if no context is specified, make sure this promise stops functioning when it is disposed
				this.relevantContext = relevantContext || this;
			}
			
			if (relevantContext)
				Weave.disposableChild(relevantContext, this);
			
			if (resolver != null)
				resolver(this.setResult, this.setError);
		}
		
		private var stackTrace_created:Error;
		private var stackTrace_resolved:Error;
		
		private var rootPromise:WeavePromise;
		protected var relevantContext:Object;
		private var result:* = undefined;
		private var error:* = undefined;
		private const handlers:Array = []; // array of Handler objects
		private const dependencies:Array = [];
		
		/**
		 * @return This WeavePromise
		 */
		public function setResult(result:/*/T/*/Object):WeavePromise/*/<T>/*/
		{
			if (Weave.wasDisposed(relevantContext))
				return this;
			
			if (WeaveAPI.debugAsyncStack)
				stackTrace_resolved = new Error("WeavePromise resolved");
			
			this.result = undefined;
			this.error = undefined;
			
			var wp:WeavePromise = result as WeavePromise;
			if (wp)
			{
				wp._notify(this);
			}
			else if (isThenable(result))
			{
				result.then(setResult, setError);
			}
			else
			{
				this.result = result as Object;
				callHandlers();
			}
			
			return this;
		}
		
		public static function asPromise/*/<T>/*/(obj:Object):/*/Promise<T>/*/Object
		{
			var wp:WeavePromise = obj as WeavePromise;
			if (wp)
				return wp.getPromise();
			return isThenable(obj) ? obj : null;
		}
		
		public static function isThenable(obj:Object):Boolean
		{
			return obj && typeof obj.then === 'function';
		}
		
		public function getResult():/*/T/*/Object
		{
			return result;
		}
		
		/**
		 * @return This WeavePromise
		 */
		public function setError(error:Object):WeavePromise/*/<T>/*/
		{
			if (Weave.wasDisposed(relevantContext))
				return this;
			
			if (WeaveAPI.debugAsyncStack)
				stackTrace_resolved = new Error("WeavePromise resolved");
			
			this.result = undefined;
			this.error = error as Object;
			
			callHandlers();
			
			return this;
		}
		
		public function getError():Object
		{
			return error;
		}
		
		private function callHandlers(newHandlersOnly:Boolean = false):void
		{
			// stop if depenencies are busy because we will call handlers when they become unbusy
			if (dependencies.some(Weave.isBusy))
				return;
			
			// stop if the promise has not been resolved yet
			if (result === undefined && error === undefined)
				return;
			
			// make sure thrown errors are seen
			if (handlers.length == 0 && error !== undefined)
				JS.error(error);
			
			var shouldCallLater:Boolean = false;
			
			for (var i:int = 0; i < handlers.length; i++)
			{
				var handler:WeavePromiseHandler = handlers[i];
				
				if (_callNewHandlersSeparately)
				{
					if (newHandlersOnly != handler.isNew)
					{
						shouldCallLater = handler.isNew;
						continue;
					}
				}
				else
				{
					if (newHandlersOnly && !handler.isNew)
					{
						continue;
					}
				}
				
				if (result !== undefined)
					handler.onResult(result);
				else if (error !== undefined)
					handler.onError(error);
			}
			
			if (shouldCallLater)
				WeaveAPI.Scheduler.callLater(relevantContext, callHandlers, [true]);
		}
		
		public function then/*/<U>/*/(onFulfilled:/*/(value:T) => (U|Promise<U>|WeavePromise<U>)/*/Function = null, onRejected:/*/(error:any) => (U|Promise<U>|WeavePromise<U>)/*/Function = null):WeavePromise/*/<U>/*/
		{
			if (Weave.wasDisposed(relevantContext))
				return this;
			
			var next:WeavePromise = new WeavePromise(this);
			handlers.push(new WeavePromiseHandler(onFulfilled, onRejected, next));
			
			// call new handler(s) if promise has already been resolved
			if (result !== undefined || error !== undefined)
				WeaveAPI.Scheduler.callLater(relevantContext, callHandlers, [true]);
			
			return next;
		}
		
		private function _notify(next:WeavePromise):void
		{
			if (Weave.wasDisposed(relevantContext))
				return;
			
			// avoid adding duplicate handlers
			for each (var handler:WeavePromiseHandler in handlers)
				if (handler.next === next)
					return;
			
			handlers.push(new WeavePromiseHandler(null, null, next));
			
			// resolve next immediately if this promise has been resolved
			if (result !== undefined)
				next.setResult(result);
			else if (error !== undefined)
				next.setError(error);
		}
		
		public function depend(...linkableObjects):WeavePromise/*/<T>/*/
		{
			for each (var dependency:ILinkableObject in linkableObjects)
			{
				if (dependencies.indexOf(dependency) < 0)
					dependencies.push(dependency);
				Weave.getCallbacks(dependency).addGroupedCallback(relevantContext, callHandlers, true);
			}
			return this;
		}
		
		public function getPromise():/*/Promise<T>/*/Object
		{
			var var_resolve:Function, var_reject:Function;
			var promise:Object = new JS.Promise(function(resolve:Function, reject:Function):void {
				var_resolve = resolve;
				var_reject = reject;
			});
			promise._WeavePromise = this; // for debugging
			then(var_resolve, var_reject);
			return promise;
		}
		
		public function dispose():void
		{
			Weave.dispose(this);
			dependencies.length = 0;
			handlers.length = 0;
		}
	}
}
