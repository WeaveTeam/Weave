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
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	import mx.collections.CursorBookmark;
	import mx.controls.ComboBox;
	import mx.core.UIComponent;

	/**
	 * Added functionality: set selectedLabel(), dropdownStyle
	 * 
	 * @author adufilie
	 */
	public class CustomComboBox extends ComboBox
	{
		public function CustomComboBox()
		{
			minWidth = 0;
			addEventListener(MouseEvent.MOUSE_DOWN, function(..._):void { setFocus(); });
		}
		
		/**
		 * An object containing dropdown style values, or a Function that returns such an object.
		 */
		public var dropdownStyle:Object = null;
		
		/**
		 * Set this to true for the dropdown to inherit the 'backgroundColor' style from the closest ancestor with a value.
		 */
		public var dropdownInheritsBackgroundColor:Boolean = true;
		
		override public function getStyle(styleProp:String):*
		{
			// this style property is retrieved in displayDropDown(), so we can intercept the request here to update the dropdown style.
			if (styleProp == "openDuration" && dropdown)
			{
				if (dropdownInheritsBackgroundColor)
				{
					const BACKGROUND_COLOR:String = 'backgroundColor';
					var ancestor:DisplayObject = this;
					while (ancestor && !(ancestor is UIComponent) || (ancestor as UIComponent).getStyle(BACKGROUND_COLOR) === undefined)
						ancestor = ancestor.parent;
					if (ancestor is UIComponent)
						dropdown.setStyle(BACKGROUND_COLOR, (ancestor as UIComponent).getStyle(BACKGROUND_COLOR));
				}
				
				var style:Object = dropdownStyle is Function ? this.dropdownStyle() : dropdownStyle;
				for (var key:String in style)
					dropdown.setStyle(key, style[key]);
			}
			
			return super.getStyle(styleProp);
		}
		
		/**
		 * This function will set the selectedItem corresponding to the given label.
		 * @param value The label of the item to select.
		 */
		[Bindable]
		public function set selectedLabel(value:String):void
		{
			selectByField("label", value);
		}
		
		public function selectByField(field:String, value:*):void
		{
			// save current iterator bookmark
			var bookmark:CursorBookmark = iterator.bookmark;
			
			// find desired label
			var newSelectedItem:Object = null;
			iterator.seek(CursorBookmark.FIRST, 0);
			while (iterator.moveNext())
			{
				var item_value:* = null;
				
				if (field == "label")
					item_value = itemToLabel(iterator.current);
				else
					if (iterator.current)
						item_value = iterator.current[field];
				
				if (item_value == value)
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
