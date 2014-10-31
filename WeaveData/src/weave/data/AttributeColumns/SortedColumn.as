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
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.data.KeySets.SortedKeySet;
	
	/**
	 * This is a wrapper for another column that provides sorted keys.
	 * 
	 * @author adufilie
	 */
	public class SortedColumn extends ExtendedDynamicColumn implements IAttributeColumn
	{
		public function SortedColumn()
		{
			registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(internalDynamicColumn));
			sortCopyAscending = SortedKeySet.generateSortCopyFunction([internalDynamicColumn], [1]);
			sortCopyDescending = SortedKeySet.generateSortCopyFunction([internalDynamicColumn], [-1]);
		}
		
		/**
		 * This is an option to sort the column in ascending or descending order.
		 */
		public const ascending:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));

		private var _keys:Array = [];
		private var _prevTriggerCounter:uint = 0;
		private var sortCopyAscending:Function;
		private var sortCopyDescending:Function;

		/**
		 * This function returns the unique strings of the internal column.
		 * @return The keys this column defines values for.
		 */
		override public function get keys():Array
		{
			if (_prevTriggerCounter != triggerCounter)
			{
				if (ascending.value)
					_keys = sortCopyAscending(super.keys);
				else
					_keys = sortCopyDescending(super.keys);
				_prevTriggerCounter = triggerCounter;
			}
			return _keys;
		}
	}
}
