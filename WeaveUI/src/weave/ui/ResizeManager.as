package weave.ui
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.controls.scrollClasses.ScrollBar;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	import mx.managers.CursorManager;
	
	
	/**
	 * Utility class for allowing containers to be resized by a resize handle.
	 * Has a small resize handle that can be added to a UIComponent.  This resize handle will 
	 * cause the UIComponent to be resized when the user drags the handle.
	 * It also supports showing a custom cursor while the resizing is occurring.
	 * 
	 * @author Chris Callendar
	 * @date March 17th, 2009
	 * GNU Lesser General Public License (LGPL-3.0, open source). 
	 */
	public class ResizeManager
	{
		
		public static const RESIZE_START:String = "resizeStart";
		public static const RESIZE_END:String = "resizeEnd";
		
		private const RESIZE_HANDLE_SIZE:int = 16;
		private var resizeInitX:Number = 0;
		private var resizeInitY:Number = 0;
		
		private var _resizeHandle:ResizeHandle;
		private var _enabled:Boolean;
		private var _bringToFrontOnResize:Boolean;
		
		private var resizeComponent:UIComponent;
		
		private var isResizing:Boolean;
		private var startWidth:Number;
		private var startHeight:Number;
		
		private var _keepAspectRatio:Boolean = false;
		private var widthToHeightRatio:Number = NaN;
		
		[Embed(source="/weave/resources/images/right_bottom_resize.png")]
		public var resizeIcon:Class;
		private var resizeCursorID:int;
		
		public function ResizeManager(resizeComponent:UIComponent) {
			this.resizeComponent = resizeComponent;
			this._enabled = true;
			this._bringToFrontOnResize = false;
			resizeCursorID = 0;
		}
		
		public function get enabled():Boolean {
			return _enabled;
		}
		
		public function set enabled(en:Boolean):void {
			if (en != _enabled) {
				_enabled = en;
				resizeHandle.enabled = en;
				resizeHandle.visible = en;
			}
		}
		
		public function get bringToFrontOnResize():Boolean {
			return _bringToFrontOnResize;
		}
		
		/**
		 * Sets whether the resize component is brought to the front of the display list
		 * when resizing happens.
		 */
		public function set bringToFrontOnResize(value:Boolean):void {
			_bringToFrontOnResize = value;
		}
		
		public function get keepAspectRatio():Boolean {
			return _keepAspectRatio;
		}
		
		/**
		 * Sets whether the resize component has its width and height aspect ratio fixed.
		 */
		public function set keepAspectRatio(value:Boolean):void {
			_keepAspectRatio = value;
			widthToHeightRatio = NaN;
		}
		
		/**        
		 * Returns the resizeHandle UIComponent.
		 */
		public function get resizeHandle():ResizeHandle {
			if (_resizeHandle == null) {
				_resizeHandle = new ResizeHandle();
				_resizeHandle.mouseEnabled = true;
				_resizeHandle.addEventListener(MouseEvent.MOUSE_DOWN, resizeHandler);
				_resizeHandle.addEventListener(MouseEvent.MOUSE_OVER, mouseOverResizeHandler);
				_resizeHandle.addEventListener(MouseEvent.MOUSE_OUT, mouseOutResizeHandler);
				_resizeHandle.width = RESIZE_HANDLE_SIZE;
				_resizeHandle.height = RESIZE_HANDLE_SIZE;
				_resizeHandle.positionResizeHandle = true;
				_resizeHandle.dropShadowEnabled = true;
				_resizeHandle.keepOnTop = true;
				_resizeHandle.toolTip = "Drag this handle to resize the component";
			}
			return _resizeHandle;
		}
		
		/**
		 * Checks if the horizontal and/or vertical scrollbars are showing, if so it resizes
		 * them to make sure the resize handle isn't covered up.
		 * If the component is a ScrollControlBase, then you have to pass in the scrollbars
		 * since they are protected properties.
		 */
		public function adjustScrollBars(hScroll:ScrollBar, vScroll:ScrollBar):void {
			if (enabled) {
				// keep the resize handle on top
				resizeHandle.bringToFront();
				
				// make room for the resize handle, only needed if one scrollbar is showing
				var hScrollShowing:Boolean = hScroll && hScroll.visible;
				var vScrollShowing:Boolean = vScroll && vScroll.visible;
				if (hScrollShowing && vScrollShowing) {
					// do nothing, there is already a white square between the ends of the scrollbars
					// where the resize handle is, so no need to resize the scrollbars
				} else if (hScrollShowing) {
					// important - use setActualSize instead of the width/height properties otherwise
					// we get into an endless loop
					hScroll.setActualSize(Math.max(hScroll.minWidth, hScroll.width - resizeHandle.width), hScroll.height);
				} else if (vScrollShowing) {
					vScroll.setActualSize(vScroll.width, Math.max(vScroll.minHeight, vScroll.height - resizeHandle.height));
				}
			}
		}
		
		// Resize event handler
		private function resizeHandler(event:MouseEvent):void {
			if (enabled) {
				event.stopImmediatePropagation();
				startResize(event.stageX, event.stageY);
			}
		}    
		
		private function startResize(globalX:Number, globalY:Number):void {
			// dispatch a resizeStart event - can be cancelled!
			var event:ResizeEvent = new ResizeEvent(RESIZE_START, false, true, resizeComponent.width, resizeComponent.height); 
			var okay:Boolean = resizeComponent.dispatchEvent(event);
			if (okay) {
				isResizing = true;
				
				// move above all others
				if (bringToFrontOnResize && resizeComponent.parent) {
					var index:int = resizeComponent.parent.getChildIndex(resizeComponent);
					var last:int = resizeComponent.parent.numChildren - 1;
					if (index != last) {
						resizeComponent.parent.setChildIndex(resizeComponent, last);
					}
				}
				
				resizeInitX = globalX;
				resizeInitY = globalY;
				startWidth = resizeComponent.width;
				startHeight = resizeComponent.height;
				if (keepAspectRatio) {
					widthToHeightRatio = startWidth / startHeight;
				}
				
				// Add event handlers so that the SystemManager handles the mouseMove and mouseUp events. 
				// Set useCapure flag to true to handle these events 
				// during the capture phase so no other component tries to handle them.
				resizeComponent.systemManager.addEventListener(MouseEvent.MOUSE_MOVE, resizeMouseMoveHandler, true);
				resizeComponent.systemManager.addEventListener(MouseEvent.MOUSE_UP, resizeMouseUpHandler, true);
			}
		}
		
		/**
		 * Resizes this panel as the user moves the mouse with the mouse button down.
		 * Also restricts the width and height based on the resizeComponent's minWidth, maxWidth, minHeight, and
		 * maxHeight properties.
		 */
		private function resizeMouseMoveHandler(event:MouseEvent):void {
			event.stopImmediatePropagation();
			
			var newWidth:Number = resizeComponent.width + event.stageX - resizeInitX; 
			var newHeight:Number = resizeComponent.height + event.stageY - resizeInitY;
			
			// keep the width to height aspect ratio?
			if (keepAspectRatio && !isNaN(widthToHeightRatio)) {
				// choose the dimension to restrict based on the smaller change
				var dw:Number = Math.abs(newWidth - resizeComponent.width);
				var dh:Number = Math.abs(newHeight - resizeComponent.height);
				if (dw > dh) {
					newHeight = Math.round(newWidth / widthToHeightRatio);
				} else {
					newWidth = Math.round(newHeight * widthToHeightRatio);
				}
			}
			
			// restrict the width/height
			if ((newWidth >= resizeComponent.minWidth) && (newWidth <= resizeComponent.maxWidth)) {
				resizeComponent.width = newWidth;
			}
			if ((newHeight >= resizeComponent.minHeight) && (newHeight <= resizeComponent.maxHeight)) {
				resizeComponent.height = newHeight;
			}
			
			resizeInitX = event.stageX;
			resizeInitY = event.stageY;
			
			// Update the scrollRect property (this is used by the PopUpManager)
			// will usually be null
			if (resizeComponent.scrollRect) {
				var rect:Rectangle = resizeComponent.scrollRect;
				rect.width = resizeComponent.width;
				rect.height = resizeComponent.height;
				resizeComponent.scrollRect = rect;
			}
		}
		
		/** 
		 * Removes the event handlers from the SystemManager.
		 */
		private function resizeMouseUpHandler(event:MouseEvent):void {
			event.stopImmediatePropagation();
			resizeComponent.systemManager.removeEventListener(MouseEvent.MOUSE_MOVE, resizeMouseMoveHandler, true);
			resizeComponent.systemManager.removeEventListener(MouseEvent.MOUSE_UP, resizeMouseUpHandler, true);
			if (isResizing) {
				isResizing = false;
				resizeComponent.dispatchEvent(new ResizeEvent(RESIZE_END, false, false, startWidth, startHeight));
			}
			
			// check if the mouse is outside the resize handle
			var pt:Point = resizeHandle.globalToLocal(new Point(event.stageX, event.stageY));
			var bounds:Rectangle = new Rectangle(0, 0, resizeHandle.width, resizeHandle.height);
			var isOver:Boolean = bounds.containsPoint(pt);
			if (!isOver) {
				removeResizeCursor();
			}
		}
		
		private function mouseOverResizeHandler(event:MouseEvent):void {
			setResizeCursor();
			resizeComponent.systemManager.addEventListener(MouseEvent.MOUSE_OUT, mouseOutResizeHandler, true);
		}
		
		private function mouseOutResizeHandler(event:MouseEvent):void {
			if (!isResizing) {
				removeResizeCursor();
				resizeComponent.systemManager.removeEventListener(MouseEvent.MOUSE_OUT, mouseOutResizeHandler, true);
			}
		}
		
		private function setResizeCursor():void {
			if ((resizeCursorID == 0) && (resizeIcon != null)) {
				resizeCursorID = CursorManager.setCursor(resizeIcon);
			}
		}
		
		private function removeResizeCursor():void {
			if (resizeCursorID != 0) {
				CursorManager.removeCursor(resizeCursorID);
				resizeCursorID = 0;
			} 
		} 
		
	}
}

