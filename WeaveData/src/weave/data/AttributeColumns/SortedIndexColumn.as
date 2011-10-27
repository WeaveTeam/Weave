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
	import weave.utils.VectorUtils;
	
	/**
	 * This column maps a record key to the index in the list of records sorted by numeric value.
	 * 
	 * @author adufilie
	 */
	public class SortedIndexColumn extends DynamicColumn implements IAttributeColumn, IPrimitiveColumn
	{
		public function SortedIndexColumn()
		{
			super();
			addImmediateCallback(this, invalidateLookup);
		}

		private function invalidateLookup():void
		{
			// invalidate lookup
			_keyToIndexMap = null;
			// TODO: set unit?
		}

		/**
		 * This object maps a key to the index of that key in the sorted list of keys.
		 */
		private var _keyToIndexMap:Dictionary = null;
		
		/**
		 * This is used to store the sorted list of keys.
		 */
		private const _keys:Array = new Array();

		/**
		 * This function returns the unique strings of the internal column.
		 * @return The keys this column defines values for.
		 */
		override public function get keys():Array
		{
			// validate lookup table if necessary
			if (_keyToIndexMap == null)
				createLookupTable();
			return _keys;
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return _keyToIndexMap[key] != undefined;
		}
		
		/**
		 * This function will sort the keys and create the keyToIndexMap mapping the keys to their sorted index values.
		 */
		private function createLookupTable():void
		{
			// get the keys from the internal column
			var keys:Array = internalColumn ? internalColumn.keys : [];
			// make a copy of the list of keys
			VectorUtils.copy(keys, _keys);
			// sort the keys based on the numeric values associated with them
			_keys.sort(sortByNumericValue);
			// update the lookup table
			_keyToIndexMap = new Dictionary();
			var i:int = _keys.length;
			while (--i > -1)
				_keyToIndexMap[_keys[i]] = i;
		}

		/**
		 * This function is used to sort a list of keys.
		 * @param key1 The first key identifying a Number to compare.
		 * @param key2 The second key identifying a Number to compare.
		 * @return The compare result used to sort a list of keys.
		 */
		private function sortByNumericValue(key1:IQualifiedKey, key2:IQualifiedKey):int
		{
			var val1:Number = internalColumn.getValueFromKey(key1, Number);
			var val2:Number = internalColumn.getValueFromKey(key2, Number);
			// if numeric values are equal, compare the keys
			return ObjectUtil.numericCompare(val1, val2) || ObjectUtil.compare(key1, key2);
		}
		
		/**
		 * @param key A key existing in the internal column.
		 * @param dataType A requested return type.
		 * @return If dataType is not specified, returns the index of the key in the sorted list of keys.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			var result:*;
			if (internalColumn != null)
			{
				// validate lookup table if necessary
				if (_keyToIndexMap == null)
					createLookupTable();
				// get the list of internal keys from the given stringValue
				result = Number(_keyToIndexMap[key]);
			}
			else
			{
				result = NaN;
			}
			// cast to other types
			if (dataType == String)
				result = internalColumn ? internalColumn.getValueFromKey(key, String) : '';
			else if (dataType == Boolean)
				result = !isNaN(result); // true if key exists in lookup table
			
			return result;
		}
		
		/**
		 * @param index The index in the sorted keys vector.
		 * @return The key at the given index value.
		 */
		public function deriveStringFromNumber(index:Number):String
		{
			// validate lookup table if necessary
			if (_keyToIndexMap == null)
				createLookupTable();
			// return the key at the given number as an index
			index = Math.round(index);
			// return '' if there is no key at the given index value
			if (index < 0 || index >= _keys.length)
				return '';
			return internalColumn ? internalColumn.getValueFromKey(_keys[index], String) : '';
		}
	}
}
