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
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.primitives.Bounds2D;
	import weave.primitives.ColorRamp;
	import weave.utils.BitmapText;
	import weave.utils.ColumnUtils;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * This plotter displays a colored circle and a label for a list of bins.
	 * 
	 * @author adufilie
	 */
	public class BarChartLegendPlotter extends AbstractPlotter
	{
		public function BarChartLegendPlotter()
		{
			init();
		}
		private function init():void
		{
			shapeSize.value = 12;
			
//			//***
//			//ToDo get columns from event dispatch from CompoundBarChartTool
//			var compoundBarChartTool:CompoundBarChartTool = Weave.getObject("CompoundBarChartTool") as CompoundBarChartTool;
//			var siv:SimpleInteractiveVisualization = compoundBarChartTool.children.getObject("visualization") as SimpleInteractiveVisualization;
//			var sp:SelectablePlotLayer = siv.layers.getObject("plot") as SelectablePlotLayer;
//			var dynamicPlotter:DynamicPlotter = sp.plotter as DynamicPlotter;
//			var barChartPlotter:CompoundBarChartPlotter = dynamicPlotter.internalObject as CompoundBarChartPlotter;
//			//chartColors = barChartPlotter.chartColors;
//			//dynamicColumns = barChartPlotter.heightColumns.getObjects(DynamicColumn);
//			//***
			
			registerNonSpatialProperties(
				Weave.properties.axisFontSize,
				Weave.properties.axisFontColor,
				Weave.properties.axisFontFamily,
				Weave.properties.axisFontItalic,
				Weave.properties.axisFontUnderline,
				Weave.properties.axisFontBold
			);
		}
		
		public const columns:ILinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		public const chartColors:ColorRamp = newSpatialProperty(ColorRamp);
		
		// this is used to draw text on bitmaps
		private const bitmapText:BitmapText = new BitmapText();
		
		/**
		 * This is the radius of the circle, in screen coordinates.
		 */
		public const shapeSize:LinkableNumber = newNonSpatialProperty(LinkableNumber);
		/**
		 * This is the line style used to draw the outline of the shape.
		 */
		public const lineStyle:SolidLineStyle = newNonSpatialProperty(SolidLineStyle);
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// draw nothing -- everything is in the background layer
		}
		
		private const tempPoint:Point = new Point(); // reusable temporary object
		
		private var XMIN:Number = 0, XMAX:Number = 1;
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			var columnObjects:Array = columns.getObjects();
			var yMin:Number = 0;
			var yMax:Number = columnObjects.length - 1;
			return getReusableBounds(XMIN, yMin - 0.5, XMAX, yMax + 0.5);
		}
		
		private var _legendBoxSize:Number = 0.4;
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var margin:int = 4;
			
			// get height of record graphics
			var height:Number = screenBounds.getYCoverage() / dataBounds.getYCoverage();
			var actualShapeSize:int = Math.max(7, Math.min(shapeSize.value, height));
			
			var columnObjects:Array = columns.getObjects().reverse();
			// draw the bins
			for (var i:int = 0; i < columnObjects.length; i++)
			{
				//***
				// draw graphics
				var color:Number = chartColors.getColorFromNorm(i / (columnObjects.length - 1));
				
				var xMin:Number = screenBounds.getXNumericMin();
				var xMax:Number = screenBounds.getXNumericMax();
				
				// get y coordinate to display graphics at.
				tempPoint.y = i - _legendBoxSize;
				dataBounds.projectPointTo(tempPoint, screenBounds);
				var yMin:Number = tempPoint.y;
				tempPoint.y = i + _legendBoxSize;
				dataBounds.projectPointTo(tempPoint, screenBounds);
				var yMax:Number = tempPoint.y;
				
				// draw circle
				var g:Graphics = tempShape.graphics;
				g.clear();
				lineStyle.beginLineStyle(null, g);
				if (!isNaN(color))
					g.beginFill(color, 1.0);
				tempShape.graphics.drawRect(
						xMin,
						yMin,
						actualShapeSize,
						yMax - yMin
					);
				destination.draw(tempShape);
				
				// set up BitmapText
				bitmapText.textFormat.size = Weave.properties.axisFontSize.value;
				bitmapText.textFormat.color = Weave.properties.axisFontColor.value;
				bitmapText.textFormat.font = Weave.properties.axisFontFamily.value;
				bitmapText.textFormat.bold = Weave.properties.axisFontBold.value;
				bitmapText.textFormat.italic = Weave.properties.axisFontItalic.value;
				bitmapText.textFormat.underline = Weave.properties.axisFontUnderline.value;
				bitmapText.text = ColumnUtils.getTitle(columnObjects[i]);
				bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER;
				bitmapText.x = xMin + actualShapeSize + margin;
				bitmapText.y = (yMin + yMax) / 2;
				bitmapText.draw(destination);
			}
		}
	}
}
