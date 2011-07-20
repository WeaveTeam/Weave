/*
Weave (Web-based Analysis and Visualization Environment)
Copyright (C) 2008-2011 University of Massachusetts Lowell

This file is a part of Weave.

Weave is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License, Version 3,
as published by the Free Software Foundation.

Weave is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Weave. If not, see <http://www.gnu.org/licenses/>.
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
	
	import weave.api.WeaveAPI;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableContainer;
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.utils.CustomCursorManager;
	
	
	/**
	 * PenMouse
	 * This is a class that controls the graphical annotations within Weave.
	 *
	 * @author jfallon
	 */
	public class PenMouse extends UIComponent implements ILinkableObject, IDisposableObject
	{
		public function PenMouse()
		{
			//Initial setup
			coords.value = "";
			lineWidth.value = 2;
			lineColor.value = 0x000000;
		}
		
		public function dispose():void
		{
			editMode = false; // cleans up event listeners and cursor
		}
		
		public var drawing:Boolean = false;
		public const penEnabled:LinkableBoolean = newLinkableChild( this, LinkableBoolean );
		public const coords:LinkableString = newLinkableChild( this, LinkableString, handleCoordsChange ); //This is used for sessiong all of the coordinates.
		public const lineWidth:LinkableNumber = newLinkableChild( this, LinkableNumber, invalidateDisplayList ); //Allows user to change the size of the line.
		public const lineColor:LinkableNumber = newLinkableChild( this, LinkableNumber, invalidateDisplayList ); //Allows the user to change the color of the line.
		private var placeholder:int = 0; //This is necessary for drawing the lines. The placeholder keeps track of what has been drawn so there is no re-drawing.
		private var _coordsArrays:Array = []; // parsed from coords LinkableString
		private var _editMode:Boolean = false; // true when editing
		
		public function get editMode():Boolean
		{
			return _editMode;
		}
		public function set editMode(value:Boolean):void
		{
			if (_editMode == value)
				return;
			
			_editMode = value;
			
			if (value)
			{
				// enable pen
				CustomCursorManager.showCursor(CustomCursorManager.PEN_CURSOR, CursorManagerPriority.HIGH, -3, -22);
				
				addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown );
				addEventListener(MouseEvent.MOUSE_UP, handleMouseUp );
				addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove );
				penEnabled.value = true;
			}
			else
			{
				removeEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown );
				removeEventListener(MouseEvent.MOUSE_UP, handleMouseUp );
				removeEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove );
				
				CustomCursorManager.removeAllCursors();
				penEnabled.value = false;
			}
			invalidateDisplayList();
		}
		
		private function handleCoordsChange():void
		{
			if (!drawing)
				_coordsArrays = WeaveAPI.CSVParser.parseCSV( coords.value );
			invalidateDisplayList();
		}
		
		/**
		 * This function is called when the tool is active and the left mouse button is clicked.
		 * It adds the initial mouse position cooardinate to the session state so it knows where
		 * to start from for the following lineTo's added to it.
		 */
		public function handleMouseDown(event:MouseEvent):void
		{
			drawing = true;
			// new line in CSV means "moveTo"
			_coordsArrays.push([mouseX, mouseY]);
			coords.value += '\n' + mouseX + "," + mouseY + ",";
			invalidateDisplayList();
		}
		
		public function handleMouseUp(event:MouseEvent):void
		{
			drawing = false;
			invalidateDisplayList();
		}
		
		/**
		 * This function is called when the tool is enabled and the mouse is being held down.
		 * It adds coordinates for lineTo to the session state in the form of ( "l,500,450" ).
		 */
		public function handleMouseMove(event:MouseEvent):void
		{
			CustomCursorManager.showCursor(CustomCursorManager.PEN_CURSOR, CursorManagerPriority.HIGH, -3, -22); //This is a temporary fix, should be changed if there is another way.
			if( drawing ){
				_coordsArrays[_coordsArrays.length - 1].push(mouseX, mouseY);
				coords.value += '' + mouseX + "," + mouseY + ",";
				invalidateDisplayList();
			}
		}
		
		override public function validateSize(recursive:Boolean=false):void
		{
			if (parent)
			{
				width = parent.width;
				height = parent.height;
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			graphics.clear();
			
			if (editMode)
			{
				// draw invisible transparent rectangle to capture mouse events
				graphics.lineStyle(0, 0, 0);
				graphics.beginFill(0, 0);
				graphics.drawRect(0, 0, width, height);
				graphics.endFill();
				addEventListener( MouseEvent.MOUSE_OUT, removeCursor );
				addEventListener( MouseEvent.MOUSE_OVER, addCursor );
			}
			
			graphics.lineStyle(lineWidth.value, lineColor.value);
			for (var line:int = 0; line < _coordsArrays.length; line++)
			{
				var lineArray:Array = _coordsArrays[line];
				for(var i:int = 0; i < lineArray.length - 1 ; i += 2 )
				{
					if( i == 0 ){
						graphics.moveTo( lineArray[i], lineArray[i+1] );
					}
					else {
						graphics.lineTo( lineArray[i], lineArray[i+1] );
					}
				}
			}
		}
		
		public function removeCursor( e:MouseEvent ):void
		{
			CustomCursorManager.removeAllCursors();
		}
		
		public function addCursor( e:MouseEvent ):void
		{
			CustomCursorManager.showCursor(CustomCursorManager.PEN_CURSOR, CursorManagerPriority.HIGH, -3, -22);
		}
		
		/*************************************************
		 * static section *
		 *************************************************/
		
		private static var _penToolMenuItem:ContextMenuItem = null;
		private static var _removeDrawingsMenuItem:ContextMenuItem = null;
		private static const ENABLE_PEN:String = "Enable Pen Tool";
		private static const DISABLE_PEN:String = "Disable Pen Tool";
		private static const PEN_OBJECT_NAME:String = "penTool";
		
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
			//Reset Context Menu as if no PenMouse Object is there and let following code adjust as necessary.
			_penToolMenuItem.caption = ENABLE_PEN;
			_removeDrawingsMenuItem.enabled = false;
			//If session state is imported need to detect if there already is drawings.
			//Check if LinkableContainer is null.
			if( ( getLinkableContainer(e.mouseTarget) as ILinkableContainer) )
				if( ( getLinkableContainer(e.mouseTarget) as ILinkableContainer).getLinkableChildren().getObject( PEN_OBJECT_NAME ) )
				{
					var penObject:ILinkableObject = ( getLinkableContainer(e.mouseTarget) as ILinkableContainer).getLinkableChildren().getObject( PEN_OBJECT_NAME );
					if( ( penObject as PenMouse ).penEnabled.value == true )
					{
						_penToolMenuItem.caption = DISABLE_PEN;
						( penObject as PenMouse).editMode = true;
					}
					else
					{
						_penToolMenuItem.caption = ENABLE_PEN;
					}
					_removeDrawingsMenuItem.enabled = true;
				}
		}
		
		/**
		 * This function gets called whenever Enable/Disable Pen Tool is clicked in the Context Menu.
		 * This creates a PenMouse object if there isn't one existing already.
		 * All of the necessary event listeners are added and captions are
		 * dealt with appropriately.
		 */
		public static function drawFunction(e:ContextMenuEvent):void
		{
			var linkableContainer:ILinkableContainer = getLinkableContainer(e.mouseTarget);
			
			if ( linkableContainer )
				var penTool:PenMouse = linkableContainer.getLinkableChildren().requestObject(PEN_OBJECT_NAME, PenMouse,false);
			if( _penToolMenuItem.caption == ENABLE_PEN )
			{
				// enable pen
				
				penTool.editMode = true;
				penTool.penEnabled.value = true;
				_penToolMenuItem.caption = DISABLE_PEN;
				_removeDrawingsMenuItem.enabled = true;
				CustomCursorManager.showCursor(CustomCursorManager.PEN_CURSOR, CursorManagerPriority.HIGH, -3, -22);
			}
			else
			{
				// disable pen
				penTool.editMode = false;
				penTool.penEnabled.value = false;
				
				_penToolMenuItem.caption = ENABLE_PEN;
			}
		}
		
		/**
		 * This function is passed a target and checks to see if the target is an ILinkableContainer.
		 * Either a ILinkableContainer or null will be returned.
		 */
		private static function getLinkableContainer(target:*):*
		{
			var targetComponent:* = target;
			
			while(targetComponent)
			{
				if(targetComponent is ILinkableContainer)
					return targetComponent as ILinkableContainer;
				
				targetComponent = targetComponent.parent;
			}
			
			return targetComponent;
		}
		
		/**
		 * This function occurs when Remove All Drawings is pressed.
		 * It removes the PenMouse object and clears all of the event listeners.
		 */
		public static function eraseDrawings(e:ContextMenuEvent):void
		{
			var linkableContainer:ILinkableContainer = getLinkableContainer(e.mouseTarget);
			
			if ( linkableContainer )
				linkableContainer.getLinkableChildren().removeObject( PEN_OBJECT_NAME );
			_penToolMenuItem.caption = ENABLE_PEN;
			_removeDrawingsMenuItem.enabled = false;
		}
	}
}