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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IQualifiedKey;
	import weave.api.detectLinkableObjectChange;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotTask;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableFunction;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.AttributeColumns.SortedIndexColumn;
	import weave.data.BinningDefinitions.CategoryBinningDefinition;
	import weave.primitives.Bounds2D;
	import weave.primitives.ColorRamp;
	import weave.primitives.Range;
	import weave.utils.AsyncSort;
	import weave.utils.BitmapText;
	import weave.utils.ColumnUtils;
	import weave.utils.LinkableTextFormat;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * CompoundBarChartPlotter
	 * 
	 * @author adufilie
	 * @author kmanohar
	 */
	public class CompoundBarChartPlotter extends AbstractPlotter
	{
		public function CompoundBarChartPlotter()
		{
			colorColumn.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;

			// get the keys from the sort column
			setKeySource(sortColumn);
			
			// Link the subset key filter to the filter of the private _filteredSortColumn.
			// This is so the records will be filtered before they are sorted in the _sortColumn.
			linkSessionState(_filteredKeySet.keyFilter, _filteredSortColumn.filter);
			
			heightColumns.addGroupedCallback(this, heightColumnsGroupCallback);
			registerSpatialProperty(sortColumn);
			registerSpatialProperty(colorColumn); // because color is used for sorting
			registerLinkableChild(this, LinkableTextFormat.defaultTextFormat); // redraw when text format changes
			
			_binnedSortColumn.binningDefinition.requestLocalObject(CategoryBinningDefinition, true); // creates one bin per unique value in the sort column
			
			heightColumns.childListCallbacks.addImmediateCallback(this, handleColumnsListChange);
		}
		private function handleColumnsListChange():void
		{
			// When a new column is created, register the stats to trigger callbacks and affect busy status.
			// This will be cleaned up automatically when the column is disposed.
			var newColumn:IAttributeColumn = heightColumns.childListCallbacks.lastObjectAdded as IAttributeColumn;
			if (newColumn)
				registerSpatialProperty(WeaveAPI.StatisticsCache.getColumnStatistics(newColumn));
		}
		
		/**
		 * This is the line style used to draw the outline of the rectangle.
		 */
		public const lineStyle:DynamicLineStyle = registerLinkableChild(this, new DynamicLineStyle(SolidLineStyle));
		public function get colorColumn():AlwaysDefinedColumn { return fillStyle.color; }
		private const fillStyle:SolidFillStyle = newDisposableChild(this, SolidFillStyle);
		
		public const groupBySortColumn:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false)); // when this is true, we use _binnedSortColumn
		private const _binnedSortColumn:BinnedColumn = newSpatialProperty(BinnedColumn); // only used when groupBySortColumn is true
		private const _sortedIndexColumn:SortedIndexColumn = _binnedSortColumn.internalDynamicColumn.requestLocalObject(SortedIndexColumn, true); // this sorts the records
		private const _filteredSortColumn:FilteredColumn = _sortedIndexColumn.requestLocalObject(FilteredColumn, true); // filters before sorting
		public function get sortColumn():DynamicColumn { return _filteredSortColumn.internalDynamicColumn; }
		public const labelColumn:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const stackedMissingDataGap:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(true));
		
		private var _sortByColor:Function;
		
		public function sortAxisLabelFunction(value:Number):String
		{
			if (groupBySortColumn.value)
				return _binnedSortColumn.deriveStringFromNumber(value);
			
			// get the sorted keys
			var sortedKeys:Array = _sortedIndexColumn.keys;
			
			// cast the input value from the axis to an int (not ideal at all, need to make this more robust)
			var sortedKeyIndex:int = int(value);
			
			// if this key is out of range, we have a problem
			if (sortedKeyIndex < 0 || sortedKeyIndex > sortedKeys.length-1)
				return "Invalid tick mark value: "+value.toString();
			
			// if the labelColumn doesn't have any data, use default label
			if (labelColumn.getInternalColumn() == null)
				return null;
			
			// otherwise return the value from the labelColumn
			return labelColumn.getValueFromKey(sortedKeys[sortedKeyIndex], String);
		}
		
		public const chartColors:ColorRamp = registerLinkableChild(this, new ColorRamp(ColorRamp.getColorRampXMLByName("Doppler Radar"))); // bars get their color from here

		public const showValueLabels:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const valueLabelDataCoordinate:LinkableNumber = registerLinkableChild(this, new LinkableNumber(NaN));
		public const valueLabelHorizontalAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.HORIZONTAL_ALIGN_LEFT));
		public const valueLabelVerticalAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.VERTICAL_ALIGN_MIDDLE));
		public const valueLabelRelativeAngle:LinkableNumber = registerLinkableChild(this, new LinkableNumber(NaN));		
		public const valueLabelColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0));
		public const valueLabelMaxWidth:LinkableNumber = registerLinkableChild(this, new LinkableNumber(200, verifyLabelMaxWidth));
		public const recordValueLabelColoring:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		public const showLabels:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const labelFormatter:LinkableFunction = registerLinkableChild(this, new LinkableFunction('string', true, false, ['string']));
		public const labelDataCoordinate:LinkableNumber = registerLinkableChild(this, new LinkableNumber(NaN));
		public const labelHorizontalAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.HORIZONTAL_ALIGN_RIGHT));
		public const labelVerticalAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.VERTICAL_ALIGN_MIDDLE));
		public const labelRelativeAngle:LinkableNumber = registerLinkableChild(this, new LinkableNumber(NaN));		
		public const labelColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0));
		public const labelMaxWidth:LinkableNumber = registerLinkableChild(this, new LinkableNumber(200, verifyLabelMaxWidth));
		public const recordLabelColoring:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		public const heightColumns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		public const positiveErrorColumns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		public const negativeErrorColumns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		public const horizontalMode:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));
		public const zoomToSubset:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(true));
		public const zoomToSubsetBars:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));
		public const barSpacing:LinkableNumber = registerSpatialProperty(new LinkableNumber(0));
		public const groupingMode:LinkableString = registerSpatialProperty(new LinkableString(STACK, verifyGroupingMode));
		public static const GROUP:String = 'group';
		public static const STACK:String = 'stack';
		public static const PERCENT_STACK:String = 'percentStack';
		private function verifyGroupingMode(mode:String):Boolean
		{
			return [GROUP, STACK, PERCENT_STACK].indexOf(mode) >= 0;
		}
		private function verifyLabelMaxWidth(value:Number):Boolean
		{
			return value > 0;
		}
		
		private function heightColumnsGroupCallback():void
		{
			if (!sortColumn.getInternalColumn())
			{
				var columns:Array = heightColumns.getObjects();
				if (columns.length)
					sortColumn.requestLocalObjectCopy(columns[0]);
			}
		}
		
		// this is a way to get the number of keys (bars or groups of bars) shown
		public function get maxTickMarks():int
		{
			if (groupBySortColumn.value)
				return _binnedSortColumn.numberOfBins;
			return _filteredKeySet.keys.length;
		}
		
		private function sortBins():void
		{
			if (!groupBySortColumn.value)
				return;
			var colorChanged:Boolean = detectLinkableObjectChange(sortBins, colorColumn);
			var binsChanged:Boolean = detectLinkableObjectChange(sortBins, _binnedSortColumn);
			
			if (colorChanged)
			{
				// find internal color column, then use its internal column
				var column:IAttributeColumn = colorColumn;
				while (column)
				{
					if (column is ColorColumn)
					{
						column = (column as ColorColumn).internalDynamicColumn;
						break;
					}
					if (column is IColumnWrapper)
						column = (column as IColumnWrapper).getInternalColumn();
				}
				_sortByColor = ColumnUtils.generateCompareFunction([column]);
			}
			
			if (colorChanged || binsChanged)
			{
				for (var i:int = 0; i < _binnedSortColumn.numberOfBins; i++)
					AsyncSort.sortImmediately(_binnedSortColumn.getKeysFromBinIndex(i), _sortByColor);
			}
		}
				
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			if (!(task.asyncState is Function))
			{
				// these variables are used to save state between function calls
				var _barSpacing:Number;
				var _heightColumns:Array;
				var _posErrCols:Array;
				var _negErrCols:Array;
				var _groupingMode:String;
				var _horizontalMode:Boolean;
				var _groupBySortColumn:Boolean;
				var reverseOrder:Boolean;
				var showErrorBars:Boolean;
				var clipRectangle:Rectangle = new Rectangle();
				var graphics:Graphics = tempShape.graphics;
				var count:int;
				var numHeightColumns:int;
				var shouldDrawValueLabel:Boolean;
				var shouldDrawLabel:Boolean;
				
				task.asyncState = function():Number
				{
					if (task.iteration == 0)
					{
						// save local copies of these values to speed up calculations
						_barSpacing = barSpacing.value;
						_heightColumns = heightColumns.getObjects();
						_posErrCols = positiveErrorColumns.getObjects();
						_negErrCols = negativeErrorColumns.getObjects();
						_groupingMode = getActualGroupingMode();
						_horizontalMode = horizontalMode.value;
						_groupBySortColumn = groupBySortColumn.value;
						reverseOrder = (_horizontalMode == (_groupingMode == GROUP));
						if (reverseOrder)
						{
							_heightColumns.reverse();
							_posErrCols.reverse();
							_negErrCols.reverse();
						}
						sortBins(); // make sure group-by-sort will work properly
						
						showErrorBars = _groupingMode == GROUP || _heightColumns.length == 1;
						
						LinkableTextFormat.defaultTextFormat.copyTo(_bitmapText.textFormat);
						
						// BEGIN template code for defining a drawPlot() function.
						//---------------------------------------------------------
						task.screenBounds.getRectangle(clipRectangle, true);
						clipRectangle.width++; // avoid clipping lines
						clipRectangle.height++; // avoid clipping lines
						count = 0;
						numHeightColumns = _heightColumns.length;
						shouldDrawValueLabel = showValueLabels.value;
						shouldDrawLabel = showLabels.value && (numHeightColumns >= 1) && (labelColumn.getInternalColumn() || _groupingMode == GROUP);
					}
					
					if (task.iteration < task.recordKeys.length)
					{
						var recordKey:IQualifiedKey = task.recordKeys[task.iteration] as IQualifiedKey;
						
						//-------------------------------
						// BEGIN code to draw one record
						//-------------------------------
						graphics.clear();
						
						// y coordinates depend on height columns
						var yMin:Number = 0; // start first bar at zero
						var yMax:Number = 0;
						var yNegativeMin:Number = 0;
						var yNegativeMax:Number = 0;
						
						// x coordinates depend on sorted index
						var sortedIndex:Number;
						if (_groupBySortColumn)
							sortedIndex = _binnedSortColumn.getValueFromKey(recordKey, Number);
						else
							sortedIndex = _sortedIndexColumn.getValueFromKey(recordKey, Number);
						
						var spacing:Number = StandardLib.constrain(_barSpacing, 0, 1) / 2; // max distance between bar groups is 0.5 in data coordinates
						var xMin:Number = sortedIndex - (0.5 - spacing / 2);
						var xMax:Number = sortedIndex + (0.5 - spacing / 2);
						
						var recordWidth:Number = xMax - xMin;
						var barWidth:Number = _groupingMode == GROUP ? recordWidth / numHeightColumns : recordWidth;
						if (_groupBySortColumn)
						{
							var keysInBin:Array = _binnedSortColumn.getKeysFromBinIndex(sortedIndex); // already sorted
							if (keysInBin)
							{
								var index:int = keysInBin.indexOf(recordKey);
								recordWidth /= keysInBin.length;
								barWidth /= keysInBin.length;
								xMin += index * recordWidth;
								xMax = xMin + recordWidth;
							}
						}
						
						var totalHeight:Number = 0;
						for (var hCount:int = 0; hCount < _heightColumns.length; hCount++)
						{
							var column:IAttributeColumn = _heightColumns[hCount] as IAttributeColumn;
							var h:Number = column.getValueFromKey(recordKey, Number);
							
							if (isNaN(h))
								continue;
							
							totalHeight = totalHeight + h;
						}
						
						// loop over height columns, incrementing y coordinates
						for (var i:int = 0; i < _heightColumns.length; i++)
						{
							//------------------------------------
							// BEGIN code to draw one bar segment
							//------------------------------------
							var heightColumn:IAttributeColumn = _heightColumns[i] as IAttributeColumn;
							// add this height to the current bar
							var height:Number = heightColumn.getValueFromKey(recordKey, Number);
							var heightMissing:Boolean = isNaN(height);
							if (heightMissing)
							{
								// if height is missing, use mean value unless we're in 100% stacked mode
								if (stackedMissingDataGap.value && _groupingMode != PERCENT_STACK)
									height = WeaveAPI.StatisticsCache.getColumnStatistics(heightColumn).getMean();
							}
							if (isNaN(height)) // check again because getMean may return NaN
								height = 0;
							
							if (height >= 0)
							{
								//normalizing to 100% stack
								if (_groupingMode == PERCENT_STACK && totalHeight)
									yMax = yMin + (100 / totalHeight * height);
								else
									yMax = yMin + height;
							}
							else
							{
								if (_groupingMode == PERCENT_STACK && totalHeight)
									yNegativeMax = yNegativeMin + (100 / totalHeight * height);
								else
									yNegativeMax = yNegativeMin + height;
							}
							
							if (!heightMissing)
							{
								// draw graphics
								
								var barStart:Number = xMin;
								if (_groupingMode == GROUP)
									barStart += i / numHeightColumns * recordWidth;
								var barEnd:Number = barStart + barWidth;
								
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
								tempBounds.setMinPoint(tempPoint);
								
								if (height >= 0)
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
								tempBounds.setMaxPoint(tempPoint);
								
								task.dataBounds.projectCoordsTo(tempBounds, task.screenBounds);
								
								//////////////////////////
								// BEGIN draw graphics
								//////////////////////////
								graphics.clear();
								
								var colorNorm:Number = i / (_heightColumns.length - 1);
								if (reverseOrder)
									colorNorm = 1 - colorNorm;
								var color:Number = chartColors.getColorFromNorm(colorNorm);
								
								// if there is one column, act like a regular bar chart and color in with a chosen color
								if (_heightColumns.length == 1)
								{
									// this might introduce a little overhead...
									color = fillStyle.color.getValueFromKey(recordKey, Number) as Number;
									
									fillStyle.beginFillStyle(recordKey, graphics); 
								}
								else // otherwise use a pre-defined set of colors for each bar segment
									graphics.beginFill(color, 1);
								
								
								lineStyle.beginLineStyle(recordKey, graphics);
								if (tempBounds.getHeight() == 0)
									graphics.lineStyle(0,0,0);
								
								graphics.drawRect(tempBounds.getXMin(), tempBounds.getYMin(), tempBounds.getWidth(), tempBounds.getHeight());
								
								graphics.endFill();
								
								if (showErrorBars)
								{
									//------------------------------------
									// BEGIN code to draw one error bar
									//------------------------------------
									var positiveError:IAttributeColumn = _posErrCols.length > i ? _posErrCols[i] as IAttributeColumn : null;
									var negativeError:IAttributeColumn = _negErrCols.length > i ? _negErrCols[i] as IAttributeColumn : null;
									var errorPlusVal:Number = positiveError ? positiveError.getValueFromKey(recordKey, Number) : NaN;
									var errorMinusVal:Number = negativeError ? negativeError.getValueFromKey(recordKey, Number) : NaN;
									if (isFinite(errorPlusVal) && isFinite(errorMinusVal))
									{
										var center:Number = (barStart + barEnd) / 2;
										var width:Number = barEnd - barStart; 
										var left:Number = center - width / 4;
										var right:Number = center + width / 4;
										var top:Number;
										var bottom:Number;
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
											
											// BEGIN DRAW
											lineStyle.beginLineStyle(recordKey, graphics);
											for (var iCoord:int = 0; iCoord < coords.length; iCoord += 2) // loop over x,y coordinate pairs
											{
												tempPoint.x = coords[iCoord];
												tempPoint.y = coords[iCoord + 1];
												task.dataBounds.projectPointTo(tempPoint, task.screenBounds);
												if (iCoord % 4 == 0) // every other pair
													graphics.moveTo(tempPoint.x, tempPoint.y);
												else
													graphics.lineTo(tempPoint.x, tempPoint.y);
											}
											// END DRAW
										}
									}
									//------------------------------------
									// END code to draw one error bar
									//------------------------------------
								}
									
								task.buffer.draw(tempShape, null, null, null, clipRectangle);
								//////////////////////////
								// END draw graphics
								//////////////////////////
							}
							//------------------------------------
							// END code to draw one bar segment
							//------------------------------------
							
							//------------------------------------
							// BEGIN code to draw one bar value label (directly to BitmapData) 
							//------------------------------------
							if (shouldDrawValueLabel && !heightMissing)
							{
								_bitmapText.text = heightColumn.getValueFromKey(recordKey, String);
								
								var valueLabelPos:Number = valueLabelDataCoordinate.value;
								if (!isFinite(valueLabelPos))
									valueLabelPos = (height >= 0) ? yMax : yNegativeMax;
								
								// For stack and percent stack bar charts, draw value label in the middle of each segment
								if (_heightColumns.length > 1 && _groupingMode != GROUP)
								{
									if (height >= 0)
										valueLabelPos = (yMin + yMax) / 2;
									else
										valueLabelPos = (yNegativeMin + yNegativeMax) / 2;
								}
								
								if (!_horizontalMode)
								{
									tempPoint.x = (barStart + barEnd) / 2;
									tempPoint.y = valueLabelPos;
									_bitmapText.angle = 270;
								}
								else
								{
									tempPoint.x = valueLabelPos;
									tempPoint.y = (barStart + barEnd) / 2;
									_bitmapText.angle = 0;
								}
								
								task.dataBounds.projectPointTo(tempPoint, task.screenBounds);
								_bitmapText.x = tempPoint.x;
								_bitmapText.y = tempPoint.y;
								_bitmapText.maxWidth = valueLabelMaxWidth.value;
								_bitmapText.verticalAlign = valueLabelVerticalAlign.value;
								_bitmapText.horizontalAlign = valueLabelHorizontalAlign.value;
														
								if (isFinite(valueLabelRelativeAngle.value))
									_bitmapText.angle += valueLabelRelativeAngle.value;
								
								if (recordValueLabelColoring.value)
									_bitmapText.textFormat.color = color;
								else
									_bitmapText.textFormat.color = valueLabelColor.value;
								_bitmapText.draw(task.buffer);
							}
							//------------------------------------
							// END code to draw one bar value label (directly to BitmapData)
							//------------------------------------
							
							//------------------------------------
							// BEGIN code to draw one label using labelColumn (or column title if grouped)
							//------------------------------------
							// avoid drawing duplicate overlapping labels
							if (shouldDrawLabel && !heightMissing && (i == 0 || _groupingMode == GROUP))
							{
								if (_groupingMode == GROUP)
									_bitmapText.text = ColumnUtils.getTitle(heightColumn);
								else
									_bitmapText.text = labelColumn.getValueFromKey(recordKey, String);
								
								try
								{
									_bitmapText.text = labelFormatter.apply(null, [_bitmapText.text]);
								}
								catch (e:Error)
								{
									_bitmapText.text = '';
								}
		
								var labelPos:Number = labelDataCoordinate.value;
								if (_horizontalMode)
								{
									if (!(labelPos <= Infinity)) // alternative to isNaN
										labelPos = (height >= 0) ? task.dataBounds.getXMin(): task.dataBounds.getXMax();
									
									tempPoint.x = labelPos;
									tempPoint.y = (barStart + barEnd) / 2;
									_bitmapText.angle = 0;
								}
								else
								{
									if (!(labelPos <= Infinity)) // alternative to isNaN
										labelPos = (height >= 0) ? task.dataBounds.getYMin(): task.dataBounds.getYMax();
									tempPoint.x = (barStart + barEnd) / 2;
									tempPoint.y = labelPos;
									_bitmapText.angle = 270;
								}
								
								task.dataBounds.projectPointTo(tempPoint, task.screenBounds);
								_bitmapText.x = tempPoint.x;
								_bitmapText.y = tempPoint.y;
								_bitmapText.maxWidth = labelMaxWidth.value;
								if (isFinite(labelRelativeAngle.value))
									_bitmapText.angle += labelRelativeAngle.value;
								_bitmapText.verticalAlign = labelVerticalAlign.value;
								_bitmapText.horizontalAlign = labelHorizontalAlign.value;
								
								if (recordLabelColoring.value)
									_bitmapText.textFormat.color = color;
								else
									_bitmapText.textFormat.color = labelColor.value;
								
								_bitmapText.draw(task.buffer);
							}
							//------------------------------------
							// END code to draw one label using labelColumn
							//------------------------------------
		
							// update min values for next loop iteration
							if (_groupingMode != GROUP)
							{
								// the next bar starts on top of this bar
								if (height >= 0)
									yMin = yMax;
								else
									yNegativeMin = yNegativeMax;
							}
						}
						//-----------------------------
						// END code to draw one record
						//-----------------------------
						return task.iteration / task.recordKeys.length;
					}
					
					return 1; // avoids divide-by-zero when there are no record keys
				}; // end task function
			} // end if
			
			return (task.asyncState as Function).apply(this, arguments);
		}
		
		private const _bitmapText:BitmapText = new BitmapText();		
		
		/**
		 * This function takes into account whether or not there is only a single height column specified.
		 * @return The actual grouping mode, which may differ from the session state of the groupingMode variable.
		 */
		public function getActualGroupingMode():String
		{
			return heightColumns.getNames().length == 1 ? STACK : groupingMode.value;
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var bounds:IBounds2D = getReusableBounds();
			var _groupingMode:String = getActualGroupingMode();
			var _groupBySortColumn:Boolean = groupBySortColumn.value;
			var _heightColumns:Array = heightColumns.getObjects();
			var _posErrCols:Array = positiveErrorColumns.getObjects();
			var _negErrCols:Array = negativeErrorColumns.getObjects();
			_posErrCols.length = _heightColumns.length;
			_negErrCols.length = _heightColumns.length;
			var showErrorBars:Boolean = _groupingMode == GROUP || _heightColumns.length == 1;
			sortBins(); // make sure group-by-sort will work properly
			
			// bar position depends on sorted index
			var sortedIndex:Number;
			if (_groupBySortColumn)
				sortedIndex = _binnedSortColumn.getValueFromKey(recordKey, Number);
			else
				sortedIndex = _sortedIndexColumn.getValueFromKey(recordKey, Number);
			var spacing:Number = StandardLib.constrain(barSpacing.value, 0, 1) / 2; // max distance between bar groups is 0.5 in data coordinates
			var minPos:Number = sortedIndex - 0.5 + spacing / 2;
			var maxPos:Number = sortedIndex + 0.5 - spacing / 2;
			var recordWidth:Number = maxPos - minPos;
			// if grouping by sort column with more than one height column, don't attempt to separate the bounds for each record.
			if (_groupBySortColumn)
			{
				// separate the bounds for each record when grouping by sort column
				var keysInBin:Array = _binnedSortColumn.getKeysFromBinIndex(sortedIndex); // already sorted
				if (keysInBin)
				{
					var index:int = keysInBin.indexOf(recordKey);
					recordWidth /= keysInBin.length;
					minPos = minPos + index * recordWidth;
					maxPos = minPos + recordWidth;
				}
			}
			// this bar is between minPos and maxPos in the x or y range
			if (horizontalMode.value)
				bounds.setYRange(minPos, maxPos);
			else
				bounds.setXRange(minPos, maxPos);
			
			tempRange.setRange(0, 0); // bar starts at zero
			
			
			var allMissing:Boolean = true;
			for (var i:int = 0; i < _heightColumns.length; i++)
			{
				var column:IAttributeColumn = _heightColumns[i] as IAttributeColumn;
				var height:Number = column.getValueFromKey(recordKey, Number);
				if (isFinite(height))
				{
					// not all missing
					allMissing = false;
				}
				else if (_heightColumns.length > 1 && stackedMissingDataGap.value)
				{
					// use mean value for missing data gap
					height = WeaveAPI.StatisticsCache.getColumnStatistics(column).getMean();
				}

				var positiveError:IAttributeColumn = _posErrCols[i] as IAttributeColumn;
				var negativeError:IAttributeColumn = _negErrCols[i] as IAttributeColumn;
				if (showErrorBars && positiveError && negativeError)
				{
					var errorPlus:Number = positiveError.getValueFromKey(recordKey, Number);
					var errorMinus:Number = -negativeError.getValueFromKey(recordKey, Number);
					if (height > 0 && errorPlus > 0)
						height += errorPlus;
					if (height < 0 && errorMinus < 0)
						height += errorMinus;
				}
				if (_groupingMode == GROUP)
				{
					tempRange.includeInRange(height);
				}
				else
				{
					if (height > 0)
						tempRange.end += height;
					if (height < 0)
						tempRange.begin += height;
				}
			}
			
			// if max value is zero, flip direction so negative bars go downward
			if (tempRange.end == 0)
				tempRange.setRange(tempRange.end, tempRange.begin);
			
			if (allMissing)
				tempRange.setRange(NaN, NaN);
			
			if (allMissing && zoomToSubsetBars.value)
			{
				bounds.reset();
			}
			else
			{
				if (_groupingMode == PERCENT_STACK)
				{
					tempRange.begin = 0;
					tempRange.end = 100;
				}
				
				if (horizontalMode.value) // x range
					bounds.setXRange(tempRange.begin, tempRange.end);
				else // y range
					bounds.setYRange(tempRange.begin, tempRange.end);
			}
			
			return [bounds];
		}
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			var bounds:IBounds2D = getReusableBounds();
			if (!zoomToSubset.value)
			{
				tempRange.setRange(0, 0);
				var _heightColumns:Array = heightColumns.getObjects();
				var _posErrCols:Array = positiveErrorColumns.getObjects();
				var _negErrCols:Array = negativeErrorColumns.getObjects();
				_posErrCols.length = _heightColumns.length;
				_negErrCols.length = _heightColumns.length;
				var _groupingMode:String = getActualGroupingMode();
				var showErrorBars:Boolean = _groupingMode == GROUP || _heightColumns.length == 1;
				for (var i:int = 0; i < _heightColumns.length; i++)
				{
					var column:IAttributeColumn = _heightColumns[i] as IAttributeColumn;
					if (_groupingMode == PERCENT_STACK)
					{
						tempRange.begin = 0;
						tempRange.end = 100;
					}
					else
					{
						var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(column);
						var max:Number = stats.getMax();
						var min:Number = stats.getMin();
						var positiveError:IAttributeColumn = _posErrCols[i] as IAttributeColumn;
						var negativeError:IAttributeColumn = _negErrCols[i] as IAttributeColumn;
						if (showErrorBars && positiveError && negativeError)
						{
							var errorMax:Number = WeaveAPI.StatisticsCache.getColumnStatistics(positiveError).getMax();
							var errorMin:Number = -WeaveAPI.StatisticsCache.getColumnStatistics(negativeError).getMax();
							if (max > 0 && errorMax > 0)
								max += errorMax;
							if (min < 0 && errorMin < 0)
								min += errorMin;
						}
						
						if (_groupingMode == GROUP)
						{
							tempRange.includeInRange(min);
							tempRange.includeInRange(max);
						}
						else
						{
							if (max > 0)
								tempRange.end += max;
							if (min < 0)
								tempRange.begin += min;
						}
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
		
		// backwards compatibility
		[Deprecated(replacement='groupingMode')] public function set groupMode(value:Boolean):void { groupingMode.value = value ? GROUP : STACK; }
		[Deprecated(replacement="positiveErrorColumns")] public function set positiveError(dynamicState:Object):void
		{
			dynamicState.objectName = positiveErrorColumns.generateUniqueName(dynamicState.className);
			positiveErrorColumns.setSessionState([dynamicState], false);
		}
		[Deprecated(replacement="negativeErrorColumns")] public function set negativeError(dynamicState:Object):void
		{
			dynamicState.objectName = negativeErrorColumns.generateUniqueName(dynamicState.className);
			negativeErrorColumns.setSessionState([dynamicState], false);
		}
	}
}
