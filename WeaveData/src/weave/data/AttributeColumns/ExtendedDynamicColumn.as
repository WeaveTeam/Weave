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
	
	import mx.utils.NameUtil;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.core.CallbackCollection;
	import weave.utils.ColumnUtils;
	
	/**
	 * This provides a wrapper for a dynamic column, and allows new properties to be added.
	 * The purpose of this class is to provide a base for extending DynamicColumn.
	 * 
	 * @author adufilie
	 */
	public class ExtendedDynamicColumn extends CallbackCollection implements IColumnWrapper
	{
		public function ExtendedDynamicColumn()
		{
		}
		
		/**
		 * This is for the IColumnWrapper interface.
		 */
		public function getInternalColumn():IAttributeColumn
		{
			return internalDynamicColumn.getInternalColumn();
		}
		
		/**
		 * This is the internal DynamicColumn object that is being extended.
		 */
		public function get internalDynamicColumn():DynamicColumn
		{
			return _internalDynamicColumn;
		}
		private const _internalDynamicColumn:DynamicColumn = newLinkableChild(this, DynamicColumn);
		
		private var name:String = NameUtil.createUniqueName(this);
		
		/************************************
		 * Begin IAttributeColumn interface
		 ************************************/

		public function getMetadata(propertyName:String):String
		{
			return internalDynamicColumn.getMetadata(propertyName);
		}

		/**
		 * @return the keys associated with this column.
		 */
		public function get keys():Array
		{
			return internalDynamicColumn.keys;
		}
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			return internalDynamicColumn.containsKey(key);
		}

		/**
		 * getValueFromKey
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			return internalDynamicColumn.getValueFromKey(key, dataType);
		}
		
		public function toString():String
		{
			return getQualifiedClassName(this).split("::")[1] + ColumnUtils.getTitle(this);
		}
	}
}
