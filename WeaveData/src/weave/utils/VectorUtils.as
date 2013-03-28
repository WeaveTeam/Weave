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
	import mx.utils.ObjectUtil;
	
	/**
	 * This class contains static functions that manipulate Vectors and Arrays.
	 * Functions with * as parameter types support both Vector and Array.
	 * Vector.&lt;*&rt; is not used because it causes compiler errors.
	 * 
	 * @author adufilie
	 */
	public class VectorUtils
	{
		/**
		 * This function copies the contents of the source to the destination.
		 * Either parameter may be either an Array or a Vector.
		 * @return A pointer to the destination Array (or Vector)
		 */
		public static function copy(source:*, destination:*):*
		{
			destination.length = source.length;
			var i:int = source.length;
			while (i--)
				destination[i] = source[i];
			return destination;
		}
		/**
		 * Efficiently removes duplicate adjacent items in a pre-sorted Array (or Vector).
		 * @param vector The sorted Array (or Vector)
		 */
		public static function removeDuplicatesFromSortedArray(vector:*):void
		{
			var iEnd:int = vector.length;
			var iPrevWrite:int = 0; // always keep first item 
			var iRead:int = 1; // start by reading second item
			for (; iRead < iEnd; iRead++) // increment iRead unconditionally
			{
				// only copy current item if it is different from the previous
				if (vector[iPrevWrite] != vector[iRead])
					vector[++iPrevWrite] = vector[iRead];
			}
			if (iEnd > 0)
				vector.length = iPrevWrite + 1;
		}
		/**
		 * randomizes the order of the elements in the vector in O(n) time by modifying the given array.
		 * @param the vector to randomize
		 */
		public static function randomSort(vector:*):void
		{
			var length:int = vector.length;
			for (var i:int = length; i--;)
			{
				// randomly choose index j
				var j:int = Math.floor(Math.random() * length);
				// swap elements i and j
				var temp:* = vector[i];
				vector[i] = vector[j];
				vector[j] = temp;
			}
		}
		
		/**
		 * See http://en.wikipedia.org/wiki/Quick_select#Partition-based_general_selection_algorithm
		 * @param list An Array or Vector to be re-organized
		 * @param firstIndex The index of the first element in the list to partition.
		 * @param lastIndex The index of the last element in the list to partition.
		 * @param pivotIndex The index of an element to use as a pivot when partitioning.
		 * @param compareFunction A function that takes two array elements a,b and returns -1 if a&lt;b, 1 if a&gt;b, or 0 if a==b.
		 * @return The index the pivot element was moved to during the execution of the function.
		 */
		private static function partition(list:*, firstIndex:int, lastIndex:int, pivotIndex:int, compareFunction:Function):int
		{
			var temp:*;
			var pivotValue:* = list[pivotIndex];
			// Move pivot to end
			temp = list[pivotIndex];
			list[pivotIndex] = list[lastIndex];
			list[lastIndex] = temp;
			
			var storeIndex:int = firstIndex;
			for (var i:int = firstIndex; i < lastIndex; i++)
			{
				if (compareFunction(list[i], pivotValue) < 0)
				{
					if (storeIndex != i)
					{
						// swap elements at storeIndex and i
						temp = list[storeIndex];
						list[storeIndex] = list[i];
						list[i] = temp;
					}
					
					storeIndex++;
				}
			}
			if (storeIndex != lastIndex)
			{
				// Move pivot to its final place
				temp = list[storeIndex];
				list[storeIndex] = list[lastIndex];
				list[lastIndex] = temp;
			}
			// everything to the left of storeIndex is < pivot element
			// everything to the right of storeIndex is >= pivot element
			return storeIndex;
		}
		
		//testPartition()
		private static function testPartition():void
		{
			var list:Array = [3,7,5,8,2];
			var pivotIndex:int = partition(list, 0, list.length - 1, list.length/2, AsyncSort.defaultCompare);
			
			for (var i:int = 0; i < list.length; i++)
				if (i < pivotIndex != list[i] < list[pivotIndex])
					throw new Error('assertion fail');
		}
		
		/**
		 * See http://en.wikipedia.org/wiki/Quick_select#Partition-based_general_selection_algorithm
		 * @param list An Array or Vector to be re-organized.
		 * @param compareFunction A function that takes two array elements a,b and returns -1 if a&lt;b, 1 if a&gt;b, or 0 if a==b.
		 * @param firstIndex The index of the first element in the list to calculate a median from.
		 * @param lastIndex The index of the last element in the list to calculate a median from.
		 * @return The index the median element.
		 */
		public static function getMedianIndex(list:*, compareFunction:Function, firstIndex:int = 0, lastIndex:int = -1):int
		{
			var left:int = firstIndex;
			var right:int = (lastIndex >= 0) ? (lastIndex) : (list.length - 1);
			if (left >= right)
				return left;
			var medianIndex:int = (left + right) / 2;
			while (true)
			{
				var pivotIndex:int = partition(list, left, right, (left + right) / 2, compareFunction);
				if (medianIndex == pivotIndex)
					return medianIndex;
				if (medianIndex < pivotIndex)
					right = pivotIndex - 1;
				else
					left = pivotIndex + 1;
			}
			return -1;
		}

		/**
		 * Merges two previously-sorted arrays or vectors.
		 * @param sortedInputA The first sorted array or vector.
		 * @param sortedInputB The second sorted array or vector.
		 * @param mergedOutput A vector or array to store the merged arrays or vectors.
		 * @param comparator A function that takes two parameters and returns -1 if the first parameter is less than the second, 0 if equal, or 1 if the first is greater than the second.
		 */		
		public static function mergeSorted(sortedInputA:*, sortedInputB:*, mergedOutput:*, comparator:Function):void
		{
			var indexA:int = 0;
			var indexB:int = 0;
			var indexOut:int = 0;
			var lengthA:int = sortedInputA.length;
			var lengthB:int = sortedInputB.length;
			while (indexA < lengthA && indexB < lengthB)
				if (comparator(sortedInputA[indexA], sortedInputB[indexB]) < 0)
					mergedOutput[indexOut++] = sortedInputA[indexA++];
				else
					mergedOutput[indexOut++] = sortedInputB[indexB++];
			
			while (indexA < lengthA)
				mergedOutput[indexOut++] = sortedInputA[indexA++];
			
			while (indexB < lengthB)
				mergedOutput[indexOut++] = sortedInputB[indexB++];

			mergedOutput.length = indexOut;
		}

		/**
		 * This will flatten an Array of Arrays into a flat Array.
		 * Items will be appended to the destination Array.
		 * @param source A multi-dimensional Array to flatten.
		 * @param destination An Array or Vector to append items to.  If none specified, a new one will be created.
		 * @return The destination Array with all the nested items in the source appended to it.
		 */
		public static function flatten(source:Array, destination:* = null):*
		{
			if (destination == null)
				destination = [];
			if (source == null)
				return destination;

			for (var i:int = 0; i < source.length; i++)
				if (source[i] is Array || source[i] is Vector)
					flatten(source[i], destination);
				else
					destination.push(source[i]);
			return destination;
		}
		
		/**
		 * This will take an Array of Arrays of String items and produce a single list of String-joined items.
		 * @param arrayOfArrays An Array of Arrays of String items.
		 * @param separator The separator String used between joined items.
		 * @param includeEmptyItems Set this to true to include empty-strings and undefined items in the nested Arrays.
		 * @return An Array of String-joined items in the same order they appear in the nested Arrays.
		 */
		public static function joinItems(arrayOfArrays:Array, separator:String, includeEmptyItems:Boolean):Array
		{
			var maxLength:int = 0;
			var itemList:Array;
			for each (itemList in arrayOfArrays)
				maxLength = Math.max(maxLength, itemList.length);
			
			var result:Array = [];
			for (var itemIndex:int = 0; itemIndex < maxLength; itemIndex++)
			{
				var joinedItem:Array = [];
				for (var listIndex:int = 0; listIndex < arrayOfArrays.length; listIndex++)
				{
					itemList = arrayOfArrays[listIndex] as Array;
					var item:String = '';
					if (itemList && itemIndex < itemList.length)
						item = itemList[itemIndex] || '';
					if (item || includeEmptyItems)
						joinedItem.push(item);
				}
				result.push(joinedItem.join(separator));
			}
			return result;
		}
	}
}
