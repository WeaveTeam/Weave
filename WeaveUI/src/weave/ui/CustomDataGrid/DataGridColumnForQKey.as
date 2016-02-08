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
	import mx.controls.dataGridClasses.DataGridColumn;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.utils.ColumnUtils;
	
	public class DataGridColumnForQKey extends DataGridColumn
	{
		public function DataGridColumnForQKey(attrColumn:IAttributeColumn)
		{
			this.attrColumn = attrColumn;
			labelFunction = _labelFunction;
			headerWordWrap = true;
			this.minWidth = 0;
		}
		
		public var attrColumn:IAttributeColumn = null;
		
		override public function get headerText():String
		{
			return super.headerText || ColumnUtils.getTitle(attrColumn);
		}
		
		private function _labelFunction(item:Object, column:DataGridColumn):String
		{
			return attrColumn.getValueFromKey(item as IQualifiedKey, String) as String;
		}
	}
}
