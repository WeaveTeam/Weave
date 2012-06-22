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
package weave.api.ui
{

	/**
	 * This is an interface for a collaboration cursor manager, which is in charge of rendering collaboration mouse cursors.
	 * After any change in the property of a cursor, if nothing occurs after a set amount of time (for example, 5000 milliseconds),
	 * the cursor should fade out of view so it does not clutter the display.  The next time the position of that cursor is updated,
	 * the cursor should fade back into view quickly during the move animation.
	 * 
	 * @author adufilie
	 */
	public interface ICollabCursorManager
	{
		/**
		 * This function creates a mouse cursor and needs to be passed a name, preferably the collaborator's username.
		 * @param id Identity to use to refer to the mouse cursor with.
		 */		
		function createCursor(id:String):void;
		/**
		 * This is a list of all existing cursor ids.
		 * @return An Array of mouse cursor ids.
		 */
		function getCursorIds():Array;
		
		/**
		 * This will set the visibility of a mouse cursor so that it smoothly fades in or out of view using alpha values.
		 * @param id Identifies a mouse cursor. If the cursor doesn't exist, it will be created.
		 * @param visible Set to true if the mouse should become visible, or false if it should become invisible.
		 * @param duration The duration of the visibility transition, in milliseconds.
		 */
		function setVisible(id:String, visible:Boolean, duration:uint = 3000):void;

		/**
		 * Set the coordinates of a specific mouse cursor.
		 * The cursor should animate between the previous and new positions.
		 * @param id Identifies a mouse cursor. If the cursor doesn't exist, it will be created.
		 * @param x The new X position
		 * @param y The new Y position
		 * @param duration The duration of the movement animation, in milliseconds.
		 */
		function setPosition(id:String, x:Number, y:Number, duration:uint):void;
		
		/**
		 * Set the color of a specific mouse cursor.
		 * @param id Identifies a mouse cursor. If the cursor doesn't exist, it will be created.
		 * @param color The new color of the cursor
		 * @param duration The duration of the color change effect, in milliseconds.
		 */
		function setColor(id:String, color:uint, duration:uint = 1000):void;
		
		/**
		 *This function returns the color of a specified mouse cursor's color. 
		 * @param Id of the mouse.
		 * @return Returns the color of the cursor, or NaN if the cursor doesn't exist.
		 * 
		 */
		function getColor(id:String):Number;
		
		/**
		 * Remove a specific mouse cursor immediately so it no longer appears on the screen or in the list of cursor ids.
		 * @param id Identifies a cursor. If the cursor doesn't exist, this function has no effect.
		 */		
		function removeCursor(id:String):void;
		
		function addToQueue(id:String, self:String):Number;
		
		function removeFromQueue(id:String, self:String):Number;
	}
}