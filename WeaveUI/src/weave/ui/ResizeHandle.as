package weave.ui
{
	/**
	 * Renders a resize handle by drawing a set of small dots (squares). 
	 * 
	 * There are styles for setting the backgroundColor, backgroundAlpha (0 by default),
	 * resizeHandleColor (0x666666 by default) and resizeHandleAlpha (1 by default).
	 * 
	 * There is also a dropShadowEnabled property that sets whether a DropShadowFilter
	 * is used (defaults to false).
	 * 
	 * @author Chris Callendar
	 * @date March 4th, 2010
	 * GNU Lesser General Public License (LGPL-3.0, open source). 
	 */
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	
	import weave.utils.StyleUtils;
	
	import mx.core.Container;
	import mx.core.IChildList;
	import mx.core.UIComponent;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
	
	[Style(name="backgroundColor", type="uint", format="Color", inherit="no")]
	[Style(name="backgroundAlpha", type="Number", inherit="no")]
	[Style(name="resizeHandleColor", type="uint", format="Color", inherit="no")]
	[Style(name="resizeHandleAlpha", type="Number", inherit="no")]
	
	/**
	 * Renders a resize handle by drawing a set of small dots (squares). 
	 * 
	 * There are styles for setting the backgroundColor, backgroundAlpha (0 by default),
	 * resizeHandleColor (0x666666 by default) and resizeHandleAlpha (1 by default).
	 * 
	 * There is also a dropShadowEnabled property that sets whether a DropShadowFilter
	 * is used (defaults to false).
	 * 
	 * @author Chris Callendar
	 * @date March 4th, 2010
	 */
	public class ResizeHandle extends UIComponent
	{
		
		private static var classConstructed:Boolean = classConstruct(); 
		private static function classConstruct():Boolean {
			var style:CSSStyleDeclaration = StyleManager.getStyleDeclaration("ResizeHandle");
			if (!style) {
				style = new CSSStyleDeclaration();
			}
			style.defaultFactory = function():void {
				this.backgroundColor = 0xffffff;
				this.backgroundAlpha = 0;
				this.resizeHandleColor = 0x666666;
				this.resizeHandleAlpha = 1;
			};
			StyleManager.setStyleDeclaration("ResizeHandle", style, true);
			return true;
		};
		
		private var _rows:uint = 3;
		private var _cols:uint = 3;
		private var _dotSize:uint = 2;
		private var _dropShadowEnabled:Boolean = false;
		public const dropShadowFilter:DropShadowFilter = new DropShadowFilter(1, 45, 0xdddddd, 0.5, 1, 1);
		private var _keepOnTop:Boolean = false;
		private var _positionResizeHandle:Boolean = false;
		
		public function ResizeHandle() {
			super();
		}
		
		[Inspectable(category="Resize Handle", defaultValue="false")]
		[Bindable("positionResizeHandleChanged")]
		public function set positionResizeHandle(value:Boolean):void {
			if (value != _positionResizeHandle) {
				_positionResizeHandle = value;
				invalidateDisplayList();
				dispatchEvent(new Event("positionResizeHandleChanged"));
			}
		}
		
		public function get positionResizeHandle():Boolean {
			return _positionResizeHandle;
		}
		
		[Inspectable(category="Resize Handle", defaultValue="false")]
		[Bindable("keepOnTopChanged")]
		public function set keepOnTop(value:Boolean):void {
			if (value != _keepOnTop) {
				_keepOnTop = value;
				invalidateDisplayList();
				dispatchEvent(new Event("keepOnTopChanged"));
			}
		}
		
		public function get keepOnTop():Boolean {
			return _keepOnTop;
		}
		
		[Inspectable(category="Resize Handle", defaultValue="false")]
		[Bindable("dropShadowEnabledChanged")]
		public function set dropShadowEnabled(value:Boolean):void {
			if (value != _dropShadowEnabled) {
				_dropShadowEnabled = value;
				this.filters = (value ? [ dropShadowFilter ] : null);
				dispatchEvent(new Event("dropShadowEnabledChanged"));
			}
		}
		
		public function get dropShadowEnabled():Boolean {
			return _dropShadowEnabled;
		}
		
		[Inspectable(category="Resize Handle", defaultValue="0xdddddd")]
		[Bindable("dropShadowColorChanged")]
		public function set dropShadowColor(value:uint):void {
			if (value != dropShadowFilter.color) {
				dropShadowFilter.color = value;
				if (dropShadowEnabled) {
					this.filters = [ dropShadowFilter ];
				}
				dispatchEvent(new Event("dropShadowColorChanged"));
			}
		}
		
		public function get dropShadowColor():uint {
			return dropShadowFilter.color;
		}
		
		[Inspectable(category="Resize Handle", defaultValue="2")]
		[Bindable("dotSizeChanged")]
		public function set dotSize(value:uint):void {
			if (value != _dotSize) {
				_dotSize = value;
				invalidateSize();
				invalidateDisplayList();
				dispatchEvent(new Event("dotSizeChanged"));
			}
		}
		
		public function get dotSize():uint {
			return _dotSize;
		}
		
		[Inspectable(category="Resize Handle", defaultValue="3")]
		[Bindable("rowsChanged")]
		public function set rows(value:uint):void {
			if (value != _rows) {
				_rows = value;
				invalidateSize();
				invalidateDisplayList();
				dispatchEvent(new Event("rowsChanged"));
			}
		}
		
		public function get rows():uint {
			return _rows;
		}
		
		[Inspectable(category="Resize Handle", defaultValue="3")]
		[Bindable("columnsChanged")]
		public function set columns(value:uint):void {
			if (value != _cols) {
				_cols = value;
				invalidateSize();
				invalidateDisplayList();
				dispatchEvent(new Event("columnsChanged"));
			}
		}
		
		public function get columns():uint {
			return _cols;
		}
		
		override public function styleChanged(styleProp:String):void {
			super.styleChanged(styleProp);
			
			if ((styleProp == "backgroundColor") || (styleProp == "backgroundAlpha") || 
				(styleProp == "resizeHandleColor") || (styleProp == "resizeHandleAlpha")) {
				invalidateDisplayList();
			}
		}
		
		public function updateStyles(colorStyle:Object, alphaStyle:Object = null):void {
			if (colorStyle != null) {
				setStyle("resizeHandleColor", colorStyle);
			}
			if (alphaStyle != null) {
				setStyle("resizeHandleAlpha", alphaStyle);
			}                 
		}
		
		override protected function measure():void {
			var h:Number = 0;
			var w:Number = 0;
			if (rows > 0) {
				h = (((2*rows) + 2) * dotSize);
			}
			if (columns > 0) {
				w = (((2*columns) + 2) * dotSize);
			}
			measuredWidth = w;
			measuredMinWidth = w;
			measuredHeight = h;
			measuredMinHeight = h;
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void {
			super.updateDisplayList(w, h);
			
			// make sure the resize handle is on top
			if (keepOnTop) {
				bringToFront();
			}
			
			if (positionResizeHandle) {
				setResizeHandlePosition();
			}
			
			graphics.clear();
			if (enabled && (w > 0) && (h > 0) && (dotSize > 0)) {
				var bg:uint = StyleUtils.getColorStyle(this, "backgroundColor", 0xffffff);
				var bgAlpha:Number = StyleUtils.getAlphaStyle(this, "backgroundAlpha", 0);
				drawResizeArea(bg, bgAlpha, w, h);
				var color:uint = StyleUtils.getColorStyle(this, "resizeHandleColor", 0x666666);
				var alpha:Number = StyleUtils.getAlphaStyle(this, "resizeHandleAlpha", 1);
				if (alpha > 0) {
					drawResizeHandle(color, alpha);
				}
			}
		}
		
		protected function drawBackground(w:Number, h:Number, color:uint, alpha:Number = 1):void {
			if (alpha > 0) {
				graphics.lineStyle(0, 0, 0);
				graphics.beginFill(color, alpha);
				graphics.drawRect(0, 0, w, h);
				graphics.endFill();
			}
		}
		
		/**
		 * Draws the resize handle.
		 */
		protected function drawResizeHandle(color:uint = 0x666666, alpha:Number = 1):void {
			var rowCount:uint = rows;
			var colCount:uint = columns;
			var dblDot:Number = dotSize * 2;
			// check if an explicit width or height was set, if so then adjust the columns
			if (!isNaN(explicitWidth)) {
				colCount = Math.round((explicitWidth - dblDot)  / dblDot);
			}
			if (!isNaN(explicitHeight)) {
				rowCount = Math.round((explicitHeight - dblDot) / dblDot);
			}
			
			// draw the triangle, e.g.
			//     .
			//   . .
			// . . .
			var dx:Number, dy:Number;
			var min:Number = Math.max(rowCount, colCount) - 1;
			for (var col:uint = 0; col < colCount; col++) {
				dx = dblDot + (col * dblDot);
				for (var row:uint = 0; row < rowCount; row++) {
					if ((row + col) >= min) {
						dy = dblDot + (row * dblDot); 
						drawDot(color, alpha, dx, dy, dotSize, dotSize);
					}
				}
			}
		}
		
		/**
		 * Draws a single (2x2) dot.
		 */
		protected function drawDot(color:uint, alpha:Number, xx:Number, yy:Number, w:Number = 2, h:Number = 2):void {
			graphics.lineStyle(0, 0, 0);    // no border
			graphics.beginFill(color, alpha);
			graphics.drawRect(xx, yy, w, h);
			graphics.endFill();
		}
		
		/**
		 * Draws a triangle region around the resize handle.
		 * This makes it so that the mouse down event works properly.
		 * @param color the color for the background 
		 * @param w the width of the resize handle
		 * @param h the height of the resize handle
		 */
		protected function drawResizeArea(color:uint, alpha:Number, w:Number, h:Number):void {
			var g:Graphics = graphics;
			// no border
			g.lineStyle(0, 0, 0);
			// fill the background, set alpha=0 to make it transparent
			g.beginFill(color, alpha);
			// draw a triangle
			var xx:Number = 0, yy:Number = 0;
			g.moveTo(xx, yy + h);
			g.lineTo(xx + w, yy + h);
			g.lineTo(xx + w, yy);
			g.lineTo(xx, yy + h);
			//g.drawRect(xx, yy, w, h);
			g.endFill();
		}
		
		/**
		 * Positions the resize handle in the bottom right corner of the parent container.
		 * @param parentW the parent container's width
		 * @param parentH the parent container's height
		 */
		public function setResizeHandlePosition():void {
			if (parent) {
				var parentW:Number = parent.width;
				var parentH:Number = parent.height;
				if (enabled && (parentW >= width) && (parentH >= height)) {
					var newX:Number = parentW - width;
					var newY:Number = parentH - height;
					if ((newX != x) || (newY != y)) {
						move(newX, newY);
					}
					if (!visible) {
						visible = true;
					}
				} else {
					visible = false;
				}
			}
		}
		
		public function bringToFront():void {
			if (parent) {
				var index:int;
				if (parent is UIComponent) {
					var list:IChildList = UIComponent(parent);
					// check the raw children
					if (parent is Container) {
						var rawChildren:IChildList = (parent as Container).rawChildren;
						if (rawChildren.contains(this)) {
							list = rawChildren;
						}
					}
					if (list.contains(this)) {
						index = list.getChildIndex(this); 
						if (index != (list.numChildren - 1)) { 
							list.setChildIndex(this, list.numChildren - 1);
						}
					}
				} else if (parent.contains(this)) {
					index = parent.getChildIndex(this); 
					if (index != (parent.numChildren - 1)) { 
						parent.setChildIndex(this, parent.numChildren - 1);
					}
				}
			}
		}
		
		
	}
}

