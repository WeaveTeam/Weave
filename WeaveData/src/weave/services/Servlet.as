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
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.mx_internal;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.services.IAsyncService;
	
	/**
	 * This is an IAsyncService interface for a servlet that takes its parameters from URL variables.
	 * 
	 * @author adufilie
	 */	
	public class Servlet implements IAsyncService
	{
		public static const REQUEST_FORMAT_VARIABLES:String = URLLoaderDataFormat.VARIABLES;
		public static const REQUEST_FORMAT_BINARY:String = URLLoaderDataFormat.BINARY;
		
		/**
		 * @param servletURL The URL of the servlet (everything before the question mark in a URL request).
		 * @param methodParamName This is the name of the URL parameter that specifies the method to be called on the servlet.
		 * @param urlRequestDataFormat This is the format to use when sending parameters to the servlet.
		 */
		public function Servlet(servletURL:String, methodVariableName:String, urlRequestDataFormat:String)
		{
			if (urlRequestDataFormat != REQUEST_FORMAT_BINARY && urlRequestDataFormat != REQUEST_FORMAT_VARIABLES)
				throw new Error(getQualifiedClassName(Servlet) + ': urlRequestDataFormat not supported: "' + urlRequestDataFormat + '"');
			
			_servletURL = servletURL;
			_urlRequestDataFormat = urlRequestDataFormat;
			METHOD = methodVariableName;
		}
		
		private var METHOD:String = "method";
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
		protected var _urlRequestDataFormat:String;
		
		/**
		 * This function makes a remote procedure call.
		 * @param methodName The name of the method to call.
		 * @param methodParameters The parameters to use when calling the method.
		 * @return An AsyncToken generated for the call.
		 */
		public function invokeAsyncMethod(methodName:String, methodParameters:Object = null):AsyncToken
		{
			var token:AsyncToken = new AsyncToken();
			
			_asyncTokenData[token] = arguments;
			
			if (!_invokeLater)
				invokeNow(token);
			
			return token;
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
		 * @param invokeToken An AsyncToken generated from a previous call to invokeAsyncMethod().
		 */
		protected function invokeNow(invokeToken:AsyncToken):void
		{
			var args:Array = _asyncTokenData[invokeToken] as Array;
			if (!args)
				return;
			
			var methodName:String = args[0];
			var methodParameters:Object = args[1];
			
			var request:URLRequest = new URLRequest(getServletURLForMethod(methodName));
			
			if (_urlRequestDataFormat == REQUEST_FORMAT_VARIABLES)
			{
				request.method = URLRequestMethod.GET;
				request.data = new URLVariables();
				
				// set url variable for the method name
				if(methodName)
					request.data[METHOD] = methodName;
				
				if (methodParameters != null)
				{
					// set url variables from parameters
					for (var name:String in methodParameters)
					{
						if (methodParameters[name] is Array)
							request.data[name] = WeaveAPI.CSVParser.createCSV([methodParameters[name]]);
						else
							request.data[name] = methodParameters[name];
					}
				}
			}
			else if (_urlRequestDataFormat == REQUEST_FORMAT_BINARY)
			{
				request.method = URLRequestMethod.POST;
				// create object containing method name and parameters
				var obj:Object = new Object();
				obj[METHOD] = methodName;
				obj[PARAMS] = methodParameters;
				obj["streamParameterIndex"] = -1; // index of stream parameter
				
				var streamContent:ByteArray = null;
				var params:Array = methodParameters as Array;
				if (params)
				{
					var index:int;
					for (index = 0; index < params.length; index++)
						if (params[index] is ByteArray)
							break;
					if (index < params.length)
					{
						obj.streamParameterIndex = index; // tell the server about the stream parameter index
						streamContent = params[index];
						params[index] = null; // keep the placeholder where the server will insert the stream parameter
					}
				}
				
				// serialize into AMF3
				var byteArray:ByteArray = new ByteArray(); 
				byteArray.writeObject(obj);
				// if stream content exists, append after the AMF3-serialized object
				if (streamContent)
					byteArray.writeBytes(streamContent);
				
				request.data = byteArray;
			}
			
			// the last argument is BINARY instead of _dataFormat because the stream should not be parsed
			_asyncTokenData[invokeToken] = WeaveAPI.URLRequestUtils.getURL(this, request, resultHandler, faultHandler, invokeToken, URLLoaderDataFormat.BINARY);
		}
		
		/**
		 * Set this to true to prevent url requests from being made right away.
		 * When this is set to true, invokeNow() must be called to make delayed url requests.
		 * Setting this to false will immediately resume all delayed url requests.
		 */
		protected function set invokeLater(value:Boolean):void
		{
			_invokeLater = value;
			if (!_invokeLater)
				for (var token:Object in _asyncTokenData)
					invokeNow(token as AsyncToken);
		}
		
		protected function get invokeLater():Boolean
		{
			return _invokeLater;
		}
		
		private var _invokeLater:Boolean = false;
		
		/**
		 * Cancel a URLLoader request from a given AsyncToken.
		 * This function should be used with care because multiple requests for the same URL
		 * may all be cancelled by one client.
		 *  
		 * @param asyncToken The corresponding AsyncToken.
		 */		
		public function cancelLoaderFromToken(asyncToken:AsyncToken):void
		{
			var loader:URLLoader = _asyncTokenData[asyncToken] as URLLoader;
			
			if (loader)
				loader.close();
			
			delete _asyncTokenData[asyncToken];
		}
		
		/**
		 * This is a mapping of AsyncToken objects to URLLoader objects. 
		 * This mapping is necessary so a client with an AsyncToken can cancel the loader. 
		 */		
		private const _asyncTokenData:Dictionary = new Dictionary();
				
		private function resultHandler(event:ResultEvent, token:Object = null):void
		{
			(token as AsyncToken).mx_internal::applyResult(event);
			delete _asyncTokenData[token];
		}
		
		private function faultHandler(event:FaultEvent, token:Object = null):void
		{
			(token as AsyncToken).mx_internal::applyFault(event);
			delete _asyncTokenData[token];
		}
	}
}
