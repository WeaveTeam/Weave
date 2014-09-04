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
	import mx.controls.Button;
	
	/**
	 * A button with a menu icon and an attached SubMenu.
	 * @see weave.ui.SubMenu
	 */
	[DefaultProperty("data")]
	public class MenuButton extends Button
	{
		public function MenuButton(data:Object = null)
		{
			this.setStyle('icon', MENU_LINES_ICON);
			this.data = data;
		}
		
		/**
		 * The submenu that appears when the button is pressed.
		 */
		public const menu:SubMenu = new SubMenu(this as Button);
		
		/**
		 * Set this to true to use a small menu icon.
		 */
		public function set smallIcon(value:Boolean):void
		{
			this.setStyle('icon', value ? MENU_LINES_ICON_SMALL : MENU_LINES_ICON); 
		}
		
		/**
		 * Sets menu.alignRight
		 * @see weave.ui.SubMenu#alignRight
		 */
		public function set alignRight(value:Boolean):void
		{
			menu.alignRight = value;
		}
		
		/**
		 * Sets menu.dataProvider
		 * @see #menu
		 */
		override public function set data(value:Object):void
		{
			menu.dataProvider = super.data = value;
		}
		
		[Embed(source="/weave/resources/images/menuLines.png")] private static var MENU_LINES_ICON:Class;
		[Embed(source="/weave/resources/images/menu_9x7.png")] private static var MENU_LINES_ICON_SMALL:Class;
	}
}
