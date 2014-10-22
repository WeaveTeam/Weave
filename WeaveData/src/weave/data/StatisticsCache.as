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
	import weave.api.data.IStatisticsCache;
	import weave.api.getCallbackCollection;
	import weave.api.objectWasDisposed;
	import weave.api.registerDisposableChild;
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
				stats = new ColumnStatistics(column);
				
				// when the column is disposed, the stats should be disposed
				_columnToStats[column] = registerDisposableChild(column, stats);
			}
			return stats;
		}
	}
}

import flash.utils.Dictionary;
import flash.utils.getTimer;

import weave.api.data.ColumnMetadata;
import weave.api.data.IAttributeColumn;
import weave.api.data.IColumnStatistics;
import weave.api.data.IQualifiedKey;
import weave.api.getCallbackCollection;
import weave.api.registerDisposableChild;
import weave.compiler.StandardLib;

internal class ColumnStatistics implements IColumnStatistics
{
	public function ColumnStatistics(column:IAttributeColumn)
	{
		this.column = column;
		column.addImmediateCallback(this, getCallbackCollection(this).triggerCallbacks, false, true);
	}
	
	/**
	 * @inheritDoc
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
	 * @inheritDoc
	 */
	public function getMin():Number
	{
		return validateCache(getMin);
	}
	
	/**
	 * @inheritDoc
	 */
	public function getMax():Number
	{
		return validateCache(getMax);
	}
	
	/**
	 * @inheritDoc
	 */
	public function getCount():Number
	{
		return validateCache(getCount);
	}
	
	/**
	 * @inheritDoc
	 */
	public function getSum():Number
	{
		return validateCache(getSum);
	}
	
	/**
	 * @inheritDoc
	 */
	public function getSquareSum():Number
	{
		return validateCache(getSquareSum);
	}
	
	/**
	 * @inheritDoc
	 */
	public function getMean():Number
	{
		return validateCache(getMean);
	}
	
	/**
	 * @inheritDoc
	 */
	public function getVariance():Number
	{
		return validateCache(getVariance);
	}
	
	/**
	 * @inheritDoc
	 */
	public function getStandardDeviation():Number
	{
		return validateCache(getStandardDeviation);
	}
	
	/**
	 * @inheritDoc
	 */
	public function getMedian():Number
	{
		return validateCache(getMedian);
	}
	
	/**
	 * @inheritDoc
	 */
	public function getSortIndex():Dictionary
	{
		return validateCache(getSortIndex);
	}
	
	/**
	 * Gets a Dictionary that maps a IQualifiedKey to a running total numeric value, based on the order of the keys in the column.
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
	public var prevTriggerCounter:uint = 0;
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
	private var mean:Number;
	private var variance:Number;
	private var standardDeviation:Number;
	
	//TODO - make runningTotals use sorted order instead of original key order
	private var runningTotals:Dictionary;
	
	private var outKeys:Array;
	private var outNumbers:Array;
	private var sortIndex:Dictionary; // IQualifiedKey -> int
	private var median:Number;
	
	private function asyncStart():void
	{
		// remember the trigger counter from when we begin calculating
		prevTriggerCounter = column.triggerCounter;
		i = 0;
		keys = column.keys;
		min = Infinity; // so first value < min
		max = -Infinity; // so first value > max
		count = 0;
		sum = 0;
		squareSum = 0;
		mean = NaN;
		variance = NaN;
		standardDeviation = NaN;
		
		outKeys = new Array(keys.length);
		outNumbers = new Array(keys.length);
		sortIndex = new Dictionary(true);
		median = NaN;
		
		runningTotals = new Dictionary(true);
		
		// high priority because preparing data is often a prerequisite for other things
		WeaveAPI.StageUtils.startTask(this, iterate, WeaveAPI.TASK_PRIORITY_HIGH, asyncComplete);
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
		
		for (; i < keys.length; ++i)
		{
			if (getTimer() > stopTime)
				return i / keys.length;
			
			// iterate on this key
			var key:IQualifiedKey = keys[i] as IQualifiedKey;
			var value:Number = column.getValueFromKey(key, Number);
			// skip keys that do not have an associated numeric value in the column.
			if (isFinite(value))
			{
				sum += value;
				squareSum += value * value;
				
				if (value < min)
					min = value;
				if (value > max)
					max = value;
				
				//TODO - make runningTotals use sorted order instead of original key order
				runningTotals[key] = sum;
				
				outKeys[count] = key;
				outNumbers[count] = value;
				++count;
			}
		}
		return 1;
	}
	
	private function asyncComplete():void
	{
		if (count == 0)
			min = max = NaN;
		mean = sum / count;
		variance = squareSum / count - mean * mean;
		standardDeviation = Math.sqrt(variance);
		
		outKeys.length = count;
		outNumbers.length = count;
		// Array.sort() is very fast when no compare function is given.
		var outIndices:Array = outNumbers.sort(Array.NUMERIC | Array.RETURNINDEXEDARRAY);
		median = outNumbers[outIndices[int(count / 2)]];
		i = count;
		while (--i >= 0)
			sortIndex[outKeys[i]] = outIndices[i];
		
		// BEGIN code to get custom min,max
		var tempNumber:Number;
		try {
			tempNumber = StandardLib.asNumber(column.getMetadata(ColumnMetadata.MIN));
			if (isFinite(tempNumber))
				min = tempNumber;
		} catch (e:Error) { }
		try {
			tempNumber = StandardLib.asNumber(column.getMetadata(ColumnMetadata.MAX));
			if (isFinite(tempNumber))
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
		cache[getMedian] = median;
		cache[getSortIndex] = sortIndex;
		cache[getRunningTotals] = runningTotals;
		
		//trace('stats calculated', debugId(this), debugId(column), String(column));
		
		// trigger callbacks when we are done
		getCallbackCollection(this).triggerCallbacks();
	}
}
