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

package weavejs.data.bin
{
	import weavejs.WeaveAPI;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.core.LinkableNumber;
	import weavejs.core.Scheduler;
	import weavejs.data.column.SecondaryKeyNumColumn;
	import weavejs.util.ArrayUtils;
	import weavejs.util.AsyncSort;
	import weavejs.util.ColumnUtils;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	
	/**
	 * Implemented from https://gist.github.com/tmcw/4977508
	 * Also, read : http://macwright.org/2013/02/18/literate-jenks.html
	 * Other implementations from Doug Curl (javascript) and Daniel J Lewis (python implementation) and  Simon Georget (Geostats)
	 * http://www.arcgis.com/home/item.html?id=0b633ff2f40d412995b8be377211c47b
	 * http://danieljlewis.org/2010/06/07/jenks-natural-breaks-algorithm-in-python/
	 * https://github.com/simogeo/geostats/blob/master/lib/geostats.js
	 * http://danieljlewis.org/files/2010/06/Jenks.pdf
	 */
	
	public class NaturalJenksBinningDefinition extends AbstractBinningDefinition
	{
		public function NaturalJenksBinningDefinition()
		{
			super(true, false);
		}
		
		public var numOfBins:LinkableNumber = Weave.linkableChild(this,new LinkableNumber(5));
		
		// reusable temporary object
		private var _tempNumberClassifier:NumberClassifier = Weave.disposableChild(this, NumberClassifier);
		
		private var _column:IAttributeColumn = null;
		private var asyncSort:AsyncSort = Weave.disposableChild(this, AsyncSort);
		override public function generateBinClassifiersForColumn(column:IAttributeColumn):void
		{
			_column = column;
			if (column)
			{
				// BEGIN DIMENSION SLIDER HACK
				var nonWrapperColumn:IAttributeColumn = ColumnUtils.hack_findNonWrapperColumn(column);
				if (nonWrapperColumn is SecondaryKeyNumColumn)
				{
					SecondaryKeyNumColumn.allKeysHack = true;
					var noChange:Boolean = (_keys === nonWrapperColumn.keys);
					_keys = nonWrapperColumn.keys;
					SecondaryKeyNumColumn.allKeysHack = false;
					// stop if we already did this
					if (noChange)
					{
						asyncResultCallbacks.triggerCallbacks();
						return;
					}
				}
				else
				// END DIMENSION SLIDER HACK
				{
					_keys = column.keys.concat(); // make a copy so we know length won't change during async task
				}
			}
			else
			{
				_keys = [];
			}
			
			_sortedValues = new Array();
			_numOfBins = numOfBins.value;
			_keyCount = 0;
			_previousSortedValues.length = 0;
			
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			// stop any previous sort task by sorting an empty array
			asyncSort.beginSort(_previousSortedValues);
			
			_compoundIterateAll(-1); // reset compound task
			
			// high priority because not much can be done without data
			WeaveAPI.Scheduler.startTask(asyncResultCallbacks, _compoundIterateAll, WeaveAPI.TASK_PRIORITY_HIGH, _handleJenksBreaks, Weave.lang("Computing Natural Breaks binning for {0} values", _keys.length));
		}
		
		private var _compoundIterateAll:Function = Scheduler.generateCompoundIterativeTask(_getValueFromKeys, _iterateSortedKeys, _iterateJenksBreaks);
		private var _numOfBins:int;
		private var _keyCount:int = 0;
		private var _keys:Array = []; 
		private function _getValueFromKeys(stopTime:int):Number
		{
			var currValue:Number;
			for (; _keyCount < _keys.length; _keyCount++)
			{
				if (JS.now() > stopTime)
					return _keyCount/_keys.length;
				/*ignore NaN */
				currValue = _column.getValueFromKey(_keys[_keyCount],Number);
				if (isFinite(currValue))
					_sortedValues.push(currValue);
			}
			
			// begin sorting now
			asyncSort.beginSort(_sortedValues, StandardLib.numericCompare);
			
			return 1;
		}
		
		// in the original implementation, these matrices are referred to
		// as `LC` and `OP`
		//
		// * lower_class_limits (LC): optimal lower class limits
		// * variance_combinations (OP): optimal variance combinations for all classes
		private var _lower_class_limits:Array = [];
		private var _variance_combinations:Array = [];
		
		private function _iterateSortedKeys(returnTime:int):Number
		{
			// wait for sort to complete
			if (asyncSort.result == null)
				return 0;
			
			// the code below runs only once - this function is not a proper iterative task
			
			ArrayUtils.copy(_sortedValues,_previousSortedValues);
			
			if(_sortedValues.length == 0)
				return 1;
			
			_lower_class_limits = [];
			_variance_combinations = [];
			// Initialize and fill each matrix with zeroes
			for (var i:int = 0; i < _sortedValues.length+1; i++)
			{
				var temp1:Array = [];
				var temp2:Array = [];
				// despite these arrays having the same values, we need
				// to keep them separate so that changing one does not change
				// the other
				for(var j:int =0; j < _numOfBins+1; j++)
				{
					temp1.push(0);
					temp2.push(0);
				}
				_lower_class_limits.push(temp1);
				_variance_combinations.push(temp2);
			}
			
			for (var k:int =1; k <_numOfBins + 1; k++)
			{
				_lower_class_limits[1][k] = 1;
				_variance_combinations[1][k] = 0;
				
				for (var t:int =2; t<_sortedValues.length+1; t++)
				{
					_variance_combinations[t][k] = Number.POSITIVE_INFINITY;
				}
			}
			
			_variance = 0;
			_count = 2;
			_m = 0;
			
			return 1;
		}
		
		private var _previousSortedValues:Array = [];
		private var _sortedValues:Array = [];
		
		private var _count:int = 2;
		private var _m:Number = 0;
		private var _p:Number = 2;
		
		// the variance, as computed at each step in the calculation
		private var _variance:Number = 0;
		
		// `SZ` originally. this is the sum of the values seen thus
		// far when calculating variance.
		private var _sum:Number = 0;
		
		// `ZSQ` originally. the sum of squares of values seen
		// thus far
		private var _sum_squares:Number = 0;
		// `WT` originally
		private var _w:Number = 0;
		
		
		private function _iterateJenksBreaks(returnTime:int):Number
		{
			// Compute the matrices required for Jenks breaks.
			for (; _count < _sortedValues.length + 1; _count++)
			{
				if (_m==0)
				{
					_sum= 0;
					_sum_squares= 0;
					_w= 0;
					_m =1;			
				}
				for (; _m < _count + 1; _m++)
				{
					if(JS.now()>returnTime)
					{
						return _count/(_sortedValues.length+1);
					}
					// `III` originally
					var lower_class_limit:Number = _count - _m +1;
					var val:Number = _sortedValues[lower_class_limit-1];
					
					_sum_squares += val * val;
					_sum += val;
					
					// here we're estimating variance for each potential classing
					// of the data, for each potential number of classes. `w`
					// is the number of data points considered so far.
					_w += 1;
					
					// the variance at this point in the sequence is the difference
					// between the sum of squares and the total x 2, over the number
					// of samples.					
					_variance = _sum_squares - (_sum * _sum) / _w;
					
					var i4:Number= lower_class_limit -1;
					if(i4 !=0)
					{
						_p = 2;
						for (; _p < _numOfBins + 1; _p++)
						{
							// if adding this element to an existing class
							// will increase its variance beyond the limit, break
							// the class at this point, setting the lower_class_limit
							// at this point.
							if((_variance_combinations[_count][_p]) >= (_variance + _variance_combinations[i4][_p-1]))
							{
								_lower_class_limits[_count][_p] = lower_class_limit;
								_variance_combinations[_count][_p] = _variance +_variance_combinations[i4][_p-1];
							}
						}
					}
				}
				_m = 0;
				_lower_class_limits[_count][1] = 1;
				_variance_combinations[_count][1] = _variance;
			}
			return 1;
		}
		
		private function _handleJenksBreaks():void
		{
			var k:int,
				value:Number,
				data:Array = _sortedValues,
				kclass:Array = [],
				countNum:int = 1;
			
			// don't attempt to generate more bins than there are distinct values
			value = data[0];
			for (k = 1; k < data.length; k++)
			{
				if (value != data[k])
				{
					value = data[k];
					countNum++;
					if (countNum >= _numOfBins)
						break;
				}
			}
				
			// the calculation of classes will never include the upper and
			// lower bounds, so we need to explicitly set them
			kclass[countNum] = data[data.length - 1];
			kclass[0] = data[0];
			
			// the lower_class_limits matrix is used as indexes into itself
			// here: the `k` variable is reused in each iteration.
			k = data.length - 1;
			while (countNum > 1) {
				kclass[countNum - 1] = data[_lower_class_limits[k][countNum] - 2];
				k = _lower_class_limits[k][countNum] - 1;
				countNum--;
			}
			
			for (var iBin:int = 0; iBin < kclass.length - 1; iBin++)
			{
				var minIndex:Number;
				if(iBin == 0)
				{
					minIndex = 0;
				}
				else
				{
					minIndex = _previousSortedValues.lastIndexOf(kclass[iBin]);
					minIndex = minIndex +1;
				}
				
				_tempNumberClassifier.min.value = _previousSortedValues[minIndex];
				
				var maxIndex:Number;
				if(iBin == _numOfBins -1)
				{
					maxIndex = _previousSortedValues.length -1;
				}
				else
				{
					/* Get the index of the next break */
					maxIndex = _previousSortedValues.lastIndexOf(kclass[iBin+1]);
				}
				
				if(maxIndex == -1)
				{
					_tempNumberClassifier.max.value = _tempNumberClassifier.min.value;
				}
				else
				{
					_tempNumberClassifier.max.value = _previousSortedValues[maxIndex];
				}
				_tempNumberClassifier.minInclusive.value = true;
				_tempNumberClassifier.maxInclusive.value = true;
				
				if (_tempNumberClassifier.min.value > _tempNumberClassifier.max.value)
					continue;
				
				//first get name from overrideBinNames
				var name:String = getOverrideNames()[iBin];
				//if it is empty string set it from generateBinLabel
				if (!name)
					name = _tempNumberClassifier.generateBinLabel(_column);
				
				output.requestObjectCopy(name, _tempNumberClassifier);
			}
			
			// trigger callbacks now because we're done updating the output
			asyncResultCallbacks.triggerCallbacks();
		}
		
		protected function fixMinMaxInclusive():void
		{
			var a:Array = output.getObjects(NumberClassifier);
			for (var i:int = 0; i < a.length; i++)
			{
				var nc1:NumberClassifier = a[i];
				var nc2:NumberClassifier = a[i+1];
				if (nc1 && nc2 && nc1.max.value == nc2.min.value)
					nc2.minInclusive.value = !(nc1.maxInclusive.value = (nc1.min.value == nc1.max.value || !nc1.minInclusive.value));
				var newName1:String = getOverrideNames()[i] || nc1.generateBinLabel(_column);
				output.renameObject(output.getName(nc1), newName1);
			}
		}
		
		private function getSumOfNumbers(list:Array):Number
		{
			var result:Number = 0;
			try
			{
				for each (var num:Number in list)
				{
					result += num;
				}
			}
			catch(e:Error)
			{
				JS.error(e, "Error adding numbers in array");
				return 0;
			}
			
			return result;
		}
		
		/**
		 * Returns all the values from the column sorted in ascedning order.
		 * @param column An IattributeColumn with numeric values 
		 * */
		private  function getSortedNumbersFromColumn(column:IAttributeColumn):Array
		{
			var keys:Array = column ? column.keys : [];
			var sortedColumn:Array = new Array(keys.length);
			for (var i:int = 0; i < keys.length; i++)
				sortedColumn[i] = Number(column.getValueFromKey(keys[i], Number));
			
			AsyncSort.sortImmediately(sortedColumn);
			return sortedColumn;
		}
		
		/* This function returns the Good Fit Value for the breaks. Not used but just in case*/
//		private function getGVF(column:IAttributeColumn):Number
//		{
//			var listMean:Number = getSumOfNumbers(_previousSortedValues);
//			
//			var SDAM:Number = 0;
//			var sqDev:Number = 0;
//			
//			for(var i:int =0; i < _previousSortedValues.length; i++)
//			{
//				sqDev = Math.pow((_previousSortedValues[i]- listMean), 2);
//				SDAM += sqDev;
//			}
//			
//			
//			var SDCM:Number = 0;
//			var preSDCM:Number;
//			var classStart:Number;
//			var classEnd:Number;
//			var classValues:Array;
//			var classMean:Number;
//			var sqDev2:Number;
//			
//			for(var j:int =0; j < numOfBins.value; j++)
//			{
//				if(_previousBreaks[j] ==0)
//				{
//					classStart = 0;
//				}
//				else
//				{
//					classStart = _previousSortedValues.indexOf(_previousBreaks[j]);
//					classStart += 1;
//				}
//				
//				classEnd = _previousSortedValues.indexOf(_previousBreaks[j+1]);
//				
//				classValues = _previousSortedValues.slice(classStart,classEnd);
//				
//				classMean = getSumOfNumbers(classValues)/classValues.length;
//				
//				for(var k:int =0; k < classValues.length; k++)
//				{
//					sqDev2 = Math.pow((classValues[k] - classMean),2);
//					preSDCM += sqDev2;
//				}
//				
//				SDCM += preSDCM;
//			}
//			
//			return (SDAM - SDCM)/SDAM;
//			
//		}
		
	}
}