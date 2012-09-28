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
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.ui.MouseCursorData;
	
	import mx.core.BitmapAsset;

	/**
	 * Easy interface for using native cursors.
	 * 
	 * @author skolman
	 * @author adufilie
	 */	
	public class CustomCursorManager
	{
		/**
		 * This will register an embedded cursor.
		 * To embed a cursor in your own class, follow this example:
		 * <code>
		 *    public static const MY_CURSOR:String = "myCursor";
		 *    [Embed(source="/weave/resources/images/myCursor.png")]
		 *    private static var myCursor:Class;
		 *    CustomCursorManager.registerEmbeddedCursor(MY_CURSOR, myCursor, 0, 0);
		 * </code>
		 * @param cursorName A name for the cursor.
		 * @param bitmapAsset The Class containing the embedded cursor image.
		 * @param xHotSpot The X coordinate of the hot spot.  Set to NaN to use the center X coordinate.
		 * @param yHotSpot The X coordinate of the hot spot.  Set to NaN to use the center Y coordinate.
		 */		
        public static function registerEmbeddedCursor(name:String, bitmapAssetClass:Class, xHotSpot:Number, yHotSpot:Number):void
		{
			var asset:BitmapAsset = new bitmapAssetClass() as BitmapAsset;
			if (isNaN(xHotSpot))
				xHotSpot = asset.width / 2;
			if (isNaN(yHotSpot))
				yHotSpot = asset.height / 2;
			registerCursor(name, asset.bitmapData, xHotSpot, yHotSpot);
		}
		
		/**
		 * This will register a BitmapData object as a cursor.
		 * @param cursorName A reasonably unique name for the cursor.
		 * @param bitmapData The cursor image.
		 * @param xHotSpot The X coordinate for the hot spot.
		 * @param yHotSpot The Y coordinate for the hot spot.
		 */
        public static function registerCursor(cursorName:String, bitmapData:BitmapData, xHotSpot:int = 0, yHotSpot:int = 0):void
		{
			var cursorData:MouseCursorData = new MouseCursorData();
			cursorData.data = Vector.<BitmapData>([bitmapData]);
			cursorData.hotSpot = new Point(xHotSpot, yHotSpot);
			Mouse.registerCursor(cursorName, cursorData);
		}
		
        private static var idCounter:int = 0; // used to generate unique IDs for cursors
		private static const cursorStack:Array = []; // keeps track of previously shown cursors
		
		/**
		 * This function is to set the cursor to standard cursor types like hand cursor, link cursor, etc.
		 * Look at the static String constants to get all the types of available cursors.
		 * @param name The name of a registered cursor.
		 * @return An id mapped to the cursor that can be passed to removeCursor() later.
		 * */
		public static function showCursor(name:String):int
		{
			cursorStack.push(new CursorEntry(idCounter, name));
			updateCursor();
			return idCounter++; // increment for next time
		}
		
		/**
		 * Removes a cursor previously shown.
		 * @param id The id of the cursor that was returned by a previous call to showCursor().
		 */
		public static function removeCursor(id:int):void
		{
			for (var i:int; i < cursorStack.length; i++)
			{
				if (CursorEntry(cursorStack[i]).id == id)
				{
					cursorStack.splice(i,1);
					updateCursor();
					return;
				}
			}
		}
		
		/**
		 * This function should always be called after modifying the cursor stack.
		 */		
		private static function updateCursor():void
		{
			if (cursorStack.length > 0)
				Mouse.cursor = CursorEntry(cursorStack[cursorStack.length - 1]).name;
			else
				Mouse.cursor = MouseCursor.AUTO;
		}
		
		
		
		///////////
		// hacks //
		///////////
		
		/**
		 * @TODO Stop using this function and remove it.
		 */
		[Exclude]
		public static function hack_removeCurrentCursor():void
		{
			if (cursorStack.length == 0)
				return;

			cursorStack.pop();
			updateCursor();
		}
		
		/**
		 * @TODO Stop using this function and remove it.
		 */
		[Exclude]
		public static function hack_removeAllCursors():void
		{
			cursorStack.length = 0;
			updateCursor();
		}
	}
}

internal class CursorEntry
{
	public function CursorEntry(id:int, name:String)
	{
		this.id = id;
		this.name = name;
	}
	
	public var id:Number;
	public var name:String;
}
