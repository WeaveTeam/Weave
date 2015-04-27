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
	import flash.external.ExternalInterface;
	
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.reportError;
	import weave.core.ClassUtils;
	import weave.utils.WeavePromise;

	public class JsonCache implements ILinkableObject
	{
		public function JsonCache()
		{
		}
		
		private var cache:Object = {};
		
		public function clearCache():void
		{
			for each (var entry:CacheEntry in cache)
				entry.dispose();
			cache = {};
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * @param url The URL to get JSON data
		 * @param resultHandler A function that will receive the resulting Object as its first parameter
		 * @return The cached Object.
		 */
		public function getJsonObject(url:String, resultHandler:Function = null, faultHandler:Function = null):Object
		{
			var entry:CacheEntry = cache[url];
			if (!entry)
			{
				entry = new CacheEntry(this, url);
				cache[url] = entry;
			}
			entry.addHandler(resultHandler, faultHandler);
			return entry.result;
		}
		
		public function getJsonPromise(relevantContext:Object, url:String):WeavePromise
		{
			return new WeavePromise(relevantContext, function(resolve:Function, reject:Function):void {
				getJsonObject(url, resolve, reject);
			});
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

import flash.events.Event;
import flash.net.URLRequest;

import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;
import mx.utils.StringUtil;

import weave.api.reportError;
import weave.services.JsonCache;
import weave.services.URLRequestUtils;
import weave.services.addAsyncResponder;

internal class CacheEntry
{
	public function CacheEntry(owner:JsonCache, url:String)
	{
		this.owner = owner;
		this.url = url;
		
		addAsyncResponder(
			WeaveAPI.URLRequestUtils.getURL(owner, new URLRequest(url), URLRequestUtils.DATA_FORMAT_TEXT),
			handleResponse,
			handleResponse
		);
	}
	
	public var owner:JsonCache;
	public var url:String;
	public var handlers:Array = [];
	public var result:Object = {};
	public var success:Boolean = false;
	
	private function handleResponse(event:Event, token:Object = null):void
	{
		// stop if disposed
		if (!owner)
			return;
		
		var response:Object;
		if (event is ResultEvent)
		{
			success = true;
			response = (event as ResultEvent).result;
			response = JsonCache.parseJSON(response as String);
			// avoid storing a null value
			if (response != null)
				result = response;
		}
		else
		{
			success = false;
			response = (event as FaultEvent).fault.content;
			if (response)
				reportError("Request failed: " + url + "\n" + StringUtil.trim(String(response)));
			else
				reportError(event);
		}
		
		// call handlers
		while (handlers.length)
		{
			var obj:Object = handlers.shift();
			if (event is ResultEvent && obj[RESULT] is Function)
				(obj[RESULT] as Function).apply(null, [result]);
			if (event is FaultEvent && obj[FAULT] is Function)
				(obj[FAULT] as Function).apply(null, [result]);
		}
		// stop further handlers from being added
		handlers = null;
	}
	
	private static const RESULT:int = 0; // index of resultHandler in handlers item
	private static const FAULT:int = 1; // index of faultHandler in handlers item
	
	public function addHandler(resultHandler:Function, faultHandler:Function):void
	{
		if (handlers)
		{
			handlers.push([resultHandler, faultHandler]);
		}
		else
		{
			if (success && resultHandler is Function)
				resultHandler(result);
			if (!success && faultHandler is Function)
				faultHandler(result);
		}
	}
	
	public function dispose():void
	{
		owner = null;
		handlers = null;
	}
}
