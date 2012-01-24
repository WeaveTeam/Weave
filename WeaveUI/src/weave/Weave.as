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
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.WeaveFile;
	import weave.api.core.IErrorManager;
	import weave.api.core.IExternalSessionStateInterface;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.core.IProgressIndicator;
	import weave.api.core.ISessionManager;
	import weave.api.data.IAttributeColumnCache;
	import weave.api.data.ICSVParser;
	import weave.api.data.IProjectionManager;
	import weave.api.data.IQualifiedKeyManager;
	import weave.api.data.IStatisticsCache;
	import weave.api.reportError;
	import weave.api.services.IURLRequestUtils;
	import weave.core.ClassUtils;
	import weave.core.ErrorManager;
	import weave.core.ExternalSessionStateInterface;
	import weave.core.LibraryUtils;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableHashMap;
	import weave.core.ProgressIndicator;
	import weave.core.SessionManager;
	import weave.core.SessionStateLog;
	import weave.core.WeaveXMLDecoder;
	import weave.core.WeaveXMLEncoder;
	import weave.data.AttributeColumnCache;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.CSVParser;
	import weave.data.KeySets.KeyFilter;
	import weave.data.KeySets.KeySet;
	import weave.data.ProjectionManager;
	import weave.data.QKeyManager;
	import weave.data.StatisticsCache;
	import weave.editors._registerAllLinkableObjectEditors;
	import weave.services.URLRequestUtils;
	import weave.utils.BitmapUtils;
	
	/**
	 * Weave contains objects created dynamically from a session state.
	 */
	public class Weave
	{
		{ /** begin static code block **/
			initialize();
		} /** end static code block **/
		
		private static var _initialized:Boolean = false; // used by initialize()
		
		/**
		 * This function gets called automatically and will register implementations of core API classes.
		 * This function can be called explicitly to immediately register the classes.
		 */
		public static function initialize():void
		{
			if (_initialized)
				return;
			_initialized = true;
			
			// register singleton implementations for framework classes
			WeaveAPI.registerSingleton(ISessionManager, SessionManager);
			WeaveAPI.registerSingleton(IErrorManager, ErrorManager);
			WeaveAPI.registerSingleton(IExternalSessionStateInterface, ExternalSessionStateInterface);
			WeaveAPI.registerSingleton(IProgressIndicator, ProgressIndicator);
			WeaveAPI.registerSingleton(IAttributeColumnCache, AttributeColumnCache);
			WeaveAPI.registerSingleton(IStatisticsCache, StatisticsCache);
			WeaveAPI.registerSingleton(IQualifiedKeyManager, QKeyManager);
			WeaveAPI.registerSingleton(IProjectionManager, ProjectionManager);
			WeaveAPI.registerSingleton(IURLRequestUtils, URLRequestUtils);
			WeaveAPI.registerSingleton(ICSVParser, CSVParser);
			
			_registerAllLinkableObjectEditors();
			
			// initialize the session state interface to point to Weave.root
			(WeaveAPI.ExternalSessionStateInterface as ExternalSessionStateInterface).setLinkableObjectRoot(root);
			
			// FOR BACKWARDS COMPATIBILITY
			ExternalInterface.addCallback("createObject", function(...args):* {
				reportError("The Weave JavaScript API function createObject is deprecated.  Please use requestObject instead.");
				WeaveAPI.ExternalSessionStateInterface.requestObject.apply(null, args);
			});
			
			// include these packages in WeaveXMLDecoder so they will not need to be specified in the XML session state.
			WeaveXMLDecoder.includePackages(
				"weave",
				"weave.core",
				"weave.data",
				"weave.data.AttributeColumns",
				"weave.data.BinClassifiers",
				"weave.data.BinningDefinitions",
				"weave.data.ColumnReferences",
				"weave.data.DataSources",
				"weave.data.KeySets",
				"weave.editors",
				"weave.primitives",
				"weave.Reports",
				"weave.test",
				"weave.ui",
				"weave.utils",
				"weave.visualization",
				"weave.visualization.tools",
				"weave.visualization.layers",
				"weave.visualization.plotters",
			    "weave.visualization.plotters.styles"
			);
		}
		
		private static var _root:ILinkableHashMap = null; // root object of Weave
		private static var _history:SessionStateLog = null; // root session history

		/**
		 * This is the root object in Weave, which is an ILinkableHashMap.
		 */
		public static function get root():ILinkableHashMap
		{
			if (_root == null)
			{
				_root = LinkableDynamicObject.globalHashMap;
				createDefaultObjects(_root);
				_history = new SessionStateLog(root);
			}
			return _root;
		}
		
		/**
		 * This is a log of all previous session states 
		 */		
		public static function get history():SessionStateLog
		{
			if (!root) // this check will initialize the _history variable
				throw "unexpected";
			return _history;
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
			return WeaveXMLEncoder.encode(root.getSessionState(), "Weave");
		}
		/**
		 * This function sets the session state by decoding an XML representation of it.
		 * @param newStateXML The new session state
		 */
		public static function setSessionStateXML(newStateXML:XML):void
		{
			var newState:Array = WeaveXMLDecoder.decodeDynamicState(newStateXML);
			root.setSessionState(newState, true);
		}
		
		public static const DEFAULT_WEAVE_PROPERTIES:String = "WeaveProperties";
		
		public static const DEFAULT_COLOR_BIN_COLUMN:String = "defaultColorBinColumn";
		public static const DEFAULT_COLOR_DATA_COLUMN:String = "defaultColorDataColumn";
		public static const DEFAULT_COLOR_COLUMN:String = "defaultColorColumn";

		public static const DEFAULT_SUBSET_KEYFILTER:String = "defaultSubsetKeyFilter";
		public static const DEFAULT_SELECTION_KEYSET:String = "defaultSelectionKeySet";
		public static const DEFAULT_PROBE_KEYSET:String = "defaultProbeKeySet";
		public static const ALWAYS_HIGHLIGHT_KEYSET:String = "alwaysHighlightKeySet";
		public static const SAVED_SELECTION_KEYSETS:String = "savedSelections";
		public static const SAVED_SUBSETS_KEYFILTERS:String = "savedSubsets";
		
		/**
		 * This initializes a default set of objects in an ILinkableHashMap.
		 */
		private static function createDefaultObjects(target:ILinkableHashMap):void
		{
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
			probe.addImmediateCallback(always, addKeys, [always, probe]);
			always.addImmediateCallback(probe, addKeys, [always, probe]);

			target.requestObject(SAVED_SELECTION_KEYSETS, LinkableHashMap, true);
			target.requestObject(SAVED_SUBSETS_KEYFILTERS, LinkableHashMap, true);
		}
		
		private static function addKeys(source:KeySet, destination:KeySet):void
		{
			destination.addKeys(source.keys);
		}
		
		
		/******************************************************************************************/
		
		private static const WeaveFile_CONTENT_TYPE:String = "Weave session history";
		private static const WeaveFile_THUMBNAIL:String = "thumbnail";
		private static const WeaveFile_LIBRARIES:String = "libraries";
		private static const WeaveFile_HISTORY:String = "history";
		private static const THUMBNAIL_SIZE:int = 128;
		
		/**
		 * This function will create an object that can be saved to a file and recalled later with loadWeaveFileContent().
		 */
		public static function createWeaveFileContent():ByteArray
		{
			var _thumbnail:BitmapData = BitmapUtils.getBitmapDataFromComponent(Application.application as UIComponent, THUMBNAIL_SIZE, THUMBNAIL_SIZE);
			var _libraries:Array = ["WeaveExamplePlugin.swc"];
			var _history:Object = history.getSessionState();
			// thumbnail should go first in the stream because we will often just want to extract the thumbnail and nothing else.
			var weaveFile:WeaveFile = new WeaveFile();
			weaveFile.setContentType(WeaveFile_CONTENT_TYPE);
			weaveFile.setObject(WeaveFile_THUMBNAIL, _thumbnail);
			weaveFile.setObject(WeaveFile_LIBRARIES, _libraries);
			weaveFile.setObject(WeaveFile_HISTORY, _history);
			return weaveFile.serialize();
		}
		
		/**
		 * This function will load content that was previously created with createWeaveFileContent().
		 * @param content The contents of a Weave file.
		 */
		public static function loadWeaveFileContent(content:ByteArray):void
		{
			var weaveFile:WeaveFile = new WeaveFile(content);
			if (weaveFile.getContentType() == WeaveFile_CONTENT_TYPE)
			{
				var pluginURLs:Array = weaveFile.getObject(WeaveFile_LIBRARIES) as Array;
				var remaining:int = pluginURLs.length;
				function handlePluginsFinished():void
				{
					history.setSessionState(weaveFile.getObject(WeaveFile_HISTORY));
				}
				function handlePlugin(event:Event, token:Object = null):void
				{
					var resultEvent:ResultEvent = event as ResultEvent;
					var faultEvent:FaultEvent = event as FaultEvent;
					if (resultEvent)
					{
						trace("Loaded plugin:", token);
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
						trace("Plugin failed to load:", token);
						reportError(faultEvent.fault);
					}

					remaining--;
					if (remaining == 0)
						handlePluginsFinished();
				}
				if (remaining > 0)
				{
					for each (var plugin:String in pluginURLs)
					{
						LibraryUtils.loadSWC(plugin, handlePlugin, handlePlugin, plugin);
					}
				}
				else
				{
					handlePluginsFinished();
				}
			}
			else
			{
				reportError("Unrecognized contentType: " + weaveFile.getContentType());
			}
		}
			
		private static const ILinkableObject_classQName:String = getQualifiedClassName(ILinkableObject);
	}
}
