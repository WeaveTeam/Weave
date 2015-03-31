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
	
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.ISelectableAttributes;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.utils.DrawUtils;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	public class StickFigureGlyphPlotter extends AbstractGlyphPlotter implements ISelectableAttributes
	{
		public function StickFigureGlyphPlotter()
		{
		}
		
		public function getSelectableAttributeNames():Array
		{
			return ["X", "Y", "Theta 1", "Theta 2", "Theta 3", "Theta 4"];
		}
		public function getSelectableAttributes():Array
		{
			return [dataX, dataY, theta1, theta2, theta3, theta4];
		}

		/**
		 * This is the angle at which each line will be drawn from the vertical axis.
		 */
		public const theta1:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const theta2:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const theta3:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const theta4:DynamicColumn = newLinkableChild(this, DynamicColumn);
		
		private const theta1stats:IColumnStatistics = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(theta1));
		private const theta2stats:IColumnStatistics = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(theta2));
		private const theta3stats:IColumnStatistics = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(theta3));
		private const theta4stats:IColumnStatistics = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(theta4));
		/**
		 * This is the limb length.
		 */
		public const limbLength:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(10));
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
			var theta1:Number = Math.PI*theta1stats.getNorm(recordKey);
			var theta2:Number = Math.PI*theta2stats.getNorm(recordKey);
			var theta3:Number = Math.PI*theta3stats.getNorm(recordKey);
			var theta4:Number = Math.PI*theta4stats.getNorm(recordKey);
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
