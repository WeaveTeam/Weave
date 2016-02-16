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
	/**
	 * This class contains static functions that manipulate Arrays.
	 * 
	 * @author adufilie
	 */
	public class ArrayUtils
	{
		private static var map_primitive_lookup:Object = new JS.Map();
		private static var map_object_lookup:Object = new JS.WeakMap();
		private static var _lookupId:int = 0;
		private static function _getLookup(key:*):*
		{
			var lookup:Object = key === null || typeof key !== 'object' ? map_primitive_lookup : map_object_lookup;
			return lookup.get(key);
		}
		private static function _setLookup(key:*, value:*):void
		{
			var lookup:Object = key === null || typeof key !== 'object' ? map_primitive_lookup : map_object_lookup;
			lookup.set(key, value);
		}
		
		/**
		 * Computes the union of the items in a list of Arrays. Can also be used to get a list of unique items in an Array.
		 * @param arrays A list of Arrays.
		 * @return The union of all the unique items in the Arrays in the order they appear.
		 */
		public static function union/*/<T>/*/(...arrays/*/<T[]>/*/):Array/*/<T>/*/
		{
			var result:Array = [];
			_lookupId++;
			for each (var array:* in arrays)
			{
				for each (var item:* in array)
				{
					if (_getLookup(item) !== _lookupId)
					{
						_setLookup(item, _lookupId);
						result.push(item);
					}
				}
			}
			return result;
		}
		
		
		/**
		 * Computes the intersection of the items in a list of two or more Arrays.
		 * @return The intersection of the items appearing in all Arrays, in the order that they appear in the first Array.
		 */
		public static function intersection/*/<T>/*/(firstArray:Array/*/<T>/*/, secondArray:Array/*/<T>/*/, ...moreArrays/*/<T[]>/*/):Array/*/<T>/*/
		{
			moreArrays.unshift(secondArray);
			
			var result:Array = [];
			var item:*;
			var lastArray:* = moreArrays.pop();
			
			_lookupId++;
			for each (item in lastArray)
				_setLookup(item, _lookupId);
			
			for each (var array:* in moreArrays)
			{
				for each (item in array)
					if (_getLookup(item) === _lookupId)
						_setLookup(item, _lookupId + 1);
				_lookupId++;
			}
			
			for each (item in firstArray)
				if (_getLookup(item) === _lookupId)
					result.push(item);
			
			return result;
		}
		
		/**
		 * Removes items from an Array.
		 * @param array An Array of items.
		 * @param itemsToRemove An Array of items to skip when making a copy of the array.
		 * @return A new Array containing the items from the original array except those that appear in itemsToRemove.
		 */
		public static function subtract/*/<T>/*/(array:Array/*/<T>/*/, itemsToRemove:Array/*/<T>/*/):Array/*/<T>/*/
		{
			var item:*;
			_lookupId++;
			for each (item in itemsToRemove)
				_setLookup(item, _lookupId);
			var result:Array = [];
			var i:int = 0;
			for each (item in array)
				if (_getLookup(item) !== _lookupId)
					result[i++] = item;
			return result;
		}
		
		/**
		 * This function copies the contents of the source to the destination.
		 * Either parameter may be either an Array.
		 * @param source An Array-like object.
		 * @param destination An Array.
		 * @return A pointer to the destination Array
		 */
		public static function copy/*/<T>/*/(source:Array/*/<T>/*/, destination:Array/*/<T>/*/ = null):Array/*/<T>/*/
		{
			if (!destination)
				destination = [];
			destination.length = source.length;
			for (var i:* in source)
				destination[i] = source[i];
			return destination;
		}
		/**
		 * Fills an Object with the keys from an Array.
		 */
		public static function fillKeys(output:/*/{[key:string]:boolean}/*/Object, keys:Array/*/<string>/*/):void
		{
			for each (var key:* in keys)
				output[key] = true;
		}

        /** 
         * If there are any properties of the Object, return false; else, return true.
         * @param hashMap The Object to test for emptiness.
         * @return A boolean which is true if the Object is empty, false if it has at least one property.
         */
        public static function isEmpty(object:Object):Boolean
        {
            for (var key:* in object)
                return false;
            return true;
        }
		
		/**
		 * Efficiently removes duplicate adjacent items in a pre-sorted Array.
		 * @param sorted The sorted Array
		 */
		public static function removeDuplicatesFromSortedArray(sorted:Array):void
		{
			var n:int = sorted.length;
			if (n == 0)
				return;
			var write:int = 0;
			var prev:* = sorted[0] === undefined ? null : undefined;
			for (var read:int = 0; read < n; ++read)
			{
				var item:* = sorted[read];
				if (item !== prev)
					sorted[write++] = prev = item;
			}
			sorted.length = write;
		}
		/**
		 * randomizes the order of the elements in the Array in O(n) time by modifying the given array.
		 * @param array the array to randomize
		 */
		public static function randomSort(array:Array):void
		{
			var i:int = array.length;
			while (i)
			{
				// randomly choose index j
				var j:int = Math.floor(Math.random() * i--);
				// swap elements i and j
				var temp:* = array[i];
				array[i] = array[j];
				array[j] = temp;
			}
		}
		
		/**
		 * See http://en.wikipedia.org/wiki/Quick_select#Partition-based_general_selection_algorithm
		 * @param list An Array to be re-organized
		 * @param firstIndex The index of the first element in the list to partition.
		 * @param lastIndex The index of the last element in the list to partition.
		 * @param pivotIndex The index of an element to use as a pivot when partitioning.
		 * @param compareFunction A function that takes two array elements a,b and returns -1 if a&lt;b, 1 if a&gt;b, or 0 if a==b.
		 * @return The index the pivot element was moved to during the execution of the function.
		 */
		private static function partition(list:Array, firstIndex:int, lastIndex:int, pivotIndex:int, compareFunction:Function):int
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
			var pivotIndex:int = partition(list, 0, list.length - 1, list.length/2, StandardLib.compare);
			
			for (var i:int = 0; i < list.length; i++)
				if (i < pivotIndex != list[i] < list[pivotIndex])
					throw new Error('assertion fail');
		}
		
		/**
		 * See http://en.wikipedia.org/wiki/Quick_select#Partition-based_general_selection_algorithm
		 * @param list An Array to be re-organized.
		 * @param compareFunction A function that takes two array elements a,b and returns -1 if a&lt;b, 1 if a&gt;b, or 0 if a==b.
		 * @param firstIndex The index of the first element in the list to calculate a median from.
		 * @param lastIndex The index of the last element in the list to calculate a median from.
		 * @return The index the median element.
		 */
		public static function getMedianIndex(list:Array, compareFunction:Function, firstIndex:int = 0, lastIndex:int = -1):int
		{
			var left:int = firstIndex;
			var right:int = (lastIndex >= 0) ? (lastIndex) : (list.length - 1);
			if (left >= right)
				return left;
			var medianIndex:int = int((left + right) / 2);
			while (true)
			{
				var pivotIndex:int = partition(list, left, right, int((left + right) / 2), compareFunction);
				if (medianIndex == pivotIndex)
					break;
				if (medianIndex < pivotIndex)
					right = pivotIndex - 1;
				else
					left = pivotIndex + 1;
			}
			return medianIndex;
		}

		/**
		 * Merges two previously-sorted arrays.
		 * @param sortedInputA The first sorted array.
		 * @param sortedInputB The second sorted array.
		 * @param mergedOutput An array to store the merged arrays.
		 * @param comparator A function that takes two parameters and returns -1 if the first parameter is less than the second, 0 if equal, or 1 if the first is greater than the second.
		 */		
		public static function mergeSorted/*/<T>/*/(sortedInputA:Array/*/<T>/*/, sortedInputB:Array/*/<T>/*/, mergedOutput:Array/*/<T>/*/, comparator:/*/(a:T,b:T)=>number/*/Function):void
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
		 * @param destination An Array to append items to.  If none specified, a new one will be created.
		 * @return The destination Array with all the nested items in the source appended to it.
		 */
		public static function flatten/*/<T>/*/(source:Array/*/<T>/*/, destination:Array/*/<T>/*/ = null):Array/*/<T>/*/
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
		
		public static function flattenObject(input:Object, output:Object = null, prefix:String = ''):Object
		{
			if (output == null)
				output = {};
			if (input == null)
				return output;
			
			for (var key:String in input)
				if (typeof input[key] == 'object')
					flattenObject(input[key], output, prefix + key + '.');
				else
					output[prefix + key] = input[key];
			return output;
		}
		
		/**
		 * This will take an Array of Arrays of String items and produce a single list of String-joined items.
		 * @param arrayOfArrays An Array of Arrays of String items.
		 * @param separator The separator String used between joined items.
		 * @param includeEmptyItems Set this to true to include empty-strings and undefined items in the nested Arrays.
		 * @return An Array of String-joined items in the same order they appear in the nested Arrays.
		 */
		public static function joinItems(arrayOfArrays:Array/*/<string[]>/*/, separator:String, includeEmptyItems:Boolean):Array/*/<string>/*/
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
		
		/**
		 * Performs a binary search on a sorted array with no duplicate values.
		 * @param sortedUniqueValues Array of Numbers or Strings
		 * @param compare A compare function
		 * @param exactMatchOnly If true, searches for exact match. If false, searches for insertion point.
		 * @return The index of the matching value or insertion point.
		 */
		public static function binarySearch(sortedUniqueValues:Array, item:*, exactMatchOnly:Boolean, compare:/*/(a:any,b:any)=>number/*/Function = null):int
		{
			var i:int = 0,
				imin:int = 0,
				imax:int = sortedUniqueValues.length - 1;
			while (imin <= imax)
			{
				i = int((imin + imax) / 2);
				var a:* = sortedUniqueValues[i];
				
				var c:int = compare != null ? compare(item, a) : (item < a ? -1 : (item > a ? 1 : 0));
				if (c < 0)
					imax = i - 1;
				else if (c > 0)
					imin = ++i; // set i for possible insertion point
				else
					return i;
			}
			return exactMatchOnly ? -1 : i;
		}
		
		/**
		 * Creates an object from arrays of keys and values.
		 * @param keys Keys corresponding to the values.
		 * @param values Values corresponding to the keys.
		 * @return A new Object.
		 */
		public static function zipObject/*/<T>/*/(keys:Array/*/<string>/*/, values:Array/*/<T>/*/):/*/{[key:string]:T}/*/Object
		{
			var n:int = Math.min(keys.length, values.length);
			var o:Object = {};
			for (var i:int = 0; i < n; i++)
				o[keys[i]] = values[i];
			return o;
		}
		
		/**
		 * This will get a subset of properties/items/attributes from an Object/Array/XML.
		 * @param object An Object/Array containing properties/items to retrieve.
		 * @param keys A list of property names, index values.
		 * @param output Optionally specifies where to store the resulting items.
		 * @return An Object (or Array) containing the properties/items/attributes specified by keysOrIndices.
		 */
		public static function getItems(object:/*/Object|any[]/*/*, keys:Array/*/<string>/*/, output:/*/Object|any[]/*/* = null):/*/Object|any[]/*/*
		{
			if (!output)
				output = object is Array ? [] : {};
			if (!object)
				return output;
			
			var keyIndex:*,
				keyValue:*,
				item:*;
			
			for (keyIndex in keys)
			{
				keyValue = keys[keyIndex];
				
				item = object[keyValue];
				
				if (output is Array)
					output[keyIndex] = item;
				else
					output[keyValue] = item;
			}
			if (output is Array)
				output.length = keys ? keys.length : 0;
			
			return output;
		}
		
		/**
		 * Compares a list of properties in two objects
		 * @param object1 The first object
		 * @param object2 The second object
		 * @param propertyNames A list of names of properties to compare
		 * @return -1, 0, or 1
		 */
		public static function compareProperties(object1:Object, object2:Object, propertyNames:Array/*/<string>/*/):int
		{
			for each (var name:String in propertyNames)
			{
				var result:int = StandardLib.compare(object1[name], object2[name]);
				if (result)
					return result;
			}
			return 0;
		}
		
		/**
		 * Removes items from an Array.
		 * @param array Array
		 * @param indices Array of numerically sorted indices to remove
		 */
		public static function removeByIndex(array:Array, indices:Array/*/<number>/*/):void
		{
			var n:int = array.length;
			var skipList:Array = union(indices);
			var iSkip:int = 0;
			var skip:int = skipList[0];
			var write:int = skip;
			for (var read:int = skip; read < n; ++read)
			{
				if (read == skip)
					skip = skipList[++iSkip];
				else
					array[write++] = array[read];
			}
			array.length = write;
		}
		
		/**
		 * Gets a list of values of a property from a list of objects.
		 * @param array An Array of Objects.
		 * @param property The property name to get from each object
		 * @return A list of the values of the specified property for each object in the original list.
		 */
		public static function pluck(array:Array, property:String):Array
		{
			_pluckProperty = property;
			return array.map(_pluck);
		}
		private static var _pluckProperty:String;
		private static function _pluck(item:Object, i:int, a:*):*
		{
			return item != null ? item[_pluckProperty] : undefined;
		}
		
		/**
		 * Transposes a two-dimensional table.
		 */
		public static function transpose/*/<T>/*/(table:Array/*/<T[]>/*/):Array/*/<T[]>/*/
		{
			var result:Array = [];
			for (var iCol:int = 0; iCol < table.length; iCol++)
			{
				var col:Array = table[iCol];
				for (var iRow:int = 0; iRow < col.length; iRow++)
				{
					var row:Array = result[iRow] || (result[iRow] = []);
					row[iCol] = col[iRow];
				}
			}
			return result;
		}
		
		/**
		 * Creates a lookup from item (or item property) to index. Does not consider duplicate items (or duplicate item property values).
		 * @param array An Array or Object
		 * @param propertyChain A property name or chain of property names to index on rather than the item itself.
		 * @return A reverse lookup Map.
		 */
		public static function createLookup(array:/*/any[]|{[key:string]:any}/*/*, ...propertyChain/*/<string>/*/):/*/Map<any,string>/*/Object
		{
			var lookup:Object = new JS.Map();
			for (var key:* in array)
			{
				var value:* = array[key];
				for each (var prop:String in propertyChain)
					value = value[prop];
				lookup[value] = key;
			}
			return lookup;
		}
	}
}
