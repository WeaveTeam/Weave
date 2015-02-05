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
package weave.ui
{
    public class MetadataGridItem
    {
		/**
		 * @param property The name of the metadata item
		 * @param value The starting value of the metadata item
		 */
		public function MetadataGridItem(property:String, value:Object = null)
		{
			this.property = property;
			this.oldValue = value || '';
			this.value = value || '';
		}
		
		public var property:String;
		public var oldValue:Object;
		public var value:Object;
		
		public function get changed():Boolean
		{
			// handle '' versus null
			if (!oldValue && !value)
				return false;
			
			return oldValue != value;
		}
		
		/**
		 * Use this as a placeholder in metadata object to indicate that multiple values exist for a metadata field.
		 */
		public static const MULTIPLE_VALUES_PLACEHOLDER:Object = {toString: lang('(No change)').toString};
    }
}
