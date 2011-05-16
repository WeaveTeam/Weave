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
package weave.utils
{
	import mx.managers.CursorManager;

	public class CustomCursorManager
	{
		public function CustomCursorManager()
		{
			super();
		}
		
		public static const LINK_CURSOR:String = "CustomCursorManager.LINK_CURSOR";
		[Embed(source="/weave/resources/images/axisLinkCursor.png")]
		private static var linkCursor:Class;
		
		
		public static const HAND_CURSOR:String = "CustomCursorManager.HAND_CURSOR";
        [Embed(source="/weave/resources/images/cursor_hand.png")]
        private static var handCursor:Class;
        
        public static const HAND_GRAB_CURSOR:String = "CustomCursorManager.HAND_GRAB_CURSOR";
        [Embed(source="/weave/resources/images/cursor_grab.png")]
        private static var handGrabCursor:Class;
        
		public static const SELECT_REPLACE_CURSOR:String = "CustomCursorManager.SELECT_REPLACE_CURSOR";
        [Embed(source="/weave/resources/images/cursor_select_replace.png")]
        private static var selectReplaceCursor:Class;
       
		public static const SELECT_ADD_CURSOR:String = "CustomCursorManager.SELECT_ADD_CURSOR";
        [Embed(source="/weave/resources/images/cursor_select_add.png")]
        private static var selectAddCursor:Class;
       
		public static const SELECT_SUBTRACT_CURSOR:String = "CustomCursorManager.SELECT_SUBTRACT_CURSOR";
        [Embed(source="/weave/resources/images/cursor_select_subtract.png")]
        private static var selectSubtractCursor:Class;
       
		public static const ZOOM_CURSOR:String = "CustomCursorManager.ZOOM_CURSOR";
        [Embed(source="/weave/resources/images/cursor_zoom.png")]
        private static var zoomCursor:Class;
        
        
		public static function showCursor(type:String, priority:int = 2, xOffset:int = 0, yOffset:int = 0):void
		{
			CursorManager.removeCursor(CursorManager.currentCursorID);
			
			switch(type)
			{
				case LINK_CURSOR:
					CursorManager.setCursor(linkCursor, priority, xOffset, yOffset);
					break;
					
				case HAND_CURSOR:
					CursorManager.setCursor(handCursor, priority, xOffset, yOffset);
					break;
					
				case HAND_GRAB_CURSOR:
					CursorManager.setCursor(handGrabCursor, priority, xOffset, yOffset);
					break;
					
				case SELECT_REPLACE_CURSOR:
					CursorManager.setCursor(selectReplaceCursor, priority, xOffset, yOffset);
					break;
					
				case SELECT_ADD_CURSOR:
					CursorManager.setCursor(selectAddCursor, priority, xOffset, yOffset);
					break;
					
				case SELECT_SUBTRACT_CURSOR:
					CursorManager.setCursor(selectSubtractCursor, priority, xOffset, yOffset);
					break;
					
				case ZOOM_CURSOR:
					CursorManager.setCursor(zoomCursor, priority, xOffset, yOffset);
					break;
			}
			
		}
		
		public static function removeCurrentCursor():void
		{
			CursorManager.removeCursor(CursorManager.currentCursorID);
		}
		
		public static function removeAllCursors():void
		{
			CursorManager.removeAllCursors();
		}
	}
}