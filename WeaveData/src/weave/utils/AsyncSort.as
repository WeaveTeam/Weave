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
		public function AsyncSort():void
		{
		}
		
		private static var _immediateSorter:AsyncSort;
		
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
		 * This is the sorted Array (or Vector), or null if the sort operation has not completed yet.
		 */
		public function get result():*
		{
			return size >= length ? array : null;
		}
		
		private var compare:Function;
		private var array:*;
		private var length:uint;
		private var size:uint;
		private var start:uint;
		private var middle:uint;
		private var end:uint;
		private var iLeft:uint;
		private var iRight:uint;
		private var iBuffer:uint;
		private var buffer:*;
		private var merging:Boolean;
		private var swapped:Boolean;
		private var elapsed:int;
		private var _immediately:Boolean = false;
		
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
			compare = compareFunction || ObjectUtil.compare;
			array = arrayToSort;
			length = array.length;
			
			// make a buffer of the same type and length
			var Type:Class = (array as Object).constructor;
			buffer = new Type();
			buffer.length = length;
			
			size = 1;
			middle = 0;
			end = 0;
			merging = false;
			elapsed = 0;
			swapped = false;
			
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
				if (iLeft < middle)
				{
					// copy smallest value to buffer
					if (iRight < end && compare(array[iRight], array[iLeft]) < 0)
						buffer[iBuffer++] = array[iRight++];
					else
						buffer[iBuffer++] = array[iLeft++];
				}
				else if (iRight < end)
				{
					buffer[iBuffer++] = array[iRight++];
				}
				else if (end >= length) // done merging all pairs of sub-arrays of current size
				{
					// swap sorted and unsorted arrays
					var sorted:* = buffer;
					buffer = array;
					array = sorted;
					swapped = !swapped; // keep track of whether or not this is the original array
					
					// start again from beginning of array
					size *= 2;
					end = 0;
					
					if (size >= length)
					{
						// we are done sorting.
						elapsed += getTimer() - time;
						if (swapped)
						{
							// buffer is the original, so copy the sorted values over from sorted array
							for (var i:int = length - 1; i >= 0; i--)
								buffer[i] = array[i];
							array = buffer;
						}
						buffer = null;
						return 1;
					}
				}
				else
				{
					// prepare for next merge
					start = end;
					middle = Math.min(start + size, length);
					end = Math.min(middle + size, length);
					iLeft = start;
					iRight = middle;
					iBuffer = start;
					merging = true;
				}
			}
			
			elapsed += getTimer() - time;
			
			if (length == 0)
				return 1;
			
			//TODO: improve progress calculation
			return size / length; // not exactly accurate, but returns a number < 1
		}
		
		private function done():void
		{
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/*************
		 ** Testing **
		 *************/		
		
		//test(); // Class('weave.utils.AsyncSort').test()
		public static function test():void
		{
			for each (var n:uint in [50,3000,6000,12000,25000,50000])
			{
				var array:Array = [];
				for (var i:int = 0; i < n; i++)
					array.push(uint(Math.random()*100));
				var array2:Array = array.concat();
				
				var start:int = getTimer();
				_debugCompareCount = 0;
				array.sort(_debugCompare);
				trace('Array.sort', n, 'numbers;', (getTimer() - start) / 1000, 'seconds;',_debugCompareCount,'comparisons');
				
				_debugCompareCount = 0;
				start = getTimer();
				sortImmediately(array2, _debugCompare);
				//trace('Merge Sort', n, 'numbers;', _immediateSorter.elapsed / 1000, 'seconds;',_debugCompareCount,'comparisons');
				trace('Merge Sort', n, 'numbers;', (getTimer() - start) / 1000, 'seconds;',_debugCompareCount,'comparisons');
				
				verifySorted(array2);
			}
		}
		private static function verifySorted(array:Array):void
		{
			for (var i:int = 1; i < array.length; i++)
			{
				if (array[i - 1] > array[i])
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
