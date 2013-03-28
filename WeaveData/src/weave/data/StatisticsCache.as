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
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IStatisticsCache;
	import weave.api.getCallbackCollection;
	import weave.api.objectWasDisposed;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.ReferencedColumn;
	
	/**
	 * This is an all-static class containing numerical statistics on columns and functions to access the statistics.
	 * 
	 * @author adufilie
	 */
	public class StatisticsCache implements IStatisticsCache
	{
		public function StatisticsCache():void
		{
		}
		
		/**
		 * @param column A column to get statistics for.
		 * @return A Dictionary that maps a IQualifiedKey to a running total numeric value, based on the order of the keys in the column.
		 */
		public function getRunningTotals(column:IAttributeColumn):Dictionary
		{
			return (getColumnStatistics(column) as ColumnStatistics).getRunningTotals();
		}

		private static const WRAPPER_TYPES:Array = [DynamicColumn,ReferencedColumn]; // special cases for validateCache()
		
		private const _columnToStats:Dictionary = new Dictionary(true);
		
		public function getColumnStatistics(column:IAttributeColumn):IColumnStatistics
		{
			if (column == null)
				throw new Error("getColumnStatistics(): Column parameter cannot be null.");
			
			if (objectWasDisposed(column))
			{
				delete _columnToStats[column];
				throw new Error("Invalid attempt to retrieve statistics for a disposed column.");
			}

			var stats:IColumnStatistics = _columnToStats[column] as IColumnStatistics;
			if (!stats)
			{
				// special case for column wrappers that do not alter the data in any way
				if (isSpecialCase(column))
					stats = new ColumnStatisticsWrapper(column as IColumnWrapper, this);
				else
					stats = new ColumnStatistics(column);
				
				// when the column is disposed, the stats should be disposed
				_columnToStats[column] = registerDisposableChild(column, stats);
			}
			return stats;
		}
		
		private var _DynamicColumn:String = getQualifiedClassName(DynamicColumn);
		private var _ReferencedColumn:String = getQualifiedClassName(ReferencedColumn);
		private function isSpecialCase(column:IAttributeColumn):Boolean
		{
			return (column is DynamicColumn && getQualifiedClassName(column) == _DynamicColumn)
				|| (column is ReferencedColumn && getQualifiedClassName(column) == _ReferencedColumn);
		}
	}
}
import weave.api.data.IColumnWrapper;
import weave.api.data.IStatisticsCache;
import weave.api.registerLinkableChild;
import weave.core.SessionManager;

internal class ColumnStatisticsWrapper implements IColumnStatistics
{
	public function ColumnStatisticsWrapper(columnWrapper:IColumnWrapper, statsCache:IStatisticsCache)
	{
		this.columnWrapper = columnWrapper;
		this.statsCache = statsCache;
		columnWrapper.addImmediateCallback(this, getStats);
	}
	
	private var triggerCounter:uint = 0;
	private var columnWrapper:IColumnWrapper;
	private var statsCache:IStatisticsCache;
	private var stats:IColumnStatistics;
	private function getStats():IColumnStatistics
	{
		if (triggerCounter != columnWrapper.triggerCounter)
		{
			triggerCounter = columnWrapper.triggerCounter;
			var internalColumn:IAttributeColumn = columnWrapper.getInternalColumn();
			var newStats:IColumnStatistics = internalColumn ? statsCache.getColumnStatistics(internalColumn) : null;
			if (stats != newStats)
			{
				if (stats)
					(WeaveAPI.SessionManager as SessionManager).unregisterLinkableChild(this, stats);
				stats = newStats;
				if (stats)
					(WeaveAPI.SessionManager as SessionManager).registerLinkableChild(this, stats);
			}
		}
		return stats;
	}
	
	/**
	 * @param key
	 * @return A number between 0 and 1, or NaN 
	 */		
	public function getNorm(key:IQualifiedKey):Number
	{
		return getStats() ? stats.getNorm(key) : undefined;
	}
	
	/**
	 * @return The minimum numeric value defined in the column.
	 */
	public function getMin():Number
	{
		return getStats() ? stats.getMin() : undefined;
	}
	
	/**
	 * @return The maximum numeric value defined in the column.
	 */
	public function getMax():Number
	{
		return getStats() ? stats.getMax() : undefined;
	}
	
	/**
	 * @return The count of the records having numeric values defined in the column.
	 */
	public function getCount():Number
	{
		return getStats() ? stats.getCount() : undefined;
	}
	
	/**
	 * @return The sum of all the numeric values defined in the column.
	 */
	public function getSum():Number
	{
		return getStats() ? stats.getSum() : undefined;
	}
	
	/**
	 * @return The sum of the squared numeric values defined in the column.
	 */
	public function getSquareSum():Number
	{
		return getStats() ? stats.getSquareSum() : undefined;
	}
	
	/**
	 * @return The mean value of all the numeric values defined in the column.
	 */
	public function getMean():Number
	{
		return getStats() ? stats.getMean() : undefined;
	}
	
	/**
	 * @return The variance of the numeric values defined in the column.
	 */
	public function getVariance():Number
	{
		return getStats() ? stats.getVariance() : undefined;
	}
	
	/**
	 * @return The standard deviation of the numeric values defined in the column.
	 */
	public function getStandardDeviation():Number
	{
		return getStats() ? stats.getStandardDeviation() : undefined;
	}
	
	/**
	 * @return A Dictionary that maps a IQualifiedKey to a running total numeric value, based on the order of the keys in the column.
	 */
	public function getRunningTotals():Dictionary
	{
		return getStats() ? (stats as ColumnStatistics).getRunningTotals() : undefined;
	}
}

import flash.utils.Dictionary;

import weave.api.WeaveAPI;
import weave.api.data.ColumnMetadata;
import weave.api.data.IAttributeColumn;
import weave.api.data.IColumnStatistics;
import weave.api.data.IQualifiedKey;
import weave.api.getCallbackCollection;
import weave.compiler.StandardLib;
import flash.utils.getTimer;

internal class ColumnStatistics implements IColumnStatistics
{
	public function ColumnStatistics(column:IAttributeColumn)
	{
		this.column = column;
	}
	
	/**
	 * @param key
	 * @return A number between 0 and 1, or NaN 
	 */		
	public function getNorm(key:IQualifiedKey):Number
	{
		var min:Number = validateCache(getMin);
		var max:Number = validateCache(getMax);
		var value:* = column.getValueFromKey(key, Number);
		if (value is Number)
			return (value - min) / (max - min);
		return NaN;
	}
	
	/**
	 * @return The minimum numeric value defined in the column.
	 */
	public function getMin():Number
	{
		return validateCache(getMin);
	}
	
	/**
	 * @return The maximum numeric value defined in the column.
	 */
	public function getMax():Number
	{
		return validateCache(getMax);
	}
	
	/**
	 * @return The count of the records having numeric values defined in the column.
	 */
	public function getCount():Number
	{
		return validateCache(getCount);
	}
	
	/**
	 * @return The sum of all the numeric values defined in the column.
	 */
	public function getSum():Number
	{
		return validateCache(getSum);
	}
	
	/**
	 * @return The sum of the squared numeric values defined in the column.
	 */
	public function getSquareSum():Number
	{
		return validateCache(getSquareSum);
	}
	
	/**
	 * @return The mean value of all the numeric values defined in the column.
	 */
	public function getMean():Number
	{
		return validateCache(getMean);
	}
	
	/**
	 * @return The variance of the numeric values defined in the column.
	 */
	public function getVariance():Number
	{
		return validateCache(getVariance);
	}
	
	/**
	 * @return The standard deviation of the numeric values defined in the column.
	 */
	public function getStandardDeviation():Number
	{
		return validateCache(getStandardDeviation);
	}
	
	/**
	 * @return A Dictionary that maps a IQualifiedKey to a running total numeric value, based on the order of the keys in the column.
	 */
	public function getRunningTotals():Dictionary
	{
		return validateCache(getRunningTotals);
	}
	
	/**********************************************************************/

	/**
	 * This maps a stats function of this object to a cached value for the function.
	 * Example: cache[getMin] is a cached value for the getMin function.
	 */
	private const cache:Dictionary = new Dictionary();
	
	private var column:IAttributeColumn;
	private var prevTriggerCounter:uint = 0;
	private var busy:Boolean = false;
	
	/**
	 * This function will validate the cached statistical values for the given column.
	 * @param statsFunction The function we are interested in calling.
	 * @return The cached result for the statsFunction.
	 */
	private function validateCache(statsFunction:Function):*
	{
		// the cache becomes invalid when the trigger counter has changed
		if (prevTriggerCounter != column.triggerCounter)
		{
			// statistics are undefined while column is busy
			busy = WeaveAPI.SessionManager.linkableObjectIsBusy(column);
			
			// once we have determined the column is not busy, begin the async task to calculate stats
			if (!busy)
				asyncStart();
			
			// no stats yet
			return undefined;
		}
		return cache[statsFunction];
	}
	
	private var i:int;
	private var keys:Array;
	
	private var min:Number;
	private var max:Number;
	private var count:Number;
	private var sum:Number;
	private var squareSum:Number;
	private var runningTotals:Dictionary;
	private var mean:Number;
	private var variance:Number;
	private var standardDeviation:Number;
	
	private function asyncStart():void
	{
		// remember the trigger counter from when we begin calculating
		prevTriggerCounter = column.triggerCounter;
		i = 0;
		keys = column.keys;
		min = NaN;
		max = NaN;
		count = 0;
		sum = 0;
		squareSum = 0;
		runningTotals = new Dictionary(true);
		mean = NaN;
		variance = NaN;
		standardDeviation = NaN;
		WeaveAPI.StageUtils.startTask(this, iterate, WeaveAPI.TASK_PRIORITY_BUILDING, asyncComplete);
	}

	private function iterate(stopTime:int):Number
	{
		// when the column is found to be busy or modified since last time, stop immediately
		if (busy || prevTriggerCounter != column.triggerCounter)
		{
			// make sure trigger counter is reset because cache is now invalid
			prevTriggerCounter = 0;
			return 1;
		}
		
		for (; i < keys.length; i++)
		{
			if (getTimer() > stopTime)
				return i / keys.length;
			
			// iterate on this key
			var key:IQualifiedKey = keys[i] as IQualifiedKey;
			var value:Number = column.getValueFromKey(key, Number);
			// skip keys that do not have an associated numeric value in the column.
			if (isFinite(value))
			{
				count++;
				sum += value;
				runningTotals[key] = sum;
				squareSum += value * value;
				
				if (isNaN(min) || value < min)
					min = value;
				if (isNaN(max) || value > max)
					max = value;
			}
		}
		return 1;
	}
	
	private function asyncComplete():void
	{
		mean = sum / count;
		variance = squareSum / count - mean * mean;
		standardDeviation = Math.sqrt(variance);
		
		// BEGIN code to get custom min,max
		var tempNumber:Number;
		try {
			tempNumber = StandardLib.asNumber(column.getMetadata(ColumnMetadata.MIN));
			if (!isNaN(tempNumber))
				min = tempNumber;
		} catch (e:Error) { }
		try {
			tempNumber = StandardLib.asNumber(column.getMetadata(ColumnMetadata.MAX));
			if (!isNaN(tempNumber))
				max = tempNumber;
		} catch (e:Error) { }
		// END code to get custom min,max
		
		// save the statistics for this column in the cache
		cache[getMin] = min;
		cache[getMax] = max;
		cache[getCount] = count;
		cache[getSum] = sum;
		cache[getSquareSum] = squareSum;
		cache[getMean] = mean;
		cache[getVariance] = variance;
		cache[getStandardDeviation] = standardDeviation;
		cache[getRunningTotals] = runningTotals;
		
		// trigger callbacks when we are done
		getCallbackCollection(this).triggerCallbacks();
	}
}
