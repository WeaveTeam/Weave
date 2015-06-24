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

package weave.data.Transforms
{
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.ui.ISelectableAttributes;
	import weave.core.LinkableHashMap;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.DataSources.AbstractDataSource;
	import weave.data.KeySets.ColumnDataFilter;
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
				_rootNode = new ColumnTreeNode({
					dataSource: this,
					dependency: partitionColumn,
					label: WeaveAPI.globalHashMap.getName(this),
					hasChildBranches: true,
					children: function(parentNode:ColumnTreeNode):Array {
						var partitionValues:Array = VectorUtils.union(
							partitionColumn.keys.map(
								function(key:IQualifiedKey, ..._):String {
									return partitionColumn.getValueFromKey(key, String);
								}
							)
						);
						return partitionValues.map(
							function(partitionValue:String, ..._):* {
								return {
									dataSource: parentNode.dataSource,
									dependency: inputColumns,
									data: partitionValue,
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
			return _rootNode;
		}

		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			return new ColumnTreeNode({
				dataSource: this,
				idFields: [PARTITION_VALUE_META, PARTITION_COLUMNNAME_META],
				data: metadata
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
			var filter:ColumnDataFilter = filteredColumn.filter.requestLocalObject(ColumnDataFilter, false);

			filter.column.requestLocalObjectCopy(partitionColumn);
			filter.values.setSessionState([filterValue]);
			filteredColumn.internalDynamicColumn.requestLocalObjectCopy(inputColumn);
			
			proxyColumn.setInternalColumn(filteredColumn);
		}
	}
}
