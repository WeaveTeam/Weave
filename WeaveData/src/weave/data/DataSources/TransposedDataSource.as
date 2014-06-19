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
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataSource;
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
	import weave.data.KeySets.FilteredKeySet;
	import weave.utils.ColumnUtils;
	import weave.utils.VectorUtils;
	
	public class TransposedDataSource extends AbstractDataSource
	{
		WeaveAPI.registerImplementation(IDataSource, TransposedDataSource, "Transposed data");
		
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
			if (internalData.transposedKeyType == null)
			{
				var owner:ILinkableHashMap = getLinkableOwner(this) as ILinkableHashMap;
				internalData.transposedKeyType = owner ? owner.getName(this) : DataTypes.STRING;
			}
		}
		
		private function handleColumnsChange():void
		{
			validateKeyType();
			
			var names:Array = columns.getNames();
			var objects:Array = columns.getObjects();
			
			// update transposed keys to correspond to column names
			internalData.transposedKeys = WeaveAPI.QKeyManager.getQKeys(internalData.transposedKeyType, names);
			
			// update column lookup
			internalData.sourceColumnsArray = objects;
			for (var i:int = 0; i < names.length; i++)
				internalData.sourceColumnNameToIndex[names[i]] = i;
			if (columns.childListCallbacks.lastNameRemoved)
				delete internalData.sourceColumnNameToIndex[columns.childListCallbacks.lastNameRemoved];
			
			setColumnKeySources();
		}
		
		private function setColumnKeySources():void
		{
			// get union of original keys
			(filteredKeySet as FilteredKeySet).setColumnKeySources(
				VectorUtils.flatten(internalData.sourceColumnsArray, metadata.getObjects())
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
		
		public static const PROPERTY_NAME:String = "TransposedDataSource_propertyName";
		public static const RECORD_KEY:String = "TransposedDataSource_recordKey";
		
		override protected function requestHierarchyFromSource(subtreeNode:XML = null):void
		{
			if (!subtreeNode && _attributeHierarchy.value == null)
			{
				validateKeyType();

				var hierarchy:XML = <hierarchy title={ internalData.transposedKeyType }/>;
				
				var metaCategory:XML = <category title={ lang('Source column metadata') }/>;
				var propertyName:String;
				for each (propertyName in internalData.getMetadataPropertyNames())
				{
					var metaAttr:XML = <attribute title={ propertyName }/>;
					metaAttr['@'+PROPERTY_NAME] = propertyName;
					metaCategory.appendChild(metaAttr);
				}
				hierarchy.appendChild(metaCategory);
				
				var recordCategory:XML = <category title={ lang('Transposed columns') }/>;
				var keys:Array = filteredKeySet.keys;
				for each (var key:IQualifiedKey in keys)
				{
					var recordAttr:XML = <attribute/>;
					recordAttr['@'+ColumnMetadata.TITLE] = key.localName;
					recordAttr['@'+RECORD_KEY] = WeaveAPI.CSVParser.createCSVRow([key.keyType, key.localName]);
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
				
				_attributeHierarchy.value = hierarchy;
			}
		}

		/**
		 * @inheritDoc
		 */
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var recordKey:String = proxyColumn.getMetadata(RECORD_KEY);
			var propertyName:String = proxyColumn.getMetadata(PROPERTY_NAME);
			if (recordKey)
			{
				var csv:Array = WeaveAPI.CSVParser.parseCSVRow(recordKey);
				var key:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(csv[0], csv[1]);
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
import weave.api.data.IFilteredKeySet;
import weave.api.detectLinkableObjectChange;
import weave.api.newLinkableChild;
import weave.api.registerLinkableChild;
import weave.data.KeySets.FilteredKeySet;
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
	
	public var sourceColumnsArray:Array = [];
	public var sourceColumnNameToIndex:Object = {};
	public var sourceMetadataCache:Object;
	public var transposedKeys:Array = [];
	public var transposedKeyType:String;
	public var deriveStringFromNumber:Function;
	
	public var lastError:String;
	public var lastErrorColumn:IAttributeColumn;
	public function errorHandler(e:Error):void
	{
		var str:String = e is Error ? e.message : String(e);
		str = StandardLib.substitute("Error in string formatting script for transposed column {0}:\n{1}", lastErrorColumn.getMetadata(ColumnMetadata.TITLE), str);
		if (lastError != str)
		{
			lastError = str;
			reportError(e);
		}
	}

	
	public function getMetadataPropertyNames():Array
	{
		if (detectLinkableObjectChange(getMetadataPropertyNames, dataSource.columns))
		{
			// get sorted union of all metadata property names from data columns
			var propertyNameHash:Object = {};
			for each (var column:IAttributeColumn in sourceColumnsArray)
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
import weave.api.data.IPrimitiveColumn;
import weave.compiler.StandardLib;
import weave.compiler.Compiler;
import weave.api.reportError;

internal class TransposedRecord implements IAttributeColumn, IDisposableObject, IPrimitiveColumn
{
	private var dataSource:TransposedDataSource;
	private var columnCallbacks:ICallbackCollection;
	private var internalData:InternalData;
	private var callbacks:ICallbackCollection;
	private var sourceKey:IQualifiedKey;
	private var sourceMetadataName:String;
	
	public function TransposedRecord(dataSource:TransposedDataSource, internalData:InternalData, sourceKey:IQualifiedKey, metadataName:String)
	{
		registerDisposableChild(dataSource, this);
		
		this.dataSource = dataSource;
		this.columnCallbacks = getCallbackCollection(dataSource.columns);
		this.internalData = internalData;
		this.callbacks = getCallbackCollection(dataSource);
		this.sourceKey = sourceKey;
		this.sourceMetadataName = metadataName;
	}
	
	public function dispose():void
	{
		dataSource = null;
		columnCallbacks = null;
		internalData = null;
		callbacks = null;
		sourceKey = null;
		sourceMetadataName = null;
	}
	
	public function get keys():Array
	{
		return internalData.transposedKeys;
	}
	
	public function containsKey(key:IQualifiedKey):Boolean
	{
		return key.keyType == internalData.transposedKeyType
			&& internalData.sourceColumnNameToIndex.hasOwnProperty(key.localName);
	}
	
	private static const META_META_PROPERTY_NAMES:Array = [ColumnMetadata.TITLE, ColumnMetadata.DATA_TYPE];
	
	public function getMetadataPropertyNames():Array
	{
		if (sourceMetadataName)
			return META_META_PROPERTY_NAMES;
		
		return internalData.getMetadataPropertyNames();
	}
	
	public function getMetadata(propertyName:String):String
	{
		// when columns change, reset cached metadata
		if (internalData.triggerCounter != columnCallbacks.triggerCounter)
		{
			internalData.triggerCounter = columnCallbacks.triggerCounter;
			internalData.sourceMetadataCache = {};
			internalData.deriveStringFromNumber = null;
		}
		
		// since this column is a transposed record, keyType is a custom value
		if (propertyName == ColumnMetadata.KEY_TYPE)
			return internalData.transposedKeyType;
		
		if (sourceMetadataName)
		{
			// metadata for transposed metadata columns
			if (propertyName == ColumnMetadata.TITLE)
				return sourceMetadataName;
			if (propertyName == ColumnMetadata.DATA_TYPE)
				return DataTypes.STRING;
			return null;
		}
		
		// see if there is a source metadata column specified to fill this transposed metadata
		var metaColumn:IAttributeColumn = dataSource.metadata.getObject(propertyName) as IAttributeColumn;
		if (metaColumn)
			return metaColumn.getValueFromKey(sourceKey, String) as String;
		
		// for all other metadata, cache values common among all columns
		if (internalData.sourceMetadataCache.hasOwnProperty(propertyName))
			return internalData.sourceMetadataCache[propertyName];
		var value:String = ColumnUtils.getCommonMetadata(internalData.sourceColumnsArray, propertyName);
		internalData.sourceMetadataCache[propertyName] = value;
		return value;
	}
	
	private static const compiler:Compiler = new Compiler();
	public function deriveStringFromNumber(number:Number):String
	{
		if (sourceMetadataName)
		{
			// for transposed metadata column, treat number as a source column index
			var sourceColumn:IAttributeColumn = internalData.sourceColumnsArray[number] as IAttributeColumn;
			return sourceColumn ? sourceColumn.getMetadata(sourceMetadataName) : '';
		}

		if (internalData.triggerCounter != columnCallbacks.triggerCounter)
			getMetadata(ColumnMetadata.STRING); // this resets internalData.triggerCounter and internalData.deriveStringFromNumber
		
		if (internalData.deriveStringFromNumber == null)
		{
			try
			{
				var script:String = getMetadata(ColumnMetadata.STRING);
				internalData.deriveStringFromNumber = compiler.compileToFunction(script, null, internalData.errorHandler, false, [ColumnMetadata.NUMBER]);
			}
			catch (e:Error)
			{
				internalData.errorHandler(e);
			}
			
			if (internalData.deriveStringFromNumber == null)
				internalData.deriveStringFromNumber = StandardLib.formatNumber;
		}
			
		return internalData.deriveStringFromNumber(number);
	}
	
	public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
	{
		var value:* = undefined;
		if (key.keyType == internalData.transposedKeyType)
		{
			// key.localName is source column name
			var sourceColumnIndex:* = internalData.sourceColumnNameToIndex[key.localName];
			var sourceColumn:IAttributeColumn = internalData.sourceColumnsArray[sourceColumnIndex] as IAttributeColumn;
			if (sourceColumn)
			{
				if (sourceKey)
				{
					return sourceColumn.getValueFromKey(sourceKey, dataType);
				}
				if (sourceMetadataName)
				{
					// for transposed metadata column, numeric value is source column index
					if (dataType == Number)
						return Number(sourceColumnIndex);
					
					return sourceColumn.getMetadata(sourceMetadataName);
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
