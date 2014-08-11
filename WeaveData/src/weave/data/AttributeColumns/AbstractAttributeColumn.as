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

package weave.data.AttributeColumns
{
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.core.CallbackCollection;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.VectorUtils;
	
	/**
	 * This object contains a mapping from keys to data values.
	 * 
	 * @author adufilie
	 * @author abaumann
	 */
	public class AbstractAttributeColumn extends CallbackCollection implements IAttributeColumn
	{
		public function AbstractAttributeColumn(metadata:Object = null)
		{
			if (metadata)
				setMetadata(metadata);
		}
		
		protected var _metadata:Object = null;

		/**
		 * This function should only be called once, before setting the record data.
		 * @param metadata Metadata for this column.
		 */
		public function setMetadata(metadata:Object):void
		{
			if (_metadata !== null)
				throw new Error("Cannot call setMetadata() if already set");
			// make a copy because we don't want any surprises (metadata being set afterwards)
			_metadata = copyValues(metadata);
		}
		
		/**
		 * Copies key/value pairs from an Object or XML attributes.
		 */
		protected static function copyValues(obj_or_xml:Object):Object
		{
			if (obj_or_xml is XML_Class)
				return HierarchyUtils.getMetadata(XML(obj_or_xml));
			
			var obj:Object = {};
			for (var key:String in obj_or_xml)
				obj[key] = obj_or_xml[key];
			return obj;
		}
		
		// metadata for this attributeColumn (statistics, description, unit, etc)
		public function getMetadata(propertyName:String):String
		{
			var value:String = null;
			if (_metadata)
				value = _metadata[propertyName] || null;
			return value;
		}
		
		public function getMetadataPropertyNames():Array
		{
			return VectorUtils.getKeys(_metadata);
		}
		
		// 'abstract' functions, should be defined with override when extending this class

		public /* abstract */ function get keys():Array
		{
			return null;
		}
		
		public /* abstract */ function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			return NaN;
		}
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		public /* abstract */ function containsKey(key:IQualifiedKey):Boolean
		{
			return false;
		}

		public function toString():String
		{
			return debugId(this) + '(' + ColumnUtils.getTitle(this) + ')';
		}
	}
}
