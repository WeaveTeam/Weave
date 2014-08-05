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

package weave
{
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.external.ExternalInterface;
	import flash.net.SharedObject;
	import flash.net.SharedObjectFlushStatus;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.Base64Encoder;
	import mx.utils.UIDUtil;
	
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.disposeObject;
	import weave.api.getCallbackCollection;
	import weave.api.reportError;
	import weave.compiler.StandardLib;
	import weave.core.ClassUtils;
	import weave.core.LibraryUtils;
	import weave.core.LinkableHashMap;
	import weave.core.SessionStateLog;
	import weave.core.WeaveArchive;
	import weave.core.WeaveXMLDecoder;
	import weave.core.WeaveXMLEncoder;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.KeySets.KeyFilter;
	import weave.data.KeySets.KeySet;
	
	/**
	 * Weave contains objects created dynamically from a session state.
	 */
	public class Weave
	{
		SparkClasses; // Referencing this allows all Flex classes to be dynamically created at runtime.
		
		public static var ALLOW_PLUGINS:Boolean = false; // TEMPORARY

		public static var debug:Boolean = false;
		
		
		private static var _root:ILinkableHashMap = null; // root object of Weave

		/**
		 * This is the root object in Weave, which is an ILinkableHashMap.
		 */
		public static function get root():ILinkableHashMap
		{
			createDefaultObjects(WeaveAPI.globalHashMap);
			return WeaveAPI.globalHashMap;
		}
		
		/**
		 * This is a log of all previous session states 
		 */		
		public static function get history():SessionStateLog
		{
			createDefaultObjects(WeaveAPI.globalHashMap);
			return WeaveArchive.history;
		}

		/**
		 * This function gets the WeaveProperties object from the root of Weave.
		 */
		public static function get properties():WeaveProperties
		{
			return root.getObject(DEFAULT_WEAVE_PROPERTIES) as WeaveProperties;
		}
		
		/**
		 * This function gets the XML representation of the global session state.
		 */
		public static function getSessionStateXML():XML
		{
			var xml:XML = WeaveXMLEncoder.encode(root.getSessionState(), "Weave");
			
			var plugins:Array = getPluginList();
			if (_pluginList.length)
				xml.@plugins = WeaveAPI.CSVParser.createCSVRow(plugins);
			
			WeaveArchive.updateLocalThumbnailAndScreenshot(false);
			
			// embed local files
			for each (var fileName:String in WeaveAPI.URLRequestUtils.getLocalFileNames())
			{
				var bytes:ByteArray = WeaveAPI.URLRequestUtils.getLocalFile(fileName);
				
				// use Base64Encoder here instead of StandardLib.btoa() because we want the line breaks in the XML.
				var encoder:Base64Encoder = new Base64Encoder();
				encoder.encodeBytes(bytes);
				var ascii:String = encoder.flush();
				
				xml.appendChild(<ByteArray name={ fileName } encoding="base64">{ ascii }</ByteArray>);
			}
			
			return xml;
		}
		
		public static const DEFAULT_WEAVE_PROPERTIES:String = "WeaveProperties";
		
		public static const DEFAULT_COLOR_COLUMN:String = "defaultColorColumn";
		public static const DEFAULT_COLOR_BIN_COLUMN:String = "defaultColorBinColumn";
		public static const DEFAULT_COLOR_DATA_COLUMN:String = "defaultColorDataColumn";

		public static const DEFAULT_SUBSET_KEYFILTER:String = "defaultSubsetKeyFilter";
		public static const DEFAULT_SELECTION_KEYSET:String = "defaultSelectionKeySet";
		public static const DEFAULT_PROBE_KEYSET:String = "defaultProbeKeySet";
		public static const ALWAYS_HIGHLIGHT_KEYSET:String = "alwaysHighlightKeySet";
		public static const SAVED_SELECTION_KEYSETS:String = "savedSelections";
		public static const SAVED_SUBSETS_KEYFILTERS:String = "savedSubsets";

		public static function get defaultColorColumn():ColorColumn { return root.getObject(DEFAULT_COLOR_COLUMN) as ColorColumn; }
		public static function get defaultColorBinColumn():BinnedColumn { return root.getObject(DEFAULT_COLOR_BIN_COLUMN) as BinnedColumn; }
		public static function get defaultColorDataColumn():FilteredColumn { return root.getObject(DEFAULT_COLOR_DATA_COLUMN) as FilteredColumn; }
		
		public static function get defaultSubsetKeyFilter():KeyFilter { return root.getObject(DEFAULT_SUBSET_KEYFILTER) as KeyFilter; }
		public static function get defaultSelectionKeySet():KeySet { return root.getObject(DEFAULT_SELECTION_KEYSET) as KeySet; }
		public static function get defaultProbeKeySet():KeySet { return root.getObject(DEFAULT_PROBE_KEYSET) as KeySet; }
		public static function get alwaysHighlightKeySet():KeySet { return root.getObject(ALWAYS_HIGHLIGHT_KEYSET) as KeySet; }
		public static function get savedSelectionKeySets():LinkableHashMap { return root.getObject(SAVED_SELECTION_KEYSETS) as LinkableHashMap; }
		public static function get savedSubsetsKeyFilters():LinkableHashMap { return root.getObject(SAVED_SUBSETS_KEYFILTERS) as LinkableHashMap; }
		
		/**
		 * This initializes a default set of objects in an ILinkableHashMap.
		 */
		private static function createDefaultObjects(target:ILinkableHashMap):void
		{
			if (target.objectIsLocked(DEFAULT_WEAVE_PROPERTIES))
				return;
			
			target.requestObject(DEFAULT_WEAVE_PROPERTIES, WeaveProperties, true);

			// default color column
			var cc:ColorColumn = target.requestObject(DEFAULT_COLOR_COLUMN, ColorColumn, true);
			var bc:BinnedColumn = cc.internalDynamicColumn.requestGlobalObject(DEFAULT_COLOR_BIN_COLUMN, BinnedColumn, true);
			var fc:FilteredColumn = bc.internalDynamicColumn.requestGlobalObject(DEFAULT_COLOR_DATA_COLUMN, FilteredColumn, true);
			fc.filter.requestGlobalObject(DEFAULT_SUBSET_KEYFILTER, KeyFilter, true);
			
			// default key sets
			var subset:KeyFilter = target.requestObject(DEFAULT_SUBSET_KEYFILTER, KeyFilter, true);
			subset.includeMissingKeys.value = true; // default subset should include all keys
			target.requestObject(DEFAULT_SELECTION_KEYSET, KeySet, true);
			var probe:KeySet = target.requestObject(DEFAULT_PROBE_KEYSET, KeySet, true);
			var always:KeySet = target.requestObject(ALWAYS_HIGHLIGHT_KEYSET, KeySet, true);
			var callback:Function = function():void { probe.addKeys(always.keys); };
			probe.addImmediateCallback(always, callback);
			always.addImmediateCallback(probe, callback);

			target.requestObject(SAVED_SELECTION_KEYSETS, LinkableHashMap, true);
			target.requestObject(SAVED_SUBSETS_KEYFILTERS, LinkableHashMap, true);
			
			// clear history afterwards so that the creation of these default objects do not get recorded.
			history.clearHistory();
		}
		
		
		
		/******************************************************************************************/
		
		private static var _pluginList:Array = [];
		
		/**
		 * @return A copy of the list of plugins currently loaded. 
		 */		
		public static function getPluginList():Array
		{
			return _pluginList.concat();
		}
		
		/**
		 * This function will alter the list of plugins.  If plugins need to be unloaded, externalReload() will be called.
		 * @param newPluginList A new full list of plugins that should be loaded.
		 * @param newWeaveContent The new Weave file content to load after plugins have been loaded.
		 * @return true if the plugins are already loaded.
		 */
		public static function setPluginList(newPluginList:Array, newWeaveContent:Object):Boolean
		{
			if (debug)
				debugTrace("setPluginList", arguments);
			// remove duplicates
			var array:Array = [];
			for (i = 0; i < newPluginList.length; i++)
				if (array.indexOf(newPluginList[i]) < 0)
					array.push(newPluginList[i]);
			newPluginList = array;
			// stop if no change
			if (StandardLib.arrayCompare(_pluginList, newPluginList) == 0)
			{
				return true;
			}
			
			var i:int;
			var needReload:Boolean = false;
			if (newPluginList.length < _pluginList.length)
			{
				// need to unload plugins
				needReload = true;
			}
			else
			{
				// check if order changed
				for (i = 0; i < _pluginList.length; i++)
				{
					if (_pluginList[i] != newPluginList[i])
						needReload = true;
				}
			}
			
			// save new plugin list
			_pluginList = newPluginList;
			
			if (needReload)
			{
				externalReload(newWeaveContent);
			}
			else
			{
				// load missing plugins
				var remaining:int = _pluginList.length;
				var ILinkableObject_classQName:String = getQualifiedClassName(ILinkableObject);
				
				function handlePlugin(event:Event, plugin:String):void
				{
					var resultEvent:ResultEvent = event as ResultEvent;
					var faultEvent:FaultEvent = event as FaultEvent;
					if (resultEvent)
					{
						trace("Loaded plugin:", plugin);
						var classQNames:Array = resultEvent.result as Array;
						for (var i:int = 0; i < classQNames.length; i++)
						{
							var classQName:String = classQNames[i];
							// check if it implements ILinkableObject
							if (ClassUtils.classImplements(classQName, ILinkableObject_classQName))
							{
								trace(classQName);
							}
						}
					}
					else
					{
						weaveTrace("Plugin failed to load:", plugin);
						reportError(faultEvent.fault);
					}
					
					remaining--;
					if (debug)
						reportError('remaining '+remaining);
					if (remaining == 0)
						loadWeaveFileContent(newWeaveContent);
				}
				if (remaining > 0)
				{
					for each (var plugin:String in _pluginList)
					{
						LibraryUtils.loadSWC(plugin, handlePlugin, handlePlugin, plugin);
					}
				}
				else
				{
					reportError("Unexpected");
					loadWeaveFileContent(newWeaveContent);
				}
			}
			return false;
		}
		
		/**
		 * This will change an ".xml" extension to ".weave" in a file name.
		 * @param fileName A file name to fix.
		 * @return A file name ending in ".weave".
		 */
		public static function fixWeaveFileName(fileName:String, useWeaveExtension:Boolean):String
		{
			var _xml:String = '.xml';
			var _weave:String = '.weave';
			var oldExt:String = useWeaveExtension ? _xml : _weave;
			var newExt:String = useWeaveExtension ? _weave : _xml;
			
			if (!fileName)
				fileName = generateFileName();
			if (fileName.substr(-oldExt.length).toLowerCase() == oldExt)
				fileName = fileName.substr(0, -oldExt.length);
			if (fileName.substr(-newExt.length).toLowerCase() != newExt)
				fileName += newExt;
			return fileName;
		}

		/**
		 * This function will create an object that can be saved to a file and recalled later with loadWeaveFileContent().
		 */
		public static function createWeaveFileContent(saveScreenshot:Boolean=false):ByteArray
		{
			return WeaveArchive.createWeaveFileContent(saveScreenshot, ALLOW_PLUGINS ? _pluginList : null);
		}
		
		/**
		 * Used as storage for last loaded session history file name.
		 */		
		public static var fileName:String = generateFileName();
		
		private static function generateFileName():String
		{
			return 'Weave_' + StandardLib.formatDate(new Date(), "YYYY-MM-DD_HH.NN.SS", false) + '.weave';
		}
		
		/**
		 * This function will load content that was previously created with createWeaveFileContent().
		 * @param content The contents of a Weave file.
		 */
		public static function loadWeaveFileContent(content:Object):void
		{
			if (debug)
				debugTrace("loadWeaveFileContent", arguments);
			var plugins:Array;
			var fileName:String;
			if (content is String)
				content = XML(content);
			if (content is XML)
			{
				// we must wait until all plugins are loaded before trying to decode the session state xml
				var xml:XML = content as XML;
				plugins = WeaveAPI.CSVParser.parseCSVRow(xml.@plugins) || [];
				if (setPluginList(plugins, content))
				{
					var newState:Array = WeaveXMLDecoder.decodeDynamicState(xml);
					root.setSessionState(newState, true);
					// begin with empty history after loading the session state from the xml
					history.clearHistory();
					
					// remove all local files and replace with list from xml
					for each (fileName in WeaveAPI.URLRequestUtils.getLocalFileNames())
						WeaveAPI.URLRequestUtils.removeLocalFile(fileName);
					for each (var node:XML in xml.ByteArray)
						WeaveAPI.URLRequestUtils.saveLocalFile(node.attribute('name'), StandardLib.atob(node.text()));
				}
			}
			else if (content)
			{
				if (content is ByteArray)
				{
					try
					{
						content = new WeaveArchive(content as ByteArray);
					}
					catch (e:Error)
					{
						try {
							loadWeaveFileContent(String(content));
							return;
						} catch (e:Error) { }
						throw e;
					}
				}
				
				var archive:WeaveArchive = content as WeaveArchive;
				if (!archive)
				{
					reportError("Invalid session history: " + debugId(content), null, content);
					return;
				}
				
				var _history:Object = archive.objects[WeaveArchive.ARCHIVE_HISTORY_AMF];
				if (!_history)
					throw new Error("Weave session history not found.");
				
				// remove all local files and replace with list from archive
				for each (fileName in WeaveAPI.URLRequestUtils.getLocalFileNames())
					WeaveAPI.URLRequestUtils.removeLocalFile(fileName);
				for (fileName in archive.files)
					WeaveAPI.URLRequestUtils.saveLocalFile(fileName, archive.files[fileName]);
				
				plugins = archive.objects[WeaveArchive.ARCHIVE_PLUGINS_AMF] as Array || [];
				if (setPluginList(plugins, content))
				{
					history.setSessionState(_history);
				}
			}
			
			// hack for forcing VisApplication menu to refresh
			getCallbackCollection(Weave.properties).triggerCallbacks();
			
			if (WeaveAPI.javaScriptInitialized)
			{
				Weave.initExternalDragDrop();
				properties.runStartupJavaScript();
			}
		}
		
		private static const WEAVE_RELOAD_SHARED_OBJECT:String = "WeaveExternalReload";
		
		/**
		 * This function will restart the Flash application by reloading the SWF that is embedded in the browser window.
		 * @param weaveContent Either a WeaveArchive or an XML
		 */
		public static function externalReload(weaveContent:Object = null):void
		{
			weaveContent = weaveContent as WeaveArchive || weaveContent as XML;
			
			if (!JavaScript.available)
			{
				//TODO: is it possible to restart an Adobe AIR application from within?
				reportError("Unable to restart Weave when JavaScript is not available.");
				return;
			}
			
			if (!weaveContent)
				weaveContent = createWeaveFileContent();
			
			var obj:SharedObject = SharedObject.getLocal(WEAVE_RELOAD_SHARED_OBJECT);
			var uid:String = WEAVE_RELOAD_SHARED_OBJECT;
			if (JavaScript.available && ExternalInterface.objectID)
			{
				// generate uid to be saved in parent node
				uid = UIDUtil.createUID();
			}
			
			// save session history to shared object
			if (weaveContent is XML)
				weaveContent = (weaveContent as XML).toXMLString();
			if (weaveContent is WeaveArchive)
				weaveContent = (weaveContent as WeaveArchive).serialize();
			obj.data[uid] = { date: new Date(), content: weaveContent };
			
			if (obj.flush() == SharedObjectFlushStatus.PENDING)
				obj.addEventListener(NetStatusEvent.NET_STATUS, handleExternalReloadStatus);
			else
				handleExternalReloadStatus();
			
			function handleExternalReloadStatus(event:NetStatusEvent = null):void
			{
				if (event && event.info.code != 'SharedObject.Flush.Success')
				{
					reportError(EXTERNAL_RELOAD_ERROR);
					return;
				}
				obj.close();
				
				// before reloading, dispose everything in case any JavaScript cleanup needs to happen.
				try
				{
					disposeObject(WeaveAPI.globalHashMap);
				}
				catch (e:Error)
				{
					trace(e.getStackTrace());
				}
				
				// reload the application
				if (ExternalInterface.objectID)
					JavaScript.exec(
						{reloadID: uid},
						"this.parentNode.weaveReloadID = reloadID;",
						"this.outerHTML = this.outerHTML;"
					);
				else
					JavaScript.exec("location.reload(false);");
			}
		}
		
		private static const EXTERNAL_RELOAD_ERROR:String = lang("You must allow Weave to use local storage in order to use this feature.");
		
		/**
		 * This function should be called when the application starts to restore session history after reloading the application.
		 * @return true if the application was reloaded from within.
		 */		
		public static function handleWeaveReload():Boolean
		{
			var obj:SharedObject = SharedObject.getLocal(WEAVE_RELOAD_SHARED_OBJECT);
			var uid:String = WEAVE_RELOAD_SHARED_OBJECT;
			if (JavaScript.available && ExternalInterface.objectID)
			{
				try
				{
					// get uid that was previously saved in parent node
					uid = JavaScript.exec(
						'var p = this.parentNode;',
						'var reloadID = p.weaveReloadID;',
						'p.weaveReloadID = undefined;',
						'return reloadID;'
					);
				}
				catch (e:Error)
				{
					if (e.errorID == 2060 && e.getStackTrace() == null)
						e.message = StandardLib.substitute("ExternalInterface caller {0} cannot access the current JavaScript security domain.", WeaveAPI.topLevelApplication['url']);
					reportError(e);
				}
			}
			
			// get session history from shared object
			var saved:Object = obj.data[uid];
			if (debug)
				debugTrace("handleWeaveReload", JavaScript.objectID, obj.data, uid, saved);
			if (saved)
			{
				// delete session history from shared object
				obj.setProperty(uid);
				
				// restore old session history
				loadWeaveFileContent(saved.content);
			}
			
			// delete all old saved data 
			const EXPIRATION_TIME:int = 5 * 60 * 1000; // minutes
			var date:Date = new Date();
			for (uid in obj.data)
			{
				try
				{
					if (date.getTime() - obj.data[uid].date.getTime() < EXPIRATION_TIME)
						continue;
				}
				catch (e:Error)
				{
					// ignore error, entry will be deleted
				}
				
				obj.setProperty(uid);
			}
			
			// save changes to shared object
			obj.close();
			
			return saved != null;
		}
		
		
		[Embed(source="WeaveStartup.js", mimeType="application/octet-stream")]
		private static const WeaveStartup:Class;
		private static var _startupComplete:Boolean = false;
		public static function initExternalDragDrop():void
		{
			if (_startupComplete || !JavaScript.available)
				return;
			try
			{
				WeaveAPI.initializeJavaScript(WeaveStartup);
				_startupComplete = true;
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
	}
}
