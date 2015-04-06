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

package weave.ui.controlBars
{
	import flash.events.MouseEvent;
	
	import mx.controls.menuClasses.MenuBarItem;
	
	/**
	 * Fixes flashing bug when mouseY == 0.
	 */	
	public class CustomMenuBarItem extends MenuBarItem
	{
		public function CustomMenuBarItem()
		{
			addEventListener(MouseEvent.MOUSE_MOVE, rollOver);
			addEventListener(MouseEvent.ROLL_OVER, rollOver);
			addEventListener(MouseEvent.ROLL_OUT, rollOut);
		}
		
		private var over:Boolean = false;
		private function rollOver(event:*):void
		{
			over = true;
			if (menuBarItemState != "itemDownSkin")
				menuBarItemState = "itemOverSkin";
		}
		private function rollOut(event:*):void
		{
			over = false;
			if (menuBarItemState != "itemDownSkin")
				menuBarItemState = "itemUpSkin";
		}
		
		override public function set menuBarItemState(value:String):void
		{
			if (value != "itemDownSkin" && menuBarItemState != "itemDownSkin")
				value = over && mouseY > 0 ? "itemOverSkin" : "itemUpSkin";
			super.menuBarItemState = value;
		}
	}
}
