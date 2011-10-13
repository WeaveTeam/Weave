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
	import flash.utils.getQualifiedClassName;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.core.CallbackCollection;
	import weave.utils.ColumnUtils;
	
	/**
	 * This object contains a mapping from keys to data values.
	 * 
	 * @author adufilie
	 * @author abaumann
	 */
	public class AbstractAttributeColumn extends CallbackCollection implements IAttributeColumn
	{
		public function AbstractAttributeColumn(metadata:XML = null)
		{
			// make a copy because we don't want any surprises (metadata being set afterwards)
			if (metadata)
				_metadata = metadata.copy();
		}
		
		protected var _metadata:XML = <attribute title="Undefined column"/>;

		// metadata for this attributeColumn (statistics, description, unit, etc)
		public function getMetadata(propertyName:String):String
		{
			var value:String = null;
			if (_metadata != null && _metadata.attribute(propertyName).length() > 0)
				value = _metadata.attribute(propertyName);
			
			return value;
		}
		
		// 'abstract' functions, should be defined with override when extending this class

		public /* abstract */ function get keys():Array
		{
			return null;
		}
		
		public /* abstract */ function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			return NaN;
		}
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		public /* abstract */ function containsKey(key:IQualifiedKey):Boolean
		{
			return false;
		}

/*		protected function trace(...args):void
		{
			DebugUtils.debug_trace(this, args);
		}
*/		
		public function toString():String
		{
			return getQualifiedClassName(this).split("::")[1] + ' "' + ColumnUtils.getTitle(this) + '"';
		}
	}
}
