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
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableVariable;
	import weave.core.LinkableWatcher;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	import weave.utils.ColumnUtils;
	import weave.utils.LinkableTextFormat;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	public class SimpleParallelCoordinatesAxesPlotter extends AbstractPlotter
	{
		public function SimpleParallelCoordinatesAxesPlotter()
		{
		}
		
		public const plotterPath:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array, arrayTypeIsString), handlePlotterPath);
		private const plotterWatcher:LinkableWatcher = registerLinkableChild(this, new LinkableWatcher(SimpleParallelCoordinatesPlotter));
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		private const textFormat:LinkableTextFormat = registerLinkableChild(this, Weave.properties.visTextFormat);
		
		private const bitmapText:BitmapText = new BitmapText();
		private static const minPoint:Point = new Point();
		private static const maxPoint:Point = new Point();
		private static const bitmapBounds:Bounds2D = new Bounds2D();
		
		private function arrayTypeIsString(array:Array):Boolean
		{
			return StandardLib.getArrayType(array) == String;
		}
		
		private function handlePlotterPath():void
		{
			plotterWatcher.targetPath = plotterPath.getSessionState() as Array;
		}
		
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			var plotter:SimpleParallelCoordinatesPlotter = plotterWatcher.target as SimpleParallelCoordinatesPlotter;
			if (plotter)
			{
				plotter.getBackgroundDataBounds(output)
				output.setXRange(output.getXNumericMin() - 0.5, output.getXNumericMax() + 0.5);
			}
			else
			{
				output.reset();
			}
		}
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var graphics:Graphics = tempShape.graphics;
			var plotter:SimpleParallelCoordinatesPlotter = plotterWatcher.target as SimpleParallelCoordinatesPlotter;
			if (!plotter)
				return;
			var columns:Array = plotter.columns.getObjects();
			var normalize:Boolean = plotter.normalize.value;
			
			// set up bitmapBounds so the direction matches that of screenBounds
			if (screenBounds.getXDirection() > 0)
				bitmapBounds.setXRange(0, destination.width);
			else
				bitmapBounds.setXRange(destination.width, 0);
			if (screenBounds.getYDirection() > 0)
				bitmapBounds.setYRange(0, destination.height);
			else
				bitmapBounds.setYRange(destination.height, 0);

			graphics.clear();
			lineStyle.beginLineStyle(null, graphics);
			textFormat.copyTo(bitmapText.textFormat);
			var maxMarginHeight:Number = Math.abs(bitmapBounds.getYMax() - screenBounds.getYMax());
			var minMarginHeight:Number = Math.abs(bitmapBounds.getYMin() - screenBounds.getYMin());
			bitmapText.maxWidth = bitmapBounds.getXCoverage() / columns.length;
			bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER;
			
			for (var i:int = 0; i < columns.length; i++)
			{
				var column:IAttributeColumn = columns[i] as IAttributeColumn;
				var dataMin:Number = dataBounds.getYMin();
				var dataMax:Number = dataBounds.getYMax();
				if (normalize)
				{
					// note: watched plotter already registers stats as child, so change will be detected
					var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(column);
					var statsMin:Number = stats.getMin();
					var statsMax:Number = stats.getMax();
					dataMin = StandardLib.scale(dataMin, 0, 1, statsMin, statsMax);
					dataMax = StandardLib.scale(dataMax, 0, 1, statsMin, statsMax);
				}
				
				// get coords for axis line
				minPoint.x = i;
				minPoint.y = dataBounds.getYMin();
				dataBounds.projectPointTo(minPoint, screenBounds);
				maxPoint.x = i;
				maxPoint.y = dataBounds.getYMax();
				dataBounds.projectPointTo(maxPoint, screenBounds);
				
				// draw vertical axis line
				graphics.moveTo(minPoint.x, minPoint.y);
				graphics.lineTo(maxPoint.x, maxPoint.y);
				
				// draw axis min value
				bitmapText.text = ColumnUtils.deriveStringFromNumber(column, dataMin);
				bitmapText.x = minPoint.x;
				bitmapText.y = minPoint.y;
				bitmapText.verticalAlign = screenBounds.getYDirection() > 0 ? BitmapText.VERTICAL_ALIGN_BOTTOM : BitmapText.VERTICAL_ALIGN_TOP;
				bitmapText.maxHeight = minMarginHeight / 2;
				bitmapText.draw(destination);
				
				// draw axis max value
				bitmapText.text = ColumnUtils.deriveStringFromNumber(column, dataMax);
				bitmapText.x = maxPoint.x;
				bitmapText.y = maxPoint.y;
				bitmapText.verticalAlign = screenBounds.getYDirection() > 0 ? BitmapText.VERTICAL_ALIGN_TOP : BitmapText.VERTICAL_ALIGN_BOTTOM;
				bitmapText.maxHeight = maxMarginHeight;
				bitmapText.draw(destination);
				
				// draw axis title in min margin
				bitmapText.text = ColumnUtils.getTitle(column);
				bitmapText.x = minPoint.x;
				bitmapText.y = bitmapBounds.getYMin(); // align to bottom of bitmap
				bitmapText.verticalAlign = bitmapBounds.getYDirection() > 0 ? BitmapText.VERTICAL_ALIGN_TOP : BitmapText.VERTICAL_ALIGN_BOTTOM;
				bitmapText.maxHeight = minMarginHeight / 2;
				bitmapText.draw(destination);
			}
			
			destination.draw(tempShape);
		}
	}
}
