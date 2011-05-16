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
	import mx.utils.ObjectUtil;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.utils.VectorUtils;
	
	/**
	 * This is a wrapper for another column that provides sorted keys.
	 * 
	 * @author adufilie
	 */
	public class SortedColumn extends ExtendedDynamicColumn implements IAttributeColumn
	{
		public function SortedColumn()
		{
			super();
			ascending.value = true;
			addImmediateCallback(this, invalidateKeys);
		}

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
			validateKeys();
			return _keys;
		}
		
		/**
		 * This is an option to sort the column in ascending or descending order.
		 */
		public const ascending:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		
		/**
		 * This function will invalidate the sorted keys.
		 */
		private function invalidateKeys():void
		{
			// invalidate keys
			_keys.length = 0;
		}

		/**
		 * This function will, if necessary, sort the keys based on the numeric value of the internal column.
		 */
		private function validateKeys():void
		{
			if (_keys.length == 0)
			{
				// get the keys from the internal column
				var keys:Array = internalColumn ? internalColumn.keys : [];
				// make a copy of the list of keys
				VectorUtils.copy(keys, _keys);
				// set sort mode
				_sortAscending = ascending.value;
				// sort the keys based on the numeric values associated with them
				_keys.sort(sortByNumericValue);
			}
		}

		/**
		 * This variable is used to tell the sortByNumericValue() function how to sort.
		 */
		private var _sortAscending:Boolean = true;
		
		/**
		 * This function is used to sort a list of keys.
		 * @param key1 The first key identifying a Number to compare.
		 * @param key2 The second key identifying a Number to compare.
		 * @return The compare result used to sort a list of keys.
		 */
		private function sortByNumericValue(firstKey:IQualifiedKey, secondKey:IQualifiedKey):int
		{
			var key1:IQualifiedKey = _sortAscending ? firstKey : secondKey;
			var key2:IQualifiedKey = _sortAscending ? secondKey : firstKey;
			
			var column:IAttributeColumn = internalDynamicColumn.internalColumn;
			
			var val1:Number = column ? column.getValueFromKey(key1, Number) as Number : NaN;
			var val2:Number = column ? column.getValueFromKey(key2, Number) as Number : NaN;
			// if numeric values are equal, compare the keys
			return ObjectUtil.numericCompare(val1, val2) || ObjectUtil.compare(key1, key2);
		}
	}
}
