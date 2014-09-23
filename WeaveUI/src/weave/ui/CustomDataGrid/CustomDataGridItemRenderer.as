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
	import mx.controls.dataGridClasses.DataGridItemRenderer;
	import mx.controls.listClasses.BaseListData;
	
	/**
	 * Fixes a null pointer error in validateProperties().
	 */
	public class CustomDataGridItemRenderer extends DataGridItemRenderer
	{
		override public function validateProperties():void
		{
			var _listData:BaseListData = listData;
			if (_listData && !DataGrid(_listData.owner).columns[_listData.columnIndex])
			{
				// This will throw a null pointer error but we still want to call it to set invalidatePropertiesFlag = false.
				try {
					super.validateProperties();
				} catch (e:Error) { }
				
				text = " ";
				toolTip = null;
			}
			else
				super.validateProperties();
		}
	}
}
