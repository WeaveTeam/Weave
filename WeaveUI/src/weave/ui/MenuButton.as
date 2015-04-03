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
