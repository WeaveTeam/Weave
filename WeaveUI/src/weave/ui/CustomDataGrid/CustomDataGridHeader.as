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
	import flash.events.MouseEvent;
	
	import mx.controls.dataGridClasses.DataGridHeader;

	/**
	 * This fixes the bug where mouseUp triggers a sort even if we didn't receive a mouseDown event.
	 * 
	 * @author adufilie
	 */	
	public class CustomDataGridHeader extends DataGridHeader
	{
		public function CustomDataGridHeader()
		{
			addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
		}
		
		private var _shouldHandleMouseUp:Boolean = false;
		
		protected function rollOverHandler(event:MouseEvent):void
		{
			_shouldHandleMouseUp = false;
		}
		override protected function mouseDownHandler(event:MouseEvent):void
		{
			_shouldHandleMouseUp = true;
			
			super.mouseDownHandler(event);
		}
		override protected function mouseUpHandler(event:MouseEvent):void
		{
			if (_shouldHandleMouseUp)
				super.mouseUpHandler(event);
		}
	}
}
