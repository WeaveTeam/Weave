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
	import weave.api.WeaveAPI;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.ISimpleGeometry;
	import weave.api.getCallbackCollection;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.api.ui.IPlotterWithGeometries;
	import weave.core.LinkableWatcher;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.EquationColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.KeySets.KeySet;
	import weave.primitives.GeometryType;
	import weave.primitives.SimpleGeometry;
	import weave.utils.AsyncSort;
	import weave.utils.ColumnUtils;
	import weave.utils.DrawUtils;
	import weave.utils.ObjectPool;
	import weave.utils.VectorUtils;
	import weave.visualization.plotters.styles.ExtendedLineStyle;
	
	/**	
	 * @author heather byrne
	 * @author adufilie
	 * @author abaumann
	 */
	public class ParallelCoordinatesPlotter extends AbstractPlotter implements IPlotterWithGeometries 
	{
		public function ParallelCoordinatesPlotter()
		{
			lineStyle.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			lineStyle.weight.defaultValue.value = 1;
			lineStyle.alpha.defaultValue.value = 1.0;
			
			zoomToSubset.value = true;
			clipDrawing = false;
			
			// bounds need to be re-indexed when this option changes
			registerSpatialProperty(Weave.properties.enableGeometryProbing);
			columns.childListCallbacks.addImmediateCallback(this, handleColumnsListChange);
			xColumns.childListCallbacks.addImmediateCallback(this,handleColumnsListChange);
			
			
			lineStyle.color.internalDynamicColumn.addImmediateCallback(this, handleColor, true);
			getCallbackCollection(colorDataWatcher).addImmediateCallback(this, updateFilterEquationColumns, true);
			
			// updateFilterEquationColumns sets key source
		}
		private function handleColumnsListChange():void
		{
			// When a new column is created, register the stats to trigger callbacks and affect busy status.
			// This will be cleaned up automatically when the column is disposed.
			    var newColumn:IAttributeColumn = columns.childListCallbacks.lastObjectAdded as IAttributeColumn;
			if (newColumn)
				registerLinkableChild(spatialCallbacks, WeaveAPI.StatisticsCache.getColumnStatistics(newColumn));
			
				var newtestColumn:IAttributeColumn = xColumns.childListCallbacks.lastObjectAdded as IAttributeColumn;
			if (newtestColumn)
				registerLinkableChild(spatialCallbacks, WeaveAPI.StatisticsCache.getColumnStatistics(newtestColumn));
			
			_columns = columns.getObjects();
			_xattrObjects = xColumns.getObjects();
            if(_columns.length != _xattrObjects.length)
				_xattrObjects.length = 0;
			// if there is only one column, push a copy of it so lines will be drawn
			if (_columns.length == 1)
				_columns.push(_columns[0]);
			
			if (_xattrObjects.length == 1)
				_xattrObjects.push(_xattrObjects[0]);
			
			updateFilterEquationColumns();
		}

		/*
		 * This is the line style used to draw the lines.
		 */
		public const lineStyle:ExtendedLineStyle = newLinkableChild(this, ExtendedLineStyle);
		
		public function get alphaColumn():AlwaysDefinedColumn { return lineStyle.alpha; }
		
		public const columns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		
		public const xColumns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		
		public const enableGroupBy:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false), updateFilterEquationColumns);
		public const groupBy:DynamicColumn = newSpatialProperty(DynamicColumn, updateFilterEquationColumns);
		public const xData:DynamicColumn = newSpatialProperty(DynamicColumn, updateFilterEquationColumns);
		public const yData:DynamicColumn = newSpatialProperty(DynamicColumn, updateFilterEquationColumns);
		public const xValues:LinkableString = newSpatialProperty(LinkableString, updateFilterEquationColumns);
		
		private const _keySet_groupBy:KeySet = newDisposableChild(this, KeySet);
		
		private var _columns:Array = [];
		private var _xattrObjects:Array = [];
		
		private const colorDataWatcher:LinkableWatcher = newDisposableChild(this, LinkableWatcher);
		private function handleColor():void
		{
			var cc:ColorColumn = lineStyle.color.getInternalColumn() as ColorColumn;
			var bc:BinnedColumn = cc ? cc.getInternalColumn() as BinnedColumn : null;
			var fc:FilteredColumn = bc ? bc.getInternalColumn() as FilteredColumn : null;
			colorDataWatcher.target = fc ? fc.internalDynamicColumn : null;
		}
		
		public function getXValues():Array
		{
			// if session state is defined, use that. otherwise, get the values from xData
			if (xValues.value)
			{
				return VectorUtils.flatten(WeaveAPI.CSVParser.parseCSV(xValues.value));
			}
			else
			{
				// calculate from column
				var values:Array = [];
				for each (var key:IQualifiedKey in xData.keys)
					values.push(xData.getValueFromKey(key, String));
				AsyncSort.sortImmediately(values);
				VectorUtils.removeDuplicatesFromSortedArray(values);
				return values;
			}
		}
		
		private var _in_updateFilterEquationColumns:Boolean = false;
		private function updateFilterEquationColumns():void
		{
			if (_in_updateFilterEquationColumns)
				return;
			_in_updateFilterEquationColumns = true;
			
			if (enableGroupBy.value)
			{
				setSingleKeySource(_keySet_groupBy);
			}
			else
			{
				var list:Array = _columns.concat();
				list.unshift(lineStyle.color);
				setColumnKeySources(list);
				
				_in_updateFilterEquationColumns = false;
				return;
			}
			
			// update keys
			_keySet_groupBy.delayCallbacks();
			var reverseKeys:Array = []; // a list of the keys returned as values from keyColumn
			var lookup:Dictionary = new Dictionary(); // keeps track of what keys were already seen
			for each (var key:IQualifiedKey in groupBy.keys)
			{
				var filterKey:IQualifiedKey = groupBy.getValueFromKey(key, IQualifiedKey) as IQualifiedKey;
				if (filterKey && !lookup[filterKey])
				{
					lookup[filterKey] = true;
					reverseKeys.push(filterKey);
				}
			}
			_keySet_groupBy.replaceKeys(reverseKeys);
			_keySet_groupBy.resumeCallbacks();

			// check for missing columns
			if (!(xData.getInternalColumn() && yData.getInternalColumn() && groupBy.getInternalColumn()))
			{
				if (groupBy.getInternalColumn())
					columns.removeAllObjects();
				
				if(_xattrObjects.length > 0)
					xColumns.removeAllObjects();
				_in_updateFilterEquationColumns = false;
				return;
			}
			
			// check that column keytypes are the same
			var keyType:String = ColumnUtils.getKeyType(groupBy);
			if (keyType != ColumnUtils.getKeyType(xData) || keyType != ColumnUtils.getKeyType(yData))
			{
				_in_updateFilterEquationColumns = false;
				return;
			}
			
			columns.delayCallbacks();
			columns.removeAllObjects();

			var keyCol:DynamicColumn;
			var filterCol:DynamicColumn;
			var dataCol:DynamicColumn;
			
			var values:Array = getXValues();
			for (var i:int = 0; i < values.length; i++)
			{
				var value:String = values[i];
				var col:EquationColumn = columns.requestObject(columns.generateUniqueName("line"), EquationColumn, false);
				col.delayCallbacks();
				col.variables.requestObjectCopy("keyCol", groupBy);
				col.variables.requestObjectCopy("filterCol", xData);
				col.variables.requestObjectCopy("dataCol", yData);
				
				col.setMetadata(ColumnMetadata.TITLE, value);
				col.setMetadata(ColumnMetadata.MIN, '{ getMin(dataCol) }');
				col.setMetadata(ColumnMetadata.MAX, '{ getMax(dataCol) }');
				
				col.equation.value = 'getValueFromFilterColumn(keyCol, filterCol, dataCol, "'+value+'", Number)';
				col.resumeCallbacks();
			}				
			
			columns.resumeCallbacks();
			_in_updateFilterEquationColumns = false;
		}
		
		public const normalize:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(true));
		public const curveType:LinkableString = registerLinkableChild(this, new LinkableString(CURVE_NONE, curveTypeVerifier));
		public const zoomToSubset:LinkableBoolean = newSpatialProperty(LinkableBoolean);

		public const shapeSize:LinkableNumber = registerLinkableChild(this, new LinkableNumber(5));
		public const shapeToDraw:LinkableString = registerLinkableChild(this, new LinkableString(SOLID_CIRCLE, shapeTypeVerifier));
		public const shapeBorderThickness:LinkableNumber = registerLinkableChild(this, new LinkableNumber(1));
		public const shapeBorderColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000000));
		
		public static const CURVE_NONE:String = 'none';
		public static const CURVE_TOWARDS:String = 'towards';
		public static const CURVE_AWAY:String = 'away';
		public static const CURVE_DOUBLE:String = 'double';
		private function curveTypeVerifier(type:String):Boolean
		{
			//BACKWARDS COMPATIBILITY 0.9.6
			// technically, the verifier function is not supposed to do this.
			if (type == "ParallelCoordinatesPlotter.LINE_STRAIGHT")
				curveType.value = CURVE_NONE;
			if (type == "ParallelCoordinatesPlotter.LINE_CURVE_TOWARDS")
				curveType.value = CURVE_TOWARDS;
			if (type == "ParallelCoordinatesPlotter.LINE_CURVE_AWAY")
				curveType.value = CURVE_AWAY;
			if (type == "ParallelCoordinatesPlotter.LINE_DOUBLE_CURVE")
				curveType.value = CURVE_DOUBLE;
			
			var types:Array = [CURVE_NONE, CURVE_TOWARDS, CURVE_AWAY, CURVE_DOUBLE];
			return types.indexOf(type) >= 0;
		}

		public static const shapesAvailable:Array = [NO_SHAPE, SOLID_CIRCLE, EMPTY_CIRCLE, SOLID_SQUARE, EMPTY_SQUARE];
		
		public static const NO_SHAPE:String 	  = "No Shape";
		public static const SOLID_CIRCLE:String   = "Solid Circle";
		public static const EMPTY_CIRCLE:String   = "Empty Circle";
		public static const SOLID_SQUARE:String   = "Solid Square";
		public static const EMPTY_SQUARE:String   = "Empty Square";
		private function shapeTypeVerifier(type:String):Boolean
		{
			return shapesAvailable.indexOf(type) >= 0;
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			getBoundsCoords(recordKey, output, true);
		}
		
		protected function getBoundsCoords(recordKey:IQualifiedKey, output:Array, forGetDataBounds:Boolean):void
		{
			var enableGeomProbing:Boolean = Weave.properties.enableGeometryProbing.value;
			
			initBoundsArray(output, _columns.length);
			
			var _normalize:Boolean = normalize.value;
			var outIndex:int = 0;
			for (var i:int = 0; i < _columns.length; ++i)
			{
				var yColumn:IAttributeColumn = _columns[i] as IAttributeColumn;
				var x:Number = getXAttributeCoordinates(recordKey, i);
				var y:Number = _normalize
					? WeaveAPI.StatisticsCache.getColumnStatistics(yColumn).getNorm(recordKey)
					: yColumn.getValueFromKey(recordKey, Number);
				if (!forGetDataBounds || isFinite(x) && isFinite(y))
					(output[outIndex] as IBounds2D).includeCoords(x, y);
				// when geom probing is enabled, report a single data bounds
				if (!forGetDataBounds || !enableGeomProbing)
					outIndex++;
			}
			while (output.length > outIndex + 1)
				ObjectPool.returnObject(output.pop());
		}
		
		private var tempBoundsArray:Array = [];
		
		public function getGeometriesFromRecordKey(recordKey:IQualifiedKey, minImportance:Number = 0, bounds:IBounds2D = null):Array
		{
			getBoundsCoords(recordKey, tempBoundsArray, false);
			
			var results:Array = [];
			var _normalize:Boolean = normalize.value;
			
			// push three geometries between each column
			var geometry:ISimpleGeometry;
			
			for (var i:int = 1; i < _columns.length; ++i)
			{
				var bounds:IBounds2D = tempBoundsArray[i] as IBounds2D;
				var prevBounds:IBounds2D = tempBoundsArray[i - 1] as IBounds2D;
				
				if (!bounds.isUndefined())
				{
					if (!prevBounds.isUndefined())
					{
						// both defined
						geometry = new SimpleGeometry(GeometryType.LINE);
						geometry.setVertices([
							new Point(prevBounds.getXMin(), prevBounds.getYMin()),
							new Point(bounds.getXMin(), bounds.getYMin())
						]);
						results.push(geometry);
					}
					else
					{
						// current bounds defined, previous undefined
						geometry = new SimpleGeometry(GeometryType.POINT);
						geometry.setVertices([
							new Point(bounds.getXMin(), bounds.getYMin())
						]);
						results.push(geometry);
					}
				}
				else if (i == 1 && !prevBounds.isUndefined())
				{
					// special case where i == 1 and prev bounds is defined, but current bounds is undefined
					geometry = new SimpleGeometry(GeometryType.POINT);
					geometry.setVertices([
						new Point(prevBounds.getXMin(), prevBounds.getYMin())
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
		
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			var graphics:Graphics = tempShape.graphics;

			// project data coordinates to screen coordinates and draw graphics onto tempShape
			var i:int;
			var _normalize:Boolean = normalize.value;
			var _shapeSize:Number = this.shapeSize.value;
			var _prevX:Number = 0;
			var _prevY:Number = 0;
			var continueLine:Boolean = false;
			
			for (i = 0; i < _columns.length; i++)
			{
				// project data coordinates to screen coordinates and draw graphics
				
				tempPoint.x = getXAttributeCoordinates(recordKey, i);
				
				if (_normalize)
					tempPoint.y = WeaveAPI.StatisticsCache.getColumnStatistics(_columns[i]).getNorm(recordKey);
				else
					tempPoint.y = (_columns[i] as IAttributeColumn).getValueFromKey(recordKey, Number);
				
				if (isNaN(tempPoint.x))
				{
					continueLine = false;
					continue;
				}
				
				if (isNaN(tempPoint.y))
				{
					continueLine = false;
					continue;
				}
				
				dataBounds.projectPointTo(tempPoint, screenBounds);				
				var x:Number = tempPoint.x;
				var y:Number = tempPoint.y;
				
				// thickness of the line around each shape
				var shapeLineThickness:int = shapeBorderThickness.value;
				if(_shapeSize > 0)
				{
					var shapeSize:Number = _shapeSize;
					
					// use a border around each shape
					graphics.lineStyle(shapeLineThickness, shapeBorderColor.value, shapeLineThickness == 0 ? 0 : 1);
					// draw a different shape for each option
					switch(shapeToDraw.value)
					{								
						// solid circle
						case SOLID_CIRCLE:
							graphics.beginFill(lineStyle.color.getValueFromKey(recordKey));
							// circle uses radius, so size/2
							graphics.drawCircle(x, y, shapeSize/2);
							break;
						// empty circle
						case EMPTY_CIRCLE:
							graphics.lineStyle(shapeLineThickness, lineStyle.color.getValueFromKey(recordKey), shapeLineThickness == 0 ? 0 : 1);
							graphics.drawCircle(x, y, shapeSize/2);
							
							break;
						// solid square
						case SOLID_SQUARE:
							graphics.beginFill(lineStyle.color.getValueFromKey(recordKey));
							graphics.drawRect(x-_shapeSize/2, y-_shapeSize/2, _shapeSize, _shapeSize);
							break;
						// empty square
						case EMPTY_SQUARE:
							graphics.lineStyle(shapeLineThickness, lineStyle.color.getValueFromKey(recordKey), shapeLineThickness == 0 ? 0 : 1);
							graphics.drawRect(x-_shapeSize/2, y-_shapeSize/2, _shapeSize, _shapeSize);
							break;
					}
					
					graphics.endFill();
				}
				
				// begin the line style for the parallel coordinates line
				// we want to use the missing data line style since the line is the shape we are showing 
				// (rather than just a border of another shape)
				lineStyle.beginLineStyle(recordKey, graphics);				
				
				// if we aren't continuing a new line (it is a new line segment)	
				if (!continueLine)
				{
					// set the previous X and Y locations to be this new coordinate
					_prevX = x;
					_prevY = y;
				}
				
				if (curveType.value == CURVE_NONE)
				{
					graphics.moveTo(_prevX, _prevY);
					graphics.lineTo(x, y);
					//DrawUtils.drawDashedLine(tempShape.graphics, _prevX, _prevY, x, y, 3, 2); 
				}
				else if (curveType.value == CURVE_DOUBLE)
					DrawUtils.drawDoubleCurve(graphics, _prevX, _prevY, x, y, true, 1);
				else if (curveType.value == CURVE_TOWARDS)
					DrawUtils.drawCurvedLine(graphics, _prevX,  _prevY, x, y, -1);
				else if (curveType.value == CURVE_AWAY)
					DrawUtils.drawCurvedLine(graphics, _prevX,  _prevY, x, y,  1);
				
				continueLine = true;

				_prevX = x;
				_prevY = y;
			}
		}
		
		public function yAxisLabelFunction(value:Number):String
		{
			var _columns:Array = columns.getObjects();
			if (_columns.length > 0)
				return ColumnUtils.deriveStringFromNumber(_columns[0], value); // always use the first column to format the axis labels
			return null;
		}
		
		
		public function xAxisLabelFunction(value:Number):String
		{
			try{
				
			if(usingXAttributes)
			{
				var check:String =  ColumnUtils.deriveStringFromNumber(_xattrObjects[0], value);
				return check;
			}
			else
				return ColumnUtils.getTitle(_columns[value]);
			}catch(e:Error){};
			
			return "";
		}
		
		
		public function get usingXAttributes():Boolean
		{
			if(_xattrObjects.length == _columns.length)
				return true;
			else
				return false;
		}
		
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			// normalized data coordinates
			if (zoomToSubset.value)
			{
				output.reset();
			}
			else
			{
				output.setBounds(0, 0, Math.max(1, columns.getNames().length - 1), 1);
				
				if (!normalize.value)
				{
					// reset y coords
					output.setYRange(NaN, NaN);
					for each (var column:IAttributeColumn in columns.getObjects())
					{
						var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(column);
						// expand y range to include all data coordinates
						output.includeCoords(0, stats.getMin());
						output.includeCoords(0, stats.getMax());
					}
					
					if(_xattrObjects.length > 0)
					{
						output.setXRange(NaN,NaN);
						for each (var col:IAttributeColumn in _xattrObjects)
						{
							var colStats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(col);
							// expand x range to include all data coordinates
							output.includeCoords(colStats.getMin(),NaN);
							output.includeCoords(colStats.getMax(),NaN);
						}
					}
					
					
				}
			}
		}
		
		public function getXAttributeCoordinates(recordKey:IQualifiedKey, i:int):Number
		{
			var x:Number ;
			
				if(i < _xattrObjects.length)
						x = _xattrObjects[i].getValueFromKey(recordKey, Number);
				else if(_xattrObjects.length > 0)
					x = NaN;
				else x = i;
				
				return x;
			
		}
		private static const tempPoint:Point = new Point(); // reusable object
		
		
		
		// backwards compatibility
		[Deprecated(replacement="enableGroupBy")] public function set displayFilterColumn(value:Object):void { setSessionState(enableGroupBy, value); }
		[Deprecated(replacement="groupBy")] public function set keyColumn(value:Object):void { setSessionState(groupBy, value); }
		[Deprecated(replacement="xData")] public function set filterColumn(value:Object):void { setSessionState(xData, value); }
		[Deprecated(replacement="xValues")] public function set filterValues(value:Object):void { setSessionState(xValues, value); }
		[Deprecated(replacement="xValues")] public function set groupByValues(value:Object):void { setSessionState(xValues, value); }
		[Deprecated(replacement="xColumns")] public function set xAttributeColumns(value:Object):void { setSessionState(xColumns, value, true); }
	}
}
