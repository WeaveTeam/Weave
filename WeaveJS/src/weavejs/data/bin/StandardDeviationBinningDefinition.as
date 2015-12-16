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
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IColumnStatistics;
	import weavejs.data.bin.NumberClassifier;
	import weavejs.util.StandardLib;
	
	/**
	 * StandardDeviationBinningDefinition
	 * 
	 * @author adufilie
	 */
	public class StandardDeviationBinningDefinition extends AbstractBinningDefinition
	{
		public function StandardDeviationBinningDefinition()
		{
			super(true, false);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function generateBinClassifiersForColumn(column:IAttributeColumn):void
		{
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(column);
			var mean:Number = stats.getMean();
			var stdDev:Number = stats.getStandardDeviation();
			var binNumber:int = 0;
			for (var i:int = -MAX_SD; i <= MAX_SD; i++)
				if (i != 0)
					addBin(output, Math.abs(i), i < 0, stdDev, mean, getOverrideNames()[binNumber++]);
			
			// trigger callbacks now because we're done updating the output
			asyncResultCallbacks.triggerCallbacks();
		}
		
		private static const MAX_SD:int = 3;
		
		private function addBin(output:ILinkableHashMap, absSDNumber:Number, belowMean:Boolean, stdDev:Number, mean:Number, overrideName:String):void
		{
			var name:String = overrideName;
			if (!name)
			{
				var nameFormat:String = (absSDNumber < MAX_SD) ? "{0} - {1} SD {2} mean" : "> {0} SD {2} mean"; 
				name = StandardLib.substitute(nameFormat, absSDNumber - 1, absSDNumber, belowMean ? "below" : "above");
			}
			var bin:NumberClassifier = output.requestObject(name, NumberClassifier, false);
			if (belowMean)
			{
				if (absSDNumber == MAX_SD)
					bin.min.value = -Infinity;
				else
					bin.min.value = mean - absSDNumber * stdDev;
				bin.max.value = mean - (absSDNumber - 1) * stdDev;
			}
			else // above mean
			{
				bin.min.value = mean + (absSDNumber - 1) * stdDev;
				if (absSDNumber == MAX_SD)
					bin.max.value = Infinity;
				else
					bin.max.value = mean + absSDNumber * stdDev;
			}
			bin.minInclusive.value = true;
			bin.maxInclusive.value = true;
		}
	}
}

