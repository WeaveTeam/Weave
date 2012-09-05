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
	import weave.api.core.ILinkableObject;

	/**
	 * This is an interface for getting cached numerical statistics on a column.
	 * 
	 * @author adufilie
	 */
	public interface IColumnStatistics extends ILinkableObject
	{
		//TODO(?): median,range,coefficient of variance,midrange
		
		/**
		 * @param key
		 * @return A number between 0 and 1, or NaN 
		 */		
		function getNorm(key:IQualifiedKey):Number;
		
		/**
		 * @return The minimum numeric value defined in the column.
		 */
		function getMin():Number;
		
		/**
		 * @return The maximum numeric value defined in the column.
		 */
		function getMax():Number;
		
		/**
		 * @return The count of the records having numeric values defined in the column.
		 */
		function getCount():Number;
		
		/**
		 * @return The sum of all the numeric values defined in the column.
		 */
		function getSum():Number;
		
		/**
		 * @return The sum of the squared numeric values defined in the column.
		 */
		function getSquareSum():Number;
		
		/**
		 * @return The mean value of all the numeric values defined in the column.
		 */
		function getMean():Number;
		
		/**
		 * @return The variance of the numeric values defined in the column.
		 */
		function getVariance():Number;
		
		/**
		 * @return The standard deviation of the numeric values defined in the column.
		 */
		function getStandardDeviation():Number;
	}
}
