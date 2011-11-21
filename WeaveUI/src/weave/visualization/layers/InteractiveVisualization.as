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

package weave.visualization.layers
{
	import flash.display.Graphics;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.ui.ContextMenu;
	import flash.ui.Keyboard;
	
	import mx.containers.Canvas;
	import mx.controls.ToolTip;
	import mx.core.Application;
	
	import weave.Weave;
	import weave.api.core.IDisposableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotLayer;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.StageUtils;
	import weave.data.KeySets.KeySet;
	import weave.primitives.Bounds2D;
	import weave.utils.CustomCursorManager;
	import weave.utils.DashedLine;
	import weave.utils.ProbeTextUtils;
	import weave.utils.SpatialIndex;
	import weave.utils.ZoomUtils;
	
	/**
	 * This is a container for a list of PlotLayers
	 * 
	 * @author adufilie
	 */
	public class InteractiveVisualization extends PlotLayerContainer
	{
		public function InteractiveVisualization()
		{
			super();
			init();
		}
		
		private function init():void
		{
			doubleClickEnabled = true;
			
			enableZoomAndPan.value = true;
			enableSelection.value = true;
			enableProbe.value = true;
			enableAutoZoomToExtent.value = true;
			// adding a canvas as child gets the selection rectangle on top of the vis
			addChild(selectionRectangleCanvas);
			
			addContextMenuEventListener();
			
			addEventListener(MouseEvent.DOUBLE_CLICK, handleDoubleClick);
			addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
			addEventListener(MouseEvent.ROLL_OUT, handleRollOut);
			addEventListener(MouseEvent.ROLL_OVER, handleRollOver);
			addEventListener(MouseEvent.MOUSE_WHEEL,handleMouseWheel);
			StageUtils.addEventCallback(MouseEvent.MOUSE_MOVE, this, handleMouseMove);
			StageUtils.addEventCallback(MouseEvent.MOUSE_UP, this, handleMouseUp);
			StageUtils.addEventCallback(KeyboardEvent.KEY_DOWN, this, handleKeyboardEvent);
			StageUtils.addEventCallback(KeyboardEvent.KEY_UP, this, handleKeyboardEvent);
			StageUtils.addEventCallback(StageUtils.POINT_CLICK_EVENT, this, _handlePointClick);
			
			//			addEventListener(KeyboardEvent.KEY_DOWN, handleKeyboardEvent);
			//			addEventListener(KeyboardEvent.KEY_UP, handleKeyboardEvent);
			
			Weave.properties.dashedSelectionBox.addImmediateCallback(this, validateDashedLine, null, true);
		}
		
		private function addContextMenuEventListener():void
		{
			var contextMenu:ContextMenu = (Application.application as Application).contextMenu;
			if (!contextMenu)
				return callLater(addContextMenuEventListener);
			contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, removeCursor);
		}
		private function removeCursor(e:Event):void
		{
			CustomCursorManager.removeCurrentCursor();
		}
		
		public const enableZoomAndPan:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		public const enableSelection:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		public const enableProbe:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		
		
		private var activeKeyType:String = null;
		private var mouseDragActive:Boolean = false;
		private const selectionRectangleCanvas:Canvas = new Canvas();
		
		private const mouseDragStageCoords:IBounds2D = new Bounds2D();
		

		private var _mouseMode:String = null;
		
		private function isModeSelection(mode:String):Boolean
		{
			return mode == InteractionController.SELECT_ADD
				|| mode == InteractionController.SELECT
				|| mode == InteractionController.SELECT_REMOVE;
		}
		
		private function isModeZoom(mode:String):Boolean
		{
			return mode == InteractionController.ZOOM
				|| mode == InteractionController.ZOOM_IN
				|| mode == InteractionController.ZOOM_OUT
				|| mode == InteractionController.ZOOM_TO_EXTENT;
		}
		
		
		private function updateMouseMode(mouseEventType:String = null):void
		{
			if (mouseEventType)
				_mouseMode = Weave.properties.toolInteractions.determineMouseAction(mouseEventType);
			else
				_mouseMode = Weave.properties.toolInteractions.determineMouseMode();
			
			if (!enableZoomAndPan.value && (isModeZoom(_mouseMode) || _mouseMode == InteractionController.PAN))
			{
				_mouseMode = InteractionController.SELECT;
			}
			if (!enableSelection.value && isModeSelection(_mouseMode))
			{
				_mouseMode = null;//Weave.properties.toolInteractions.defaultDragMode.value;
			}
			
			updateMouseCursor();
		}
		
		private var _selectModeCursorOffsetX:int = -2;
		private var _selectModeCursorOffsetY:int = -2;
		private function updateMouseCursor():void
		{
			if (mouseIsRolledOver)
			{
				if (_mouseMode == InteractionController.PAN)
				{
					if (StageUtils.mouseButtonDown)
						CustomCursorManager.showCursor(CustomCursorManager.HAND_GRAB_CURSOR);
					else
						CustomCursorManager.showCursor(CustomCursorManager.HAND_CURSOR);
				}
				else if (_mouseMode == InteractionController.SELECT_ADD)
				{
					CustomCursorManager.showCursor(CustomCursorManager.SELECT_ADD_CURSOR, 2, _selectModeCursorOffsetX, _selectModeCursorOffsetY);
				}
				else if (_mouseMode == InteractionController.SELECT || _mouseMode == InteractionController.PROBE)
				{
					CustomCursorManager.showCursor(CustomCursorManager.SELECT_REPLACE_CURSOR, 2, _selectModeCursorOffsetX, _selectModeCursorOffsetY);
				}	
				else if (_mouseMode == InteractionController.SELECT_REMOVE)
				{
					CustomCursorManager.showCursor(CustomCursorManager.SELECT_SUBTRACT_CURSOR, 2, _selectModeCursorOffsetX, _selectModeCursorOffsetY);
				}
				else if (_mouseMode == InteractionController.ZOOM)
				{
					CustomCursorManager.showCursor(CustomCursorManager.ZOOM_CURSOR);
				}
			}
		}
		
		private function handleKeyboardEvent():void
		{
			// if the escape key was hit, stop whatever mouse drag operation is in progress
			if (StageUtils.keyboardEvent && StageUtils.keyboardEvent.keyCode == Keyboard.ESCAPE)
			{
				mouseDragActive = false;			
			}
			
			// if currently dragging, don't change mouse mode
			if (!mouseDragActive)
				updateMouseMode();
		}
		
		/**
		 * This function gets called whenever StageUtils runs point click event callbacks.
		 * This function should remain private.
		 */
		private function _handlePointClick():void
		{
			// only handle the event if the mouse is rolled over
			if (mouseIsRolledOver)
				handleMouseClick(StageUtils.mouseEvent);
		}
		
		// this function can be defined with override by extending classes and call super.handleMouseClick(event);
		protected function handleMouseClick(event:MouseEvent):void
		{
			clearSelection();
			handleMouseEvent(event);
		}
		
		
		protected function handleDoubleClick(event:MouseEvent):void
		{								
			handleMouseEvent(event);			
		}
		
		protected function handleMouseDown(event:MouseEvent):void
		{			
			updateMouseMode(InteractionController.DRAG); // modifier keys may have changed just prior to pressing mouse button, so update mode now
			
			mouseDragActive = true;
			// clear probe when drag starts
			clearProbe();
			// start the selection rectangle from the mouse down point
			// for accuracy, use the stage coordinates from the event, not the current coordinates from the stage
			mouseDragStageCoords.setCenteredRectangle(event.stageX, event.stageY, 0, 0);
			
			handleMouseEvent(event);
		}
		protected function handleMouseUp():void
		{
			updateMouseCursor();
			
			// when the mouse is released, handle mouse move so the selection rectangle will cause the selection to update.
			handleMouseEvent(StageUtils.mouseEvent);
		}
		protected function handleMouseMove():void
		{
			handleMouseEvent(StageUtils.mouseEvent);		
		}
		protected function handleRollOut(event:MouseEvent):void
		{
			if (mouseIsRolledOver)
			{
				CustomCursorManager.removeAllCursors();
				mouseIsRolledOver = false;
				
				// when rolled over goes from true to false, clear the probe
				clearProbe();
			}
			handleMouseEvent(event);
			
			updateMouseCursor();
		}
		protected function handleRollOver(event:MouseEvent):void
		{
			mouseIsRolledOver = true;
			handleMouseEvent(event);
			
			updateMouseCursor();
		}
		
		protected var mouseIsRolledOver:Boolean = false; // start this at false because we don't want tools probing when mouse is not rolled over
		
		private const _tempBounds:IBounds2D = new Bounds2D();
		private const _screenBounds:IBounds2D = new Bounds2D();
		protected function handleMouseWheel(event:MouseEvent):void
		{
			if (Weave.properties.enableMouseWheel.value)
				handleMouseEvent(event);
		}		
		
		protected function handleMouseEvent(event:MouseEvent):void
		{
			// determine proper event type
			var eventType:String = null;
			switch (event.type)
			{
				case MouseEvent.CLICK:
				{
					eventType = InteractionController.CLICK;
					break;
				}
				case MouseEvent.DOUBLE_CLICK:
				{
					if (!mouseIsRolledOver)
						return;
					
					eventType = InteractionController.DCLICK;
					break;
				}
				case MouseEvent.MOUSE_MOVE:
				case MouseEvent.ROLL_OVER:
				case MouseEvent.ROLL_OUT:
				{
					if (event.buttonDown)
						eventType = InteractionController.DRAG;
					else
						eventType = InteractionController.MOVE;
					
					break;
				}
				case MouseEvent.MOUSE_WHEEL:
				{
					eventType = InteractionController.WHEEL;
					break;
				}
			}
			
			// if currently dragging, update drag coords and don't change mouse mode
			if (mouseDragActive)
			{
				// update end coordinates of selection rectangle
				if (event.type == MouseEvent.MOUSE_UP)
				{
					// on a mouse up event, we want accuracy, so use the mouse up event coordinates
					mouseDragStageCoords.setMaxCoords(event.stageX, event.stageY);
				}
				else
				{
					// IMPORTANT: for speed, use the current mouse coordinates instead of the event coordinates
					mouseDragStageCoords.setMaxCoords(stage.mouseX, stage.mouseY);
				}
			}
			else // not dragging -- ok to update mouse mode
			{
				updateMouseMode(eventType);
			}
			
			var dragReleased:Boolean = mouseDragActive && !event.buttonDown;
			switch (_mouseMode)
			{
				case InteractionController.SELECT_ADD:
				{
					if (mouseDragActive)
						handleSelection(event, _mouseMode);
					break;
				}
				case InteractionController.SELECT:
				{
					if (mouseDragActive)
						handleSelection(event, _mouseMode);
					break;
				}
				case InteractionController.SELECT_REMOVE:
				{
					if (mouseDragActive)
						handleSelection(event, _mouseMode);
					break;
				}
				case InteractionController.PAN:
				{
					if (enableZoomAndPan.value && mouseDragActive)
					{
						// pan the dragged distance
						projectDragBoundsToDataQueryBounds(null, false);
						zoomBounds.getDataBounds(tempDataBounds);
						tempDataBounds.setCenter(tempDataBounds.getXCenter() - queryBounds.getWidth(), tempDataBounds.getYCenter() - queryBounds.getHeight());
						zoomBounds.setDataBounds(tempDataBounds);
						// set begin point for next pan
						mouseDragStageCoords.getMaxPoint(tempPoint);
						mouseDragStageCoords.setMinPoint(tempPoint);
					}
					break;
				}
				case InteractionController.ZOOM:
				{
					if (enableZoomAndPan.value)
					{
						if (eventType == InteractionController.WHEEL)
						{
							zoomBounds.getDataBounds(_tempBounds);
							zoomBounds.getScreenBounds(_screenBounds);
							if (event.delta > 0)
								ZoomUtils.zoomDataBoundsByRelativeScreenScale(_tempBounds,_screenBounds,mouseX,mouseY,2,false);
							else if (event.delta < 0)
								ZoomUtils.zoomDataBoundsByRelativeScreenScale(_tempBounds,_screenBounds,mouseX,mouseY,0.5,false);
							zoomBounds.setDataBounds(_tempBounds);
						}
						else if (dragReleased)
						{
							// zoom to selected data bounds if area > 0
							projectDragBoundsToDataQueryBounds(null, true); // data bounds in same direction when zooming
							if (queryBounds.getArea() > 0)
								zoomBounds.setDataBounds(queryBounds);
						}
					}
					break;
				}
				case InteractionController.PROBE:
				{
					if (mouseIsRolledOver)
					{
						// probe when mouse is rolled over and selection is inactive
						handleProbe();
					}
					
					break;
				}
				case InteractionController.ZOOM_TO_EXTENT:
				{
					if (enableZoomAndPan.value)
						zoomBounds.setDataBounds(fullDataBounds, true); // zoom to full extent
					break;
				}
				case InteractionController.ZOOM_IN:
				case InteractionController.ZOOM_OUT:
				{
					if (enableZoomAndPan.value)
					{
						var multiplier:Number = 1;
						if (_mouseMode == InteractionController.ZOOM_IN)
							multiplier = 0.5; // zoom in 2x
						else
							multiplier = 2; // zoom out 2x
						
						projectDragBoundsToDataQueryBounds(null, false);
						zoomBounds.getDataBounds(_tempBounds);
						_tempBounds.setCenter(queryBounds.getXCenter(), queryBounds.getYCenter());
						
						_tempBounds.centeredResize(_tempBounds.getWidth() * multiplier, _tempBounds.getHeight() * multiplier);
						
						zoomBounds.setDataBounds(_tempBounds);
					}
					break;
				}
			}
			
			// finally, unset mouseDragActive if button was released
			if (dragReleased)
			{
				mouseDragActive = false;
			}
			
//			if (_mouseMode == InteractionController.DCLICK
//				&& mouseIsRolledOver
//				&& !(	enableZoomAndPan.value
//						&& _mouseMode != InteractionController.SELECT_ADD
//						&& _mouseMode != InteractionController.SELECT_REMOVE	))
//			{
//				selectAllVisibleRecords();
//			}
			
			updateSelectionRectangleGraphics();
		}
		
		//TODO - use this
		private function selectAllVisibleRecords():void
		{
			// clear selection or select all
			
			// set up mouse drag rectangle to select or deselect visible area
			zoomBounds.getScreenBounds(_screenBounds);
			_screenBounds.getMinPoint(tempPoint);
			mouseDragStageCoords.setMinPoint(localToGlobal(tempPoint));
			_screenBounds.getMaxPoint(tempPoint);
			mouseDragStageCoords.setMaxPoint(localToGlobal(tempPoint));
			
			immediateHandleSelection();
		}
		
		private var _selectionRectangleGraphicsCleared:Boolean = true;
		protected function updateSelectionRectangleGraphics():void 
		{
			if (!Weave.properties.enableToolSelection.value || !enableSelection.value) return;
			var g:Graphics = selectionRectangleCanvas.graphics;
			if (!_selectionRectangleGraphicsCleared)
				g.clear(); 
			
			if (!mouseDragActive || _mouseMode == InteractionController.PAN)
			{
				_selectionRectangleGraphicsCleared = true;
				return;
			}
			
			_selectionRectangleGraphicsCleared = false; 
			
			mouseDragStageCoords.getMinPoint(tempPoint); // stage coords
			var localMinPoint:Point = selectionRectangleCanvas.globalToLocal(tempPoint); // local screen coords
			mouseDragStageCoords.getMaxPoint(tempPoint); // stage coords
			var localMaxPoint:Point = selectionRectangleCanvas.globalToLocal(tempPoint); // local screen coords
			
			tempScreenBounds.setMinPoint(localMinPoint);
			tempScreenBounds.setMaxPoint(localMaxPoint);
			
			// use a blue rectangle for zoom mode, green for selection
			_dashedLine.graphics = g; 
			if (_mouseMode == InteractionController.ZOOM)
			{
				_dashedLine.lineStyle(2, 0x00faff, .75);
			}
			else
			{
				_dashedLine.lineStyle(2, 0x00ff00, .75);
			}
			
			
			var startCorner:int;
			// if height < 0, then the box is dragged upward
			// if width < 0, then the box is dragged leftward
			if (tempScreenBounds.getHeight() < 0)
			{
				if (tempScreenBounds.getWidth() < 0)
					startCorner = DashedLine.BOTTOM_RIGHT;
				else
					startCorner = DashedLine.BOTTOM_LEFT;
			}
			else 
			{
				if (tempScreenBounds.getWidth() < 0)
					startCorner = DashedLine.TOP_RIGHT;
				else
					startCorner = DashedLine.TOP_LEFT;
			}
			
			var xStart:Number = tempScreenBounds.getXMin();
			var yStart:Number = tempScreenBounds.getYMin();
			var width:Number = tempScreenBounds.getXCoverage();
			var height:Number = tempScreenBounds.getYCoverage();
			
			_dashedLine.drawRect(xStart, yStart, width, height, startCorner); // this draws onto the _selectionRectangleCanvas.graphics
		}
		
		private const _dashedLine:DashedLine = new DashedLine(0, 0, null);
		private function validateDashedLine():void
		{
			_dashedLine.lengthsString = Weave.properties.dashedSelectionBox.value;
		}
		
		private function handleSelection(event:MouseEvent,mode:String):void
		{
			var _layers:Array;
			var i:int;
			var layer:SelectablePlotLayer;
			
			// update end coordinates of selection rectangle
			if (event.type == MouseEvent.MOUSE_UP)
			{
				// on a mouse up event, we want accuracy, so use the mouse up event coordinates
				mouseDragStageCoords.setMaxCoords(event.stageX, event.stageY);
			}
			else
			{
				// IMPORTANT: for speed, use the current mouse coordinates instead of the event coordinates
				mouseDragStageCoords.setMaxCoords(stage.mouseX, stage.mouseY);
			}
			
			if ( isModeSelection(mode) )
			{
				// only if selection is enabled
				if (enableSelection.value)
				{
					// handle selection
					if (mode == InteractionController.SELECT && mouseDragStageCoords.getWidth() == 0 && mouseDragStageCoords.getHeight() == 0)
					{
						// clear selection when drag area is empty
						clearSelection();
					}
					else
					{
						delayedHandleSelection();
					}
				}
			}
		}
		
		private function clearSelection():void
		{
			var _layers:Array = layers.getObjects(SelectablePlotLayer);
			for (var i:int = 0; i < _layers.length; i++)
			{
				setSelectionKeys(_layers[i], []);
			}
		}
		
		/**
		 * This function projects drag start,stop screen coordinates into data coordinates and stores the result in queryBounds.
		 * @param layer If layer is null, InteractiveVisualization's screen/data bounds will be used.  Otherwise, uses IPlotLayer's bounds.
		 * @param zooming Specify true when computing zoom coordinates.
		 */		
		protected function projectDragBoundsToDataQueryBounds(layer:IPlotLayer, zooming:Boolean):void
		{
			if (layer)
			{
				layer.getDataBounds(tempDataBounds);
				layer.getScreenBounds(tempScreenBounds);
			}
			else
			{
				zoomBounds.getDataBounds(tempDataBounds);
				zoomBounds.getScreenBounds(tempScreenBounds);
			}
			
			// project stage coords to local layer coords
			mouseDragStageCoords.getMinPoint(tempPoint); // stage coords
			var localMinPoint:Point = globalToLocal(tempPoint); // local screen coords
			mouseDragStageCoords.getMaxPoint(tempPoint); // stage coords
			var localMaxPoint:Point = globalToLocal(tempPoint); // local screen coords
			
			// project screen coords to data coords
			tempScreenBounds.projectPointTo(localMinPoint, tempDataBounds);
			tempScreenBounds.projectPointTo(localMaxPoint, tempDataBounds);
			
			// query the spatial index, set selection
			queryBounds.setMinPoint(localMinPoint);
			queryBounds.setMaxPoint(localMaxPoint);
			
			if (zooming)
			{
				// swap min,max coordinates if necessary
				if (queryBounds.getXDirection() != tempDataBounds.getXDirection())
					queryBounds.setXRange(queryBounds.getXMax(), queryBounds.getXMin());
				if (queryBounds.getYDirection() != tempDataBounds.getYDirection())
					queryBounds.setYRange(queryBounds.getYMax(), queryBounds.getYMin());
				
				// expand rectangle if necessary to match screen aspect ratio
				var xScale:Number = queryBounds.getXCoverage() / tempScreenBounds.getXCoverage();
				var yScale:Number = queryBounds.getYCoverage() / tempScreenBounds.getYCoverage();
				if (xScale > yScale)
					queryBounds.setHeight( queryBounds.getYDirection() * tempScreenBounds.getYCoverage() * xScale );
				if (yScale > xScale)
					queryBounds.setWidth( queryBounds.getXDirection() * tempScreenBounds.getXCoverage() * yScale );
			}
		}
		
		protected function delayedHandleSelection(allowCallLater:Boolean = true):void
		{
			if (!parent)
				return;
			
			if (StageUtils.mouseMoved)
			{
				if (allowCallLater)
					callLater(delayedHandleSelection, [false]);
			}
			else
			{
				// handle selection when mouse hasn't moved since last frame.
				immediateHandleSelection();
			}
		}
		
		protected function immediateHandleSelection():void
		{
			// don't set a selection or clear the probe keys if selection is disabled
			if (!enableSelection.value)
				return;
			
			var _layers:Array = layers.getObjects(SelectablePlotLayer); // bottom to top
			// loop from bottom layer to top layer
			for (var index:int = 0; index < _layers.length; index++)
			{
				var layer:SelectablePlotLayer = _layers[index] as SelectablePlotLayer;
				// skip this layer if it is disabled
				if (!layer.layerIsVisible.value || !layer.layerIsSelectable.value)
					continue;
				// skip this layer if it does not contain lastProbedQKey
				if (_lastProbedQKey && !layer.plotter.keySet.containsKey(_lastProbedQKey))
					continue;
				
				// when using the selection layer, clear the probe
				setProbeKeys(layer, []);
				projectDragBoundsToDataQueryBounds(layer, false);
				
				
				// calculate minImportance
				layer.getDataBounds(tempDataBounds);
				layer.getScreenBounds(tempScreenBounds);
				var minImportance:Number = tempDataBounds.getArea() / tempScreenBounds.getArea();
				
				// don't query outside visible data bounds
				if (!tempDataBounds.overlaps(queryBounds))
					continue;
				tempDataBounds.constrainBounds(queryBounds, false);
				
				var keys:Array = (layer.spatialIndex as SpatialIndex).getKeysGeometryOverlap(queryBounds, minImportance, false);
				setSelectionKeys(layer, keys, true);
				
				break; // select only one layer at a time
			}
		}
		
		/**
		 * This is the last IQualifiedKey (record identifier) that was probed.
		 */
		public function get lastProbedKey():IQualifiedKey { return _lastProbedQKey; }
		private var _lastProbedQKey:IQualifiedKey = null;
		
		protected function handleProbe(allowCallLater:Boolean = true):void
		{
			if (!parent || !Weave.properties.enableToolProbe.value || !enableProbe.value)
				return;
			
			// NOTE: this code is hacked to work with only one global probe KeySet
			
			// only probe if the mouse coords are the same two frames in a row
			if (StageUtils.mouseMoved)
			{
				if (allowCallLater)
					callLater(handleProbe, [false]);
			}
			else if (mouseIsRolledOver)
			{
				// handle probe when mouse hasn't moved since last frame.
				var _layers:Array = layers.getObjects(SelectablePlotLayer).reverse(); // top to bottom
				var lastActiveLayer:SelectablePlotLayer = null;
				for (var i:int = 0; i < _layers.length; i++)
				{
					var layer:SelectablePlotLayer = _layers[i];
					if (!layer.layerIsVisible.value || !layer.layerIsSelectable.value)
						continue;
					
					lastActiveLayer = layer;
					
					layer.getDataBounds(tempDataBounds);
					layer.getScreenBounds(tempScreenBounds);
					//trace(layers.getName(layer),tempDataBounds,tempScreenBounds);
					
					// get data coords from screen coords
					var buffer:Number = 10; 
					
					tempPoint.x = mouseX - buffer;
					tempPoint.y = mouseY - buffer;
					tempScreenBounds.projectPointTo(tempPoint, tempDataBounds);
					queryBounds.setMinPoint(tempPoint);
					
					tempPoint.x = mouseX + buffer;
					tempPoint.y = mouseY + buffer;
					tempScreenBounds.projectPointTo(tempPoint, tempDataBounds);
					queryBounds.setMaxPoint(tempPoint);
					
					var xPrecision:Number = tempDataBounds.getXCoverage() / tempScreenBounds.getXCoverage();
					var yPrecision:Number = tempDataBounds.getYCoverage() / tempScreenBounds.getYCoverage();
					
					//trace(layers.getName(layer),queryBounds);
					
					// probe for records
					
					if (!tempDataBounds.overlaps(queryBounds))
						continue;
					tempDataBounds.constrainBounds(queryBounds, false);
					var keys:Array = (layer.spatialIndex as SpatialIndex).getClosestOverlappingKeys( queryBounds, xPrecision, yPrecision );
					//trace(layers.getName(layer),keys);
					
					// stop when we find keys
					if (keys.length > 0)
					{
						setProbeKeys(layer, keys);
						_lastProbedQKey = keys[0] as IQualifiedKey;
						
						return;
					}
				}
				// clear keys if nothing was probed
				// NOTE: this code is hacked to work with only one global probe KeySet
				if (lastActiveLayer)
					setProbeKeys(lastActiveLayer, []);
			}
			// either not rolled over or nothing was probed
			_lastProbedQKey = null;
		}
		
		protected function setSelectionKeys(layer:SelectablePlotLayer, keys:Array, useMouseMode:Boolean = false):void
		{
			if (!Weave.properties.enableToolSelection.value || !enableSelection.value)
				return;
			
			// set the probe filter to a new set of keys
			var keySet:KeySet = layer.selectionFilter.internalObject as KeySet;
			if (keySet != null)
			{
				if (useMouseMode && _mouseMode == InteractionController.SELECT_ADD)
					keySet.addKeys(keys);
				else if (useMouseMode && _mouseMode == InteractionController.SELECT_REMOVE)
					keySet.removeKeys(keys);
				else
					keySet.replaceKeys(keys);
			}
		}
		
		protected function setProbeKeys(layer:SelectablePlotLayer, keys:Array):void
		{
			//trace("setProbeKeys()",keys);
			// set the probe filter to a new set of keys
			var keySet:KeySet = layer.probeFilter.internalObject as KeySet;
			
			if (keySet != null)
			{
				keySet.replaceKeys(keys);
				
				if (keys.length == 0)
				{
					ProbeTextUtils.destroyProbeToolTip();
				}
				else
				{
					var text:String = ProbeTextUtils.getProbeText(keySet.keys, additionalProbeColumns);
					ToolTip.maxWidth = Weave.properties.probeToolTipMaxWidth.value;
					ProbeTextUtils.showProbeToolTip(text, stage.mouseX, stage.mouseY);
				}
			}
		}
		
		/**
		 * An array of additional columns to be displayed in the probe tooltip for this visualization instance 
		 */		
		public var additionalProbeColumns:Array = null;
		
		protected function clearProbe():void
		{
			// don't clear the probe if selection is disabled
			if (!enableSelection.value)
				return;
			
			var spls:Array = layers.getObjects(SelectablePlotLayer);
			for (var i:int = 0; i < spls.length; i++)
				setProbeKeys(spls[i], emptyArray);
		}
		private const emptyArray:Array = [];
		protected const queryBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		protected const tempDataBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		protected const tempScreenBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		private const tempPoint:Point = new Point(); // reusable temporary object
		
		//-----------------------------------------------
		// backwards compatibility
		[Deprecated(replacement="InteractionController.defaultDragMode")] public function set defaultMouseMode(value:String):void
		{
			var backwardsCompatibility:Object = {
				"InteractiveVisualization.SELECT_MODE_REPLACE": InteractionController.SELECT,
				"InteractiveVisualization.SELECT_MODE_SUBTRACT": InteractionController.SELECT_REMOVE,
				"InteractiveVisualization.SELECT_MODE_ADD": InteractionController.SELECT_ADD,
				"InteractiveVisualization.PAN_MODE": InteractionController.PAN,
				"InteractiveVisualization.ZOOM_MODE": InteractionController.ZOOM
			};
			Weave.properties.toolInteractions.defaultDragMode.value = backwardsCompatibility[value];
		}
	}
}
