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
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.mx_internal;
	
	import weave.Weave;
	import weave.api.core.ILinkableObject;
	import weave.data.KeySets.KeySet;

	use namespace mx_internal;	                          

	/**
	 * This is a wrapper around a DataGrid to fix a bug with the mx_internal addMask() function
	 * which was introduced in Flex 3.6 SDK. The issue is the lockedColumnContent is instantiated
	 * and contains invalid data when the lockedColumnCount is 0. 
	 * 
	 * @author kmonico
	 */	
	public class CustomDataGrid extends DataGrid implements ILinkableObject
	{
		
		public function CustomDataGrid()
		{
			super();			
		}
		
		
		
		/**
		 * There's a bug in Flex 3.6 SDK where the locked column content may not be updated
		 * at the same time as the listItems for the DataGrid. This is an issue because they
		 * could have different lengths, and thus cause a null reference error.
		 * 
		 * @param layoutChanged If the layout changed.
		 */			
		override mx_internal function addClipMask(layoutChanged:Boolean):void
		{
			if (lockedColumnCount == 0)
				lockedColumnContent = null; // this should be null if there are no locked columns
			
			super.addClipMask(layoutChanged);
		}
		
		public static const VERTICAL_SCROLL:String = "Vertical";
		public static const HORIZONTAL_SCROLL:String = "Horizontal";
		public function getScrollWidth(scrollBar:String):int
		{
			if (scrollBar == VERTICAL_SCROLL && verticalScrollBar)
			{
				return verticalScrollBar.getExplicitOrMeasuredWidth();
			}
			else if (scrollBar == HORIZONTAL_SCROLL && horizontalScrollBar)
			{
				return horizontalScrollBar.getExplicitOrMeasuredWidth();
			}			
			return 0;
		}
		
		
		
		
		public function invalidateFilters():void
		{
			_filtersInvalid = true;
			invalidateProperties();
		}
		private var _filtersInvalid:Boolean = false;
		
		override protected function commitProperties():void
		{
			if (_filtersInvalid)
			{ 
				_filtersInvalid = false;
				updateFilterFunctions();
				resultKeys = [];
				collection.filterFunction = callAllFilterFunctions;
				//refresh call the respective function(**callAllFilterFunctions**) through internalrefresh in listCollectionView 
				collection.refresh();
				handleCollectionRefresh();
			}
			super.commitProperties();
		}
		
		protected var columnFilterFunctions:Array;
		
		//consequnce of change in --activateFilters-- through **commit properties** method
		//fills --columnFilterFunctions--
		protected function updateFilterFunctions():void
		{
			var cff:Array = [];
			for each (var column:DataGridColumn in columns)
			{
				if (column is WeaveCustomDataGridColumn)
				{
					var mc:WeaveCustomDataGridColumn = WeaveCustomDataGridColumn(column);					
					if (mc.filterComponent)
					{
						var filter:IFilterComponent = mc.filterComponent;
						if(filter.isActive)
							cff.push(filter.filterFunction);
					}						
				}
			}
			columnFilterFunctions = cff;
		}
		
		
		private var resultKeys:Array = [];		
		
		/**
		 * This function is a logical AND of all functions in --columnFilterFunctions--
		 * on each record filterFunctions are applied through 
		 * **commitProperties** -> listcollectionview.refresh -> internalrefresh -> callAllfilterFunction through reference
		 */		
		protected function callAllFilterFunctions(key:Object):Boolean
		{
			for each (var cff:Function in columnFilterFunctions)
			{
				if (!cff(key))
					return false;
			}			
			resultKeys.push(key);		
			return true;
		}
		//executes after iteration on callAllFilterFunctions by all the datagrid records
		private function handleCollectionRefresh():void
		{			
			var filteredKeySet:KeySet = Weave.root.getObject(Weave.DEFAULT_SELECTION_KEYSET) as KeySet;
			filteredKeySet.replaceKeys(resultKeys);			
		}
		
	}
}