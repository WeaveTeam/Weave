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
	/**
	 * Represents a menu item for use with SubMenu.
	 * @see weave.ui.SubMenu
	 * 
	 * @author skolman
	 * @author adufilie
	 */
	public class SubMenuItem
	{
		/**
		 * Adds an item to the menu.
		 * @param label The Label string (or function that returns a string) to show when the menu is open.
		 * @param listener The function to call when the item is clicked.
		 * @param params An Array of parameters to pass to the listener function.
		 * @param shown A function that returns a boolean that determines whether the menu item should be shown.
		 * @param children An Array of child SubMenuItem objects.
		 * @return An object containing the parameters, which can be modified later.
		 */
		public function SubMenuItem(label:Object = null, listener:Function = null, params:Array = null, shown:Function = null, children:Array = null)
		{
			this.labelProvider = label;
			this.listener = listener;
			this.params = params;
			this.shown = shown;
			this.childMenuItems = children;
		}
		/**
		 * Label for this menu item - either a String or a Function which returns a String.
		 */
		public var labelProvider:Object;
		/**
		 * Function to call when the user clicks this menu item
		 */
		public var listener:Function;
		/**
		 * Parameters for the listener
		 */
		public var params:Array;
		/**
		 * A function which returns a Boolean specifying whether or not this menu item should be shown.
		 */
		public var shown:Function;
		/**
		 * Child SubMenuItem objects
		 */
		public var childMenuItems:Array;
		
		/**
		 * Gets label from labelProvider
		 */
		public function get label():String
		{
			return String(labelProvider is Function ? labelProvider() : labelProvider);
		}
		/**
		 * Filtered list of child menu items.
		 */
		public function get children():Array
		{
			if (!childMenuItems)
				return null;
			return childMenuItems.filter(isItemShown);
		}
		
		/**
		 * Use this for filtering an Array for visible and functional SubMenuItems.
		 */
		public static function isItemShown(item:SubMenuItem, ..._):Boolean
		{
			return item.label
				&& (item.listener != null || (item.children && item.children.length))
				&& (item.shown == null || item.shown());
		}
	}
}
