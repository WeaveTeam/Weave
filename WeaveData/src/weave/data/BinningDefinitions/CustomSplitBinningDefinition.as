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
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.weave_internal;
	import weave.data.BinClassifiers.NumberClassifier;
	import weave.utils.VectorUtils;
	
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
		 * A list of numeric values separated by commas that mark the beginning and end of bin ranges.
		 */
		public const splitValues:LinkableString = newLinkableChild(this, LinkableString);
		
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
			var values:Array = splitValues.value.split(',');
			// remove bad values
			for (i = values.length - 1; i >= 0; i--)
			{
				var number:Number = StandardLib.asNumber(values[i]);
				if (!isFinite(number))
					values.splice(i, 1);
				else
					values[i] = number;
			}
			// sort numerically
			values.sort(Array.NUMERIC);
			
			for (i = 0; i < values.length - 1; i++)
			{
				tempNumberClassifier.min.value = values[i];
				tempNumberClassifier.max.value = values[i + 1];
				tempNumberClassifier.minInclusive.value = true;
				tempNumberClassifier.maxInclusive.value = (i == values.length - 2);
				
				name = tempNumberClassifier.generateBinLabel(nonWrapperColumn as IPrimitiveColumn);
				output.requestObjectCopy(name, tempNumberClassifier);
			}
			
			// allow callbacks to run now.
			getCallbackCollection(output).resumeCallbacks();
		}
		
		// reusable temporary object
		private static const tempNumberClassifier:NumberClassifier = new NumberClassifier();

		// backwards compatibility
		[Deprecated(replacement="splitValues")] public function set binRange(value:String):void { splitValues.value = value; }
		[Deprecated(replacement="splitValues")] public function set dataMin(value:String):void { splitValues.value = value + ',' + splitValues.value; }
		[Deprecated(replacement="splitValues")] public function set dataMax(value:String):void { splitValues.value += ',' + value; }
	}
}

