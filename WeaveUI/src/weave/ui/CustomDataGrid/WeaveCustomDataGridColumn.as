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
	import mx.controls.Label;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.ClassFactory;
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.core.LinkableBoolean;
	import weave.data.AttributeColumns.ImageColumn;
	import weave.utils.ColumnUtils;
	
	public class WeaveCustomDataGridColumn extends DataGridColumn
	{
		public function WeaveCustomDataGridColumn(attrColumn:IAttributeColumn, showColors:LinkableBoolean, colorFunction:Function)
		{
			_attrColumn = attrColumn;
			labelFunction = extractDataFunction;
			sortCompareFunction = ColumnUtils.generateSortFunction([_attrColumn]);
			headerWordWrap = true;
			
			var factory:ClassFactory = new ClassFactory(DataGridCellRenderer);
			factory.properties = {
				attrColumn: attrColumn,
				showColors: showColors,
				colorFunction: colorFunction,
				keySet: Weave.root.getObject(Weave.DEFAULT_SELECTION_KEYSET)
			};
			this.itemRenderer = factory;
			
			this.showDataTips = true;
			//this.width = 20;
			this.minWidth = 0;	
			
			_attrColumn.addImmediateCallback(this, handleColumnChange, true);						
		}
		
		protected var _filterComponent:IFilterComponent;	
		public function get filterComponent():IFilterComponent
		{
			return _filterComponent;
		}
		
		public function set filterComponent(filterComp:IFilterComponent):void
		{				
			if (filterComp)
			{
				_filterComponent = filterComp;
				_filterComponent.mapColumnToFilter(this);		
			}			
		}
		
		private var _attrColumn:IAttributeColumn = null;
		public function get attrColumn():IAttributeColumn
		{
			return _attrColumn;
		}
		
		private function handleColumnChange():void
		{
			headerText = ColumnUtils.getTitle(_attrColumn);
		}
		
		private function extractDataFunction(item:Object, column:DataGridColumn):String
		{
			return _attrColumn.getValueFromKey(item as IQualifiedKey, String) as String;
		}
	}
}