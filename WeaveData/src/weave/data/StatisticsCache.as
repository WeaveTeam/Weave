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

package weave.data
{
	import flash.utils.Dictionary;
	
	import weave.api.objectWasDisposed;
	import weave.api.registerDisposableChild;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IStatisticsCache;
	import weave.primitives.WeakMap;
	
	/**
	 * This is an all-static class containing numerical statistics on columns and functions to access the statistics.
	 * 
	 * @author adufilie
	 */
	public class StatisticsCache implements IStatisticsCache
	{
		/**
		 * @param column A column to get statistics for.
		 * @return A Dictionary that maps a IQualifiedKey to a running total numeric value, based on the order of the keys in the column.
		 */
		public function getRunningTotals(column:IAttributeColumn):Dictionary
		{
			return (getColumnStatistics(column) as ColumnStatistics).getRunningTotals();
		}

		private var map_column_stats:WeakMap = new WeakMap();
		
		public function getColumnStatistics(column:IAttributeColumn):IColumnStatistics
		{
			if (column == null)
				throw new Error("getColumnStatistics(): Column parameter cannot be null.");
			
			if (objectWasDisposed(column))
			{
				map_column_stats.remove(column);
				throw new Error("Invalid attempt to retrieve statistics for a disposed column.");
			}

			var stats:IColumnStatistics = map_column_stats.get(column);
			if (!stats)
			{
				stats = new ColumnStatistics(column);
				
				// when the column is disposed, the stats should be disposed
				map_column_stats.set(column, registerDisposableChild(column, stats));
			}
			return stats;
		}
	}
}
