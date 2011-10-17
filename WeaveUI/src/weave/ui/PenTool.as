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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.IBitmapDrawable;
	import flash.display.PixelSnapping;
	import flash.display.Shape;
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Dictionary;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.events.ResizeEvent;
	import mx.managers.CursorManagerPriority;
	
	import weave.api.WeaveAPI;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableContainer;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotLayer;
	import weave.compiler.StandardLib;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.StageUtils;
	import weave.primitives.Bounds2D;
	import weave.primitives.ZoomBounds;
	import weave.utils.CustomCursorManager;
	import weave.utils.PlotterUtils;
	import weave.utils.SpatialIndex;
	import weave.visualization.layers.PlotLayerContainer;
	import weave.visualization.tools.SimpleVisTool;

	use namespace mx_internal;
	/**
	 * PenTool
	 * This is a class that controls the graphical annotations within Weave.
	 *
	 * @author jfallon
	 * @author adufilie
	 */
	public class PenTool extends UIComponent implements ILinkableObject, IDisposableObject
	{
		public function PenTool()
		{
			percentWidth = 100;
			percentHeight = 100;
			
			// add local event listeners for rollOver/rollOut for changing the cursor
			addEventListener(MouseEvent.MOUSE_OVER, handleRollOver);
			addEventListener(MouseEvent.MOUSE_OUT, handleRollOut);
			// add local event listener for mouse down.  local rather than global because we don't care if mouse was pressed elsewhere
			addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
			
			addEventListener(MouseEvent.DOUBLE_CLICK, handleDoubleClick);
			doubleClickEnabled = true;
			// add global event listener for mouse move and mouse up because user may move or release outside this display object
			StageUtils.addEventCallback(MouseEvent.MOUSE_MOVE, this, handleMouseMove);
			StageUtils.addEventCallback(MouseEvent.MOUSE_UP, this, handleMouseUp);

			// default drawing mode
			_drawingMode = POLYGON_DRAW_MODE;
			
			// when the parent is resized, screenBounds have changed so everything must be redrawn
			var visualization:PlotLayerContainer = getPlotLayerContainer(parent);
			if (visualization)
			{
				var handleContainerChange:Function = function (...args):void
				{
					invalidateDisplayList();
				};

				getCallbackCollection(visualization).addGroupedCallback(this, handleContainerChange);
			}
			
			// when databounds of the parent ILinkableContainer changes, we don't want the
			// drawing to go outside of the UIComponent. The code belows adds a mask
			// which keeps the drawing inside.
			var handleResize:Function = function (event:ResizeEvent):void
			{
				var penTool:PenTool = event.target as PenTool;
				_maskObject.graphics.clear();
				
				_maskObject.setUnscaledWidth(parent.width);
				_maskObject.setUnscaledHeight(parent.height);
				_maskObject.width = parent.width;
				_maskObject.height = parent.height;
				_maskObject.invalidateSize();
				_maskObject.validateNow();
				
//				trace(penTool.width, penTool.height, " blah", _maskObject.width, _maskObject.height);
				_maskObject.graphics.beginFill(0xFFFFFF, 1);
				_maskObject.graphics.drawRect(0, 0, parent.width, parent.height);
				_maskObject.graphics.endFill();
			}
			addEventListener(ResizeEvent.RESIZE, handleResize);
			_maskObject.visible = false;
			mask = _maskObject;
			addChild(_maskObject);
			_maskObject.percentWidth = 100;
			_maskObject.percentHeight = 100;
		}
		
		public function dispose():void
		{
			editMode = false; // public setter cleans up event listeners and cursor
		}
		
		private const _maskObject:UIComponent = new UIComponent();
		private var _editMode:Boolean = false; // true when editing
		private var _drawing:Boolean = false; // true when editing and mouse is down
		private var _coordsArrays:Array = []; // parsed from coords LinkableString
		private var _drawingMode:String = FREE_DRAW_MODE;
		
		/**
		 * This is used for sessioning all of the coordinates.
		 */
		public const coords:LinkableString = registerLinkableChild(this, new LinkableString(''), handleCoordsChange);
		/**
		 * Allows user to change the size of the line.
		 */
		public const lineWidth:LinkableNumber = registerLinkableChild(this, new LinkableNumber(2), invalidateDisplayList);
		/**
		 * Allows the user to change the color of the line.
		 */
		public const lineColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000000), invalidateDisplayList);
		
		public function get editMode():Boolean
		{
			return _editMode;
		}
		public function set editMode(value:Boolean):void
		{
			if (_editMode == value)
				return;
			
			_editMode = value;
			
			_drawing = false;
			if (value)
				CustomCursorManager.showCursor(CustomCursorManager.PEN_CURSOR, CursorManagerPriority.HIGH, -3, -22);
			else
				CustomCursorManager.removeAllCursors();
			invalidateDisplayList();
		}
		
		public function set drawingMode(mode:String):void
		{
			if (mode == FREE_DRAW_MODE || mode == POLYGON_DRAW_MODE)
				_drawingMode = mode;
		}
		public function get drawingMode():String
		{
			return _drawingMode;
		}
		private function handleScreenCoordinate(x:Number, y:Number, output:Point):void
		{
			// FREE_DRAW_MODE uses screen coordinates (for backwards compatibility)
			if (_drawingMode == FREE_DRAW_MODE)
			{
				output.x = x;
				output.y = y;
			}
			// POLYGON_DRAW_MODE uses data coordinates (for record querying)
			else if (_drawingMode == POLYGON_DRAW_MODE)
			{
				var visualization:PlotLayerContainer = getPlotLayerContainer(parent);
				if (visualization)
				{
					visualization.zoomBounds.getScreenBounds(_tempScreenBounds);				
					visualization.zoomBounds.getDataBounds(_tempDataBounds);
					
					output.x = x;
					output.y = y;
					_tempScreenBounds.projectPointTo(output, _tempDataBounds);					
				}
			}
		}
		private function projectCoordToScreenBounds(x1:Number, y1:Number, output:Point):void
		{
			// if FREE_DRAW_MODE, x and y are already screen values (backwards compatibility)
			if (_drawingMode == FREE_DRAW_MODE)
			{
				output.x = x1;
				output.y = y1;
			}
			else if (_drawingMode == POLYGON_DRAW_MODE)
			{
				var linkableContainer:ILinkableContainer = getLinkableContainer(parent);
				var visualization:PlotLayerContainer = (linkableContainer as SimpleVisTool).visualization as PlotLayerContainer;
				if (visualization)
				{
					visualization.zoomBounds.getScreenBounds(_tempScreenBounds);				
					visualization.zoomBounds.getDataBounds(_tempDataBounds);

					// project the point to screen bounds
					output.x = x1;
					output.y = y1;
					_tempDataBounds.projectPointTo(output, _tempScreenBounds);
					
					// get the rounded values
					var x2:Number = Math.round(output.x);
					var y2:Number = Math.round(output.y);

					output.x = x2;
					output.y = y2;
				}
			}
		}

		private function handleCoordsChange():void
		{
			if (!_drawing)
				_coordsArrays = WeaveAPI.CSVParser.parseCSV( coords.value );
			invalidateDisplayList();
		}
		
		/**
		 * This function is called when the left mouse button is pressed inside the PenTool UIComponent.
		 * It adds the initial mouse position coordinate to the session state so it knows where
		 * to start from for the following lineTo's added to it.
		 */
		private function handleMouseDown(event:MouseEvent):void
		{
			if (!_editMode)
				return;

			handleScreenCoordinate(mouseX, mouseY, _tempPoint);
			
			if (_drawingMode == FREE_DRAW_MODE)
			{
				// begin a new line (new array of x,y)
				_coordsArrays.push([_tempPoint.x, _tempPoint.y]);
				coords.value += '\n' + _tempPoint.x + "," + _tempPoint.y + ",";
			}
			else if (_drawingMode == POLYGON_DRAW_MODE)
			{
				// continue last line (or begin one if there is no last line)
				var line:Array;
				if (_drawing)
				{
					line = _coordsArrays[_coordsArrays.length - 1];
					line.push(_tempPoint.x, _tempPoint.y);
					coords.value += _tempPoint.x + "," + _tempPoint.y + ",";
				}
				else
				{
					line = [];
					line.push(_tempPoint.x, _tempPoint.y);
					coords.value += "\n" + _tempPoint.x + "," + _tempPoint.y + ",";
					_coordsArrays.push(line);
				}
			}
			
			_drawing = true;
						
			invalidateDisplayList();
		}
		
		private function handleDoubleClick(event:MouseEvent):void
		{
			if (_drawing && _drawingMode == POLYGON_DRAW_MODE)
			{
				var line:Array = _coordsArrays[_coordsArrays.length - 1];
				if (line && line.length > 2)
				{
					var lastPoint:Array = [ line[line.length - 2], line[line.length - 1] ];
					line.push(line[0], line[1]);
					coords.value += line[0] + "," + line[1] + ",";
				}
			}
			_drawing = false;
		}
		
		private function handleMouseUp():void
		{
			if (!_editMode)
				return;

			if (_drawingMode == FREE_DRAW_MODE)
			{
				_drawing = false;
			}
			else if (_drawingMode == POLYGON_DRAW_MODE)
			{
				var line:Array = _coordsArrays[_coordsArrays.length - 1];
				var x:Number = StandardLib.constrain(mouseX, 0, unscaledWidth);
				var y:Number = StandardLib.constrain(mouseY, 0, unscaledHeight);

				handleScreenCoordinate(x, y, _tempPoint);
				line.push(_tempPoint.x, _tempPoint.y);
				coords.value += _tempPoint.x + "," + _tempPoint.y + ",";
			}

			invalidateDisplayList();
		}
		
		private function handleMouseMove():void
		{
			if (_drawing && editMode)
			{
				var x:Number = StandardLib.constrain(mouseX, 0, unscaledWidth);
				var y:Number = StandardLib.constrain(mouseY, 0, unscaledHeight);
				
				var line:Array = _coordsArrays[_coordsArrays.length - 1];
				// only save new coords if they are different from previous coordinates
				// and we're in free_draw_mode
				if (_drawingMode == FREE_DRAW_MODE && 
					(line.length < 2 || line[line.length - 2] != x || line[line.length - 1] != y))
				{
					handleScreenCoordinate(x, y, _tempPoint);
					line.push(_tempPoint.x, _tempPoint.y);
					coords.value += _tempPoint.x + "," + _tempPoint.y + ",";
				}
			}
			invalidateDisplayList();
		}
		
		private function handleRollOver( e:MouseEvent ):void
		{
			if (!_editMode)
				return;
			
			CustomCursorManager.showCursor(CustomCursorManager.PEN_CURSOR, CursorManagerPriority.HIGH, -3, -22);
		}
		
		private function handleRollOut( e:MouseEvent ):void
		{
			if (!_editMode)
				return;
			
			CustomCursorManager.removeAllCursors();
		}
		
		private var _prevUnscaledWidth:int = 1;
		private var _prevUnscaledHeight:int = 1;
		private const _clipRectangle:Rectangle = new Rectangle();
		private const _tempShape:Shape = new Shape();
		private const _tempScreenBounds:IBounds2D = new Bounds2D();
		private const _tempDataBounds:IBounds2D = new Bounds2D();
		private const _tempPoint:Point = new Point();
		private const _lastPoint:Point = new Point();
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			var visualization:PlotLayerContainer = getPlotLayerContainer(parent);
			if (visualization)
			{
				visualization.zoomBounds.getScreenBounds(_tempScreenBounds);				
				visualization.zoomBounds.getDataBounds(_tempDataBounds);
				
				var g:Graphics = graphics;
				g.clear();
				if (_editMode)
				{
					// draw invisible rectangle to capture mouse events
					g.lineStyle(0, 0, 0);
					g.beginFill(0, 0);
					g.drawRect(0, 0, unscaledWidth, unscaledHeight);
					g.endFill();
				}
				
				g.lineStyle(lineWidth.value, lineColor.value);
				for (var line:int = 0; line < _coordsArrays.length; line++)
				{
					var lineArray:Array = _coordsArrays[line];
					for (var i:int = 0; i < lineArray.length - 1 ; i += 2 )
					{
						var x:Number = lineArray[i];
						var y:Number = lineArray[i+1];

						projectCoordToScreenBounds(x, y, _tempPoint);
						
						if ( i == 0 )
							g.moveTo(_tempPoint.x, _tempPoint.y);
						else
							g.lineTo(_tempPoint.x, _tempPoint.y);
					}
				}
				
				if (_drawing && _drawingMode == POLYGON_DRAW_MODE)
				{
					g.lineTo(mouseX, mouseY);
				}
			}
		}
		
		/*************************************************/
		/** static section                              **/
		/*************************************************/
		
		private static var _penToolMenuItem:ContextMenuItem = null;
		private static var _removeDrawingsMenuItem:ContextMenuItem = null;
		private static var _changeDrawingMode:ContextMenuItem = null;
		private static const ENABLE_PEN:String = "Enable Pen Tool";
		private static const DISABLE_PEN:String = "Disable Pen Tool";
		private static const PEN_OBJECT_NAME:String = "penTool";
		public static const FREE_DRAW_MODE:String = "Free Draw Mode";
		public static const POLYGON_DRAW_MODE:String = "Polygon Draw Mode";
		private static const _menuGroupName:String = "5 drawingMenuitems";
		public static function createContextMenuItems(destination:DisplayObject):Boolean
		{
			if (!destination.hasOwnProperty("contextMenu"))
				return false;
			
			// Add a listener to this destination context menu for when it is opened
			var contextMenu:ContextMenu = destination["contextMenu"] as ContextMenu;
			contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, handleContextMenuOpened);

			// Create a context menu item for printing of a single tool with title and logo
			_penToolMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination(ENABLE_PEN, destination, handleDrawModeMenuItem, _menuGroupName);
			_removeDrawingsMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination("Remove All Drawings", destination, handleEraseDrawingsMenuItem, _menuGroupName);
			_changeDrawingMode = CustomContextMenuManager.createAndAddMenuItemToDestination("Change Drawing Mode", destination, handleChangeMode, _menuGroupName);

			_removeDrawingsMenuItem.enabled = false;
			_changeDrawingMode.enabled = true;
			return true;
		}
		
		private static function handleChangeMode(e:ContextMenuEvent):void
		{
			var contextMenu:ContextMenu = (Application.application as Application).contextMenu;
			if (!contextMenu)
				return;
			
			var linkableContainer:ILinkableContainer = getLinkableContainer(e.mouseTarget) as ILinkableContainer;
			if (linkableContainer)
			{
				var penObject:PenTool = linkableContainer.getLinkableChildren().getObject( PEN_OBJECT_NAME ) as PenTool;
				if (penObject)
				{
					if (penObject.drawingMode == PenTool.FREE_DRAW_MODE)
						penObject.drawingMode = PenTool.POLYGON_DRAW_MODE;
					else
						penObject.drawingMode = PenTool.FREE_DRAW_MODE;

					_removeDrawingsMenuItem.enabled = true;
				}
			}
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

			// If session state is imported need to detect if there are drawings.
			var linkableContainer:ILinkableContainer = getLinkableContainer(e.mouseTarget) as ILinkableContainer;
			if (linkableContainer)
			{
				var penObject:PenTool = linkableContainer.getLinkableChildren().getObject( PEN_OBJECT_NAME ) as PenTool;
				if (penObject)
				{
					if (penObject.editMode)
					{
						_penToolMenuItem.caption = DISABLE_PEN;
					}
					else
					{
						_penToolMenuItem.caption = ENABLE_PEN;
					}
					_removeDrawingsMenuItem.enabled = true;
				}
			}
		}
		
		/**
		 * This function gets called whenever Enable/Disable Pen Tool is clicked in the Context Menu.
		 * This creates a PenMouse object if there isn't one existing already.
		 * All of the necessary event listeners are added and captions are
		 * dealt with appropriately.
		 */
		private static function handleDrawModeMenuItem(e:ContextMenuEvent):void
		{
			var linkableContainer:ILinkableContainer = getLinkableContainer(e.mouseTarget);
			
			if (!linkableContainer)
				return;
			
			var penTool:PenTool = linkableContainer.getLinkableChildren().requestObject(PEN_OBJECT_NAME, PenTool, false);
			if(_penToolMenuItem.caption == ENABLE_PEN)
			{
				// enable pen
				
				penTool.editMode = true;
				_penToolMenuItem.caption = DISABLE_PEN;
				_removeDrawingsMenuItem.enabled = true;
				CustomCursorManager.showCursor(CustomCursorManager.PEN_CURSOR, CursorManagerPriority.HIGH, -3, -22);
			}
			else
			{
				// disable pen
				penTool.editMode = false;
				
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
			
			while (targetComponent)
			{
				if (targetComponent is ILinkableContainer)
					return targetComponent as ILinkableContainer;
				
				targetComponent = targetComponent.parent;
			}
			
			return targetComponent;
		}

		private static function getPlotLayerContainer(target:*):PlotLayerContainer
		{
			var linkableContainer:ILinkableContainer = getLinkableContainer(target);
			if (!linkableContainer || !(linkableContainer is SimpleVisTool))
				return null;
			
			var visualization:PlotLayerContainer = (linkableContainer as SimpleVisTool).visualization as PlotLayerContainer;
			
			return visualization;
		}
		/**
		 * This function occurs when Remove All Drawings is pressed.
		 * It removes the PenMouse object and clears all of the event listeners.
		 */
		private static function handleEraseDrawingsMenuItem(e:ContextMenuEvent):void
		{
			var linkableContainer:ILinkableContainer = getLinkableContainer(e.mouseTarget);
			
			if (linkableContainer)
				linkableContainer.getLinkableChildren().removeObject( PEN_OBJECT_NAME );
			_penToolMenuItem.caption = ENABLE_PEN;
			_removeDrawingsMenuItem.enabled = false;
		}
		
		private static function handleSelectionContextMenuClick(e:ContextMenuEvent):void
		{
			var visualization:PlotLayerContainer = getPlotLayerContainer(e.mouseTarget) as PlotLayerContainer;
			if (!visualization)
				return;
			
			var keys:Dictionary = new Dictionary();
			var layers:Array = visualization.layers.getObjects();
			for each (var layer:IPlotLayer in layers)
			{
				var spatialIndex:SpatialIndex = layer.spatialIndex as SpatialIndex;
			}							
		}
		
	}
}