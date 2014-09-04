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
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.ISimpleGeometry;
	import weave.api.detectLinkableObjectChange;
	import weave.api.getCallbackCollection;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.api.ui.IObjectWithSelectableAttributes;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotterWithGeometries;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.LinkableWatcher;
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
	
	public class ParallelCoordinatesPlotter extends AbstractPlotter implements IPlotterWithGeometries, IObjectWithSelectableAttributes
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
			xColumns.childListCallbacks.addImmediateCallback(this, handleColumnsListChange);
			
			linkSessionState(_filteredXData.filter, filteredKeySet.keyFilter);
			linkSessionState(_filteredYData.filter, filteredKeySet.keyFilter);
			registerLinkableChild(this, xData, updateFilterEquationColumns);
			registerLinkableChild(this, yData, updateFilterEquationColumns);
			
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
			
			var newXColumn:IAttributeColumn = xColumns.childListCallbacks.lastObjectAdded as IAttributeColumn;
			if (newXColumn)
				registerLinkableChild(spatialCallbacks, WeaveAPI.StatisticsCache.getColumnStatistics(newXColumn));
			
			_yColumns = columns.getObjects();
			_xColumns = xColumns.getObjects();
            if(_yColumns.length != _xColumns.length)
			{
				_xColumns.length = 0;
				// if there is only one column, push a copy of it so lines will be drawn
				if (_yColumns.length == 1)
					_yColumns.push(_yColumns[0]);
			}
			
			updateFilterEquationColumns();
		}
		
		
		public function getSelectableAttributeNames():Array
		{
			if (enableGroupBy.value)
				return ["X values", "Y values", "Group by", "Color"];
			else
				return ["Color", "Y Columns"];
		}
		public function getSelectableAttributes():Array
		{
			if (enableGroupBy.value)
				return [xData, yData, groupBy, lineStyle.color];
			else
				return [lineStyle.color, columns];
		}

		/*
		 * This is the line style used to draw the lines.
		 */
		public const lineStyle:ExtendedLineStyle = newLinkableChild(this, ExtendedLineStyle);
		
		public const columns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		public const xColumns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		
		public const enableGroupBy:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false), updateFilterEquationColumns);
		public const groupBy:DynamicColumn = newSpatialProperty(DynamicColumn, updateFilterEquationColumns);
		public const groupKeyType:LinkableString = newSpatialProperty(LinkableString, updateFilterEquationColumns);
		public function get xData():DynamicColumn { return _filteredXData.internalDynamicColumn; }
		public function get yData():DynamicColumn { return _filteredYData.internalDynamicColumn; }
		public const xValues:LinkableString = newSpatialProperty(LinkableString, updateFilterEquationColumns);
		
		private const _filteredXData:FilteredColumn = newSpatialProperty(FilteredColumn);
		private const _filteredYData:FilteredColumn = newSpatialProperty(FilteredColumn);
		private const _keySet_groupBy:KeySet = newDisposableChild(this, KeySet);
		
		private var _yColumns:Array = [];
		private var _xColumns:Array = [];
		
		private const colorDataWatcher:LinkableWatcher = newDisposableChild(this, LinkableWatcher);
		private function handleColor():void
		{
			var cc:ColorColumn = lineStyle.color.getInternalColumn() as ColorColumn;
			var bc:BinnedColumn = cc ? cc.getInternalColumn() as BinnedColumn : null;
			var fc:FilteredColumn = bc ? bc.getInternalColumn() as FilteredColumn : null;
			var dc:DynamicColumn = fc ? fc.internalDynamicColumn : null;
			colorDataWatcher.target = dc || fc || bc || cc;
		}
		
		private var _xValues:Array;
		public function getXValues():Array
		{
			if (!detectLinkableObjectChange(getXValues, xValues, xData))
				return _xValues;
			
			var values:Array;
			// if session state is defined, use that. otherwise, get the values from xData
			if (xValues.value)
			{
				values = WeaveAPI.CSVParser.parseCSVRow(xValues.value) || [];
			}
			else
			{
				// calculate from column
				values = [];
				for each (var key:IQualifiedKey in xData.keys)
					values.push(xData.getValueFromKey(key, String));
				AsyncSort.sortImmediately(values);
				VectorUtils.removeDuplicatesFromSortedArray(values);
			}
			return _xValues = values.filter(function(value:String, ..._):Boolean { return value ? true : false; });
		}
		
		public function getForeignKeyType():String
		{
			var foreignKeyType:String = groupKeyType.value;
			if (foreignKeyType)
				return foreignKeyType;
			foreignKeyType = groupBy.getMetadata(ColumnMetadata.DATA_TYPE);
			var groupByKeyType:String = groupBy.getMetadata(ColumnMetadata.KEY_TYPE);
			var lineColorKeyType:String = lineStyle.color.getMetadata(ColumnMetadata.KEY_TYPE);
			if ((!foreignKeyType || foreignKeyType == DataType.STRING) && groupByKeyType != lineColorKeyType)
				foreignKeyType = lineColorKeyType;
			return foreignKeyType;
		}
		
		private var _in_updateFilterEquationColumns:Boolean = false;
		private function updateFilterEquationColumns():void
		{
			if (_in_updateFilterEquationColumns)
				return;
			_in_updateFilterEquationColumns = true;
			
			if (enableGroupBy.value)
			{
				setColumnKeySources([_keySet_groupBy, groupBy]);
			}
			else
			{
				var list:Array = _yColumns.concat();
				if (colorDataWatcher.target)
					list.unshift(colorDataWatcher.target);
				setColumnKeySources(list);
				
				_in_updateFilterEquationColumns = false;
				return;
			}
			
			// update keys
			_keySet_groupBy.delayCallbacks();
			var reverseKeys:Array = []; // a list of the keys returned as values from keyColumn
			var lookup:Dictionary = new Dictionary(); // keeps track of what keys were already seen
			var foreignKeyType:String = getForeignKeyType();
			for each (var key:IQualifiedKey in groupBy.keys)
			{
				var localName:String = groupBy.getValueFromKey(key, String) as String;
				var filterKey:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(foreignKeyType, localName);
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
				
				if(_xColumns.length > 0)
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

			var values:Array = getXValues();
			
			// remove columns with names not appearing in values list
			for each (var name:String in columns.getNames())
				if (values.indexOf(name) < 0)
					columns.removeObject(name);
			
			// create an equation column for each filter value
			for (var i:int = 0; i < values.length; i++)
			{
				var value:String = values[i];
				var col:EquationColumn = columns.requestObject(value, EquationColumn, false);
				col.delayCallbacks();
				col.variables.requestObjectCopy("keyCol", groupBy);
				col.variables.requestObjectCopy("filterCol", _filteredXData);
				col.variables.requestObjectCopy("dataCol", _filteredYData);
				var filterValue:LinkableString = col.variables.requestObject('filterValue', LinkableString, false);
				filterValue.value = value;
				
				col.setMetadataProperty(ColumnMetadata.TITLE, value);
				col.setMetadataProperty(ColumnMetadata.MIN, '{ getMin(dataCol) }');
				col.setMetadataProperty(ColumnMetadata.MAX, '{ getMax(dataCol) }');
				
				col.equation.value = 'getValueFromFilterColumn(keyCol, filterCol, dataCol, filterValue.value, dataType)';
				col.resumeCallbacks();
			}
			columns.setNameOrder(values);
			
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
		public const shapeBorderAlpha:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0.5));
		
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

		public static const shapesAvailable:Array = [NO_SHAPE, SOLID_CIRCLE, SOLID_SQUARE, EMPTY_CIRCLE, EMPTY_SQUARE];
		
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
			getBoundsCoords(recordKey, output, false);
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
			
			initBoundsArray(output, _yColumns.length);
			
			var outIndex:int = 0;
			for (var i:int = 0; i < _yColumns.length; ++i)
			{
				getCoords(recordKey, i, tempPoint);
				if (includeUndefinedBounds || isFinite(tempPoint.x) && isFinite(tempPoint.y))
					(output[outIndex] as IBounds2D).includePoint(tempPoint);
				// when geom probing is enabled, report a single data bounds
				if (includeUndefinedBounds || !enableGeomProbing)
					outIndex++;
			}
			while (output.length > outIndex + 1)
				ObjectPool.returnObject(output.pop());
		}
		
		private var tempBoundsArray:Array = [];
		
		public function getGeometriesFromRecordKey(recordKey:IQualifiedKey, minImportance:Number = 0, dataBounds:IBounds2D = null):Array
		{
			getBoundsCoords(recordKey, tempBoundsArray, true);
			
			var results:Array = [];
			var geometry:ISimpleGeometry;
			
			for (var i:int = 0; i < _yColumns.length; ++i)
			{
				var current:IBounds2D = tempBoundsArray[i] as IBounds2D;
				var next:IBounds2D = tempBoundsArray[i + 1] as IBounds2D;
				
				if (next && !next.isUndefined())
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
				else if (i == 0 && !current.isUndefined())
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
		
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			// this template will draw one record per iteration
			if (task.iteration < task.recordKeys.length)
			{
				//------------------------
				// draw one record
				var key:IQualifiedKey = task.recordKeys[task.iteration] as IQualifiedKey;
				if (enableGroupBy.value)
				{
					// reset lookup on first iteration
					if (task.iteration == 0)
						task.asyncState = new Dictionary();
						
					// replace groupBy keys with foreign keys so we only render lines for foreign keys
					var foreignKeyType:String = getForeignKeyType();
					if (key.keyType != foreignKeyType)
						key = WeaveAPI.QKeyManager.getQKey(foreignKeyType, groupBy.getValueFromKey(key, String));
					
					// avoid rendering duplicate lines
					if (task.asyncState[key])
						return task.iteration / task.recordKeys.length;
					task.asyncState[key] = true;
				}
				
				tempShape.graphics.clear();
				addRecordGraphicsToTempShape(key, task.dataBounds, task.screenBounds, tempShape);
				if (clipDrawing)
				{
					// get clipRectangle
					task.screenBounds.getRectangle(clipRectangle);
					// increase width and height by 1 to avoid clipping rectangle borders drawn with vector graphics.
					clipRectangle.width++;
					clipRectangle.height++;
				}
				task.buffer.draw(tempShape, null, null, null, clipDrawing ? clipRectangle : null);
				//------------------------
				
				// report progress
				return task.iteration / task.recordKeys.length;
			}
			
			// report progress
			return 1; // avoids division by zero in case task.recordKeys.length == 0
		}
		
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			var graphics:Graphics = tempShape.graphics;

			// project data coordinates to screen coordinates and draw graphics onto tempShape
			var i:int;
			var _shapeSize:Number = this.shapeSize.value;
			var _prevX:Number = 0;
			var _prevY:Number = 0;
			var continueLine:Boolean = false;
			var skipLines:Boolean = enableGroupBy.value && groupBy.containsKey(recordKey);
			
			for (i = 0; i < _yColumns.length; i++)
			{
				// project data coordinates to screen coordinates and draw graphics
				
				getCoords(recordKey, i, tempPoint);
				
				if (!isFinite(tempPoint.x) || !isFinite(tempPoint.y))
				{
					continueLine = false;
					continue;
				}
				
				dataBounds.projectPointTo(tempPoint, screenBounds);				
				var x:Number = tempPoint.x;
				var y:Number = tempPoint.y;
				
				var recordColor:Number = lineStyle.color.getValueFromKey(recordKey, Number);
				
				// thickness of the line around each shape
				var shapeLineThickness:int = shapeBorderThickness.value;
				// use a border around each shape
				graphics.lineStyle(shapeLineThickness, shapeBorderColor.value, shapeLineThickness == 0 ? 0 : shapeBorderAlpha.value);
				if (_shapeSize > 0)
				{
					var shapeSize:Number = _shapeSize;
					
					var shapeColor:Number = recordColor;
					if (isNaN(shapeColor) && enableGroupBy.value)
					{
						var shapeKey:IQualifiedKey = (_yColumns[i] as IAttributeColumn).getValueFromKey(recordKey, IQualifiedKey);
						shapeColor = lineStyle.color.getValueFromKey(shapeKey, Number);
					}
					// draw a different shape for each option
					switch (shapeToDraw.value)
					{
						// solid circle
						case SOLID_CIRCLE:
							if (isFinite(shapeColor))
								graphics.beginFill(shapeColor);
							else
								graphics.endFill();
							// circle uses radius, so size/2
							graphics.drawCircle(x, y, shapeSize/2);
							break;
						// empty circle
						case EMPTY_CIRCLE:
							graphics.lineStyle(shapeLineThickness, shapeColor, shapeLineThickness == 0 ? 0 : 1);
							graphics.drawCircle(x, y, shapeSize/2);
							break;
						// solid square
						case SOLID_SQUARE:
							if (isFinite(shapeColor))
								graphics.beginFill(shapeColor);
							else
								graphics.endFill();
							graphics.drawRect(x-_shapeSize/2, y-_shapeSize/2, _shapeSize, _shapeSize);
							break;
						// empty square
						case EMPTY_SQUARE:
							graphics.lineStyle(shapeLineThickness, shapeColor, shapeLineThickness == 0 ? 0 : 1);
							graphics.drawRect(x-_shapeSize/2, y-_shapeSize/2, _shapeSize, _shapeSize);
							break;
					}
					
					graphics.endFill();
				}
				
				if (skipLines)
					continue;
				
				if (isFinite(recordColor))
				{
					// begin the line style for the parallel coordinates line
					// we want to use the missing data line style since the line is the shape we are showing 
					// (rather than just a border of another shape)
					lineStyle.beginLineStyle(recordKey, graphics);
				}
				else
				{
					graphics.lineStyle(shapeLineThickness, shapeBorderColor.value, shapeLineThickness == 0 ? 0 : shapeBorderAlpha.value);
				}
				
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
			var _yColumns:Array = columns.getObjects();
			if (_yColumns.length > 0)
				return ColumnUtils.deriveStringFromNumber(_yColumns[0], value); // always use the first column to format the axis labels
			return null;
		}
		
		public function xAxisLabelFunction(value:Number):String
		{
			try
			{
				if (usingXAttributes)
					return ColumnUtils.deriveStringFromNumber(_xColumns[0], value);
				else
					return ColumnUtils.getTitle(_yColumns[value]);
			}
			catch(e:Error) { };
			
			return "";
		}
		
		public function get usingXAttributes():Boolean
		{
			if (_xColumns.length == _yColumns.length)
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
					
					if(_xColumns.length > 0)
					{
						output.setXRange(NaN,NaN);
						for each (var col:IAttributeColumn in _xColumns)
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
		
		/**
		 * Gets the coordinates for a record and column index and stores them in a Point object.
		 * @param recordKey
		 * @param columnIndex
		 * @param output
		 */
		public function getCoords(recordKey:IQualifiedKey, columnIndex:int, output:Point):void
		{
			output.x = NaN;
			output.y = NaN;
			
			if (enableGroupBy.value && groupBy.containsKey(recordKey))
			{
				if (xData.getValueFromKey(recordKey, String) != getXValues()[columnIndex])
					return;
				recordKey = WeaveAPI.QKeyManager.getQKey(getForeignKeyType(), groupBy.getValueFromKey(recordKey, String));
			}
			
			// X
			var xCol:IAttributeColumn = _xColumns[columnIndex] as IAttributeColumn;
			if (xCol)
				output.x = xCol.getValueFromKey(recordKey, Number);
			else if (_xColumns.length == 0)
				output.x = columnIndex;
			
			// Y
			var yCol:IAttributeColumn = _yColumns[columnIndex] as IAttributeColumn;
			if (yCol && normalize.value)
				output.y = WeaveAPI.StatisticsCache.getColumnStatistics(yCol).getNorm(recordKey);
			else if (yCol)
				output.y = yCol.getValueFromKey(recordKey, Number);
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
