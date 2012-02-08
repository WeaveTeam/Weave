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
	import flash.utils.Dictionary;
	
	import mx.utils.ObjectUtil;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IStatisticsCache;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.KeySets.KeySet;
	import weave.primitives.Bounds2D;
	import weave.primitives.ColorRamp;
	import weave.utils.ColumnUtils;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * This plotter displays a 2D histogram with optional colors.
	 * 
	 * @author skolman
	 */
	public class Histogram2DPlotter extends AbstractPlotter
	{
		public function Histogram2DPlotter()
		{
			// hack, only supports default color column
			var cc:ColorColumn = Weave.root.getObject(Weave.DEFAULT_COLOR_COLUMN) as ColorColumn;
			registerLinkableChild(this, cc);
			
			xColumn.addImmediateCallback(this, updateKeys);
			yColumn.addImmediateCallback(this, updateKeys);
			
			setKeySource(_keySet);
		}
		
		private var _keySet:KeySet = newDisposableChild(this, KeySet);
		
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const fillStyle:SolidFillStyle = newLinkableChild(this, SolidFillStyle);
		public const binColors:ColorRamp = registerLinkableChild(this, new ColorRamp("0xFFFFFF,0x000000"));
		
		public const xBinnedColumn:BinnedColumn = newSpatialProperty(BinnedColumn, handleColumnChange);
		public const yBinnedColumn:BinnedColumn = newSpatialProperty(BinnedColumn, handleColumnChange);
		
		public const showAverageColorData:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		public function get xColumn():DynamicColumn { return xBinnedColumn.internalDynamicColumn; }
		public function get yColumn():DynamicColumn { return yBinnedColumn.internalDynamicColumn; }
		
		private var cellToKeysMap:Object = {};
		private var keyToCellMap:Dictionary = new Dictionary(true);
		private var cellToAverageValueMap:Object = {};
		
		private var xBinWidth:Number;
		private var yBinWidth:Number;
		private var maxBinSize:int;
		
		private const tempPoint:Point = new Point();
		private const tempBounds:IBounds2D = new Bounds2D();

		private function updateKeys():void
		{
			_keySet.replaceKeys(ColumnUtils.getAllKeys([xBinnedColumn,yBinnedColumn]));
		}
		
		private function handleColumnChange():void
		{
			cellToKeysMap = {};
			cellToAverageValueMap = {};
			keyToCellMap = new Dictionary(true);
			maxBinSize = 0;
			
			for each (var key:IQualifiedKey in _keySet.keys)
			{
				var xCell:int = xBinnedColumn.getValueFromKey(key, Number);
				var yCell:int = yBinnedColumn.getValueFromKey(key, Number);
				var cell:String = String(xCell) + "," + String(yCell);
				
				keyToCellMap[key] = cell;
				
				var keys:Array = cellToKeysMap[cell] as Array;
				if (!keys)
					cellToKeysMap[cell] = keys = [];
				keys.push(key);
				maxBinSize = Math.max(maxBinSize, keys.length);
			}
			
			var xCol:IAttributeColumn = xBinnedColumn.internalColumn;
			var yCol:IAttributeColumn = yBinnedColumn.internalColumn;
			var sc:IStatisticsCache = WeaveAPI.StatisticsCache;
			xBinWidth = (sc.getMax(xCol) - sc.getMin(xCol)) / xBinnedColumn.numberOfBins;
			yBinWidth = (sc.getMax(yCol) - sc.getMin(yCol)) / yBinnedColumn.numberOfBins;
		}
		
		/**
		 * This draws the 2D histogram bins that a list of record keys fall into.
		 */
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if (isNaN(xBinWidth) || isNaN(yBinWidth))
				return;
			
			// hack, only supports default color column
			var colorCol:ColorColumn = Weave.root.getObject(Weave.DEFAULT_COLOR_COLUMN) as ColorColumn;
			var binCol:BinnedColumn = colorCol.internalColumn as BinnedColumn;
			var dataCol:IAttributeColumn = binCol ? binCol.internalDynamicColumn : null;
			var dataMin:Number = WeaveAPI.StatisticsCache.getMin(dataCol);
			var dataMax:Number = WeaveAPI.StatisticsCache.getMax(dataCol);
			var ramp:ColorRamp = showAverageColorData.value ? colorCol.ramp : this.binColors;
			
			var graphics:Graphics = tempShape.graphics;
			graphics.clear();
			
			// get a list of unique cells so each cell is only drawn once.
			var cells:Object = {};
			var cell:String;
			var keys:Array;
			for each (var key:IQualifiedKey in recordKeys)
			{
				cell = keyToCellMap[key];
				keys = cells[cell];
				if (!keys)
					cells[cell] = keys = [];
				keys.push(key);
			}
			
			// draw the cells
			for (cell in cells)
			{
				var cellIds:Array = cell.split(",");
				var xKeyID:int = int(cellIds[0]);
				var yKeyID:int = int(cellIds[1]);
				
				keys = cells[cell] as Array;
				
				tempPoint.x = xKeyID - 0.5;
				tempPoint.y = yKeyID - 0.5;
				dataBounds.projectPointTo(tempPoint, screenBounds);
				tempBounds.setMinPoint(tempPoint);
				tempPoint.x = xKeyID + 0.5;
				tempPoint.y = yKeyID + 0.5;
				dataBounds.projectPointTo(tempPoint, screenBounds);
				tempBounds.setMaxPoint(tempPoint);
				
				// draw rectangle for bin
				lineStyle.beginLineStyle(null, graphics);
				
				var norm:Number = keys.length / maxBinSize;
				
				if (showAverageColorData.value)
				{
					var sum:Number = 0;
					for each (key in keys)
						sum += dataCol.getValueFromKey(key, Number);
					var dataValue:Number = sum / keys.length;
					//norm = StandardLib.normalize(dataValue, dataMin, dataMax);
					norm = binCol.getBinIndexFromDataValue(dataValue) / (binCol.numberOfBins - 1);
				}
				
				var color:Number = ramp.getColorFromNorm(norm);
				graphics.beginFill(color, 1);
				
				graphics.drawRect(tempBounds.getXMin(), tempBounds.getYMin(), tempBounds.getWidth(), tempBounds.getHeight());
				graphics.endFill();
			}
			destination.draw(tempShape);
		}
		
		/**
		 * This function returns the collective bounds of all the bins.
		 */
		override public function getBackgroundDataBounds():IBounds2D
		{
			if (xBinnedColumn.internalColumn != null && yBinnedColumn.internalColumn != null)
				return getReusableBounds(-0.5, -0.5, xBinnedColumn.numberOfBins - 0.5, yBinnedColumn.numberOfBins -0.5);
			return getReusableBounds();
		}
		
		/**
		 * This gets the data bounds of the histogram bin that a record key falls into.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			
			if(xBinnedColumn.internalColumn == null || yBinnedColumn.internalColumn == null)
				return [getReusableBounds()];
			
			var shapeKey:String = keyToCellMap[recordKey];
			
			if(shapeKey == null)
				return [getReusableBounds()];
			
			var temp:Array = shapeKey.split(",");
			
			var xKey:int = temp[0];
			var yKey:int = temp[1];
			
			var xMin:Number = xKey - 0.5; 
			var yMin:Number = yKey - 0.5;
			var xMax:Number = xKey + 0.5; 
			var yMax:Number = yKey + 0.5;
			
			return [getReusableBounds(xMin,yMin,xMax,yMax)];
		}
		
	}
}
