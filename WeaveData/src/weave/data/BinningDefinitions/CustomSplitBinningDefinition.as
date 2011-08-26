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
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IBinningDefinition;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.BinClassifiers.NumberClassifier;
	
	/**
	 * Divides a data range into a number of bins based on range entered by user.
	 * 
	 * @author adufilie
	 * @author abaumann
	 * @author skolman
	 */
	public class CustomSplitBinningDefinition implements IBinningDefinition
	{
		public function CustomSplitBinningDefinition()
		{
		}
		
		/**
		 * dataMin,dataMax
		 * minimum and maximum values of the range.
		 */
		public const dataMin:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const dataMax:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		/**
		 * binRange
		 * range explicitly mentioned by the user.
		 */
		public const binRange:LinkableString = newLinkableChild(this, LinkableString);
		
		/**
		 * getBinClassifiersForColumn - implements IBinningDefinition Interface
		 * @param column 
		 * @param output
		 */
		public function getBinClassifiersForColumn(column:IAttributeColumn, output:ILinkableHashMap):void
		{
			// make sure callbacks only run once.
			getCallbackCollection(output).delayCallbacks();
			
			var name:String;
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			var nonWrapperColumn:IAttributeColumn = column;
			while (nonWrapperColumn is IColumnWrapper)
				nonWrapperColumn = (nonWrapperColumn as IColumnWrapper).internalColumn;
			
			var i:int;
			var splitBins:Array = binRange.value.split(',');
			splitBins.push(dataMin.value, dataMax.value);
			// remove bad values
			for (i = splitBins.length - 1; i >= 0; i--)
				if (!isFinite(StandardLib.asNumber(splitBins[i])))
					splitBins.splice(i, 1);
			// sort numerically
			splitBins.sort(Array.NUMERIC);
			
			for (i = 0; i < splitBins.length - 1; i++)
			{
				tempNumberClassifier.min.value = splitBins[i];
				tempNumberClassifier.max.value = splitBins[i + 1];
				tempNumberClassifier.minInclusive.value = true;
				tempNumberClassifier.maxInclusive.value = (i == splitBins.length - 1);
				
				name = tempNumberClassifier.generateBinLabel(nonWrapperColumn as IPrimitiveColumn);
				output.copyObject(name, tempNumberClassifier);
			}
			
			// allow callbacks to run now.
			getCallbackCollection(output).resumeCallbacks();
		}
		
		// reusable temporary object
		private static const tempNumberClassifier:NumberClassifier = new NumberClassifier();
	}
}

