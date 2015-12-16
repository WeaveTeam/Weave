/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weavejs.data.bin
{
	import weavejs.WeaveAPI;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.DataType;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IColumnStatistics;
	import weavejs.core.LinkableNumber;
	import weavejs.data.ColumnUtils;
	import weavejs.util.StandardLib;
	
	/**
	 * Divides a data range into a number of equally spaced bins.
	 * 
	 * @author adufilie
	 * @author abaumann
	 */
	public class SimpleBinningDefinition extends AbstractBinningDefinition
	{
		public function SimpleBinningDefinition()
		{
			super(true, true);
		}
		
		/**
		 * The number of bins to generate when calling deriveExplicitBinningDefinition().
		 */
		public var numberOfBins:LinkableNumber = Weave.linkableChild(this, new LinkableNumber(5));

		/**
		 * From this simple definition, derive an explicit definition.
		 */
		override public function generateBinClassifiersForColumn(column:IAttributeColumn):void
		{
			var name:String;
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			var integerValuesOnly:Boolean = false;
			var nonWrapperColumn:IAttributeColumn = ColumnUtils.hack_findNonWrapperColumn(column);
			if (nonWrapperColumn)
			{
				var dataType:String = nonWrapperColumn.getMetadata(ColumnMetadata.DATA_TYPE);
				if (dataType && dataType != DataType.NUMBER)
					integerValuesOnly = true;
			}
			var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(column);
			var dataMin:Number = isFinite(overrideInputMin.value) ? overrideInputMin.value : stats.getMin();
			var dataMax:Number = isFinite(overrideInputMax.value) ? overrideInputMax.value : stats.getMax();
			
			// stop if there is no data
			if (isNaN(dataMin))
			{
				asyncResultCallbacks.triggerCallbacks();
				return;
			}
		
			var binMin:Number;
			var binMax:Number = dataMin;
			var maxInclusive:Boolean;
			
			for (var iBin:int = 0; iBin < numberOfBins.value; iBin++)
			{
				if (integerValuesOnly)
				{
					maxInclusive = true;
					if (iBin == 0)
						binMin = dataMin;
					else
						binMin = binMax + 1;
					if (iBin == numberOfBins.value - 1)
						binMax = dataMax;
					else
						binMax = Math.floor(dataMin + (iBin + 1) * (dataMax - dataMin) / numberOfBins.value);
					// skip empty bins
					if (binMin > binMax)
						continue;
				}
				else
				{
					// classifiers use min <= value < max,
					// except for the final one, which uses min <= value <= max
					binMin = binMax;
					if (iBin == numberOfBins.value - 1)
					{
						binMax = dataMax;
						maxInclusive = true;
					}
					else
					{
						maxInclusive = false;
						binMax = dataMin + (iBin + 1) * (dataMax - dataMin) / numberOfBins.value;
						// TEMPORARY SOLUTION -- round bin boundaries
						binMax = StandardLib.roundSignificant(binMax, 4);
					}
					
					// TEMPORARY SOLUTION -- round bin boundaries
					if (iBin > 0)
						binMin = StandardLib.roundSignificant(binMin, 4);
	
					// skip bins with no values
					if (binMin == binMax && !maxInclusive)
						continue;
				}
				tempNumberClassifier.min.value = binMin;
				tempNumberClassifier.max.value = binMax;
				tempNumberClassifier.minInclusive.value = true;
				tempNumberClassifier.maxInclusive.value = maxInclusive;
				
				//first get name from overrideBinNames
				name = getOverrideNames()[iBin];
				//if it is empty string set it from generateBinLabel
				if (!name)
					name = tempNumberClassifier.generateBinLabel(column);

				output.requestObjectCopy(name, tempNumberClassifier);
			}
			
			// trigger callbacks now because we're done updating the output
			asyncResultCallbacks.triggerCallbacks();
		}
		
		// reusable temporary object
		private var tempNumberClassifier:NumberClassifier = Weave.disposableChild(this, NumberClassifier);
	}
}
