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

package weave.ui.CustomDataGrid
{
	import mx.collections.ISort;
	import mx.collections.Sort;
	
	import weave.compiler.StandardLib;
	import weave.utils.AsyncSort;

	public class CustomSort implements ISort
	{
		public function CustomSort(actualSort:ISort)
		{
			_sort = actualSort || new Sort();
		}
		
		private var _sort:ISort;
		
		public function get compareFunction():Function { return _sort.compareFunction; }
		public function set compareFunction(value:Function):void { _sort.compareFunction = value; }
		public function get fields():Array { return _sort.fields; }
		public function set fields(value:Array):void { _sort.fields = value; }
		public function get unique():Boolean { return _sort.unique; }
		public function set unique(value:Boolean):void { _sort.unique = value; }
		public function findItem(
			items:Array,
			values:Object,
			mode:String,
			returnInsertionIndex:Boolean = false,
			compareFunction:Function = null):int
		{
			return _sort.findItem(items, values, mode, returnInsertionIndex, compareFunction);
		}
		public function propertyAffectsSort(property:String):Boolean { return _sort.propertyAffectsSort(property); }
		public function reverse():void { _sort.reverse(); }
		
		private function fixedCompareFunction(a:Object, b:Object):int
		{
			return _sort.compareFunction(a, b, _sort.fields);
		}
		
		public function sort(items:Array):void
		{
			if (!items || items.length <= 1)
				return;
			
			if (unique)
				_sort.sort(items);
			else
			{
				// this will properly initialize _sort so fixedCompareFunction won't crash
				_sort.sort([items[0],items[1]]);
				
				StandardLib.sort(items, fixedCompareFunction);
			}
		}

	}
}