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

package weave.data.DataSources
{
	import avmplus.describeType;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableOwner;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newLinkableChild;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableHashMap;
	import weave.core.SessionManager;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.data.KeySets.FilteredKeySet;
	import weave.utils.AsyncSort;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.VectorUtils;
	
	public class TransposedDataSource extends AbstractDataSource
	{
		public function TransposedDataSource()
		{
			(WeaveAPI.SessionManager as SessionManager).excludeLinkableChildFromSessionState(this, attributeHierarchy);
			getCallbackCollection(filteredKeySet).addImmediateCallback(null, resetHierarchy);
			getCallbackCollection(metadata).addImmediateCallback(null, resetHierarchy);
			internalData = new InternalData(this);
			columns.childListCallbacks.addImmediateCallback(this, handleColumnsChange);
			metadata.childListCallbacks.addImmediateCallback(this, setColumnKeySources);
			filteredKeySet.keyFilter.globalName = 'defaultSubsetKeyFilter';
		}
		
		public const filteredKeySet:IFilteredKeySet = newLinkableChild(this, FilteredKeySet);
		
		/**
		 * These are the variables used as metadata for the transposed attribute columns.
		 */
		public const metadata:ILinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IAttributeColumn));
		/**
		 * These are the columns that will be transposed.
		 * The names in this hash map will be used as localName values in transposed IQualifedKey objects.
		 */
		public const columns:ILinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IAttributeColumn));
		
		private var internalData:InternalData;
		
		private function resetHierarchy():void
		{
			if (!linkableObjectIsBusy(filteredKeySet))
				_attributeHierarchy.value = null;
		}
		
		private function validateKeyType():void
		{
			// make sure keyType is set
			if (internalData.keyType == null)
			{
				var owner:ILinkableHashMap = getLinkableOwner(this) as ILinkableHashMap;
				internalData.keyType = owner ? owner.getName(this) : DataTypes.STRING;
			}
		}
		
		private function handleColumnsChange():void
		{
			validateKeyType();
			
			var names:Array = columns.getNames();
			var objects:Array = columns.getObjects();
			
			// update transposed keys to correspond to column names
			internalData.transposedKeys = WeaveAPI.QKeyManager.getQKeys(internalData.keyType, names);
			
			// update column lookup
			internalData.columnsArray = objects;
			for (var i:int = 0; i < names.length; i++)
				internalData.columnNameIndex[names[i]] = i;
			if (columns.childListCallbacks.lastNameRemoved)
				delete internalData.columnNameIndex[columns.childListCallbacks.lastNameRemoved];
			
			setColumnKeySources();
		}
		
		private function setColumnKeySources():void
		{
			// get union of original keys
			(filteredKeySet as FilteredKeySet).setColumnKeySources(
				VectorUtils.flatten(internalData.columnsArray, metadata.getObjects())
			);
		}
		
		override protected function get initializationComplete():Boolean
		{
			// column requests aren't handled until this becomes true
			return super.initializationComplete;
		}
		
		override protected function initialize():void
		{
			validateKeyType();
			
			super.initialize();
		}
		
		private function toCSV(...values):String
		{
			return WeaveAPI.CSVParser.createCSV([values]);
		}
		
		public static const PROPERTY_NAME:String = "TransposedDataSource_propertyName";
		public static const RECORD_KEY:String = "TransposedDataSource_recordKey";
		
		override protected function requestHierarchyFromSource(subtreeNode:XML = null):void
		{
			if (!subtreeNode && _attributeHierarchy.value == null)
			{
				validateKeyType();

				var hierarchy:XML = <hierarchy title={ internalData.keyType }/>;
				
				var recordCategory:XML = <category title={ lang('Transposed columns') }/>;
				var keys:Array = filteredKeySet.keys;
				for each (var key:IQualifiedKey in keys)
				{
					var recordAttr:XML = <attribute/>;
					recordAttr['@'+ColumnMetadata.TITLE] = key.localName;
					recordAttr['@'+RECORD_KEY] = toCSV(key.keyType, key.localName);
					for each (propertyName in metadata.getNames())
					{
						var metaColumn:IAttributeColumn = metadata.getObject(propertyName) as IAttributeColumn;
						var value:String = metaColumn.getValueFromKey(key, String) as String;
						if (value)
							recordAttr['@'+propertyName] = value;
					}
					recordCategory.appendChild(recordAttr);
				}
				hierarchy.appendChild(recordCategory);
				
				var metaCategory:XML = <category title={ lang('Original column metadata') }/>;
				var propertyName:String;
				for each (propertyName in internalData.getMetadataPropertyNames())
				{
					var metaAttr:XML = <attribute title={ propertyName }/>;
					metaAttr['@'+PROPERTY_NAME] = propertyName;
					metaCategory.appendChild(metaAttr);
				}
				hierarchy.appendChild(metaCategory);
				
				_attributeHierarchy.value = hierarchy;
			}
		}

		/**
		 * This function must be implemented by classes by extend AbstractDataSource.
		 * This function should make a request to the source to fill in the proxy column.
		 * @param columnReference An object that contains all the information required to request the column from this IDataSource. 
		 * @param A ProxyColumn object that will be updated when the column data is ready.
		 */
		override protected function requestColumnFromSource(columnReference:IColumnReference, proxyColumn:ProxyColumn):void
		{
			var hierarchyRef:HierarchyColumnReference = columnReference as HierarchyColumnReference;
			if (!hierarchyRef)
				return handleUnsupportedColumnReference(columnReference, proxyColumn);

			var pathInHierarchy:XML = hierarchyRef.hierarchyPath.value;
			var leafNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy);
			//delete leafNode.@title;
			proxyColumn.setMetadata(leafNode);

			var recordKey:String = proxyColumn.getMetadata(RECORD_KEY);
			var propertyName:String = proxyColumn.getMetadata(PROPERTY_NAME);
			
			if (recordKey)
			{
				var csv:Array = WeaveAPI.CSVParser.parseCSV(recordKey);
				var key:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(csv[0][0], csv[0][1]);
				proxyColumn.setInternalColumn(new TransposedRecord(this, internalData, key, null));
			}
			else if (propertyName)
			{
				proxyColumn.setInternalColumn(new TransposedRecord(this, internalData, null, propertyName));
			}
			else
				proxyColumn.setInternalColumn(ProxyColumn.undefinedColumn);
		}
	}
}
import weave.api.core.ILinkableObject;
import weave.api.data.IFilteredKeySet;
import weave.api.detectLinkableObjectChange;
import weave.api.newLinkableChild;
import weave.api.registerLinkableChild;
import weave.data.KeySets.FilteredKeySet;
import weave.utils.AsyncSort;
import weave.utils.VectorUtils;

internal class InternalData
{
	public function InternalData(dataSource:TransposedDataSource)
	{
		this.dataSource = dataSource;
		this.callbacks = getCallbackCollection(dataSource);
	}
	
	public var dataSource:TransposedDataSource;
	public var callbacks:ICallbackCollection;
	public var triggerCounter:uint = 0;
	
	public var columnsArray:Array = [];
	public var columnNameIndex:Object = {};
	public var transposedKeys:Array = [];
	public var keyType:String;
	public var metadataCache:Object;
	public function getMetadataPropertyNames():Array
	{
		if (detectLinkableObjectChange(getMetadataPropertyNames, dataSource.columns))
		{
			// get sorted union of all metadata property names from data columns
			var propertyNameHash:Object = {};
			for each (var column:IAttributeColumn in columnsArray)
				VectorUtils.fillKeys(propertyNameHash, column.getMetadataPropertyNames());
			_metadataPropertyNames = VectorUtils.getKeys(propertyNameHash);
			ColumnUtils.sortMetadataPropertyNames(_metadataPropertyNames);
		}
		return _metadataPropertyNames;
	}
	private var _metadataPropertyNames:Array;
}

import weave.api.core.ICallbackCollection;
import weave.api.core.IDisposableObject;
import weave.api.data.ColumnMetadata;
import weave.api.data.IAttributeColumn;
import weave.api.data.IQualifiedKey;
import weave.api.getCallbackCollection;
import weave.api.registerDisposableChild;
import weave.data.DataSources.TransposedDataSource;
import weave.utils.ColumnUtils;
import weave.utils.EquationColumnLib;
import weave.api.data.DataTypes;
import weave.compiler.ProxyObject;

internal class TransposedRecord implements IAttributeColumn, IDisposableObject
{
	private var dataSource:TransposedDataSource;
	private var columnCallbacks:ICallbackCollection;
	private var internalData:InternalData;
	private var callbacks:ICallbackCollection;
	private var originalKey:IQualifiedKey;
	private var metadataName:String;
	
	public function TransposedRecord(dataSource:TransposedDataSource, internalData:InternalData, originalKey:IQualifiedKey, metadataName:String)
	{
		registerDisposableChild(dataSource, this);
		
		this.dataSource = dataSource;
		this.columnCallbacks = getCallbackCollection(dataSource.columns);
		this.internalData = internalData;
		this.callbacks = getCallbackCollection(dataSource);
		this.originalKey = originalKey;
		this.metadataName = metadataName;
	}
	
	public function dispose():void
	{
		dataSource = null;
		columnCallbacks = null;
		internalData = null;
		callbacks = null;
		originalKey = null;
		metadataName = null;
	}
	
	public function get keys():Array
	{
		return internalData.transposedKeys;
	}
	
	public function containsKey(key:IQualifiedKey):Boolean
	{
		return key.keyType == internalData.keyType
			&& internalData.columnNameIndex.hasOwnProperty(key.localName);
	}
	
	private static const META_META_PROPERTY_NAMES:Array = [ColumnMetadata.TITLE, ColumnMetadata.DATA_TYPE];
	
	public function getMetadataPropertyNames():Array
	{
		if (metadataName)
			return META_META_PROPERTY_NAMES;
		
		return internalData.getMetadataPropertyNames();
	}
	
	public function getMetadata(propertyName:String):String
	{
		// since this column is a transposed record, keyType is a custom value
		if (propertyName == ColumnMetadata.KEY_TYPE)
			return internalData.keyType;
		
		if (metadataName)
		{
			if (propertyName == ColumnMetadata.TITLE)
				return propertyName;
			if (propertyName == ColumnMetadata.DATA_TYPE)
				return DataTypes.STRING;
			return null;
		}
		
		// see if there is an original column specified to fill this transposed metadata
		var metaColumn:IAttributeColumn = dataSource.metadata.getObject(propertyName) as IAttributeColumn;
		if (metaColumn)
			return metaColumn.getValueFromKey(originalKey, String) as String;
		
		// for all other metadata, cache values common among all columns
		// when columns change, reset cached metadata
		if (internalData.triggerCounter != columnCallbacks.triggerCounter)
		{
			internalData.triggerCounter = columnCallbacks.triggerCounter;
			internalData.metadataCache = {};
		}
		if (internalData.metadataCache.hasOwnProperty(propertyName))
			return internalData.metadataCache[propertyName];
		var value:String = ColumnUtils.getCommonMetadata(internalData.columnsArray, propertyName);
		internalData.metadataCache[propertyName] = value;
		return value;
	}
	
	public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
	{
		var value:* = undefined;
		if (key.keyType == internalData.keyType)
		{
			var col:IAttributeColumn = internalData.columnsArray[internalData.columnNameIndex[key.localName]] as IAttributeColumn;
			if (col)
			{
				if (originalKey)
				{
					return col.getValueFromKey(originalKey, dataType);
				}
				if (metadataName)
				{
					if (dataType == Number)
						return Number(internalData.columnNameIndex[key.localName]);
					
					return col.getMetadata(metadataName);
				}
			}
		}
		
		return EquationColumnLib.cast(value, dataType);
	}
	
	//-------------------------------
	// ICallbackCollection interface
	
	public function addImmediateCallback(relevantContext:Object, callback:Function, runCallbackNow:Boolean = false, alwaysCallLast:Boolean = false):void
	{
		if (callbacks)
			callbacks.addImmediateCallback.apply(this, arguments);
	}
	public function addGroupedCallback(relevantContext:Object, groupedCallback:Function, triggerCallbackNow:Boolean = false):void
	{
		if (callbacks)
			callbacks.addGroupedCallback.apply(this, arguments);
	}
	public function addDisposeCallback(relevantContext:Object, callback:Function):void
	{
		if (callbacks)
			callbacks.addDisposeCallback.apply(this, arguments);
	}
	public function removeCallback(callback:Function):void
	{
		if (callbacks)
			callbacks.removeCallback.apply(this, arguments);
	}
	public function get triggerCounter():uint
	{
		return callbacks ? callbacks.triggerCounter : 0;
	}
	public function triggerCallbacks():void
	{
		if (callbacks)
			callbacks.triggerCallbacks.apply(this, arguments);
	}
	public function get callbacksAreDelayed():Boolean
	{
		return callbacks ? callbacks.callbacksAreDelayed : false;
	}
	public function delayCallbacks():void
	{
		if (callbacks)
			callbacks.delayCallbacks.apply(this, arguments);
	}
	public function resumeCallbacks():void
	{
		if (callbacks)
			callbacks.resumeCallbacks.apply(this, arguments);
	}
}
