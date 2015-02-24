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
	import mx.core.mx_internal;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	
	/**
	 * Use this class to build dependency trees involving asynchronous calls.
	 * When the callbacks of a LinkableTask are triggered, a function will be invoked.
	 * If the function returns an AsyncToken, LinkableTask's callbacks will be triggered again when a ResultEvent or FaultEvent is received from the AsyncToken.
	 * Dependency trees can be built using newLinkableChild() and registerLinkableChild().
	 * 
	 * @see weave.api.core.ISessionManager#newLinkableChild()
	 * @see weave.api.core.ISessionManager#registerLinkableChild()
	 * @author adufilie
	 */
	public class LinkableTask implements ILinkableObject, IDisposableObject
	{
		/**
		 * Creates a LinkableTask from an iterative task function.
		 * @param asyncTask A function which is designed to be called repeatedly across multiple frames until it returns a value of 1.
		 * @param priority The task priority, which should be one of the static constants in WeaveAPI.
		 * @param description A description of the task.
		 * @see weave.api.core.IStageUtils#startTask()
		 */
		public static function fromIterativeTask(iterativeTask:Function, priority:uint, description:String = null, validateNow:Boolean = false):LinkableTask
		{
			var promise:LinkableTask;
			var asyncToken:AsyncToken;
			
			function asyncStart():AsyncToken
			{
				WeaveAPI.StageUtils.startTask(promise, iterativeTask, priority, asyncComplete);
				return asyncToken = new AsyncToken();
			}
			
			function asyncComplete():void
			{
				asyncToken.mx_internal::applyResult(ResultEvent.createEvent(null, asyncToken));
			}
			
			return promise = new LinkableTask(asyncStart, null, description, validateNow);
		}
		
		/**
		 * @param task A function to invoke, which may return an AsyncToken.
		 * @param taskParams Parameters to pass to the task function.
		 * @param description A description of the task.
		 */
		public function LinkableTask(task:Function, taskParams:Array = null, description:String = null, validateNow:Boolean = false)
		{
			_task = task;
			_taskParams = taskParams;
			_description = description;
			_callbackCollection = WeaveAPI.SessionManager.getCallbackCollection(this);
			_callbackCollection.addImmediateCallback(null, _immediateCallback);
			_callbackCollection.addGroupedCallback(null, _groupedCallback);
			if (validateNow)
				validate();
		}
		
		private var _task:Function;
		private var _taskParams:Array;
		private var _description:String;
		
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
		 * If this LinkableTask is set to lazy mode, this will switch it to non-lazy mode and automatically invoke the async task when necessary.
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
			
			// mark as busy starting now because we plan to start the task inside _groupedCallback()
			WeaveAPI.ProgressIndicator.addTask(_groupedCallback, this, _description);
		}
		
		private function _groupedCallback():void
		{
			if (_lazy || !_invalidated)
				return;
			
			_invalidated = false;
			
			try
			{
				var invokeResult:Object = _task.apply(null, _taskParams);
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
		
		public function dispose():void
		{
			_lazy = true;
			_invalidated = true;
			_asyncToken = null;
			_result = null;
			_error = null;
		}
	}
}
