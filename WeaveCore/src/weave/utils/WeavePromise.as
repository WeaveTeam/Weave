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
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.apache.flex.promises.Promise;
	import org.apache.flex.promises.enums.PromiseState;
	import org.apache.flex.promises.vo.Handler;
	
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.objectWasDisposed;
	
	/**
	 * Use this when you need a Promise chain to depend on ILinkableObjects and resolve multiple times.
	 * 
	 * Adds support for <code>depend(...linkableObjects)</code>
	 */
	public class WeavePromise extends Promise
	{
		private static function _noop(..._):* { }
		
		public function WeavePromise(relevantContext:Object, resolver:Function = null)
		{
			super(resolver as Function || _noop);
			
			if (resolver == null)
			{
				state_ = PromiseState.FULFILLED;
				value_ = relevantContext;
			}
			
			this.rootPromise = relevantContext as WeavePromise || this;
			this.relevantContext = relevantContext is WeavePromise ? rootPromise.relevantContext : relevantContext;
			
			WeaveAPI.ProgressIndicator.addTask(this.rootPromise, this.relevantContext as ILinkableObject);
		}
		
		protected var rootPromise:WeavePromise;
		protected var relevantContext:Object;
		protected const dependencies:Array = [];
		
		/**
		 * Changed for Weave so handlers can be called more than once.
		 */
		override protected function handle_(handler:Handler):void
		{
			if (handlers_.indexOf(handler) < 0)
				handlers_.push(handler);
			
			if (state_ === PromiseState.PENDING || dependencies.some(dependencyIsBusy))
				return;
			
			//TODO - super.handle_() does not follow spec - should be async
			super.handle_(handler);
		}
		
		/**
		 * Changed for Weave so handlers can be called more than once.
		 */
		override protected function processHandlers_():void
		{
			if (state_ === PromiseState.PENDING || dependencies.some(dependencyIsBusy))
			{
				if (handlers_.length)
				{
					WeaveAPI.ProgressIndicator.addTask(this.rootPromise, this.relevantContext as ILinkableObject);
				}
				return;
			}

			if (handlers_.length == 0)
			{
				WeaveAPI.ProgressIndicator.removeTask(rootPromise);
			}
			
			if (objectWasDisposed(relevantContext))
				return;
			
			for each (var handler:Handler in handlers_)
				handle_(handler);
		}
		
		public function depend(...linkableObjects):Promise
		{
			if (linkableObjects.length)
			{
				WeaveAPI.ProgressIndicator.addTask(rootPromise, relevantContext as ILinkableObject);
			}
			for each (var dependency:ILinkableObject in linkableObjects)
			{
				getCallbackCollection(dependency).addGroupedCallback(relevantContext, processHandlers_, true);
			}
			return this;
		}
		
		private function dependencyIsBusy(dependency:ILinkableObject, i:int, a:Array):Boolean
		{
			return WeaveAPI.SessionManager.linkableObjectIsBusy(dependency);
		}
		
		override protected function newPromise(resolver:Function):Promise
		{
			return new WeavePromise(this.rootPromise, resolver);
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
	}
}
