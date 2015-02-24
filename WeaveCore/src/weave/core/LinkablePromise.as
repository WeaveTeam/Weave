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
	
	/**
	 * @author adufilie
	 */
	public class LinkablePromise implements ILinkableObject, IDisposableObject
	{
		public function LinkablePromise(invoke:Function, invokeParams:Array = null)
		{
			this.invoke = invoke;
			this.invokeParams = invokeParams;
			this.callbackCollection = WeaveAPI.SessionManager.getCallbackCollection(this);
			
			callbackCollection.addGroupedCallback(null, groupedCallback);
		}
		
		private var callbackCollection:ICallbackCollection;
		private var invoke:Function;
		private var invokeParams:Array;
		private var asyncToken:AsyncToken;
		private var resultTriggerCount:int = 0;
		
		public var result:Object;
		public var error:Error;
		
		private function groupedCallback():void
		{
			if (callbackCollection.triggerCounter == resultTriggerCount)
				return;
			
			this.result = null;
			this.error = null;
			
			WeaveAPI.ProgressIndicator.addTask(groupedCallback, this);
			
			asyncToken = invoke.apply(null, invokeParams) as AsyncToken;
			if (asyncToken)
			{
				asyncToken.addResponder(new AsyncResponder(handleResult, handleFault, asyncToken));
			}
			else
			{
				asyncToken = null;
				WeaveAPI.StageUtils.callLater(this, handleResult);
			}
		}
		
		private function handleResult(event:ResultEvent = null, asyncToken:AsyncToken = null):void
		{
			if (this.asyncToken != asyncToken)
				return;
			
			WeaveAPI.ProgressIndicator.removeTask(groupedCallback);
			
			this.result = event && event.result;
			this.error = null;
			
			resultTriggerCount = callbackCollection.triggerCounter + 1;
			callbackCollection.triggerCallbacks();
		}
		
		private function handleFault(event:FaultEvent, asyncToken:AsyncToken):void
		{
			if (this.asyncToken != asyncToken)
				return;
			
			WeaveAPI.ProgressIndicator.removeTask(groupedCallback);
			
			this.result = null;
			this.error = event.fault;
			
			resultTriggerCount = callbackCollection.triggerCounter + 1;
			callbackCollection.triggerCallbacks();
		}
		
		public function dispose():void
		{
		}
	}
}
