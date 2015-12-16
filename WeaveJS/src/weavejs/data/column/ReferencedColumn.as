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

package weavejs.data.column
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IColumnWrapper;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.CallbackCollection;
	import weavejs.core.LinkableString;
	import weavejs.core.LinkableVariable;
	import weavejs.core.LinkableWatcher;
	import weavejs.data.hierarchy.GlobalColumnDataSource;
	
	/**
	 * This provides a wrapper for a referenced column.
	 * 
	 * @author adufilie
	 */
	public class ReferencedColumn extends CallbackCollection implements IColumnWrapper
	{
		public function ReferencedColumn()
		{
			super();
		}
		
		private var _initialized:Boolean = false;
		
		private var _dataSource:IDataSource;
		
		private function updateDataSource():void
		{
			var root:ILinkableHashMap = Weave.getRoot(this);
			if (!root)
				return;
			
			if (!_initialized)
			{
				root.childListCallbacks.addImmediateCallback(this, updateDataSource);
				_initialized = true;
			}
			
			var ds:IDataSource = root.getObject(dataSourceName.value) as IDataSource;
			if (!ds)
				ds = GlobalColumnDataSource.getInstance(root);
			if (_dataSource != ds)
			{
				_dataSource = ds;
				triggerCallbacks();
			}
		}
		
		/**
		 * This is the name of an IDataSource in the top level session state.
		 */
		public var dataSourceName:LinkableString = Weave.linkableChild(this, LinkableString, updateDataSource);
		
		/**
		 * This holds the metadata used to identify a column.
		 */
		public var metadata:LinkableVariable = Weave.linkableChild(this, LinkableVariable);
		
		/**
		 * @inheritDoc
		 */
		public function getDataSource():IDataSource
		{
			return _dataSource;
		}
		
		/**
		 * Updates the session state to refer to a new column.
		 */
		public function setColumnReference(dataSource:IDataSource, metadata:Object):void
		{
			delayCallbacks();
			dataSourceName.value = Weave.getRoot(this).getName(dataSource);
			this.metadata.setSessionState(metadata);
			resumeCallbacks();
		}
		
		/**
		 * The trigger counter value at the last time the internal column was retrieved.
		 */		
		private var _prevTriggerCounter:uint = 0;
		/**
		 * the internal referenced column
		 */
		private var _internalColumn:IAttributeColumn = null;
		
		private var _columnWatcher:LinkableWatcher = Weave.linkableChild(this, LinkableWatcher);
		
		/**
		 * @inheritDoc 
		 */		
		public function getInternalColumn():IAttributeColumn
		{
			if (_prevTriggerCounter != triggerCounter)
			{
				if (Weave.wasDisposed(_dataSource))
					_dataSource = null;
				
				_columnWatcher.target = _internalColumn = WeaveAPI.AttributeColumnCache.getColumn(_dataSource, metadata.state);
				
				_prevTriggerCounter = triggerCounter;
			}
			return _internalColumn;
		}
		
		
		/************************************
		 * Begin IAttributeColumn interface
		 ************************************/

		public function getMetadata(attributeName:String):String
		{
			if (_prevTriggerCounter != triggerCounter)
				getInternalColumn();
			return _internalColumn ? _internalColumn.getMetadata(attributeName) : null;
		}

		public function getMetadataPropertyNames():Array
		{
			if (_prevTriggerCounter != triggerCounter)
				getInternalColumn();
			return _internalColumn ? _internalColumn.getMetadataPropertyNames() : [];
		}
		
		/**
		 * @return the keys associated with this column.
		 */
		public function get keys():Array
		{
			if (_prevTriggerCounter != triggerCounter)
				getInternalColumn();
			return _internalColumn ? _internalColumn.keys : [];
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			if (_prevTriggerCounter != triggerCounter)
				getInternalColumn();
			return _internalColumn && _internalColumn.containsKey(key);
		}
		
		/**
		 * getValueFromKey
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_prevTriggerCounter != triggerCounter)
				getInternalColumn();
			return _internalColumn ? _internalColumn.getValueFromKey(key, dataType) : undefined;
		}
	}
}
