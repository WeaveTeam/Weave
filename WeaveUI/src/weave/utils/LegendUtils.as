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

package weave.utils
{
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	
	import weave.Weave;
	import weave.api.primitives.IBounds2D;

	/**
	 * A collection of static methods for drawing and positioning legend items.
	 * 
	 * @author kmonico
	 */	
	public class LegendUtils
	{
		/**
		 * This function will fill in outputScreenBounds with the bounds of the item, relative to
		 * the legend placement. 
		 * @param fullScreenBounds The full bounds of the screen.
		 * @param index The index of the item relative to totalItemCount.
		 * @param outputScreenBounds The output bounds in screen coordinates.
		 * @param totalItemCount The total number of items in the legend.
		 * @param maxColumns The maximum number of columns. When a column is filled, the next item is placed
		 * at the beginning of the next row.
		 * @param transposeInRow If <code>true</code>, then the column of the item will be transposed inside the row.
		 * For example, with maxColumns = 5 (columns 0 .. 4), an item in column 0 would be transposed to column 4. An item in
		 * column 3 would be transposed to column 1, etc.
		 */		
		public static function getBoundsFromItemID(fullScreenBounds:IBounds2D, index:int, outputScreenBounds:IBounds2D, totalItemCount:int, maxColumns:int = 1, transposeInRow:Boolean = false):void
		{
			if (maxColumns <= 0)
				maxColumns = 1;
			if (maxColumns > totalItemCount)
				maxColumns = totalItemCount;
			var maxRows:int = Math.ceil(totalItemCount / maxColumns);

			var xSpacing:Number = fullScreenBounds.getXCoverage() / maxColumns;
			var ySpacing:Number = fullScreenBounds.getYCoverage() / maxRows;
			var desiredColumn:int = index % maxColumns;
			var desiredRow:int = index / maxColumns;
			if (transposeInRow)
				desiredColumn = (maxColumns - 1) - desiredColumn;
			
			var xMinDesired:Number = fullScreenBounds.getXNumericMin() + xSpacing * desiredColumn;
			var yMinDesired:Number = fullScreenBounds.getYNumericMin() + ySpacing * desiredRow;
			var xMaxDesired:Number = xMinDesired + xSpacing;
			var yMaxDesired:Number = yMinDesired + ySpacing;
			outputScreenBounds.setBounds(xMinDesired, yMinDesired, xMaxDesired, yMaxDesired);			
		}
		
		/**
		 * This function will render the text on the destination bitmap.
		 * @param destination The bitmap on which to render the text.
		 * @param text The text to draw on the bitmap.
		 * @param itemScreenBounds The screen bounds of the item.
		 * @param iconGap The gap between the icon and the text.
		 * @param clipRectangle A rectangle used for clipping, if desired. This is typically the bounds of the 
		 * screen during a drawPlot or drawBackground call.
		 */		
		public static function renderLegendItemText(destination:BitmapData, text:String, itemScreenBounds:IBounds2D, iconGap:int, clipRectangle:Rectangle = null):void
		{
			bitmapText.textFormat.size = Weave.properties.axisFontSize.value;
			bitmapText.textFormat.color = Weave.properties.axisFontColor.value;
			bitmapText.textFormat.font = Weave.properties.axisFontFamily.value;
			bitmapText.textFormat.bold = Weave.properties.axisFontBold.value;
//			bitmapText.textFormat.italic = Weave.properties.axisFontItalic.value;
//			bitmapText.textFormat.underline = Weave.properties.axisFontUnderline.value;
			bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_MIDDLE;
			
			bitmapText.text = text;
			bitmapText.x = itemScreenBounds.getXNumericMin() + iconGap;
			bitmapText.y = itemScreenBounds.getYCenter();
			bitmapText.maxWidth = itemScreenBounds.getXCoverage() - iconGap;
			bitmapText.maxHeight = itemScreenBounds.getYCoverage();
			bitmapText.draw(destination, null, null, null, clipRectangle ); 
		}
		
		private static const bitmapText:BitmapText = new BitmapText();
	}
}