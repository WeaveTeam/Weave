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
			bitmapText.maxHeight = Math.abs(bitmapBounds.getYMin() - screenBounds.getYMin());
			bitmapText.maxWidth = bitmapBounds.getXCoverage() / columns.length;
			bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER;
			
			for (var i:int = 0; i < columns.length; i++)
			{
				var column:IAttributeColumn = columns[i] as IAttributeColumn;
				var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(column); // note: watched plotter already registers stats as child
				
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
				bitmapText.text = ColumnUtils.deriveStringFromNumber(column, normalize ? stats.getMin() : dataBounds.getYMin());
				bitmapText.x = minPoint.x;
				bitmapText.y = minPoint.y;
				bitmapText.verticalAlign = screenBounds.getYDirection() > 0 ? BitmapText.VERTICAL_ALIGN_BOTTOM : BitmapText.VERTICAL_ALIGN_TOP;
				bitmapText.draw(destination);
				
				// draw axis max value
				bitmapText.text = ColumnUtils.deriveStringFromNumber(column, normalize ? stats.getMax() : dataBounds.getYMax());
				bitmapText.x = maxPoint.x;
				bitmapText.y = maxPoint.y;
				bitmapText.verticalAlign = screenBounds.getYDirection() > 0 ? BitmapText.VERTICAL_ALIGN_TOP : BitmapText.VERTICAL_ALIGN_BOTTOM;
				bitmapText.draw(destination);
				
				// draw axis title
				bitmapText.text = ColumnUtils.getTitle(column);
				bitmapText.x = minPoint.x;
				bitmapText.y = bitmapBounds.getYMin(); // align to bottom of bitmap
				bitmapText.verticalAlign = bitmapBounds.getYDirection() > 0 ? BitmapText.VERTICAL_ALIGN_TOP : BitmapText.VERTICAL_ALIGN_BOTTOM;
				bitmapText.draw(destination);
			}
			
			destination.draw(tempShape);
		}
	}
}
