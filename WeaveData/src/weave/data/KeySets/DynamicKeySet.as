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
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.core.LinkableDynamicObject;
	
	/**
	 * This is a wrapper for a dynamically created object implementing IKeySet.
	 * 
	 * @author adufilie
	 */
	public class DynamicKeySet extends LinkableDynamicObject implements IKeySet
	{
		public function DynamicKeySet()
		{
			super(IKeySet);
		}
		
		public function containsKey(key:IQualifiedKey):Boolean
		{
			if (internalObject == null)
				return false;
			return (internalObject as IKeySet).containsKey(key);
		}
		public function get keys():Array
		{
			if (internalObject == null)
				return [];
			return (internalObject as IKeySet).keys;
		}
	}
}
