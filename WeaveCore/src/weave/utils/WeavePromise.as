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
	
	import weave.api.getCallbackCollection;
	import weave.api.objectWasDisposed;
	import weave.api.registerDisposableChild;
	import weave.api.reportError;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	
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
				// if no context is specified, make sure this promise stops functioning when it is disposed
				this.relevantContext = relevantContext || this;
			}
			
			if (relevantContext)
				registerDisposableChild(relevantContext, this);
			
			if (resolver != null)
				resolver(this.setResult, this.setError);
		}
		
		private static function noop(value:Object):Object { return value; }
		
		private var rootPromise:WeavePromise;
		protected var relevantContext:Object;
		private var result:* = undefined;
		private var error:* = undefined;
		private const handlers:Array = []; // array of Handler objects
		private const dependencies:Array = [];
		
		/**
		 * @return This WeavePromise
		 */
		public function setResult(result:Object):WeavePromise
		{
			if (objectWasDisposed(relevantContext))
				return this;
			
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
			if (objectWasDisposed(relevantContext))
				return this;
			
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
			if (dependencies.some(dependencyIsBusy))
				return;
			
			// stop if the promise has not been resolved yet
			if (result === undefined && error === undefined)
				return;
			
			// make sure thrown errors are seen
			if (handlers.length == 0 && error !== undefined)
				reportError(error);
			
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
			if (objectWasDisposed(relevantContext))
				return this;
			
			if (onFulfilled == null)
				onFulfilled = noop;
			if (onRejected == null)
				onRejected = noop;
			
			var next:WeavePromise = new WeavePromise(this);
			handlers.push(new Handler(onFulfilled, onRejected, next));
			
			// call new handler(s) if promise has already been resolved
			if (result !== undefined || error !== undefined)
			{
				// callLater will not call the function if the context was disposed
				WeaveAPI.StageUtils.callLater(relevantContext, callHandlers, [true]);
			}
			
			return next;
		}
		
		public function depend(...linkableObjects):WeavePromise
		{
			for each (var dependency:ILinkableObject in linkableObjects)
			{
				if (dependencies.indexOf(dependency) < 0)
					dependencies.push(dependency);
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
			dependencies.length = 0;
			handlers.length = 0;
		}
	}
}

import weave.utils.WeavePromise;

internal class Handler
{
	public var onFulfilled:Function;
	public var onRejected:Function;
	public var next:WeavePromise;
	
	public function Handler(onFulfilled:Function, onRejected:Function, next:WeavePromise)
	{
		this.next = next;
		this.onFulfilled = onFulfilled;
		this.onRejected = onRejected;
	}
	
	public function onResult(result:Object):void
	{
		wasCalled = true;
		try
		{
			next.setResult(onFulfilled(result));
		}
		catch (e:Error)
		{
			next.setError(e);
		}
	}
	
	public function onError(error:Object):void
	{
		wasCalled = true;
		try
		{
			next.setError(onRejected(error));
		}
		catch (e:Error)
		{
			next.setError(e);
		}
	}
	
	/**
	 * Used as a flag to indicate whether or not this handler has been called 
	 */
	public var wasCalled:Boolean = false;
}
