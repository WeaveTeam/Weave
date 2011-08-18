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
	
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableString;
	
	/**
	 * This is a column containing aggregated values.
	 * 
	 * TODO: finish this implementation
	 * 
	 * @author adufilie
	 */
	[ExcludeClass]
	public class AggregatedColumn extends ExtendedDynamicColumn
	{
		public function AggregatedColumn()
		{
			init();
		}
		private function init():void
		{
		}
		public const keyMapping:DynamicColumn = newLinkableChild(this, DynamicColumn, invalidateCache);
		public const aggregationType:LinkableString = newLinkableChild(this, LinkableString, invalidateCache);

		private function invalidateCache():void
		{
			_cache = null;
		}
		
		private var _cache:Dictionary = null;

		/**
		 * @return The result of the compiled equation evaluated at the given record key.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_cache == null)
				_cache = new Dictionary();

			var value:* = _cache[key];
			if (value == undefined && internalColumn != null)
			{
				var internalKeys:Array = keyMapping.getValueFromKey(key, Array) as Array;
				if (internalKeys == null)
					return undefined;
				
				//TODO: rewrite this code and support more aggregation types
				switch (aggregationType.value)
				{
					case 'sum':
						var sum:Number = 0;
						for (var i:int = 0; i < internalKeys.length; i++)
						{
							var internalKey:IQualifiedKey = internalKeys[i] as IQualifiedKey;
							sum += internalColumn.getValueFromKey(internalKey, Number);
						}
						value = sum;
					
					default:
					case 'count':
						value = internalKeys.length;
				}
				
				_cache[key] = value;
			}
			
			if (dataType == String)
				return StandardLib.formatNumber(value);
			else if (dataType != null)
				return EquationColumnLib.cast(undefined, dataType);
			
			return value;
		}
	}
}
