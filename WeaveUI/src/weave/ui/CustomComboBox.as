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
	import flash.events.MouseEvent;
	
	import mx.collections.CursorBookmark;
	import mx.controls.ComboBox;

	/**
	 * Added functionality: set selectedLabel()
	 * 
	 * @author adufilie
	 */
	public class CustomComboBox extends ComboBox
	{
		public function CustomComboBox()
		{
			addEventListener(MouseEvent.MOUSE_DOWN, function(..._):void { setFocus(); });
		}
		
		/**
		 * This function will set the selectedItem corresponding to the given label.
		 * @param value The label of the item to select.
		 */
		[Bindable]
		public function set selectedLabel(value:String):void
		{
			// save current iterator bookmark
			var bookmark:CursorBookmark = iterator.bookmark;

			// find desired label
			var newSelectedItem:Object = null;
			iterator.seek(CursorBookmark.FIRST, 0);
			while (iterator.moveNext())
			{
				if (itemToLabel(iterator.current) == value)
				{
					newSelectedItem = iterator.current;
					break;
				}
			}
			
			// restore iterator bookmark
			iterator.seek(bookmark, 0);
			
			// if label was found, set selected item
			if (newSelectedItem != null)
				selectedItem = newSelectedItem;
		}
	}
}
