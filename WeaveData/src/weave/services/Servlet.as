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
	import weave.api.services.IURLRequestUtils;
	
	/**
	 * Servlet
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
		public function Servlet(servletURL:String, methodURLParam:String, urlRequestDataFormat:String)
		{
			if (urlRequestDataFormat != REQUEST_FORMAT_BINARY && urlRequestDataFormat != REQUEST_FORMAT_VARIABLES)
				throw new Error(getQualifiedClassName(Servlet) + ': urlRequestDataFormat not supported: "' + urlRequestDataFormat + '"');
			
			var urlParts:Array = servletURL.split('?');
			_servletURL = urlParts[0];
			_methodURLParam = methodURLParam;
			_urlRequestDataFormat = urlRequestDataFormat;
		}
		
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
		 * This is the name of the URL parameter that specifies the method to be called on the servlet.
		 */
		protected var _methodURLParam:String;
		
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
			var request:URLRequest = new URLRequest(_servletURL);
			
			if (_urlRequestDataFormat == REQUEST_FORMAT_VARIABLES)
			{
				request.method = URLRequestMethod.GET;
				request.data = new URLVariables();
				
				// set url variable for the method name
				if (_methodURLParam != null && methodName != null)
					request.data[_methodURLParam] = methodName;
				
				if (methodParameters != null)
				{
					// set url variables from parameters
					for (var name:String in methodParameters)
					{
						if(methodParameters[name] is Array)
							request.data[name] = WeaveAPI.CSVParser.createCSVFromArrays([methodParameters[name]]);
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
				obj.methodName = methodName;
				obj.methodParameters = methodParameters;
				
				// serialize into compressed AMF3
				var byteArray:ByteArray = new ByteArray(); 
				byteArray.writeObject(obj);
				byteArray.compress();
				
				request.data = byteArray;
			}
			
			var token:AsyncToken = new AsyncToken();
			
			// the last argument is BINARY instead of _dataFormat because the stream should not be parsed
			_asyncTokenToLoader[token] = WeaveAPI.URLRequestUtils.getURL(request, resultHandler, faultHandler, token, URLLoaderDataFormat.BINARY);
			return token;
		}
		
		/**
		 * Cancel a URLLoader request from a given AsyncToken.
		 * This function should be used with care because multiple requests for the same URL
		 * may all be cancelled by one client.
		 *  
		 * @param asyncToken The corresponding AsyncToken.
		 */		
		public function cancelLoaderFromToken(asyncToken:AsyncToken):void
		{
			var loader:URLLoader = _asyncTokenToLoader[asyncToken];
			
			if (loader)
				loader.close();
		}
		
		/**
		 * This is a mapping of AsyncToken objects to URLLoader objects. 
		 * This mapping is necessary so a client with an AsyncToken can cancel the loader. 
		 */		
		private const _asyncTokenToLoader:Dictionary = new Dictionary();
				
		private function resultHandler(event:ResultEvent, token:Object = null):void
		{
			(token as AsyncToken).mx_internal::applyResult(event);
		}
		
		private function faultHandler(event:FaultEvent, token:Object = null):void
		{
			(token as AsyncToken).mx_internal::applyFault(event);
		}
	}
}
