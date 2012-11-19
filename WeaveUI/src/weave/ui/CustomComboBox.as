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
	import flash.events.KeyboardEvent;
	
	import mx.collections.CursorBookmark;
	import mx.controls.ComboBox;
	import mx.events.ListEvent;
	import mx.states.OverrideBase;
	import mx.utils.StringUtil;

	/**
	 * Added functionality: set selectedLabel()
	 * 
	 * Added functionality: get selectedLabel()
	 * Added functionality: Multiple selection
	 * 
	 * @author adufilie
	 * @author pstickne
	 */
	public class CustomComboBox extends ComboBox
	{
		private var ctrlPressed:Boolean = false;
		
		
		public function CustomComboBox()
		{
			super();
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
		override public function get selectedLabel():String
		{
			var label:String = "";
			if( selectedItems && selectedItems.length > 0 )
			{
				for( var i:int = 0; i < selectedItems.length-1; i++ )
				{
					label += selectedItems[i] + ",";
				}
				label += selectedItems[selectedItems.length-1];
				return label;
			}
			return label;
		}
		override protected function keyDownHandler(event:KeyboardEvent):void
		{
			super.keyDownHandler(event);
			this.ctrlPressed = event.ctrlKey;
			if( this.ctrlPressed == true )
				dropdown.allowMultipleSelection = true;
		}
		
		override protected function keyUpHandler(event:KeyboardEvent):void
		{
			super.keyUpHandler(event);
			this.ctrlPressed = event.ctrlKey;
			
			if( this.ctrlPressed == false )
			{
				this.close();
			}
		}
		override public function close( trigger:Event = null ):void
		{
			if( this.ctrlPressed == false )
			{
				super.close( trigger );
			}
		}
		
		public function set selectedItems( value:Array ):void
		{
			if( this.dropdown )
				this.dropdown.selectedItems = value;
		}
		[Bindable] public function get selectedItems():Array
		{
			if( this.dropdown )
				return this.dropdown.selectedItems;
			else
				return null;
		}
		
		public function set selectedIndices( value:Array ):void
		{
			if( this.dropdown )
				this.dropdown.selectedIndices = value;
		}
		[Bindable] public function get selectedIndices():Array
		{
			if( this.dropdown )
				return this.dropdown.selectedIndices;
			else
				return null;
		}
	}
}
