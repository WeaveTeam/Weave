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
		/**
		 * @param compareFunction A function that compares two items and returns -1, 0, or 1.
		 * @see mx.utils.ObjectUtil#compare
		 */
		public function AsyncSort(compareFunction:Function = null):void
		{
			compare = compareFunction;
		}
		
		/**
		 * This function will sort an Array immediately and return the result.
		 * @param array An Array to sort.
		 * @return The sorted Array, which may or may not be the original array.
		 */		
		public static function sortImmediately(array:Array, compareFunction:Function = null):Array
		{
			if (!_immediateSorter)
				_immediateSorter = new AsyncSort();
			
			_immediateSorter._immediately = true;
			_immediateSorter.beginSort(array, compareFunction);
			_immediateSorter._immediately = false;
			return _immediateSorter.result;
		}
		
		private static var _immediateSorter:AsyncSort;
		
		/**
		 * This is the sorted Array, or null if the sort operation has not completed yet.
		 */
		public function get result():Array
		{
			return size >= length ? array : null;
		}
		
		private var compare:Function;
		private var array:Array;
		private var length:uint;
		private var size:uint;
		private var start:uint;
		private var middle:uint;
		private var end:uint;
		private var iLeft:uint;
		private var iRight:uint;
		private var iBuffer:uint;
		private var buffer:Array = [];
		private var merging:Boolean;
		private var elapsed:int;
		private var _immediately:Boolean = false;
		
		/**
		 * This will begin an asynchronous sorting operation on the specified Array.
		 * Only one sort operation can be carried out at a time.
		 * Callbacks will be triggered when the sorting operation completes.
		 * The given Array will be modified in-place, but there is no guarantee that the result will be the same Array.
		 * @param arrayToSort The Array to sort.
		 */
		public function beginSort(arrayToSort:*, compareFunction:Function = null):void
		{
			// initialize
			compare = compareFunction || compare || ObjectUtil.compare;
			array = arrayToSort;
			length = array.length;
			buffer.length = length;
			size = 1;
			end = 0;
			merging = false;
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
			breakReturn: while (true)
			{
				if (!merging)
				{
					if (getTimer() > stopTime)
						break breakReturn;
					
					if (end >= length)
					{
						// swap sorted and unsorted arrays
						var sorted:Array = buffer;
						buffer = array;
						array = sorted;
						
						// start again from beginning of array
						size *= 2;
						end = 0;
						
						if (size >= length)
						{
							elapsed += getTimer() - time;
							return 1; // done
						}
						
						continue;
					}
					
					// prepare for next merge
					start = end;
					middle = Math.min(start + size, length);
					end = Math.min(middle + size, length);
					iLeft = start;
					iRight = middle;
					iBuffer = start;
					merging = true;
				}
				
				// merge
				while (true)
				{
					if (getTimer() > stopTime)
						break breakReturn;
	
					// copy smallest value to buffer
					if (iLeft < middle)
					{
						if (iRight < end && compare(array[iRight], array[iLeft]) < 0)
							buffer[iBuffer++] = array[iRight++];
						else
							buffer[iBuffer++] = array[iLeft++];
					}
					else if (iRight < end)
						buffer[iBuffer++] = array[iRight++];
					else
						break;
				}
				
				merging = false;
			}
			
			elapsed += getTimer() - time;
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
		public static function test(n:uint = 50000):void
		{
			
			var array:Array = [];
			for (var i:int = 0; i < n; i++)
				array.push(uint(Math.random()*100));
			var array2:Array = ObjectUtil.copy(array) as Array;
			var array3:Array = ObjectUtil.copy(array) as Array;
			
			trace('Sorting',n,'numbers...');
			var start:int = getTimer();
			_debugCompareCount = 0;
			array.sort(_debugCompare);
			trace('built-in sort',(getTimer() - start) / 1000, 'seconds;',_debugCompareCount,'comparisons');
			
			_debugCompareCount = 0;
			_testSorter = new AsyncSort(_debugCompare);
			getCallbackCollection(_testSorter).addImmediateCallback(null, handleTestSort);
			_testSorter.beginSort(array3);
		}
		private static var _testSorter:AsyncSort;
		private static var _debugCompareCount:int = 0;
		private static function _debugCompare(a:Object, b:Object):int
		{
			_debugCompareCount++;
			return ObjectUtil.compare(a, b);
		}
		private static function handleTestSort():void
		{
			trace('async merge sort',_testSorter.elapsed/1000, 'seconds;',_debugCompareCount,'comparisons');
			trace('VERIFYING ASYNC SORT');
			for (var i:int = 0; i < _testSorter.result.length - 1; i++)
			{
				if (_testSorter.result[i] > _testSorter.result[i+1])
					throw new Error("ASSERTION FAIL "+_testSorter.result[i]+','+_testSorter.result[i+1]);
			}
			trace('SUCCESS');
		}
	}
}
