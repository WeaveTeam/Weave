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

package weave.data
{
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IStatisticsCache;
	import weave.compiler.StandardLib;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.ReferencedColumn;
	
	/**
	 * This is an all-static class containing numerical statistics on columns and functions to access the statistics.
	 * 
	 * @author adufilie
	 */
	public class StatisticsCache implements IStatisticsCache
	{
		public static function get instance():StatisticsCache
		{
			return WeaveAPI.StatisticsCache as StatisticsCache;
		}
		
		//TODO(?): median,range,coefficient of variance,midrange

		public function StatisticsCache():void
		{
			// Make sure each function gets a Dictionary for cached values.
			// Each Dictionary should use weak keys so old columns don't hang around just to be listed in the cache.
			var functions:Array = [
				getMin,
				getMax,
				getCount,
				getMean,
				getSum,
				getSquareSum,
				getVariance,
				getStandardDeviation,
				getRunningTotals
			];
			for each (var func:Function in functions)
				cache[func] = new Dictionary(true);
		}
		
		/**
		 * @param column A column to get statistics for.
		 * @return The minimum numeric value defined in the column.
		 */
		public function getMin(column:IAttributeColumn):Number
		{
			return validateCache(column, getMin);
		}
		
		/**
		 * @param column A column to get statistics for.
		 * @return The maximum numeric value defined in the column.
		 */
		public function getMax(column:IAttributeColumn):Number
		{
			return validateCache(column, getMax);
		}
		
		/**
		 * @param column A column to get statistics for.
		 * @return The count of the records having numeric values defined in the column.
		 */
		public function getCount(column:IAttributeColumn):Number
		{
			return validateCache(column, getCount);
		}
		
		/**
		 * @param column A column to get statistics for.
		 * @return The sum of all the numeric values defined in the column.
		 */
		public function getSum(column:IAttributeColumn):Number
		{
			return validateCache(column, getSum);
		}
		
		/**
		 * @param column A column to get statistics for.
		 * @return The sum of the squared numeric values defined in the column.
		 */
		public function getSquareSum(column:IAttributeColumn):Number
		{
			return validateCache(column, getSquareSum);
		}
		
		/**
		 * @param column A column to get statistics for.
		 * @return The mean value of all the numeric values defined in the column.
		 */
		public function getMean(column:IAttributeColumn):Number
		{
			return validateCache(column, getMean);
		}
		
		/**
		 * @param column A column to get statistics for.
		 * @return The variance of the numeric values defined in the column.
		 */
		public function getVariance(column:IAttributeColumn):Number
		{
			return validateCache(column, getVariance);
		}
		
		/**
		 * @param column A column to get statistics for.
		 * @return The standard deviation of the numeric values defined in the column.
		 */
		public function getStandardDeviation(column:IAttributeColumn):Number
		{
			return validateCache(column, getStandardDeviation);
		}
		
		/**
		 * @param column A column to get statistics for.
		 * @return A Dictionary that maps a IQualifiedKey to a running total numeric value, based on the order of the keys in the column.
		 */
		public function getRunningTotals(column:IAttributeColumn):Dictionary
		{
			return validateCache(column, getRunningTotals);
		}

		/**
		 * This maps a static function of StatisticsRepository to a Dictionary
		 * mapping an IAttributeColumn to a cached value for the function.
		 * Example: cache[getMin][column] is a cached value for the getMin function called for the given column.
		 */
		private const cache:Dictionary = new Dictionary();

		/**
		 * This maps an IAttributeColumn to a value of true or false, indicating
		 * whether or not the cached values are valid for that column.
		 */
		private const cacheIsValid:Dictionary = new Dictionary(true);

		/**
		 * This function will invalidate any cached statistical values associated with the given column.
		 * @param column A column to invalidate statistics for.
		 */
		private function invalidateCache(column:IAttributeColumn):void
		{
			cacheIsValid[column] = false;
		}
		
		/**
		 * This function will validate the cached statistical values for the given column.
		 * @param column A column to calculate basic statistical values for.
		 * @param statsFunction The function we are interested in calling.
		 * @return The cached result of the statsFunction for the given column.
		 */
		private function validateCache(column:IAttributeColumn, statsFunction:Function):*
		{
			//---
			// special case for column wrappers that do not alter the data in any way
			var wrapperTypes:Array = [DynamicColumn,ReferencedColumn];
			var foundWrapper:Boolean = false;
			do {
				foundWrapper = false;
				for each (var wrapperType:Class in wrapperTypes)
				{
					if (column is wrapperType && getQualifiedClassName(column) == getQualifiedClassName(wrapperType))
					{
						column = (column as IColumnWrapper).internalColumn;
						foundWrapper = true;
					}
				}
			} while (foundWrapper);
			//---
			
			if (column == null)
				return NaN;

			// if the cacheIsValid dictionary has no entry for this column,
			// add a callback to the column that will invalidate the cache
			if (cacheIsValid[column] === undefined)
				column.addImmediateCallback(column, invalidateCache, [column], true);
			
			// if cache is invalid, validate it now.  if callbacks are running, cache is invalid.
			if (!cacheIsValid[column] || column.callbacksWereTriggered)
			{
				var min:Number = NaN;
				var max:Number = NaN;
				var count:Number = 0;
				var sum:Number = 0;
				var squareSum:Number = 0;
				var runningTotals:Dictionary = new Dictionary();
				var value:Number;
				
				// loop through the keys for the key type associated with the column, and calculate statistics
				var keys:Array = column.keys;
				for (var i:int = 0; i < keys.length; i++)
				{
					var key:IQualifiedKey = keys[i];
					value = column.getValueFromKey(key, Number);
					// skip keys that do not have an associated numeric value in the column.
					if (isNaN(value) || value == Infinity || value == -Infinity)
						continue;

					count++;
					sum += value;
					runningTotals[key] = sum;
					squareSum += value * value;
					
					if (isNaN(min) || value < min)
						min = value;
					if (isNaN(max) || value > max)
						max = value;
				}
				
				var mean:Number = sum / count;
				var variance:Number = squareSum / count - mean * mean;
				var standardDeviation:Number = Math.sqrt(variance);

				// BEGIN code to get custom min,max
				var tempNumber:Number;
				try {
					tempNumber = StandardLib.asNumber(column.getMetadata(AttributeColumnMetadata.MIN));
					if (!isNaN(tempNumber))
						min = tempNumber;
				} catch (e:Error) { }
				try {
					tempNumber = StandardLib.asNumber(column.getMetadata(AttributeColumnMetadata.MAX));
					if (!isNaN(tempNumber))
						max = tempNumber;
				} catch (e:Error) { }
				// END code to get custom min,max
				
				// save the statistics for this column in the cache
				cache[getMin][column] = min;
				cache[getMax][column] = max;
				cache[getCount][column] = count;
				cache[getSum][column] = sum;
				cache[getSquareSum][column] = squareSum;
				cache[getMean][column] = mean;
				cache[getVariance][column] = variance;
				cache[getStandardDeviation][column] = standardDeviation;
				cache[getRunningTotals][column] = runningTotals;
				
				// the cache is now valid for this column
				cacheIsValid[column] = true;
			}
			
			return cache[statsFunction][column];
		}
	}
}
