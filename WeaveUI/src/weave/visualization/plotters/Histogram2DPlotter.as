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
	
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.SessionManager;
	import weave.core.StageUtils;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.BinningDefinitions.DynamicBinningDefinition;
	import weave.data.KeySets.KeySet;
	import weave.data.QKeyManager;
	import weave.data.StatisticsCache;
	import weave.primitives.Bounds2D;
	import weave.primitives.ColorRamp;
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
			init();
		}
		private function init():void
		{
			
			xColumn.addImmediateCallback(this,updateKeys);
			yColumn.addImmediateCallback(this,updateKeys);
			
			setKeySource(_keySet);
		}
		
		private var _keySet:KeySet = newDisposableChild(this,KeySet);
		private function updateKeys():void
		{
			getAllKeys(_keySet,[xBinnedColumn,yBinnedColumn]);
			handleColumnChange();
		}
		
		private function getAllKeys(outputKeySet:KeySet, inputKeySets:Array):void
		{
			outputKeySet.delayCallbacks();
			outputKeySet.clearKeys();
			
			for (var i:int = 0; i < inputKeySets.length; i++)
			{
				outputKeySet.addKeys((inputKeySets[i]).keys);
			}
			outputKeySet.resumeCallbacks();			
		}
		
		
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const fillStyle:SolidFillStyle = newLinkableChild(this, SolidFillStyle);
		public const binColors:ColorRamp = registerLinkableChild(this, new ColorRamp("0xFFFFFF,0x000000")); // bars get their color from here
		
		public const xBinnedColumn:BinnedColumn = newSpatialProperty(BinnedColumn,handleColumnChange);
		public const yBinnedColumn:BinnedColumn = newSpatialProperty(BinnedColumn,handleColumnChange);
		
		public function get xColumn():DynamicColumn {return xBinnedColumn.internalDynamicColumn;}
		public function get yColumn():DynamicColumn {return yBinnedColumn.internalDynamicColumn;}
		
		private var cellToKeysMap:Object = {};
		private var keyToCellMap:Dictionary = new Dictionary(true);
		private function handleColumnChange():void
		{
			
			if(xBinnedColumn.internalColumn != null && yBinnedColumn.internalColumn != null)
			{
				cellToKeysMap = {};
				keyToCellMap = new Dictionary(true);
				
				for each(var key:Object in _keySet.keys)
				{
					var xCell:int = xBinnedColumn.getValueFromKey(key as IQualifiedKey,Number);
					var yCell:int = yBinnedColumn.getValueFromKey(key as IQualifiedKey,Number);
					
					var cell:String = String(xCell) + "," + String(yCell);
					
					keyToCellMap[key] = cell;
					
					if(!cellToKeysMap[cell])
						cellToKeysMap[cell] = [];
					
					(cellToKeysMap[cell] as Array).push(key);
				
				}
			}
			
			calculateMinMaxWidth();
		}
		
	
		
		/**
		 * This draws the 2D histogram bins that a list of record keys fall into.
		 */
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if(xBinnedColumn == null || yBinnedColumn == null)
				return;
			
			
			if (isNaN(xBinWidth))
				return;
			if (isNaN(yBinWidth))
				return;
			
			// find max bin size
			var max:int = 0;
			for (var obj:Object in cellToKeysMap)
			{
				max = Math.max(max, ((cellToKeysMap[obj] as Array).length));
			}
			
			
			var graphics:Graphics = tempShape.graphics;
			graphics.clear();
			
			
			for each (var key:Object in recordKeys)
			{
				
				var shapeKey:String = keyToCellMap[key];
				
				var keys:Array = (cellToKeysMap[shapeKey] as Array);
				
				var binSize:int = keys.length;
				
				var shapeKeyIds:Array = (shapeKey as String).split(",");
				var xKeyID:int = shapeKeyIds[0];
				var yKeyID:int = shapeKeyIds[1];
				
				
				tempPoint.x = xKeyID - 0.5; 
				tempPoint.y = yKeyID - 0.5;
				dataBounds.projectPointTo(tempPoint, screenBounds);
				tempBounds.setMinPoint(tempPoint);
				tempPoint.x = xKeyID + 0.5; 
				tempPoint.y = yKeyID+ 0.5;
				dataBounds.projectPointTo(tempPoint, screenBounds);
				tempBounds.setMaxPoint(tempPoint);
				
				// draw rectangle for bin
				lineStyle.beginLineStyle(null, graphics);
				
				
				var norm:Number = binSize/max;
				var color:Number = binColors.getColorFromNorm(norm);
				graphics.beginFill(color, 1);
				
				graphics.drawRect(tempBounds.getXMin(), tempBounds.getYMin(), tempBounds.getWidth(), tempBounds.getHeight());
				graphics.endFill();
				
			}
			destination.draw(tempShape);
		}
		
		private var xDataMin:Number;
		private var yDataMin:Number;
		private var xDataMax:Number;
		private var yDataMax:Number;
		
		private var xBinWidth:Number;
		private var yBinWidth:Number;
		
		private function calculateMinMaxWidth():void
		{
			if(xBinnedColumn == null || yBinnedColumn == null)
				return;
			
			var xAttrColumn:IAttributeColumn = xBinnedColumn.internalColumn;
			var yAttrColumn:IAttributeColumn = yBinnedColumn.internalColumn;
			
			if (xAttrColumn == null || yAttrColumn == null)
			{
				return;
			}
			
			xDataMin = StatisticsCache.instance.getMin(xAttrColumn);
			xDataMax = StatisticsCache.instance.getMax(xAttrColumn);
			yDataMin = StatisticsCache.instance.getMin(yAttrColumn);
			yDataMax = StatisticsCache.instance.getMax(yAttrColumn);
			
			xBinWidth = (xDataMax - xDataMin) / xBinnedColumn.numberOfBins;
			yBinWidth = (yDataMax - yDataMin) / yBinnedColumn.numberOfBins;
		}
		
		private const tempPoint:Point = new Point();
		private const tempBounds:IBounds2D = new Bounds2D();
		
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
