/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.data
{
	/**
	 * This is an interface for getting cached numerical statistics on columns.
	 * 
	 * @author adufilie
	 */
	public interface IStatisticsCache
	{
		/**
		 * @param column A column to get statistics for.
		 * @return The minimum numeric value defined in the column.
		 */
		function getMin(column:IAttributeColumn):Number;
		
		/**
		 * @param column A column to get statistics for.
		 * @return The maximum numeric value defined in the column.
		 */
		function getMax(column:IAttributeColumn):Number;
		
		/**
		 * @param column A column to get statistics for.
		 * @return The count of the records having numeric values defined in the column.
		 */
		function getCount(column:IAttributeColumn):Number;
		
		/**
		 * @param column A column to get statistics for.
		 * @return The sum of all the numeric values defined in the column.
		 */
		function getSum(column:IAttributeColumn):Number;
		
		/**
		 * @param column A column to get statistics for.
		 * @return The sum of the squared numeric values defined in the column.
		 */
		function getSquareSum(column:IAttributeColumn):Number;
		
		/**
		 * @param column A column to get statistics for.
		 * @return The mean value of all the numeric values defined in the column.
		 */
		function getMean(column:IAttributeColumn):Number;
		
		/**
		 * @param column A column to get statistics for.
		 * @return The variance of the numeric values defined in the column.
		 */
		function getVariance(column:IAttributeColumn):Number;
		
		/**
		 * @param column A column to get statistics for.
		 * @return The standard deviation of the numeric values defined in the column.
		 */
		function getStandardDeviation(column:IAttributeColumn):Number;
	}
}
