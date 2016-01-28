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
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.net.IURLRequestUtils;
	import weavejs.util.Dictionary2D;
	import weavejs.util.JS;
	import weavejs.util.WeavePromise;

	public class URLRequestUtils implements IURLRequestUtils
	{
		private function byteArrayToDataUri(byteArray:/*Uint8*/Array, mimeType:String):String
		{
			return "data:" + (mimeType || '') + ';base64,' + JS.global.btoa(byteArrayToString(byteArray));
		}
		
		private function byteArrayToString(byteArray:/*Uint8*/Array):String
		{
			var CHUNK_SIZE:int = 8192;
			var n:int = byteArray.length;
			if (n <= CHUNK_SIZE)
				return String.fromCharCode.apply(String, byteArray);
			var strings:Array = [];
			for (var i:int = 0; i < byteArray.length;)
				strings.push(String.fromCharCode.apply(null, byteArray.subarray(i, i += CHUNK_SIZE)));
			return strings.join('');
		}
		
		public function request(relevantContext:Object, urlRequest:URLRequest):WeavePromise
		{
			var responseType:String = urlRequest.responseType || ResponseType.UINT8ARRAY;
			
			if (urlRequest.url.indexOf(LOCAL_FILE_URL_SCHEME) == 0)
			{
				var weaveRoot:ILinkableHashMap = Weave.getRoot(relevantContext as ILinkableObject);
				var promise:WeavePromise = get_d2d_context_url_promise(weaveRoot, urlRequest.url);
				if (!promise.getResult() && !promise.getError())
					promise.setError(Weave.lang("Local file missing: {0}", urlRequest.url.substr(LOCAL_FILE_URL_SCHEME.length)));
				promise = promise.then(function(byteArray:/*Uint8*/Array):Object {
					return new WeavePromise(relevantContext, function(resolve:Function, reject:Function):* {
						switch (responseType) {
							default:
							case ResponseType.TEXT:
								return resolve(byteArrayToString(byteArray));
							case ResponseType.JSON:
								return resolve(JSON.parse(byteArrayToString(byteArray)));
							case ResponseType.BLOB:
								return resolve(new JS.global.Blob([byteArray.buffer]));
							case ResponseType.ARRAYBUFFER:
								return resolve(byteArray.buffer);
							case ResponseType.DOCUMENT:
								return reject(new Error("responseType " + ResponseType.DOCUMENT + " not supported for local files"));
							case ResponseType.UINT8ARRAY:
								return resolve(byteArray);
							case ResponseType.DATAURI:
								return resolve(byteArrayToDataUri(byteArray, urlRequest.mimeType));
						}
					});
				});
			}
			else
			{
				//TODO WeavePromise needs a way to specify a dispose handler (new WeavePromise(context, resolver, cleanup))
				// so we can cancel the request automatically when the promise is disposed
				promise = new WeavePromise(relevantContext, function(resolve:Function, reject:Function):void {
					var done:Boolean = false;
					var ie9_XHR:Class = JS.global.XDomainRequest;
					var XHR:Class = ie9_XHR || JS.global.XMLHttpRequest;
					var xhr:Object = new XHR();
					xhr.open(urlRequest.method || RequestMethod.GET, urlRequest.url, true);
					for (var name:String in urlRequest.requestHeaders)
						xhr.setRequestHeader(name, urlRequest.requestHeaders[name], false);
					
					if (responseType === ResponseType.UINT8ARRAY || responseType === ResponseType.DATAURI)
						xhr.responseType = ResponseType.ARRAYBUFFER;
					else
						xhr.responseType = responseType;
					
					xhr.onload = function(event:*):void {
						var result:* = ie9_XHR ? xhr.responseText : xhr.response;
						
						if (responseType === ResponseType.UINT8ARRAY)
							result = new JS.Uint8Array(result);
						if (responseType === ResponseType.DATAURI)
							result = byteArrayToDataUri(new JS.Uint8Array(result), urlRequest.mimeType);
						
						resolve(result);
						done = true;
					};
					xhr.onerror = function(event:*):void {
						if (!done)
							reject(xhr);
						done = true;
					};
					xhr.onreadystatechange = function():void {
						if (xhr.readyState == 4 && xhr.status != 200)
						{
							JS.setTimeout(
								function():void {
									if (!done)
										reject(xhr);
									done = true;
								},
								1000
							);
						}
					};
					xhr.send(urlRequest.data);
				});
			}
			
			var ilo:ILinkableObject = relevantContext as ILinkableObject;
			if (ilo)
				WeaveAPI.ProgressIndicator.addTask(promise, ilo, request.url);
			
			return promise;
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
			promise.setResult(null);
			//promise.setError(Weave.lang('File removed: {0}', url));
		}
		
		public function getLocalFileNames(weaveRoot:ILinkableHashMap):Array
		{
			return JS.mapKeys(d2d_context_url_promise.map.get(weaveRoot)).sort();
		}
	}
}
