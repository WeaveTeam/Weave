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
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.mx_internal;
	
	import weave.Weave;
	import weave.api.data.IQualifiedKey;
	import weave.data.KeySets.KeySet;
	
	use namespace mx_internal;	                          
	
	public class CustomDataGridWithFilters extends CustomDataGrid
	{
		public function CustomDataGridWithFilters()
		{
			super();
		}

		// need to set default filter when user sets the dataprovider
		override public function set dataProvider(value:Object):void
		{
			super.dataProvider = value;
			collection.filterFunction = filterKeys;
			collection.refresh();
		}

		private var _filtersEnabled:Boolean = false;
		
		public function set enableFilters(val:Boolean):void
		{
			if(_filtersEnabled != val)
			{
				_filtersEnabled = val;
				invalidateFilters();
			}			
		}
		
		public function invalidateFilters():void
		{
			_filtersInValid = true;	
			invalidateDisplayList();
		}
		private var _filtersInValid:Boolean = true;
		
		private var selectedKeySet:KeySet = Weave.defaultSelectionKeySet;
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (_filtersInValid)
			{ 
				_filtersInValid = false;	
				if(_filtersEnabled){
					filteredKeys = [];
					filterContainsAllKeys = true;
					columnFilterFunctions = getAllFilterFunctions();
					collection.filterFunction = callAllFilterFunctions;
					//refresh call the respective function(**callAllFilterFunctions**) through internalrefresh in listCollectionView 
					collection.refresh();
					if (filterContainsAllKeys)
						selectedKeySet.clearKeys();
					else
						selectedKeySet.replaceKeys(filteredKeys);
					filteredKeys = null;
				}				
				else{					
					collection.filterFunction = filterKeys;
					collection.refresh();
					selectedKeySet.clearKeys();
				}
			}			
		}
		
		// contains keys filtered by filterfunctions in each WeaveCustomDataGridColumn
		private var filteredKeys:Array;		
		private var columnFilterFunctions:Array;
		private var filterContainsAllKeys:Boolean;
		
		/**
		 * This function is a logical AND of each WeaveCustomDataGridColumn filter function
		 * Called by following sequnce of Function
		 * commitProperties -> listcollectionview.refresh -> internalrefresh -> callAllfilterFunction through reference
		 */		
		protected function callAllFilterFunctions(key:Object):Boolean
		{
			for each (var cff:Function in columnFilterFunctions)
				if (!cff(key))
					return filterContainsAllKeys = false;
			if (filteredKeys)
				filteredKeys.push(key);
			return true;
		}
				
		
		//Collects all filterfunctions associated with each WeaveCustomDataGridColumn
		// returns those filter functions as Array
		protected function getAllFilterFunctions():Array
		{
			var cff:Array = [filterKeys];
			for each (var column:DataGridColumn in columns)
			{
				if (column is CustomDataGridColumn)
				{
					var mc:CustomDataGridColumn = CustomDataGridColumn(column);					
					if (mc.filterComponent)
					{
						var filter:IFilterComponent = mc.filterComponent;
						if(filter.isActive)
							cff.push(filter.filterFunction);
					}						
				}
			}
			return  cff;
		}
	
		private function filterKeys(item:Object):Boolean
		{
			if(Weave.defaultSubsetKeyFilter.containsKey(item as IQualifiedKey))
				return true;
			else 
				return false;
		}
		
		
	}
}