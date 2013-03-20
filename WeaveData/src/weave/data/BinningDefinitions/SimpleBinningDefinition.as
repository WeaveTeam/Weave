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
	import weave.api.WeaveAPI;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableNumber;
	import weave.data.BinClassifiers.NumberClassifier;
	import weave.utils.ColumnUtils;
	
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
			// we need a default value for the number of bins (in the spirit of a micro API).
			numberOfBins.value = 10;
		}
		
		/**
		 * The number of bins to generate when calling deriveExplicitBinningDefinition().
		 */
		public const numberOfBins:LinkableNumber = newLinkableChild(this, LinkableNumber);

		/**
		 * From this simple definition, derive an explicit definition.
		 */
		override public function generateBinClassifiersForColumn(column:IAttributeColumn):void
		{
			var name:String;
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			var nonWrapperColumn:IAttributeColumn = column;
			while (nonWrapperColumn is IColumnWrapper)
				nonWrapperColumn = (nonWrapperColumn as IColumnWrapper).getInternalColumn();
			
			var dataType:String = nonWrapperColumn ? ColumnUtils.getDataType(nonWrapperColumn) : null;
			if (dataType == null)
			{
				// hack -- if we find a number, assume dataType is number
				for each (var key:IQualifiedKey in column.keys)
				{
					if (column.getValueFromKey(key) is Number)
					{
						dataType = DataTypes.NUMBER;
						break;
					}
				}
			}
			
			var integerValuesOnly:Boolean = nonWrapperColumn && dataType != DataTypes.NUMBER;
			var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(column);
			var dataMin:Number = stats.getMin();
			var dataMax:Number = stats.getMax();
			
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
					name = tempNumberClassifier.generateBinLabel(nonWrapperColumn as IPrimitiveColumn);

				output.requestObjectCopy(name, tempNumberClassifier);
			}
			
			// trigger callbacks now because we're done updating the output
			asyncResultCallbacks.triggerCallbacks();
		}
		
		// reusable temporary object
		private static const tempNumberClassifier:NumberClassifier = new NumberClassifier();
	}
}
