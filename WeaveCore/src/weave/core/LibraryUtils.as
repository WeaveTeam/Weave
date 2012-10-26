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

package weave.core
{
	import flash.system.ApplicationDomain;
	
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	
	/**
	 * This is an all-static class containing functions for loading SWC libraries at runtime.
	 * 
	 * @author adufilie
	 */
	public class LibraryUtils
	{
//		/**
//		 * This function gets a Class definition for a qualified class name.
//		 * @param classQName The qualified name of a class.
//		 * @return The class definition, or null if the class cannot be resolved.
//		 */
//		public static function getClassDefinition(classQName:String):Class
//		{
//			var domain:ApplicationDomain = ApplicationDomain.currentDomain;
//			if (domain.hasDefinition(classQName))
//				return domain.getDefinition(classQName) as Class;
//			return null;
//		}
		
		/**
		 * This function loads a SWC library into the current ApplicationDomain so getClassDefinition() and getDefinitionByName() can get its class definitions.
		 * The result passed to the asyncResultHandler function will be an Array containing the qualified class names of all the classes defined in the library.
		 * @param url The URL of the SWC library to load.
		 * @param asyncResultHandler A function with the following signature:  function(e:ResultEvent, token:Object = null):void.  This function will be called if the request succeeds.
		 * @param asyncFaultHandler A function with the following signature:  function(e:FaultEvent, token:Object = null):void.  This function will be called if there is an error.
		 * @param token An object that gets passed to the handler functions.
		 */
		public static function loadSWC(url:String, asyncResultHandler:Function = null, asyncFaultHandler:Function = null, token:Object = null):void
		{
			var library:Library = _libraries[url] as Library;
			if (!library || WeaveAPI.SessionManager.objectWasDisposed(library))
				_libraries[url] = library = new Library(url);
			
//			library.addAsyncResponder(handleSWCLoaded, null, url);
			library.addAsyncResponder(asyncResultHandler, asyncFaultHandler, token);
		}
		
//		/**
//		 * @private
//		 */		
//		private static function handleSWCLoaded(event:ResultEvent, token:Object = null):void
//		{
//			var url:String = token as String;
//			var defs:Array = event.result as Array;
//			var isLoaded:Boolean = isSWCLoaded(url);
//			for each (var def:String in defs)
//				
//				_classQNames[def] = isLoaded
//					
//			//todo: check all class defs before loading swf, remove the ones that already exist
//			// once swf is loaded, only bother initializing the ones that didn't already exist.
//			// keep a mapping between those classes and the swc url
//		}
//		
//		/**
//		 * This object maps a qualified class name to a value of true if the class should be made available through getClassDefinition(). 
//		 */		
//		private static const _classQNames:Object = {};
//		
//		public static function isSWCLoaded(url:String):Boolean
//		{
//			return false;
//		}
//		
//		/**
//		 * This function will unload a previously loaded SWC library.
//		 * @param url The URL of the SWC library to unload.
//		 */
//		public static function unloadSWC(url:String):void
//		{
//			throw new Error("Not working yet"); // because it is loaded into the same application domain, it can't be unloaded.
//			
//			var library:Library = _libraries[url] as Library;
//			if (library)
//			{
//				WeaveAPI.SessionManager.disposeObjects(library);
//				delete _libraries[url];
//			}
//		}
		
		/**
		 * @private
		 * 
		 * This maps a SWC URL to a Library object.
		 */
		private static const _libraries:Object = {};
	}
}

import avmplus.DescribeType;

import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

import mx.controls.SWFLoader;
import mx.core.mx_internal;
import mx.rpc.AsyncResponder;
import mx.rpc.AsyncToken;
import mx.rpc.Fault;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;

import nochump.util.zip.ZipFile;

import weave.api.WeaveAPI;
import weave.api.core.IDisposableObject;
import weave.core.ClassUtils;

/**
 * @private
 */
internal class Library implements IDisposableObject
{
	/**
	 * @param url The URL to a SWC file.
	 */	
	public function Library(url:String)
	{
		_url = url;
		WeaveAPI.URLRequestUtils.getURL(null, new URLRequest(url), handleSWCResult, handleSWCFault);
	}
	
	private var _url:String;
	private var _swfLoader:SWFLoader = new SWFLoader();
	private var _asyncToken:AsyncToken = new AsyncToken();
	private var _classQNames:Array = null;
	private var _library_swf:ByteArray;
	private var _catalog_xml:XML;
	
	private function noOp(..._):void { } // does nothing

	/**
	 * This function will unload the library and notify any pending responders with a FaultEvent.
	 */
	public function dispose():void
	{
		if (_swfLoader)
		{
			_swfLoader.unloadAndStop();
			WeaveAPI.ProgressIndicator.removeTask(_swfLoader);
			_swfLoader = null;
		}
		_classQNames = null;
		_notifyResponders();
	}
	
	/**
	 * This function will create an AsyncResponder that gets notified when the SWC library finishes loading.
	 * @see mx.rpc.AsyncResponder
	 */	
	public function addAsyncResponder(asyncResultHandler:Function, asyncFaultHandler:Function, token:Object):void
	{
		if (asyncResultHandler == null)
			asyncResultHandler = noOp;
		if (asyncFaultHandler == null)
			asyncFaultHandler = noOp;
		
		// if there is no AsyncToken, it means we previously notified responders and cleared the pointer
		if (!_asyncToken)
		{
			_asyncToken = new AsyncToken();
			// notify the responder one frame later
			WeaveAPI.StageUtils.callLater(this, _notifyResponders, null, WeaveAPI.TASK_PRIORITY_IMMEDIATE);
		}
		
		_asyncToken.addResponder(new AsyncResponder(asyncResultHandler, asyncFaultHandler, token));
	}
	
	/**
	 * @private
	 * 
	 * This gets called when a SWC download fails.
	 */		
	private function handleSWCFault(event:FaultEvent, token:Object = null):void
	{
		_notifyResponders(event.fault);
	}
	
	/**
	 * @private
	 * 
	 * This gets called when the SWC finishes downloading.
	 * Extract the SWC archive and load the SWF.
	 */		
	private function handleSWCResult(event:ResultEvent, token:Object = null):void
	{
		try
		{
			// Extract the files from the SWC archive
			var zipFile:ZipFile = new ZipFile(event.result as ByteArray);
			_library_swf = zipFile.getInput(zipFile.getEntry("library.swf"));
			_catalog_xml = XML(zipFile.getInput(zipFile.getEntry("catalog.xml")));
			zipFile = null;
			
			_swfLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSWFFault);
			_swfLoader.addEventListener(IOErrorEvent.IO_ERROR, handleSWFFault);
			_swfLoader.addEventListener(ProgressEvent.PROGRESS, handleSWFProgress);
			_swfLoader.addEventListener(Event.COMPLETE, handleSWFResult);
			
			// Dynamic creation of Flex classes doesn't work unless the library is loaded into the same application domain.
			_swfLoader.loaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
			_swfLoader.load(_library_swf);
			
			WeaveAPI.ProgressIndicator.addTask(_swfLoader);
		}
		catch (e:Error)
		{
			var fault:Fault = new Fault(String(e.errorID), e.name, e.message);
			_notifyResponders(fault);
		}
	}
	
	/**
	 * @private
	 *
	 * This is called when the SWFLoader fails.
	 */	
	private function handleSWFFault(event:Event):void
	{
		WeaveAPI.ProgressIndicator.removeTask(_swfLoader);
		
		// broadcast fault to responders
		var fault:Fault;
		if (event is ErrorEvent)
		{
			fault = new Fault(String(event.type), event.type, (event as ErrorEvent).text);
		}
		else
		{
			var msg:String = "Unable to load library: " + _url;
			fault = new Fault(String(event.type), event.type, msg);
		}
		_notifyResponders(fault);
	}
	
	/**
	 * @private
	 *
	 * This is called when the SWFLoader dispatches a ProgressEvent.
	 */	
	private function handleSWFProgress(event:ProgressEvent):void
	{
		WeaveAPI.ProgressIndicator.updateTask(_swfLoader, event.bytesLoaded / event.bytesTotal);
	}
	
	/**
	 * avmplus.describeTypeJSON(o:*, flags:uint):Object
	 */
	private static const describeTypeJSON:Function = DescribeType.getJSONFunction();
	
	/**
	 * @private
	 *
	 * This is called when the SWFLoader finishes loading.
	 * Begin initializing the classes defined in the SWF.
	 */	
	private function handleSWFResult(event:Event):void
	{
		WeaveAPI.ProgressIndicator.removeTask(_swfLoader);
		
		// get a sorted list of qualified class names
		var defList:XMLList = _catalog_xml.descendants(new QName('http://www.adobe.com/flash/swccatalog/9', 'def'));
		var idList:XMLList = defList.@id;
		_classQNames = [];
		for each (var id:String in idList)
		{
			_classQNames.push(id.split(':').join('.'));
		}
		_classQNames.sort();
		
		// iterate over all the classes, initializing them
		var index:int = 0;
		function loadingTask():Number
		{
			if (index >= _classQNames.length) // in case the length is zero
				return 1;

			var classQName:String = _classQNames[index] as String;
			try
			{
				// initialize the class
				var classDef:Class = ClassUtils.getClassDefinition(classQName);
				
				// register this class as an implementation of every interface it implements.
				var classInfo:Object = describeTypeJSON(classDef, DescribeType.INCLUDE_TRAITS | DescribeType.INCLUDE_INTERFACES | DescribeType.USE_ITRAITS);
				for each (var interfaceQName:String in classInfo.traits.interfaces)
				{
					var interfaceDef:Class = ClassUtils.getClassDefinition(interfaceQName);
					if (interfaceDef)
						WeaveAPI.registerImplementation(interfaceDef, classDef);
				}
			}
			catch (e:Error)
			{
				var fault:Fault = new Fault(String(e.errorID), e.name, e.message);
				_notifyResponders(fault);
				return 1;
			}
			
			index++;
			
			return index / _classQNames.length;  // this will be 1.0 after the last iteration.
		}
		WeaveAPI.StageUtils.startTask(this, loadingTask, WeaveAPI.TASK_PRIORITY_PARSING, _notifyResponders);
	}
	
	/**
	 * @private
	 */	
	private function _notifyResponders(fault:Fault = null):void
	{
		if (_asyncToken)
		{
			if (_classQNames && !fault)
			{
				var resultEvent:ResultEvent = ResultEvent.createEvent(_classQNames.concat(), _asyncToken);
				_asyncToken.mx_internal::applyResult(resultEvent);
				_asyncToken = null; // prevent responders from being called again
			}
			else
			{
				// if _classQNames is null it means the library was unloaded or there was a fault.
				if (!fault)
					fault = new Fault('Error', "Unable to load plugin " + _url);
				var faultEvent:FaultEvent = FaultEvent.createEvent(fault, _asyncToken);
				_asyncToken.mx_internal::applyFault(faultEvent);
				_asyncToken = null; // prevent responders from being called again
				
				WeaveAPI.SessionManager.disposeObjects(this);
			}
		}
	}
}
