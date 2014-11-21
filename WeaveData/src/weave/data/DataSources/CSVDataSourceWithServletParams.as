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

package weave.data.DataSources
{
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.detectLinkableObjectChange;
	import weave.api.disposeObject;
	import weave.api.getCallbackCollection;
	import weave.api.getSessionState;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.core.UntypedLinkableVariable;
	import weave.services.AMF3Servlet;
	import weave.services.addAsyncResponder;
	
	/**
	 * 
	 * @author adufilie
	 * @author skolman
	 */
	public class CSVDataSourceWithServletParams extends CSVDataSource
	{
		/**
		 * Session state of servletParams must be an object with two properties: 'method' and 'params'
		 * If this is set, it assumes that url.value points to a Weave AMF3Servlet and the servlet method returns a table of data.
		 */
		public const servletParams:UntypedLinkableVariable = registerLinkableChild(this, new UntypedLinkableVariable(null, verifyServletParams));
		public static const SERVLETPARAMS_PROPERTY_METHOD:String = 'method';
		public static const SERVLETPARAMS_PROPERTY_PARAMS:String = 'params';
		private var _servlet:AMF3Servlet = null;
		private function verifyServletParams(value:Object):Boolean
		{
			return value != null
				&& value.hasOwnProperty(SERVLETPARAMS_PROPERTY_METHOD)
				&& value.hasOwnProperty(SERVLETPARAMS_PROPERTY_PARAMS);
		}
		
		/**
		 * Called when url session state changes
		 */		
		override protected function handleURLChange():void
		{
			var urlChanged:Boolean = detectLinkableObjectChange(handleURLChange, url);
			var servletParamsChanged:Boolean = detectLinkableObjectChange(handleURLChange, servletParams);
			if (urlChanged || servletParamsChanged)
			{
				if (url.value)
				{
					// if url is specified, do not use csvDataString
					csvData.setSessionState(null);
					if (servletParams.value)
					{
						if (!_servlet || _servlet.servletURL != url.value)
						{
							disposeObject(_servlet);
							_servlet = registerLinkableChild(this, new AMF3Servlet(url.value));
						}
						var token:AsyncToken = _servlet.invokeAsyncMethod(
							servletParams.value[SERVLETPARAMS_PROPERTY_METHOD],
							servletParams.value[SERVLETPARAMS_PROPERTY_PARAMS]
						);
						addAsyncResponder(token, handleServletResponse, handleServletError, getSessionState(this));
					}
					else
					{
						disposeObject(_servlet);
						_servlet = null;
						WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(url.value), handleCSVDownload, handleCSVDownloadError, url.value, URLLoaderDataFormat.TEXT);
					}
				}
			}
		}
		
		private function handleServletResponse(event:ResultEvent, sessionState:Object):void
		{
			if (WeaveAPI.SessionManager.computeDiff(sessionState, getSessionState(this)) !== undefined)
				return;
			var data:Array = event.result as Array;
			if (!data)
			{
				reportError('Result from servlet is not an Array');
				return;
			}
			if (data.length && !(data[0] is Array))
				data = WeaveAPI.CSVParser.convertRecordsToRows(data);
			
			handleParsedRows(data);
			getCallbackCollection(this).triggerCallbacks();
		}
		private function handleServletError(event:FaultEvent, sessionState:Object):void
		{
			if (WeaveAPI.SessionManager.computeDiff(sessionState, getSessionState(this)) !== undefined)
				return;
			reportError(event);
		}
	}
}
