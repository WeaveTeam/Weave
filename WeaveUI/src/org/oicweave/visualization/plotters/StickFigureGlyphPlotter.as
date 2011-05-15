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

package org.oicweave.visualization.plotters
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.api.primitives.IBounds2D;
	import org.oicweave.core.LinkableNumber;
	import org.oicweave.data.AttributeColumns.AlwaysDefinedColumn;
	import org.oicweave.data.AttributeColumns.DynamicColumn;
	import org.oicweave.utils.ColumnUtils;
	import org.oicweave.utils.DrawUtils;
	import org.oicweave.visualization.plotters.styles.DynamicLineStyle;
	import org.oicweave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * CirclePlotter
	 * 
	 * @heather byrne
	 */
	public class StickFigureGlyphPlotter extends AbstractGlyphPlotter
	{
		public function StickFigureGlyphPlotter()
		{
			_lineStyle.requestLocalObject(SolidLineStyle, false);
			registerNonSpatialProperties(theta1, theta2, theta3, theta4, limbLength, lineStyle, curvature);
		
			curvature.value = 0.0;
		}

		/**
		 * This is the angle at which each line will be drawn from the vertical axis.
		 */
		public const theta1:DynamicColumn = new DynamicColumn();
		
		public const theta2:DynamicColumn = new DynamicColumn();		
		
		public const theta3:DynamicColumn = new DynamicColumn();
		
		public const theta4:DynamicColumn = new DynamicColumn();		
		/**
		 * This is the limb length.
		 */
		public const limbLength:AlwaysDefinedColumn = new AlwaysDefinedColumn(10);
		/**
		 * This is the line style used to draw the outline of the rectangle.
		 */
		private var _lineStyle:DynamicLineStyle = new DynamicLineStyle();
		/**
		 * This is the fill style used to fill the rectangle.
		 */
		
		public function get lineStyle():SolidLineStyle
		{
			return _lineStyle.internalObject as SolidLineStyle;
		}
		
		public const curvature:LinkableNumber = new LinkableNumber();

		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			// project data coordinates to screen coordinates and draw graphics
			var theta1:Number = Math.PI*ColumnUtils.getNorm(this.theta1, recordKey);
			var theta2:Number = Math.PI*ColumnUtils.getNorm(this.theta2, recordKey);
			var theta3:Number = Math.PI*ColumnUtils.getNorm(this.theta3, recordKey);
			var theta4:Number = Math.PI*ColumnUtils.getNorm(this.theta4, recordKey);
			var limbLength:Number = this.limbLength.getValueFromKey(recordKey, Number) as Number;
			tempPoint.x = dataX.getValueFromKey(recordKey, Number) as Number;
			tempPoint.y = dataY.getValueFromKey(recordKey, Number) as Number;
			dataBounds.projectPointTo(tempPoint, screenBounds);

			// draw graphics
			var graphics:Graphics = tempShape.graphics;
			var x:Number = tempPoint.x;
			var y:Number = tempPoint.y;
			var topY:Number = y+(limbLength/2);
			var bottomY:Number = y-(limbLength/2);
			
			lineStyle.beginLineStyle(recordKey, graphics);				
	

			//trace("graphics.drawCircle(",tempPoint.x, tempPoint.y, radius,");");
			graphics.moveTo(x, y);
			
			//Draw Center Vertical line
			graphics.moveTo(x, topY);
			graphics.lineTo(x, bottomY);
			
			/*//move back to top and draw first limb with top of vertical line as "orgin point"
			if (!isNaN(theta1)){
				graphics.moveTo(x, topY);
				graphics.lineTo(x+(Math.sin(theta1)*limbLength), topY-(Math.cos(theta1)*limbLength));
			}
			//move back to top and draw second limb with top of vertical line as "orgin point"
			if (!isNaN(theta2)){
				graphics.moveTo(x, topY);
				graphics.lineTo(x-(Math.sin(theta2)*limbLength), topY-(Math.cos(theta2)*limbLength));
			}
			//move back to top and draw second limb with bottom of vertical line as "orgin point"
			if (!isNaN(theta3)){
				graphics.moveTo(x, bottomY);
				graphics.lineTo(x-(Math.sin(theta3)*limbLength), bottomY+(Math.cos(theta3)*limbLength)); 
			}
			if (!isNaN(theta4)){
				//move back to top and draw second limb with bottom of vertical line as "orgin point"
				graphics.moveTo(x, bottomY);
				graphics.lineTo(x+(Math.sin(theta4)*limbLength), bottomY+(Math.cos(theta4)*limbLength));
			}*/
			
			//move back to top and draw first limb with top of vertical line as "orgin point"
			if (!isNaN(theta1)){
				DrawUtils.drawCurvedLine(graphics, x, topY, x+(Math.sin(theta1)*limbLength), topY-(Math.cos(theta1)*limbLength), curvature.value);
			}
			//move back to top and draw second limb with top of vertical line as "orgin point"
			if (!isNaN(theta2)){
				DrawUtils.drawCurvedLine(graphics, x, topY, x-(Math.sin(theta2)*limbLength), topY-(Math.cos(theta2)*limbLength), curvature.value);
			}
			//move back to top and draw second limb with bottom of vertical line as "orgin point"
			if (!isNaN(theta3)){
				DrawUtils.drawCurvedLine(graphics, x, bottomY, x-(Math.sin(theta3)*limbLength), bottomY+(Math.cos(theta3)*limbLength), curvature.value);
			}
			//move back to top and draw second limb with bottom of vertical line as "orgin point"
			if (!isNaN(theta4)){
				DrawUtils.drawCurvedLine(graphics, x, bottomY, x+(Math.sin(theta4)*limbLength), bottomY+(Math.cos(theta4)*limbLength), curvature.value);
			}
		}
		
		private static const tempPoint:Point = new Point(); // reusable object
	}
}
