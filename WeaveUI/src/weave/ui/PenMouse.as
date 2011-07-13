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
	import flash.display.DisplayObject;
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.managers.CursorManagerPriority;
	
	import weave.Weave;
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.StageUtils;
	import weave.data.CSVParser;
	import weave.utils.CustomCursorManager;

	
	/**
	 * PenMouse
	 * This is a class that controls the graphical annotations within Weave.
	 * 
	 * @author jfallon
	 */	
	public class PenMouse extends UIComponent implements ILinkableObject
	{
		
		public var drawing:Boolean = false;
		public const coords:LinkableString = newLinkableChild( this, LinkableString, drawSprite ); //This is used for sessiong all of the coordinates.
		public const lineWidth:LinkableNumber = newLinkableChild( this, LinkableNumber, changeWidth ); //Allows user to change the size of the line.
		private var placeholder:int = new int(0); //This is necessary for drawing the lines. The placeholder keeps track of what has been drawn so there is no re-drawing.
		
		public function PenMouse()
		{
			//Initial setup
			coords.value = "";
			lineWidth.value = 2;
			graphics.lineStyle(lineWidth.value, 0x000000);
		}
		
		/**
		 * This function is called when the tool is active and the left mouse button is clicked.
		 * It adds the initial mouse position cooardinate to the session state so it knows where
		 * to start from for the following lineTo's added to it. 
		 */
		public function beginDraw():void
		{
			drawing = true;
			coords.value += "m," + mouseX + "," + mouseY + ",";
		}
		
		public function stop():void
		{
			drawing = false;
		}
		
		/**
		 * This function is called when the tool is enabled and the mouse is being held down.
		 * It adds coordinates for lineTo to the session state in the form of ( "l,500,450" ).		 * 
		 */		
		public function draw():void
		{
			if( drawing ){
				coords.value += "l," + mouseX + "," + mouseY + ",";
			}
		}
		
		public function drawSprite():void
		{
			var i:int = new int(0);
			var parse:CSVParser = new CSVParser();
			var test:Array = new Array( parse.parseCSV( coords.value ) );
			if( test[0][0] != null ){
				i = placeholder;
				for( i; i < test[0][0].length ; i++ )
				{
					if( test[0][0][i] == "m" ){
						graphics.moveTo( test[0][0][i+1], test[0][0][i+2] );
						i += 2;
					}
					else if( test[0][0][i] == "l" ){
						graphics.lineTo( test[0][0][i+1], test[0][0][i+2] );
						i += 2;
					}
					placeholder = i;
				}
			}
		}
		
		public function changeWidth():void
		{
			graphics.lineStyle( lineWidth.value, 0x000000 );
		}
		
		/*************************************************
		 *                static section                 *
		 *************************************************/
		
		private static var _penToolMenuItem:ContextMenuItem = null;
		private static var _removeDrawingsMenuItem:ContextMenuItem = null;
		private static const ENABLE_PEN:String		= "Enable Pen Tool";
		private static const DISABLE_PEN:String  = "Disable Pen Tool";
		
		public static function createContextMenuItems(destination:DisplayObject):Boolean
		{
			if(!destination.hasOwnProperty("contextMenu") )
			return false;

			
			// Add a listener to this destination context menu for when it is opened
			var contextMenu:ContextMenu = destination["contextMenu"] as ContextMenu;
			contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, handleContextMenuOpened);
		
			// Create a context menu item for printing of a single tool with title and logo
			_penToolMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination(ENABLE_PEN, destination, drawFunction, "5 drawingMenuItems");
			_removeDrawingsMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination("Remove All Drawings", destination, eraseDrawings, "5 drawingMenuItems");
			if( !Weave.root.getName( penTool ) )
				_removeDrawingsMenuItem.enabled = false;
			
			return true;
		}
		
		/**
		 * This function is called whenever the context menu is opened.
		 * The function will change the caption displayed depending upon if there is any drawings.
		 * This is also used to get the correct mouse pointer for the context menu.
		 */
		private static function handleContextMenuOpened(e:ContextMenuEvent):void
		{
			var contextMenu:ContextMenu = (Application.application as Application).contextMenu;
			if (!contextMenu)
				return;
			CustomCursorManager.removeCurrentCursor();
			//If session state is imported need to detect if there already is drawings.
			if( Weave.root.getName( penTool ) )
				_removeDrawingsMenuItem.enabled = true;
		}
		
		public static var penTool:PenMouse = null;
		
		/**
		 * This function gets called whenever Enable/Disable Pen Tool is clicked in the Context Menu.
		 * This creates a PenMouse object if there isn't one existing already.
		 * All of the necessary event listeners are added and captions are 
		 * dealt with appropriately.  
		 */				
		public static function drawFunction(e:ContextMenuEvent):void
		{
			if( _penToolMenuItem.caption == ENABLE_PEN )
			{
				if( penTool == null )
				{
					penTool = Weave.root.requestObject("penTool", PenMouse, false ) as PenMouse;
				}
				CustomCursorManager.showCursor(CustomCursorManager.PEN_CURSOR, CursorManagerPriority.HIGH, -3, -22);
				StageUtils.addEventCallback(MouseEvent.MOUSE_DOWN, e.contextMenuOwner, penTool.beginDraw );
				StageUtils.addEventCallback(MouseEvent.MOUSE_UP, e.contextMenuOwner, penTool.stop );
				StageUtils.addEventCallback(MouseEvent.MOUSE_MOVE, e.contextMenuOwner, penTool.draw );
				_penToolMenuItem.caption = DISABLE_PEN;
				_removeDrawingsMenuItem.enabled = true;
			}
			else
			{
				_penToolMenuItem.caption = ENABLE_PEN;
				StageUtils.removeEventCallback(MouseEvent.MOUSE_DOWN, penTool.beginDraw );
				StageUtils.removeEventCallback(MouseEvent.MOUSE_UP, penTool.stop );
				StageUtils.removeEventCallback(MouseEvent.MOUSE_MOVE, penTool.draw );
				CustomCursorManager.removeAllCursors();
			}
		}
		
		/**
		 * This function occurs when Remove All Drawings is pressed.
		 * It removes the PenMouse object and clears all of the event listeners.  
		 */		
		public static function eraseDrawings(e:ContextMenuEvent):void
		{
			if( penTool )
			{
				StageUtils.removeEventCallback(MouseEvent.MOUSE_DOWN, penTool.beginDraw );
				StageUtils.removeEventCallback(MouseEvent.MOUSE_UP, penTool.stop );
				StageUtils.removeEventCallback(MouseEvent.MOUSE_MOVE, penTool.draw );
				CustomCursorManager.removeAllCursors();
				Weave.root.removeObject( "penTool" );
				penTool = null;
				_penToolMenuItem.caption = ENABLE_PEN;
				_removeDrawingsMenuItem.enabled = false;
			}
		}
	}
}