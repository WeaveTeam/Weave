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
	
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.utils.ColumnUtils;
	import weave.utils.DrawUtils;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * CirclePlotter
	 * 
	 * @heather byrne
	 */
	public class StickFigureGlyphPlotter extends AbstractGlyphPlotter
	{
		public function StickFigureGlyphPlotter()
		{
		}

		/**
		 * This is the angle at which each line will be drawn from the vertical axis.
		 */
		public const theta1:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const theta2:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const theta3:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const theta4:DynamicColumn = newLinkableChild(this, DynamicColumn);
		/**
		 * This is the limb length.
		 */
		public const limbLength:AlwaysDefinedColumn = registerLinkableChild(this, AlwaysDefinedColumn(10));
		/**
		 * This is the line style used to draw the outline of the rectangle.
		 */
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		
		public const curvature:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0));

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
			var limbLength:Number = this.limbLength.getValueFromKey(recordKey, Number);
			tempPoint.x = dataX.getValueFromKey(recordKey, Number);
			tempPoint.y = dataY.getValueFromKey(recordKey, Number);
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
