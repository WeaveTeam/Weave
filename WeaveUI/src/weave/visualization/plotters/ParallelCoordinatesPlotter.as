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
	import flash.utils.getDefinitionByName;
	
	import mx.utils.ObjectUtil;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.setSessionState;
	import weave.api.ui.IPlotterWithGeometries;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.EquationColumn;
	import weave.data.CSVParser;
	import weave.data.KeySets.KeySet;
	import weave.primitives.SimpleGeometry;
	import weave.utils.ColumnUtils;
	import weave.utils.DrawUtils;
	import weave.utils.EquationColumnLib;
	import weave.utils.VectorUtils;
	import weave.visualization.plotters.styles.ExtendedSolidLineStyle;
	
	/**	
	 * @author heather byrne
	 * @author adufilie
	 * @author abaumann
	 */
	public class ParallelCoordinatesPlotter extends AbstractPlotter implements IPlotterWithGeometries 
	{
		public function ParallelCoordinatesPlotter()
		{
			lineStyle.color.internalDynamicColumn.requestGlobalObject(Weave.DEFAULT_COLOR_COLUMN, ColorColumn, false);
			lineStyle.weight.defaultValue.value = 1;
			lineStyle.alpha.defaultValue.value = 1.0;
			setKeySource(_combinedKeySet);
			
			zoomToSubset.value = true;
			
			// bounds need to be re-indexed when this option changes
			registerSpatialProperty(Weave.properties.enableGeometryProbing);
			
			enableGroupBy.addImmediateCallback(this, updateFilterEquationColumns);
			xData.addImmediateCallback(this, updateFilterEquationColumns);
			yData.addImmediateCallback(this, updateFilterEquationColumns);
			groupBy.addImmediateCallback(this, updateFilterEquationColumns);
			groupByValues.addImmediateCallback(this, updateFilterEquationColumns);
		}

		/*
		 * This is the line style used to draw the lines.
		 */
		public const lineStyle:ExtendedSolidLineStyle = newNonSpatialProperty(ExtendedSolidLineStyle);
		
		public function get alphaColumn():AlwaysDefinedColumn { return lineStyle.alpha; }
		
		public const columns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn), handleColumnsChange);
		
		public const enableGroupBy:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));
		public const xData:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const yData:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const groupBy:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const groupByValues:LinkableString = newSpatialProperty(LinkableString);
		
		private const _combinedKeySet:KeySet = newNonSpatialProperty(KeySet);
		
		private var _columns:Array = [];
		private function handleColumnsChange():void
		{			
			_columns = columns.getObjects();

			_combinedKeySet.delayCallbacks();
			
			if (enableGroupBy.value)
			{
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
				_combinedKeySet.replaceKeys(reverseKeys);
			}
			else
			{
				// get list of all keys in all columns
				if (_columns.length > 0)
				{
					_combinedKeySet.replaceKeys((_columns[0] as IAttributeColumn).keys);
					for (var i:int = 1; i < _columns.length; i++)
					{
						_combinedKeySet.addKeys((_columns[i] as IAttributeColumn).keys);
					}
				}
				else
					_combinedKeySet.clearKeys();
			}					
			
			// if there is only one column, push a copy of it so lines will be drawn
			if (_columns.length == 1)
				_columns.push(_columns[0]);
			
			_combinedKeySet.resumeCallbacks();
		}
					
		
		
		private function updateFilterEquationColumns():void
		{
			var str:String = groupByValues.value;
			
			// check that values list string exists
			if (!enableGroupBy.value)
			{
				return;
			}					
			
			// check for missing columns
			if (!(xData.internalColumn && yData.internalColumn && groupBy.internalColumn))
			{
				if (groupBy.internalColumn)
					columns.removeAllObjects();
				return;
			}
			
			if (!str) 
				return;
			
			// check that column keytypes are the same
			var keytypes:Array = [ColumnUtils.getKeyType(xData), ColumnUtils.getKeyType(groupBy), ColumnUtils.getKeyType(yData)];
			if (!((keytypes[0] == keytypes[1]) && (keytypes[0] == keytypes[2])))
			{
				return;
			}
			
			var values:Array = VectorUtils.flatten(WeaveAPI.CSVParser.parseCSV(str));
			
			columns.removeAllObjects();
			columns.delayCallbacks();

			var keyCol:DynamicColumn;
			var filterCol:DynamicColumn;
			var dataCol:DynamicColumn;
			
			for (var i:int = 0; i < values.length; i++)
			{
				var value:String = values[i];
				var col:EquationColumn = columns.requestObject(columns.generateUniqueName("line"), EquationColumn, false);
				col.delayCallbacks();
				col.variables.copyObject("keyCol", groupBy);
				col.variables.copyObject("filterCol", xData);
				col.variables.copyObject("dataCol", yData);
				
				col.setMetadata(AttributeColumnMetadata.TITLE, value);
				col.setMetadata(AttributeColumnMetadata.MIN, '{ getMin(dataCol) }');
				col.setMetadata(AttributeColumnMetadata.MAX, '{ getMax(dataCol) }');
				
				col.equation.value = 'getValueFromFilterColumn(keyCol, filterCol, dataCol, "'+value+'", Number)';
				col.resumeCallbacks();
			}				
			
			columns.resumeCallbacks();
			
		}		
		
		public const normalize:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(true));
		public const curveType:LinkableString = registerNonSpatialProperty(new LinkableString(CURVE_NONE, curveTypeVerifier));
		public const shapeSize:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(5));
		public const zoomToSubset:LinkableBoolean = newSpatialProperty(LinkableBoolean);

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
		
		public const shapeToDraw:LinkableString = registerNonSpatialProperty(new LinkableString(SOLID_CIRCLE, shapeTypeVerifier));
		public const shapeBorderThickness:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(0));
		public const shapeBorderColor:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(0x000000));
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var results:Array = [];
			var i:int;
			var _normalize:Boolean = normalize.value;
			for (i = 0; i < _columns.length; ++i)
			{
				var x:Number;
				var y:Number;
				
				x = i;
				if (_normalize)
					y = ColumnUtils.getNorm(_columns[i], recordKey);
				else
					y = (_columns[i] as IAttributeColumn).getValueFromKey(recordKey, Number);
				
				// Disable geometry probing when we're in parallel coordinates (normalize) mode
				// because line segment intersection means nothing in parallel coordinates.
				if (Weave.properties.enableGeometryProbing.value && !_normalize)
				{
					if (i < _columns.length - 1)
					{
						// include a bounds for the line segment
						var bounds:IBounds2D = getReusableBounds(x, y, x, y);
						if (_normalize)
							y = ColumnUtils.getNorm(_columns[i+1], recordKey);
						else
							y = (_columns[i+1] as IAttributeColumn).getValueFromKey(recordKey, Number);
						bounds.includeCoords(x + 1, y);
						
						results.push(bounds);
					}
				}
				else
				{
					// include a bounds for the point on the axis
					results.push(getReusableBounds(x, y, x, y));
				}
			}
				
			return results;
		}
		
		public function getGeometriesFromRecordKey(recordKey:IQualifiedKey, minImportance:Number = 0, bounds:IBounds2D = null):Array
		{
			var results:Array = [];
			var _normalize:Boolean = normalize.value;
			
			// push three geometries between each column
			var x:Number, y:Number;
			var prevX:Number, prevY:Number;
			for (var i:int = 0; i < _columns.length; ++i)
			{
				x = i;
				if (_normalize)
					y = ColumnUtils.getNorm(_columns[i], recordKey);
				else
					y = (_columns[i] as IAttributeColumn).getValueFromKey(recordKey, Number);
				
				if (i > 0)
				{
					var geometry:SimpleGeometry = new SimpleGeometry(SimpleGeometry.LINE);
					geometry.setVertices([new Point(prevX, prevY), new Point(x, y)]);
					results.push(geometry);
				}
				
				prevX = x;
				prevY = y;
			}

			return results;
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
				tempPoint.x = i;
				if (_normalize)
					tempPoint.y = ColumnUtils.getNorm(_columns[i], recordKey);
				else
					tempPoint.y = (_columns[i] as IAttributeColumn).getValueFromKey(recordKey, Number);
				
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
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			// normalized data coordinates
			var bounds:IBounds2D = getReusableBounds();
			if (!zoomToSubset.value)
			{
				bounds.setBounds(0, 0, Math.max(1, columns.getNames().length - 1), 1);
				
				if (!normalize.value)
				{
					// reset y coords
					bounds.setYRange(NaN, NaN);
					for each (var column:IAttributeColumn in columns.getObjects())
					{
						// expand y range to include all data coordinates
						bounds.includeCoords(0, WeaveAPI.StatisticsCache.getMin(column));
						bounds.includeCoords(0, WeaveAPI.StatisticsCache.getMax(column));
					}
				}
			}
			return bounds;
		}
		
		private static const tempPoint:Point = new Point(); // reusable object
		
		
		
		// backwards compatibility
		[Deprecated(replacement="enableGroupBy")] public function set displayFilterColumn(value:Object):void { setSessionState(enableGroupBy, value); }
		[Deprecated(replacement="xData")] public function set filterColumn(value:Object):void { setSessionState(xData, value); }
		[Deprecated(replacement="groupBy")] public function set keyColumn(value:Object):void { setSessionState(groupBy, value); }
		[Deprecated(replacement="groupByValues")] public function set filterValues(value:Object):void { setSessionState(groupByValues, value); }
	}
}
