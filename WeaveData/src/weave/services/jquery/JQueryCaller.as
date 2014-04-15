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
package weave.services.jquery
{
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
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

	public class JQueryCaller
	{
		[Embed(source="jquery-caller.js", mimeType="application/octet-stream")]
		private static const JS_jquery_caller:Class;
		[Embed(source="jquery-1.7.1.min.js", mimeType="application/octet-stream")]
		private static const JS_jquery:Class;
		
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
				WeaveAPI.executeJavaScript(new JS_jquery(), new JS_jquery_caller());
				
				// expose the result and fault callbacks for javascript to use by jquery
				ExternalInterface.addCallback("jqueryResult", jqueryResult);
				ExternalInterface.addCallback("jqueryFault",  jqueryFault);
				
				_initialized = true;
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		
		public static function getFileFromURL(url:String, token:AsyncToken, onFail:Function):void
		{
			initialize();
				
			var uniqueID:String = UIDUtil.createUID();
			uniqueIDToTokenMap[uniqueID] = new QueryToken(url, token, onFail);
			
			ExternalInterface.call("WeaveJQueryCaller.getFile", url, uniqueID);
		}
		
		public static function jqueryResult(id:String, data:String, base64encoded:Boolean, success:Boolean):void
		{
			var qt:QueryToken = uniqueIDToTokenMap[id] as QueryToken;
			delete uniqueIDToTokenMap[id];
			
			if (!success)
			{	
				qt.onFail();
				return;
			}
			
			if (base64encoded)
			{
				var decoder:Base64Decoder = new Base64Decoder();
				decoder.decode(data);
				data = decoder.flush().toString();
			}
			qt.asyncToken.mx_internal::applyResult(ResultEvent.createEvent(data, qt.asyncToken));
		}
		
		public static function jqueryFault(id:String, jqXHR:Object, textStatus:String, errorThrown:String):void
		{
			var qt:QueryToken = uniqueIDToTokenMap[id] as QueryToken;
			delete uniqueIDToTokenMap[id];
			
			var fault:Fault = new Fault(SecurityErrorEvent.SECURITY_ERROR, SecurityErrorEvent.SECURITY_ERROR, "Cross-domain access is not permitted for URL: " + qt.url);
			fault.rootCause = errorThrown;
			fault.content = jqXHR.responseText;
			qt.asyncToken.mx_internal::applyFault(FaultEvent.createEvent(fault, qt.asyncToken));
			//trace("FAULT! getting " + qt.url);
		}
	}
}
import mx.rpc.AsyncToken;

internal class QueryToken
{
	public function QueryToken(url:String, asyncToken:AsyncToken, onFail:Function)
	{
		this.url = url;
		this.asyncToken = asyncToken;
		this.onFail = onFail;
	}
	
	public var url:String;
	public var asyncToken:AsyncToken;
	public var onFail:Function;
}
