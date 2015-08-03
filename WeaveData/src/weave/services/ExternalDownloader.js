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

/**
 * Makes a URL request and calls weave.ExternalDownloader_callback() when done.
 * @private
 * @param {string} id Identifies the request
 * @param {string} method Either "GET" or "POST"
 * @param {string} url The URL
 * @param {Object.<String,String>} Maps request header names to values
 * @param {string} base64data Base64-encoded data, specified if method is "POST"
 */
weave.ExternalDownloader_request = function (id, method, url, requestHeaders, base64data) {
	var done = false;
	var ie9_XHR = window.XDomainRequest;
	var XHR = ie9_XHR || XMLHttpRequest;
	var request = new XHR();
	request.open(method, url, true);
	for (var name in requestHeaders)
		request.setRequestHeader(name, requestHeaders[name], false);
	request.responseType = "blob";
	request.onload = function(event) {
		if (ie9_XHR)
		{
			var b64 = ie9_btoa(request.responseText);
			weave.ExternalDownloader_callback(id, request.status, b64);
			done = true;
		}
		else
			weave.Blob_to_b64(request.response, function(b64){
				weave.ExternalDownloader_callback(id, request.status, b64);
				done = true;
			});
	};
	request.onerror = function(event) {
		if (!done)
			weave.ExternalDownloader_callback(id, request.status, null);
		done = true;
	};
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
		data = weave.b64_to_ArrayBuffer(base64data);
	request.send(data);
};

weave.b64_to_ArrayBuffer = function(base64data)
{
	var byteCharacters = atob(base64data);
	var myArray = new ArrayBuffer(byteCharacters.length);
	var longInt8View = new Uint8Array(myArray);
    for (var i = 0; i < byteCharacters.length; i++)
    	longInt8View[i] = byteCharacters.charCodeAt(i);
    return myArray;
};

weave.Blob_to_b64 = function(blob, callback)
{
	var reader = new FileReader();
	reader.onloadend = function(event) {
		var dataurl = reader.result;
		var base64data = dataurl.split(',').pop();
		callback(base64data);
	};
	reader.onerror = function(event) {
		callback(null);
	};
	reader.readAsDataURL(blob);
};

// modified from https://github.com/davidchambers/Base64.js
function ie9_btoa(input) {
	var str = String(input);
	for (
		// initialize result and counter
		var block, charCode, idx = 0, map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=', output = '';
		// if the next str index does not exist:
		//   change the mapping table to "="
		//   check if d has no fractional digits
		str.charAt(idx | 0) || (map = '=', idx % 1);
		// "8 - idx % 1 * 8" generates the sequence 2, 4, 6, 8
		output += map.charAt(63 & block >> 8 - idx % 1 * 8)
	) {
		charCode = str.charCodeAt(idx += 3/4);
		if (charCode > 0xFF) {
			throw new InvalidCharacterError("'btoa' failed: The string to be encoded contains characters outside of the Latin1 range.");
		}
		block = block << 8 | charCode;
	}
	return output;
}
