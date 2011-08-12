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
	
	import weave.api.WeaveAPI;
	import weave.core.ErrorManager;
	import weave.utils.ByteArrayUtils;

	public class JQueryCaller
	{
		[Embed("jquery-caller.js", mimeType="application/octet-stream")]
		private static const JQCaller:Class;
		[Embed("jquery-1.5.2.js", mimeType="application/octet-stream")]
		private static const JQ:Class;
		
		/**
		 * uniqueIDToTokenMap
		 * This maps a unique ID (generated when a request is made to download from a URL through this class)
		 * to an AsyncToken associated with it.
		 */
		private static const uniqueIDToTokenMap:Dictionary = new Dictionary(true);
		
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
				WeaveAPI.ErrorManager.reportError(e);
			}
		}
		
		public static function getFileFromURL(url:String, token:AsyncToken):void
		{
			initialize();
				
			var uniqueID:String = UIDUtil.createUID();
			uniqueIDToTokenMap[uniqueID] = token;
			
			ExternalInterface.call("WeaveJQueryCaller.getFile('"+url+"', '"+uniqueID+"')");
			
		}
		
		public static function jqueryResult(id:String, data:Object):void
		{
			trace("RESULT!", data);
			var token:AsyncToken = uniqueIDToTokenMap[id] as AsyncToken;

			token.mx_internal::applyResult(ResultEvent.createEvent(data, token));
			
			delete uniqueIDToTokenMap[id];
		}
		
		public static function jqueryFault(id:String, url:String,...params):void
		{
			var token:AsyncToken = uniqueIDToTokenMap[id] as AsyncToken;
			
			var fault:Fault = new Fault(SecurityErrorEvent.SECURITY_ERROR, SecurityErrorEvent.SECURITY_ERROR, "JQuery failed to download from url.");
			token.mx_internal::applyFault(FaultEvent.createEvent(fault, token));
			trace("FAULT! getting " + url);
			
			delete uniqueIDToTokenMap[id];
		}

		private static const staticDecoder:Base64Decoder = new Base64Decoder();
	}
}