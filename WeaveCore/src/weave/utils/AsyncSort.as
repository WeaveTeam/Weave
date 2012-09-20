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

package weave.utils
{
	import flash.utils.getTimer;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	
	/**
	 * Asynchronous merge sort.
	 * 
	 * @author adufilie
	 */
	public class AsyncSort implements ILinkableObject
	{
		public static var debug:Boolean = false;
		
		public function AsyncSort():void
		{
		}
		
		private static var _immediateSorter:AsyncSort; // used by sortImmediately()
		
		/**
		 * This function will sort an Array (or Vector) immediately.
		 * @param array An Array (or Vector) to sort in place.
		 * @param compareFunction The function used to compare items in the array.
		 */		
		public static function sortImmediately(array:*, compareFunction:Function = null):void
		{
			if (!_immediateSorter)
				_immediateSorter = new AsyncSort();
			
			_immediateSorter._immediately = true;
			_immediateSorter.beginSort(array, compareFunction);
			_immediateSorter._immediately = false;
		}
		
		/**
		 * This function is a wrapper for ObjectUtil.stringCompare(a, b, true) (case-insensitive String compare).
		 */		
		public static function compareCaseInsensitive(a:String, b:String):int
		{
			return ObjectUtil.stringCompare(a, b, true);
		}
		
		/**
		 * This is a basic compare function similar to the default compare used by Array.sort().
		 * This function is faster than ObjectUtil.compare(), but does not do deep object compare.
		 */
		public static function defaultCompare(a:*, b:*):int
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
				return ObjectUtil.stringCompare(typeA, typeB);
			if (typeA == 'boolean')
				return ObjectUtil.numericCompare(Number(a), Number(b));
			if (typeA == 'number')
				return ObjectUtil.numericCompare(a as Number, b as Number);
			if (typeA == 'string')
				return ObjectUtil.stringCompare(a as String, b as String);
			if (a is Date && b is Date)
				return ObjectUtil.dateCompare(a as Date, b as Date);
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
		 * @see mx.utils.ObjectUtil#compare
		 */
		public function beginSort(arrayToSort:*, compareFunction:Function = null):void
		{
			// initialize
			compare = compareFunction || defaultCompare;
			original = arrayToSort;
			source = original;
			length = original.length;
			
			// make a buffer of the same type and length
			var Type:Class = (source as Object).constructor;
			destination = new Type();
			destination.length = length;
			
			subArraySize = 1;
			middle = 0;
			end = 0;
			elapsed = 0;
			
			if (_immediately)
			{
				iterate(int.MAX_VALUE);
				done();
			}
			else
			{
				WeaveAPI.StageUtils.startTask(this, iterate, WeaveAPI.TASK_PRIORITY_BUILDING, done);
			}
		}
		
		private function iterate(stopTime:int):Number
		{
			var time:int = getTimer();
			
			while (getTimer() < stopTime)
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
			
			elapsed += getTimer() - time;
			
			// if one sub-array includes the entire array, we're done
			if (subArraySize >= length)
			{
				// source array is completely sorted
				if (source != original) // if source isn't the original
				{
					// copy the sorted values to the original
					for (var i:int = length - 1; i >= 0; i--)
						original[i] = source[i];
				}
				
				// clean up so the "get result()" function knows we're done
				source = null;
				destination = null;
				
				return 1; // done
			}
			
			//TODO: improve progress calculation
			return subArraySize / length; // not exactly accurate, but returns a number < 1
		}
		
		private function done():void
		{
			if (debug)
			{
				var sec:Number = elapsed/1000;
				if (sec > 1)
					trace('sort',result.length,'in',sec,'seconds');
			}
			
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/*************
		 ** Testing **
		 *************/
		
		//test(true); // Class('weave.utils.AsyncSort').test(false)
		/*
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
		public static function test(useDefaultSort:Boolean):void
		{
			for each (var n:uint in [0,1,50,3000,6000,12000,25000,50000])
			{
				var array:Array = [];
				for (var i:int = 0; i < n; i++)
					array.push(Math.random() < .5 ? NaN : uint(Math.random()*100));
				var array2:Array = array.concat();
				
				var start:int = getTimer();
				_debugCompareCount = 0;
				if (useDefaultSort)
					array.sort();
				else
					array.sort(_debugCompare);
				trace('Array.sort', n, 'numbers;', (getTimer() - start) / 1000, 'seconds;',_debugCompareCount,'comparisons');
				
				start = getTimer();
				_debugCompareCount = 0;
				if (useDefaultSort)
					sortImmediately(array2);
				else
					sortImmediately(array2, _debugCompare);
				//trace('Merge Sort', n, 'numbers;', _immediateSorter.elapsed / 1000, 'seconds;',_debugCompareCount,'comparisons');
				trace('Merge Sort', n, 'numbers;', (getTimer() - start) / 1000, 'seconds;',_debugCompareCount,'comparisons');
				
				if (array2.length == 1 && ObjectUtil.compare(array[0],array2[0]) != 0)
					throw new Error("sort failed on array length 1");
				
				verifyNumbersSorted(array2);
			}
		}
		private static function verifyNumbersSorted(array:Array):void
		{
			for (var i:int = 1; i < array.length; i++)
			{
				if (ObjectUtil.numericCompare(array[i - 1], array[i]) > 0)
				{
					throw new Error("ASSERTION FAIL " + array[i - 1] + ' > ' + array[i]);
				}
			}
		}
		private static var _debugCompareCount:int = 0;
		private static function _debugCompare(a:Object, b:Object):int
		{
			_debugCompareCount++;
			return ObjectUtil.compare(a, b);
		}
	}
}
