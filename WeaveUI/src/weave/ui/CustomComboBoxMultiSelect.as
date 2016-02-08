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
	public class CustomComboBoxMultiSelect extends ComboBox
	{
		private var ctrlPressed:Boolean = false;
		
		
		public function CustomComboBoxMultiSelect()
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
