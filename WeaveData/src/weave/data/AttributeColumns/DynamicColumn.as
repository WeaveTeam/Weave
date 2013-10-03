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
	import flash.utils.getQualifiedClassName;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IQualifiedKey;
	import weave.api.reportError;
	import weave.core.ClassUtils;
	import weave.core.LinkableDynamicObject;
	import weave.utils.ColumnUtils;
	
	/**
	 * This provides a wrapper for a dynamically created column.
	 * 
	 * @author adufilie
	 */
	public class DynamicColumn extends LinkableDynamicObject implements IColumnWrapper
	{
		public function DynamicColumn(columnTypeRestriction:Class = null)
		{
			if (columnTypeRestriction == null)
			{
				columnTypeRestriction = IAttributeColumn;
			}
			else
			{
				// make sure the columnTypeRestriction implements IAttributeColumn
				var columnTypeQName:String = getQualifiedClassName(columnTypeRestriction);
				var baseQName:String = getQualifiedClassName(IAttributeColumn);
				if (!ClassUtils.classIs(columnTypeQName, baseQName))
				{
					reportError("DynamicColumn(): columnTypeRestriction does not implement IAttributeColumn: " + columnTypeQName);
					columnTypeRestriction = IAttributeColumn;
				}
			}
			
			super(columnTypeRestriction);
		}
		
		/**
		 * This function lets you skip the step of casting internalObject as an IAttributeColumn.
		 */
		public function getInternalColumn():IAttributeColumn
		{
			return internalObject as IAttributeColumn;
		}
		
		/************************************
		 * Begin IAttributeColumn interface
		 ************************************/

		public function getMetadata(propertyName:String):String
		{
			if (internalObject)
				return (internalObject as IAttributeColumn).getMetadata(propertyName);
			return null;
		}
		
		public function getMetadataPropertyNames():Array
		{
			if (internalObject)
				return (internalObject as IAttributeColumn).getMetadataPropertyNames();
			return [];
		}
		
		/**
		 * @return the keys associated with this column.
		 */
		public function get keys():Array
		{
			return getInternalColumn() ? getInternalColumn().keys : [];
		}
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			if (internalObject)
				return (internalObject as IAttributeColumn).containsKey(key);
			return false;
		}

		/**
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (internalObject)
				return (internalObject as IAttributeColumn).getValueFromKey(key, dataType);
			return undefined;
		}
		
		public function toString():String
		{
			return debugId(this) + '(' + ColumnUtils.getTitle(this) + ')';
		}
	}
}
