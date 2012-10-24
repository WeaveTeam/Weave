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
	import mx.utils.UIDUtil;
	
	import weave.api.reportError;

	public class JQueryCaller
	{
		[Embed(source="jquery-caller.js", mimeType="application/octet-stream")]
		private static const JQCaller:Class;
		[Embed(source="jquery-1.7.1.min.js", mimeType="application/octet-stream")]
		private static const JQ:Class;
		
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
				// load the embedded jquery javascript file so it can be used as any other loaded
				// javascript file would
				var jq:String = String(new JQ());
				ExternalInterface.call('function(){' + jq + '}');
				
				// do the same for the javascript file that makes use of jquery
				var jqc:String = String(new JQCaller());
				ExternalInterface.call('function(){' + jqc + '}');
				
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
		
		public static function getFileFromURL(url:String, token:AsyncToken):void
		{
			initialize();
				
			var uniqueID:String = UIDUtil.createUID();
			uniqueIDToTokenMap[uniqueID] = new QueryToken(url, token);
			
			ExternalInterface.call("WeaveJQueryCaller.getFile('"+url+"', '"+uniqueID+"')");
		}
		
		public static function jqueryResult(id:String, data:Object):void
		{
			trace("RESULT!", data);
			var qt:QueryToken = uniqueIDToTokenMap[id] as QueryToken;

			qt.asyncToken.mx_internal::applyResult(ResultEvent.createEvent(data, qt.asyncToken));
			
			delete uniqueIDToTokenMap[id];
		}
		
		public static function jqueryFault(id:String, errorThrown:Object):void
		{
			var qt:QueryToken = uniqueIDToTokenMap[id] as QueryToken;
			
			var fault:Fault = new Fault(SecurityErrorEvent.SECURITY_ERROR, SecurityErrorEvent.SECURITY_ERROR, "JQuery failed to download from url.");
			fault.rootCause = errorThrown;
			qt.asyncToken.mx_internal::applyFault(FaultEvent.createEvent(fault, qt.asyncToken));
			trace("FAULT! getting " + qt.url);
			
			delete uniqueIDToTokenMap[id];
		}
	}
}
import mx.rpc.AsyncToken;

internal class QueryToken
{
	public function QueryToken(url:String, asyncToken:AsyncToken)
	{
		this.url = url;
		this.asyncToken = asyncToken;
	}
	
	public var url:String;
	public var asyncToken:AsyncToken;
}
