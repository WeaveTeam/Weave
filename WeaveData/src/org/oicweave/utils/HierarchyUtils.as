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

package org.oicweave.utils
{
	/**
	 * HierarchyUtils
	 * An all-static class containing functions for dealing with xml hierarchies and xml hierarchy paths.
	 * 
	 * @author adufilie
	 */
	public class HierarchyUtils
	{
		/**
		 * addPathToHierarchy
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
			if (!nodeContainsAttributes(hierarchyRoot, pathToAdd, true))
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
		 * getNodeFromPath
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
			if (!nodeContainsAttributes(hierarchyRoot, pathInHierarchy, true))
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
		 * getPathFromNode
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
		 * getPathDepth
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
		 * isValidPath
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
		 * nodeContainsAttributes
		 * @param more An XML node that may contain more attributes than those in 'less'.
		 * @param less An XML node that has attributes to look for in 'more'.
		 * @return true if the all the attributes of 'less' match the corresponding attributes of 'more'.
		 */
		public static function nodeContainsAttributes(more:XML, less:XML, matchNodeName:Boolean = true):Boolean
		{
			var moreName:String = more.name();
			var lessName:String = less.name();
			if (matchNodeName && moreName != lessName)
				return false;
			var moreAttrs:XMLList = more.attributes();
			var lessAttrs:XMLList = less.attributes();
			for (var iLess:int = 0; iLess < lessAttrs.length(); iLess++)
			{
				var lessAttr:XML = lessAttrs[iLess] as XML;
				lessName = lessAttr.name();
				// skip attributes with empty strings
				if (lessAttr.toXMLString() == '')
					continue;
				
				var found:Boolean = false;
				for (var iMore:int = 0; iMore < moreAttrs.length(); iMore++)
				{
					var moreAttr:XML = moreAttrs[iMore] as XML;
					moreName = moreAttr.name();
					
					if (moreName == lessName)
					{
						// if name and value are equal, we found the attr
						if (moreAttr.contains(lessAttr))
						{
							found = true;
							break;
						}
						// return false if name is equal but value is different
						return false;
					}
				}
				if (!found)
					return false;
			}
			return true;
		}

		/**
		 * getFirstNodeContainingAttributes
		 * @param nodes An XMLList of nodes to search.
		 * @param compareTo An XML node that has attributes to look for in 'nodes'.
		 * @return The first node in 'nodes' that matches all attributes in 'compareTo'.
		 */
		public static function getFirstNodeContainingAttributes(nodes:XMLList, compareTo:XML, matchNodeName:Boolean = true):XML
		{
			var i:int;
			var length:int = nodes.length();
			// first, check if an node contains all the attributes of compareTo
			for (i = 0; i < length; i++)
				if (nodeContainsAttributes(nodes[i], compareTo, matchNodeName))
					return nodes[i];
			// if no nodes contain all the attributes of compareTo, see if compareTo contains all the attributes of one of the nodes.
			for (i = 0; i < length; i++)
				if (nodeContainsAttributes(compareTo, nodes[i], matchNodeName))
					return nodes[i];
			return null;
		}
		
//		/**
//		 * getCascadedAttribute
//		 * @param hierarchyNode A node in an xml hierarchy.
//		 * @param attributeName The name of the attribute to get.
//		 * @return The attribute value from hierarchyNode or from the first ancestor of hierarchyNode the attribute is defined for.
//		 */
//		public static function getCascadedAttribute(hierarchyNode:XML, attributeName:String):String
//		{
//			var attributeValue:String;
//			var node:XML = hierarchyNode;
//			while (node != null)
//			{
//				attributeValue = node.attribute(attributeName).toString();
//				if (attributeValue != "")
//					return attributeValue;
//				node = node.parent();
//			}
//			return "";
//		}
		
		private static function trace(...args):void
		{
			DebugUtils.debug_trace(HierarchyUtils, args);
		}
	}
}
