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
	import weavejs.api.net.IURLRequestUtils;
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
		
		public static const RESPONSE_TEXT:String = 'text';
		public static const RESPONSE_ARRAYBUFFER:String = 'arraybuffer';
		public static const RESPONSE_JSON:String = 'json';
		public static const RESPONSE_BLOB:String = 'blob';
		public static const RESPONSE_DOCUMENT:String = 'document';
		
		/**
		 * @inheritDoc
		 */
		public function request(relevantContext:Object, method:String, url:String, requestHeaders:Object, data:String, responseType:String):WeavePromise
		{
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
	}
}
