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

package weave.data.ColumnReferences
{
	import flash.utils.getQualifiedClassName;
	
	import weave.core.LinkableXML;
	import weave.api.newLinkableChild;
	import weave.utils.HierarchyUtils;

	/**
	 * This is a temporary solution for Weave 0.8.  This class should be deleted later.
	 * 
	 * @author adufilie
	 */
	/* [Deprecated] */ public class HierarchyColumnReference extends AbstractColumnReference
	{
		public function HierarchyColumnReference()
		{
		}
		
		// path in the IDataSource hierarchy
		public const hierarchyPath:LinkableXML = newLinkableChild(this, LinkableXML, handlePathChange);
		
		/**
		 * This function generates a hash value containing a sorted list of names and values of the
		 * attributes of the leaf XML node in the hierarchyPath.
		 */		
		override public function getHashCode():String
		{
			if (_hash == null)
			{
				var properties:Array = [];
				var attrs:XMLList = HierarchyUtils.getLeafNodeFromPath(hierarchyPath.value || <tag/>).attributes();
				for each (var attr:XML in attrs)
					properties.push(attr.localName() + ': "' + attr.toXMLString() + '"');
				_hash = _hashPrefix + '{' + properties.sort().join(', ') + '}';
			}
			return _hash;
		}
		
		// this function removes unwanted attributes from the path leaf node, and name of hierarchy
		private function handlePathChange():void
		{
			if (hierarchyPath.value && hierarchyPath.value.localName().toString() == 'hierarchy')
				delete hierarchyPath.value["@name"]; // for backwards compatibility
		}
	}
}
