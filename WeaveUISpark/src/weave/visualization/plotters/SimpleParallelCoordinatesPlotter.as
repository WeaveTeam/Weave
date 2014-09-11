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
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.ISimpleGeometry;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IObjectWithSelectableAttributes;
	import weave.api.ui.IPlotter;
	import weave.api.ui.IPlotterWithGeometries;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.primitives.GeometryType;
	import weave.primitives.SimpleGeometry;
	import weave.utils.DrawUtils;
	import weave.utils.ObjectPool;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	public class SimpleParallelCoordinatesPlotter extends AbstractPlotter implements IPlotterWithGeometries, IObjectWithSelectableAttributes
	{
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, SimpleParallelCoordinatesPlotter, "Parallel Coordinates");
		
		public const columns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		public const normalize:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(true));
		public const selectableLines:LinkableBoolean = newSpatialProperty(LinkableBoolean);
		
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const curvedLines:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		private var _columns:Array = [];
		private static const tempBoundsArray:Array = []; // Array of reusable Bounds2D objects
		private static const tempPoint:Point = new Point(); // reusable Point object
		
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
				registerLinkableChild(spatialCallbacks, WeaveAPI.StatisticsCache.getColumnStatistics(newColumn));
			
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

		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			getBoundsCoords(recordKey, output, false);
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
					output[i] = WeaveAPI.StatisticsCache.getColumnStatistics(column).getNorm(recordKey);
				else
					output[i] = column.getValueFromKey(recordKey, Number);
			}
			return output;
		}
		
		
		/**
		 * Gets an Array of Bounds2D objects for a given key in data coordinates.
		 * @parma recordKey The key
		 * @param output Used to store the Bounds2D objects.
		 * @param includeUndefinedBounds If this is set to true, the output is guaranteed to have the same length as _yColumns.
		 */
		protected function getBoundsCoords(recordKey:IQualifiedKey, output:Array, includeUndefinedBounds:Boolean):void
		{
			var enableGeomProbing:Boolean = Weave.properties.enableGeometryProbing.value;
			
			initBoundsArray(output, _columns.length);
			
			var values:Array = getValues(recordKey);
			var outIndex:int = 0;
			for (var x:int = 0; x < values.length; ++x)
			{
				var y:Number = values[x];
				if (includeUndefinedBounds || isFinite(y))
					(output[outIndex] as IBounds2D).includeCoords(x, y);
				// when geom probing is enabled, report a single data bounds
				if (includeUndefinedBounds || !enableGeomProbing)
					outIndex++;
			}
			while (output.length > outIndex + 1)
				ObjectPool.returnObject(output.pop());
		}
		
		public function getGeometriesFromRecordKey(recordKey:IQualifiedKey, minImportance:Number = 0, dataBounds:IBounds2D = null):Array
		{
			getBoundsCoords(recordKey, tempBoundsArray, true);
			
			var results:Array = [];
			var geometry:ISimpleGeometry;
			var includeLines:Boolean = selectableLines.value;
			
			for (var i:int = 0; i < _columns.length; ++i)
			{
				var current:IBounds2D = tempBoundsArray[i] as IBounds2D;
				var next:IBounds2D = tempBoundsArray[i + 1] as IBounds2D;
				
				if (includeLines && next && !next.isUndefined())
				{
					if (current.isUndefined())
					{
						// current undefined, next defined
						geometry = new SimpleGeometry(GeometryType.POINT);
						geometry.setVertices([
							new Point(next.getXMin(), next.getYMin())
						]);
						results.push(geometry);
					}
					else
					{
						// both current and next are defined
						geometry = new SimpleGeometry(GeometryType.LINE);
						geometry.setVertices([
							new Point(current.getXMin(), current.getYMin()),
							new Point(next.getXMin(), next.getYMin())
						]);
						results.push(geometry);
					}
				}
				else if (!current.isUndefined() && (i == 0 || !includeLines))
				{
					// special case: i == 0, current defined, next undefined
					geometry = new SimpleGeometry(GeometryType.POINT);
					geometry.setVertices([
						new Point(current.getXMin(), current.getYMin())
					]);
					results.push(geometry);
				}
			}

			return results;
		}
		
		public function getBackgroundGeometries():Array
		{
			return [];
		}
		
		private var drawStubs:Boolean = true;
		
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
					var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(_columns[i]);
					output.includeCoords(i, stats.getMin());
					output.includeCoords(i, stats.getMax());
				}
			}
		}
	}
}
