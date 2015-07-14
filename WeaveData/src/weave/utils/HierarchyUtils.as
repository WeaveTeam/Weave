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

package weave.utils
{
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataSource_File;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.data.IWeaveTreeNodeWithPathFinding;

	/**
	 * An all-static class containing functions for dealing with xml hierarchies and xml hierarchy paths.
	 * 
	 * @author adufilie
	 */
	public class HierarchyUtils
	{
		/**
		 * Gets all metadata stored at the leaf node of a hierarchy path.
		 * @return An Object mapping attribute names to values.
		 */
		public static function getMetadata(leafNodeOrPath:XML):Object
		{
			var xml:XML = getNodeFromPath(leafNodeOrPath, leafNodeOrPath);
			var obj:Object = {};
			if (xml)
				for each (var attr:XML in xml.attributes())
					obj[String(attr.name())] = String(attr);
			return obj;
		}
		
		/**
		 * Creates an XML node containing attribute name/value pairs corresponding to the given metadata.
		 */
		public static function nodeFromMetadata(metadata:Object):XML
		{
			var node:XML = <attribute/>;
			for (var key:String in metadata)
				if (metadata[key] != null)
					node['@'+key] = metadata[key];
			return node;
		}
		
		/**
		 * @param hierarchyRoot An XML hierarchy to traverse and compare with the nodes of pathInHierarchy.
		 * @param pathInHierarchy An XML path, starting at the level of the hierarchy root, which will be compared with the hierarchy.
		 * @return The leaf node of the newly added path in the hierarchy.
		 */
		public static function addPathToHierarchy(hierarchyRoot:XML, pathToAdd:XML):XML
		{
			// reject invalid paths
			if (!isValidPath(pathToAdd))
				return null;
			// stop if top-level hierarchy attributes do not match
			if (!nodeNamesMatch(hierarchyRoot, pathToAdd) || !nodeContainsAttributes(hierarchyRoot, pathToAdd.attributes()))
				return null;
			var hierarchyNode:XML = hierarchyRoot;
			while (true)
			{
				var pathChildren:XMLList = pathToAdd.children();
				// if end of path was reached, return the matching node in the hierarchy
				if (pathChildren.length() == 0)
					return hierarchyNode;
				// traverse to next level in path
				pathToAdd = pathChildren[0];
				// find a child of hierarchyNode that matches all the attributes of the current node in pathInHierarchy
				var matchingChild:XML = getFirstNodeContainingAttributes(hierarchyNode.children(), pathToAdd, true);
				// if a matching child was not found, add one and return the newly added leaf node.
				if (matchingChild == null)
				{
					hierarchyNode = hierarchyNode.appendChild(pathToAdd.copy());
					return getNodeFromPath(hierarchyNode, pathToAdd);
				}
				// traverse to the hierarchy node matching the path
				hierarchyNode = matchingChild;
			}
			return hierarchyNode;
		}
		
		/**
		 * @param pathInHierarchy An XML path from a hierarchy.
		 * @param maxDepth The maximum depth to traverse in the path before returning the node.
		 * @return A pointer to the xml node in the path at the given maxDepth, or the leaf node in the path if maxDepth is larger than the depth of the path.
		 */
		public static function getLeafNodeFromPath(pathInHierarchy:XML, maxDepth:int = int.MAX_VALUE):XML
		{
			return getNodeFromPath(pathInHierarchy, pathInHierarchy, maxDepth);
		}
		
		/**
		 * @param hierarchyRoot An XML hierarchy to traverse and compare with the nodes of pathInHierarchy.
		 * @param pathInHierarchy An XML path, starting at the level of the hierarchy root, which will be compared with the hierarchy.
		 * @param maxDepth The maximum depth to traverse in the path before returning the matching node in the hierarchy.
		 * @return A pointer to the xml node in the hierarchy matching the given path, or null if the path was not found in the hierarchy.
		 */
		public static function getNodeFromPath(hierarchyRoot:XML, pathInHierarchy:XML, maxDepth:int = int.MAX_VALUE):XML
		{
			// return null if an invalid parameter is given
			if (hierarchyRoot == null || pathInHierarchy == null)
				return null;
			// stop if top-level hierarchy attributes do not match
			if (!nodeNamesMatch(hierarchyRoot, pathInHierarchy) || !nodeContainsAttributes(hierarchyRoot, pathInHierarchy.attributes()))
			{
				//trace("root does not contain "+pathInHierarchy.toXMLString());
				return null;
			}
			var hierarchyNode:XML = hierarchyRoot;
			var depth:int = 0;
			while (hierarchyNode != null) // stop if matching node is not found
			{
				// if end of path (or maxDepth) was reached or there are multiple children in the
				// requested path, then return the xml from the hierarchy
				if (depth++ >= maxDepth || pathInHierarchy.children().length() == 0)
					break;
				// if there is more than one child node in the path, reject it.
				if (pathInHierarchy.children().length() > 1)
					return null;
				// traverse to next level in path
				pathInHierarchy = pathInHierarchy.children()[0];
				// find a child of hierarchyNode that matches all the attributes of the current node in pathInHierarchy
				hierarchyNode = getFirstNodeContainingAttributes(hierarchyNode.children(), pathInHierarchy, true);
			}
			return hierarchyNode;
		}

		/**
		 * @param hierarchyPointer A pointer to a node in the hierarchy.
		 * @return A new XML object defining the path from the root of the hierarchy to the specified node.
		 */
		public static function getPathFromNode(hierarchyRoot:XML, hierarchyNode:XML):XML
		{
			if (hierarchyNode == null)
				return null;
			var path:XML = hierarchyNode.copy();
			// clear children
			// tip from: http://cookbooks.adobe.com/post_XML_children_removing-16306.html
			path.setChildren(<dummy/>);
			delete path.dummy;
			// start node pointer at specified hierarchyNode and stop when node points to hierarchyRoot
			var node:XML = hierarchyNode;
			while (node != hierarchyRoot && node.parent() != null)
			{
				var parentCopy:XML = node.parent().copy();
				path = parentCopy.setChildren(path);
				node = node.parent();
			}
			return path;
		}
		
		/**
		 * @param pathInHierarchy An XML path in some hierarchy which will be checked for leaf depth.  Any node not having exactly one child will be treated as the end of the path.
		 * @return The depth of the path, 0 meaning the given root node in the path has no children.
		 */
		public static function getPathDepth(pathInHierarchy:XML):int
		{
			var depth:int = 0;
			while (pathInHierarchy != null && pathInHierarchy.children().length() == 1)
			{
				pathInHierarchy = pathInHierarchy.children()[0];
				depth++;
			}
			return depth;
		}

		/**
		 * If any node in an XML object has more than one child, it does not qualify as an "XML path". 
		 * @param pathInHierarchy An XML path in some hierarchy which will be verified.
		 * @return A value of true if all nodes in 'pathInHierarchy' have zero or one child.
		 */
		public static function isValidPath(pathInHierarchy:XML):Boolean
		{
			var children:XMLList;
			var length:int;
			while (pathInHierarchy != null)
			{
				children = pathInHierarchy.children();
				length = children.length();
				if (length == 0)
					return true;
				if (length > 1)
					return false;
				pathInHierarchy = children[0];
			}
			return false;
		}
		
		/**
		 * Checks if two node names match.
		 * @param a First XML node.
		 * @param b Second XML node.
		 * @return true if the node names match.
		 */		
		public static function nodeNamesMatch(a:XML, b:XML):Boolean
		{
			return String(a.name()) == String(b.name());
		}

		/**
		 * @param more An XML node that may contain more attributes than those in 'less'.
		 * @param less An XML node that has attributes to look for in 'more'.
		 * @return true if the all the attributes of 'less' match the corresponding attributes of 'more'.
		 */
		public static function nodeContainsAttributes(more:XML, lessAttrs:XMLList):Boolean
		{
			for each (var lessAttr:XML in lessAttrs)
			{
				var value:String = lessAttr;
				if (value && value != String(more.attribute(lessAttr.name())))
					return false;
			}
			return true;
		}

		/**
		 * @param nodes An XMLList of nodes to search.
		 * @param compareTo An XML node that has attributes to look for in 'nodes'.
		 * @return The first node in 'nodes' that matches all attributes in 'compareTo'.
		 */
		public static function getFirstNodeContainingAttributes(nodes:XMLList, compareTo:XML, matchNodeName:Boolean = true, twoWayCompare:Boolean = true):XML
		{
			var node:XML;
			var compareToAttrs:XMLList = compareTo.attributes();
			// first, check if an node contains all the attributes of compareTo
			for each (node in nodes)
				if (!matchNodeName || nodeNamesMatch(node, compareTo))
					if (nodeContainsAttributes(node, compareToAttrs))
						return node;
			if (twoWayCompare)
			{
				// if no nodes contain all the attributes of compareTo, see if compareTo contains all the attributes of one of the nodes.
				for each (node in nodes)
					if (!matchNodeName || nodeNamesMatch(node, compareTo))
						if (nodeContainsAttributes(compareTo, node.attributes()))
							return node;
			}
			return null;
		}
		
		/**
		 * Finds a node in a hierarchy which corresponds to a foreign node from a foreign hierarchy.
		 * Useful when you saved a node from a previous version of a hierarchy which may have been modified since then.
		 */
		public static function findEquivalentNode(hierarchy:XML, foreignNode:XML):XML
		{
			return getNodeFromPath(hierarchy, getPathFromNode(hierarchy, foreignNode));
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
			
			for each (var child:IWeaveTreeNode in root.getChildren())
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
				for each (var child:IWeaveTreeNode in node.getChildren())
					getAllColumnReferences(child, output);
			return output;
		}
		
		
		/**
		 * For each tag matching tagName, replace attribute names of that tag using the nameMapping.
		 * Example usage: convertOldHierarchyFormat(root, 'attribute', {dataTableName: "dataTable", dataType: myFunction})
		 * @param root The root XML hierachy tag.
		 * @param tagName The name of tags that need to be converted from an old format.
		 * @param nameMapping Maps attribute names to new attribute names or functions that convert the old values, with the following signature:  function(value:String):String
		 */
		public static function convertOldHierarchyFormat(root:XML, tagName:String, nameMapping:Object):void
		{
			if (root == null)
				return;
			
			var node:XML;
			var oldName:String;
			var value:String;
			var nodes:XMLList;
			var nameMap:Object;
			var newName:String;
			var valueConverter:Function;
			
			nodes = root.descendants(tagName);
			for each (node in nodes)
			{
				for (oldName in nameMapping)
				{
					newName = nameMapping[oldName] as String;
					valueConverter = nameMapping[oldName] as Function;
					
					value = node.attribute(oldName);
					if (value) // if there's an old value
					{
						if (valueConverter != null) // if there's a converter
						{
							node.@[oldName] = valueConverter(value); // convert the old value
						}
						else if (!String(node.attribute(newName))) // if there's no value under the newName
						{
							// rename the attribute from oldName to newName
							delete node.@[oldName];
							node.@[newName] = value;
						}
					}
				}
			}
		}
	}
}
