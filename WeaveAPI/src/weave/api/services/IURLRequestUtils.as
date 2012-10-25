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

package weave.api.services
{
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	/**
	 * An interface for GET and POST URL requests.
	 * 
	 * @author adufilie
	 */
	public interface IURLRequestUtils
	{
		/**
		 * This will set the base URL for use with relative URL requests.
		 */
		function setBaseURL(baseURL:String):void;
		
		/**
		 * This function performs an HTTP GET request and calls result or fault handlers when the request succeeds or fails.
		 * @param relevantContext Specifies an object that the async handlers are relevant to.  If the object is disposed via WeaveAPI.SessionManager.dispose() before the download finishes, the async handler functions will not be called.  This parameter may be null.
		 * @param request The URL to get.
		 * @param asyncResultHandler A function with the following signature:  function(e:ResultEvent, token:Object = null):void.  This function will be called if the request succeeds.
		 * @param asyncFaultHandler A function with the following signature:  function(e:FaultEvent, token:Object = null):void.  This function will be called if there is an error.
		 * @param token An object that gets passed to the handler functions.
		 * @param dataFormat The value to set as the dataFormat property of a URLLoader object.
		 * @return The URLLoader used to perform the HTTP GET request.
		 */
		function getURL(relevantContext:Object, request:URLRequest, asyncResultHandler:Function = null, asyncFaultHandler:Function = null, token:Object = null, dataFormat:String = "binary"):URLLoader;

		/**
		 * This function will download content from a URL and call the given handler functions when it completes or a fault occurrs.
		 * @param relevantContext Specifies an object that the async handlers are relevant to.  If the object is disposed via WeaveAPI.SessionManager.dispose() before the download finishes, the async handler functions will not be called.  This parameter may be null.
		 * @param request The URL from which to get content.
		 * @param asyncResultHandler A function with the following signature:  function(e:ResultEvent, token:Object = null):void.  This function will be called if the request succeeds.
		 * @param asyncFaultHandler A function with the following signature:  function(e:FaultEvent, token:Object = null):void.  This function will be called if there is an error.
		 * @param token An object that gets passed to the handler functions.
		 * @param useCache A boolean indicating whether to use the cached images. If set to <code>true</code>, this function will return null if there is already a bitmap for the request.
		 * @return An IURLRequestToken that can be used to cancel the request and cancel the async handlers.
		 */
		function getContent(relevantContext:Object, request:URLRequest, asyncResultHandler:Function = null, asyncFaultHandler:Function = null, token:Object = null, useCache:Boolean = true):IURLRequestToken;
		
		/**
		 * This function will download an image from the URL and call the given handler functions when it completes or a fault occurrs.
		 * @param relevantContext Specifies an object that the async handlers are relevant to.  If the object is disposed via WeaveAPI.SessionManager.dispose() before the download finishes, the async handler functions will not be called.  This parameter may be null.
		 * @param request The URL from which to get the image.
		 * @param asyncResultHandler A function with the following signature:  function(e:ResultEvent, token:Object = null):void.  This function will be called if the request succeeds.
		 * @param asyncFaultHandler A function with the following signature:  function(e:FaultEvent, token:Object = null):void.  This function will be called if there is an error.
		 * @param token An object that gets passed to the handler functions.
		 * @param useCache A boolean indicating whether to use the cached images. If set to <code>true</code>, this function will return null if there is already a bitmap for the request.
		 * @return An IURLRequestToken that can be used to cancel the request and cancel the async handlers.
		 */
		function getImage(relavantContext:Object, request:URLRequest, asyncResulthandler:Function = null, asyncFaultHandler:Function = null, token:Object = null, useCache:Boolean = true):void;
	}
}
