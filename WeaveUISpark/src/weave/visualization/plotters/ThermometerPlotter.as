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
	import flash.display.BitmapData;
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.ISelectableAttributes;
	import weave.api.ui.IPlotTask;
	
	public class ThermometerPlotter extends MeterPlotter implements ISelectableAttributes
	{
		public function getSelectableAttributeNames():Array
		{
			return ["Meter"];
		}
		public function getSelectableAttributes():Array
		{
			return [meterColumn];
		}
		
		// reusable point objects
		private const bottom:Point = new Point(), top:Point = new Point();
		
		//the radius of the thermometer bulb (circle at bottom) in pixels
		private const bulbRadius:Number = 30;
		
		//the thickness of the thermometer red center line
		private const centerLineThickness:Number = 20;
		
		//the thickness of the thermometer background center line
		private const backgroundCenterLineThickness:Number = 30;
		
		//the color to use for background elements
		private const backgroundCenterLineColor:uint = 0x777777;
		
		//the x offset (in pixels) used when drawing all shapes (so axis line is fully visible) 
		private const xOffset:Number = backgroundCenterLineThickness/2+1;
		
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			//compute the meter value by averaging all record values
			var meterValue:Number = 0;
			var n:Number = task.recordKeys.length;
			
			for (var i:int = 0; i < n; i++)//TODO handle missing values
				meterValue += meterColumn.getValueFromKey(task.recordKeys[i] as IQualifiedKey, Number);
			meterValue /= n;
					
			if (isFinite(meterValue))
			{
				//clear the graphics
				var graphics:Graphics = tempShape.graphics;
				graphics.clear();
				
				//project bottom point
				bottom.x = bottom.y = 0;
				task.dataBounds.projectPointTo(bottom, task.screenBounds);
				bottom.x += xOffset;
				
				//project top point (data value)
				top.x = 0;
				top.y = meterValue;
				task.dataBounds.projectPointTo(top, task.screenBounds);
				top.x += xOffset;
				
				//draw the center line (from zero to data value)
				graphics.lineStyle(centerLineThickness,0xff0000,1.0, false, "normal", CapsStyle.NONE, null, 3);
				graphics.moveTo(bottom.x, bottom.y+bulbRadius);
				graphics.lineTo(top.x, top.y);
				
				task.buffer.draw(tempShape);
			}
			return 1;
		}
		
		/**
		 * This function draws the background graphics for this plotter, if applicable.
		 * An example background would be the origin lines of an axis.
		 * @param dataBounds The data coordinates that correspond to the given screenBounds.
		 * @param screenBounds The coordinates on the given sprite that correspond to the given dataBounds.
		 * @param destination The sprite to draw the graphics onto.
		 */
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var graphics:Graphics = tempShape.graphics;
			graphics.clear();
			
			//project bottom point
			bottom.x = bottom.y = 0;
			dataBounds.projectPointTo(bottom, screenBounds);
			bottom.x += xOffset;
			
			//project data max top point
			top.x = 0;
			top.y = meterColumnStats.getMax();
			dataBounds.projectPointTo(top, screenBounds);
			top.x += xOffset;
			
			//draw the background line (from zero to data max)
			graphics.lineStyle(backgroundCenterLineThickness,backgroundCenterLineColor);
			graphics.moveTo(bottom.x, bottom.y+bulbRadius);
			graphics.lineTo(top.x, top.y);
				
			//draw background circle
			graphics.lineStyle(5,backgroundCenterLineColor);
			graphics.beginFill(0xFF0000);
			graphics.drawCircle(bottom.x,bottom.y+bulbRadius,bulbRadius);
			graphics.endFill();
			
			destination.draw(tempShape);
		}
		
		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @param output An IBounds2D object to store the result in.
		 */
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			output.setBounds(0, 0, 1, meterColumnStats.getMax());
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			initBoundsArray(output).setBounds(0, 0, 1, meterColumnStats.getMax());
		}
	}
}


