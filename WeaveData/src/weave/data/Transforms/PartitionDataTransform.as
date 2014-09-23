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
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.detectLinkableObjectChange;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.ui.ISelectableAttributes;
	import weave.core.LinkableHashMap;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.DataSources.AbstractDataSource;
	import weave.data.KeySets.StringDataFilter;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.utils.VectorUtils;

	public class PartitionDataTransform extends AbstractDataSource implements ISelectableAttributes
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, PartitionDataTransform, "Partitioned table");

		public static const PARTITION_VALUE_META:String = "__PartitionValue__";
		public static const PARTITION_COLUMNNAME_META:String = "__PartitionColumnName__";
		
		public const inputColumns:ILinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IAttributeColumn));
		public const partitionColumn:DynamicColumn = newLinkableChild(this, DynamicColumn);

		public function PartitionDataTransform()
		{
		}

		public function getSelectableAttributes():Array
		{
			return [partitionColumn, inputColumns];
		}
		public function getSelectableAttributeNames():Array
		{
			return ["Partition by", "Columns to partition"];
		}
		
		override protected function initialize():void
		{
			// recalculate all columns previously requested
			refreshAllProxyColumns();
			
			super.initialize();
		}
		
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!_rootNode)
			{
				var source:PartitionDataTransform = this;
				var partitionValues:Array = [];
				
				_rootNode = new ColumnTreeNode({
					source: source,
					data: source,
					label: WeaveAPI.globalHashMap.getName(this),
					isBranch: true,
					hasChildBranches: true,
					children: function():Array {
						if (detectLinkableObjectChange(_rootNode, partitionColumn))
							partitionValues = VectorUtils.union(
								partitionColumn.keys.map(
									function(key:IQualifiedKey, ..._):String {
										return partitionColumn.getValueFromKey(key, String);
									}
								)
							);
						return partitionValues.map(
							function(partitionValue:String, ..._):* {
								return {
									source: source,
									data: partitionValue,
									isBranch: true,
									hasChildBranches: false,
									children: function():Array {
										return inputColumns.getNames().map(
											function(columnName:String, ..._):* {
												var column:IAttributeColumn = inputColumns.getObject(columnName) as IAttributeColumn;
												if (!column)
													return null;
												var title:String = lang("{0} ({1})", column.getMetadata(ColumnMetadata.TITLE), partitionValue);
												
												var metadata:Object = {};
												metadata[ColumnMetadata.TITLE] = title;
												metadata[PARTITION_VALUE_META] = partitionValue;
												metadata[PARTITION_COLUMNNAME_META] = columnName;
												return generateHierarchyNode(metadata);
											}
										);
									}
								};
							}
						);
					}
				});
			}
			return _rootNode;
		}

		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			return new ColumnTreeNode({
				source: this,
				idFields: [PARTITION_VALUE_META, PARTITION_COLUMNNAME_META],
				columnMetadata: metadata
			});
		}
		
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var filterValue:String = proxyColumn.getMetadata(PARTITION_VALUE_META);
			var columnName:String = proxyColumn.getMetadata(PARTITION_COLUMNNAME_META);
			var inputColumn:IAttributeColumn = inputColumns.getObject(columnName) as IAttributeColumn;
			if (!inputColumn)
			{
				proxyColumn.dataUnavailable();
				return;
			}

			var filteredColumn:FilteredColumn = proxyColumn.getInternalColumn() as FilteredColumn || new FilteredColumn();
			var filter:StringDataFilter = filteredColumn.filter.requestLocalObject(StringDataFilter, false);

			filter.column.requestLocalObjectCopy(partitionColumn);
			filter.stringValue.value = filterValue;
			filteredColumn.internalDynamicColumn.requestLocalObjectCopy(inputColumn);
			
			proxyColumn.setInternalColumn(filteredColumn);
		}
	}
}
