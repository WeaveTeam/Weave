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
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.visualization.plotters.styles.DynamicFillStyle;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;

	/**
	 * This plotter plots rectangles using xMin,yMin,xMax,yMax values.
	 * There is a set of data coordinates and a set of screen offset coordinates.
	 * 
	 * @author adufilie
	 */
	public class BoundsPlotter extends AbstractPlotter
	{
		public function BoundsPlotter()
		{
			for each (var spatialProperty:ILinkableObject in [xMinData, yMinData, xMaxData, yMaxData])
				registerSpatialProperty(spatialProperty);
			for each (var child:ILinkableObject in [xMinScreenOffset, yMinScreenOffset, xMaxScreenOffset, yMaxScreenOffset, lineStyle, fillStyle])
				registerLinkableChild(this, child);
			// initialize default line & fill styles
			lineStyle.requestLocalObject(SolidLineStyle, false);
			var fill:SolidFillStyle = fillStyle.requestLocalObject(SolidFillStyle, false);
			fill.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			
			setKeySource(xMinData); // not the best solution... need the union of x,y,x,y
		}

		// spatial properties
		/**
		 * This is the minimum X data value associated with the rectangle.
		 */
		public const xMinData:DynamicColumn = new DynamicColumn();
		/**
		 * This is the minimum Y data value associated with the rectangle.
		 */
		public const yMinData:DynamicColumn = new DynamicColumn();
		/**
		 * This is the maximum X data value associated with the rectangle.
		 */
		public const xMaxData:DynamicColumn = new DynamicColumn();
		/**
		 * This is the maximum Y data value associated with the rectangle.
		 */
		public const yMaxData:DynamicColumn = new DynamicColumn();

		// visual properties
		/**
		 * This is an offset in screen coordinates when projecting the data rectangle onto the screen.
		 */
		public const xMinScreenOffset:AlwaysDefinedColumn = new AlwaysDefinedColumn(0);
		/**
		 * This is an offset in screen coordinates when projecting the data rectangle onto the screen.
		 */
		public const yMinScreenOffset:AlwaysDefinedColumn = new AlwaysDefinedColumn(0);
		/**
		 * This is an offset in screen coordinates when projecting the data rectangle onto the screen.
		 */
		public const xMaxScreenOffset:AlwaysDefinedColumn = new AlwaysDefinedColumn(0);
		/**
		 * This is an offset in screen coordinates when projecting the data rectangle onto the screen.
		 */
		public const yMaxScreenOffset:AlwaysDefinedColumn = new AlwaysDefinedColumn(0);
		/**
		 * This is the line style used to draw the outline of the rectangle.
		 */
		public const lineStyle:DynamicLineStyle = new DynamicLineStyle();
		/**
		 * This is the fill style used to fill the rectangle.
		 */
		public const fillStyle:DynamicFillStyle = new DynamicFillStyle();

		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var bounds:IBounds2D = getReusableBounds(
					xMinData.getValueFromKey(recordKey, Number),
					yMinData.getValueFromKey(recordKey, Number),
					xMaxData.getValueFromKey(recordKey, Number),
					yMaxData.getValueFromKey(recordKey, Number)
				);
			return [bounds];
		}

		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			// project data coordinates to screen coordinates and draw graphics
			tempPoint.x = xMinData.getValueFromKey(recordKey, Number);
			tempPoint.y = yMinData.getValueFromKey(recordKey, Number);
			dataBounds.projectPointTo(tempPoint, screenBounds);
			tempPoint.x += xMinScreenOffset.getValueFromKey(recordKey, Number);
			tempPoint.y += yMinScreenOffset.getValueFromKey(recordKey, Number);
			tempBounds.setMinPoint(tempPoint);
			
			tempPoint.x = xMaxData.getValueFromKey(recordKey, Number);
			tempPoint.y = yMaxData.getValueFromKey(recordKey, Number);
			dataBounds.projectPointTo(tempPoint, screenBounds);
			tempPoint.x += xMaxScreenOffset.getValueFromKey(recordKey, Number);
			tempPoint.y += yMaxScreenOffset.getValueFromKey(recordKey, Number);
			tempBounds.setMaxPoint(tempPoint);
				
			// draw graphics
			var graphics:Graphics = tempShape.graphics;

			lineStyle.beginLineStyle(recordKey, graphics);
			fillStyle.beginFillStyle(recordKey, graphics);

			//trace(recordKey,tempBounds);
			graphics.drawRect(tempBounds.getXMin(), tempBounds.getYMin(), tempBounds.getWidth(), tempBounds.getHeight());

			graphics.endFill();
		}
		
		private static const tempBounds:IBounds2D = new Bounds2D(); // reusable object
		private static const tempPoint:Point = new Point(); // reusable object
	}
}
