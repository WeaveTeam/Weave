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
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import org.oicweave.Weave;
	import org.oicweave.api.WeaveAPI;
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.api.primitives.IBounds2D;
	import org.oicweave.compiler.MathLib;
	import org.oicweave.core.LinkableNumber;
	import org.oicweave.data.AttributeColumns.BinnedColumn;
	import org.oicweave.data.AttributeColumns.ColorColumn;
	import org.oicweave.data.AttributeColumns.DynamicColumn;
	import org.oicweave.primitives.Bounds2D;
	import org.oicweave.utils.BitmapText;
	import org.oicweave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * This plotter displays a legend for a ColorColumn.  If the ColorColumn contains a BinnedColumn, a list of bins
	 * with their corresponding colors will be displayed.  If not a continuous color scale will be displayed.  By
	 * default this plotter links to the static color column, but it can be linked to another by changing or removing
	 * the dynamicColorColumn.staticName value.
	 * 
	 * @author adufilie
	 */
	public class ColorBinLegendPlotter extends AbstractPlotter
	{
		public function ColorBinLegendPlotter()
		{
			init();
		}
		private function init():void
		{
			dynamicColorColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			
			setKeySource(dynamicColorColumn);
			
			registerNonSpatialProperties(
				Weave.properties.axisFontSize,
				Weave.properties.axisFontColor,
				Weave.properties.axisFontFamily,
				Weave.properties.axisFontItalic,
				Weave.properties.axisFontUnderline,
				Weave.properties.axisFontBold
			);
		}
		
		
		/**
		 * This plotter is specifically implemented for visualizing a ColorColumn.
		 * This DynamicColumn only allows internal columns of type ColorColumn.
		 */
		public const dynamicColorColumn:DynamicColumn = registerSpatialProperty(new DynamicColumn(ColorColumn));
		
		/**
		 * This accessor function provides convenient access to the internal ColorColumn.
		 * The public session state is defined by dynamicColorColumn.
		 */
		public function get internalColorColumn():ColorColumn
		{
			return dynamicColorColumn.internalColumn as ColorColumn;
		}
		
		// this is used to draw text on bitmaps
		private const bitmapText:BitmapText = new BitmapText();
		
		/**
		 * This is the radius of the circle, in screen coordinates.
		 */
		public const shapeSize:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(20));
		/**
		 * This is the line style used to draw the outline of the shape.
		 */
		public const lineStyle:SolidLineStyle = newNonSpatialProperty(SolidLineStyle);

		private var _drawBackground:Boolean = false; // this is used to check if we should draw the bins with no records.
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// draw the bins that have no records in them in the background
			_drawBackground = true;
			drawBinnedPlot(keySet.keys, dataBounds, screenBounds, destination);
			_drawBackground = false;
		}

		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if (internalColorColumn == null)
				return; // draw nothing
			if (internalColorColumn.internalColumn is BinnedColumn)
				drawBinnedPlot(recordKeys, dataBounds, screenBounds, destination);
			else
				drawContinuousPlot(recordKeys, dataBounds, screenBounds, destination);
		}
			
		protected function drawContinuousPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			//todo
		}
		
		protected function drawBinnedPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var binnedColumn:BinnedColumn = internalColorColumn.internalColumn as BinnedColumn;
			
			// convert record keys to bin keys
			// save a mapping of each bin key found to a value of true
			var binIndexMap:Dictionary = new Dictionary();
			for (var i:int = 0; i < recordKeys.length; i++)
				binIndexMap[ binnedColumn.getValueFromKey(recordKeys[i], Number) ] = 1;
			
			var margin:int = 4;
			
			// get height of record graphics
			var height:Number = screenBounds.getYCoverage() / dataBounds.getYCoverage();
			var actualShapeSize:int = Math.max(7, Math.min(shapeSize.value, height - margin));
			
			// draw the bins
			var binCount:int = binnedColumn.derivedBins.getObjects().length;
			for (var binIndex:int = 0; binIndex < binCount; binIndex++)
			{
				// if _drawBackground is set, we should draw the bins that have no records in them.
				if ((_drawBackground?0:1) ^ int(binIndexMap[binIndex])) // xor
					continue;
				
				var internalMin:Number = WeaveAPI.StatisticsCache.getMin(internalColorColumn.internalDynamicColumn);
				var internalMax:Number = WeaveAPI.StatisticsCache.getMax(internalColorColumn.internalDynamicColumn);
				var color:Number = internalColorColumn.ramp.getColorFromNorm(MathLib.normalize(binIndex, internalMin, internalMax));
				
				var xMin:Number = screenBounds.getXNumericMin();
				var xMax:Number = screenBounds.getXNumericMax();
				
				// get y coordinate to display graphics at.
				tempPoint.y = binIndex;
				dataBounds.projectPointTo(tempPoint, screenBounds);
				var y:Number = tempPoint.y;
				
				// draw almost-invisible rectangle (for probe filters)
				tempBounds.copyFrom(dataBounds);
				tempBounds.setCenteredYRange(binIndex, 1)

				dataBounds.projectCoordsTo(tempBounds, screenBounds);
				
				tempBounds.getRectangle(tempRectangle);
				destination.fillRect(tempRectangle, 0x02808080);
				
				// draw circle
				var g:Graphics = tempShape.graphics;
				g.clear();
				lineStyle.beginLineStyle(null, g);
				if (!isNaN(color))
					g.beginFill(color, 1.0);
				tempShape.graphics.drawCircle(margin + xMin + actualShapeSize / 2, y, actualShapeSize / 2);
				destination.draw(tempShape);
				
				// set up BitmapText
				bitmapText.textFormat.size = Weave.properties.axisFontSize.value;
				bitmapText.textFormat.color = Weave.properties.axisFontColor.value;
				bitmapText.textFormat.font = Weave.properties.axisFontFamily.value;
				bitmapText.textFormat.bold = Weave.properties.axisFontBold.value;
				bitmapText.textFormat.italic = Weave.properties.axisFontItalic.value;
				bitmapText.textFormat.underline = Weave.properties.axisFontUnderline.value;
				bitmapText.text = binnedColumn.deriveStringFromNumber(binIndex);
				bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER;
				bitmapText.x = xMin + actualShapeSize + margin * 2;
				bitmapText.y = y;
				bitmapText.draw(destination);
			}
		}
		
		// reusable temporary objects
		private const tempPoint:Point = new Point();
		private const tempBounds:IBounds2D = new Bounds2D();
		private const tempRectangle:Rectangle = new Rectangle();
		
		private var XMIN:Number = 0, XMAX:Number = 1;
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var bounds:IBounds2D = getReusableBounds();
			
			if (internalColorColumn.internalColumn)
			{
				var y:Number = internalColorColumn.internalColumn.getValueFromKey(recordKey, Number) as Number;
				bounds.setBounds(XMIN, y, XMAX, y);
				if (internalColorColumn.internalColumn is BinnedColumn)
					bounds.setHeight(1); // include 0.5 beyond binIndex
			}
			else
			{
				bounds.reset();
			}
			
			return [bounds];
		}
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			var bounds:IBounds2D = getReusableBounds();
			
			var min:Number = WeaveAPI.StatisticsCache.getMin(internalColorColumn.internalColumn);
			var max:Number = WeaveAPI.StatisticsCache.getMax(internalColorColumn.internalColumn);
			bounds.setBounds(XMIN, min, XMAX, max);
			if (internalColorColumn.internalColumn is BinnedColumn)
				bounds.setHeight(bounds.getHeight() + 1); // include 0.5 beyond min and max
			
			return bounds;
		}
	}
}
