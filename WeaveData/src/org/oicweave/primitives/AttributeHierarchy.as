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

package org.oicweave.primitives
{
	import org.oicweave.api.data.IAttributeHierarchy;
	import org.oicweave.core.LinkableXML;
	import org.oicweave.utils.HierarchyUtils;
	
	/**
	 * TODO: Instead of XML, this should be a hierarchy of IColumnReference objects that can be passed to getAttributeColumn().
	 * 
	 * @author adufilie
	 */
	public class AttributeHierarchy extends LinkableXML implements IAttributeHierarchy
	{
		public function AttributeHierarchy()
		{
		}

		/**
		 * getNodeFromPath
		 * @param pathInHierarchy An XML path, starting at the level of the hierarchy root, which will be compared with the hierarchy.
		 * @param maxDepth The maximum depth to traverse in the path before returning the matching node in the hierarchy.
		 * @return A pointer to the xml node in the hierarchy matching the given path.
		 */
		public function getNodeFromPath(pathInHierarchy:XML, maxDepth:int = int.MAX_VALUE):XML
		{
			return HierarchyUtils.getNodeFromPath(value, pathInHierarchy, maxDepth);
		}

		/**
		 * getPathFromNode
		 * @param hierarchyNode A pointer to a node in the hierarchy.
		 * @return A new XML object defining the path from the root of the hierarchy to the specified node.
		 */
		public function getPathFromNode(hierarchyNode:XML):XML
		{
			return HierarchyUtils.getPathFromNode(value, hierarchyNode);
		}
	}
}
