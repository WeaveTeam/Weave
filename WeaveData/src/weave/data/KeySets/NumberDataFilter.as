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
package weave.data.KeySets
{
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.DynamicColumn;

	public class NumberDataFilter implements IKeyFilter
	{
		public const enabled:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true), cacheValues);
		public const column:DynamicColumn = newLinkableChild(this, DynamicColumn, cacheValues);
		public const min:LinkableNumber = registerLinkableChild(this, new LinkableNumber(-Infinity), cacheValues);
		public const max:LinkableNumber = registerLinkableChild(this, new LinkableNumber(Infinity), cacheValues);
		public const includeMissingKeyTypes:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true), cacheValues);

		private function cacheValues():void
		{
			_enabled = enabled.value;
			_keyType = column.getMetadata(ColumnMetadata.KEY_TYPE);
			_min = min.value;
			_max = max.value;
			_includeMissingKeyTypes = includeMissingKeyTypes.value;
		}
		
		private var _enabled:Boolean;
		private var _keyType:String;
		private var _min:Number;
		private var _max:Number;
		private var _includeMissingKeyTypes:Boolean;

		public function containsKey(key:IQualifiedKey):Boolean
		{
			if (!_enabled)
				return true;
			if (_includeMissingKeyTypes && key.keyType != _keyType)
				return true;
			var value:Number = column.getValueFromKey(key, Number);
			return value >= _min && value <= _max;
		}
	}
}
