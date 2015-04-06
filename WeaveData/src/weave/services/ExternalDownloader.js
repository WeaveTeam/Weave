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
	var request = new XMLHttpRequest();
	request.open(method, url, true);
	for (var name in requestHeaders)
		request.setRequestHeader(name, requestHeaders[name], false);
	request.responseType = "blob";
	request.onload = function(event) {
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


