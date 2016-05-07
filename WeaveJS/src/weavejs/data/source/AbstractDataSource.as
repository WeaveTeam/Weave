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

package weavejs.data.source
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.IDisposableObject;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IWeaveTreeNode;
	import weavejs.core.CallbackCollection;
	import weavejs.core.LinkableString;
	import weavejs.data.column.ProxyColumn;
	import weavejs.data.hierarchy.HierarchyUtils;
	import weavejs.util.DebugUtils;
	import weavejs.util.JS;
	
	/**
	 * This is a base class to make it easier to develope a new class that implements IDataSource.
	 * Classes that extend AbstractDataSource should implement the following methods:
	 * getHierarchyRoot, generateHierarchyNode, requestColumnFromSource 
	 * 
	 * @author adufilie
	 */
	public class AbstractDataSource implements IDataSource, IDisposableObject
	{
		public function AbstractDataSource()
		{
			var cc:ICallbackCollection = Weave.getCallbacks(this);
			cc.addImmediateCallback(this, uninitialize);
			cc.addGroupedCallback(this, initialize, true, false);
		}
		
		/**
		 * Overrides root hierarchy label.
		 */
		public const label:LinkableString = Weave.linkableChild(this, LinkableString);
		
		public function getLabel():String
		{
			if (label.value)
				return label.value;
			var root:ILinkableHashMap = Weave.getRoot(this);
			if (root)
				return root.getName(this);
			return null;
		}

		/**
		 * This variable is set to false when the session state changes and true when initialize() is called.
		 */
		protected var _initializeCalled:Boolean = false;
		
		/**
		 * This should be used to keep a pointer to the hierarchy root node.
		 */
		protected var _rootNode:IWeaveTreeNode;
		
		/**
		 * ProxyColumn -> (true if pending, false if not pending)
		 */
		protected var map_proxyColumn_pending:Object = new JS.Map();
		
		private var _hierarchyRefresh:ICallbackCollection = Weave.linkableChild(this, CallbackCollection, refreshHierarchy);
		
		public function get hierarchyRefresh():ICallbackCollection
		{
			return _hierarchyRefresh;
		}
		
		/**
		 * Sets _rootNode to null and triggers callbacks.
		 * @inheritDoc
		 */
		protected function refreshHierarchy():void
		{
			_rootNode = null;
		}
		
		/**
		 * This function must be implemented by classes that extend AbstractDataSource.
		 * This function should set _rootNode if it is null, which may happen from calling refreshHierarchy().
		 * @inheritDoc
		 */
		/* abstract */ public function getHierarchyRoot():IWeaveTreeNode
		{
			return _rootNode;
		}

		/**
		 * This function must be implemented by classes that extend AbstractDataSource.
		 * This function should make a request to the source to fill in the proxy column.
		 * @param proxyColumn Contains metadata for the column request and will be used to store column data when it is ready.
		 */
		/* abstract */ protected function requestColumnFromSource(proxyColumn:ProxyColumn):void { }

		/**
		 * This function must be implemented by classes that extend AbstractDataSource.
		 * @param metadata A set of metadata that may identify a column in this IDataSource.
		 * @return A node that contains the metadata.
		 */
		/* abstract */ protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode { return null; }
		
		/**
		 * Classes that extend AbstractDataSource can define their own replacement for this function.
		 * All column requests will be delayed as long as this accessor function returns false.
		 * The default behavior is to return false during the time between a change in the session state and when initialize() is called.
		 */		
		protected function get initializationComplete():Boolean
		{
			return _initializeCalled;
		}

		/**
		 * This function is called as an immediate callback and sets initialized to false.
		 */
		protected function uninitialize():void
		{
			_initializeCalled = false;
		}
		
		/**
		 * This function will be called as a grouped callback the frame after the session state for the data source changes.
		 * When overriding this function, super.initialize() should be called.
		 */
		protected function initialize(forceRefresh:Boolean = false):void
		{
			// set initialized to true so other parts of the code know if this function has been called.
			_initializeCalled = true;
			if (forceRefresh)
				refreshAllProxyColumns(initializationComplete);
			else
				handleAllPendingColumnRequests(initializationComplete);
		}
		
		/**
		 * The default implementation of this function calls generateHierarchyNode(metadata) and
		 * then traverses the _rootNode to find a matching node.
		 * This function should be overridden if the hierachy is not known completely, since this
		 * may result in traversing the entire hierarchy, causing many remote procedure calls if
		 * the hierarchy is stored remotely.
		 */
		public function findHierarchyNode(metadata:Object):/*/IWeaveTreeNode & weavejs.api.data.IColumnReference/*/IWeaveTreeNode
		{
			var path:Array = HierarchyUtils.findPathToNode(getHierarchyRoot(), generateHierarchyNode(metadata));
			if (path)
				return path[path.length - 1];
			return null;
		}
		
		/**
		 * This function creates a new ProxyColumn object corresponding to the metadata and queues up the request for the column.
		 * @param metadata An object that contains all the information required to request the column from this IDataSource. 
		 * @return A ProxyColumn object that will be updated when the column data is ready.
		 */
		public function generateNewAttributeColumn(metadata:Object):IAttributeColumn
		{
			var proxyColumn:ProxyColumn = Weave.disposableChild(this, ProxyColumn);
			proxyColumn.setMetadata(metadata);
			var name:String = this.getLabel() || DebugUtils.debugId(this);
			var description:String = name + " pending column request";
			WeaveAPI.ProgressIndicator.addTask(proxyColumn, this, description);
			WeaveAPI.ProgressIndicator.addTask(proxyColumn, proxyColumn, description);
			handlePendingColumnRequest(proxyColumn);
			return proxyColumn;
		}
		
		/**
		 * This function will call requestColumnFromSource() if initializationComplete==true.
		 * Otherwise, it will delay the column request again.
		 * This function may be overridden by classes that extend AbstractDataSource.
		 * However, if the extending class decides it wants to call requestColumnFromSource()
		 * for the pending column, it is recommended to call super.handlePendingColumnRequest() instead.
		 * @param request The request that needs to be handled.
		 */
		protected function handlePendingColumnRequest(column:ProxyColumn, forced:Boolean = false):void
		{
			// If data source is already initialized (session state is stable, not currently changing), we can request the column now.
			// Otherwise, we have to wait.
			if (initializationComplete || forced)
			{
				map_proxyColumn_pending.set(column, false); // no longer pending
				WeaveAPI.ProgressIndicator.removeTask(column);
				requestColumnFromSource(column);
			}
			else
			{
				map_proxyColumn_pending.set(column, true); // pending
			}
		}
		
		/**
		 * This function will call handlePendingColumnRequest() on each pending column request.
		 */
		protected function handleAllPendingColumnRequests(forced:Boolean = false):void
		{
			var cols:Array = JS.mapKeys(map_proxyColumn_pending);
			for each (var proxyColumn:Object in cols)
				if (map_proxyColumn_pending.get(proxyColumn)) // pending?
					handlePendingColumnRequest(proxyColumn as ProxyColumn, forced);
		}
		
		/**
		 * Calls requestColumnFromSource() on all ProxyColumn objects created previously via generateNewAttributeColumn().
		 */
		protected function refreshAllProxyColumns(forced:Boolean = false):void
		{
			var cols:Array = JS.mapKeys(map_proxyColumn_pending);
			for each (var proxyColumn:Object in cols)
				handlePendingColumnRequest(proxyColumn as ProxyColumn, forced);
		}
		
		/**
		 * This function should be called when the IDataSource is no longer in use.
		 * All existing pointers to objects should be set to null so they can be garbage collected.
		 */
		public function dispose():void
		{
			var cols:Array = JS.mapKeys(map_proxyColumn_pending);
			for each (var column:Object in cols)
				WeaveAPI.ProgressIndicator.removeTask(column);
			_initializeCalled = false;
			map_proxyColumn_pending = null;
		}
	}
}
