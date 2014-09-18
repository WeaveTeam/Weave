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
	import flash.utils.Dictionary;
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.ISimpleGeometry;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.ISelectableAttributes;
	import weave.api.ui.IPlotter;
	import weave.api.ui.IPlotterWithGeometries;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeometryType;
	import weave.primitives.SimpleGeometry;
	import weave.utils.DrawUtils;
	import weave.utils.ObjectPool;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	public class SimpleParallelCoordinatesPlotter extends AbstractPlotter implements IPlotterWithGeometries, ISelectableAttributes
	{
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, SimpleParallelCoordinatesPlotter, "Parallel Coordinates");
		
		private static const tempBoundsArray:Array = []; // Array of reusable Bounds2D objects
		private static const tempPoint:Point = new Point(); // reusable Point object
		
		public const columns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		public const normalize:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(true));
		public const selectableLines:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));
		
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const curvedLines:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		private var _columns:Array = [];
		private var _stats:Dictionary = new Dictionary(true);
		private var extendPointBounds:Number = 0.25; // extends point bounds when selectableLines is false
		private var drawStubs:Boolean = true; // draws stubbed line segments eminating from points with missing neighboring values
		
		public function SimpleParallelCoordinatesPlotter()
		{
			lineStyle.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			lineStyle.weight.defaultValue.value = 1;
			lineStyle.alpha.defaultValue.value = 1.0;
			
			clipDrawing = false;
			
			// bounds need to be re-indexed when this option changes
			registerSpatialProperty(Weave.properties.enableGeometryProbing);
			columns.childListCallbacks.addImmediateCallback(this, handleColumnsListChange);
		}
		private function handleColumnsListChange():void
		{
			// When a new column is created, register the stats to trigger callbacks and affect busy status.
			// This will be cleaned up automatically when the column is disposed.
			var newColumn:IAttributeColumn = columns.childListCallbacks.lastObjectAdded as IAttributeColumn;
			if (newColumn)
			{
				_stats[newColumn] = WeaveAPI.StatisticsCache.getColumnStatistics(newColumn);
				registerLinkableChild(spatialCallbacks, _stats[newColumn]);
			}
			
			_columns = columns.getObjects();
			
			setColumnKeySources([lineStyle.color].concat(_columns));
		}
		
		public function getSelectableAttributeNames():Array
		{
			return ["Color", "Columns"];
		}
		public function getSelectableAttributes():Array
		{
			return [lineStyle.color, columns];
		}

		/**
		 * Gets an Array of numeric values from the columns.
		 * @param recordKey A key.
		 * @return An Array Numbers.
		 */
		private function getValues(recordKey:IQualifiedKey):Array
		{
			var output:Array = new Array(_columns.length);
			for (var i:int = 0; i < _columns.length; i++)
			{
				var column:IAttributeColumn = _columns[i];
				if (normalize.value)
					output[i] = (_stats[column] as IColumnStatistics).getNorm(recordKey);
				else
					output[i] = column.getValueFromKey(recordKey, Number);
			}
			return output;
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			var enableGeomProbing:Boolean = Weave.properties.enableGeometryProbing.value;
			
			var values:Array = getValues(recordKey);
			
			// when geom probing is enabled, report a single data bounds
			initBoundsArray(output, enableGeomProbing ? 1 : values.length);
			
			var stubSize:Number = selectableLines.value ? 0.5 : extendPointBounds;
			var outputIndex:int = 0;
			for (var x:int = 0; x < values.length; x++)
			{
				var y:Number = values[x];
				if (isFinite(y))
				{
					var bounds:IBounds2D = output[outputIndex] as IBounds2D;
					bounds.includeCoords(x, y);
					if (drawStubs)
					{
						bounds.includeCoords(x - stubSize, y);
						bounds.includeCoords(x + stubSize, y);
					}
					if (!enableGeomProbing)
						outputIndex++;
				}
			}
		}
		
		public function getGeometriesFromRecordKey(recordKey:IQualifiedKey, minImportance:Number = 0, dataBounds:IBounds2D = null):Array
		{
			var x:int;
			var y:Number;
			var results:Array = [];
			var values:Array = getValues(recordKey);
			if (selectableLines.value)
			{
				var continueLine:Boolean = false;
				for (x = 0; x < values.length; x++)
				{
					y = values[x];
					if (isFinite(y))
					{
						if (continueLine)
						{
							// finite -> finite
							results.push(new SimpleGeometry(GeometryType.LINE, [
								new Point(x - 1, values[x - 1]),
								new Point(x, y)
							]));
						}
						else
						{
							// NaN -> finite
							if (drawStubs && x > 0)
							{
								results.push(new SimpleGeometry(GeometryType.LINE, [
									new Point(x - 0.5, y),
									new Point(x, y)
								]));
							}
							else if (x == values.length - 1)
							{
								results.push(new SimpleGeometry(GeometryType.POINT, [
									new Point(x, y)
								]));
							}
						}
						continueLine = true;
					}
					else
					{
						if (continueLine)
						{
							// finite -> NaN
							y = values[x - 1];
							if (drawStubs)
							{
								results.push(new SimpleGeometry(GeometryType.LINE, [
									new Point(x - 1, y),
									new Point(x - 0.5, y)
								]));
							}
							else
							{
								results.push(new SimpleGeometry(GeometryType.POINT, [
									new Point(x - 1, y)
								]));
							}
						}
						continueLine = false;
					}
				}
			}
			else
			{
				for (x = 0; x < values.length; x++)
				{
					y = values[x];
					if (isFinite(y))
					{
						if (extendPointBounds)
							results.push(new SimpleGeometry(GeometryType.LINE, [
								new Point(x - extendPointBounds, y),
								new Point(x + extendPointBounds, y)
							]));
						else
							results.push(new SimpleGeometry(GeometryType.POINT, [
								new Point(x, y)
							]));
					}
				}
			}
			
			return results;
		}
		
		public function getBackgroundGeometries():Array
		{
			return [];
		}
		
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			var graphics:Graphics = tempShape.graphics;
			var prevScreenX:Number = NaN;
			var prevScreenY:Number = NaN;
			var continueLine:Boolean = false;
			
			lineStyle.beginLineStyle(recordKey, graphics);
			
			var values:Array = getValues(recordKey);
			for (var x:int = 0; x < values.length; x++)
			{
				var y:Number = values[x];
				if (!isFinite(y))
				{
					// missing value
					if (drawStubs && continueLine)
					{
						// previous value was not missing, so half a horizontal line eminating from the previous point
						tempPoint.x = x - 0.5;
						tempPoint.y = values[x - 1];
						dataBounds.projectPointTo(tempPoint, screenBounds);
						graphics.lineTo(tempPoint.x, tempPoint.y);
					}
					
					continueLine = false;
					continue;
				}
				
				// value is not missing
				
				if (x > 0 && drawStubs && !continueLine)
				{
					// previous value was missing, so draw half a horizontal line going into the current point
					tempPoint.x = x - 0.5;
					tempPoint.y = y;
					dataBounds.projectPointTo(tempPoint, screenBounds);
					prevScreenX = tempPoint.x
					prevScreenY = tempPoint.y;
					graphics.moveTo(prevScreenX, prevScreenY);
					continueLine = true;
				}
				
				tempPoint.x = x;
				tempPoint.y = y;
				dataBounds.projectPointTo(tempPoint, screenBounds);
				if (continueLine)
				{
					if (curvedLines.value)
						DrawUtils.drawDoubleCurve(graphics, prevScreenX, prevScreenY, tempPoint.x, tempPoint.y, true, 1, continueLine);
					else
						graphics.lineTo(tempPoint.x, tempPoint.y);
				}
				else
					graphics.moveTo(tempPoint.x, tempPoint.y);
				
				continueLine = true;
				prevScreenX = tempPoint.x;
				prevScreenY = tempPoint.y;
			}
		}
		
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			output.setXRange(0, _columns.length - 1);
			if (normalize.value)
			{
				output.setYRange(0, 1);
			}
			else
			{
				output.setYRange(NaN, NaN);
				for (var i:int = 0; i < _columns.length; i++)
				{
					var stats:IColumnStatistics = _stats[_columns[i]];
					output.includeCoords(i, stats.getMin());
					output.includeCoords(i, stats.getMax());
				}
			}
		}
	}
}
