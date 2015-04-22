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
    import weave.api.data.IDataSource;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.registerLinkableChild;
    import weave.data.AttributeColumnCache;

    public class DataSourceTreeNode extends WeaveTreeDescriptorNode implements ILinkableObject
    {
		public function DataSourceTreeNode()
		{
			var rootNode:DataSourceTreeNode = this;
			var root:ILinkableHashMap = WeaveAPI.globalHashMap;
			registerLinkableChild(this, root.childListCallbacks);
			
			super({
				dependency: rootNode,
				label: lang('Data Sources'),
				hasChildBranches: true,
				children: function():Array {
					var sources:Array = root.getObjects(IDataSource).concat(AttributeColumnCache.globalColumnDataSource);
					var nodes:Array = sources.map(
						function(ds:IDataSource, ..._):* {
							registerLinkableChild(rootNode, ds);
							return ds.getHierarchyRoot();
						}
					);
					
					// only show global columns node if it has at least one child
					var globalColumnsNode:IWeaveTreeNode = nodes[nodes.length - 1];
					if (!globalColumnsNode.getChildren().length)
						nodes.pop();
					
					return nodes;
				}
			});
		}
    }
}
