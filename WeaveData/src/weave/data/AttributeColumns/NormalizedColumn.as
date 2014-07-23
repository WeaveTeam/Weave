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

package weave.data.AttributeColumns
{
	import weave.api.WeaveAPI;
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
