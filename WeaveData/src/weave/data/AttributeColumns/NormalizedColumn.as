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

package weave.data.AttributeColumns
{
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.core.LinkableNumber;
	
	/**
	 * @author adufilie
	 */
	public class NormalizedColumn extends ExtendedDynamicColumn
	{
		public function NormalizedColumn(min:Number = 0, max:Number = 1)
		{
			_stats = WeaveAPI.StatisticsCache.getColumnStatistics(internalDynamicColumn);
			// when stats update, we need to trigger our callbacks because the values returned by getValueFromKey() will be different.
			getCallbackCollection(_stats).addImmediateCallback(this, triggerCallbacks);
			
			this.min.value = min;
			this.max.value = max;
		}

		private var _stats:IColumnStatistics;
		
		public const min:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const max:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		/**
		 * getValueFromKey
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (dataType == null)
				dataType = Number;
			
			if (dataType == Number)
			{
				// get norm value between 0 and 1
				var norm:Number = _stats.getNorm(key);
				// return number between min and max
				return min.value + norm * (max.value - min.value);
			}
			
			return super.getValueFromKey(key, dataType);
		}
	}
}
