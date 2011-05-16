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
	import flash.utils.Dictionary;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	
	/**
	 * This column maps a key to the running total numeric value at the key, using the order of the keys in the internal column.
	 * 
	 * @author adufilie
	 */
	public class RunningTotalColumn extends DynamicColumn implements IAttributeColumn
	{
		public function RunningTotalColumn()
		{
			super();
			addImmediateCallback(this, handleInternalColumnChange);
		}

		protected function handleInternalColumnChange():void
		{
			_runningTotalMap = null; // clear previous values
		}
		
		private var _runningTotalMap:Dictionary = null;
		
		/**
		 * @param key A key existing in the internal column.
		 * @param dataType A requested return type.
		 * @return The running total numeric value at the specified key.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_runningTotalMap == null)
			{
				_runningTotalMap = new Dictionary();
				var keys:Array = internalColumn ? internalColumn.keys : [];
				var sum:Number = 0;
				for (var i:int = 0; i < keys.length; i++)
				{
					var _key:IQualifiedKey = keys[i];
					sum += (internalColumn.getValueFromKey(_key, Number) as Number);
					_runningTotalMap[_key] = sum;
					//trace("RunningTotalColumn "+_key+"("+i+") -> "+sum);
				}
			}
			
			var result:Number = _runningTotalMap[key];
			
			// cast to other types
			if (dataType == String)
				return isNaN(result) ? '' : key; // returns the key itself or empty string if the key doesn't exist
			else if (dataType == Boolean)
				return !isNaN(result); // true if key exists in lookup table
			
			return result;
		}
	}
}
