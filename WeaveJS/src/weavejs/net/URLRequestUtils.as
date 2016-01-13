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
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.net.IURLRequestUtils;
	import weavejs.util.Dictionary2D;
	import weavejs.util.JS;
	import weavejs.util.WeavePromise;

	/**
	 * An all-static class containing functions for downloading URLs.
	 * 
	 * @author adufilie
	 */
	public class URLRequestUtils implements IURLRequestUtils
	{
		public static const METHOD_GET:String = 'get';
		public static const METHOD_POST:String = 'post';
		
		public static const RESPONSE_ARRAYBUFFER:String = 'arraybuffer';
		public static const RESPONSE_BLOB:String = 'blob';
		public static const RESPONSE_DOCUMENT:String = 'document';
		public static const RESPONSE_JSON:String = 'json';
		public static const RESPONSE_TEXT:String = 'text';
		
		private function byteArrayToString(byteArray:Array):String
		{
			var CHUNK_SIZE:int = 8192;
			var n:int = byteArray.length;
			if (n <= CHUNK_SIZE)
				return String.fromCharCode.apply(String, byteArray);
			var strings:Array = [];
			for (var i:int = 0; i < byteArray.length;)
				strings.push(String.fromCharCode.apply(null, byteArray.slice(i, i += CHUNK_SIZE)));
			return strings.join('');
		}
		
		public function request(relevantContext:Object, method:String, url:String, requestHeaders:Object, data:String, responseType:String):WeavePromise
		{
			if (url.indexOf(LOCAL_FILE_URL_SCHEME) == 0)
			{
				var weaveRoot:ILinkableHashMap = Weave.getRoot(relevantContext as ILinkableObject);
				var promise:WeavePromise = get_d2d_context_url_promise(weaveRoot, url);
				if (!promise.getResult() && !promise.getError())
					promise.setError(Weave.lang("Local file missing: {0}", url.substr(LOCAL_FILE_URL_SCHEME.length)));
				return promise.then(function(byteArray:/*Uint8*/Array):Object {
					return new WeavePromise(relevantContext, function(resolve:Function, reject:Function):* {
						switch (responseType) {
							default:
							case RESPONSE_TEXT:
								return resolve(byteArrayToString(byteArray));
							case RESPONSE_JSON:
								return resolve(JSON.parse(byteArrayToString(byteArray)));
							case RESPONSE_BLOB:
								return resolve(new JS.global.Blob([byteArray.buffer]));
							case RESPONSE_ARRAYBUFFER:
								return resolve(byteArray.buffer);
							case RESPONSE_DOCUMENT:
								return reject(new Error("responseType " + RESPONSE_DOCUMENT + " not supported for local files"));
						}
					});
				});
			}
			
			return new WeavePromise(relevantContext, function(resolve:Function, reject:Function):void {
				var done:Boolean = false;
				var ie9_XHR:Class = JS.global.XDomainRequest;
				var XHR:Class = ie9_XHR || JS.global.XMLHttpRequest;
				var request:Object = new XHR();
				request.open(method, url, true);
				for (var name:String in requestHeaders)
					request.setRequestHeader(name, requestHeaders[name], false);
				request.responseType = responseType;
				request.onload = function(event):void {
					resolve(ie9_XHR ? request.responseText : request.response);
					done = true;
				};
				request.onerror = function(event):void {
					if (!done)
						reject(request);
					done = true;
				};
				request.onreadystatechange = function():void {
					if (request.readyState == 4 && request.status != 200)
					{
						JS.setTimeout(
							function():void {
								if (!done)
									reject(request);
								done = true;
							},
							1000
						);
					}
				};
				request.send(data);
			});
		}
		
		public static const LOCAL_FILE_URL_SCHEME:String = 'local://';
		
		private const d2d_context_url_promise:Dictionary2D = new Dictionary2D();
		private function get_d2d_context_url_promise(weaveRoot:ILinkableHashMap, url:String):WeavePromise
		{
			var promise:WeavePromise = d2d_context_url_promise.get(weaveRoot, url);
			if (!promise)
			{
				promise = new WeavePromise(weaveRoot).setResult(null);
				d2d_context_url_promise.set(weaveRoot, url, promise);
			}
			return promise;
		}
		
		public function saveLocalFile(weaveRoot:ILinkableHashMap, name:String, byteArray:/*Uint8*/Array):String
		{
			var url:String = LOCAL_FILE_URL_SCHEME + name;
			var promise:WeavePromise = get_d2d_context_url_promise(weaveRoot, url);
			promise.setResult(byteArray);
			return url;
		}
		
		public function getLocalFile(weaveRoot:ILinkableHashMap, name:String):/*Uint8*/Array
		{
			var url:String = LOCAL_FILE_URL_SCHEME + name;
			var promise:WeavePromise = get_d2d_context_url_promise(weaveRoot, url);
			var result:* = promise.getResult();
			return result;
		}
		
		public function removeLocalFile(weaveRoot:ILinkableHashMap, name:String):void
		{
			var url:String = LOCAL_FILE_URL_SCHEME + name;
			var promise:WeavePromise = get_d2d_context_url_promise(weaveRoot, url);
			promise.setError(Weave.lang('File removed: {0}', url));
		}
		
		public function getLocalFileNames(weaveRoot:ILinkableHashMap):Array
		{
			return JS.mapKeys(d2d_context_url_promise.map.get(weaveRoot)).sort();
		}
	}
}
