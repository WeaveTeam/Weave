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

package weave.data.BinningDefinitions
{
	import mx.utils.StringUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.data.BinClassifiers.NumberClassifier;
	
	/**
	 * StandardDeviationBinningDefinition
	 * 
	 * @author adufilie
	 */
	public class StandardDeviationBinningDefinition extends AbstractBinningDefinition
	{
		public function StandardDeviationBinningDefinition()
		{
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getBinClassifiersForColumn(column:IAttributeColumn, output:ILinkableHashMap):void
		{
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(column);
			var mean:Number = stats.getMean();
			var stdDev:Number = stats.getStandardDeviation();
			var binNumber:int = 0;
			for (var i:int = -MAX_SD; i <= MAX_SD; i++)
				if (i != 0)
					addBin(output, Math.abs(i), i < 0, stdDev, mean, getNameFromOverrideString(binNumber++));
		}
		
		private static const MAX_SD:int = 3;
		
		private function addBin(output:ILinkableHashMap, absSDNumber:Number, belowMean:Boolean, stdDev:Number, mean:Number, overrideName:String):void
		{
			var name:String = overrideName;
			if (!name)
			{
				var nameFormat:String = (absSDNumber < MAX_SD) ? "{0} - {1} SD {2} mean" : "> {0} SD {2} mean"; 
				name = StringUtil.substitute(nameFormat, absSDNumber - 1, absSDNumber, belowMean ? "below" : "above");
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

