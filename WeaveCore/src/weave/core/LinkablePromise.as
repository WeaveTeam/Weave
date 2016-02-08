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

package weave.core
{
	import mx.core.mx_internal;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.registerLinkableChild;
	import weave.utils.WeavePromise;
	
	/**
	 * Use this class to build dependency trees involving asynchronous calls.
	 * When the callbacks of a LinkablePromise are triggered, a function will be invoked.
	 * If the function returns an AsyncToken, LinkablePromise's callbacks will be triggered again when a ResultEvent or FaultEvent is received from the AsyncToken.
	 * Dependency trees can be built using newLinkableChild() and registerLinkableChild().
	 * 
	 * @see weave.api.core.ISessionManager#newLinkableChild()
	 * @see weave.api.core.ISessionManager#registerLinkableChild()
	 * @author adufilie
	 */
	public class LinkablePromise implements ILinkableObject, IDisposableObject
	{
		/**
		 * Creates a LinkablePromise from an iterative task function.
		 * @param initialize A function that should be called prior to starting the iterativeTask.
		 * @param iterativeTask A function which is designed to be called repeatedly across multiple frames until it returns a value of 1.
		 * @param priority The task priority, which should be one of the static constants in WeaveAPI.
		 * @param description A description of the task as a String, or a function to call which returns a descriptive string.
		 * Such a function has the signature function():String.
		 * @see weave.api.core.IStageUtils#startTask()
		 */
		public static function fromIterativeTask(initialize:Function, iterativeTask:Function, priority:uint, description:* = null, validateNow:Boolean = false):LinkablePromise
		{
			var promise:LinkablePromise;
			var asyncToken:AsyncToken;
			
			function asyncStart():AsyncToken
			{
				if (initialize != null)
					initialize();
				WeaveAPI.StageUtils.startTask(promise, iterativeTask, priority, asyncComplete);
				return asyncToken = new AsyncToken();
			}
			
			function asyncComplete():void
			{
				asyncToken.mx_internal::applyResult(ResultEvent.createEvent(null, asyncToken));
			}
			
			return promise = new LinkablePromise(asyncStart, description, validateNow);
		}
		
		/**
		 * @param task A function to invoke, which must take zero parameters and may return an AsyncToken.
		 * @param description A description of the task as a String, or a function to call which returns a descriptive string.
		 * Such a function has the signature function():String.
		 */
		public function LinkablePromise(task:Function, description:* = null, validateNow:Boolean = false)
		{
			_task = task;
			_description = description;
			_callbackCollection = WeaveAPI.SessionManager.getCallbackCollection(this);
			_callbackCollection.addImmediateCallback(null, _immediateCallback);
			_callbackCollection.addGroupedCallback(null, _groupedCallback, validateNow);
			if (validateNow)
			{
				_lazy = false;
				_immediateCallback();
			}
		}
		
		private var _task:Function;
		private var _description:Object; /* Function or String */
		
		private var _callbackCollection:ICallbackCollection;
		private var _lazy:Boolean = true;
		private var _invalidated:Boolean = true;
		private var _asyncToken:AsyncToken;
		private var _selfTriggeredCount:uint = 0;
		private var _result:Object;
		private var _error:Object;
		
		/**
		 * The result of calling the invoke function.
		 * When this value is accessed, validate() will be called.
		 */
		public function get result():Object
		{
			validate();
			return _result;
		}
		
		/**
		 * The error that occurred calling the invoke function.
		 * When this value is accessed, validate() will be called.
		 */
		public function get error():Object
		{
			validate();
			return _error;
		}
		
		/**
		 * If this LinkablePromise is set to lazy mode, this will switch it to non-lazy mode and automatically invoke the async task when necessary.
		 */
		public function validate():void
		{
			if (!_lazy)
				return;
			
			_lazy = false;
			
			if (_invalidated)
				_callbackCollection.triggerCallbacks();
		}
		
		private function _immediateCallback():void
		{
			// stop if self-triggered
			if (_callbackCollection.triggerCounter == _selfTriggeredCount)
				return;
			
			// reset variables
			_invalidated = true;
			_asyncToken = null;
			_result = null;
			_error = null;
			
			// we are no longer waiting for the async task
			WeaveAPI.ProgressIndicator.removeTask(_groupedCallback);
			
			// stop if lazy
			if (_lazy)
				return;
			
			// stop if still busy because we don't want to invoke the task if an external dependency is not ready
			if (WeaveAPI.SessionManager.linkableObjectIsBusy(this))
			{
				// make sure _groupedCallback() will not invoke the task.
				// this is ok to do since callbacks will be triggered again when the dependencies are no longer busy.
				_invalidated = false;
				return;
			}
			
			
			var _tmp_description:String = null;
			if (_description is Function)
				_tmp_description = (_description as Function)();
			else
				_tmp_description = _description as String;

			// mark as busy starting now because we plan to start the task inside _groupedCallback()
			WeaveAPI.ProgressIndicator.addTask(_groupedCallback, this, _tmp_description);
		}
		
		private function _groupedCallback():void
		{
			try
			{
				if (_lazy || !_invalidated)
					return;
				
				// _invalidated is true prior to invoking the task
				var invokeResult:* = _task.apply(null);
				
				// if _invalidated has been set to false, it means _immediateCallback() was triggered from the task and it's telling us we should stop now.
				if (!_invalidated)
					return;
				
				// set _invalidated to false now since we invoked the task
				_invalidated = false;
				
				if (invokeResult is WeavePromise)
					_asyncToken = (invokeResult as WeavePromise).getAsyncToken();
				else
					_asyncToken = invokeResult as AsyncToken;
				if (_asyncToken)
				{
					_asyncToken.addResponder(new AsyncResponder(_handleResult, _handleFault, _asyncToken));
				}
				else
				{
					_result = invokeResult;
					WeaveAPI.StageUtils.callLater(this, _handleResult);
				}
			}
			catch (invokeError:Error)
			{
				_invalidated = false;
				_asyncToken = null;
				_error = invokeError;
				WeaveAPI.StageUtils.callLater(this, _handleFault);
			}
		}
		
		private function _handleResult(event:ResultEvent = null, asyncToken:AsyncToken = null):void
		{
			// stop if asyncToken is no longer relevant
			if (_invalidated || _asyncToken != asyncToken)
				return;
			
			// no longer busy
			WeaveAPI.ProgressIndicator.removeTask(_groupedCallback);
			
			// if there is an event, save the result
			if (event)
				_result = event.result;
			
			_selfTriggeredCount = _callbackCollection.triggerCounter + 1;
			_callbackCollection.triggerCallbacks();
		}
		
		private function _handleFault(event:FaultEvent = null, asyncToken:AsyncToken = null):void
		{
			// stop if asyncToken is no longer relevant
			if (_invalidated || _asyncToken != asyncToken)
				return;
			
			// no longer busy
			WeaveAPI.ProgressIndicator.removeTask(_groupedCallback);
			
			// if there is an event, save the error
			if (event)
				_error = event.fault;
			
			_selfTriggeredCount = _callbackCollection.triggerCounter + 1;
			_callbackCollection.triggerCallbacks();
		}
		
		/**
		 * Registers dependencies of the LinkablePromise.
		 */
		public function depend(dependency:ILinkableObject, ...otherDependencies):LinkablePromise
		{
			otherDependencies.unshift(dependency);
			for each (dependency in otherDependencies)
				registerLinkableChild(this, dependency);
			return this;
		}
		
		public function dispose():void
		{
			WeaveAPI.ProgressIndicator.removeTask(_groupedCallback);
			_lazy = true;
			_invalidated = true;
			_asyncToken = null;
			_result = null;
			_error = null;
		}
	}
}
