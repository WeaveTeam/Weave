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
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.core.LinkableString;
	import weave.utils.EquationColumnLib;

	public class KeyColumn extends AbstractAttributeColumn
	{
		public function KeyColumn(metadata:XML=null)
		{
			super(metadata);
		}
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == ColumnMetadata.TITLE)
			{
				var kt:String = keyType.value;
				if (kt)
					return lang("Key ({0})", kt);
				return lang("Key");
			}
			if (propertyName == ColumnMetadata.KEY_TYPE)
				return keyType.value;
			
			return super.getMetadata(propertyName);
		}
		
		public const keyType:LinkableString = newLinkableChild(this, LinkableString);
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class=null):*
		{
			var kt:String = keyType.value;
			if (kt && key.keyType != kt)
				return EquationColumnLib.cast(undefined, dataType);
			
			if (dataType == String)
				return key.localName;
			
			if (dataType == IQualifiedKey)
				return key;
			
			return EquationColumnLib.cast(key, dataType);
		}
		
		override public function get keys():Array
		{
			return [];
		}
	}
}