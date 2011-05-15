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

package org.oicweave.data.KeySets
{
	import org.oicweave.api.data.IDynamicKeyFilter;
	import org.oicweave.api.data.IKeyFilter;
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.core.LinkableDynamicObject;
	
	/**
	 * This is a wrapper for a dynamically created object implementing IKeyFilter.
	 * 
	 * @author adufilie
	 */
	public class DynamicKeyFilter extends LinkableDynamicObject implements IDynamicKeyFilter
	{
		public function DynamicKeyFilter()
		{
			super(IKeyFilter);
		}
		
		public function containsKey(key:IQualifiedKey):Boolean
		{
			if (internalObject == null)
				return false;
			return (internalObject as IKeyFilter).containsKey(key);
		}
	}
}
