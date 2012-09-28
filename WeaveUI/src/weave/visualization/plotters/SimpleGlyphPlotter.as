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

package weave.visualization.plotters
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import weave.Weave;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;

	/**
	 * Plots squares or circles.
	 * 
	 * @author adufilie
	 */
	public class SimpleGlyphPlotter extends AbstractGlyphPlotter
	{
		public function SimpleGlyphPlotter()
		{
			fillStyle.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			setColumnKeySources([screenSize, dataX, dataY], [true, false, false]);
		}
		
		private static const LEFT:String = 'left', CENTER:String = 'center', RIGHT:String = 'right';
		private static const TOP:String = 'top', MIDDLE:String = 'middle', BOTTOM:String = 'bottom';
		private static const HORIZONTAL_MODES:Array = [LEFT,CENTER,RIGHT];
		private static const VERTICAL_MODES:Array = [TOP,MIDDLE,BOTTOM];
		private static function verifyHorizontal(value:String):Boolean { return HORIZONTAL_MODES.indexOf(value) >= 0; }
		private static function verifyVertical(value:String):Boolean { return VERTICAL_MODES.indexOf(value) >= 0; }
		
		/**
		 * This is the line style used to draw the outline of the rectangle.
		 */
		public const lineStyle:SolidLineStyle = registerLinkableChild(this, new SolidLineStyle());
		/**
		 * This is the fill style used to fill the rectangle.
		 */
		public const fillStyle:SolidFillStyle = registerLinkableChild(this, new SolidFillStyle());
		/**
		 * This determines the screen size of the glyphs.
		 */
		public const screenSize:AlwaysDefinedColumn = registerSpatialProperty(new AlwaysDefinedColumn());
		/**
		 * If this is true, ellipses will be drawn instead of rectangles.
		 */
		public const drawEllipse:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		/**
		 * This determines how the glyphs are aligned horizontally to the data coordinates.
		 */		
		public const horizontalPosition:LinkableString = registerLinkableChild(this, new LinkableString(CENTER, verifyHorizontal));
		/**
		 * This determines how the glyphs are aligned vertically to the data coordinates.
		 */		
		public const verticalPosition:LinkableString = registerLinkableChild(this, new LinkableString(MIDDLE, verifyVertical));
		
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			var x:Number = getCoordFromRecordKey(recordKey, true);
			var y:Number = getCoordFromRecordKey(recordKey, false);
			var size:Number = screenSize.getValueFromKey(recordKey, Number);
			
			if (isNaN(x) || isNaN(y) || isNaN(size))
				return;
			
			// project x,y data coordinates to screen coordinates
			tempPoint.x = x;
			tempPoint.y = y;
			dataBounds.projectPointTo(tempPoint, screenBounds);
			
			// add screen offsets
			tempPoint.x += size * (HORIZONTAL_MODES.indexOf(horizontalPosition.value) / 2 - 1);
			tempPoint.y += size * (VERTICAL_MODES.indexOf(verticalPosition.value) / 2 - 1);
			
			// draw graphics
			var graphics:Graphics = tempShape.graphics;
			lineStyle.beginLineStyle(recordKey, graphics);
			fillStyle.beginFillStyle(recordKey, graphics);
			
			if (drawEllipse.value)
				graphics.drawEllipse(tempPoint.x, tempPoint.y, size, size);
			else
				graphics.drawRect(tempPoint.x, tempPoint.y, size, size);
			
			graphics.endFill();
		}
		
		private static const tempPoint:Point = new Point(); // reusable object
	}
}
