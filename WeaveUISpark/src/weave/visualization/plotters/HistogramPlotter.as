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
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.api.ui.ISelectableAttributes;
	import weave.api.ui.IPlotTask;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.primitives.Bounds2D;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * This plotter displays a histogram with optional colors.
	 * 
	 * @author adufilie
	 */
	public class HistogramPlotter extends AbstractPlotter implements ISelectableAttributes
	{
		public function HistogramPlotter()
		{
			clipDrawing = true;
			
			aggregateStats = registerSpatialProperty(WeaveAPI.StatisticsCache.getColumnStatistics(columnToAggregate));
			
			// don't lock the ColorColumn, so linking to global ColorColumn is possible
			var _colorColumn:ColorColumn = fillStyle.color.internalDynamicColumn.requestLocalObject(ColorColumn, false);
			_colorColumn.ramp.value = "0x808080";

			var _binnedColumn:BinnedColumn = _colorColumn.internalDynamicColumn.requestLocalObject(BinnedColumn, true);
			
			// the data inside the binned column needs to be filtered by the subset
			var filteredColumn:FilteredColumn = _binnedColumn.internalDynamicColumn.requestLocalObject(FilteredColumn, true);
			
			linkSessionState(filteredKeySet.keyFilter, filteredColumn.filter);
			
			// make the colors spatial properties because the binned column is inside
			registerSpatialProperty(fillStyle.color.internalDynamicColumn);

			setSingleKeySource(fillStyle.color.internalDynamicColumn); // use record keys, not bin keys!
		}
		
		public function getSelectableAttributeNames():Array
		{
			return ["Grouping values", "Height values (Optional)"];
		}
		public function getSelectableAttributes():Array
		{
			return [fillStyle.color, columnToAggregate];
		}
		
		/**
		 * This column object may change and it may be null, depending on the session state.
		 * This function is provided for convenience.
		 */		
		public function get internalBinnedColumn():BinnedColumn
		{
			var cc:ColorColumn = internalColorColumn;
			if (cc)
				return cc.getInternalColumn() as BinnedColumn
			return null;
		}
		/**
		 * This column object may change and it may be null, depending on the session state.
		 * This function is provided for convenience.
		 */
		public function get internalColorColumn():ColorColumn
		{
			return fillStyle.color.getInternalColumn() as ColorColumn;
		}
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const fillStyle:SolidFillStyle = newLinkableChild(this, SolidFillStyle);
		public const drawPartialBins:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		public const columnToAggregate:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const aggregationMethod:LinkableString = registerSpatialProperty(new LinkableString(AG_COUNT, verifyAggregationMethod));
		public const horizontalMode:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));
		
		private static function verifyAggregationMethod(value:String):Boolean { return ENUM_AGGREGATION_METHODS.indexOf(value) >= 0; }
		public static const ENUM_AGGREGATION_METHODS:Array = [AG_COUNT, AG_SUM, AG_MEAN];
		public static const AG_COUNT:String = 'count';
		public static const AG_SUM:String = 'sum';
		public static const AG_MEAN:String = 'mean';
		
		private var aggregateStats:IColumnStatistics;

		private function getAggregateValue(keys:Array):Number
		{
			var agCol:IAttributeColumn = columnToAggregate.getInternalColumn();
			if (!agCol)
				return 0;
			
			var count:int = 0;
			var sum:Number = 0;
			for each (var key:IQualifiedKey in keys)
			{
				var value:Number = agCol.getValueFromKey(key, Number);
				if (isFinite(value))
				{
					sum += value;
					count++;
				}
			}
			if (aggregationMethod.value == AG_MEAN)
				return sum /= count; // convert sum to mean
			if (aggregationMethod.value == AG_COUNT)
				return count; // use count of finite values
			
			// AG_SUM
			return sum;
		}

		/**
		 * This function returns the collective bounds of all the bins.
		 */
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			output.reset();
			
			var binCol:BinnedColumn = internalBinnedColumn;
			if (binCol)
			{
				if (horizontalMode.value)
					output.setYRange(-0.5, Math.max(1, binCol.numberOfBins) - 0.5);
				else
					output.setXRange(-0.5, Math.max(1, binCol.numberOfBins) - 0.5);
			}
		}
		
		/**
		 * This gets the data bounds of the histogram bin that a record key falls into.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			var binCol:BinnedColumn = internalBinnedColumn;
			if (binCol == null)
			{
				initBoundsArray(output, 0);
				return;
			}
			
			var binIndex:Number = binCol.getValueFromKey(recordKey, Number);
			if (isNaN(binIndex))
			{
				initBoundsArray(output, 0);
				return;
			}
			
			var keysInBin:Array = binCol.getKeysFromBinIndex(binIndex);
			var agCol:IAttributeColumn = columnToAggregate.getInternalColumn();
			var binHeight:Number = agCol ? getAggregateValue(keysInBin) : keysInBin.length;
			
			if (horizontalMode.value)
				initBoundsArray(output).setBounds(0, binIndex - 0.5, binHeight, binIndex + 0.5);
			else
				initBoundsArray(output).setBounds(binIndex - 0.5, 0, binIndex + 0.5, binHeight);
		}
		
		/**
		 * This draws the histogram bins that a list of record keys fall into.
		 */
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			drawAll(task.recordKeys, task.dataBounds, task.screenBounds, task.buffer);
			return 1;
		}
		private function drawAll(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var i:int;
			var binCol:BinnedColumn = internalBinnedColumn;
			if (binCol == null)
				return;
			
			// convert record keys to bin keys
			// save a mapping of each bin key found to a value of true
			var binName:String;
			var _tempBinKeyToSingleRecordKeyMap:Object = new Object();
			for (i = 0; i < recordKeys.length; i++)
			{
				binName = binCol.getValueFromKey(recordKeys[i], String);
				var array:Array = _tempBinKeyToSingleRecordKeyMap[binName] as Array
				if (!array)
					array = _tempBinKeyToSingleRecordKeyMap[binName] = [];
				array.push(recordKeys[i]);
			}

			var binNames:Array = [];
			for (binName in _tempBinKeyToSingleRecordKeyMap)
				binNames.push(binName);
			var allBinNames:Array = binCol.binningDefinition.getBinNames();
			
			// draw the bins
			// BEGIN template code for defining a drawPlot() function.
			//---------------------------------------------------------
			
			var key:IQualifiedKey;
			var agCol:IAttributeColumn = columnToAggregate.getInternalColumn();
			var graphics:Graphics = tempShape.graphics;
			for (i = 0; i < binNames.length; i++)
			{
				binName = binNames[i];
				var keys:Array = _tempBinKeyToSingleRecordKeyMap[binName] as Array;
				if (!drawPartialBins.value)
					keys = binCol.getKeysFromBinName(binName);
				
				var binIndex:int = allBinNames.indexOf(binName);
				var binHeight:Number = agCol ? getAggregateValue(keys) : keys.length;
				
				// bars are centered at their binIndex values and have width=1
				if (horizontalMode.value)
				{
					tempBounds.setXRange(0, binHeight);
					tempBounds.setCenteredYRange(binIndex, 1);
				}
				else
				{
					tempBounds.setYRange(0, binHeight);
					tempBounds.setCenteredXRange(binIndex, 1);
				}
				dataBounds.projectCoordsTo(tempBounds, screenBounds);
	
				// draw rectangle for bin
				graphics.clear();
				lineStyle.beginLineStyle(keys[0], graphics);
				fillStyle.beginFillStyle(keys[0], graphics);
				graphics.drawRect(tempBounds.getXMin(), tempBounds.getYMin(), tempBounds.getWidth(), tempBounds.getHeight());
				graphics.endFill();
				// flush the tempShape "buffer" onto the destination BitmapData.
				destination.draw(tempShape);
			}
			
			//---------------------------------------------------------
			// END template code
		}
		
		private const tempBounds:IBounds2D = new Bounds2D(); // reusable temporary object

		//------------------------
		// backwards compatibility
		[Deprecated(replacement="fillStyle.color.internalDynamicColumn")] public function set dynamicColorColumn(value:Object):void
		{
			setSessionState(fillStyle.color.internalDynamicColumn, value);
		}
		[Deprecated(replacement="internalBinnedColumn")] public function set binnedColumn(value:Object):void
		{
			fillStyle.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			setSessionState(internalBinnedColumn, value);
		}
		[Deprecated(replacement="columnToAggregate")] public function set sumColumn(value:Object):void
		{
			setSessionState(columnToAggregate, value);
			if (columnToAggregate.getInternalColumn())
				aggregationMethod.value = AG_SUM;
		}
	}
}
