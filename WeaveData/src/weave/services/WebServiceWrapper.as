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

package weave.services
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.messaging.messages.ErrorMessage;
	import mx.rpc.AbstractOperation;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.soap.LoadEvent;
	import mx.rpc.soap.SOAPFault;
	import mx.rpc.soap.WebService;
	
	import weave.api.reportError;
	import weave.api.services.IAsyncService;
	
	/**
	 * @author adufilie
	 */	
	public class WebServiceWrapper extends AsyncInvocationQueue implements IAsyncService
	{
		public function WebServiceWrapper(wsdl:String, useQueue:Boolean = true)
		{
			super();

			this.useQueue = useQueue;

			globalQueue = getGlobalQueue(wsdl);

			//webService.requestTimeout = 10; // 10 second timeout
			webService.makeObjectsBindable = false;

			// WORKAROUND FOR FLEX BUG: DOUBLE-ENCODING OF SPECIAL CHARS
			// http://bugs.adobe.com/jira/browse/FB-17407
			webService.xmlSpecialCharsFilter = function(value:Object):String { return value.toString(); }

			webService.loadWSDL(wsdl);
			webService.addEventListener(LoadEvent.LOAD, handleWSDLDownload);
			webService.addEventListener(FaultEvent.FAULT, handleWebServiceFault);
		}

		/**
		 * @param methodName The name of the method to call.
		 * @param methodParameters The parameters to use when calling the method.
		 * @return An AsyncToken generated for the call.
		 */
		public function invokeAsyncMethod(methodName:String, methodParameters:Object = null):AsyncToken
		{
			//trace("remoteProcedureCall",methodName,methodParameters);
			var abstractOperation:AbstractOperation = webService.getOperation(methodName);
			abstractOperation.arguments = methodParameters;
			var token:AsyncToken = abstractOperation.send();
			if (wsdlXML == null)
			{
				pendingAsyncTokens[token] = methodName;
				token.addResponder(new DelayedAsyncResponder(clearPendingAsyncTokenRef, clearPendingAsyncTokenRef, token));
			}
			else if (operations.indexOf(methodName) == -1)
			{
				var t:Timer = new Timer(0, 1);
				t.addEventListener(TimerEvent.TIMER, function (e:Event):void { handleMissingOperation(token, methodName); } );
				t.start();
			}
			return token;
		}
		
		/**
		 * This maps an AsyncToken to the name of the web method that was called.
		 * Only AsyncTokens created before wsdlXML was downloaded are added here.
		 */
		private const pendingAsyncTokens:Dictionary = new Dictionary();
		/**
		 * When an AsyncToken runs its responders, this function will be called to remove it from pendingAsyncTokens.
		 */
		private function clearPendingAsyncTokenRef(event:Event, token:Object = null):void
		{
			delete pendingAsyncTokens[token];
		}

		/**
		 * This is called when an operation does not exist.
		 */
		private function handleMissingOperation(token:AsyncToken, missingOperation:String):void
		{
			var faultString:String = 'The operation "'+missingOperation+'" does not exist';
			var faultDetail:String = "Available operations are: ["+operations+"]";
			var fault:Fault = new Fault("Undefined Fault Code", faultString, faultDetail);
			var faultEvent:FaultEvent = new FaultEvent(FaultEvent.FAULT, false, false, fault, token);
			if (token.responders != null)
				for each (var responder:IResponder in token.responders)
					responder.fault(faultEvent);
		}
		
		/**
		 * This is the wsdl file, used to verify that an operation exists before trying to call it.
		 */
		private var wsdlXML:XML = null;
		/**
		 * This is an array of operation names available in the WSDL.
		 */
		public const operations:Array = [];
		/**
		 * This function parses the WSDL once it is downloaded and fills in the operations array.
		 */
		private static const portTypeQName:QName = new QName("http://schemas.xmlsoap.org/wsdl/","portType");
		private static const operationQName:QName = new QName("http://schemas.xmlsoap.org/wsdl/","operation");
		private function handleWSDLDownload(event:LoadEvent):void
		{
			wsdlXML = event.xml;
			// get operation names from WSDL
			var operationXMLList:XMLList = wsdlXML.elements(portTypeQName).elements(operationQName).@name;
			for (var i:int = 0; i < operationXMLList.length(); i++)
				operations.push(String(operationXMLList[i]));
			// handle pending tokens that are from nonexisting operations
			for (var token:* in pendingAsyncTokens)
				if (operations.indexOf(pendingAsyncTokens[token]) == -1)
					handleMissingOperation(token, pendingAsyncTokens[token]);
		}

		/**
		 * This is the url of the wsdl.
		 */
		public function get wsdl():String
		{
			return webService.wsdl;
		}

		/**
		 * This is the WebService object where the web method calls are made.
		 */		
		public const webService:WebService = new WebService();

		private var useQueue:Boolean;

		/**
		 * This generic DownloadQueue takes care of all the calls associated with
		 * all instances of the WebServiceQueue class with the same wsdl url.
		 */
		private var globalQueue:AsyncInvocationQueue = null;

		/**
		 * This object maps a wsdl url to a global queue for that wsdl.
		 */		
		private static const globalQueueMap:Object = new Object();
		/**
		 * @param wsdl The url of the wsdl we want the global queue for
		 * @return The global queue corresponding to the given wsdl.
		 */
		private static function getGlobalQueue(wsdl:String):AsyncInvocationQueue
		{
			if (globalQueueMap[wsdl] == undefined)
				globalQueueMap[wsdl] = new AsyncInvocationQueue();
			return globalQueueMap[wsdl];
		}
		
		/**
		 * @param webMethod The name of the function to call on the WebService.
		 * @param parameters The parameters to the WebService function.
		 * @return A new ProxyAsyncToken responsible for making the WebService call.
		 */
		public function generateQuery(webMethod:String, parameters:Array, resultCastFunction:Function = null):ProxyAsyncToken
		{
			if (wsdlXML != null && operations.indexOf(webMethod) < 0)
				trace('"Warning!!! Operation "'+webMethod+'" not found in WSDL "'+wsdl+'"');

			return new ProxyAsyncToken(invokeAsyncMethod, [webMethod, parameters], resultCastFunction);
		}

		/**
		 * Generates a new ProxyAsyncToken and performs it immediately.
		 * @param webMethod The name of the function to call on the WebService.
		 * @param parameters The parameters to the WebService function.
		 * @return A new ProxyAsyncToken responsible for making the WebService call.
		 */
		public function generateAndPerformQuery(webMethod:String, parameters:Array, resultCastFunction:Function = null):ProxyAsyncToken
		{
			var query:ProxyAsyncToken = generateQuery(webMethod, parameters, resultCastFunction);
			performQuery(query);
			return query;
		}

		/**
		 * Generates a new ProxyAsyncToken and adds it to the queue.
		 * If useQueue is false, the query will be performed immediately.
		 * @param webMethod The name of the function to call on the WebService.
		 * @param parameters The parameters to the WebService function.
		 * @return A new ProxyAsyncToken responsible for making the WebService call.
		 */
		public function generateQueryAndAddToQueue(webMethod:String, parameters:Array, resultCastFunction:Function = null):ProxyAsyncToken
		{
			var query:ProxyAsyncToken = generateQuery(webMethod, parameters, resultCastFunction);
			if (useQueue)
				addToQueue(query);
			else
				performQuery(query);
			return query;
		}

		override protected function performQuery(query:ProxyAsyncToken):void
		{
			// add fault listener to this operation to prevent errors from propagating to webService object
			var methodName:String = query._params[0]; // first parameter of invokeAsyncMethod
			var abstractOperation:AbstractOperation = webService.getOperation(methodName);
			if (!abstractOperation.hasEventListener(FaultEvent.FAULT))
				abstractOperation.addEventListener(FaultEvent.FAULT, handleWebMethodFault);

			// if the query produces a fault, notify the user
			addAsyncResponder(query, null, handleDownloadFault, query);
			addAsyncResponder(query, handleQueryResultOrFault, handleQueryResultOrFault, query);

			// instead of downloading from this class, pass the query on to the global queue
			//globalQueue.addToQueue(query);
			//trace("performQuery -> globalQueue.addToQueue()", query);

			query.invoke(); // temporary?  perform query now instead of using global queue
		}
		
		override protected function handleQueryResultOrFault(event:Event, query:ProxyAsyncToken):void
		{
			//trace(token, (event is ResultEvent) ? "SUCCESS" : "FAIL");

			super.handleQueryResultOrFault(event, query);
		}
		
		public var alertEnabled:Boolean = true; // true to enable alert boxes
		protected var alertOnlyOnce:Boolean = false; // set this to true if you only want a maximum of one alert to show for this web service
		
		/**
		 * This function is called when a query produces a fault.
		 * It will notify the user with an Alert box and set 'alerted' = true.
		 * If 'alerted' is already true, it will not display an Alert box.
		 */
		protected function handleDownloadFault(event:FaultEvent, query:ProxyAsyncToken):void
		{
			//trace("###################### Web service fault:", query, event.toString());
			if (alertEnabled)
			{
				reportError(
					getFaultTitle(event) + ": "
					+ getFaultDetail(event) + "\n"
					+ "\n"
					+ "WebService: " + webService.wsdl + "\n"
					+ "\n"
					+ "WebMethod: " + query
				);
				if (alertOnlyOnce)
					alertEnabled = false;
			}
		}
		
		/**
		 * Called when web service dispatches a fault event.
		 */
		protected function handleWebServiceFault(event:FaultEvent):void
		{
			if (alertEnabled)
				reportError(getFaultTitle(event) + ": " + webService.wsdl + "\n\n" + getFaultDetail(event));
			if (alertOnlyOnce)
				alertEnabled = false;
		}
		
		/**
		 * Called when a web method dispatches a fault event. This is dummy method to
		 * prevent fault events on web methods from bubbling up to the WebService object.
		 */
		protected function handleWebMethodFault(event:FaultEvent):void
		{
			// do nothing
		}

		/**
		 * Get a short description of the error.
		 */
		private function getFaultTitle(event:FaultEvent):String
		{
			try {
				if (event.fault.faultDetail == null && event.message is ErrorMessage)
				{
					return (event.message as ErrorMessage).faultString;
				}
				else if (event.fault is SOAPFault)
					return "WebService Fault"; // for exceptions thrown from WeaveDataServices
				else
					return event.fault.faultString;
			}
			catch (e:Error) {
			}
			return "WebService Fault";
		}
		
		/**
		 * Get a detailed description of the error.
		 */
		private function getFaultDetail(event:FaultEvent):String
		{
			try {
				if (event.fault.faultDetail == null && event.message is ErrorMessage)
				{
					return (event.message as ErrorMessage).faultDetail;
				}
				else if (event.fault is SOAPFault) // for exceptions thrown from WeaveDataServices
					return event.fault.faultString;
				else
					return event.fault.faultDetail;
			}
			catch (e:Error) {}
			return "";
		}
	}
}
