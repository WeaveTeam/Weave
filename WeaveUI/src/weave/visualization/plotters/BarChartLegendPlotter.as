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
	import flash.utils.Dictionary;
	
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableFunction;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.primitives.Bounds2D;
	import weave.primitives.ColorRamp;
	import weave.utils.ColumnUtils;
	import weave.utils.LegendUtils;
	import weave.utils.LinkableTextFormat;
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
			registerLinkableChild(this, LinkableTextFormat.defaultTextFormat); // redraw when text format changes
		}
		
		public const columns:ILinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn), createColumnHashes);
		public const chartColors:ColorRamp = newSpatialProperty(ColorRamp);
		public const shapeSize:LinkableNumber = registerLinkableChild(this, new LinkableNumber(12));
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		[Bindable] public var numColumns:int = 0;
		private var _columnOrdering:Array = [];
		private var _columnToBounds:Dictionary = new Dictionary();
		private var _columnToTitle:Dictionary = new Dictionary();
		private var _maxBoxSize:Number = 8;
		
		/**
		 * This is the maximum number of items to draw in a single row.
		 * @default 1 
		 */		
		public const maxColumns:LinkableNumber = registerSpatialProperty(new LinkableNumber(1), createColumnHashes);
		
		/**
		 * This is an option to reverse the item order.
		 * @default true
		 */		
		public const ascendingOrder:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(true), createColumnHashes);
		
		/**
		 * This is the compiled function to apply to the item labels.
		 * 
		 * @default string
		 */		
		public const itemLabelFunction:LinkableFunction = registerSpatialProperty(new LinkableFunction('string', true, false, ['number','string']), createColumnHashes);

		// TODO This should go somewhere else...
		/**
		 * This is the compiled function to apply to the title of the tool.
		 * 
		 * @default string  
		 */		
		public const legendTitleFunction:LinkableFunction = registerLinkableChild(this, new LinkableFunction('string', true, false, ['string']));
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			return getReusableBounds(0, 0, 1, 1);
		}
		
		private function createColumnHashes():void
		{
			_columnOrdering = [];
			_columnToBounds = new Dictionary();
			_columnToTitle = new Dictionary();
			var columnObjects:Array = columns.getObjects();
			numColumns = columnObjects.length;
			for (var i:int = 0; i < numColumns; ++i)
			{
				var column:IAttributeColumn = columnObjects[i];
				var colTitle:String = ColumnUtils.getTitle(column);
				var b:IBounds2D = new Bounds2D();
				
				_columnOrdering.push(column);
				try
				{
					_columnToTitle[column] = itemLabelFunction.apply(null, [i, colTitle]);
				}
				catch (e:Error)
				{
					_columnToTitle[column] = colTitle;
				}
			}
			
			if (ascendingOrder.value)
				_columnOrdering = _columnOrdering.reverse(); 
		}

		private const _itemBounds:IBounds2D = new Bounds2D();
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			screenBounds.getRectangle(clipRectangle);
			var g:Graphics = tempShape.graphics;
			g.clear();
			lineStyle.beginLineStyle(null, g);
			var maxCols:int = maxColumns.value;
			var margin:int = 4;
			var actualShapeSize:int = Math.max(_maxBoxSize, shapeSize.value);
			for (var iColumn:int = 0; iColumn < numColumns; ++iColumn)
			{
				var column:IAttributeColumn = _columnOrdering[iColumn];
				var title:String = _columnToTitle[column];
				LegendUtils.getBoundsFromItemID(screenBounds, iColumn, _itemBounds, numColumns, maxCols);
				LegendUtils.renderLegendItemText(destination, title, _itemBounds, actualShapeSize + margin, clipRectangle);

				// draw the rectangle
				// if we have reversed the order of the columns, iColumn should match the colors (this has always been backwards?)
				// otherwise, we reverse the iColorIndex
				var iColorIndex:int = ascendingOrder.value ? (numColumns - 1 - iColumn) : iColumn;
				var color:Number = chartColors.getColorFromNorm(iColorIndex / (numColumns - 1));
				if (color <= Infinity) // alternative to !isNaN()
					g.beginFill(color, 1.0);
				var xMin:Number = _itemBounds.getXNumericMin();
				var xMax:Number = _itemBounds.getXNumericMax();
				var yMin:Number = _itemBounds.getYNumericMin();
				var yMax:Number = _itemBounds.getYNumericMax();
				var yCoverage:Number = _itemBounds.getYCoverage();
				// we don't want the rectangles touching
				yMin += 0.1 * yCoverage;
				yMax -= 0.1 * yCoverage;
				tempShape.graphics.drawRect(
					xMin,
					yMin,
					actualShapeSize,
					yMax - yMin
				);
			}
			destination.draw(tempShape, null, null, null, clipRectangle);
		}
		
		// backwards compatibility
		[Deprecated(replacement="ascendingOrder")] public function set reverseOrder(value:Boolean):void { ascendingOrder.value = value; }
	}
}
