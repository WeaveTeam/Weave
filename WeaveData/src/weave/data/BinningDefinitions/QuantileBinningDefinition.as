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
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.core.LinkableNumber;
	import weave.data.BinClassifiers.NumberClassifier;
	
	/**
	 * QuantileBinningDefinition
	 * 
	 * @author adufilie
	 * @author abaumann
	 * @author sanbalagan
	 */
	public class QuantileBinningDefinition implements IBinningDefinition
	{
		public function QuantileBinningDefinition()
		{
			this.refQuantile.value = 0.3;
		}
		
		public const refQuantile:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
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
			
			var dataMin:Number = WeaveAPI.StatisticsCache.getMin(column);
			var dataMax:Number = WeaveAPI.StatisticsCache.getMax(column);
			var sortedColumn:Array = getSortedColumn(column); 
			var binMin:Number;
			var binMax:Number = sortedColumn[0]; 
			var maxInclusive:Boolean;				
						          
			var refBinSize:Number = Math.ceil(WeaveAPI.StatisticsCache.getCount(column) * refQuantile.value);//how many records in a bin
			var numberOfBins:int = Math.ceil(WeaveAPI.StatisticsCache.getCount(column)/ refBinSize);
			var binRecordCount:uint = refBinSize;
				
			for (var iBin:int = 0; iBin < numberOfBins; iBin++)
			{
				binRecordCount = (iBin +1) * refBinSize;
				binMin = binMax;
				if (iBin == numberOfBins - 1)
				{
					binMax = sortedColumn[sortedColumn.length -1];
					maxInclusive = true;
				}
				else{					
					binMax = sortedColumn[binRecordCount -1];
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
		
		//variables for getSortedColumn method
		private var _sortedColumn:Array;
		private var keys:Array;
		
		/**
		 * getSortedColumn 
		 * @param column 
		 * @return _sortedColumn array 
		 */
		private function getSortedColumn(column:IAttributeColumn):Array
		{
			keys = column ? column.keys : [];
			_sortedColumn = new Array(keys.length);
			var i:uint = 0;
			for each (var key:IQualifiedKey in keys)	
			{
				_sortedColumn[i] = column.getValueFromKey(key,Number) as Number;
				i = i+1;
			}
			_sortedColumn.sort(Array.NUMERIC);				
			return _sortedColumn;
		}

	}
}
