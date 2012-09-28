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
	import weave.api.core.ILinkableObject;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.DynamicColumn;

	public class StringDataFilter implements IKeyFilter, ILinkableObject
	{
		public function StringDataFilter()
		{
		}
		
		public const column:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const stringValue:LinkableString = newLinkableChild(this, LinkableString);
		
		public function containsKey(key:IQualifiedKey):Boolean
		{
			return column.getValueFromKey(key, String) == stringValue.value;
		}
	}
}
