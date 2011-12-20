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

package weave.ui
{
	import flash.events.Event;
	import flash.system.Capabilities;
	
	import mx.collections.CursorBookmark;
	import mx.controls.ColorPicker;
	import mx.controls.ComboBox;
	import mx.events.FlexEvent;

	/**
	 * Added functionality: The same selectedColor can be selected again with the popup.
	 * 
	 * @author adufilie
	 */
	public class CustomColorPicker extends ColorPicker
	{
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			// This makes it so the same color can be selected again while still triggering a change event.
			super.selectedColor = super.selectedColor | 0x1000000;
		}
		
		override public function get selectedColor():uint
		{
			return super.selectedColor & 0xFFFFFF;
		}
		override public function set selectedColor(value:uint):void
		{
			super.selectedColor = value;
			
			// This makes it so the same color can be selected again while still triggering a change event.
			super.selectedColor = super.selectedColor | 0x1000000;
		}
	}
}
