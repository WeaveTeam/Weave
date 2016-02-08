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

package weavejs.net
{
	import weavejs.WeaveAPI;
	import weavejs.api.net.IAsyncService;
	import weavejs.util.JS;
	import weavejs.util.JSByteArray;
	import weavejs.util.WeavePromise;
	
	/**
	 * This is an IAsyncService interface for a servlet that takes its parameters from URL variables.
	 * 
	 * @author adufilie
	 */	
	public class Servlet implements IAsyncService
	{
		/**
		 * WeavePromise -> [methodName, params, id]
		 */
		protected var map_promise_methodParamsId:Object = new JS.WeakMap();
		
		private var nextId:int = 1;
		
		/**
		 * @param servletURL The URL of the servlet (everything before the question mark in a URL request).
		 * @param methodParamName This is the name of the URL parameter that specifies the method to be called on the servlet.
		 * @param urlRequestDataFormat This is the format to use when sending parameters to the servlet.
		 */
		public function Servlet(servletURL:String, methodVariableName:String, protocol:String)
		{
			if ([Protocol.URL_PARAMS, Protocol.JSONRPC_2_0, Protocol.JSONRPC_2_0_AMF].indexOf(protocol) < 0)
				throw new Error(Weave.className(Servlet) + ': protocol not supported: "' + protocol + '"');
			
			_servletURL = servletURL;
			_protocol = protocol;
			METHOD = methodVariableName;
		}
		
		/**
		 * The name of the property which contains the remote method name.
		 */
		private var METHOD:String = "method";
		/**
		 * The name of the property which contains method parameters.
		 */
		private var PARAMS:String = "params";
		
		/**
		 * This is the base URL of the servlet.
		 * The base url is everything before the question mark in a url request like the following:
		 *     http://www.example.com/servlet?param=123
		 */
		public function get servletURL():String
		{
			return _servletURL;
		}
		protected var _servletURL:String;

		/**
		 * This is the data format of the results from HTTP GET requests.
		 */
		protected var _protocol:String;
		
		protected var _invokeLater:Boolean = false;
		
		/**
		 * This function makes a remote procedure call.
		 * @param methodName The name of the method to call.
		 * @param methodParameters The parameters to use when calling the method.
		 * @return A WeavePromise generated for the call.
		 */
		public function invokeAsyncMethod(methodName:String, methodParameters:Object = null):WeavePromise
		{
			var promise:WeavePromise = new WeavePromise(this);
			
			map_promise_methodParamsId.set(promise, [methodName, methodParameters, nextId++]);
			
			if (!_invokeLater)
				invokeNow(promise);
			
			return promise;
		}
		
		/**
		 * This function may be overrided to give different servlet URLs for different methods.
		 * @param methodName The method.
		 * @return The servlet url for the method.
		 */
		protected function getServletURLForMethod(methodName:String):String
		{
			return _servletURL;
		}
		
		/**
		 * This will make a url request that was previously delayed.
		 * @param promise A WeavePromise generated from a previous call to invokeAsyncMethod().
		 */
		protected function invokeNow(promise:WeavePromise):void
		{
			//TODO - need a way to cancel previous request
			// if promise.setResult was called with a urlPromise, dispose the old urlPromise or re-invoke it
			
			var method0_params1_id2:Array = map_promise_methodParamsId.get(promise);
			if (!method0_params1_id2)
				return;
			
			var method:String = method0_params1_id2[0];
			var params:Object = method0_params1_id2[1];
			var id:int = method0_params1_id2[2];
			
			var url:String = getServletURLForMethod(method);
			var request:URLRequest = new URLRequest(url);
			if (_protocol == Protocol.URL_PARAMS)
			{
				params = JS.copyObject(params);
				params[METHOD] = method;
				request.url = buildUrlWithParams(url, params);
				request.method = RequestMethod.GET;
			}
			else if (_protocol == Protocol.JSONRPC_2_0)
			{
				request.method = RequestMethod.POST;
				request.data = JSON.stringify({
					jsonrpc: "2.0",
					method: method,
					params: params,
					id: id
				});
				request.responseType = ResponseType.JSON;
			}
			else if (_protocol == Protocol.JSONRPC_2_0_AMF)
			{
				request.method = RequestMethod.POST;
				request.data = JSON.stringify({
					jsonrpc: "2.0/AMF3",
					method: method,
					params: params,
					id: id
				});
			}
			
			var result:WeavePromise = WeaveAPI.URLRequestUtils.request(this, request);
			
			if (_protocol == Protocol.JSONRPC_2_0_AMF)
				result = result.then(readAmf3Object);
			
			promise.setResult(result);
		}
		
		
		/**
		 * This function reads an object that has been AMF3-serialized into a ByteArray and compressed.
		 * @param compressedSerializedObject The ByteArray that contains the compressed AMF3 serialization of an object.
		 * @return The result of calling readObject() on the ByteArray, or null if the RPC returns void.
		 * @throws Error if unable to read the result.
		 */
		public static function readAmf3Object(bytes:/*Uint8*/Array):Object
		{
			// length may be zero for void result
			var obj:Object = bytes && bytes.length && new JSByteArray(bytes).readObject();
			
			// TEMPORARY SOLUTION to detect errors
			if (obj && (obj.faultCode && obj.faultString))
				throw new Error(obj.faultCode + ": " + obj.faultString);
			
			return obj;
		}
		
		public static function buildUrlWithParams(url:String, params:Object):String
		{
			var queryString:String = '';
			var qi:int = url.indexOf('?');
			if (qi >= 0)
			{
				queryString = url.substr(qi + 1);
				url = url.substr(0, qi);
			}
			
			for each (var key:String in params)
			{
				if (queryString)
					queryString += '&';
				var value:* = params[key];
				if (params != null && typeof params === 'object')
					value = JSON.stringify(value);
				queryString += encodeURIComponent(value);
				params[key]
			}
			
			return url + '?' + queryString;
		}
	}
}
