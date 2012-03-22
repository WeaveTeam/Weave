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
