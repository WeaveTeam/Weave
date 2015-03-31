/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.visualization.plotters
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import weave.Weave;
	import weave.api.core.DynamicState;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.setSessionState;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
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
			for each (var child:ILinkableObject in [xMinScreenOffset, yMinScreenOffset, xMaxScreenOffset, yMaxScreenOffset, line, fill])
				registerLinkableChild(this, child);
			
			fill.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			
			setColumnKeySources([xMinData, yMinData, xMaxData, yMaxData]);
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
		public const line:SolidLineStyle = new SolidLineStyle();
		/**
		 * This is the fill style used to fill the rectangle.
		 */
		public const fill:SolidFillStyle = new SolidFillStyle();

		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param output An Array of IBounds2D object to store the result in.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			initBoundsArray(output);
			(output[0] as IBounds2D).setBounds(
				xMinData.getValueFromKey(recordKey, Number),
				yMinData.getValueFromKey(recordKey, Number),
				xMaxData.getValueFromKey(recordKey, Number),
				yMaxData.getValueFromKey(recordKey, Number)
			);
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

			line.beginLineStyle(recordKey, graphics);
			fill.beginFillStyle(recordKey, graphics);

			//trace(recordKey,tempBounds);
			graphics.drawRect(tempBounds.getXMin(), tempBounds.getYMin(), tempBounds.getWidth(), tempBounds.getHeight());

			graphics.endFill();
		}
		
		private static const tempBounds:IBounds2D = new Bounds2D(); // reusable object
		private static const tempPoint:Point = new Point(); // reusable object
		
		[Deprecated(replacement="line")] public function set lineStyle(value:Object):void
		{
			try
			{
				setSessionState(line, value[0][DynamicState.SESSION_STATE]);
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		[Deprecated(replacement="fill")] public function set fillStyle(value:Object):void
		{
			try
			{
				setSessionState(fill, value[0][DynamicState.SESSION_STATE]);
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
	}
}
