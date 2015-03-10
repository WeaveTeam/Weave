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
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.CallbackCollection;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.data.KeySets.KeySetUnion;
	import weave.utils.ColumnUtils;
	
	/**
	 * This provides a wrapper for a dynamic column, and allows new properties to be added.
	 * The purpose of this class is to provide a base for extending DynamicColumn.
	 * 
	 * @author adufilie
	 */
	public class CombinedColumn extends CallbackCollection implements IAttributeColumn
	{
		public function CombinedColumn()
		{
			registerLinkableChild(this, keySetUnion.busyStatus);
			columns.childListCallbacks.addImmediateCallback(this, handleColumnsList);
		}
		
		public const useFirstColumnMetadata:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		public const columns:ILinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IAttributeColumn));
		private const keySetUnion:KeySetUnion = newLinkableChild(this, KeySetUnion);
		
		private var _columnsArray:Array = [];
		
		private function handleColumnsList():void
		{
			_columnsArray = columns.getObjects();
			if (columns.childListCallbacks.lastObjectAdded)
				keySetUnion.addKeySetDependency(columns.childListCallbacks.lastObjectAdded as IKeySet);
		}
		
		/************************************
		 * Begin IAttributeColumn interface
		 ************************************/

		public function getMetadata(propertyName:String):String
		{
			if (useFirstColumnMetadata.value)
			{
				var firstColumn:IAttributeColumn = _columnsArray[0] as IAttributeColumn;
				return firstColumn ? firstColumn.getMetadata(propertyName) : null;
			}
			return ColumnUtils.getCommonMetadata(_columnsArray, propertyName);
		}

		public function getMetadataPropertyNames():Array
		{
			// TEMPORARY SOLUTION
			var firstColumn:IAttributeColumn = _columnsArray[0] as IAttributeColumn;
			return firstColumn ? firstColumn.getMetadataPropertyNames() : null;
		}
		
		/**
		 * @return the keys associated with this column.
		 */
		public function get keys():Array
		{
			return keySetUnion.keys;
		}
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			return keySetUnion.containsKey(key);
		}

		/**
		 * getValueFromKey
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			for each (var column:IAttributeColumn in _columnsArray)
				if (column.containsKey(key))
					return column.getValueFromKey(key, dataType);
			return dataType == String ? '' : undefined;
		}
		
		public function toString():String
		{
			return debugId(this) + '(' + ColumnUtils.getTitle(this) + ')';
		}
	}
}
