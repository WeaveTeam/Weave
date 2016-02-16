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

package weavejs.api.data
{
	/**
	 * Constants associated with different aggregation methods.
	 * @see weave.api.data.ColumnMetadata
	 */
	public class Aggregation
	{
		public static const ALL_TYPES:Array/*/string/*/ = [SAME, FIRST, LAST, MEAN, SUM, MIN, MAX, COUNT];
		
		public static const SAME:String = "same";
		public static const FIRST:String = "first";
		public static const LAST:String = "last";
		
		public static const MEAN:String = "mean";
		public static const SUM:String = "sum";
		public static const MIN:String = "min";
		public static const MAX:String = "max";
		public static const COUNT:String = "count";
		
		/**
		 * The default aggregation mode.
		 */
		public static const DEFAULT:String = SAME;
		
		/**
		 * The string displayed when data for a record is ambiguous.
		 */
		public static const AMBIGUOUS_DATA:String = "Ambiguous data";
		
		/**
		 * Maps an aggregation method to a short description of its behavior.
		 */
		public static const HELP:Object = {
			'same': 'Keep the value only if it is the same for each record in the group.',
			'first': 'Use the first of a group of values.',
			'last': 'Use the last of a group of values.',
			'mean': 'Calculate the mean (average) from a group of numeric values.',
			'sum': 'Calculate the sum (total) from a group of numeric values.',
			'min': 'Use the minimum of a group of numeric values.',
			'max': 'Use the maximum of a group of numeric values.',
			'count': 'Count the number of values in a group.'
		};
	}
}
