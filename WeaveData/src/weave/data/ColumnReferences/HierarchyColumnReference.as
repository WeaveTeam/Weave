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
	import weave.api.newLinkableChild;
	import weave.core.LinkableXML;
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

		/**
		 * This function gets metadata associated with the column.
		 * For standard metadata property names, refer to the AttributeColumnMetadata class.
		 * @param propertyName The name of the metadata property to retrieve.
		 * @result The value of the specified metadata property.
		 */
		override public function getMetadata(propertyName:String):String
		{
			var _metadata:XML = HierarchyUtils.getLeafNodeFromPath(hierarchyPath.value);
			var value:String = null;
			if (_metadata != null && _metadata.attribute(propertyName).length() > 0)
				value = _metadata.attribute(propertyName);
			
			return value;
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
				_hash = _hashPrefix + ';' + dataSourceName.value + '{' + properties.sort().join(', ') + '}';
			}
			return _hash;
		}
		
		private function handlePathChange():void
		{
			if (hierarchyPath.value && String(hierarchyPath.value.localName()) == 'hierarchy')
				delete hierarchyPath.value["@name"]; // for backwards compatibility
			
			var leaf:XML = HierarchyUtils.getLeafNodeFromPath(hierarchyPath.value);
			if (leaf)
			{
				var mapping:Object = {
					dataType: convertOldDataType as Function,
					'projectionSRS': 'projection'
				};
				for (var oldName:String in mapping)
				{
					var value:String = leaf.attribute(oldName);
					if (value)
					{
						delete leaf['@'+oldName];
						if (mapping[oldName] is Function)
							value = (mapping[oldName] as Function).call(null, value);
						var newName:String = mapping[oldName] as String || oldName;
						leaf['@'+newName] = value;
					}
				}
			}
			hierarchyPath.detectChanges();
		}
		private function convertOldDataType(oldValue:String):String
		{
			if (['String','Number','Geometry'].indexOf(oldValue) >= 0)
				return oldValue.toLowerCase();
			return oldValue;
		}
	}
}
