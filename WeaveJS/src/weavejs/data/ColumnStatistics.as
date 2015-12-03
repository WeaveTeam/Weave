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

package weavejs.data
{
	import weavejs.WeaveAPI;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IColumnStatistics;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.data.keys.QKeyManager;
	import weavejs.utils.DebugUtils;
	import weavejs.utils.JS;
	import weavejs.utils.StandardLib;
	
	internal class ColumnStatistics implements IColumnStatistics
	{
		public function ColumnStatistics(column:IAttributeColumn)
		{
			this.column = column;
			column.addImmediateCallback(this, Weave.getCallbacks(this).triggerCallbacks, false, true);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getNorm(key:IQualifiedKey):Number
		{
			var min:Number = validateCache(getMin);
			var max:Number = validateCache(getMax);
			var map_numericData:Object = validateCache(hack_getNumericData);
			var value:Number = map_numericData ? map_numericData.get(key) : NaN;
			return (value - min) / (max - min);
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
		public function getSortIndex():Object
		{
			return validateCache(getSortIndex);
		}
		
		/**
		 * @inheritDoc
		 */
		public function hack_getNumericData():Object
		{
			return validateCache(hack_getNumericData);
		}
		
		/**
		 * Gets a Dictionary that maps a IQualifiedKey to a running total numeric value, based on the order of the keys in the column.
		 */
		public function getRunningTotals():Object
		{
			return validateCache(getRunningTotals);
		}
		
		/**********************************************************************/
		
		/**
		 * This maps a stats function of this object to a cached value for the function.
		 * Example: map_method_result.get(getMin) is a cached value for the getMin function.
		 */
		private var map_method_result:Object = new JS.WeakMap();
		
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
			return map_method_result.get(statsFunction);
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
		private var map_runningTotals:Object;
		
		private var outKeys:Array;
		private var outNumbers:Array;
		private var map_sortIndex:Object; // IQualifiedKey -> int
		private var hack_map_numericData:Object; // IQualifiedKey -> Number
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
			map_sortIndex = new JS.WeakMap();
			hack_map_numericData = new JS.WeakMap();
			median = NaN;
			
			map_runningTotals = new JS.WeakMap();
			
			// high priority because preparing data is often a prerequisite for other things
			WeaveAPI.Scheduler.startTask(this, iterate, WeaveAPI.TASK_PRIORITY_HIGH, asyncComplete, Weave.lang("Calculating statistics for {0} values in {1}", keys.length, DebugUtils.debugId(column)));
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
				if (JS.now() > stopTime)
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
					map_runningTotals.set(key, sum);
					
					hack_map_numericData.set(key, value);
					outKeys[count] = key;
					outNumbers[count] = value;
					++count;
				}
			}
			return 1;
		}
		
		private function asyncComplete():void
		{
			if (busy)
			{
				Weave.getCallbacks(this).triggerCallbacks();
				return;
			}
			
			if (count == 0)
				min = max = NaN;
			mean = sum / count;
			variance = squareSum / count - mean * mean;
			standardDeviation = Math.sqrt(variance);
			
			outKeys.length = count;
			outNumbers.length = count;
			var qkm:QKeyManager = WeaveAPI.QKeyManager as QKeyManager;
			var outIndices:Array = StandardLib.sortOn(outKeys, [outNumbers, qkm.map_qkey_keyType, qkm.map_qkey_localName], null, false, true);
			median = outNumbers[outIndices[int(count / 2)]];
			i = count;
			while (--i >= 0)
				map_sortIndex.set(outKeys[outIndices[i]], i);
			
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
			map_method_result.set(getMin, min);
			map_method_result.set(getMax, max);
			map_method_result.set(getCount, count);
			map_method_result.set(getSum, sum);
			map_method_result.set(getSquareSum, squareSum);
			map_method_result.set(getMean, mean);
			map_method_result.set(getVariance, variance);
			map_method_result.set(getStandardDeviation, standardDeviation);
			map_method_result.set(getMedian, median);
			map_method_result.set(getSortIndex, map_sortIndex);
			map_method_result.set(hack_getNumericData, hack_map_numericData);
			map_method_result.set(getRunningTotals, map_runningTotals);
			
			//trace('stats calculated', debugId(this), debugId(column), String(column));
			
			// trigger callbacks when we are done
			Weave.getCallbacks(this).triggerCallbacks();
		}
	}
}
