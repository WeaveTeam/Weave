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
	import flash.net.getClassByAlias;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.SessionManager;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.SortedIndexColumn;
	import weave.primitives.Bounds2D;
	import weave.primitives.ColorRamp;
	import weave.primitives.Range;
	import weave.utils.BitmapText;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * CompoundBarChartPlotter
	 * 
	 * @author adufilie
	 * @author ckellehe
	 */
	public class CompoundBarChartPlotter extends AbstractPlotter
	{
		public function CompoundBarChartPlotter()
		{
			init();
		}
		private function init():void
		{
			colorColumn.internalDynamicColumn.requestGlobalObject(Weave.DEFAULT_COLOR_COLUMN, ColorColumn, false);
			
			// get the keys from the sort column
			setKeySource(sortColumn);
			
			// Link the subset key filter to the filter of the private _filteredSortColumn.
			// This is so the records will be filtered before they are sorted in the _sortColumn.
			linkSessionState(_filteredKeySet.keyFilter, _filteredSortColumn.filter);
			
			horizontalMode.value = false;
			showValueLabels.value = false;
			groupMode.value = false;
			barSpacing.value = 0;
			zoomToSubset.value = true;
			
			heightColumns.addGroupedCallback(this, defineSortColumnIfUndefined);
			registerNonSpatialProperty(colorColumn);
			registerSpatialProperty(sortColumn);
			
			registerNonSpatialProperties(
				Weave.properties.axisFontSize,
				Weave.properties.axisFontColor
			);
		}
		
		/**
		 * This is the line style used to draw the outline of the rectangle.
		 */
		public const lineStyle:DynamicLineStyle = registerNonSpatialProperty(new DynamicLineStyle(SolidLineStyle));
		public function get colorColumn():AlwaysDefinedColumn { return fillStyle.color; }
		// for now it is a solid fill style -- needs to be updated to be dynamic fill style later
		private const fillStyle:SolidFillStyle = newDisposableChild(this, SolidFillStyle);
		
		private var _sortedIndexColumn:SortedIndexColumn = newDisposableChild(this, SortedIndexColumn); // this sorts the records
		private var _filteredSortColumn:FilteredColumn = _sortedIndexColumn.requestLocalObject(FilteredColumn, true); // filters before sorting
		public const positiveError:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const negativeError:DynamicColumn = newSpatialProperty(DynamicColumn);
		public function get sortColumn():DynamicColumn { return _filteredSortColumn.internalDynamicColumn; }
		
		public function getSortedKeys():Array { return _sortedIndexColumn.keys; }
		
		public const chartColors:ColorRamp = registerNonSpatialProperty(new ColorRamp(ColorRamp.getColorRampXMLByName("Doppler Radar"))); // bars get their color from here
		public const heightColumns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		
		public const horizontalMode:LinkableBoolean = newSpatialProperty(LinkableBoolean);
		public const groupMode:LinkableBoolean = newSpatialProperty(LinkableBoolean);
		public const zoomToSubset:LinkableBoolean = newSpatialProperty(LinkableBoolean);
		public const barSpacing:LinkableNumber = newSpatialProperty(LinkableNumber);
		public const showValueLabels:LinkableBoolean = newNonSpatialProperty(LinkableBoolean);
		
		private function defineSortColumnIfUndefined():void
		{
			var columns:Array = heightColumns.getObjects();
			if (sortColumn.internalColumn == null && columns.length > 0)
				sortColumn.copyLocalObject(columns[0]);
		}
		
		
		// this is a way to get the number of keys (bars or groups of bars) shown
		public function get numBarsShown():int { return _filteredKeySet.keys.length }
		
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// save local copies of these values to speed up calculations
			var _barSpacing:Number = barSpacing.value;
			var _groupMode:Boolean = groupMode.value;
			var _horizontalMode:Boolean = horizontalMode.value;
			var _heightColumns:Array = heightColumns.getObjects().reverse();
			
			
			// BEGIN template code for defining a drawPlot() function.
			//---------------------------------------------------------
			screenBounds.getRectangle(clipRectangle, true);
			clipRectangle.width++; // avoid clipping lines
			clipRectangle.height++; // avoid clipping lines
			var graphics:Graphics = tempShape.graphics;
			var count:int = 0;
			graphics.clear();
			for (var iRecord:int = 0; iRecord < recordKeys.length; iRecord++)
			{
				var recordKey:IQualifiedKey = recordKeys[iRecord] as IQualifiedKey;
				
				//------------------------------------
				// BEGIN code to draw one compound bar
				//------------------------------------
				
				var sortedIndex:int = _sortedIndexColumn.getValueFromKey(recordKey, Number);
				
				// x coordinates depend on sorted index
				var xMin:Number = sortedIndex;
				var xMax:Number = xMin + 1;
				
				// y coordinates depend on height columns
				var yMin:Number = 0; // start first bar at zero
				var yMax:Number = 0;
				var yNegativeMin:Number = 0;
				var yNegativeMax:Number = 0;
				// constrain the spacing to be between 0 and 0.5
				var spacing:Number = 0.5 * Math.min(1.0, Math.max(0.0, _barSpacing) );
				var halfSpacing:Number = spacing/2;
				var numHeightColumns:int = _heightColumns.length;
				
				var groupedBarWidth:Number = (xMax - xMin - halfSpacing*2)/(numHeightColumns);
				
				// loop over height columns, incrementing y coordinates
				for (var i:int = 0; i < _heightColumns.length; i++)
				{
					var heightColumn:IAttributeColumn = _heightColumns[i] as IAttributeColumn;
					// add this height to the current bar
					var height:Number = heightColumn.getValueFromKey(recordKey, Number);
					var heightMissing:Boolean = isNaN(height);
					
					if (heightMissing)
						height = WeaveAPI.StatisticsCache.getMean(heightColumn);
					if (isNaN(height))
						height = 0;
					// avoid adding NaN to y coordinate (because result will be NaN).
					if (height >= 0)
					{
						yMax = yMin + height;
					}
					else
					{
						yNegativeMax = yNegativeMin + height;
					}
					var halfXRange:Number = (xMax - xMin) / 2;
					var halfColumnWidth:Number = (_heightColumns.length - 1) / 2;
					
					if (!heightMissing)
					{
						// bar starts at bar center - half width of the bar, plus the spacing between this and previous bar
						var barStart:Number = xMin + halfSpacing - halfXRange;
						if (_groupMode)
							barStart = xMin + (i - halfColumnWidth) * groupedBarWidth - groupedBarWidth / 2;
						
						if ( height >= 0)
						{
							// project data coordinates to screen coordinates
							if (_horizontalMode)
							{
								tempPoint.x = yMin; // swapped
								tempPoint.y = barStart;
							}
							else
							{
								tempPoint.x = barStart;
								tempPoint.y = yMin;
							}
						}
						else
						{
							if (_horizontalMode)
							{
								tempPoint.x = yNegativeMax; // swapped
								tempPoint.y = barStart;
							}
							else
							{
								tempPoint.x = barStart;
								tempPoint.y = yNegativeMax;
							}
						}
						// bar ends at bar center + half width of the bar, less the spacing between this and next bar
						var barEnd:Number = xMin - halfSpacing + halfXRange;
						if (_groupMode)
							barEnd = xMin + (i+1 - halfColumnWidth) * groupedBarWidth - groupedBarWidth / 2;
						
						dataBounds.projectPointTo(tempPoint, screenBounds);
						tempBounds.setMinPoint(tempPoint);
						
						if(height >= 0)
						{
							if (_horizontalMode)
							{
								tempPoint.x = yMax; // swapped
								tempPoint.y = barEnd;
							}
							else
							{
								tempPoint.x = barEnd;
								tempPoint.y = yMax;
							}
						}
						else
						{
							
							if (_horizontalMode)
							{
								tempPoint.x = yNegativeMin; // swapped
								tempPoint.y = barEnd;
							}
							else
							{
								tempPoint.x = barEnd;
								tempPoint.y = yNegativeMin;
							}
						}
						dataBounds.projectPointTo(tempPoint, screenBounds);
						tempBounds.setMaxPoint(tempPoint);
						
						// draw graphics
						var color:Number = chartColors.getColorFromNorm(i / (_heightColumns.length - 1));
						
						// if there is one column, act like a regular bar chart and color in with a chosen color
						if (_heightColumns.length == 1)
							fillStyle.beginFillStyle(recordKey, graphics);
							// otherwise use a pre-defined set of colors for each bar segment
						else
							graphics.beginFill(color, 1);
						
						
						lineStyle.beginLineStyle(recordKey, graphics);
						if(tempBounds.getHeight() == 0)
							graphics.lineStyle(0,0,0);
						
						graphics.drawRect(tempBounds.getXMin(), tempBounds.getYMin(), tempBounds.getWidth(), tempBounds.getHeight());
						
						graphics.endFill();
					}						
					
					if (!_groupMode)
					{
						// the next bar starts on top of this bar
						if (height >= 0)
							yMin = yMax;
						else
							yNegativeMin = yNegativeMax;
					}
					
					//------------------------------------
					// BEGIN code to draw one bar value label
					//------------------------------------
					if (showValueLabels.value && ((_heightColumns.length >= 1 && _groupMode) || _heightColumns.length == 1))
					{
						if (height != 0)
						{
							_bitmapText.text = heightColumn.getValueFromKey(recordKey, Number);;
							_bitmapText.textFormat.color = Weave.properties.axisFontColor.value;
							_bitmapText.textFormat.size = Weave.properties.axisFontSize.value;
							_bitmapText.textFormat.underline = Weave.properties.axisFontUnderline.value;
							if (!_horizontalMode)
							{
								_tempPoint.x = (barStart + barEnd) / 2;
								if (height >= 0)
								{
									_tempPoint.y = yMax;
									_bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_LEFT;
								}
								else
								{
									_tempPoint.y = yNegativeMax;
									_bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_RIGHT;
								}
								_bitmapText.angle = 270;
								_bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER;
							}
							else
							{
								_tempPoint.y = (barStart + barEnd) / 2;
								if (height >= 0)
								{
									_tempPoint.x = yMax;
									_bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_LEFT;
								}
								else
								{
									_tempPoint.x = yNegativeMax;
									_bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_RIGHT;
								}
								_bitmapText.angle = 0;
								_bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER;
							}
							dataBounds.projectPointTo(_tempPoint, screenBounds);
							_bitmapText.textFormat.size = Weave.properties.axisFontSize.value;
							_bitmapText.textFormat.color = Weave.properties.axisFontColor.value;
							_bitmapText.x = _tempPoint.x;
							_bitmapText.y = _tempPoint.y;
							_bitmapText.draw(destination);
						}
					}
					//------------------------------------
					// END code to draw one bar value label
					//------------------------------------
					
				}
				//------------------------------------
				// END code to draw one compound bar
				//------------------------------------
				
				//------------------------------------
				// BEGIN code to draw one error bar
				//------------------------------------
				if (_heightColumns.length == 1 && this.positiveError.internalColumn != null)
				{
					var errorPlusVal:Number = this.positiveError.getValueFromKey( recordKey, Number);
					var errorMinusVal:Number;
					if (this.negativeError.internalColumn != null)
					{
						errorMinusVal = this.negativeError.getValueFromKey( recordKey , Number);
					}
					else
					{
						errorMinusVal = errorPlusVal;
					}
					if (isFinite(errorPlusVal) && isFinite(errorMinusVal))
					{
						var center:Number = (barStart + barEnd) / 2;
						var width:Number = barEnd - barStart; 
						var left:Number = center - width / 4;
						var right:Number = center + width / 4;
						var top:Number, bottom:Number;
						if (height >= 0)
						{
							top = yMax + errorPlusVal;
							bottom = yMax - errorMinusVal;
						}
						else
						{
							top = yNegativeMax + errorPlusVal;
							bottom = yNegativeMax - errorMinusVal;
						}
						if (top != bottom)
						{
							var coords:Array = []; // each pair of 4 numbers represents a line segment to draw
							if (!_horizontalMode)
							{
								coords.push(left, top, right, top);
								coords.push(center, top, center, bottom);
								coords.push(left, bottom, right, bottom);
							}
							else
							{
								coords.push(top, left, top, right);
								coords.push(top, center, bottom, center);
								coords.push(bottom, left, bottom, right);
							}
							
							for (i = 0; i < coords.length; i += 2) // loop over x,y coordinate pairs
							{
								tempPoint.x = coords[i];
								tempPoint.y = coords[i + 1];
								dataBounds.projectPointTo(tempPoint, screenBounds);
								if (i % 4 == 0) // every other pair
									graphics.moveTo(tempPoint.x, tempPoint.y);
								else
									graphics.lineTo(tempPoint.x, tempPoint.y);
							}
						}
					}
				}
				//------------------------------------
				// END code to draw one error bar
				//------------------------------------
				
				// If the recordsPerDraw count has been reached, flush the tempShape "buffer" onto the destination BitmapData.
				if (++count > AbstractPlotter.recordsPerDraw)
				{
					destination.draw(tempShape, null, null, null, clipRectangle);
					graphics.clear();
					count = 0;
				}
			}
			// flush the tempShape buffer
			if (count > 0)
				destination.draw(tempShape, null, null, null, clipRectangle);
			
			//---------------------------------------------------------
			// END template code
		}
		
		private const _bitmapText:BitmapText = new BitmapText();
		private const _tempPoint:Point = new Point();
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var errorBounds:IBounds2D = getReusableBounds(); // the bounds of key + error bars
			var keyBounds:IBounds2D = getReusableBounds(); // the bounds of just the key
			var _groupMode:Boolean = groupMode.value;
			var errorColumnsIncluded:Boolean = false; // are error columns the i = 1 and i=2 columns in height columns?
			
			// bar position depends on sorted index
			var sortedIndex:int = _sortedIndexColumn.getValueFromKey(recordKey, Number);
			var minPos:Number = sortedIndex - 0.5;
			var maxPos:Number = minPos + 1;
			// this bar is between minPos and maxPos in the x or y range
			if (horizontalMode.value)
				keyBounds.setYRange(minPos, maxPos);
			else
				keyBounds.setXRange(minPos, maxPos);
			
			var _heightColumns:Array = heightColumns.getObjects();
			if (_heightColumns.length == 1)
			{
				_heightColumns.push(positiveError);
				_heightColumns.push(negativeError);
				errorColumnsIncluded = true; 
			}
			
			tempRange.setRange(0, 0); // bar starts at zero
			
			// loop over height columns, incrementing y coordinates
			for (var i:int = 0; i < _heightColumns.length; i++)
			{
				var heightColumn:IAttributeColumn = _heightColumns[i] as IAttributeColumn;
				var height:Number = heightColumn.getValueFromKey(recordKey, Number);

				if (heightColumn == positiveError)
				{
					if (tempRange.end == 0)
						continue;
				}
				if (heightColumn == negativeError)
				{
					if (isNaN(height))
						height = positiveError.getValueFromKey(recordKey, Number);
					if (tempRange.begin < 0)
						height = -height;
					else
						continue;
				}
				
				if (isNaN(height))
					height = WeaveAPI.StatisticsCache.getMean(heightColumn);
				if (isNaN(height))
					height = 0;
				if (_groupMode)
				{
					tempRange.includeInRange(height);
				}
				else
				{
					// add this height to the current bar, so add to y value
					// avoid adding NaN to y coordinate (because result will be NaN).
					if (isFinite(height))
					{
						if (height >= 0)
							tempRange.end += height;
						else
							tempRange.begin += height;
					}
				}
				
				// if there are no error columns in _heightColumns, 
				// or if there are error columns (which occurs only if there is one height column),
				// we want to include the current range in keyBounds
				if (!errorColumnsIncluded || i == 0) 
				{
					if (horizontalMode.value)
						keyBounds.setXRange(tempRange.begin, tempRange.end);
					else
						keyBounds.setYRange(tempRange.begin, tempRange.end);
				}
			}
			
			if (horizontalMode.value)
				errorBounds.setBounds(tempRange.begin, minPos, tempRange.end, maxPos); // x,y swapped
			else
				errorBounds.setBounds(minPos, tempRange.begin, maxPos, tempRange.end);
			
			return [keyBounds, errorBounds];
		}
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			var bounds:IBounds2D = getReusableBounds();
			if (!zoomToSubset.value)
			{
				tempRange.setRange(0, 0);
				var _heightColumns:Array = heightColumns.getObjects();
				for each (var column:IAttributeColumn in _heightColumns)
				{
					if (groupMode.value)
					{
						tempRange.includeInRange(WeaveAPI.StatisticsCache.getMin(column));
						tempRange.includeInRange(WeaveAPI.StatisticsCache.getMax(column));
					}
					else
					{
						var max:Number = WeaveAPI.StatisticsCache.getMax(column);
						var min:Number = WeaveAPI.StatisticsCache.getMin(column);
						if (_heightColumns.length == 1)
						{
							var errorMax:Number = WeaveAPI.StatisticsCache.getMax(positiveError);
							var errorMin:Number = -WeaveAPI.StatisticsCache.getMax(negativeError);
							if (isNaN(errorMin))
								errorMin = errorMax;
							if (max > 0 && errorMax > 0)
								max += errorMax;
							if (min < 0 && errorMin > 0)
								min -= errorMin;
						}
						if (max > 0)
							tempRange.end += max;
						if (min < 0)
							tempRange.begin += min;
					}
				}
				
				if (horizontalMode.value) // x range
					bounds.setBounds(tempRange.begin, NaN, tempRange.end, NaN);
				else // y range
					bounds.setBounds(NaN, tempRange.begin, NaN, tempRange.end);
			}
			return bounds;
		}
		
		private const tempRange:Range = new Range(); // reusable temporary object
		private const tempPoint:Point = new Point(); // reusable temporary object
		private const tempBounds:IBounds2D = new Bounds2D(); // reusable temporary object
	}
}
