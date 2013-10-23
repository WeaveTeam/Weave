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
	import flash.events.AsyncErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.IDisposableObject;
	import weave.api.disposeObjects;
	import weave.api.reportError;
	import weave.api.services.IAsyncService;
	
	/**
	 * This class provides two-way communication between Flash applications in the form of an IAsyncService.
	 */	
	public class LocalAsyncService implements IAsyncService, IDisposableObject
	{
		/**
		 * @param receivingObject The object to receive remote commands from.
		 * @param receivingObjectIsServer If true, receivingObject acts as the server and listens for the remote object acts as a client.
		 * @param serverConnectionName The connection name the server uses.
		 * @param clientConnectionName The connection name the client will use.  If not specified, this is derived from serverConnectionName
		 */
		public function LocalAsyncService(receivingObject:Object, receivingObjectIsServer:Boolean, serverConnectionName:String, clientConnectionName:String = null)
		{
			super();

			this.receivingObject = receivingObject;

			if (clientConnectionName == null)
				clientConnectionName = serverConnectionName + "_client";
			localName = (receivingObjectIsServer ? serverConnectionName : clientConnectionName);
			remoteName = (receivingObjectIsServer ? clientConnectionName : serverConnectionName);

			// this LocalAsyncService object will receive commands from another LocalAsyncService object
			conn.client = this;
			conn.addEventListener(AsyncErrorEvent.ASYNC_ERROR, handleAsyncError);
			conn.addEventListener(StatusEvent.STATUS, handleStatus);
			try
			{
				conn.connect(localName);
				//trace(localName,"connect");
			}
			catch (error:ArgumentError)
			{
				_fault = new Fault(String(error.errorID), error.name, error.message);
				//trace("LocalAsyncService()", localName, error);
				reportError(error);
			}
		}

		private var _fault:Fault; // the fault that will be passed to any future async requests
		private var receivingObject:Object; // object that will be made available to run commands on
		private const conn:LocalConnection = new LocalConnection();
		private var localName:String; // local connection name
		private var remoteName:String; // remote connection name
		private var commandCounter:int = 0; // incremented each time a command is sent
		private const tokens:Object = new Object(); // maps commandID to AsyncToken object
		private const chunks:Object = new Object(); // maps commandID to an Array of ByteArray chunks
		private const chunkCounters:Object = new Object(); // maps commandID to a counter used to keep track of how many chunks remain
		private static const tempByteArray:ByteArray = new ByteArray(); // reusable temporary object

		/**
		 * @return A new unique identifier for a command issued by this LocalAsyncService.
		 */		
		private function generateCommandID():String
		{
			return localName + commandCounter++;
		}
		
		/**
		 * @param methodName The name of the method to call.
		 * @param methodParameters The parameters to use when calling the method.
		 * @return An AsyncToken generated for the call.
		 */
		public function invokeAsyncMethod(methodName:String, methodParameters:Object = null):AsyncToken
		{
			//trace(localName,"remoteProcedureCall",methodName,ObjectUtil.toString(methodParameters));
			var commandID:String = generateCommandID();
			
			// If you are getting a compiler error on this line,
			// it means you must update to Flex SDK 3.5.
			tokens[commandID] = new AsyncToken();
			
			if (_fault)
			{
				WeaveAPI.StageUtils.callLater(this, receiveFault, [commandID, _fault]);
			}
			else
			{
				try
				{
					send("receiveCommand", commandID, methodName, methodParameters);
				}
				catch (error:ArgumentError)
				{
					reportError(error);
					WeaveAPI.StageUtils.callLater(this, receiveFault, [commandID, new Fault(String(error.errorID), error.name, error.message)]);
				}
			}
			
			return tokens[commandID];
		}
		
		/**
		 * This function gets called by the remote LocalAsyncService.
		 * The specified method will be called with the given parameters and
		 * the return value will be sent back via a remote receiveResult() call.
		 * @param commandID A string to identify which method invocation the result is for when it is sent back.
		 * @param methodName The name of the method to call on receivingObject.
		 * @param parameters Arguments to pass to the method.
		 */
		private function receiveCommand(commandID:String, methodName:String, methodParameters:Array):void
		{
			//trace(localName,"receiveCommand",commandID,methodName,ObjectUtil.toString(methodParameters));
			try
			{
				var method:Function = receivingObject[methodName] as Function;
				var result:Object = method.apply(null, methodParameters);
				if (result is AsyncToken)
				{
					var responder:AsyncResponder = new DelayedAsyncResponder(
							handleAsyncResult,
							handleAsyncFault,
							commandID
						);
					(result as AsyncToken).addResponder(responder);
				}
				else
				{
					handleResult(commandID, result);
				}
			}
			catch (e:Error)
			{
				handleFault(commandID, new Fault(String(e.errorID), e.name, e.message));
			}
		}
		
		/**
		 * This function will relay a result back to the remote LocalAsyncService.
		 * @param commandID A string to identify which method invocation the result is for.
		 * @param result The result of the method invocation.
		 */
		private function handleResult(commandID:String, result:Object):void
		{
			send("receiveResult", commandID, result);
		}
		
		/**
		 * This function will relay a fault back to the remote LocalAsyncService.
		 * @param commandID A string to identify which method invocation the result is for.
		 * @param fault The fault that occurred when invoking the method.
		 */
		private function handleFault(commandID:String, fault:Fault):void
		{
			send("receiveFault", commandID, new SerializableFault(fault));
		}
		
		/**
		 * This function is used as a result function for an AsyncResponder.
		 * The handleResult() function will be called using the event.result as the result.
		 * @param event The event from an AsyncToken.
		 * @param token The commandID associated with an AsyncToken.
		 */
		private function handleAsyncResult(event:ResultEvent, commandID:String):void
		{
			handleResult(commandID, event.result);
		}
		
		/**
		 * This function is used as a fault function for an AsyncResponder.
		 * The handleFault() function will be called using the event.fault as the fault.
		 * @param event The event from an AsyncToken.
		 * @param token The commandID associated with an AsyncToken.
		 */
		private function handleAsyncFault(event:FaultEvent, commandID:String):void
		{
			handleFault(commandID, event.fault);
		}
		
		/**
		 * This function gets called by the remote LocalAsyncService.
		 * @param commandID The string identifying which method invocation the result is for.
		 * @param result The result of the method invocation.
		 */
		private function receiveResult(commandID:String, result:Object):void
		{
			//trace(localName,"receiveResult",commandID,ObjectUtil.toString(result));
			var token:AsyncToken = tokens[commandID] as AsyncToken;
			if (token != null)
			{
				delete tokens[commandID];
				// broadcast result to responders
				var resultEvent:ResultEvent = new ResultEvent(ResultEvent.RESULT, false, false, result, token);
				if (token.responders != null)
					for each (var responder:IResponder in token.responders)
						responder.result(resultEvent);
			}
		}
		
		/**
		 * This function gets called by the remote LocalAsyncService.
		 * @param commandID The string identifying which method invocation the result is for.
		 * @param fault The fault caused by the method invocation.
		 */
		private function receiveFault(commandID:String, fault:Fault):void
		{
			//trace(localName,"receiveFault",commandID,fault.toString());
			var token:AsyncToken = tokens[commandID] as AsyncToken;
			if (token != null)
			{
				delete tokens[commandID];
				// broadcast result to responders
				var faultEvent:FaultEvent = new FaultEvent(FaultEvent.FAULT, false, false, fault, token);
				if (token.responders != null)
					for each (var responder:IResponder in token.responders)
						responder.fault(faultEvent);
			}
		}
		
		/**
		 * For internal use. Sends chunks of a wrapper command to the other LocalAsyncService object.
		 * @param commandID A string to identify which method invocation the result is for when it is sent back.
		 * @param receivingMethod Either "receiveCommand", "receiveResult", or "receiveFault"
		 * @param parameters The parameters to give to the receivingMethod.
		 */
		private function send(receivingMethod:String, ... parameters):void
		{
			//trace(localName,"send",receivingMethod,ObjectUtil.toString(parameters));
			// serialize the method name and parameters
			tempByteArray.clear();
			tempByteArray.writeObject([receivingMethod, parameters]);
			tempByteArray.position = 0;
			// split the ByteArray into chunks and send them
			var commandID:String = generateCommandID();
			var chunkID:uint = 0;
			var moreChunksFollow:Boolean = true;
			while (moreChunksFollow)
			{
				var chunkData:ByteArray = new ByteArray();
				var chunkSize:uint = Math.min(tempByteArray.bytesAvailable, 39900); // size limit for send data is 40k
				tempByteArray.readBytes(chunkData, 0, chunkSize);
				moreChunksFollow = (tempByteArray.bytesAvailable > 0);

				// chunkData was chunkData.toString() before because byteArray is sometimes encoded as a generic object
				// but I can't reproduce it and this fixes a bug with a unicode character (such as the greek lowercase mu, char code 181).
				// the unicode char bug occurs during the toString() call which results in a string with a smaller size than the bytearray.
				conn.send(remoteName, "receiveChunkedData", commandID, chunkID++, chunkData, moreChunksFollow);
			}
		}

		/**
		 * This function gets called by the remote LocalAsyncService.
		 * This function will receive a chunk of a serialized Array containing
		 * a name of a function of this class and a list of parameters.  When all
		 * the chunks have been received for the specified commandID, the function
		 * will be called with its parameters.
		 * An example Array that would be serialized is:
		 *     ["receiveCommand",[commandID,methodName,methodParameters]]
		 * In this case, the resulting function call would be:
		 *     receiveCommand(commandID,methodName,methodParameters);
		 * @param commandID A string to identify which method invocation the result is for when it is sent back.
		 * @param chunkID An unsigned integer designating the order in which chunks should be assembled.
		 * @param chunkData Part of a serialized list of parameters for the receiveCommand() function.
		 * @param moreChunksFollow If this is true, it means more chunks appear after this chunkID.  If false, this is the last chunkID.
		 */
		public function receiveChunkedData(commandID:String, chunkID:uint, chunkData:ByteArray, moreChunksFollow:Boolean):void
		{
			//trace('receiveChunkedData', commandID, chunkID, chunkData.length, moreChunksFollow);
			_receiveChunkedData.apply(null, [commandID, chunkID, chunkData, moreChunksFollow]);
		}
		private function _receiveChunkedData(commandID:String, chunkID:uint, chunkData:ByteArray, moreChunksFollow:Boolean):void
		{
			// initialize parameters array and params received count
			if (chunks[commandID] == undefined)
				chunks[commandID] = new Array();
			if (chunkCounters[commandID] == undefined)
				chunkCounters[commandID] = 0;
			
			// save chunk data and update chunk counter
			chunks[commandID][chunkID] = chunkData;
			// The chunk counter serves as a flag to indicate when all the chunks have been received.
			// For example, if there are three chunks, chunks 0 and 1 will add 2 to the counter, then chunk 2 will decrease the counter to zero.
			if (moreChunksFollow)
				chunkCounters[commandID]++; // INCREASE chunk counter by 1 for this chunk
			else
				chunkCounters[commandID] -= chunkID; // DECREASE chunk counter by the highest chunkID
			// When the counter is zero, all the chunks have been received.
			if (chunkCounters[commandID] == 0)
			{
				var chunkList:Array = chunks[commandID] as Array;
				// de-serialize the parameter array
				tempByteArray.clear();
				for (var i:int = 0; i < chunkList.length; i++)
					tempByteArray.writeBytes(chunkList[i]);
				tempByteArray.position = 0;
				var methodAndParams:Array = tempByteArray.readObject();
				// first item in the array is the methodName, second item is the parameters
				(this[methodAndParams[0]] as Function).apply(null, methodAndParams[1]);
				// perform cleanup now
				delete chunks[commandID];
				delete chunkCounters[commandID];
			}
		}
		
		private function handleAsyncError(event:AsyncErrorEvent):void
		{
			trace("LocalAsyncService.handleAsyncError()", localName, ObjectUtil.toString(event));
			if (!_fault)
				_fault = new Fault(String(event.error.errorID), event.error.name, event.error.message);
			
			disposeObjects(this);
		}

		private function handleStatus(event:StatusEvent):void
		{
			if (event.level == 'error')
			{
				if (!_fault)
					_fault = new Fault(StatusEvent.STATUS, 'Received LocalConnection error status');
				
				disposeObjects(this);
			}
		}
		
		/**
		 * This will call close() on the LocalConnection object.
		 */
		public function dispose():void
		{
			if (!_fault)
				_fault = new Fault("disposed", "LocalAsyncService was disposed");
			
			// pass fault to all pending commands
			for (var commandID:String in tokens)
				receiveFault(commandID, _fault);
			
			conn.close();
		}
	}
}
import flash.net.registerClassAlias;
import flash.utils.getQualifiedClassName;

import mx.rpc.Fault;

internal class SerializableFault extends Fault
{
	{ // static code
		registerClassAlias(getQualifiedClassName(SerializableFault), SerializableFault);
	}
	
	public function SerializableFault(fault:Fault = null)
	{
		super(
			fault ? fault.faultCode : null,
			fault ? fault.faultString : null,
			fault ? fault.faultDetail : null
		);
	}
	
	public function set faultCode(value:String):void { _faultCode = value; }
	public function set faultDetail(value:String):void { _faultDetail = value; }
	public function set faultString(value:String):void { _faultString = value; }
}
