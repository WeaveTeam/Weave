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

package org.oicweave
{
	import flash.external.ExternalInterface;
	
	import org.oicweave.api.WeaveAPI;
	import org.oicweave.api.core.IExternalSessionStateInterface;
	import org.oicweave.api.core.ILinkableHashMap;
	import org.oicweave.api.core.ISessionManager;
	import org.oicweave.api.data.IAttributeColumnCache;
	import org.oicweave.api.data.ICSVParser;
	import org.oicweave.api.data.IProjectionManager;
	import org.oicweave.api.data.IQualifiedKeyManager;
	import org.oicweave.api.data.IStatisticsCache;
	import org.oicweave.core.LinkableDynamicObject;
	import org.oicweave.core.LinkableHashMap;
	import org.oicweave.core.SessionManager;
	import org.oicweave.core.WeaveJavaScriptAPI;
	import org.oicweave.core.WeaveXMLDecoder;
	import org.oicweave.core.WeaveXMLEncoder;
	import org.oicweave.data.AttributeColumnCache;
	import org.oicweave.data.AttributeColumns.BinnedColumn;
	import org.oicweave.data.AttributeColumns.ColorColumn;
	import org.oicweave.data.AttributeColumns.FilteredColumn;
	import org.oicweave.data.CSVParser;
	import org.oicweave.data.KeySets.KeyFilter;
	import org.oicweave.data.KeySets.KeySet;
	import org.oicweave.data.ProjectionManager;
	import org.oicweave.data.QKeyManager;
	import org.oicweave.data.StatisticsCache;
	import org.oicweave.utils.DebugTimer;
	
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
			WeaveAPI.registerSingleton(IExternalSessionStateInterface, WeaveJavaScriptAPI);
			WeaveAPI.registerSingleton(IAttributeColumnCache, AttributeColumnCache);
			WeaveAPI.registerSingleton(IStatisticsCache, StatisticsCache);
			WeaveAPI.registerSingleton(IQualifiedKeyManager, QKeyManager);
			WeaveAPI.registerSingleton(IProjectionManager, ProjectionManager);
			WeaveAPI.registerSingleton(ICSVParser, CSVParser);
			
			// initialize the session state interface to point to Weave.root
			(WeaveAPI.ExternalSessionStateInterface as WeaveJavaScriptAPI).setLinkableObjectRoot(root);
			
			// FOR BACKWARDS COMPATIBILITY
			ExternalInterface.addCallback("createObject", WeaveAPI.ExternalSessionStateInterface.requestObject);
			
			// include these packages in WeaveXMLDecoder so they will not need to be specified in the XML session state.
			WeaveXMLDecoder.includePackages(
				"org.oicweave",
				"org.oicweave.core",
				"org.oicweave.data",
				"org.oicweave.data.AttributeColumns",
				"org.oicweave.data.ColumnReferences",
				"org.oicweave.data.BinClassifiers",
				"org.oicweave.data.BinningDefinitions",
				"org.oicweave.data.DataSources",
				"org.oicweave.data.KeySets",
				"org.oicweave.data.Units",
				"org.oicweave.primitives",
				"org.oicweave.Reports",
				"org.oicweave.test",
				"org.oicweave.ui",
				"org.oicweave.ui.vistools",
				"org.oicweave.visualization",
				"org.oicweave.visualization.tools",
				"org.oicweave.visualization.layers",
				"org.oicweave.visualization.plotters",
			    "org.oicweave.visualization.plotters.styles"
			);
		}
		
		
		private static var _root:ILinkableHashMap = null; // root object of Weave

		/**
		 * This is the root object in Weave, which is an ILinkableHashMap.
		 */
		public static function get root():ILinkableHashMap
		{
			if (_root == null)
			{
				_root = LinkableDynamicObject.globalHashMap;
				createDefaultObjects(_root);
			}
			return _root;
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
		 * @param removeMissingObjects If this is true, existing objects not appearing in the session state will be removed.
		 */
		public static function setSessionStateXML(newStateXML:XML, removeMissingObjects:Boolean):void
		{
			var newState:Array = WeaveXMLDecoder.decodeDynamicState(newStateXML);
			
			var t:DebugTimer = new DebugTimer();
			root.setSessionState(newState, removeMissingObjects);
			t.debug('set global session state');
		}
		
		public static const DEFAULT_WEAVE_PROPERTIES:String = "WeaveProperties";
		
		public static const DEFAULT_COLOR_BIN_COLUMN:String = "defaultColorBinColumn";
		public static const DEFAULT_COLOR_DATA_COLUMN:String = "defaultColorDataColumn";
		public static const DEFAULT_COLOR_COLUMN:String = "defaultColorColumn";

		public static const DEFAULT_SUBSET_KEYFILTER:String = "defaultSubsetKeyFilter";
		public static const DEFAULT_SELECTION_KEYSET:String = "defaultSelectionKeySet";
		public static const DEFAULT_PROBE_KEYSET:String = "defaultProbeKeySet";
		public static const SAVED_SELECTION_KEYSETS:String = "savedSelections";
		public static const SAVED_SUBSETS_KEYFILTERS:String = "savedSubsets";
		
		/**
		 * This initializes a default set of objects in an ILinkableHashMap.
		 */
		private static function createDefaultObjects(target:ILinkableHashMap):void
		{
			target.requestObject(DEFAULT_WEAVE_PROPERTIES, WeaveProperties, true);

			initializeColorColumns(target);

			target.requestObject(SAVED_SELECTION_KEYSETS, LinkableHashMap, true);
			target.requestObject(SAVED_SUBSETS_KEYFILTERS, LinkableHashMap, true);
		}
		
		private static function initializeColorColumns(target:ILinkableHashMap):void
		{
			// default color column
			var cc:ColorColumn = target.requestObject(DEFAULT_COLOR_COLUMN, ColorColumn, true);
			var bc:BinnedColumn = cc.internalDynamicColumn.requestGlobalObject(DEFAULT_COLOR_BIN_COLUMN, BinnedColumn, true);
			var fc:FilteredColumn = bc.internalDynamicColumn.requestGlobalObject(DEFAULT_COLOR_DATA_COLUMN, FilteredColumn, true);
			fc.filter.requestGlobalObject(DEFAULT_SUBSET_KEYFILTER, KeyFilter, true);
			
			// default key sets
			var subset:KeyFilter = target.requestObject(DEFAULT_SUBSET_KEYFILTER, KeyFilter, true);
			subset.includeMissingKeys.value = true; // default subset should include all keys
			target.requestObject(DEFAULT_SELECTION_KEYSET, KeySet, true);
			target.requestObject(DEFAULT_PROBE_KEYSET, KeySet, true);
		}
	}
}
