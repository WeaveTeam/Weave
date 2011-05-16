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
	 * VectorUtils
	 * This class contains static functions that manipulate Vector objects.
	 * 
	 * @author adufilie
	 * @author abaumann
	 */
	public class VectorUtils
	{
		// Vector.<*> causes compiler errors, so use *
		/**
		 * copyList
		 * This function copies the contents of the source to the destination.
		 * Either parameter may be either an Array or a Vector.
		 * @return A pointer to the destination Array (or Vector)
		 */
		public static function copy(source:*, destination:*):*
		{
			destination.length = source.length;
			for (var i:int = source.length - 1; i >= 0; i--)
				destination[i] = source[i];
			return destination;
		}
		/**
		 * appends the contents of the additionalValuesVector to the destionationVector
		 * returns a pointer to the destinationVector
		 */
		public static function append(destinationVector:*, additionalValuesVector:*):*
		{
			destinationVector.length += additionalValuesVector.length;
			var destinationIndex:int = destinationVector.length - 1;
			var additionalValueIndex:int = additionalValuesVector.length - 1;
			while (additionalValueIndex >= 0)
				destinationVector[destinationIndex--] = additionalValuesVector[additionalValueIndex--];
			return destinationVector;
		}
		
		/**
		 * compares two vectors to see if their contents are equal.
		 */
		public static function compare(vector1:*, vector2:*):Boolean
		{
			try
			{
				if(vector1.length != vector2.length)
					return false;	
			
				for (var i:int = 0; i < vector1.length; i++)
				{
					if(vector1[i] != vector2[i])
						return false;	
				}
				
				return true;
			}
			catch (error:Error)
			{
				return false;
			}
			
			return false;
		}
		/**
		 * copies the contents of the XMLList to the Vector
		 * returns a pointer to the same Vector
		 */
		public static function copyXMLListToVector(xmlList:*, vector:*=null):*
		{
			if(vector == null)
				vector = new Vector.<String>();
			
			if (xmlList == null)
			{
				vector.length = 0;
			}
			else
			{
				vector.length = (xmlList is XMLList ? xmlList.length() : xmlList.length);
				
				for (var i:int = vector.length - 1; i >= 0; i--)
					vector[i] = xmlList[i];
			}
			return vector;
		}
		/**
		 * Efficiently removes duplicate adjacent items in a pre-sorted Array (or Vector).
		 * @param vector The sorted Array (or Vector)
		 * @return A pointer to the same Array (or Vector)
		 */
		public static function removeDuplicatesFromSortedArray(vector:*):*
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
			return vector;
		}
		/**
		 * standard '<' and '>' comparing objects, can be used for Vector sorting
		 */
		public static function standardCompare(x:*, y:*):Number
		{
			if (x < y)
				return -1;
			if (x > y)
				return 1;
			return 0;
		}
		/**
		 * randomSort
		 * randomizes the order of the elements in the vector in O(n) time by modifying the given array.
		 * @param the vector to randomize
		 * @return the input vector
		 */
		public static function randomSort(vector:*):*
		{
			var ptr:*;
			var j:int;
			var length:int = vector.length;
			// loop through all index values 0 <= i < length
			for (var i:int = length - 1; i >= 0; i--)
			{
				// randomly choose index j
				j = Math.floor(Math.random() * length);
				// swap elements i and j
				ptr = vector[i];
				vector[i] = vector[j];
				vector[j] = ptr;
			}
			return vector;
		}

		/**
		 * partition
		 * See http://en.wikipedia.org/wiki/Quick_select#Partition-based_general_selection_algorithm
		 * @param list An Array or Vector to be re-organized
		 * @param firstIndex The index of the first element in the list to partition.
		 * @param lastIndex The index of the first element in the list to partition.
		 * @param pivotIndex The index of an element to use as a pivot when partitioning.
		 * @param compareFunction A function that takes two array elements a,b and returns -1 if a<b, 1 if a>b, or 0 if a==b.
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
					// swap elements at storeIndex and i
					temp = list[storeIndex];
					list[storeIndex] = list[i];
					list[i] = temp;
					storeIndex++;
				}
			}
			// Move pivot to its final place
			temp = list[storeIndex];
			list[storeIndex] = list[lastIndex];
			list[lastIndex] = temp;
			// everything to the left of storeIndex is < pivot element
			// everything to the right of storeIndex is >= pivot element
			return storeIndex;
		}

		/**
		 * getMedianIndex
		 * See http://en.wikipedia.org/wiki/Quick_select#Partition-based_general_selection_algorithm
		 * @param list An Array or Vector to be re-organized.
		 * @param compareFunction A function that takes two array elements a,b and returns -1 if a<b, 1 if a>b, or 0 if a==b.
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
			var k:int = (left + right) / 2;
			var pivotIndex:int;
			while (true)
			{
				pivotIndex = (left + right) / 2; 
				// pivotIndex could be random, if desired
				//pivotIndex = left + Math.random() * right - left;
				pivotIndex = partition(list, left, right, pivotIndex, compareFunction);
				if (k == pivotIndex)
					return k;
				if (k < pivotIndex)
					right = pivotIndex - 1;
				else
					left = pivotIndex + 1;
			}
			return -1;
		}

		/**
		 * mergeSorted
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
		 * flatten
		 * This will flatten an Array of Arrays into a flat Array.
		 * Items will be appended to the destination Array.
		 * @param source An Array to flatten.
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
				if (source[i] is Array)
					flatten(source[i], destination);
				else
					destination.push(source[i]);
			return destination;
		}
		
		/*
		trace(VectorUtils.copy(["Abc","aAc","abb","Aab"],new Vector.<String>()).sort(0));
		trace(VectorUtils.copy(["Abc","aAc","abd","Aab"],new Vector.<String>()).sort(Array.CASEINSENSITIVE));
		*/
	}
}
