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
	import weavejs.api.data.IAttributeColumn;
	import weavejs.core.LinkableString;
	import weavejs.util.AsyncSort;
	import weavejs.util.StandardLib;
	
	/**
	 * Divides a data range into a number of bins based on range entered by user.
	 * 
	 * @author adufilie
	 * @author abaumann
	 * @author skolman
	 */
	public class CustomSplitBinningDefinition extends AbstractBinningDefinition
	{
		public function CustomSplitBinningDefinition()
		{
			super(true, false);
		}
		
		/**
		 * A list of numeric values separated by commas that mark the beginning and end of bin ranges.
		 */
		public const splitValues:LinkableString = Weave.linkableChild(this, LinkableString);
		
		override public function generateBinClassifiersForColumn(column:IAttributeColumn):void
		{
			// make sure callbacks only run once.
			Weave.getCallbacks(output).delayCallbacks();
			
			var name:String;
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			var i:int;
			var values:Array = String(splitValues.value || '').split(',');
			// remove bad values
			for (i = values.length; i--;)
			{
				var number:Number = StandardLib.asNumber(values[i]);
				if (!isFinite(number))
					values.splice(i, 1);
				else
					values[i] = number;
			}
			// sort numerically
			AsyncSort.sortImmediately(values);
			
			for (i = 0; i < values.length - 1; i++)
			{
				tempNumberClassifier.min.value = values[i];
				tempNumberClassifier.max.value = values[i + 1];
				tempNumberClassifier.minInclusive.value = true;
				tempNumberClassifier.maxInclusive.value = (i == values.length - 2);
				
				//first get name from overrideBinNames
				name = getOverrideNames()[i];
				//if it is empty string set it from generateBinLabel
				if(!name)
					name = tempNumberClassifier.generateBinLabel(column);
				output.requestObjectCopy(name, tempNumberClassifier);
			}
			
			// allow callbacks to run now.
			Weave.getCallbacks(output).resumeCallbacks();
			
			// trigger callbacks now because we're done updating the output
			asyncResultCallbacks.triggerCallbacks();
		}
		
		// reusable temporary object
		private var tempNumberClassifier:NumberClassifier = Weave.disposableChild(this, NumberClassifier);

		// backwards compatibility
		[Deprecated(replacement="splitValues")] public function set binRange(value:String):void { splitValues.value = value; }
		[Deprecated(replacement="splitValues")] public function set dataMin(value:String):void { splitValues.value = value + ',' + splitValues.value; }
		[Deprecated(replacement="splitValues")] public function set dataMax(value:String):void { splitValues.value += ',' + value; }
	}
}

