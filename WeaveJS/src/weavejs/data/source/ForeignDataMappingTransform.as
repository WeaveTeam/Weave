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
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.ISelectableAttributes;
	import weavejs.api.data.IWeaveTreeNode;
	import weavejs.core.LinkableHashMap;
	import weavejs.data.column.DynamicColumn;
	import weavejs.data.column.ProxyColumn;
	import weavejs.data.hierarchy.ColumnTreeNode;

	public class ForeignDataMappingTransform extends AbstractDataSource implements ISelectableAttributes
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, ForeignDataMappingTransform, "Foreign data mapping");

		public static const DATA_COLUMNNAME_META:String = "__DataColumnName__";

		public const keyColumn:DynamicColumn = Weave.linkableChild(this, DynamicColumn);
		public const dataColumns:ILinkableHashMap = Weave.linkableChild(this, new LinkableHashMap(IAttributeColumn));
		

		public function ForeignDataMappingTransform()
		{
		}

		public function getSelectableAttributeNames():Array
		{
			return ["Foreign key mapping", "Data to transform"];
		}
		public function getSelectableAttributes():Array
		{
			return [keyColumn, dataColumns];
		}
		
		override protected function get initializationComplete():Boolean
		{
			return super.initializationComplete
				&& !Weave.isBusy(keyColumn)
				&& !Weave.isBusy(dataColumns);
		}
		
		override protected function initialize(forceRefresh:Boolean = false):void
		{
			// recalculate all columns previously requested
			super.initialize(true);
		}
		
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!_rootNode)
				_rootNode = new ColumnTreeNode({
					cacheSettings: {label: false},
					dataSource: this,
					dependency: dataColumns,
					data: this,
					label: getLabel,
					hasChildBranches: false,
					children: function():Array {
						return dataColumns.getNames().map(
							function(dataColumnName:String, ..._):* {
								var column:IAttributeColumn = dataColumns.getObject(dataColumnName) as IAttributeColumn;
								var title:String = column.getMetadata(ColumnMetadata.TITLE);
								var metadata:Object = {};
								metadata[ColumnMetadata.TITLE] = title;
								metadata[DATA_COLUMNNAME_META] = dataColumnName;
								return generateHierarchyNode(metadata);
							}
						);
					}
				});
			return _rootNode;
		}

		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata)
				return null;
			
			var name:String = metadata[DATA_COLUMNNAME_META];
			metadata = getColumnMetadata(name);
			if (!metadata)
				return null;
			
			return new ColumnTreeNode({
				dataSource: this,
				idFields: [DATA_COLUMNNAME_META],
				data: metadata
			});
		}
		
		private function getColumnMetadata(dataColumnName:String, includeSourceColumnMetadata:Boolean = true):Object
		{
			var column:IAttributeColumn = dataColumns.getObject(dataColumnName) as IAttributeColumn;
			if (!column)
				return null;
			
			var metadata:Object = includeSourceColumnMetadata ? ColumnMetadata.getAllMetadata(column) : {};
			metadata[ColumnMetadata.KEY_TYPE] = keyColumn.getMetadata(ColumnMetadata.KEY_TYPE);
			metadata[DATA_COLUMNNAME_META] = dataColumnName;
			return metadata;
		}
		
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var dataColumnName:String = proxyColumn.getMetadata(DATA_COLUMNNAME_META);
			var metadata:Object = getColumnMetadata(dataColumnName, false);
			if (!metadata)
			{
				proxyColumn.dataUnavailable();
				return;
			}
			proxyColumn.setMetadata(metadata);
			
			var dataColumn:IAttributeColumn = dataColumns.getObject(dataColumnName) as IAttributeColumn;
			var foreignDataColumn:ForeignDataColumn = proxyColumn.getInternalColumn() as ForeignDataColumn || new ForeignDataColumn(this);
			foreignDataColumn.setup(metadata, dataColumn);
			
			proxyColumn.setInternalColumn(foreignDataColumn);
		}
	}
}

import weavejs.WeaveAPI;
import weavejs.api.data.ColumnMetadata;
import weavejs.api.data.DataType;
import weavejs.api.data.IAttributeColumn;
import weavejs.api.data.IPrimitiveColumn;
import weavejs.api.data.IQualifiedKey;
import weavejs.core.SessionManager;
import weavejs.data.ColumnUtils;
import weavejs.data.column.AbstractAttributeColumn;
import weavejs.data.source.ForeignDataMappingTransform;
import weavejs.util.ArrayUtils;

internal class ForeignDataColumn extends AbstractAttributeColumn implements IPrimitiveColumn
{
	public function ForeignDataColumn(source:ForeignDataMappingTransform)
	{
		Weave.linkableChild(this, source);
		_keyColumn = source.keyColumn;
	}
	
	private var _keyColumn:IAttributeColumn;
	private var _dataColumn:IAttributeColumn;
	private var _keyType:String;
	
	public function setup(metadata:Object, dataColumn:IAttributeColumn):void
	{
		if (_dataColumn && _dataColumn != dataColumn)
			(WeaveAPI.SessionManager as SessionManager).unregisterLinkableChild(this, _dataColumn);
		
		_metadata = copyValues(metadata);
		_dataColumn = Weave.linkableChild(this, dataColumn);
		_keyType = dataColumn.getMetadata(ColumnMetadata.KEY_TYPE);
		triggerCallbacks();
	}
	
	override public function getMetadata(propertyName:String):String
	{
		return super.getMetadata(propertyName)
			|| _dataColumn.getMetadata(propertyName);
	}
	
	override public function getMetadataPropertyNames():Array
	{
		if (_dataColumn)
			return ArrayUtils.union(super.getMetadataPropertyNames(), _dataColumn.getMetadataPropertyNames());
		return super.getMetadataPropertyNames();
	}
	
	override public function get keys():Array
	{
		return _keyColumn.keys;
	}
	
	override public function containsKey(key:IQualifiedKey):Boolean
	{
		return _dataColumn.containsKey(key);
	}
	
	public function deriveStringFromNumber(value:Number):String
	{
		return ColumnUtils.deriveStringFromNumber(_dataColumn, value);
	}
	
	override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
	{
		//TODO - this should be cached
		var localName:String;
		// if the foreign key column is numeric, avoid using the formatted strings as keys
		if (_keyColumn.getMetadata(ColumnMetadata.DATA_TYPE) == DataType.NUMBER)
			localName = _keyColumn.getValueFromKey(key, Number);
		else
			localName = _keyColumn.getValueFromKey(key, String);
		
		var foreignKey:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(_keyType, localName);
		return _dataColumn.getValueFromKey(foreignKey, dataType);
	}
}
