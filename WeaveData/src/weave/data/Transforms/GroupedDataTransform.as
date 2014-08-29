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
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataSource;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;

	import weave.api.detectLinkableObjectChange;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableVariable;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.EquationColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.KeySets.KeySet;
	import weave.data.DataSources.AbstractDataSource;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.utils.ColumnUtils;
	import weave.utils.EquationColumnLib;
	import weave.utils.VectorUtils;

	public class GroupedDataTransform extends AbstractDataSource
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, GroupedDataTransform, "Grouped Data Transform");

		public static const DATA_COLUMNNAME_META:String = "__GroupedDataColumnName__";

		public var _cachedUniqueValues:Array;

		public const groupByColumn:DynamicColumn = newLinkableChild(this, DynamicColumn, updateUniqueValues);

		public const userKeyType:LinkableString = newLinkableChild(this, LinkableString, updateUniqueValues);
		public const aggregationType:LinkableString = newLinkableChild(this, LinkableString);

		public const dataColumns:ILinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IAttributeColumn));

		public const metadataOverlay:ILinkableHashMap = registerLinkableChild(this, new LinkableHashMap(ILinkableVariable));

		public function GroupedDataTransform()
		{

		}

		public function updateUniqueValues()
		{
			var values:Array = groupByColumn.keys.map(function(key:IQualifiedKey, ..._):String
				{ return groupByColumn.getValueFromKey(key, String);});

			var keyType:String = userKeyType.value ? userKeyType.value : groupByColumn.getMetadata(ColumnMetadata.DATA_TYPE);

			_cachedUniqueValues = VectorUtils.union(values).map(

				function(s:String, ..._):IQualifiedKey
				{
					return WeaveAPI.QKeyManager.getQKey(keyType, s);
				}
			);



			return;
		}

		override protected function initialize():void
		{
			refreshAllProxyColumns();

			super.initialize();
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
					hasChildBranches: true,
					children: function():Array {
						return dataColumns.getNames().map(
							function (columnName:String, ..._):* {
								var column:IAttributeColumn = dataColumns.getObject(columnName) as IAttributeColumn;
								if (!column) return null;
								var metadata:Object = ColumnMetadata.getAllMetadata(column);
								metadata[DATA_COLUMNNAME_META] = columnName;
								return generateHierarchyNode(metadata);
							}
							)
					}
					})
			}
			return _rootNode;
		}

		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata) return null;

			metadata = getColumnMetadata(metadata[DATA_COLUMNNAME_META]);

			if (!metadata) return null;

			return new ColumnTreeNode({
				source: this,
				idFields: [DATA_COLUMNNAME_META],
				columnMetadata: metadata
			});
		}
		private function getColumnMetadata(dataColumnName:String):Object
		{
			var column:IAttributeColumn = dataColumns.getObject(dataColumnName) as IAttributeColumn;

			if (!column) return null;

			var metadata:Object = ColumnMetadata.getAllMetadata(column);

			metadata[ColumnMetadata.KEY_TYPE] = userKeyType.value ? userKeyType.value : groupByColumn.getMetadata(ColumnMetadata.DATA_TYPE);
			metadata[DATA_COLUMNNAME_META] = dataColumnName;

			return metadata;
		}

		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var metadata:Object = proxyColumn.getProxyMetadata();

			var columnName:String = metadata[DATA_COLUMNNAME_META];

			if (!metadata)
			{
				proxyColumn.dataUnavailable();
				return;
			}

			var dataColumn:IAttributeColumn = dataColumns.getObject(columnName) as IAttributeColumn;
			var equationColumn:EquationColumn = proxyColumn.getInternalColumn() as EquationColumn || new EquationColumn();
			var uniqueValues:KeySet = equationColumn.variables.requestObject("foreignKeys", KeySet, false) as KeySet;

			equationColumn.variables.requestObjectCopy("dataColumn", dataColumn);
			equationColumn.variables.requestObjectCopy("groupByColumn", groupByColumn);
			equationColumn.filterByKeyType.value = true;
			
			uniqueValues.replaceKeys(_cachedUniqueValues);

			equationColumn.metadata.value = metadata;
			equationColumn.equation.value = "\
				function(key, dataType) {\
					import \"weave.api.data.ColumnMetadata\";\
					import \"weave.data.AttributeColumns.NumberColumn\";\
					var metadata = ColumnMetadata.getAllMetadata(this);\
					var associatedKeys = getAssociatedKeys(groupByColumn, key, true);\
					var values = associatedKeys.map(k => dataColumn.getValueFromKey(k));\
					if (dataType === String) return String(values);\
					return NumberColumn.aggregate(values, metadata);\
				}"

			proxyColumn.setInternalColumn(equationColumn);
		}
	}
}