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

package weave.ui.CustomDataGrid
{
	import mx.collections.ISort;
	import mx.collections.Sort;
	
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
			if (unique)
				_sort.sort(items);
			else
				AsyncSort.sortImmediately(items, fixedCompareFunction);
		}

	}
}