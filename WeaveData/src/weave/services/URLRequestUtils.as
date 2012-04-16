/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.services
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
	
	import mx.core.mx_internal;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.services.IURLRequestToken;
	import weave.api.services.IURLRequestUtils;

	/**
	 * An all-static class containing functions for downloading URLs.
	 * 
	 * @author adufilie
	 */
	public class URLRequestUtils implements IURLRequestUtils
	{
		public static const DATA_FORMAT_TEXT:String = URLLoaderDataFormat.TEXT;
		public static const DATA_FORMAT_BINARY:String = URLLoaderDataFormat.BINARY;
		public static const DATA_FORMAT_VARIABLES:String = URLLoaderDataFormat.VARIABLES;
		
		/**
		 * This function performs an HTTP GET request and calls result or fault handlers when the request succeeds or fails.
		 * @param request The URL to get.
		 * @param asyncResultHandler A function with the following signature:  function(e:ResultEvent, token:Object = null):void.  This function will be called if the request succeeds.
		 * @param asyncFaultHandler A function with the following signature:  function(e:FaultEvent, token:Object = null):void.  This function will be called if there is an error.
		 * @param token An object that gets passed to the handler functions.
		 * @param dataFormat The value to set as the dataFormat property of a URLLoader object.
		 * @param reportProgress If set to true, WeaveAPI.ProgressIndicator will be notified of the download progress.
		 * @return The URLLoader used to perform the HTTP GET request.
		 */
		public function getURL(request:URLRequest, asyncResultHandler:Function = null, asyncFaultHandler:Function = null, token:Object = null, dataFormat:String = "binary", reportProgress:Boolean = true):URLLoader
		{
			var urlLoader:CustomURLLoader; 
			try
			{
				urlLoader = new CustomURLLoader(request, dataFormat, reportProgress, true);
				urlLoader.addResponder(new AsyncResponder(asyncResultHandler || noOp, asyncFaultHandler || noOp, token));
			}
			catch (e:Error)
			{
				// When an error occurs, we need to run the asyncFaultHandler later
				// and return a new URLLoader. CustomURLLoader doesn't load if the 
				// last parameter to the constructor is false.
				urlLoader = new CustomURLLoader(request, dataFormat, reportProgress, false);
				WeaveAPI.StageUtils.callLater(
					this, 
					asyncFaultHandler || noOp, 
					[new FaultEvent(FaultEvent.FAULT, false, true, new Fault(String(e.errorID), e.name, e.message)), token]
				);
			}
			
			return urlLoader;
		}
		
		private function noOp(..._):void { } // does nothing

		/**
		 * This function will download content from a URL and call the given handler functions when it completes or a fault occurrs.
		 * @param request The URL from which to get content.
		 * @param asyncResultHandler A function with the following signature:  function(e:ResultEvent, token:Object = null):void.  This function will be called if the request succeeds.
		 * @param asyncFaultHandler A function with the following signature:  function(e:FaultEvent, token:Object = null):void.  This function will be called if there is an error.
		 * @param token An object that gets passed to the handler functions.
		 * @param useCache A boolean indicating whether to use the cached images. If set to <code>true</code>, this function will return null if there is already a bitmap for the request.
		 * @param reportProgress If set to true, WeaveAPI.ProgressIndicator will be notified of the download progress.
		 * @return An IURLRequestToken that can be used to cancel the request and cancel the async handlers.
		 */
		public function getContent(request:URLRequest, asyncResultHandler:Function = null, asyncFaultHandler:Function = null, token:Object = null, useCache:Boolean = true, reportProgress:Boolean = true):IURLRequestToken
		{
			if (useCache)
			{
				var content:Object = _contentCache[request.url]; 
				if (content)
				{
					// create a request token so its cancel function can be used and the result handler won't be called next frame
					var contentRequestToken:ContentRequestToken = new ContentRequestToken(null, asyncResultHandler, asyncFaultHandler, token);
					var resultEvent:ResultEvent = ResultEvent.createEvent(content);
					// wait one frame and make sure to call contentResult() instead of result().
					WeaveAPI.StageUtils.callLater(null, contentRequestToken.contentResult, [resultEvent], false);
					return contentRequestToken;
				}
			}
			
			// check for a loader that is currently downloading this url
			var loader:CustomURLLoader = _requestURLToLoader[request.url] as CustomURLLoader;
			if (loader == null || loader.isClosed)
			{
				// make the request and add handler function that will load the content
				loader = getURL(request, handleGetContentResult, null, request.url, DATA_FORMAT_BINARY, reportProgress) as CustomURLLoader;
				_requestURLToLoader[request.url] = loader;
			}
			
			// create a ContentRequestToken so the handlers will run when the content finishes loading.
			return new ContentRequestToken(loader, asyncResultHandler, asyncFaultHandler, token);
		}
		
		/**
		 * This maps a URL to the content that was downloaded from that URL.
		 */		
		private const _contentCache:Object = new Object();
		
		/**
		 * A mapping of URL Strings to CustomURLLoaders.
		 * This mapping is necessary for cached requests to return the active request.
		 */
		private const _requestURLToLoader:Object = new Object();
		
		/**
		 * This function gets called asynchronously from getContent().
		 * This function may cause both result & fault handlers to occur on original CustomURLLoader object,
		 * but it is ok because nothing outside this class has access to the internal CustomURLLoader
		 * and the result and fault functions added internally do not cause problems when both are called.
		 */
		private function handleGetContentResult(resultEvent:ResultEvent, token:Object = null):void
		{
			var url:String = token as String;
			var customURLLoader:CustomURLLoader = _requestURLToLoader[url] as CustomURLLoader;
			
			var bytes:ByteArray = resultEvent.result as ByteArray;
			if (!bytes || bytes.length == 0)
			{
				var faultEvent:FaultEvent = FaultEvent.createEvent(new Fault("Error", "HTTP GET failed: Content is null from " + url));
				customURLLoader.asyncToken.mx_internal::applyFault(faultEvent);
				return;
			}

			var handleLoaderComplete:Function = function (completeEvent:Event):void
			{
				var loaderInfo:LoaderInfo = completeEvent.target as LoaderInfo;
				var result:Object = loaderInfo.content;
				
				// save the image, run handler, and remove the loader from the dictionary
				_contentCache[url] = result;
				delete _requestURLToLoader[url];
				// run the responders from ContentRequestTokens that were not called before
				var responders:Array = customURLLoader.asyncToken.responders;
				var contentResultEvent:ResultEvent = ResultEvent.createEvent(result);
				for (var i:int = 0; i < responders.length; i++)
				{
					var contentRequestToken:ContentRequestToken = responders[i] as ContentRequestToken;
					if (contentRequestToken)
						contentRequestToken.contentResult(contentResultEvent);
				}
			};
			var handleLoaderError:Function = function(errorEvent:IOErrorEvent):void
			{
				var faultEvent:FaultEvent = FaultEvent.createEvent(new Fault(errorEvent.type, errorEvent.text));
				customURLLoader.asyncToken.mx_internal::applyFault(faultEvent);
			};
		
		
			//TODO:  loader spits out lots of errors when it can't parse the data as an image.
			
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleLoaderComplete);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, handleLoaderError);
			loader.loadBytes(bytes);
		}
	}
}

import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.ByteArray;

import mx.core.mx_internal;
import mx.rpc.AsyncResponder;
import mx.rpc.AsyncToken;
import mx.rpc.Fault;
import mx.rpc.IResponder;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;

import weave.api.WeaveAPI;
import weave.api.services.IURLRequestToken;
import weave.services.URLRequestUtils;

internal class CustomURLLoader extends URLLoader
{
	public function CustomURLLoader(request:URLRequest, dataFormat:String, reportProgress:Boolean, loadNow:Boolean)
	{
		super.dataFormat = dataFormat;
		_urlRequest = request;
		_reportProgress = reportProgress;
		
		if (loadNow)
		{
			// keep track of pending requests
			if (_reportProgress)
				WeaveAPI.ProgressIndicator.addTask(this);
			addResponder(new AsyncResponder(removePendingRequest, removePendingRequest));
			
			// set up event listeners
			addEventListener(Event.COMPLETE, handleGetResult);
			addEventListener(IOErrorEvent.IO_ERROR, handleGetError);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError);
			addEventListener(ProgressEvent.PROGRESS, handleProgressUpdate);
			
			super.load(request);
		}
	}
	
	private var _reportProgress:Boolean;
	private var _asyncToken:AsyncToken = new AsyncToken();
	private var _isClosed:Boolean = false;
	private var _urlRequest:URLRequest = null;
	
	override public function load(request:URLRequest):void
	{
		throw new Error("URLLoaders from URLRequestUtils are not to be reused.");
	}
	
	override public function close():void
	{
		if (_reportProgress)
			WeaveAPI.ProgressIndicator.removeTask(this);
		_isClosed = true;
		try {
			super.close();
		} catch (e:Error) { } // ignore close() errors
	}
	
	/**
	 * This is the AsyncToken that keeps track of IResponders.
	 */	
	public function get asyncToken():AsyncToken
	{
		return _asyncToken;
	}
	
	/**
	 * This is the URLRequest that was passed to load().
	 */
	public function get urlRequest():URLRequest
	{
		return _urlRequest;
	}
	
	/**
	 * Gets the open or closed status of the URLLoader.
	 */
	public function get isClosed():Boolean
	{
		return _isClosed;
	}
	
	/**
	 * This provides a convenient way for adding result/fault handlers.
	 * @param responder
	 */
	public function addResponder(responder:IResponder):void
	{
		_asyncToken.addResponder(responder);
	}
	
	/**
	 * This provides a convenient way to remove a URLRequestToken as a responder.
	 * @param responder
	 */
	public function removeResponder(responder:URLRequestToken):void
	{
		var responders:Array = _asyncToken.responders;
		var index:int = responders.indexOf(responder);
		if (index >= 0)
		{
			// URLRequestToken found -- remove it
			responders.splice(index, 1);
			// see if there are any more URLRequestTokens
			for each (var obj:Object in _asyncToken.responders)
				if (obj is URLRequestToken)
					return;
			// no more URLRequestTokens found, so cancel
			close();
		}
	}

	/**
	 * This function is the event listener for a URLLoader's ProgressEvent.
	 * The primary purpose is to relay the URLLoader and its progress to the 
	 * ProgressIndicator class.
	 *  
	 * @param event
	 */
	private function handleProgressUpdate(event:Event):void
	{
		if (_reportProgress)
			WeaveAPI.ProgressIndicator.updateTask(this, bytesLoaded / bytesTotal);
	}

	/**
	 * This function gets called when a getURL request succeeds or fails.
	 * @param token The URLLoader to remove from the pendingRequests Array.
	 */
	private function removePendingRequest(event:Event, token:Object = null):void
	{
		if (_reportProgress)
			WeaveAPI.ProgressIndicator.removeTask(this);
	}

	/**
	 * This function gets called when a URLLoader generated by getURL() dispatches a COMPLETE Event.
	 * @param event The COMPLETE Event from a URLLoader.
	 */
	private function handleGetResult(event:Event):void
	{
		// broadcast result to responders
		_asyncToken.mx_internal::applyResult(ResultEvent.createEvent(data));
	}
	
	/**
	 * This function gets called when a URLLoader generated by getURL() dispatches an IOErrorEvent.
	 * @param event The ErrorEvent from a URLLoader.
	 */
	private function handleGetError(event:Event):void
	{
		// broadcast fault to responders
		var fault:Fault;
		if (event is ErrorEvent)
			fault = new Fault(String(event.type), event.type, (event as ErrorEvent).text);
		else
			fault = new Fault(String(event.type), event.type, "Request cancelled");
		_asyncToken.mx_internal::applyFault(FaultEvent.createEvent(fault));
	}
	
	/**
	 * This function gets called when a URLLoader generated by get() dispatches an SecurityErrorEvent.
	 * @param event The ErrorEvent from a URLLoader.
	 */
	private function handleSecurityError(event:SecurityErrorEvent):void
	{
		if (false)
		{
			// call the JQueryCaller to use JQuery to try to download a file that we had a security error
			// on - this is to get around the Flash player's security restrictions for downloading files
			// from servers without a permissive crossdomain.xml
			/** NOTE: this will not work for anything other than text data - it can be used to access data
			 *        in formats such as XML from a server that does not have a crossdomain.xml that is 
			 *        permissive, this will NOT work for binary data such as images **/
			//JQueryCaller.getFileFromURL(_urlRequest.url, _asyncToken);
		}
		else
		{
			handleGetError(event);
		}
	}
}

/**
 * This is an AsyncResponder that can be cancelled using the IURLRequestToken interface.
 * 
 * @author adufilie
 */
internal class URLRequestToken extends AsyncResponder implements IURLRequestToken
{
	public function URLRequestToken(loader:CustomURLLoader = null, result:Function = null, fault:Function = null, token:Object = null)
	{
		super(result || noOp, fault || noOp, token);
		
		this.loader = loader;
		if (loader)
			loader.addResponder(this);
	}
	
	private static function noOp(..._):void {} // does nothing
	
	private var loader:CustomURLLoader;
	private var cancelled:Boolean = false;
	
	public function cancelRequest():void
	{
		if (!cancelled && loader)
			loader.removeResponder(this);
		cancelled = true;
	}
	
	override public function result(data:Object):void
	{
		if (!cancelled)
			super.result(data);
	}
	
	override public function fault(info:Object):void
	{
		if (!cancelled)
			super.fault(info);
	}
}

/**
 * This is a URLRequestToken that is used by getContent() to delay the handlers until the content finishes loading.
 * 
 * @author adufilie
 */
internal class ContentRequestToken extends URLRequestToken
{
	public function ContentRequestToken(loader:CustomURLLoader = null, result:Function = null, fault:Function = null, token:Object = null)
	{
		super(loader, result, fault, token);
	}
	
	/**
	 * This function should be called when the content is loaded.
	 * @param event
	 */	
	public function contentResult(event:ResultEvent):void
	{
		super.result(event);
	}
	
	/**
	 * This function does nothing.  Instead, contentResult() should be called.
	 * @param data
	 */
	override public function result(data:Object):void
	{
		// Instead of this function, contentResult() will call super.result()
	}
}
