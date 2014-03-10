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

package weave.data.AttributeColumns
{
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IDataSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.setSessionState;
	import weave.core.CallbackCollection;
	import weave.core.ClassUtils;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.core.LinkableWatcher;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	
	/**
	 * This provides a wrapper for a referenced column.
	 * 
	 * @author adufilie
	 */
	public class ReferencedColumn extends CallbackCollection implements IColumnWrapper
	{
		public function ReferencedColumn()
		{
			WeaveAPI.globalHashMap.childListCallbacks.addImmediateCallback(this, updateDataSource);
		}
		
		private var _dataSource:IDataSource;
		
		private function updateDataSource():void
		{
			var ds:IDataSource = WeaveAPI.globalHashMap.getObject(dataSourceName.value) as IDataSource;
			if (_dataSource != ds)
			{
				_dataSource = ds;
				triggerCallbacks();
			}
		}
		
		/**
		 * This is the name of an IDataSource in the top level session state.
		 */
		public const dataSourceName:LinkableString = newLinkableChild(this, LinkableString, updateDataSource);
		
		/**
		 * This holds the metadata used to identify a column.
		 */
		public const metadata:LinkableVariable = newLinkableChild(this, LinkableVariable);
		
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
			dataSourceName.value = WeaveAPI.globalHashMap.getName(dataSource);
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
		
		private const _columnWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher);
		
		/**
		 * @inheritDoc 
		 */		
		public function getInternalColumn():IAttributeColumn
		{
			if (_prevTriggerCounter != triggerCounter)
			{
				_columnWatcher.target = _internalColumn = WeaveAPI.AttributeColumnCache.getColumn(getDataSource(), metadata.getSessionState());
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
		
		public function toString():String
		{
			return debugId(this) + '(' + ColumnUtils.getTitle(this) + ')';
		}
		
		// backwards compatibility
		[Deprecated] public function set columnReference(value:Object):void { setSessionState(this['dynamicColumnReference'], value); }
		[Deprecated] public function get dynamicColumnReference():ILinkableDynamicObject
		{
			if (!_dcr)
			{
				ClassUtils.registerDeprecatedClass("weave.data.ColumnReferences::HierarchyColumnReference", HierarchyColumnReference);
				_dcr = newDisposableChild(this, LinkableDynamicObject);
				var hcr:HierarchyColumnReference = _dcr.requestLocalObject(HierarchyColumnReference, true);
				hcr.referencedColumn = this;
			}
			return _dcr;
		}
		private var _dcr:ILinkableDynamicObject;
	}
}

import weave.api.core.ILinkableObject;
import weave.api.newLinkableChild;
import weave.core.LinkableString;
import weave.core.LinkableXML;
import weave.data.AttributeColumns.ReferencedColumn;
import weave.utils.HierarchyUtils;

// for backwards compatibility
internal class HierarchyColumnReference implements ILinkableObject
{
	public var referencedColumn:ReferencedColumn;
	[Deprecated] public function set dataSourceName(state:String):void
	{
		if (referencedColumn)
			referencedColumn.dataSourceName.setSessionState(state);
	}
	[Deprecated] public function set hierarchyPath(state:Object):void
	{
		if (referencedColumn)
			referencedColumn.metadata.setSessionState(HierarchyUtils.getMetadata(LinkableXML.xmlFromState(state)));
	}
}
