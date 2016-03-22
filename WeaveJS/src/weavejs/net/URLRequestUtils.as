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
		private function byteArrayToDataUri(byteArray:/*/Uint8Array/*/Array, mimeType:String):String
		{
			return "data:" + (mimeType || '') + ';base64,' + JS.global.btoa(byteArrayToString(byteArray));
		}
		
		private function byteArrayToString(byteArray:/*/Uint8Array/*/Array):String
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
			var promise:WeavePromise;
			
			if (String(urlRequest.url).indexOf(LOCAL_FILE_URL_SCHEME) == 0)
			{
				var fileName:String = String(urlRequest.url).substr(LOCAL_FILE_URL_SCHEME.length);
				var weaveRoot:ILinkableHashMap = Weave.getRoot(relevantContext as ILinkableObject);
				var cachedPromise:WeavePromise = get_d2d_weaveRoot_fileName_promise(weaveRoot, fileName);
				if (cachedPromise.getResult() == null && cachedPromise.getError() == null)
				{
					if (weaveRoot)
						removeLocalFile(weaveRoot, fileName);
					else
						cachedPromise.setError(new Error(Weave.lang("To request a " + LOCAL_FILE_URL_SCHEME + " URL, the relevantContext must be an ILinkableObject registered under an instance of Weave.")));
				}
				promise = new WeavePromise(relevantContext)
					.setResult(cachedPromise)
					.then(function(byteArray:/*/Uint8Array/*/Array):Object {
						switch (responseType) {
							default:
							case ResponseType.TEXT:
								return byteArrayToString(byteArray);
							case ResponseType.JSON:
								return JSON.parse(byteArrayToString(byteArray));
							case ResponseType.BLOB:
								return new JS.global.Blob([byteArray.buffer]);
							case ResponseType.ARRAYBUFFER:
								return byteArray.buffer;
							case ResponseType.DOCUMENT:
								throw new Error("responseType " + ResponseType.DOCUMENT + " not supported for local files");
							case ResponseType.UINT8ARRAY:
								return byteArray;
							case ResponseType.DATAURI:
								return byteArrayToDataUri(byteArray, urlRequest.mimeType);
						}
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
				WeaveAPI.ProgressIndicator.addTask(promise, ilo, urlRequest.url);
			
			return promise;
		}
		
		public static const LOCAL_FILE_URL_SCHEME:String = 'local://';
		
		private const d2d_weaveRoot_fileName_promise:Dictionary2D = new Dictionary2D(true);
		private function get_d2d_weaveRoot_fileName_promise(weaveRoot:ILinkableHashMap, fileName:String):WeavePromise
		{
			var context:Object = weaveRoot || this; // use (this) instead of (null) to avoid WeakMap invalid key error
			var promise:WeavePromise = d2d_weaveRoot_fileName_promise.get(context, fileName);
			if (!promise)
			{
				promise = new WeavePromise(context).setResult(null);
				d2d_weaveRoot_fileName_promise.set(context, fileName, promise);
			}
			return promise;
		}
		
		public function saveLocalFile(weaveRoot:ILinkableHashMap, fileName:String, byteArray:/*/Uint8Array/*/Array):String
		{
			var promise:WeavePromise = get_d2d_weaveRoot_fileName_promise(weaveRoot, fileName);
			promise.setResult(byteArray);
			return LOCAL_FILE_URL_SCHEME + fileName;
		}
		
		public function getLocalFile(weaveRoot:ILinkableHashMap, fileName:String):/*/Uint8Array/*/Array
		{
			var promise:WeavePromise = get_d2d_weaveRoot_fileName_promise(weaveRoot, fileName);
			var result:* = promise.getResult();
			return result;
		}
		
		public function removeLocalFile(weaveRoot:ILinkableHashMap, fileName:String):void
		{
			var promise:WeavePromise = get_d2d_weaveRoot_fileName_promise(weaveRoot, fileName);
			promise.setError(new Error(Weave.lang("Local file missing: {0}", fileName)));
		}
		
		public function getLocalFileNames(weaveRoot:ILinkableHashMap):Array
		{
			return d2d_weaveRoot_fileName_promise.secondaryKeys(weaveRoot).sort();
		}
	}
}
