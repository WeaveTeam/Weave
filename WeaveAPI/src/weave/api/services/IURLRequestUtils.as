/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Weave API.
 *
 * The Initial Developer of the Original Code is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

package weave.api.services
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.core.mx_internal;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.services.IURLRequestToken;

	/**
	 * An interface for GET and POST URL requests.
	 * 
	 * @author adufilie
	 */
	public interface IURLRequestUtils
	{
		/**
		 * This function performs an HTTP GET request and calls result or fault handlers when the request succeeds or fails.
		 * @param request The URL to get.
		 * @param resultHandler A function with the following signature:  function(e:ResultEvent, token:Object = null):void.  This function will be called if the request succeeds.
		 * @param errorHandler A function with the following signature:  function(e:FaultEvent, token:Object = null):void.  This function will be called if there is an error.
		 * @param token An object that gets passed to the handler functions.
		 * @param dataFormat The value to set as the dataFormat property of a URLLoader object.
		 * @return The URLLoader used to perform the HTTP GET request.
		 */
		function getURL(request:URLRequest, asyncResultHandler:Function = null, asyncFaultHandler:Function = null, token:Object = null, dataFormat:String = "binary"):URLLoader;

		/**
		 * This function will download content from a URL and call the given handler functions when it completes or a fault occurrs.
		 * @param request The URL from which to get content.
		 * @param asyncResultHandler A function with the following signature:  function(e:ResultEvent, token:Object = null):void.  This function will be called if the request succeeds.
		 * @param asyncErrorHandler A function with the following signature:  function(e:FaultEvent, token:Object = null):void.  This function will be called if there is an error.
		 * @param token An object that gets passed to the handler functions.
		 * @param useCache A boolean indicating whether to use the cached images. If set to <code>true</code>, this function will return null if there is already a bitmap for the request.
		 * @return An IURLRequestToken that can be used to cancel the request and cancel the async handlers.
		 */
		function getContent(request:URLRequest, asyncResultHandler:Function = null, asyncFaultHandler:Function = null, token:Object = null, useCache:Boolean = true):IURLRequestToken;
	}
}
