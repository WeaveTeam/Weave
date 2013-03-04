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
	import flash.display.Graphics;
	import flash.display.NativeMenu;
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Dictionary;
	
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.getCallbackCollection;
	import weave.api.registerLinkableChild;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.ILinkableContainer;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeometryType;
	import weave.primitives.SimpleGeometry;
	import weave.utils.CustomCursorManager;
	import weave.utils.SpatialIndex;
	import weave.visualization.layers.Visualization;

	use namespace mx_internal;
	
	/**
	 * This is a class that controls the graphical annotations within Weave.
	 * 
	 * @author jfallon
	 * @author adufilie
	 * @author kmonico
	 */
	public class PenTool extends UIComponent implements ILinkableObject, IDisposableObject
	{
		// TODO: Refactor into separate classes for free draw and polygonal drawing?
		public function PenTool()
		{
			percentWidth = 100;
			percentHeight = 100;
			
			// add local event listeners for rollOver/rollOut for changing the cursor
			addEventListener(MouseEvent.MOUSE_OVER, handleRollOver);
			addEventListener(MouseEvent.MOUSE_OUT, handleRollOut);
			// add local event listener for mouse down. local rather than global because we don't care if mouse was pressed elsewhere
			addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);

			addEventListener(FlexEvent.CREATION_COMPLETE, handleCreationComplete);

			// enable the double click event
			doubleClickEnabled = true;
			addEventListener(MouseEvent.DOUBLE_CLICK, handleDoubleClick);
			
			// add global event listener for mouse move and mouse up because user may move or release outside this display object
			WeaveAPI.StageUtils.addEventCallback(MouseEvent.MOUSE_MOVE, this, handleMouseMove);
			WeaveAPI.StageUtils.addEventCallback(MouseEvent.MOUSE_UP, this, handleMouseUp);
 
			setupMask();
		}


		/**
		 * Setup the clipping mask which is used to keep the pen drawings on screen.
		 */		
		private function setupMask():void
		{
			// when this component is resized, the mask needs to be updated
			var handleResize:Function = function (event:ResizeEvent):void
			{
				var penTool:PenTool = event.target as PenTool;
				
				// clear the mask graphics
				_maskObject.graphics.clear();

				// percent width and height seems off sometimes...
				_maskObject.width = parent.width;
				_maskObject.height = parent.height;
				_maskObject.invalidateSize();
				_maskObject.validateNow();
				
				// and draw the invisible rectangle (invisible because mask.visible = false)
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
		
		private function handleCreationComplete(event:FlexEvent):void
		{
			// when the visualization changes, the dataBounds may have changed
			var visualization:Visualization = getVisualization(parent);
			if (visualization)
			{
				var handleContainerChange:Function = function ():void
				{
					invalidateDisplayList();
				};

				getCallbackCollection(visualization).addGroupedCallback(this, handleContainerChange);
			}
			
			drawingMode.addGroupedCallback(this, removeAllDrawings);
		}

		/**
		 * Remove all the drawings and set the pentool to currently not drawing. 
		 */		
		public function removeAllDrawings():void
		{
			_drawing = false;
			coords.value = "";
		}
		
		public function dispose():void
		{
			editMode = false; // public setter cleans up event listeners and cursor
		}
		
		private const _maskObject:UIComponent = new UIComponent();
		private var _editMode:Boolean = false; // true when editing
		private var _drawing:Boolean = false; // true when editing and mouse is down
		private var _coordsArrays:Array = []; // parsed from coords LinkableString
		
		/**
		 * The current mode of the drawing.
		 * @default FREE_DRAW_MODE 
		 */		
		public const drawingMode:LinkableString = registerLinkableChild(this, new LinkableString(FREE_DRAW_MODE, verifyDrawingMode));
		
		/**
		 * This is used for sessioning all of the coordinates.
		 */
		public const coords:LinkableString = registerLinkableChild(this, new LinkableString(''), handleCoordsChange);
		
		/**
		 * The width of the line.
		 * @default 2
		 */
		public const lineWidth:LinkableNumber = registerLinkableChild(this, new LinkableNumber(2), invalidateDisplayList);
		
		/**
		 * The color of the line.
		 * @default 0x0
		 */
		public const lineColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x0), invalidateDisplayList);
		
		/**
		 * The alpha of the line.
		 * @default 1 
		 */		
		public const lineAlpha:LinkableNumber = registerLinkableChild(this, new LinkableNumber(1, verifyAlpha), invalidateDisplayList);
		
		/**
		 * The fill color of the polygon drawn in POLYGON_DRAW_MODE.
		 * @default 0x000000 
		 */		
		public const polygonFillColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000000), invalidateDisplayList);
		
		/**
		 * The fill alpha of the polygon drawn in POLYGON_DRAW_MODE.
		 * @default 1 
		 */		
		public const polygonFillAlpha:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0, verifyAlpha), invalidateDisplayList);
		
		/**
		 * Verification function for the alpha properties.
		 */		
		private function verifyAlpha(value:Number):Boolean
		{
			return value >= 0 && value <= 1;
		}

		/**
		 * Verification function for the drawing mode property.
		 */		
		private function verifyDrawingMode(value:String):Boolean
		{
			return value == FREE_DRAW_MODE || value == POLYGON_DRAW_MODE;
		}

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
				CustomCursorManager.showCursor(PEN_CURSOR);
			else
				CustomCursorManager.hack_removeAllCursors();
			invalidateDisplayList();
		}

		/**
		 * Handle a screen coordinate and project it into the data bounds of the parent visualization. 
		 * @param x The x value in screen coordinates.
		 * @param y The y value in screen coordinates.
		 * @param output The point to store the data projected point.
		 */		
		private function handleScreenCoordinate(x:Number, y:Number, output:Point):void
		{
			var visualization:Visualization = getVisualization(parent);
			if (visualization)
			{
				visualization.plotManager.zoomBounds.getScreenBounds(_tempScreenBounds);
				visualization.plotManager.zoomBounds.getDataBounds(_tempDataBounds);
				
				output.x = x;
				output.y = y;
				_tempScreenBounds.projectPointTo(output, _tempDataBounds);					
			}
		}
		
		/**
		 * Handle a data coordinate and project it into the screen bounds of the parent visualization. 
		 * @param x1 The x value in data coordiantes.
		 * @param y1 The y value in data coordinates.
		 * @param output The point to store the screen projected point.
		 */		
		private function projectCoordToScreenBounds(x1:Number, y1:Number, output:Point):void
		{
			var linkableContainer:ILinkableContainer = getLinkableContainer(parent);
			var children:Array = linkableContainer.getLinkableChildren().getObjects(Visualization);
			if (children.length > 0)
			{
				var visualization:Visualization = children[0] as Visualization;
				
				visualization.plotManager.zoomBounds.getScreenBounds(_tempScreenBounds);
				visualization.plotManager.zoomBounds.getDataBounds(_tempDataBounds);
				
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

		/**
		 * This is the callback of <code>coords</code> 
		 */		
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
			var line:Array;

			if (!_editMode)// || mouseOffscreen())
				return;
			
			// project the point to data coordinates
			handleScreenCoordinate(mouseX, mouseY, _tempPoint);
			
			if (drawingMode.value == FREE_DRAW_MODE)
			{
				// begin a new line and save the point. Note that _drawing is true
				// to avoid parsing coords.value
				_drawing = true;
				coords.value += '\n' + _tempPoint.x + "," + _tempPoint.y + ",";
				_coordsArrays.push([_tempPoint.x, _tempPoint.y]);
			}
			else if (drawingMode.value == POLYGON_DRAW_MODE)
			{
				if (_drawing && _coordsArrays.length >= 1) 
				{
					// continue last line
					coords.value += _tempPoint.x + "," + _tempPoint.y + ",";
					
					line = _coordsArrays[_coordsArrays.length - 1];
					line.push(_tempPoint.x, _tempPoint.y);
				}
				else // begin a line
				{
					// To simplify the code, append the same "x,y," string to coords.value
					// and then manually push the values into _coordsArrays. If we let the 
					// coords callback parse coords.value, then _coordsArrays will have an element
					// "" at index 2 for the new line, which will put "" into _coordsArray[line][2] and
					// this is cast to 0 during drawing.
					_drawing = true;

					coords.value += '\n' + _tempPoint.x + "," + _tempPoint.y + ",";
				
					line = [];
					line.push(_tempPoint.x, _tempPoint.y);
					_coordsArrays.push(line);
				}
			}
			
			// redraw
			invalidateDisplayList();
		}
		
		/**
		 * Handle a double click event which is used for ending the polygon drawing. 
		 * @param event The mouse event.
		 */		
		private function handleDoubleClick(event:MouseEvent):void
		{
			if (_drawing && drawingMode.value == POLYGON_DRAW_MODE)
			{
				var line:Array = _coordsArrays[_coordsArrays.length - 1];
				if (line && line.length > 2)
				{
					line.push(line[0], line[1]);
					coords.value += line[0] + "," + line[1]; // this ends the line
				}
				_drawing = false;
			}
		}
		
		/**
		 * Handle the mouse release event. 
		 */		
		private function handleMouseUp():void
		{
			
			if (!_editMode)// || mouseOffscreen())
				return;

			if (drawingMode.value == FREE_DRAW_MODE)
			{
				_drawing = false;
			}
			// this code is just appending to the last line
//			if (drawingMode.value == POLYGON_DRAW_MODE)
//			{
//				// when in polygon draw mode, we are still drawing after letting go of mouse1
//				var line:Array = _coordsArrays[_coordsArrays.length - 1];
//
//				handleScreenCoordinate(mouseX, mouseY, _tempPoint);
//				line.push(_tempPoint.x, _tempPoint.y);
//				coords.value += _tempPoint.x + "," + _tempPoint.y + ",";
//			}

			// redraw
			invalidateDisplayList();
		}
		
		/**
		 * Handle a mouse move event. 
		 */		
		private function handleMouseMove():void
		{
			if (_drawing && editMode)// && !mouseOffscreen())
			{
				// get the current line
				var line:Array = _coordsArrays[_coordsArrays.length - 1];
				// only save new coords if they are different from previous coordinates
				// and we're in free_draw_mode
				if (drawingMode.value == FREE_DRAW_MODE &&  
					(line.length < 2 || line[line.length - 2] != x || line[line.length - 1] != y))
				{
					handleScreenCoordinate(mouseX, mouseY, _tempPoint);
					line.push(_tempPoint.x, _tempPoint.y);
					coords.value += _tempPoint.x + "," + _tempPoint.y + ",";
				}
			}
			
			// redraw
			invalidateDisplayList();
		}
		
		/**
		 * Show the pen cursor if we are in edit mode. 
		 * @param e The mouse event.
		 */		
		private function handleRollOver(e:MouseEvent):void
		{
			if (!_editMode)
				return;
			
			CustomCursorManager.showCursor(PEN_CURSOR);
		}
		
		/**
		 * Turn off edit mode.
		 * @param e The mouse event.
		 */		
		private function handleRollOut( e:MouseEvent ):void
		{
			if (!_editMode)
				return;
			
			CustomCursorManager.hack_removeAllCursors();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var visualization:Visualization = getVisualization(parent); 
			if (visualization) 
			{
				var lastShape:Array;
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
				
				if (drawingMode.value == POLYGON_DRAW_MODE && polygonFillAlpha.value > 0)
					g.beginFill(polygonFillColor.value, polygonFillAlpha.value);					

				g.lineStyle(lineWidth.value, lineColor.value, lineAlpha.value);
				for (var line:int = 0; line < _coordsArrays.length; line++)
				{
					var points:Array = _coordsArrays[line];
					for (var i:int = 0; i < points.length - 1 ; i += 2 )
					{
						projectCoordToScreenBounds(points[i], points[i+1], _tempPoint);
						
						if (i == 0)
							g.moveTo(_tempPoint.x, _tempPoint.y);
						else
							g.lineTo(_tempPoint.x, _tempPoint.y);
					}
				
					// If we are not drawing (or this is not the last shape), always connect back to first point in the shape.
					// The effect of this is either completing the polygon by drawing a line or
					// drawing to the current position of the graphics object. This is only used to
					// draw complete polygons without affecting the polygon's internal representation.					
					if (points.length >= 2 &&			// at least 2 points 
						(!_drawing || line < (_coordsArrays.length - 1)) && 	// not drawing or not on the last line
						drawingMode.value == POLYGON_DRAW_MODE)	// and drawing polygons
					{
						projectCoordToScreenBounds(points[0], points[1], _tempPoint);
						
						g.lineTo(_tempPoint.x, _tempPoint.y);
					}
				}
				
				// If we are drawing, show what the last polygon would look like if we add the current mouse position
				// If the user drew two of three points for a triangle, this would show what the completed triangle
				// would look like if the final point was placed under the cursor. Note that if the PenTool is disabled,
				// the final point is not put into coords.
				if (_drawing && drawingMode.value == POLYGON_DRAW_MODE)
				{
					g.lineTo(mouseX, mouseY);
					
					lastShape = _coordsArrays[_coordsArrays.length - 1];
					if (lastShape && lastShape.length >= 2)
					{
						projectCoordToScreenBounds(lastShape[0], lastShape[1], _tempPoint);
						
						g.lineStyle(lineWidth.value, lineColor.value, 0.35);
						g.lineTo(_tempPoint.x, _tempPoint.y);
					}
				}
				
				if (drawingMode.value == POLYGON_DRAW_MODE && polygonFillAlpha.value > 0)
					g.endFill();
			} // if (visualization)
		}

		/**
		 * Check if the mouse if off the tool. 
		 * @return <code>true</code> if the mouse is outside the parent coordinates.
		 */		
		private function mouseOffscreen():Boolean
		{
			return mouseX < parent.x || mouseX >= parent.x + parent.width
				|| mouseY < parent.y || mouseY >= parent.y + parent.height;
		}
		
		/**
		 * Get all the keys which overlap the drawn polygons. 
		 * @return An array of IQualifiedKey objects.
		 */		
		public function getOverlappingKeys():Array
		{
			if (drawingMode.value == FREE_DRAW_MODE)
				return [];
			
			var visualization:Visualization = getVisualization(parent);
			if (!visualization)
				return [];
			
			var key:IQualifiedKey;
			var keys:Dictionary = new Dictionary();
			var plotterNames:Array = visualization.plotManager.plotters.getObjects();
			var shapes:Array = WeaveAPI.CSVParser.parseCSV(coords.value);
			for each (var shape:Array in shapes)
			{
				_tempArray.length = 0;
				for (var i:int = 0; i < shape.length - 1; i += 2)
				{
					var newPoint:Point = new Point();
					newPoint.x = shape[i];
					newPoint.y = shape[i + 1];
					_tempArray.push(newPoint);
				}
				_simpleGeom.setVertices(_tempArray);
				
				for each (var plotterName:String in plotterNames)
				{
					var spatialIndex:SpatialIndex = visualization.plotManager.hack_getSpatialIndex(plotterName);
					var overlappingKeys:Array = spatialIndex.getKeysGeometryOverlapGeometry(_simpleGeom);
					for each (key in overlappingKeys)
					{
						keys[key] = true;
					}
				}
			}
//			for each (var layer:IPlotLayer in layers)
//			{
//				var spatialIndex:SpatialIndex = layer.spatialIndex as SpatialIndex;
//				var shapes:Array = WeaveAPI.CSVParser.parseCSV(coords.value);
//				for each (var shape:Array in shapes)
//				{
//					_tempArray.length = 0;
//					for (var i:int = 0; i < shape.length - 1; i += 2)
//					{
//						var newPoint:Point = new Point();
//						newPoint.x = shape[i];
//						newPoint.y = shape[i + 1];
//						_tempArray.push(newPoint);
//					}
//					_simpleGeom.setVertices(_tempArray);
//					var overlappingKeys:Array = spatialIndex.getKeysGeometryOverlapGeometry(_simpleGeom);
//					for each (key in overlappingKeys)
//					{
//						keys[key] = true;
//					}				
//				}

			var result:Array = [];
			for (var keyObj:* in keys)
			{
				result.push(keyObj as IQualifiedKey);
			}
			return result;
		}
				
		private const _tempArray:Array = [];
		private const _simpleGeom:SimpleGeometry = new SimpleGeometry(GeometryType.POLYGON);
		private const _tempScreenBounds:IBounds2D = new Bounds2D();
		private const _tempDataBounds:IBounds2D = new Bounds2D();
		private const _tempPoint:Point = new Point();
		
		/*************************************************/
		/** static section                              **/
		/*************************************************/
		
		private static var _penToolMenuItem:ContextMenuItem = null;
		private static var _removeDrawingsMenuItem:ContextMenuItem = null;
		private static var _changeDrawingMode:ContextMenuItem = null;
		private static var _selectRecordsMenuItem:ContextMenuItem = null;
		private static const ENABLE_PEN:String = lang("Enable Pen Tool");
		private static const DISABLE_PEN:String = lang("Disable Pen Tool");
		private static const REMOVE_DRAWINGS:String = lang("Remove All Drawings");
		private static const CHANGE_DRAWING_MODE:String = lang("Change Drawing Mode");
		private static const PEN_OBJECT_NAME:String = "penTool";
		public static const FREE_DRAW_MODE:String = "Free Draw Mode";
		public static const POLYGON_DRAW_MODE:String = "Polygon Draw Mode";
		private static const SELECT_RECORDS:String = "Select Records in Polygon";
		private static const _menuGroupName:String = "9 drawingMenuitems";
		public static function createContextMenuItems(destination:DisplayObject):Boolean
		{
			if (!destination.hasOwnProperty("contextMenu"))
				return false;
			
			// Add a listener to this destination context menu for when it is opened
			var contextMenu:ContextMenu = destination["contextMenu"] as ContextMenu;
			contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, handleContextMenuOpened);

			// Create a context menu item for printing of a single tool with title and logo
			_penToolMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination(ENABLE_PEN, destination, handlePenToolToggleMenuItem, _menuGroupName);
			_removeDrawingsMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination(REMOVE_DRAWINGS, destination, handleEraseDrawingsMenuItem, _menuGroupName);
			_changeDrawingMode = CustomContextMenuManager.createAndAddMenuItemToDestination(CHANGE_DRAWING_MODE, destination, handleChangeMode, _menuGroupName);
//			_selectRecordsMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination(SELECT_RECORDS, destination, handleSelectRecords, _menuGroupName);

			_removeDrawingsMenuItem.enabled = false;
			_changeDrawingMode.enabled = false;
			
			return true;
		}
		
		private static function handleChangeMode(e:ContextMenuEvent):void
		{
			var contextMenu:NativeMenu = (WeaveAPI.topLevelApplication as UIComponent).contextMenu;
			if (!contextMenu)
				return;
			
			var linkableContainer:ILinkableContainer = getLinkableContainer(e.mouseTarget) as ILinkableContainer;
			if (linkableContainer)
			{
				var penObject:PenTool = linkableContainer.getLinkableChildren().getObject(PEN_OBJECT_NAME) as PenTool;
				if (penObject)
				{
					// remove all the drawings and set _drawing = false
					penObject.removeAllDrawings();
					
					if (penObject.drawingMode.value == PenTool.FREE_DRAW_MODE)
					{
						penObject.drawingMode.value = PenTool.POLYGON_DRAW_MODE;
					}
					else
					{
						penObject.drawingMode.value = PenTool.FREE_DRAW_MODE;
					}

					// remove all drawings because it doesn't make sense to allow the user to 
					// select using free draw drawings.
					penObject.coords.value = "";
					
					_removeDrawingsMenuItem.enabled = true;
				}
				CustomCursorManager.showCursor(PEN_CURSOR);
			}
		}
		
		/**
		 * This function is called whenever the context menu is opened.
		 * The function will change the caption displayed depending upon if there is any drawings.
		 * This is also used to get the correct mouse pointer for the context menu.
		 */
		private static function handleContextMenuOpened(e:ContextMenuEvent):void
		{
			var contextMenu:NativeMenu = (WeaveAPI.topLevelApplication as UIComponent).contextMenu;
			if (!contextMenu)
				return;

			CustomCursorManager.hack_removeCurrentCursor();

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
						_changeDrawingMode.enabled = true;
					}
					else
					{
						_penToolMenuItem.caption = ENABLE_PEN;
						_changeDrawingMode.enabled = false;
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
		private static function handlePenToolToggleMenuItem(e:ContextMenuEvent):void
		{
			var linkableContainer:ILinkableContainer = getLinkableContainer(e.mouseTarget);
			if (!linkableContainer)
				return;

			var visualization:Visualization = getVisualization(e.mouseTarget);
			if (!visualization)
				return;
			
			var penTool:PenTool = linkableContainer.getLinkableChildren().requestObject(PEN_OBJECT_NAME, PenTool, false);
			if (_penToolMenuItem.caption == ENABLE_PEN)
			{
				// enable pen
				penTool.editMode = true;
				_penToolMenuItem.caption = DISABLE_PEN;
				_removeDrawingsMenuItem.enabled = true;
				_changeDrawingMode.enabled = true;
				CustomCursorManager.showCursor(PEN_CURSOR);
			}
			else
			{
				// disable pen
				penTool.editMode = false;
				_changeDrawingMode.enabled = false;
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

		/**
		 * @param target The UIComponent for which to get its PlotLayerContainer.
		 * @return The PlotLayerContainer visualization for the target if it has one. 
		 */		
		private static function getVisualization(mouseTarget:Object):Visualization
		{
			var linkableContainer:ILinkableContainer = getLinkableContainer(mouseTarget);
			if (!linkableContainer)
				return null;
			
			return linkableContainer.getLinkableChildren().getObjects(Visualization)[0] as Visualization;
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
		
//		/**
//		 * This function is called when the select records context menu item is clicked. 
//		 * @param e The event.
//		 */		
//		private static function handleSelectRecords(e:ContextMenuEvent):void
//		{
//			var linkableContainer:ILinkableContainer = getLinkableContainer(e.mouseTarget);
//			if (!linkableContainer)
//				return;
//			var visualization:PlotLayerContainer = getPlotLayerContainer(e.mouseTarget) as PlotLayerContainer;
//			if (!visualization)
//				return;
//			
//			var penTool:PenTool = linkableContainer.getLinkableChildren().requestObject(PEN_OBJECT_NAME, PenTool, false);
//			penTool.selectRecords();
//		}		
		
		/**
		 * Embedded cursors
		 */
		public static const PEN_CURSOR:String = "penCursor";
		[Embed(source="/weave/resources/images/penpointer.png")]
		private static var penCursor:Class;
		CustomCursorManager.registerEmbeddedCursor(PEN_CURSOR, penCursor, 3, 22);
	}
}