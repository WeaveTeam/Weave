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
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	
	/**
	 * @author adufilie
	 */
	public class LinkablePromise implements ILinkableObject, IDisposableObject
	{
		public function LinkablePromise(invoke:Function, invokeParams:Array = null)
		{
			_invoke = invoke;
			_invokeParams = invokeParams;
			_callbackCollection = WeaveAPI.SessionManager.getCallbackCollection(this);
			_callbackCollection.addImmediateCallback(null, _immediateCallback);
			_callbackCollection.addGroupedCallback(null, _groupedCallback);
			_callbackCollection.triggerCallbacks();
		}
		
		private var _callbackCollection:ICallbackCollection;
		private var _invoke:Function;
		private var _invokeParams:Array;
		
		private var _pendingInvoke:Boolean;
		private var _asyncToken:AsyncToken;
		private var _selfTriggeredCount:uint = 0;
		private var _result:Object;
		private var _error:Object;
		
		public function get result():Object { return _result; }
		public function get error():Object { return _error; }
		
		private function _immediateCallback():void
		{
			// stop if self-triggered
			if (_callbackCollection.triggerCounter == _selfTriggeredCount)
				return;
			
			// reset variables and mark as busy
			_pendingInvoke = true;
			_asyncToken = null;
			_result = null;
			_error = null;
			WeaveAPI.ProgressIndicator.addTask(_groupedCallback, this);
		}
		
		private function _groupedCallback():void
		{
			if (!_pendingInvoke)
				return;
			
			_pendingInvoke = false;
			
			try
			{
				var invokeResult:Object = _invoke.apply(null, _invokeParams);
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
			if (_pendingInvoke || _asyncToken != asyncToken)
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
			if (_pendingInvoke || _asyncToken != asyncToken)
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
			_pendingInvoke = false;
			_asyncToken = null;
			_result = null;
			_error = null;
		}
	}
}
