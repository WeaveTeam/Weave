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
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.reportError;
	import weave.compiler.Compiler;
	import weave.core.ClassUtils;

	public class JsonCache implements ILinkableObject
	{
		public function JsonCache()
		{
		}
		
		private var cache:Object = {};
		
		public function clearCache():void
		{
			cache = {};
			getCallbackCollection(this).triggerCallbacks();
		}
		
		public function getJsonObject(url:String):Object
		{
			if (!cache.hasOwnProperty(url))
			{
				cache[url] = {};
				WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(url), handleResponse, handleResponse, url, URLRequestUtils.DATA_FORMAT_TEXT);
			}
			return cache[url];
		}
		
		private function handleResponse(event:Event, url:String):void
		{
			var response:Object;
			if (event is ResultEvent)
			{
				response = (event as ResultEvent).result;
				response = parseJSON(response as String);
				if (response)
					cache[url] = response;
			}
			else
			{
				response = (event as FaultEvent).fault.content;
				if (response)
					reportError("Request failed: " + url + "; response=" + Compiler.stringify(response));
				else
					reportError(event);
			}
		}
		
		public static function parseJSON(json:String):Object
		{
			try
			{
				var JSON:Object = ClassUtils.getClassDefinition('JSON');
				if (JSON)
					return JSON.parse(json);
				else if (ExternalInterface.available)
					return ExternalInterface.call('JSON.parse', json);
				
				reportError("No JSON parser available");
			}
			catch (e:Error)
			{
				reportError("Unable to parse JSON result");
				trace(json);
			}
			return null;
		}
	}
}
