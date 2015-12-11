/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

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
			super();
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
