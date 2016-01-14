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
	public class WeavePromise implements IDisposableObject
	{
		/**
		 * @param relevantContext This parameter may be null.  If the relevantContext object is disposed, the promise will be disabled.
		 * @param resolver A function like function(resolve:Function, reject:Function):void which carries out the promise.
		 *                 If no resolver is given, setResult() or setError() should be called externally.
		 */
		public function WeavePromise(relevantContext:Object, resolver:Function = null)
		{
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
				this.relevantContext = relevantContext;
			}
			
			if (relevantContext)
				Weave.disposableChild(relevantContext, this);
			
			if (resolver != null)
			{
				setBusy(true);
				resolver(this.setResult, this.setError);
			}
		}
		
		private static function noop(value:Object):Object { return value; }
		
		private var rootPromise:WeavePromise;
		protected var relevantContext:Object;
		private var result:* = undefined;
		private var error:* = undefined;
		private var handlers:Array = []; // array of Handler objects
		private var dependencies:Array = [];
		
		/**
		 * @return This WeavePromise
		 */
		public function setResult(result:Object):WeavePromise
		{
			if (Weave.wasDisposed(relevantContext))
			{
				setBusy(false);
				return this;
			}
			
			this.result = undefined;
			this.error = undefined;
			
			if (result is JS.Promise)
			{
				result.then(setResult, setError);
			}
			else if (result is WeavePromise)
			{
				(result as WeavePromise).then(setResult, setError);
			}
			else
			{
				this.result = result as Object;
				callHandlers();
			}
			
			return this;
		}
		
		public function getResult():Object
		{
			return result;
		}
		
		/**
		 * @return This WeavePromise
		 */
		public function setError(error:Object):WeavePromise
		{
			if (Weave.wasDisposed(relevantContext))
			{
				setBusy(false);
				return this;
			}
			
			this.result = undefined;
			this.error = error as Object;
			
			callHandlers();
			
			return this;
		}
		
		public function getError():Object
		{
			return error;
		}
		
		private function setBusy(busy:Boolean):void
		{
			if (busy)
			{
				WeaveAPI.ProgressIndicator.addTask(rootPromise, relevantContext as ILinkableObject);
			}
			else
			{
				WeaveAPI.ProgressIndicator.removeTask(rootPromise);
			}
		}
		
		private function callHandlers(newHandlersOnly:Boolean = false):void
		{
			if (dependencies.some(Weave.isBusy))
			{
				if (handlers.length)
					setBusy(true);
				return;
			}
			
			// if there are no more handlers, remove the task
			if (handlers.length == 0)
				setBusy(false);
			
			if (Weave.wasDisposed(relevantContext))
			{
				setBusy(false);
				return;
			}
			
			for (var i:int = 0; i < handlers.length; i++)
			{
				var handler:WeavePromiseHandler = handlers[i];
				if (newHandlersOnly && handler.wasCalled)
					continue;
				if (result !== undefined)
					handler.onResult(result);
				else if (error !== undefined)
					handler.onError(error);
			}
		}
		
		public function then(onFulfilled:Function = null, onRejected:Function = null):WeavePromise
		{
			if (onFulfilled == null)
				onFulfilled = noop;
			if (onRejected == null)
				onRejected = noop;
			
			var next:WeavePromise = new WeavePromise(this);
			next.result = undefined;
			handlers.push(new WeavePromiseHandler(onFulfilled, onRejected, next));
			
			if (result !== undefined || error !== undefined)
			{
				// callLater will not call the function if the context was disposed
				WeaveAPI.Scheduler.callLater(relevantContext, callHandlers, [true]);
				setBusy(true);
			}
			
			return next;
		}
		
		public function depend(...linkableObjects):WeavePromise
		{
			if (linkableObjects.length)
			{
				setBusy(true);
			}
			for each (var dependency:ILinkableObject in linkableObjects)
			{
				Weave.getCallbacks(dependency).addGroupedCallback(relevantContext, callHandlers, true);
			}
			return this;
		}
		
		public function getPromise():Object
		{
			var var_resolve:Function, var_reject:Function;
			var promise:Object = new JS.Promise(function(resolve:Function, reject:Function):void {
				var_resolve = resolve;
				var_reject = reject;
			});
			then(var_resolve, var_reject);
			return promise;
		}
		
		public function dispose():void
		{
			handlers.length = 0;
			setBusy(false);
		}
	}
}
