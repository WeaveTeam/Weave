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

package weavejs.net
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableObject;
	import weavejs.util.WeavePromise;

	public class JsonCache implements ILinkableObject
	{
		public static function buildURL(base:String, params:Object):String
		{
			var paramsStr:String = '';
			for (var key:String in params)
				paramsStr += (paramsStr ? '&' : '?') + encodeURIComponent(key) + '=' + encodeURIComponent(params[key]);
			return base + paramsStr;
		}
		
		/**
		 * @param requestHeaders Optionally set this to an Object mapping header names to values.
		 */
		public function JsonCache(requestHeaders:Object = null)
		{
			this.requestHeaders = requestHeaders;
		}
		
		private var requestHeaders:Object = null;
		
		private var cache:Object = {};
		
		public function clearCache():void
		{
			for each (var promise:WeavePromise in cache)
				Weave.dispose(promise);
			cache = {};
			Weave.getCallbacks(this).triggerCallbacks();
		}
		
		/**
		 * @param url The URL to get JSON data
		 * @return The cached Object.
		 */
		public function getJsonObject(url:String):Object
		{
			return getJsonPromise(url).getResult();
		}
		
		public function getJsonPromise(url:String):WeavePromise/*/<any>/*/
		{
			var promise:WeavePromise = cache[url];
			if (!promise)
			{
				var request:URLRequest = new URLRequest(url);
				request.requestHeaders = requestHeaders;
				request.responseType = ResponseType.JSON;
				promise = new WeavePromise(this)
					.setResult(WeaveAPI.URLRequestUtils.request(this, request))
					.then(function(result:Object):Object { return result || {}; });
				cache[url] = promise;
			}
			return promise;
		}
	}
}
