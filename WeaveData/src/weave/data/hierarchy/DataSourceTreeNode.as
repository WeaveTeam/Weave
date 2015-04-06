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
					var equationColumns:Array = root.getObjects(EquationColumn);
					var csvColumns:Array = root.getObjects(CSVColumn);
					var columns:Array = equationColumns.concat(csvColumns);
					if (columns.length)
						nodes.push({
							source: root.childListCallbacks,
							label: function():String {
								return csvColumns.length
									? lang('Generated columns')
									: lang('Equations');
							},
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
