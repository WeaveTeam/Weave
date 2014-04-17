/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

/**
 * The code below assumes it is being executed within a function(){} where the 'weave' variable is defined.
 * @namespace weave
 * @description The Weave instance.
 * @private
 */

/**
 * Makes a URL request and calls weave.ExternalDownloader_callback() when done.
 * @param {string} id Identifies the request
 * @param {string} method Either "GET" or "POST"
 * @param {string} url The URL
 * @param {Object.<String,String>} Maps request header names to values
 * @param {string} base64data Base64-encoded data, specified if method is "POST"
 */
weave.ExternalDownloader_request = function (id, method, url, requestHeaders, base64data) {
	console.log('request', url, requestHeaders, base64data);
	var done = false;
	var request = new XMLHttpRequest();
	request.open(method, url, true);
	//request.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
	for (var name in requestHeaders)
		request.setRequestHeader(name, requestHeaders[name], false);
	request.responseType = "blob";
	request.onload = function(event) {
		var blob = request.response;
		var reader = new FileReader();
		reader.onloadend = function(event) {
			var url = reader.result;
			var base64data = url.split(',').pop();
			weave.ExternalDownloader_callback(id, request.status, base64data);
			done = true;
		};
		reader.onerror = function(event) {
			weave.ExternalDownloader_callback(id, request.status, null);
			done = true;
		};
		reader.readAsDataURL(blob);
	};
	request.onerror = function(event) {
		if (!done)
			weave.ExternalDownloader_callback(id, request.status, null);
		done = true;
	}
	request.onreadystatechange = function() {
		if (request.readyState == 4 && request.status != 200)
		{
			setTimeout(
				function() {
					if (!done)
						weave.ExternalDownloader_callback(id, request.status, null);
					done = true;
				},
				1000
			);
		}
	};
	var data = null;
	if (method == "POST" && base64data)
	{
		var byteCharacters = atob(base64data);
		var myArray = new ArrayBuffer(byteCharacters.length);
		var longInt8View = new Uint8Array(myArray);
        for (var i = 0; i < byteCharacters.length; i++)
        	longInt8View[i] = byteCharacters.charCodeAt(i);
        data = myArray;
	}
	request.send(data);
};
