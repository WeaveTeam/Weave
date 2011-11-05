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
	import flash.events.Event;
	
	import mx.controls.Label;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.ClassFactory;
	import mx.utils.ObjectUtil;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.data.AttributeColumns.ImageColumn;
	import weave.utils.ColumnUtils;
	import weave.visualization.tools.DataItemRenderer;
	
	public class WeaveDataGridImageColumn extends DataGridColumn
	{
		public static const COLUMN_NEEDS_UPDATE_EVENT:String = "WeaveDataGridColumn.COLUMN_NEEDS_UPDATE_EVENT";
		
		public function WeaveDataGridImageColumn(attrColumn:IAttributeColumn)
		{
			super();
			
			dataField = "key";
			labelFunction = extractDataFunction;
			sortCompareFunction = customSorter;
			headerWordWrap = true;
			if( attrColumn is ImageColumn )
			{
				var factory:ClassFactory = new ClassFactory( DataItemRenderer );
				factory.properties = { imageColumn: attrColumn };
				this.itemRenderer = factory;
				
				
			}
			else
				this.itemRenderer = new ClassFactory(HeatMapDataGridColumnRenderer);
			//this.headerRenderer = new ClassFactory(LockableHeaderRenderer);	
			
			this.dataTipField = "key";
			this.showDataTips = true;
			//this.width = 20;
			this.minWidth = 0;	
			
			_attrColumn = attrColumn;
			_attrColumn.addImmediateCallback(this, handleColumnChange);
			handleColumnChange();
		}
		
		private function customSorter(item1:Object, item2:Object):int
		{
			var data1:Object = _attrColumn.getValueFromKey(item1[dataField]);
			var data2:Object = _attrColumn.getValueFromKey(item2[dataField]);
			
			var dataCompare:int;
			if (data1 is String && data2 is String)
				dataCompare = ObjectUtil.stringCompare(data1 as String, data2 as String, true);
			else
				dataCompare = ObjectUtil.compare(data1, data2);
			return dataCompare || ObjectUtil.compare(item1[dataField], item2[dataField]);
		}
		
		private var _attrColumn:IAttributeColumn = null;
		public function get attrColumn():IAttributeColumn
		{
			return _attrColumn;
		}
		
		private function handleColumnChange():void
		{
			headerText = ColumnUtils.getTitle(_attrColumn);
			dispatchEvent(new Event(COLUMN_NEEDS_UPDATE_EVENT));
		}
		
		private function extractDataFunction(item:Object, column:DataGridColumn):String
		{
			var xml:XML = <data/>;
			
			var col:IAttributeColumn = _attrColumn;
			
			if(col is ImageColumn)
				xml.@norm = 0;
			else
				xml.@norm = ColumnUtils.getNorm(col, item[dataField] as IQualifiedKey);
			
			xml.@string = col.getValueFromKey(item[dataField] as IQualifiedKey, String) as String;
			
			return xml.toXMLString();
		}
	}
}