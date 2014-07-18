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
