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

package weave.data.Transforms
{
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableVariable;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.detectLinkableObjectChange;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.EquationColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.DataSources.AbstractDataSource;
	import weave.data.KeySets.KeySet;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.utils.ColumnUtils;
	import weave.utils.EquationColumnLib;

	public class GroupedDataTransform extends AbstractDataSource
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, GroupedDataTransform, "Grouped Data Transform");

		public static const DATA_COLUMNNAME_META:String = "__GroupedDataColumnName__";

		public function GroupedDataTransform()
		{

		}

		override protected function initialize():void
		{
			refreshAllProxyColumns();

			super.initialize();
		}

		public const groupByColumn:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const groupKeyType:LinkableString = newLinkableChild(this, LinkableString);
		public const dataColumns:ILinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IAttributeColumn));

		/**
		 * The session state maps a column name in dataColumns hash map to a value for its "aggregation" metadata.
		 */
		public const aggregationModes:ILinkableVariable = registerLinkableChild(this, new LinkableVariable(null, typeofIsObject));
		private function typeofIsObject(value:Object):Boolean
		{
			return typeof value == 'object';
		}
		
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!_rootNode)
			{
				var source:GroupedDataTransform = this;

				_rootNode = new ColumnTreeNode({
					source: source,
					data: source,
					label: WeaveAPI.globalHashMap.getName(this),
					isBranch: true,
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
			}
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
				source: this,
				idFields: [DATA_COLUMNNAME_META],
				columnMetadata: metadata
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
			
			var agg:Object = aggregationModes.getSessionState();
			if (agg && agg[dataColumnName])
				metadata[ColumnMetadata.AGGREGATION] = agg[dataColumnName];

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
			var equationColumn:EquationColumn = proxyColumn.getInternalColumn() as AggregateColumn || new AggregateColumn();
			
			var uniqueValues:KeySet = equationColumn.variables.requestObject("foreignKeys", KeySet, false) as KeySet;

			equationColumn.variables.requestObjectCopy(AggregateColumn.DATA_COLUMN, dataColumn);
			equationColumn.variables.requestObjectCopy(AggregateColumn.GROUP_BY_COLUMN, groupByColumn);
			equationColumn.filterByKeyType.value = true;
			
			uniqueValues.replaceKeys(getGroupKeys());

			equationColumn.metadata.value = metadata;
			equationColumn.equation.value = "this.getAggregateValue(key, dataType)";

			proxyColumn.setInternalColumn(equationColumn);
		}

		private var _groupKeys:Array;
		private function getGroupKeys():Array
		{
			if (detectLinkableObjectChange(getGroupKeys, groupByColumn, groupKeyType))
			{
				_groupKeys = [];
				var stringLookup:Object = {};
				var keyType:String = groupKeyType.value || groupByColumn.getMetadata(ColumnMetadata.DATA_TYPE);
				for each (var key:IQualifiedKey in groupByColumn.keys)
				{
					var localName:String = groupByColumn.getValueFromKey(key, String);
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

import weave.api.data.ColumnMetadata;
import weave.api.data.DataType;
import weave.api.data.IAttributeColumn;
import weave.api.data.IQualifiedKey;
import weave.compiler.StandardLib;
import weave.data.AttributeColumns.EquationColumn;
import weave.data.AttributeColumns.NumberColumn;
import weave.data.AttributeColumns.StringColumn;
import weave.utils.ColumnUtils;
import weave.utils.EquationColumnLib;

internal class AggregateColumn extends EquationColumn
{
	public static const GROUP_BY_COLUMN:String = 'dataColumn';
	public static const DATA_COLUMN:String = 'groupByColumn';
	
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
		var groupByColumn:IAttributeColumn = this.variables.getObject(GROUP_BY_COLUMN) as IAttributeColumn;
		var keys:Array = EquationColumnLib.getAssociatedKeys(groupByColumn, groupKey, true);
		
		var dataColumn:IAttributeColumn = this.variables.getObject(DATA_COLUMN) as IAttributeColumn;
		var meta_dataType:String = dataColumn.getMetadata(ColumnMetadata.DATA_TYPE);
		var inputType:Class = DataType.getClass(meta_dataType);

		if (dataType === Array)
		{
			// We want a flat Array of values, not a nested Array, so we request the original input type
			// in case they need to be pre-aggregated.
			return getValues(dataColumn, keys, inputType);
		}
		
		var meta_aggregation:String = this.getMetadata(ColumnMetadata.AGGREGATION);
		
		if (inputType === Number || inputType === Date)
		{
			var number:Number = NumberColumn.aggregate(this.getValueFromKey(groupKey, Array), meta_aggregation);
			
			if (dataType === Number)
				return number;
			
			if (dataType === Date)
				return new Date(number);
			
			if (dataType === String)
				return ColumnUtils.deriveStringFromNumber(dataColumn, number)
					|| StandardLib.formatNumber(number);
			
			return undefined;
		}
		
		if (inputType === String)
		{
			// get a list of values of the requested type, then treat them as Strings and aggregate the Strings
			var values:Array = getValues(dataColumn, keys, dataType);
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
