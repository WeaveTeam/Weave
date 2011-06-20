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
	
	import mx.containers.Canvas;
	import mx.core.Application;
	import mx.utils.ObjectUtil;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.core.IDisposableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
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
	public class InteractiveVisualization extends PlotLayerContainer implements IDisposableObject
	{
		public function InteractiveVisualization()
		{
			super();
			init();
		}
		
		private var plotShadow:DropShadowFilter 	= new DropShadowFilter(1, 45, 0x000000, 0.2, 0, 0, 1);
		private function init():void
		{
			doubleClickEnabled = true;
			
			enableZoomAndPan.value = true;
			enableAutoZoomToExtent.value = true;
			// adding a canvas as child gets the selection rectangle on top of the vis
			addChild(selectionRectangleCanvas);
			
			shadowAmount.value = 0;

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
			
			defaultMouseMode.value = SELECT_MODE_REPLACE;
		}
		
		public function dispose():void
		{
			removeEventListener(MouseEvent.CLICK, handleMouseClick);
			removeEventListener(MouseEvent.DOUBLE_CLICK, handleDoubleClick);
			removeEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
			removeEventListener(MouseEvent.ROLL_OUT, handleRollOut);
			removeEventListener(MouseEvent.ROLL_OVER, handleRollOver);
		}
		
		private function addContextMenuEventListener():void
		{
			var contextMenu:ContextMenu = (Application.application as Application).contextMenu;
			if (!contextMenu)
				return callLater(addContextMenuEventListener);
			contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, function(e:Event):void {
				CustomCursorManager.removeCurrentCursor();
			});
		}
		
		public const shadowAmount:LinkableNumber = newLinkableChild(this, LinkableNumber, updateShadow);
		private function updateShadow():void
		{
			if (shadowAmount.value == 0)
			{
				filters = null;
				return;
			}
			
			var amount:Number = shadowAmount.value / 100;
			
			plotShadow.distance = 1 + (1 * amount);
			plotShadow.alpha = amount;
			plotShadow.blurX = 2 * amount;
			plotShadow.blurY = 2 * amount;
			
			filters = [plotShadow];
		}
		
		public const enableZoomAndPan:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		
		protected var activeKeyType:String = null;
		protected var mouseDragActive:Boolean = false;
		protected var selectionRectangleCanvas:Canvas = new Canvas();
		
		protected const mouseDragStageCoords:IBounds2D = new Bounds2D();
		
		public static const SELECT_MODE_SUBTRACT:String  = "InteractiveVisualization.SELECT_MODE_SUBTRACT";
		public static const SELECT_MODE_REPLACE:String  	= "InteractiveVisualization.SELECT_MODE_REPLACE";
		public static const SELECT_MODE_ADD:String  = "InteractiveVisualization.SELECT_MODE_ADD";
		public static const PAN_MODE:String 	= "InteractiveVisualization.PAN_MODE";
		public static const ZOOM_MODE:String 	= "InteractiveVisualization.ZOOM_MODE";
		public static const NO_CURSOR:String    = "InteractiveVisualization.NO_CURSOR";

		private function isModeSelection(mode:String):Boolean
		{
			return mode == SELECT_MODE_ADD
				|| mode == SELECT_MODE_REPLACE
				|| mode == SELECT_MODE_SUBTRACT;
		}
		
		public const defaultMouseMode:LinkableString = newLinkableChild(this, LinkableString, handleMouseModeChange);
		
		
		
        

		protected function handleMouseModeChange():void
		{
			// stop whatever current mouse drag action is active
			mouseDragActive = false;
			
			updateMouseCursor();  
		}
		  
		private var _temporaryMouseMode:String = null;
		protected function updateTemporaryMouseMode():void
		{
			var shift:Boolean = StageUtils.shiftKey;
			var alt:Boolean   = StageUtils.altKey;
			var ctrl:Boolean  = StageUtils.ctrlKey;

			

			// control only for select add
			if (ctrl && !shift && !alt )
				_temporaryMouseMode = SELECT_MODE_ADD;
			// control and shift only for select subtract
			else if (ctrl && shift && !alt)
				_temporaryMouseMode = SELECT_MODE_SUBTRACT;
			// control and alt only for select replace
			else if (ctrl && alt && !shift)
				_temporaryMouseMode = SELECT_MODE_REPLACE;
			else
				_temporaryMouseMode = null;
			
			// if panning and zooming is enabled, check for its key commands
			if (enableZoomAndPan.value)
			{
				// shift only for zoom
				if (shift && !alt && !ctrl)
					_temporaryMouseMode = ZOOM_MODE;
				// alt only for pan
				else if (alt && !shift &&!ctrl)
					_temporaryMouseMode = PAN_MODE;
			}
				
			updateMouseCursor();
		}
		
		public function hideMouseCursors():void
		{
			_temporaryMouseMode = NO_CURSOR;
			updateMouseCursor();
		}
		
		private var _selectModeCursorOffsetX:int = -2;
		private var _selectModeCursorOffsetY:int = -2;
		private function updateMouseCursor():void
		{
			var mode:String = _temporaryMouseMode ? _temporaryMouseMode : defaultMouseMode.value;
			
			
			// commented out because there were complaints/"bug" reports about this
			/* 
			if(StageUtils.previousFrameElapsedTime > 75)
			{
				CursorManager.removeCursor(CursorManager.currentCursorID);
				callLater(updateMouseCursor);
				return;
			}
			*/
				
			//resumeBackgroundProcessing()
			//suspendBackgroundProcessing()

			if(mouseIsRolledOver)
			{
				if(mode == PAN_MODE)
				{
					if(_mouseDown)
						CustomCursorManager.showCursor(CustomCursorManager.HAND_GRAB_CURSOR);
					else
						CustomCursorManager.showCursor(CustomCursorManager.HAND_CURSOR);
				}
				else if(mode == SELECT_MODE_ADD)
				{
					CustomCursorManager.showCursor(CustomCursorManager.SELECT_ADD_CURSOR, 2, _selectModeCursorOffsetX, _selectModeCursorOffsetY);
				}
				else if(mode == SELECT_MODE_REPLACE)
				{
					CustomCursorManager.showCursor(CustomCursorManager.SELECT_REPLACE_CURSOR, 2, _selectModeCursorOffsetX, _selectModeCursorOffsetY);
				}	
				else if(mode == SELECT_MODE_SUBTRACT)
				{
					CustomCursorManager.showCursor(CustomCursorManager.SELECT_SUBTRACT_CURSOR, 2, _selectModeCursorOffsetX, _selectModeCursorOffsetY);
				}
				else if(mode == ZOOM_MODE)
				{
					CustomCursorManager.showCursor(CustomCursorManager.ZOOM_CURSOR);
				}
			}
		}
		
		protected function handleKeyboardEvent():void
		{
			// if the escape key was hit, stop whatever mouse drag operation is in progress
			if(StageUtils.keyboardEvent && (StageUtils.keyboardEvent.keyCode == 27))
				mouseDragActive = false;

			// if currently dragging, don't change mouse mode
			if (!mouseDragActive)
				updateTemporaryMouseMode();
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
		}
		
		
		protected function handleDoubleClick(event:MouseEvent):void
		{
			var mode:String = _temporaryMouseMode ? _temporaryMouseMode : defaultMouseMode.value;
			
			if (!mouseIsRolledOver)
				return;

			if (enableZoomAndPan.value && mode != SELECT_MODE_ADD && mode != SELECT_MODE_SUBTRACT)
			{
				if (event.ctrlKey && event.shiftKey)
				{
					// zoom to full extent
					dataBounds.copyFrom(fullDataBounds);
				}
				else
				{
					// zoom in or out 2x

					var zoomOut:Boolean = (event.ctrlKey || event.shiftKey);

					projectDragBoundsToDataQueryBounds(false);
					dataBounds.copyTo(_tempBounds);
					_tempBounds.setCenter(queryBounds.getXCenter(), queryBounds.getYCenter());
					
					var multiplier:Number = zoomOut ? 2 : 0.5;
					_tempBounds.centeredResize(_tempBounds.getWidth() * multiplier, _tempBounds.getHeight() * multiplier);

					dataBounds.copyFrom(_tempBounds);
				}
			}
			else
			{
				// clear selection or select all

				// set up mouse drag rectangle to select or deselect visible area
				getScreenBounds(_screenBounds);
				_screenBounds.getMinPoint(tempPoint);
				mouseDragStageCoords.setMinPoint(localToGlobal(tempPoint));
				_screenBounds.getMaxPoint(tempPoint);
				mouseDragStageCoords.setMaxPoint(localToGlobal(tempPoint));

				immediateHandleSelection();
			}
		}
		
		private var _mouseDown:Boolean = false;
		protected function handleMouseDown(event:MouseEvent):void
		{
			_mouseDown = true;
			
			updateMouseCursor();
			
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
			_mouseDown = false;
			
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
		
		private var _tempBounds:IBounds2D = new Bounds2D();
		private var _screenBounds:IBounds2D = new Bounds2D();
		protected function handleMouseWheel(event:MouseEvent):void
		{
			if (Weave.properties.enableMouseWheel.value && enableZoomAndPan.value)
			{
				dataBounds.copyTo(_tempBounds);
				getScreenBounds(_screenBounds);
				if(event.delta > 0)
					ZoomUtils.zoomDataBoundsByRelativeScreenScale(_tempBounds,_screenBounds,mouseX,mouseY,2,false);
				else if(event.delta < 0)
						ZoomUtils.zoomDataBoundsByRelativeScreenScale(_tempBounds,_screenBounds,mouseX,mouseY,0.5,false);
				dataBounds.copyFrom(_tempBounds);
			}
		}
		
		
		protected function handleMouseEvent(event:MouseEvent):void
		{
			var mode:String = _temporaryMouseMode ? _temporaryMouseMode : defaultMouseMode.value;
			
			
			var dragReleased:Boolean = false;
			var i:int;
			var _layers:Array;
			var layer:SelectablePlotLayer;
			
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
				
				if (!event.buttonDown)
					dragReleased = true;

				if ( isModeSelection(mode) )
				{
					// handle selection
					if (mode == SELECT_MODE_REPLACE && mouseDragStageCoords.getWidth() == 0 && mouseDragStageCoords.getHeight() == 0)
					{
						_layers = layers.getObjects(SelectablePlotLayer);
						for (i = 0; i < _layers.length; i++)
						{
							// clear selection when drag area is empty
							setSelectionKeys(_layers[i], []);
						}
					}
					else
					{
						delayedHandleSelection();
					}
				}
				else if (mode == PAN_MODE)
				{
					// pan the dragged distance
					projectDragBoundsToDataQueryBounds(false);
					dataBounds.copyTo(tempDataBounds);
					tempDataBounds.setCenter(tempDataBounds.getXCenter() - queryBounds.getWidth(), tempDataBounds.getYCenter() - queryBounds.getHeight());
					dataBounds.copyFrom(tempDataBounds);
					// set begin point for next pan
					mouseDragStageCoords.setMinPoint(mouseDragStageCoords.getMaxPoint(tempPoint));
				}
				else if (mode == ZOOM_MODE)
				{
					if (dragReleased)
					{
						// zoom to selected data bounds if area > 0
						projectDragBoundsToDataQueryBounds();
						if (queryBounds.getArea() > 0)
							dataBounds.copyFrom(queryBounds);
					}
				}
			}
			else // mouseDragActive == false
			{
				// only update mouse mode when mouse drag isn't active
				updateTemporaryMouseMode();
				
				if (mouseIsRolledOver && !event.buttonDown)
				{
					// probe when mouse is rolled over and selection is inactive
					handleProbe();
				}
			}
			
			// stop drag when the mouse button is released
			if (dragReleased)
				mouseDragActive = false;
				
			updateSelectionRectangleGraphics(event.stageX, event.stageY);
			//updateMouseCursor();
		}
		
		private var _selectionRectangleGraphicsCleared:Boolean = true;
		protected function updateSelectionRectangleGraphics(currentX:Number, currentY:Number):void 
		{
			var mouseMode:String = _temporaryMouseMode ? _temporaryMouseMode : defaultMouseMode.value;
			 
			if(!Weave.properties.enableToolSelection.value) return;
			var g:Graphics = selectionRectangleCanvas.graphics;
			if (!_selectionRectangleGraphicsCleared)
				g.clear(); 
			
			if (!mouseDragActive || mouseMode == PAN_MODE)
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
			if(mouseMode == ZOOM_MODE)
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
		
		protected function projectDragBoundsToDataQueryBounds(sameDirection:Boolean = true):void
		{
			dataBounds.copyTo(tempDataBounds);
			getScreenBounds(tempScreenBounds);
			
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
			
			if (sameDirection)
			{
				if (queryBounds.getXDirection() != tempDataBounds.getXDirection())
					queryBounds.setXRange(queryBounds.getXMax(), queryBounds.getXMin());
				if (queryBounds.getYDirection() != tempDataBounds.getYDirection())
					queryBounds.setYRange(queryBounds.getYMax(), queryBounds.getYMin());
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
			var _layers:Array = layers.getObjects(SelectablePlotLayer); // bottom to top
			// loop from bottom layer to top layer
			for (var index:int = 0; index < _layers.length; index++)
			{
				var layer:SelectablePlotLayer = _layers[index] as SelectablePlotLayer;
				// skip this layer if it is disabled
				if (!layer.layerIsVisible.value || !layer.layerIsSelectable.value)
					continue;
				// skip this layer if it does not contain lastProbedQKey
				if (lastProbedQKey && !layer.plotter.keySet.containsKey(lastProbedQKey))
					continue;

				// when using the selection layer, clear the probe
				setProbeKeys(layer, []);
				projectDragBoundsToDataQueryBounds();
				
				
				// calculate minImportance
				layer.getDataBounds(tempDataBounds);
				layer.getScreenBounds(tempScreenBounds);
				if (!tempDataBounds.overlaps(queryBounds))
					continue;
				tempDataBounds.constrainBounds(queryBounds, false);	
				var keys:Array = (layer.spatialIndex as SpatialIndex).getKeysOverlappingBounds(queryBounds, tempDataBounds.getArea() / tempScreenBounds.getArea());
				setSelectionKeys(layer, keys, true);
				
				break; // select only one layer at a time
			}
		}
		
		/**
		 * This is the last IQualifiedKey (record identifier) that was probed.
		 */
		private var lastProbedQKey:IQualifiedKey = null;
		
		protected function handleProbe(allowCallLater:Boolean = true):void
		{
			if (!parent || !Weave.properties.enableToolProbe.value)
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
						lastProbedQKey = keys[0] as IQualifiedKey;
						
						return;
					}
				}
				// clear keys if nothing was probed
				// NOTE: this code is hacked to work with only one global probe KeySet
				if (lastActiveLayer)
					setProbeKeys(lastActiveLayer, []);
				lastProbedQKey = null;
			}
		}
		
		protected function setSelectionKeys(layer:SelectablePlotLayer, keys:Array, useMouseMode:Boolean = false):void
		{
			if (!Weave.properties.enableToolSelection.value)
				return;

			var mouseMode:String = _temporaryMouseMode ? _temporaryMouseMode : defaultMouseMode.value;

			// set the probe filter to a new set of keys
			var keySet:KeySet = layer.selectionFilter.internalObject as KeySet;
			if (keySet != null)
			{
				if (useMouseMode && mouseMode == SELECT_MODE_ADD)
					keySet.addKeys(keys);
				else if (useMouseMode && mouseMode == SELECT_MODE_SUBTRACT)
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
					var text:String = ProbeTextUtils.getProbeText(keySet, additionalProbeColumns);
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
			var spls:Array = layers.getObjects(SelectablePlotLayer);
			for (var i:int = 0; i < spls.length; i++)
				setProbeKeys(spls[i], []);
		}
		
		protected const queryBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		protected const tempDataBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		protected const tempScreenBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		private const tempPoint:Point = new Point(); // reusable temporary object
	}
}
