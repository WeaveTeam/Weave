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

package weave.utils
{
	/**
	 * A utility class for determining optimal tick mark values
	 * 
	 * @author curran
	 */
	public class TickMarkUtils
	{
		/**
		 * These are the basis values, multiplied with 10^n, of nice tick marks.
		 */
		private static const niceIntervalBases:Array = [1, 2, 5];
	
		/**
		 * Gets a nice tick mark interval for the given axis specification.
		 * 
		 * @param min
		 *            the minimum value of the axis
		 * @param max
		 *            the maximum value of the axis
		 * @param n
		 *            the approximate number of tick marks desired
		 * @return a nice interval between tick marks.
		 */
		public static function getNiceInterval(min:Number, max:Number, n:Number):Number {
			var span:Number = max - min;
			var interval:Number = span / n;
			var intervalExponent:Number = Math.floor(log10(interval));
			var intervalBase:Number = interval / Math.pow(10, intervalExponent);
	
			var bestIntervalBase:Number = niceIntervalBases[0];
			for (var i:Number = 1; i < niceIntervalBases.length; i++)
				if (Math.abs(intervalBase - niceIntervalBases[i]) < Math
						.abs(intervalBase - bestIntervalBase))
					bestIntervalBase = niceIntervalBases[i];
	
			var bestInterval:Number = bestIntervalBase * Math.pow(10, intervalExponent);
			return bestInterval;
		}
		
		private static function log10(x:Number):Number{
			return Math.log(x)/Math.log(10);
		}
	
		/**
		 * Gets the value which should be used for the first tick mark for the given
		 * minimum value and interval.
		 * 
		 * @param min
		 * @param interval
		 */
		public static function getFirstTickValue(min:Number, interval:Number):Number {
			var v:Number = Math.ceil(min / interval) * interval;
			//silly -0 issue
			if (v == -0)
				v = 0;
			return v;
		}
	
		/**
		 * Gets the next smallest nice interval. For example, an input of 50 will
		 * result in 10, and an input of 1 will result in .5.
		 * 
		 * @param interval
		 *            a nice interval (returned by getNiceInterval())
		 */
		public static function getNextSmallerInterval(interval:Number):Number {
			var intervalExponent:Number = Math.floor(log10(interval));
			var intervalBase:Number = interval / Math.pow(10, intervalExponent);
	
			var closestNiceBase:Number = niceIntervalBases[0];
			var closestNiceBaseIndex:Number = 0;
			for (var i:Number = 1; i < niceIntervalBases.length; i++)
				if (Math.abs(intervalBase - niceIntervalBases[i]) < Math
						.abs(intervalBase - closestNiceBase))
					closestNiceBase = niceIntervalBases[closestNiceBaseIndex = i];
	
			if (closestNiceBase == niceIntervalBases[0])
				return niceIntervalBases[niceIntervalBases.length - 1]
						* Math.pow(10, intervalExponent - 1);
			else
				return niceIntervalBases[closestNiceBaseIndex - 1]
						* Math.pow(10, intervalExponent);
		}
    }
}