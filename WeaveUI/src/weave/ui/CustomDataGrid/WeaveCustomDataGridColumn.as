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
	import mx.core.ClassFactory;
	
	import weave.Weave;
	import weave.api.core.IDisposableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.registerDisposableChild;
	import weave.core.LinkableBoolean;
	import weave.data.KeySets.KeySet;
	import weave.data.KeySets.SortedKeySet;
	import weave.utils.ColumnUtils;
	
	public class WeaveCustomDataGridColumn extends DataGridColumn implements IDisposableObject
	{
		public function WeaveCustomDataGridColumn(attrColumn:IAttributeColumn, showColors:LinkableBoolean, colorFunction:Function)
		{
			registerDisposableChild(attrColumn, this);
			
			this.attrColumn = attrColumn;
			this.showColors = showColors;
			this.colorFunction = colorFunction;
			
			labelFunction = extractDataFunction;
			sortCompareFunction = SortedKeySet.generateCompareFunction([attrColumn]);
			headerWordWrap = true;
			
			var factory:ClassFactory = new ClassFactory(DataGridCellRenderer);
			factory.properties = {column: this};
			this.itemRenderer = factory;
			
			this.minWidth = 0;
			
			attrColumn.addImmediateCallback(this, handleColumnChange, true);
		}
		
		public function dispose():void
		{
			attrColumn.removeCallback(handleColumnChange);
			attrColumn = null;
			selectionKeySet = null;
			showColors = null;
			filterComponent = null;
			colorFunction = null;
			
			sortCompareFunction = null;
			labelFunction = null;
			itemRenderer = null;
		}
		
		/**
		 * This function should take two parameters: function(column:IAttributeColumn, key:IQualifiedKey, cell:UIComponent):Number
		 * The return value should be a color, or NaN for no color.
		 */
		[Exclude] public var colorFunction:Function = null;
		[Exclude] public var selectionKeySet:KeySet = Weave.defaultSelectionKeySet;
		[Exclude] public var attrColumn:IAttributeColumn = null;
		[Exclude] public var showColors:LinkableBoolean = null;
		
		protected var _filterComponent:IFilterComponent;	
		public function get filterComponent():IFilterComponent
		{
			return _filterComponent;
		}
		
		public function set filterComponent(filterComp:IFilterComponent):void
		{				
			_filterComponent = filterComp;
			
			if (filterComp)
				_filterComponent.mapColumnToFilter(this);
		}
		
		private function handleColumnChange():void
		{
			headerText = ColumnUtils.getTitle(attrColumn);
		}
		
		private function extractDataFunction(item:Object, column:DataGridColumn):String
		{
			return attrColumn.getValueFromKey(item as IQualifiedKey, String) as String;
		}
	}
}