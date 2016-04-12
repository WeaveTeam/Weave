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

package weavejs.data.hierarchy
{
	import weavejs.api.data.IColumnReference;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IDataSource_File;
	import weavejs.api.data.IWeaveTreeNode;
	import weavejs.api.data.IWeaveTreeNodeWithPathFinding;

	/**
	 * An all-static class containing functions for dealing with data hierarchies.
	 * 
	 * @author adufilie
	 */
	public class HierarchyUtils
	{
		public static function findParentNode(root:IWeaveTreeNode, dataSource:IDataSource, metadata:Object):IWeaveTreeNode
		{
			var leaf:IWeaveTreeNode = dataSource.findHierarchyNode(metadata);
			var path:Array = findPathToNode(root, leaf);
			if (path && path.length > 1)
				return path[path.length - 2];
			return null;
		}
		
		public static function findSiblingNodes(dataSource:IDataSource, metadata:Object):Array/*/<IWeaveTreeNode>/*/
		{
			if (!dataSource || !metadata)
				return [];
			
			var parent:IWeaveTreeNode = findParentNode(dataSource.getHierarchyRoot(), dataSource, metadata);
			return parent ? parent.getChildren() : []
		}
		
		/**
		 * Finds a series of IWeaveTreeNode objects which can be traversed as a path to a descendant node.
		 * @param root The root IWeaveTreeNode.
		 * @param descendant The descendant IWeaveTreeNode.
		 * @return An Array of IWeaveTreeNode objects which can be followed as a path from the root to the descendant, including the root and descendant nodes.
		 *         The last item in the path may be the equivalent node found in the hierarchy rather than the descendant node that was passed in.
		 *         Returns null if the descendant is unreachable from this node.
		 * @see weave.api.data.IWeaveTreeNode#equals()
		 */
		public static function findPathToNode(root:IWeaveTreeNode, descendant:IWeaveTreeNode):Array
		{
			if (!root || !descendant)
				return null;
			
			if (root is IWeaveTreeNodeWithPathFinding)
				return (root as IWeaveTreeNodeWithPathFinding).findPathToNode(descendant);
			
			if (root.equals(descendant))
				return [root];
			
			var childs:Array = root.getChildren();
			for each (var child:IWeaveTreeNode in childs)
			{
				var path:Array = findPathToNode(child, descendant);
				if (path)
				{
					path.unshift(root);
					return path;
				}
			}
			
			return null;
		}
		
		/**
		 * Traverses an entire hierarchy and returns all nodes that
		 * implement IColumnReference and have column metadata.
		 */
		public static function getAllColumnReferenceDescendants(source:IDataSource_File):Array
		{
			return getAllColumnReferences(source.getHierarchyRoot(), []);
		}
		private static function getAllColumnReferences(node:IWeaveTreeNode, output:Array):Array
		{
			var ref:IColumnReference = node as IColumnReference;
			if (ref && ref.getColumnMetadata())
				output.push(ref);
			if (node)
			{
				var childs:Array = node.getChildren();
				for each (var child:IWeaveTreeNode in childs)
					getAllColumnReferences(child, output);
			}
			return output;
		}
	}
}
