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
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IQualifiedKey;
	import weave.api.registerLinkableChild;
	import weave.core.CallbackCollection;
	import weave.core.LinkableDynamicObject;
	import weave.utils.ColumnUtils;
	
	/**
	 * This provides a wrapper for a referenced column.
	 * 
	 * @author adufilie
	 */
	public class ReferencedColumn extends CallbackCollection implements IColumnWrapper
	{
		public function ReferencedColumn()
		{
		}
		
		/**
		 * This is a reference to another column.
		 */
		public const dynamicColumnReference:LinkableDynamicObject = registerLinkableChild(this, new LinkableDynamicObject(IColumnReference), handleReferenceChange);
		
		/**
		 * This is the actual IColumnReference object inside dynamicColumnReference.
		 */
		public function get internalColumnReference():IColumnReference
		{
			return dynamicColumnReference.internalObject as IColumnReference;
		}
		
		/**
		 * This gets called when either the columnReference object changes or the referenced column changes.
		 * This function will remove a callback from the old column and add a callback to the new one.
		 */
		protected function handleReferenceChange():void
		{
			var newColumn:IAttributeColumn = WeaveAPI.AttributeColumnCache.getColumn(internalColumnReference);
			// do nothing if this is the same column
			if (_internalColumn == newColumn)
				return;
			
			if (_internalColumn != null)
				_internalColumn.removeCallback(triggerCallbacks);

			_internalColumn = newColumn;
			
			if (_internalColumn != null)
				_internalColumn.addImmediateCallback(this, triggerCallbacks);
		}
		
		/**
		 * @return The column referenced by the columnReference object.
		 */
		public function get internalColumn():IAttributeColumn
		{
			return _internalColumn;
		}
		/**
		 * the internal referenced column
		 */
		protected var _internalColumn:IAttributeColumn = null;
		

		
		
		
		
		
		
		
		/************************************
		 * Begin IAttributeColumn interface
		 ************************************/

		public function getMetadata(attributeName:String):String
		{
			return _internalColumn ? _internalColumn.getMetadata(attributeName) : null;
		}

		/**
		 * @return the keys associated with this column.
		 */
		public function get keys():Array
		{
			return _internalColumn ? _internalColumn.keys : [];
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			return _internalColumn && _internalColumn.containsKey(key);
		}
		
		/**
		 * getValueFromKey
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_internalColumn != null)
				return _internalColumn.getValueFromKey(key, dataType);
			return undefined;
		}
		
		public function toString():String
		{
			return getQualifiedClassName(this).split("::")[1] + ColumnUtils.getTitle(this);
		}
		
		// backwards compatibility
		[Deprecated(replacement="dynamicColumnReference")] public function get columnReference():ILinkableObject { return dynamicColumnReference; }
	}
}
