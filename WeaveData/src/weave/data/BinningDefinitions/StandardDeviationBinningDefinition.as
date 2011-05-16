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
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IBinningDefinition;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.newLinkableChild;
	import weave.core.LinkableNumber;
	import weave.data.BinClassifiers.NumberClassifier;
	
	/**
	 * StandardDeviationBinningDefinition
	 * 
	 * @author adufilie
	 * @author abaumann
	 * @author sanbalagan
	 */
	public class StandardDeviationBinningDefinition implements IBinningDefinition
	{
		public function StandardDeviationBinningDefinition()
		{
			this.sdNumber.value = 3;
		}
		
		public const sdNumber:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		/**
		 * getBinClassifiersForColumn - implements IBinningDefinition Interface
		 * @param column 
		 * @param output
		 */
		public function getBinClassifiersForColumn(column:IAttributeColumn, output:ILinkableHashMap):void
		{
			var name:String;
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			var columnMean:Number = WeaveAPI.StatisticsCache.getMean(column);
			var columnSD:Number = WeaveAPI.StatisticsCache.getStandardDeviation(column); 
					
			var binMin:Number;
			var binMax:Number = columnMean - sdNumber.value * columnSD;
			var maxInclusive:Boolean;
			
			var iBin:int;
			for (iBin = sdNumber.value ; iBin > 0 ; iBin--)
			{
				binMin = binMax
				binMax = columnMean - (iBin-1) * columnSD;
				maxInclusive = false;
				
				tempNumberClassifier.min.value = binMin;
				tempNumberClassifier.max.value = binMax;
				tempNumberClassifier.minInclusive.value = true;
				tempNumberClassifier.maxInclusive.value = maxInclusive;
				
				name = tempNumberClassifier.generateBinLabel(column as IPrimitiveColumn);
				output.copyObject(name, tempNumberClassifier);
			}	
						
			for (iBin = 0 ; iBin < sdNumber.value ; iBin++)
			{
				binMin = binMax; 
				binMax = columnMean + (iBin+1) * columnSD;
				if (iBin == sdNumber.value - 1){
					maxInclusive = true;
				} else {
					maxInclusive = false;				
				}
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
