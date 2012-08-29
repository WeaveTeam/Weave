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
	import com.as3xls.xls.formula.Tokens;
	
	import flash.display.Bitmap;
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
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import mx.core.mx_internal;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.services.IURLRequestToken;
	import weave.api.services.IURLRequestUtils;
	import weave.utils.ImageLoaderUtils;
	import weave.utils.ImageLoaderUtilsEvent;

	/**
	 * An all-static class containing functions for downloading URLs.
	 * 
	 * @author adufilie
	 */
	public class URLRequestUtils implements IURLRequestUtils
	{
		public static var delayResults:Boolean = false; // when true, delays result/fault handling and fills the 'delayed' Array.
		public static const delayed:Array = []; // array of objects with properties:  label:String, resume:Function
		
		public static const DATA_FORMAT_TEXT:String = URLLoaderDataFormat.TEXT;
		public static const DATA_FORMAT_BINARY:String = URLLoaderDataFormat.BINARY;
		public static const DATA_FORMAT_VARIABLES:String = URLLoaderDataFormat.VARIABLES;
		
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
		public function getURL(relevantContext:Object, request:URLRequest, asyncResultHandler:Function = null, asyncFaultHandler:Function = null, token:Object = null, dataFormat:String = "binary"):URLLoader
		{
			var urlLoader:CustomURLLoader;
			try
			{
				urlLoader = new CustomURLLoader(relevantContext, request, dataFormat, true);
				urlLoader.addResponder(new CustomAsyncResponder(relevantContext, null, asyncResultHandler, asyncFaultHandler, token));
			}
			catch (e:Error)
			{
				// When an error occurs, we need to run the asyncFaultHandler later
				// and return a new URLLoader. CustomURLLoader doesn't load if the 
				// last parameter to the constructor is false.
				urlLoader = new CustomURLLoader(relevantContext, request, dataFormat, false);
				WeaveAPI.StageUtils.callLater(
					relevantContext, 
					asyncFaultHandler || noOp, 
					[new FaultEvent(FaultEvent.FAULT, false, true, new Fault(String(e.errorID), e.name, e.message)), token]
				);
			}
			
			return urlLoader;
		}
		
		private function noOp(..._):void { } // does nothing

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
		public function getContent(relevantContext:Object, request:URLRequest, asyncResultHandler:Function = null, asyncFaultHandler:Function = null, token:Object = null, useCache:Boolean = true):IURLRequestToken
		{
			if (useCache)
			{
				var content:Object = _contentCache[request.url]; 
				if (content)
				{
					// create a request token so its cancel function can be used and the result handler won't be called next frame
					var contentRequestToken:ContentAsyncResponder = new ContentAsyncResponder(relevantContext, null, asyncResultHandler, asyncFaultHandler, token);
					var resultEvent:ResultEvent = ResultEvent.createEvent(content);
					// wait one frame and make sure to call contentResult() instead of result().
					WeaveAPI.StageUtils.callLater(relevantContext, contentRequestToken.contentResult, [resultEvent], WeaveAPI.TASK_PRIORITY_PARSING);
					return contentRequestToken;
				}
			}
			
			// check for a loader that is currently downloading this url
			var loader:CustomURLLoader = _requestURLToLoader[request.url] as CustomURLLoader;
			if (loader == null || loader.isClosed)
			{
				// make the request and add handler function that will load the content
				loader = getURL(relevantContext, request, handleGetContentResult, null, request.url, DATA_FORMAT_BINARY) as CustomURLLoader;
				_requestURLToLoader[request.url] = loader;
			}
			
			// create a ContentRequestToken so the handlers will run when the content finishes loading.
			return new ContentAsyncResponder(relevantContext, loader, asyncResultHandler, asyncFaultHandler, token);
		}
		
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
		public function getImage(relavantContext:Object, request:URLRequest, asyncResulthandler:Function = null, asyncFaultHandler:Function = null, token:Object = null, useCache:Boolean = true):void
		{
			var imageLoaderUtils:ImageLoaderUtils = new ImageLoaderUtils();
			var handleLoadComplete:Function = function(e:ImageLoaderUtilsEvent):void 
			{
				var resultEvent:ResultEvent = ResultEvent.createEvent(e.bitmap);
				if( asyncResulthandler != null )
				{
					_bitmapCache[request.url] = e.bitmap;
					asyncResulthandler(resultEvent, request.url);
				}
			}
			var handleLoadError:Function = function(e:ImageLoaderUtilsEvent):void
			{
				var faultEvent:FaultEvent = FaultEvent.createEvent(new Fault(e.event.type, e.event.target as String));
				if( asyncFaultHandler != null )
				{
					delete _bitmapCache[request.url];
					asyncFaultHandler(faultEvent, request.url);
				}
			}
			
			imageLoaderUtils.addEventListener(ImageLoaderUtilsEvent.LOAD_COMPLETE, handleLoadComplete);
			imageLoaderUtils.addEventListener(ImageLoaderUtilsEvent.ERROR, handleLoadError);
			imageLoaderUtils.url = request.url;
		}
		
		/**
		 * This maps a URL to the content that was downloaded from that URL.
		 */		
		private const _contentCache:Object = new Object();
		
		/**
		 * This maps a URL to the bitmap data of the image downloaded from that URL.
		 */
		private const _bitmapCache:Object = new Object();
		
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
					var contentRequestToken:ContentAsyncResponder = responders[i] as ContentAsyncResponder;
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
import mx.utils.ObjectUtil;

import weave.api.WeaveAPI;
import weave.api.core.ILinkableObject;
import weave.api.services.IURLRequestToken;
import weave.services.URLRequestUtils;

internal class CustomURLLoader extends URLLoader
{
	public function CustomURLLoader(relevantContext:Object, request:URLRequest, dataFormat:String, loadNow:Boolean)
	{
		super.dataFormat = dataFormat;
		_urlRequest = request;
		
		if (loadNow)
		{
			if (URLRequestUtils.delayed)
			{
				label = request.url;
				try
				{
					var bytes:ByteArray = ObjectUtil.copy(request.data as ByteArray) as ByteArray;
					bytes.uncompress();
					label += ' ' + ObjectUtil.toString(bytes.readObject()).split('\n').join(' ');
				}
				catch (e:Error) { }
				//WeaveAPI.externalTrace('requested ' + label);
				URLRequestUtils.delayed.push({"label": label, "resume": resume});
			}
			
			// keep track of pending requests
			WeaveAPI.ProgressIndicator.addTask(this);
			if (relevantContext is ILinkableObject)
				WeaveAPI.SessionManager.assignBusyTask(this, relevantContext as ILinkableObject);
			addResponder(new AsyncResponder(removeTask, removeTask));
			
			// set up event listeners
			addEventListener(Event.COMPLETE, handleGetResult);
			addEventListener(IOErrorEvent.IO_ERROR, handleGetError);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError);
			addEventListener(ProgressEvent.PROGRESS, handleProgressUpdate);
			
			super.load(request);
		}
	}
	
	internal var label:String;
	private var _asyncToken:AsyncToken = new AsyncToken();
	private var _isClosed:Boolean = false;
	private var _urlRequest:URLRequest = null;
	
	override public function load(request:URLRequest):void
	{
		throw new Error("URLLoaders from URLRequestUtils are not to be reused.");
	}
	
	override public function close():void
	{
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
	public function removeResponder(responder:CustomAsyncResponder):void
	{
		var responders:Array = _asyncToken.responders;
		var index:int = responders.indexOf(responder);
		if (index >= 0)
		{
			// URLRequestToken found -- remove it
			responders.splice(index, 1);
			// see if there are any more URLRequestTokens
			for each (var obj:Object in _asyncToken.responders)
				if (obj is CustomAsyncResponder)
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
		WeaveAPI.ProgressIndicator.updateTask(this, bytesLoaded / bytesTotal);
	}

	/**
	 * This function gets called when a getURL request succeeds or fails.
	 * @param token The URLLoader to remove from the task list.
	 */
	private function removeTask(event:Event, token:Object = null):void
	{
		WeaveAPI.ProgressIndicator.removeTask(this);
	}
	
	private var _resumeFunc:Function = null;
	private var _resumeParam:Object = null;
	/**
	 * When URLRequestUtils.delayResults is set to true, this function will resume
	 * @return true  
	 */	
	public function resume():void
	{
		if (_resumeFunc == null)
		{
			_resumeFunc = resume; // this cancels the pending delay behavior
		}
		else
		{
			_resumeFunc(_resumeParam);
		}
	}
	
	/**
	 * This function gets called when a URLLoader generated by getURL() dispatches a COMPLETE Event.
	 * @param event The COMPLETE Event from a URLLoader.
	 */
	private function handleGetResult(event:Event):void
	{
		//WeaveAPI.externalTrace('getResult ' + label);
		if (URLRequestUtils.delayResults && _resumeFunc == null)
		{
			_resumeFunc = handleGetResult;
			_resumeParam = event;
			return;
		}
		
		// broadcast result to responders
		_asyncToken.mx_internal::applyResult(ResultEvent.createEvent(data));
	}
	
	/**
	 * This function gets called when a URLLoader generated by getURL() dispatches an IOErrorEvent.
	 * @param event The ErrorEvent from a URLLoader.
	 */
	private function handleGetError(event:Event):void
	{
		if (URLRequestUtils.delayResults && _resumeFunc == null)
		{
			_resumeFunc = handleGetError;
			_resumeParam = event;
			return;
		}
		
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
internal class CustomAsyncResponder extends AsyncResponder implements IURLRequestToken
{
	public function CustomAsyncResponder(relevantContext:Object, loader:CustomURLLoader, result:Function, fault:Function, token:Object = null)
	{
		super(result || noOp, fault || noOp, token);
	
		this.relevantContext = relevantContext;
		
		this.loader = loader;
		if (loader)
			loader.addResponder(this);
	}
	
	private static function noOp(..._):void {} // does nothing
	
	private var loader:CustomURLLoader;
	private var relevantContext:Object;
	
	public function cancelRequest():void
	{
		if (loader && !WeaveAPI.SessionManager.objectWasDisposed(this))
			loader.removeResponder(this);
		WeaveAPI.SessionManager.disposeObjects(this);
	}
	
	override public function result(data:Object):void
	{
		if (!WeaveAPI.SessionManager.objectWasDisposed(this) && !WeaveAPI.SessionManager.objectWasDisposed(relevantContext))
			super.result(data);
	}
	
	override public function fault(data:Object):void
	{
		if (!WeaveAPI.SessionManager.objectWasDisposed(this) && !WeaveAPI.SessionManager.objectWasDisposed(relevantContext))
			super.fault(data);
	}
}

/**
 * This is a CustomAsyncResponder that is used by getContent() to delay the handlers until the content finishes loading.
 * 
 * @author adufilie
 */
internal class ContentAsyncResponder extends CustomAsyncResponder
{
	public function ContentAsyncResponder(relevantContext:Object, loader:CustomURLLoader, result:Function, fault:Function, token:Object = null)
	{
		super(relevantContext, loader, result, fault, token);
	}
	
	/**
	 * This function should be called when the content is loaded.
	 * @param event
	 */	
	internal function contentResult(event:ResultEvent):void
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
