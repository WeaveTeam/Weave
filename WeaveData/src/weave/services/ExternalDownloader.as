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
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.core.mx_internal;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.Base64Decoder;
	import mx.utils.ObjectUtil;
	import mx.utils.UIDUtil;
	import mx.utils.URLUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.reportError;

	public class ExternalDownloader
	{
		[Embed(source="ExternalDownloader.js", mimeType="application/octet-stream")]
		private static const JS_ExternalDownloader:Class;
		
		/**
		 * This maps a unique ID (generated when a request is made to download from a URL through this class)
		 * to a QueryToken associated with it.
		 */
		private static const uniqueIDToTokenMap:Object = new Object();
		
		private static var _initialized:Boolean = false;
		
		private static function initialize():void
		{
			if(_initialized)
				return;
			
			try
			{
				// execute embedded scripts
				WeaveAPI.executeJavaScript(new JS_ExternalDownloader());
				
				// expose the result and fault callbacks for javascript to use by jquery
				ExternalInterface.addCallback("ExternalDownloader_result", externalResult);
				ExternalInterface.addCallback("ExternalDownloader_fault",  externalFault);
				
				_initialized = true;
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		
		public static function download(urlRequest:URLRequest, dataFormat:String, token:AsyncToken, onFail:Function):void
		{
			initialize();
			
			//TODO: support HTTP POST with binary data
			// https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/Sending_and_Receiving_Binary_Data#Sending_binary_data
			
			var url:String = urlRequest.url;
			if (urlRequest.data is URLVariables)
				url += "?" + urlRequest.data;
				
			var uniqueID:String = UIDUtil.createUID();
			uniqueIDToTokenMap[uniqueID] = new QueryToken(url, dataFormat, token, onFail);
			
			WeaveAPI.executeJavaScript("weave.ExternalDownloader_get(id, url);", {"id": uniqueID, "url": url});
		}
		
		private static function externalResult(id:String, base64data:String):void
		{
			var qt:QueryToken = uniqueIDToTokenMap[id] as QueryToken;
			delete uniqueIDToTokenMap[id];
			
			var decoder:Base64Decoder = new Base64Decoder();
			decoder.decode(base64data);
			
			var result:Object;
			if (qt.dataFormat == URLRequestUtils.DATA_FORMAT_BINARY)
				result = decoder.flush();
			else
				result = decoder.flush().toString();
			
			qt.asyncToken.mx_internal::applyResult(ResultEvent.createEvent(result, qt.asyncToken));
		}
		
		private static function externalFault(id:String, request:Object, error:Object):void
		{
			var qt:QueryToken = uniqueIDToTokenMap[id] as QueryToken;
			delete uniqueIDToTokenMap[id];
			
			var fault:Fault = new Fault(SecurityErrorEvent.SECURITY_ERROR, SecurityErrorEvent.SECURITY_ERROR, "Cross-domain access is not permitted for URL: " + qt.url);
			fault.rootCause = error;
			fault.content = request;
			qt.asyncToken.mx_internal::applyFault(FaultEvent.createEvent(fault, qt.asyncToken));
			//trace("FAULT! getting " + qt.url);
		}
	}
}
import mx.rpc.AsyncToken;

internal class QueryToken
{
	public function QueryToken(url:String, dataFormat:String, asyncToken:AsyncToken, onFail:Function)
	{
		this.url = url;
		this.dataFormat = dataFormat;
		this.asyncToken = asyncToken;
		this.onFail = onFail;
	}
	
	public var url:String;
	public var dataFormat:String;
	public var asyncToken:AsyncToken;
	public var onFail:Function;
}
