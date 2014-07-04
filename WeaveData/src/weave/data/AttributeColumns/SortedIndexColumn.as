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
	import flash.utils.Dictionary;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.data.QKeyManager;
	import weave.utils.AsyncSort;
	import weave.utils.VectorUtils;
	
	/**
	 * This column maps a record key to the index in the list of records sorted by numeric value.
	 * 
	 * @author adufilie
	 */
	public class SortedIndexColumn extends DynamicColumn implements IAttributeColumn, IPrimitiveColumn
	{
		/**
		 * This is used to store the sorted list of keys.
		 */
		private var _keys:Array = [];
		/**
		 * This object maps a key to the index of that key in the sorted list of keys.
		 */
		private var _keyToIndexMap:Dictionary = new Dictionary(true);
		private var _column:IAttributeColumn = null;
		private var _triggerCount:uint = 0;
		private var _asyncSort:AsyncSort = newLinkableChild(this, AsyncSort, handleSorted);
		
		private function validate():void
		{
			_keys = super.keys.concat();
			_column = getInternalColumn();
			_asyncSort.beginSort(_keys, sortByNumericValue);
		}
		private function handleSorted():void
		{
			_triggerCount++; // account for _asyncSort trigger
			_keyToIndexMap = VectorUtils.createLookup(_keys);
		}

		/**
		 * This function is used to sort a list of keys.
		 * @param key1 The first key identifying a Number to compare.
		 * @param key2 The second key identifying a Number to compare.
		 * @return The compare result used to sort a list of keys.
		 */
		private function sortByNumericValue(key1:IQualifiedKey, key2:IQualifiedKey):int
		{
			var val1:Number = _column.getValueFromKey(key1, Number);
			var val2:Number = _column.getValueFromKey(key2, Number);
			// if numeric values are equal, compare the keys
			return ObjectUtil.numericCompare(val1, val2)
				|| QKeyManager.keyCompare(key1, key2);
		}
		
		override public function get keys():Array
		{
			if (_triggerCount != triggerCounter)
			{
				_triggerCount = triggerCounter;
				validate();
			}
			return _keys;
		}
		
		/**
		 * @param key A key existing in the internal column.
		 * @param dataType A requested return type.
		 * @return If dataType is not specified, returns the index of the key in the sorted list of keys.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_triggerCount != triggerCounter)
			{
				_triggerCount = triggerCounter;
				validate();
			}
			
			if (dataType == String)
				return _column ? _column.getValueFromKey(key, String) : '';
			
			return _column ? Number(_keyToIndexMap[key]) : undefined;
		}
		
		/**
		 * @param index The index in the sorted keys vector.
		 * @return The key at the given index value.
		 */
		public function deriveStringFromNumber(index:Number):String
		{
			if (_triggerCount != triggerCounter)
			{
				_triggerCount = triggerCounter;
				validate();
			}
			
			index = Math.round(index);
			if (!_column || index < 0 || index >= _keys.length)
				return '';
			return _column.getValueFromKey(_keys[index], String);
		}
	}
}
