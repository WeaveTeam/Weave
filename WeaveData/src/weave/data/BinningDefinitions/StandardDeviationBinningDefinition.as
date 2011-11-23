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
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableNumber;
	import weave.core.weave_internal;
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
		
		public const sdNumber:LinkableNumber = registerLinkableChild(this, new LinkableNumber(3, verifySDNumber));
		
		private function verifySDNumber(value:Number):Boolean
		{
			return [1,2,3].indexOf(value) >= 0;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getBinClassifiersForColumn(column:IAttributeColumn, output:ILinkableHashMap):void
		{
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			var mean:Number = WeaveAPI.StatisticsCache.getMean(column);
			var stdDev:Number = WeaveAPI.StatisticsCache.getStandardDeviation(column);
			
			for (var i:int = -sdNumber.value; i < sdNumber.value; i++)
			{
				//first get name from overrideBinNames
				var name:String = getNameFromOverrideString(sdNumber.value + i);
				//if it is empty string set it from generateBinLabel
				if (!name)
				{
					if (i < 0)
						name = -i + ' below';
					else
						name = (i + 1) + ' above';
				}
				
				var bin:NumberClassifier = output.requestObject(name, NumberClassifier, false);
				bin.min.value = mean + i * stdDev;
				bin.max.value = mean + (i + 1) * stdDev;
				bin.minInclusive.value = true;
				bin.maxInclusive.value = (i == sdNumber.value - 1);
			}
		}
	}
}
