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
	import mx.core.ClassFactory;
	
	import weave.Weave;
	import weave.api.core.IDisposableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.registerDisposableChild;
	import weave.core.LinkableBoolean;
	import weave.data.KeySets.KeySet;
	import weave.utils.ColumnUtils;
	
	public class DataGridColumnForQKeyWithFilterAndGraphics extends DataGridColumnForQKey implements IDisposableObject
	{
		public function DataGridColumnForQKeyWithFilterAndGraphics(attrColumn:IAttributeColumn, showColors:LinkableBoolean, colorFunction:Function)
		{
			super(attrColumn);
			this.showColors = showColors;
			this.colorFunction = colorFunction;
			this.itemRenderer = new ClassFactory(DataGridQKeyRendererWithGraphics);
			
			registerDisposableChild(attrColumn, this);
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
		 * This function should have the following signature: function(column:IAttributeColumn, key:IQualifiedKey, cell:UIComponent):Number
		 * The return value should be a color, or NaN for no color.
		 */
		public var colorFunction:Function = null;
		public var selectionKeySet:KeySet = Weave.defaultSelectionKeySet;
		public var probeKeySet:KeySet = Weave.defaultProbeKeySet;
		public var showColors:LinkableBoolean = null;
		
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
	}
}