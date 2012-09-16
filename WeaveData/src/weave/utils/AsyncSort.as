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
			compare = compareFunction || ObjectUtil.compare;
		}
		
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
		
		/**
		 * This will begin an asynchronous sorting operation on the specified Array.
		 * Only one sort operation can be carried out at a time.
		 * Callbacks will be triggered when the sorting operation completes.
		 * The given Array will be modified in-place, but there is no guarantee that the result will be the same Array.
		 * @param arrayToSort The Array to sort.
		 */
		public function beginSort(arrayToSort:*):void
		{
			// initialize
			array = arrayToSort;
			length = array.length;
			buffer.length = length;
			size = 1;
			end = 0;
			merging = false;
			
			WeaveAPI.StageUtils.startTask(this, iterate, WeaveAPI.TASK_PRIORITY_BUILDING, done);
		}
		
		private function iterate(stopTime:int):Number
		{
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
							return 1; // done
						
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
			
			return size / length; // not exactly accurate, but returns a number < 1
		}
		
		private function done():void
		{
			getCallbackCollection(this).triggerCallbacks();
		}
		
		private static var testSorter:AsyncSort;
		//test(); // Class('weave.utils.AsyncSort').test()
		public static function test(n:uint = 100000):void
		{
			var start:int;
			testSorter = new AsyncSort();
			function handleSort():void
			{
				trace(getTimer() - start, 'ms async');
				trace('VERIFYING ASYNC SORT');
				var result:Array = testSorter.result;
				for (var i:int = 0; i < result.length - 1; i++)
				{
					if (result[i] > result[i+1])
						throw new Error("ASSERTION FAIL "+result[i]+','+result[i+1]);
				}
				trace('SUCCESS');
			}
			getCallbackCollection(testSorter).addImmediateCallback(null, handleSort);
			
			var array:Array = [];
			for (var i:int = 0; i < n; i++)
				array.push(uint(Math.random()*100));
			var array2:Array = ObjectUtil.copy(array) as Array;
			
			trace('sorting',n,'numbers...');
			start = getTimer();
			array.sort();
			trace(getTimer() - start, 'ms immediate');
			
			start = getTimer();
			testSorter.beginSort(array2);
		}
	}
}
