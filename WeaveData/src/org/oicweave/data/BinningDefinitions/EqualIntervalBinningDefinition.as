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

package org.oicweave.data.BinningDefinitions
{
	import org.oicweave.api.WeaveAPI;
	import org.oicweave.api.core.ILinkableHashMap;
	import org.oicweave.api.data.IAttributeColumn;
	import org.oicweave.api.data.IBinningDefinition;
	import org.oicweave.api.data.IPrimitiveColumn;
	import org.oicweave.api.newLinkableChild;
	import org.oicweave.compiler.MathLib;
	import org.oicweave.core.LinkableNumber;
	import org.oicweave.data.BinClassifiers.NumberClassifier;
	
	/**
	 * EqualIntervalBinningDefinition
	 * 
	 * @author adufilie
	 * @author abaumann
	 * @author sanbalagan
	 */
	public class EqualIntervalBinningDefinition implements IBinningDefinition
	{
		public function EqualIntervalBinningDefinition()
		{
			// the value of 1 is arbitrary, but at least when you choose this type of binning
			// it will show some data rather than nothing
			this.dataInterval.value = 1;	
		}
		
		public const dataInterval:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		public function getBinClassifiersForColumn(column:IAttributeColumn, output:ILinkableHashMap):void
		{
			var name:String;
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			//var integerValuesOnly:Boolean = column is StringColumn;
			var dataMin:Number = WeaveAPI.StatisticsCache.getMin(column);
			var dataMax:Number = WeaveAPI.StatisticsCache.getMax(column);
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
						binMax = MathLib.roundSignificant(binMax, 4);
					}
					
					// TEMPORARY SOLUTION -- round bin boundaries
					if (iBin > 0)
						binMin = MathLib.roundSignificant(binMin, 4);
					
					// skip bins with no values
					if (binMin == binMax && !maxInclusive)
						continue;
				tempNumberClassifier.min.value = binMin;
				tempNumberClassifier.max.value = binMax;
				tempNumberClassifier.minInclusive.value = true;
				tempNumberClassifier.maxInclusive.value = maxInclusive;
				
				name = tempNumberClassifier.generateBinLabel(column as IPrimitiveColumn);
				output.copyObject(name, tempNumberClassifier);
			}
		}
		
		// reusable temporary object
		private static const tempNumberClassifier:NumberClassifier = new NumberClassifier();
	}
}
