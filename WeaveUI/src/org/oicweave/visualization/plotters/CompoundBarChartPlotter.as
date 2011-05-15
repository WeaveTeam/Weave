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

package org.oicweave.visualization.plotters
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import org.oicweave.Weave;
	import org.oicweave.api.WeaveAPI;
	import org.oicweave.api.data.IAttributeColumn;
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.api.linkSessionState;
	import org.oicweave.api.newDisposableChild;
	import org.oicweave.api.primitives.IBounds2D;
	import org.oicweave.core.LinkableBoolean;
	import org.oicweave.core.LinkableHashMap;
	import org.oicweave.core.LinkableNumber;
	import org.oicweave.core.SessionManager;
	import org.oicweave.data.AttributeColumns.AlwaysDefinedColumn;
	import org.oicweave.data.AttributeColumns.ColorColumn;
	import org.oicweave.data.AttributeColumns.DynamicColumn;
	import org.oicweave.data.AttributeColumns.FilteredColumn;
	import org.oicweave.data.AttributeColumns.SortedIndexColumn;
	import org.oicweave.primitives.Bounds2D;
	import org.oicweave.primitives.ColorRamp;
	import org.oicweave.visualization.plotters.styles.DynamicLineStyle;
	import org.oicweave.visualization.plotters.styles.SolidFillStyle;
	import org.oicweave.visualization.plotters.styles.SolidLineStyle;
	
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
			groupMode.value = false;
			barSpacing.value = 0;
			
			heightColumns.addGroupedCallback(this, defineSortColumnIfUndefined);
			registerNonSpatialProperty(colorColumn);
			registerSpatialProperty(sortColumn);
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
		
		public function get sortColumn():DynamicColumn { return _filteredSortColumn.internalDynamicColumn; }
		
		public function getSortedKeys():Array { return _sortedIndexColumn.keys; }
		
		public const chartColors:ColorRamp = registerNonSpatialProperty(new ColorRamp(ColorRamp.getColorRampXMLByName("Doppler Radar"))); // bars get their color from here
		public const heightColumns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		public const horizontalMode:LinkableBoolean = newSpatialProperty(LinkableBoolean);
		public const groupMode:LinkableBoolean = newSpatialProperty(LinkableBoolean);
		public const barSpacing:LinkableNumber = newSpatialProperty(LinkableNumber);
		
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
			
			var graphics:Graphics = tempShape.graphics;
			var count:int = 0;
			graphics.clear();
			for (var iRecord:int = 0; iRecord < recordKeys.length; iRecord++)
			{
				var recordKey:IQualifiedKey = recordKeys[iRecord] as IQualifiedKey;
				
				//------------------------------------
				// BEGIN code to draw one compound bar
				//------------------------------------
				
				
				
				var sortedIndex:int = _sortedIndexColumn.getValueFromKey(recordKey, Number) as Number;
				
				// x coordinates depend on sorted index
				var xMin:Number = sortedIndex;
				/*if (_groupMode)
				xMin *= _heightColumns.length;*/
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
					var height:Number = heightColumn.getValueFromKey(recordKey, Number) as Number;
					var heightMissing:Boolean = isNaN(height);
					
					if (heightMissing)
						height = WeaveAPI.StatisticsCache.getMean(heightColumn);
					if (isNaN(height))
						height = 0;
					// avoid adding NaN to y coordinate (because result will be NaN).
					if(height >= 0) 
					{
						yMax = yMin + height;
					}
					else
					{
						yNegativeMax = yNegativeMin + height;
					}
					var halfXRange:Number = (xMax - xMin)/2;
					var halfColumnWidth:Number = (_heightColumns.length-1)/2;
					
					if( !heightMissing)
					{
						// bar starts at bar center - half width of the bar, plus the spacing between this and previous bar
						var barStart:Number = xMin + halfSpacing - halfXRange;
						if (_groupMode)
							barStart = xMin + (i - halfColumnWidth) * groupedBarWidth - groupedBarWidth/2;
						
						if( height >= 0) {
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
						} else {
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
						if(_groupMode)
							barEnd = xMin + (i+1 - halfColumnWidth) * groupedBarWidth - groupedBarWidth/2;
						
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
						} else {
							
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
						if(_heightColumns.length == 1)
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
						if(height>=0)yMin = yMax;
						else yNegativeMin = yNegativeMax;
					}
					
				}
				
				
				//------------------------------------
				// END code to draw one compound bar
				//------------------------------------
				
				// If the recordsPerDraw count has been reached, flush the tempShape "buffer" onto the destination BitmapData.
				if (++count > AbstractPlotter.recordsPerDraw)
				{
					destination.draw(tempShape);
					graphics.clear();
					count = 0;
				}
			}
			// flush the tempShape buffer
			if (count > 0)
				destination.draw(tempShape);
			
			//---------------------------------------------------------
			// END template code
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var _groupMode:Boolean = groupMode.value;
			var _heightColumns:Array = heightColumns.getObjects();
			
			// x coordinates depend on sorted index
			var sortedIndex:int = _sortedIndexColumn.getValueFromKey(recordKey, Number) as Number;
			var xMin:Number = sortedIndex - 0.5;
			/*if (_groupMode)
			xMin *= _heightColumns.length;*/
			var xMax:Number = xMin + 1;//(_groupMode ? _heightColumns.length : 1);
			
			// y coordinates depend on height columns
			var yMin:Number = 0; // start first bar at zero
			var yMax:Number = 0;
			var negativeHeight:Number = 0; 
			
			// loop over height columns, incrementing y coordinates
			for (var i:int = 0; i < _heightColumns.length; i++)
			{
				var heightColumn:IAttributeColumn = _heightColumns[i] as IAttributeColumn;
				var height:Number = heightColumn.getValueFromKey(recordKey, Number) as Number;
				if (isNaN(height))
					height = WeaveAPI.StatisticsCache.getMean(heightColumn);
				if (isNaN(height))
					height = 0;
				if (_groupMode)
				{
					// the next bar starts next to this bar, so use max y value
					if (height > yMax)
						yMax = height;
				}
				else
				{
					// add this height to the current bar, so add to y value
					// avoid adding NaN to y coordinate (because result will be NaN).
					if (!isNaN(height))
					{
						if( height >= 0 )yMax += height;
						else negativeHeight += height;
					}
				}
			}
			
			if (horizontalMode.value)
			{
				return [getReusableBounds(negativeHeight, xMin, yMax, xMax)]; // x,y swapped
			}
			else
			{
				return [getReusableBounds(xMin, negativeHeight, xMax, yMax)];
			}
		}
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			var bounds:IBounds2D = getReusableBounds(NaN, 0, NaN, 0);
			for each (var column:IAttributeColumn in heightColumns.getObjects())
			{
				if (groupMode.value)
				{
					bounds.includeCoords(NaN, WeaveAPI.StatisticsCache.getMin(column));
					bounds.includeCoords(NaN, WeaveAPI.StatisticsCache.getMax(column));
				}
				else
				{
					if (!isNaN(WeaveAPI.StatisticsCache.getMax(column)))
						bounds.setYMax(bounds.getYMax() + WeaveAPI.StatisticsCache.getMax(column));
				}
			}
			
			// swap x,y if in horizontal mode
			if (horizontalMode.value)
				bounds.setBounds(bounds.getYMin(), bounds.getXMin(), bounds.getYMax(), bounds.getXMax());
			
			return bounds;
		}
		
		private const tempPoint:Point = new Point(); // reusable temporary object
		private const tempBounds:IBounds2D = new Bounds2D(); // reusable temporary object
	}
}
