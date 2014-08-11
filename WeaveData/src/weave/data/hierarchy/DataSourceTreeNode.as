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
package weave.data.hierarchy
{
    import weave.api.core.ILinkableHashMap;
    import weave.api.core.ILinkableObject;
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IAttributeColumn;
    import weave.api.data.IDataSource;
    import weave.api.registerLinkableChild;
    import weave.data.AttributeColumnCache;
    import weave.data.AttributeColumns.CSVColumn;
    import weave.data.AttributeColumns.EquationColumn;

    public class DataSourceTreeNode extends ColumnTreeNode implements ILinkableObject
    {
		public function DataSourceTreeNode()
		{
			var rootNode:DataSourceTreeNode = this;
			var root:ILinkableHashMap = WeaveAPI.globalHashMap;
			registerLinkableChild(this, root.childListCallbacks);
			super({
				source: rootNode,
				label: lang('Data Sources'),
				isBranch: true,
				hasChildBranches: true,
				children: function():Array {
					var nodes:Array = root.getObjects(IDataSource).map(
						function(ds:IDataSource, ..._):* {
							registerLinkableChild(rootNode, ds);
							return ds.getHierarchyRoot();
						}
					);
					var columns:Array = root.getObjects(EquationColumn).concat(root.getObjects(CSVColumn));
					if (columns.length)
						nodes.push({
							source: root.childListCallbacks,
							label: lang("Equations"),
							isBranch: true,
							hasChildBranches: false,
							children: columns.map(
								function(column:IAttributeColumn, ..._):* {
									registerLinkableChild(rootNode, column);
									var meta:Object = {};
									meta[AttributeColumnCache.GLOBAL_COLUMN_METADATA_NAME] = root.getName(column);
									return {
										source: column,
										label: function():String {
											return column.getMetadata(ColumnMetadata.TITLE);
										},
										columnMetadata: meta
									};
								}
							)
						});
					return nodes;
				}
			});
		}
    }
}
