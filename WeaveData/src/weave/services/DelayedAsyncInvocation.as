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

package weave.services
{
	import flash.events.Event;
	
	import mx.messaging.messages.ErrorMessage;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.api.services.IAsyncService;

	/**
	 * This class contains the information required to invoke an asynchronous method.
	 * A DelayedAsyncCall object may be saved in a queue for calling later.
	 * 
	 * @author adufilie
	 */
	public class DelayedAsyncInvocation extends AsyncToken
	{
		public function DelayedAsyncInvocation(service:IAsyncService, methodName:String, parameters:Object, resultCastFunction:Function = null, handleErrorMessageObjects:Boolean = true)
		{
			super();
			
			this.service = service;
			this.methodName = methodName;
			this.parameters = parameters;
			this.resultCastFunction = resultCastFunction;
			this.handleErrorMessageObjects = handleErrorMessageObjects;
		}

		public var service:IAsyncService;
		public var methodName:String;
		public var parameters:Object;
		public var resultCastFunction:Function;
		public var handleErrorMessageObjects:Boolean;
		
		// the token associated with the call, null until query is performed	
		private var internalAsyncToken:AsyncToken = null;

		// used to keep track of the time spent running responder functions
		private var processingTime:int = 0;
		
		/**
		 * This function will create a new AsyncResponder object and pass it to the addResponder function.
		 */
		public function addAsyncResponder(resultFunc:Function, faultFunc:Function = null, token:Object = null):void
		{
			if (resultFunc == null)
				resultFunc = emptyResultOrFaultFunction;
			if (faultFunc == null)
				faultFunc = emptyResultOrFaultFunction;

			// put a wrapper function around result & fault functions to keep track of processing time
			var faultWrapperFunc:Function = function(event:FaultEvent, token:Object = null):void
			{
				if (token == null)
					faultFunc(event);
				else
					faultFunc(event, token);
			}
			var resultWrapperFunc:Function = function(event:ResultEvent, token:Object = null):void
			{
				if (token == null)
					resultFunc(event);
				else
					resultFunc(event, token);
			}
			
			addResponder(new DelayedAsyncResponder(resultWrapperFunc, faultWrapperFunc, token));
		}
		
		/**
		 * This function does nothing.
		 * It can be used in place of a result or fault function when no function is desired.
		 */
		private static function emptyResultOrFaultFunction(event:Event, token:Object = null):void
		{
			// does nothing
		} 
		
		/**
		 * This function will invoke the async method using the parameters previously specified.
		 */
		public function invoke():void
		{
			if (internalAsyncToken != null)
			{
				trace("invoke(): Operation has already been called.", toString());
				return;
			}
			
			//trace("performQuery", this);
			internalAsyncToken = service.invokeAsyncMethod(methodName, parameters);
			
			// when the query finishes, forward the event to the responders in this AsyncToken.
			internalAsyncToken.addResponder(new DelayedAsyncResponder(handleResult, handleFault, this));
		}
		
		/**
		 * This function gets called when the internalAsyncToken runs its result functions.
		 * This function will call the result functions of the responders added to this object.
		 */
		private function handleResult(event:ResultEvent, token:Object = null):void
		{
			// cast result if result cast function is given
			if (resultCastFunction != null)
			{
				var result:Object = resultCastFunction.apply(null, [event.result]);
				event = ResultEvent.createEvent(result, event.token, event.message);
			}
			
			// if option is enabled, check if event.result is an ErrorMessage object.
			if (handleErrorMessageObjects && event.result is ErrorMessage)
			{
				// When an ErrorMessage is returned by the AsyncToken, treat it as a fault.
				var msg:ErrorMessage = event.result as ErrorMessage;
				var fault:Fault = new Fault(msg.faultCode, msg.faultString, msg.faultDetail);
				fault.message = msg;
				fault.content = event;
				fault.rootCause = this;
				var faultEvent:FaultEvent = FaultEvent.createEvent(fault, this, msg);
				handleFault(faultEvent, token);
				return;
			}
			
			// broadcast result to responders in the order they were added
			if (responders != null)
				for (var i:int = 0; i < responders.length; i++)
					(responders[i] as IResponder).result(event);
		}
		/**
		 * This function gets called when the internalAsyncToken runs its fault functions.
		 * This function will call the fault functions of the responders added to this object.
		 */
		private function handleFault(event:FaultEvent, token:Object = null):void
		{
			// broadcast fault to responders in the order they were added
			if (responders != null)
				for (var i:int = 0; i < responders.length; i++)
					(responders[i] as IResponder).fault(event);
		}
		
		protected var truncateToStringOutput:Boolean = true; // set to true to prevent toString() from returning lengthy strings
		
		override public function toString():String
		{
			var paramStr:String = "";
			var tempStr:String;
			if (parameters is Array)
			{
				for (var i:int = 0; i < parameters.length; i++)
				{
					if (i > 0)
						paramStr += ", ";
					tempStr = parameters[i];
					if (tempStr != null && truncateToStringOutput && tempStr.length > 64)
						tempStr = tempStr.substr(0, 61) + "...";
					paramStr += tempStr;
				}
			}
			else
			{
				paramStr = ObjectUtil.toString(parameters);
			}
			return methodName + "(" + paramStr + ")";
		}
	}
}
