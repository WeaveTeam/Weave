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
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.data.KeySets.SortedKeySet;
	
	public class DataGridColumnForQKey extends DataGridColumn
	{
		public function DataGridColumnForQKey(attrColumn:IAttributeColumn)
		{
			this.attrColumn = attrColumn;
			
			labelFunction = _labelFunction;
			sortCompareFunction = SortedKeySet.generateCompareFunction([attrColumn]);
			headerWordWrap = true;
			
			this.minWidth = 0;
		}
		
		public var attrColumn:IAttributeColumn = null;
		
		private function _labelFunction(item:Object, column:DataGridColumn):String
		{
			return attrColumn.getValueFromKey(item as IQualifiedKey, String) as String;
		}
	}
}