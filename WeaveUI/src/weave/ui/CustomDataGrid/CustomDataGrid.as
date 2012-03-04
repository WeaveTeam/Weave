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
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.controls.listClasses.ListBaseContentHolder;
	import mx.controls.scrollClasses.ScrollBar;
	import mx.core.mx_internal;
	import mx.managers.LayoutManager;
	
	import weave.Weave;
	import weave.api.data.IQualifiedKey;
	import weave.data.KeySets.KeyFilter;
	import weave.data.KeySets.KeySet;
	
	
	use namespace mx_internal;	                          
	
	/**
	 * This is a wrapper around a DataGrid to fix a bug with the mx_internal addMask() function
	 * which was introduced in Flex 3.6 SDK. The issue is the lockedColumnContent is instantiated
	 * and contains invalid data when the lockedColumnCount is 0. 
	 * 
	 * @author kmonico
	 */	
	public class CustomDataGrid extends DataGrid
	{
		
		public function CustomDataGrid()
		{
			super();			
		}
		override protected function setupColumnItemRenderer(c:DataGridColumn, contentHolder:ListBaseContentHolder, rowNum:int, colNum:int, data:Object, uid:String):IListItemRenderer{
			return super.setupColumnItemRenderer(c,contentHolder,rowNum,colNum,data,uid);
		}
	
		override protected function updateList():void{
			super.updateList();
		}
		override protected function drawSelectionIndicator(indicator:Sprite, x:Number, y:Number, width:Number, height:Number, color:uint, itemRenderer:IListItemRenderer):void
		{
			super.drawSelectionIndicator(indicator,x,y,width,height,color,itemRenderer);
		}
		override  public function set lockedColumnCount(value:int):void
		{ 
			
			super.lockedColumnCount = value;
			/*if(value == 0){
				invalidateProperties();
			}*/
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
				
		public function getColumnDisplayWidth():Number
		{
			var columnDisplayWidth:Number = this.width - this.viewMetrics.right - this.viewMetrics.left;		
			return columnDisplayWidth;
		}
		
		private var _filtersEnabled:Boolean = false;
		
		public function set enableFilters(val:Boolean):void{
			_filtersEnabled = val;
			invalidateFilters();
		}
		
		
		public function invalidateFilters():void
		{	
			_filtersInValid = true;	
			invalidateDisplayList();
		}
		private var _filtersInValid:Boolean = false;
		
		private var selectedKeySet:KeySet = Weave.root.getObject(Weave.DEFAULT_SELECTION_KEYSET) as KeySet;
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (_filtersInValid)
			{ 
				_filtersInValid = false;	
				if(_filtersEnabled){
					filteredKeys = [];
					collection.filterFunction = callAllFilterFunctions;
					//refresh call the respective function(**callAllFilterFunctions**) through internalrefresh in listCollectionView 
					collection.refresh();				
					selectedKeySet.replaceKeys(filteredKeys);
				}				
				else{					
					collection.filterFunction = filterKeys;
					collection.refresh();
					selectedKeySet.replaceKeys([]);
				}
			}			
		}
		
		/*********************************************** Filters Section***************************************************/
		
	
		
		// contains keys filtered by filterfunctions in each WeaveCustomDataGridColumn
		private var filteredKeys:Array = [];		
		
		/**
		 * This function is a logical AND of each WeaveCustomDataGridColumn filter function
		 * Called by following sequnce of Function
		 * commitProperties -> listcollectionview.refresh -> internalrefresh -> callAllfilterFunction through reference
		 */		
		protected function callAllFilterFunctions(key:Object):Boolean
		{
			var columnFilterFunctions:Array = getAllFilterFunctions();
			for each (var cff:Function in columnFilterFunctions)
			{
				if (!cff(key))
					return false;
			}			
			filteredKeys.push(key);		
			return true;
		}
				
		
		//Collects all filterfunctions associated with each WeaveCustomDataGridColumn
		// returns those filter functions as Array
		protected function getAllFilterFunctions():Array
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
			return  cff;
		}
		
		/*********************************************** Subset Section***************************************************/
		
		private var _subset:KeyFilter = Weave.root.getObject(Weave.DEFAULT_SUBSET_KEYFILTER) as KeyFilter;
		
		private function filterKeys(item:Object):Boolean
		{
			if(_subset.containsKey(item as IQualifiedKey))
				return true;
			else 
				return false;
		}
		
		
	}
}