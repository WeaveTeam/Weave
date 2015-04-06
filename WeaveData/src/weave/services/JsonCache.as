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

package weave.services
{
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.StringUtil;
	
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.reportError;
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
				addAsyncResponder(
					WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(url), URLRequestUtils.DATA_FORMAT_TEXT),
					handleResponse,
					handleResponse,
					url
				);
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
					reportError("Request failed: " + url + "\n" + StringUtil.trim(String(response)));
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
