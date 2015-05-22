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
	import mx.core.mx_internal;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.objectWasDisposed;
	import weave.api.registerDisposableChild;
	
	/**
	 * Use this when you need a Promise chain to depend on ILinkableObjects and resolve multiple times.
	 * 
	 * Adds support for <code>depend(...linkableObjects)</code>
	 */
	public class WeavePromise implements IDisposableObject
	{
		/**
		 * @param relevantContext This parameter may be null.  If the relevantContext object is disposed, the promise will be disabled.
		 * @param resolver A function like function(resolve:Function, reject:Function):void which carries out the promise
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
				
				// if resolver is not specified, immediately set the result of the root promise equal to the relevantContext
				if (resolver == null)
					this.setResult(this.relevantContext);
			}
			
			if (relevantContext)
				registerDisposableChild(relevantContext, this);
			
			if (resolver != null)
			{
				setBusy(true);
				resolver(this.setResult, this.setError);
			}
		}
		
		private static function noop(value:Object):Object { return value; }
		
		private var rootPromise:WeavePromise;
		private var relevantContext:Object;
		private var result:* = undefined;
		private var error:* = undefined;
		private const handlers:Array = []; // array of Handler objects
		private const dependencies:Array = [];
		
		public function setResult(result:Object):void
		{
			if (objectWasDisposed(relevantContext))
			{
				setBusy(false);
				return;
			}
			
			this.result = undefined;
			this.error = undefined;
			
			if (result is AsyncToken)
			{
				(result as AsyncToken).addResponder(new AsyncResponder(
					function(event:ResultEvent, token:Object):void {
						setResult(event.result);
					},
					function(event:FaultEvent, token:Object):void {
						setError(event.fault);
					}
				));
			}
			else if (result is WeavePromise)
			{
				(result as WeavePromise).then(setResult, setError);
			}
			else
			{
				this.result = result;
				callHandlers();
			}
		}
		
		public function getResult():Object
		{
			return result;
		}
		
		public function setError(error:Object):void
		{
			if (objectWasDisposed(relevantContext))
			{
				setBusy(false);
				return;
			}
			
			this.result = undefined;
			this.error = error;
			
			callHandlers();
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
			if (dependencies.some(dependencyIsBusy))
			{
				if (handlers.length)
					setBusy(true);
				return;
			}
			
			// if there are no more handlers, remove the task
			if (handlers.length == 0)
				setBusy(false);
			
			if (objectWasDisposed(relevantContext))
			{
				setBusy(false);
				return;
			}
			
			for (var i:int = 0; i < handlers.length; i++)
			{
				var handler:Handler = handlers[i];
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
			var handler:Handler = new Handler(
				function(result:Object):void {
					handler.wasCalled = true;
					try
					{
						next.setResult(onFulfilled(result));
					}
					catch (e:Error)
					{
						handler.onError(e);
					}
				},
				function(error:Object):void {
					handler.wasCalled = true;
					try
					{
						next.setError(onRejected(error));
					}
					catch (e:Error)
					{
						next.setError(e);
					}
				}
			);
			handlers.push(handler);
			
			if (result !== undefined || error !== undefined)
			{
				// callLater will not call the function if the context was disposed
				WeaveAPI.StageUtils.callLater(relevantContext, callHandlers, [true]);
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
				getCallbackCollection(dependency).addGroupedCallback(relevantContext, callHandlers, true);
			}
			return this;
		}
		
		private static function dependencyIsBusy(dependency:ILinkableObject, i:int, a:Array):Boolean
		{
			return WeaveAPI.SessionManager.linkableObjectIsBusy(dependency);
		}
		
		public function getAsyncToken():AsyncToken
		{
			var asyncToken:AsyncToken = new AsyncToken();
			then(
				function(result:*):void
				{
					asyncToken.mx_internal::applyResult(ResultEvent.createEvent(result, asyncToken));
				},
				function(error:*):void
				{
					var fault:Fault = new Fault("Error", "Broken promise");
					fault.content = error;
					asyncToken.mx_internal::applyFault(FaultEvent.createEvent(fault, asyncToken));
				}
			);
			return asyncToken;
		}
		
		public function dispose():void
		{
			handlers.length = 0;
			setBusy(false);
		}
	}
}

internal class Handler
{
	public function Handler(onResult:Function, onError:Function)
	{
		this.onResult = onResult;
		this.onError = onError;
	}
	public var onResult:Function;
	public var onError:Function;
	/**
	 * Used as a flag to indicate whether or not this handler has been called 
	 */
	public var wasCalled:Boolean = false;
}
