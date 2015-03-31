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

package weave.data.BinningDefinitions
{
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableNumber;
	import weave.data.BinClassifiers.NumberClassifier;
	
	/**
	 * EqualIntervalBinningDefinition
	 * 
	 * @author adufilie
	 * @author abaumann
	 * @author sanbalagan
	 */
	public class EqualIntervalBinningDefinition extends AbstractBinningDefinition
	{
		public function EqualIntervalBinningDefinition()
		{
			super(true, true);
		}
		
		public const dataInterval:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		
		override public function generateBinClassifiersForColumn(column:IAttributeColumn):void
		{
			var name:String;
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			//var integerValuesOnly:Boolean = column is StringColumn;
			var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(column);
			var dataMin:Number = isFinite(overrideInputMin.value) ? overrideInputMin.value : stats.getMin();
			var dataMax:Number = isFinite(overrideInputMax.value) ? overrideInputMax.value : stats.getMax();
			var binMin:Number;
			var binMax:Number = dataMin;
			var maxInclusive:Boolean;
			//var valuesPerBin:int = Math.ceil((dataMax - dataMin + 1) / dataInterval.value);
			var numberOfBins:int = Math.ceil((dataMax - dataMin) / dataInterval.value);
			
			for (var iBin:int = 0; iBin < numberOfBins; iBin++)
			{
				
					// classifiers use min <= value < max,
					// except for the final one, which uses min <= value <= max
					binMin = binMax;
					if (iBin == numberOfBins - 1)
					{
						binMax = dataMax;
						maxInclusive = true;
					}
					else
					{
						maxInclusive = false;
						
						//****binMax = dataMin + (iBin + 1) * (dataMax - dataMin) / numberOfBins.value;
						binMax = binMin + dataInterval.value;
						// TEMPORARY SOLUTION -- round bin boundaries
						binMax = StandardLib.roundSignificant(binMax, 4);
					}
					
					// TEMPORARY SOLUTION -- round bin boundaries
					if (iBin > 0)
						binMin = StandardLib.roundSignificant(binMin, 4);
					
					// skip bins with no values
					if (binMin == binMax && !maxInclusive)
						continue;
				tempNumberClassifier.min.value = binMin;
				tempNumberClassifier.max.value = binMax;
				tempNumberClassifier.minInclusive.value = true;
				tempNumberClassifier.maxInclusive.value = maxInclusive;
				
				//first get name from overrideBinNames
				name = getOverrideNames()[iBin];
				//if it is empty string set it from generateBinLabel
				if(!name)
					name = tempNumberClassifier.generateBinLabel(column);
				output.requestObjectCopy(name, tempNumberClassifier);
			}
			
			// trigger callbacks now because we're done updating the output
			asyncResultCallbacks.triggerCallbacks();
		}
		
		// reusable temporary object
		private static const tempNumberClassifier:NumberClassifier = new NumberClassifier();
	}
}
