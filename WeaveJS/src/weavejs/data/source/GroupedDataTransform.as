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
	import weavejs.api.core.ILinkableVariable;
	import weavejs.api.data.Aggregation;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.DataType;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.api.data.ISelectableAttributes;
	import weavejs.api.data.IWeaveTreeNode;
	import weavejs.core.LinkableHashMap;
	import weavejs.core.LinkableString;
	import weavejs.core.LinkableVariable;
	import weavejs.data.column.DynamicColumn;
	import weavejs.data.column.ProxyColumn;
	import weavejs.data.hierarchy.ColumnTreeNode;
	import weavejs.util.JS;

	public class GroupedDataTransform extends AbstractDataSource implements ISelectableAttributes
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, GroupedDataTransform, "Grouped data transform");

		public static const DATA_COLUMNNAME_META:String = "__GroupedDataColumnName__";

		public function GroupedDataTransform()
		{
		}
		
		public function get selectableAttributes():/*/Map<string, (weavejs.api.data.IColumnWrapper|weavejs.api.core.ILinkableHashMap)>/*/Object
		{
			return new JS.Map()
				.set("Group by", groupByColumn)
				.set("Data to transform", dataColumns);
		}
		
		override protected function get initializationComplete():Boolean
		{
			return super.initializationComplete
				&& !Weave.isBusy(groupByColumn)
				&& !Weave.isBusy(dataColumns);
		}

		override protected function initialize(forceRefresh:Boolean = false):void
		{
			super.initialize(true);
		}

		public const groupByColumn:DynamicColumn = Weave.linkableChild(this, DynamicColumn);
		public const groupKeyType:LinkableString = Weave.linkableChild(this, LinkableString);
		public const dataColumns:ILinkableHashMap = Weave.linkableChild(this, new LinkableHashMap(IAttributeColumn));

		/**
		 * The session state maps a column name in dataColumns hash map to a value for its "aggregation" metadata.
		 */
		public const aggregationModes:ILinkableVariable = Weave.linkableChild(this, new LinkableVariable(null, typeofIsObject));
		private function typeofIsObject(value:Object):Boolean
		{
			return typeof value == 'object';
		}
		
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!_rootNode)
				_rootNode = new ColumnTreeNode({
					cacheSettings: {label: false},
					dataSource: this,
					dependency: dataColumns.childListCallbacks,
					data: this,
					label: getLabel,
					hasChildBranches: false,
					children: function():Array {
						return dataColumns.getNames().map(
							function (columnName:String, ..._):* {
								var meta:Object = {};
								meta[DATA_COLUMNNAME_META] = columnName;
								return generateHierarchyNode(meta);
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

			metadata = getColumnMetadata(metadata[DATA_COLUMNNAME_META]);

			if (!metadata)
				return null;

			return new ColumnTreeNode({
				dataSource: this,
				idFields: [DATA_COLUMNNAME_META],
				data: metadata
			});
		}
		
		private function getColumnMetadata(dataColumnName:String):Object
		{
			var column:IAttributeColumn = dataColumns.getObject(dataColumnName) as IAttributeColumn;
			if (!column)
				return null;

			var metadata:Object = ColumnMetadata.getAllMetadata(column);
			metadata[ColumnMetadata.KEY_TYPE] = groupKeyType.value || groupByColumn.getMetadata(ColumnMetadata.DATA_TYPE);
			metadata[DATA_COLUMNNAME_META] = dataColumnName;
			
			var aggState:Object = aggregationModes.getSessionState();
			var aggregation:String = aggState ? aggState[dataColumnName] : null;
			aggregation = aggregation || Aggregation.DEFAULT;
			metadata[ColumnMetadata.AGGREGATION] = aggregation;
			
			if (aggregation != Aggregation.SAME)
				metadata[ColumnMetadata.TITLE] = Weave.lang("{0} ({1})", metadata[ColumnMetadata.TITLE], aggregation);

			return metadata;
		}
		
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var columnName:String = proxyColumn.getMetadata(DATA_COLUMNNAME_META);
			var metadata:Object = getColumnMetadata(columnName);
			if (!metadata)
			{
				proxyColumn.dataUnavailable();
				return;
			}
			proxyColumn.setMetadata(metadata);
			
			var dataColumn:IAttributeColumn = dataColumns.getObject(columnName) as IAttributeColumn;
			var aggregateColumn:AggregateColumn = proxyColumn.getInternalColumn() as AggregateColumn || new AggregateColumn(this);
			aggregateColumn.setup(metadata, dataColumn, getGroupKeys());

			proxyColumn.setInternalColumn(aggregateColumn);
		}

		private var _groupKeys:Array;
		private function getGroupKeys():Array
		{
			if (Weave.detectChange(getGroupKeys, groupByColumn, groupKeyType))
			{
				_groupKeys = [];
				var stringLookup:Object = {};
				var keyType:String = groupKeyType.value || groupByColumn.getMetadata(ColumnMetadata.DATA_TYPE);
				for each (var key:IQualifiedKey in groupByColumn.keys)
				{
					var localName:String;
					// if the foreign key column is numeric, avoid using the formatted strings as keys
					if (groupByColumn.getMetadata(ColumnMetadata.DATA_TYPE) == DataType.NUMBER)
						localName = groupByColumn.getValueFromKey(key, Number);
					else
						localName = groupByColumn.getValueFromKey(key, String);
					
					if (!stringLookup[localName])
					{
						stringLookup[localName] = true;
						var groupKey:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(keyType, localName);
						_groupKeys.push(groupKey);
					}
				}
			}
			return _groupKeys;
		}
	}
}

import weavejs.WeaveAPI;
import weavejs.api.data.Aggregation;
import weavejs.api.data.ColumnMetadata;
import weavejs.api.data.DataType;
import weavejs.api.data.IAttributeColumn;
import weavejs.api.data.IPrimitiveColumn;
import weavejs.api.data.IQualifiedKey;
import weavejs.core.SessionManager;
import weavejs.data.ColumnUtils;
import weavejs.data.EquationColumnLib;
import weavejs.data.column.AbstractAttributeColumn;
import weavejs.data.column.NumberColumn;
import weavejs.data.column.StringColumn;
import weavejs.data.source.GroupedDataTransform;
import weavejs.util.ArrayUtils;
import weavejs.util.Dictionary2D;
import weavejs.util.StandardLib;

internal class AggregateColumn extends AbstractAttributeColumn implements IPrimitiveColumn
{
	public function AggregateColumn(source:GroupedDataTransform)
	{
		Weave.linkableChild(this, source);
		_groupByColumn = source.groupByColumn;
	}
	
	private var _groupByColumn:IAttributeColumn;
	private var _dataColumn:IAttributeColumn;
	private var _keys:Array;
	private var _cacheTriggerCounter:uint = 0;
	
	public function setup(metadata:Object, dataColumn:IAttributeColumn, keys:Array):void
	{
		if (_dataColumn && _dataColumn != dataColumn)
			(WeaveAPI.SessionManager as SessionManager).unregisterLinkableChild(this, _dataColumn);
		
		_metadata = copyValues(metadata);
		_dataColumn = dataColumn && Weave.linkableChild(this, dataColumn);
		_keys = keys;
		_cacheTriggerCounter = 0;
		triggerCallbacks();
	}
	
	override public function getMetadata(propertyName:String):String
	{
		return super.getMetadata(propertyName)
			|| (_dataColumn ? _dataColumn.getMetadata(propertyName) : null);
	}
	
	override public function getMetadataPropertyNames():Array
	{
		if (_dataColumn)
			return ArrayUtils.union(super.getMetadataPropertyNames(), _dataColumn.getMetadataPropertyNames());
		return super.getMetadataPropertyNames();
	}

	/**
	 * @inheritDoc
	 */
	override public function get keys():Array
	{
		return _keys;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function containsKey(key:IQualifiedKey):Boolean
	{
		return _dataColumn && _dataColumn.containsKey(key);
	}
	
	public function deriveStringFromNumber(value:Number):String
	{
		return ColumnUtils.deriveStringFromNumber(_dataColumn, value);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function getValueFromKey(groupKey:IQualifiedKey, dataType:Class = null):*
	{
		if (triggerCounter != _cacheTriggerCounter)
		{
			_cacheTriggerCounter = triggerCounter;
			dataCache = new Dictionary2D();
		}
		
		if (!dataType)
			dataType = Array;

		var value:* = dataCache.get(dataType, groupKey);

		if (value === undefined)
		{
			value = getAggregateValue(groupKey, dataType);
			dataCache.set(dataType, groupKey, value === undefined ? UNDEFINED : value);
		}
		else if (value === UNDEFINED)
		{
			value = undefined;
		}

		return value;
	}
	
	private static const UNDEFINED:Object = {}; // used as a placeholder for undefined values in dataCache
	
	/**
	 * Computes an aggregated value.
	 * @param groupKey A key that references a String value and is associated with a set of input keys.
	 * @param dataType The dataType parameter passed to the EquationColumn.
	 */
	public function getAggregateValue(groupKey:IQualifiedKey, dataType:Class):*
	{
		if (groupKey.keyType != this.getMetadata(ColumnMetadata.KEY_TYPE))
			return undefined;
		
		if (!dataType)
			dataType = Array;
		
		// get input keys from groupKey
		var tempKeys:Array = EquationColumnLib.getAssociatedKeys(_groupByColumn, groupKey, true);
		var meta_dataType:String = _dataColumn ? _dataColumn.getMetadata(ColumnMetadata.DATA_TYPE) : null;
		var inputType:Class = DataType.getClass(meta_dataType);

		if (dataType === Array)
		{
			// We want a flat Array of values, not a nested Array, so we request the original input type
			// in case they need to be pre-aggregated.
			return getValues(_dataColumn, tempKeys, inputType);
		}
		
		var meta_aggregation:String = this.getMetadata(ColumnMetadata.AGGREGATION) || Aggregation.DEFAULT;
		
		if (inputType === Number || inputType === Date)
		{
			var array:Array = this.getValueFromKey(groupKey, Array) as Array;
			var number:Number = NumberColumn.aggregate(array, meta_aggregation);
			
			if (dataType === Number)
				return number;
			
			if (dataType === Date)
				return new Date(number);
			
			if (dataType === String)
			{
				if (isNaN(number) && array && array.length > 1 && meta_aggregation == Aggregation.SAME)
					return Aggregation.AMBIGUOUS_DATA;
				return ColumnUtils.deriveStringFromNumber(_dataColumn, number)
					|| StandardLib.formatNumber(number);
			}
			
			return undefined;
		}
		
		if (inputType === String)
		{
			// get a list of values of the requested type, then treat them as Strings and aggregate the Strings
			var values:Array = getValues(_dataColumn, tempKeys, dataType);

			var string:String = StringColumn.aggregate(values, meta_aggregation);
			
			if (dataType === Number)
				return StandardLib.asNumber(string);
			
			if (dataType === String)
				return string;
			
			return undefined;
		}
		
		if (meta_dataType === DataType.GEOMETRY)
		{
			if (dataType === String)
				return this.containsKey(groupKey) ? 'Geometry(' + groupKey.keyType + '#' + groupKey.localName + ')' : '';
		}
		
		return undefined;
	}
	
	/**
	 * Gets an Array of values from a column, excluding missing data.
	 * Flattens Arrays.
	 */
	private static function getValues(column:IAttributeColumn, keys:Array, dataType:Class):Array
	{
		var values:Array = [];
		if (!column)
			return values;
		for each (var key:IQualifiedKey in keys)
		{
			if (!column.containsKey(key))
				continue;
			var value:* = column.getValueFromKey(key, dataType);
			if (value is Array)
				values.push.apply(values, value);
			else
				values.push(value);
		}
		return values;
	}
}
