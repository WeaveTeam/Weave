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
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;

	/**
	 * This plotter plots lines using x1,y1,x2,y2 values.
	 * There is a set of data coordinates and a set of screen offset coordinates.
	 * 
	 * @author adufilie
	 */
	public class LinePlotter extends AbstractPlotter
	{
		public function LinePlotter()
		{
			for each (var spatialProperty:ILinkableObject in [x1Data, y1Data, x2Data, y2Data])
				registerSpatialProperty(spatialProperty);
			// initialize default line style
			lineStyle.requestLocalObject(SolidLineStyle, false);
			
			setKeySource(x1Data);
		}

		// spatial properties
		/**
		 * This is the beginning X data value associated with the line.
		 */
		public const x1Data:DynamicColumn = new DynamicColumn();
		/**
		 * This is the beginning Y data value associated with the line.
		 */
		public const y1Data:DynamicColumn = new DynamicColumn();
		/**
		 * This is the ending X data value associated with the line.
		 */
		public const x2Data:DynamicColumn = new DynamicColumn();
		/**
		 * This is the ending Y data value associated with the line.
		 */
		public const y2Data:DynamicColumn = new DynamicColumn();

		// visual properties
		/**
		 * This is an offset in screen coordinates when projecting the line onto the screen.
		 */
		public const x1ScreenOffset:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(0));
		/**
		 * This is an offset in screen coordinates when projecting the line onto the screen.
		 */
		public const y1ScreenOffset:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(0));
		/**
		 * This is an offset in screen coordinates when projecting the line onto the screen.
		 */
		public const x2ScreenOffset:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(0));
		/**
		 * This is an offset in screen coordinates when projecting the line onto the screen.
		 */
		public const y2ScreenOffset:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(0));
		/**
		 * This is the line style used to draw the line.
		 */
		public const lineStyle:DynamicLineStyle = registerLinkableChild(this, new DynamicLineStyle());

		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var b1:IBounds2D = getReusableBounds();
			var b2:IBounds2D = getReusableBounds();
			b1.includeCoords(
					x1Data.getValueFromKey(recordKey, Number),
					y1Data.getValueFromKey(recordKey, Number)
				);
			b2.includeCoords(
					x2Data.getValueFromKey(recordKey, Number),
					y2Data.getValueFromKey(recordKey, Number)
				);
			return [b1,b2];
		}

		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			var graphics:Graphics = tempShape.graphics;

			// project data coordinates to screen coordinates and draw graphics onto tempShape
			lineStyle.beginLineStyle(recordKey, graphics);				
			
			// project data coordinates to screen coordinates and draw graphics
			tempPoint.x = x1Data.getValueFromKey(recordKey, Number);
			tempPoint.y = y1Data.getValueFromKey(recordKey, Number);
			dataBounds.projectPointTo(tempPoint, screenBounds);
			tempPoint.x += x1ScreenOffset.getValueFromKey(recordKey, Number);
			tempPoint.y += y1ScreenOffset.getValueFromKey(recordKey, Number);
			
			graphics.moveTo(tempPoint.x, tempPoint.y);
			
			tempPoint.x = x2Data.getValueFromKey(recordKey, Number);
			tempPoint.y = y2Data.getValueFromKey(recordKey, Number);
			dataBounds.projectPointTo(tempPoint, screenBounds);
			tempPoint.x += x2ScreenOffset.getValueFromKey(recordKey, Number);
			tempPoint.y += y2ScreenOffset.getValueFromKey(recordKey, Number);
			
			graphics.lineTo(tempPoint.x, tempPoint.y);
		}
		
		private static const tempPoint:Point = new Point(); // reusable object
	}
}
