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

package weavejs.util
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableObject;
	import weavejs.util.DebugUtils;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	
	/**
	 * Asynchronous merge sort.
	 * 
	 * @author adufilie
	 */
	public class AsyncSort implements ILinkableObject
	{
		public static var debug:Boolean = false;
		
		private static var _immediateSorter:AsyncSort; // used by sortImmediately()
		
		/**
		 * This function will sort an Array (or Vector) immediately.
		 * @param array An Array (or Vector) to sort in place.
		 * @param compareFunction The function used to compare items in the array.
		 */
		public static function sortImmediately(array:*, compareFunction:Function = null):void
		{
			if (!_immediateSorter)
			{
				_immediateSorter = new AsyncSort();
				_immediateSorter._immediately = true;
			}
			
			// temporarily set _immediateSorter to null in case sortImmediately is called recursively.
			var sorter:AsyncSort = _immediateSorter;
			_immediateSorter = null;
			
			sorter.beginSort(array, compareFunction);
			
			_immediateSorter = sorter;
		}
		
		/**
		 * This function is a wrapper for StandardLib.stringCompare(a, b, true) (case-insensitive String compare).
		 */		
		public static function compareCaseInsensitive(a:String, b:String):int
		{
			return StandardLib.stringCompare(a, b, true);
		}
		
		/**
		 * Compares two primitive values.
		 * This function is faster than StandardLib.compare(), but does not do deep object compare.
		 */
		public static function primitiveCompare(a:*, b:*):int
		{
			if (a === b)
				return 0;
			if (a == null)
				return 1;
			if (b == null)
				return -1;
			var typeA:String = typeof(a);
			var typeB:String = typeof(b);
			if (typeA != typeB)
				return StandardLib.stringCompare(typeA, typeB);
			if (typeA == 'boolean')
				return StandardLib.numericCompare(Number(a), Number(b));
			if (typeA == 'number')
				return StandardLib.numericCompare(a as Number, b as Number);
			if (typeA == 'string')
				return StandardLib.stringCompare(a as String, b as String);
			if (a is Date && b is Date)
				return StandardLib.dateCompare(a as Date, b as Date);
			return 1; // not equal
		}
		
		/**
		 * This is the sorted Array (or Vector), or null if the sort operation has not completed yet.
		 */
		public function get result():*
		{
			return source ? null : original;
		}
		
		private var original:*; // original array
		private var source:*; // contains sub-arrays currently being merged
		private var destination:*; // buffer to store merged sub-arrays
		private var compare:Function; // compares two array items
		private var length:uint; // length of original array
		private var subArraySize:uint; // size of sub-array
		private var middle:uint; // end of left and start of right sub-array
		private var end:uint; // end of right sub-array
		private var iLeft:uint; // left sub-array source index
		private var iRight:uint; // right sub-array source index
		private var iMerged:uint; // merged destination index
		private var elapsed:int; // keeps track of elapsed time inside iterate()
		private var _immediately:Boolean = false; // set in sortImmediately(), checked in beginSort()
		
		/**
		 * This will begin an asynchronous sorting operation on the specified Array (or Vector).
		 * Only one sort operation can be carried out at a time.
		 * Callbacks will be triggered when the sorting operation completes.
		 * The given Array (or Vector) will be modified in-place.
		 * @param arrayToSort The Array (or Vector) to sort.
		 * @param compareFunction A function that compares two items and returns -1, 0, or 1.
		 * @see mx.utils.StandardLib#compare()
		 */
		public function beginSort(arrayToSort:*, compareFunction:Function = null):void
		{
			// initialize
			compare = compareFunction || primitiveCompare;
			original = arrayToSort || [];
			source = original;
			length = original.length;
			
			// make a buffer of the same type and length
			var Type:Class = (source as Object).constructor;
			destination = new Type();
			destination.length = length;
			
			subArraySize = 1;
			iLeft = 0;
			iRight = 0;
			middle = 0;
			end = 0;
			elapsed = 0;
			
			if (_immediately)
			{
				iterate(Number.MAX_VALUE);
				done();
			}
			else
			{
				// high priority because many things cannot continue without sorting results or must be recalculated when sorting finishes
				WeaveAPI.Scheduler.startTask(this, iterate, WeaveAPI.TASK_PRIORITY_HIGH, done, Weave.lang("Sorting {0} items", original.length));
			}
		}
		
		/**
		 * Aborts the current async sort operation.
		 */
		public function abort():void
		{
			compare = null;
			source = original = destination = null;
			length = subArraySize = iLeft = iRight = middle = end = elapsed = 0;
		}
		
		private function iterate(stopTime:int):Number
		{
			var time:int = JS.now();
			
			while (JS.now() < stopTime)
			{
				if (iLeft < middle) // if there are still more items in the left sub-array
				{
					// copy smallest value to merge destination
					if (iRight < end && compare(source[iRight], source[iLeft]) < 0)
						destination[iMerged++] = source[iRight++];
					else
						destination[iMerged++] = source[iLeft++];
				}
				else if (iRight < end) // if there are still more items in the right sub-array
				{
					destination[iMerged++] = source[iRight++];
				}
				else if (end < length) // if there are still more pairs of sub-arrays to merge
				{
					// begin merging the next pair of sub-arrays
					var start:uint = end;
					middle = Math.min(start + subArraySize, length);
					end = Math.min(middle + subArraySize, length);
					iLeft = start;
					iRight = middle;
					iMerged = start;
				}
				else // done merging all pairs of sub-arrays
				{
					// use the merged destination as the next source
					var merged:* = destination;
					destination = source;
					source = merged;
					
					// start merging sub-arrays of twice the previous size
					end = 0;
					subArraySize *= 2;
					
					// stop if the sub-array includes the entire array
					if (subArraySize >= length)
						break;
				}
			}
			
			elapsed += JS.now() - time;
			
			// if one sub-array includes the entire array, we're done
			if (subArraySize >= length)
				return 1; // done
			
			//TODO: improve progress calculation
			return subArraySize / length; // not exactly accurate, but returns a number < 1
		}
		
		private function done():void
		{
			// source array is completely sorted
			if (source != original) // if source isn't the original
			{
				// copy the sorted values to the original
				var i:int = length;
				while (i--)
					original[i] = source[i];
			}
			
			// clean up so the "get result()" function knows we're done
			source = null;
			destination = null;
			
			if (debug && elapsed > 0)
				DebugUtils.debugTrace(this,result.length,'in',elapsed/1000,'seconds');
			
			if (!_immediately)
				Weave.getCallbacks(this).triggerCallbacks();
		}
		
		/*************
		 ** Testing **
		 *************/
		
		/*
			Built-in sort is slower when using a compare function because it uses more comparisons.
			Array.sort 50 numbers; 0.002 seconds; 487 comparisons
			Merge Sort 50 numbers; 0.001 seconds; 208 comparisons
			Array.sort 3000 numbers; 0.304 seconds; 87367 comparisons
			Merge Sort 3000 numbers; 0.111 seconds; 25608 comparisons
			Array.sort 6000 numbers; 0.809 seconds; 226130 comparisons
			Merge Sort 6000 numbers; 0.275 seconds; 55387 comparisons
			Array.sort 12000 numbers; 1.969 seconds; 554380 comparisons
			Merge Sort 12000 numbers; 0.514 seconds; 119555 comparisons
			Array.sort 25000 numbers; 9.498 seconds; 2635394 comparisons
			Merge Sort 25000 numbers; 1.234 seconds; 274965 comparisons
			Array.sort 50000 numbers; 37.285 seconds; 10238787 comparisons
			Merge Sort 50000 numbers; 2.603 seconds; 585089 comparisons
		*/
		/*
			Built-in sort is faster when no compare function is given.
			Array.sort 50 numbers; 0 seconds
			Merge Sort 50 numbers; 0.001 seconds
			Array.sort 3000 numbers; 0.003 seconds
			Merge Sort 3000 numbers; 0.056 seconds
			Array.sort 6000 numbers; 0.006 seconds
			Merge Sort 6000 numbers; 0.123 seconds
			Array.sort 12000 numbers; 0.012 seconds
			Merge Sort 12000 numbers; 0.261 seconds
			Array.sort 25000 numbers; 0.026 seconds
			Merge Sort 25000 numbers; 0.599 seconds
			Array.sort 50000 numbers; 0.058 seconds
			Merge Sort 50000 numbers; 1.284 seconds
		*/
		private static var _testArrays:Array;
		private static var _testArraysSortOn:Array;
		private static var _testType:int = -1;
		private static function initTestArrays(testType:int):void
		{
			if (testType != _testType)
			{
				_testType = testType;
				_testArrays = [];
				_testArraysSortOn = [];
				for each (var n:uint in [0,1,2,3,4,5,50,3000,6000,12000,25000,50000])
				{
					var array:Array = [];
					var arraySortOn:Array = [];
					for (var i:int = 0; i < n; i++)
					{
						var value:*;
						if (testType == 0) // random integers
							value = uint(Math.random()*100);
						else if (testType == 1) // random integers and NaNs
							value = Math.random() < .5 ? NaN : uint(Math.random()*100);
						else if (testType == 2) // random strings
							value = 'a' + Math.random();
						
						array.push(value);
						arraySortOn.push({'value': value});
					}
					_testArrays.push(array);
					_testArraysSortOn.push(arraySortOn);
				}
			}
			var desc:String = ['uint', 'uint and NaN', 'string'][testType];
			trace("testType =", testType, '(' + desc + ')');
		}
		public static function test(compare:Object, testType:int = 0):void
		{
			initTestArrays(testType);
			_debugCompareFunction = compare as Function;
			for each (var _array:Array in _testArrays)
			{
				var array1:Array = _array.concat();
				var array2:Array = _array.concat();
				
				var start:int = JS.now();
				_debugCompareCount = 0;
				if (compare === null)
					array1.sort(0);
				else if (compare is Function)
					array1.sort(_debugCompareCounter);
				else
					array1.sort(compare);
				trace('Array.sort', array1.length, 'numbers;', (JS.now() - start) / 1000, 'seconds;', _debugCompareCount ? (_debugCompareCount+' comparisons') : '');
				
				start = JS.now();
				_debugCompareCount = 0;
				sortImmediately(array2, compare is Function ? _debugCompareCounter : null);
				//trace('Merge Sort', n, 'numbers;', _immediateSorter.elapsed / 1000, 'seconds;',_debugCompareCount,'comparisons');
				trace('Merge Sort', array2.length, 'numbers;', (JS.now() - start) / 1000, 'seconds;', _debugCompareCount ? (_debugCompareCount+' comparisons') : '');
				
				if (array2.length == 1 && StandardLib.compare(array1[0],array2[0]) != 0)
					throw new Error("sort failed on array length 1");
				
				verifyNumbersSorted(array2);
			}
		}
		public static function testSortOn(compare:Object, testType:int = 0):void
		{
			initTestArrays(testType);
			_debugCompareFunction = newSortOnCompare('value', compare as Function || primitiveCompare);
			for each (var _array:Array in _testArraysSortOn)
			{
				var array1:Array = _array.concat();
				var array2:Array = _array.concat();
				var array3:Array = _array.concat();
				var array4:Array = _array.concat();
				
				var start:int;
				
				/*
				start = JS.now();
				_debugCompareCount = 0;
				if (compare === null)
					array1.sortOn('value', 0);
				else if (compare is Function)
					array1.sortOn('value', _debugCompareCounter);
				else
					array1.sortOn('value', compare);
				trace('Array.sortOn', array1.length, 'numbers;', (JS.now() - start) / 1000, 'seconds;', _debugCompareCount ? (_debugCompareCount+' comparisons') : '');
				*/
				
				start = JS.now();
				_debugCompareCount = 0;
				var plucked:Array = new Array(_array.length);
				var i:int = _array.length;
				while (i--)
					plucked[i] = _array[i]['value'];
				if (compare === null)
					plucked.sort(0);
				else if (compare is Function)
					plucked.sort(_debugCompareCounter);
				else
					plucked.sort(compare);
				trace('Pluck & sort', plucked.length, 'numbers;', (JS.now() - start) / 1000, 'seconds;', _debugCompareCount ? (_debugCompareCount+' comparisons') : '');
				
				start = JS.now();
				_debugCompareCount = 0;
				StandardLib.sortOn(array3, 'value');
				trace('StdLib sortOn', array3.length, 'numbers;', (JS.now() - start) / 1000, 'seconds;', _debugCompareCount ? (_debugCompareCount+' comparisons') : '');
				
				start = JS.now();
				_debugCompareCount = 0;
				StandardLib.sortOn(array4, ['value']);
				trace('StdLib sortOn[]', array4.length, 'numbers;', (JS.now() - start) / 1000, 'seconds;', _debugCompareCount ? (_debugCompareCount+' comparisons') : '');

				start = JS.now();
				_debugCompareCount = 0;
				sortImmediately(array2, _debugCompareCounter);
				//trace('Merge Sort', n, 'numbers;', _immediateSorter.elapsed / 1000, 'seconds;',_debugCompareCount,'comparisons');
				trace('Merge SortOn', array2.length, 'numbers;', (JS.now() - start) / 1000, 'seconds;', _debugCompareCount ? (_debugCompareCount+' comparisons') : '');

				if (array2.length == 1 && StandardLib.compare(array1[0],array2[0]) != 0)
					throw new Error("sort failed on array length 1");
				
				verifyNumbersSorted(array2);
			}

		}
		private static function newSortOnCompare(prop:String, compare:Function):Function
		{
			return function(a:*, b:*):int { return compare(a[prop], b[prop]); };
		}
		private static function verifyNumbersSorted(array:Array):void
		{
			for (var i:int = 1; i < array.length; i++)
			{
				if (StandardLib.numericCompare(array[i - 1], array[i]) > 0)
				{
					throw new Error("ASSERTION FAIL " + array[i - 1] + ' > ' + array[i]);
				}
			}
		}
		private static var _debugCompareCount:int = 0;
		private static var _debugCompareFunction:Function = null;
		private static function _debugCompareCounter(a:Object, b:Object):int
		{
			_debugCompareCount++;
			return _debugCompareFunction(a, b);
		}
	}
}
