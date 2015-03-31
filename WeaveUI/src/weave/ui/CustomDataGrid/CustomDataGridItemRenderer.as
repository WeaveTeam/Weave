/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

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
