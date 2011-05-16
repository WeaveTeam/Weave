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

package weave.data.ColumnReferences
{
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataSource;
	import weave.api.getCallbackCollection;
	import weave.api.getSessionState;
	import weave.api.newLinkableChild;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableString;
	
	/**
	 * This is a base class for implementing an IColumnReference.
	 * This class should be extended and include all the information required to retrieve a column of data.
	 * 
	 * The implementation of getHashCode() uses the session state of this object to generate a hash code.
	 * When you extend AbstractColumnReference, you need to make sure that the session state contains all
	 * the properties required to differentiate one column reference from another.
	 * 
	 * @author adufilie
	 */
	public class AbstractColumnReference implements IColumnReference
	{
		public function AbstractColumnReference()
		{
			// Whenever any property of the column reference changes, the hash value needs to be updated.
			getCallbackCollection(this).addImmediateCallback(this, invalidateHash, null, true);
		}
		
		/**
		 * This is the name of an IDataSource in the top level session state.
		 */
		public const dataSourceName:LinkableString = newLinkableChild(this, LinkableString);

		/**
		 * This function returns the IDataSource that knows how to get the column this object refers to.
		 * @return The IDataSource that can be used to retrieve the column that this object refers to.
		 */		
		public function getDataSource():IDataSource
		{
			return LinkableDynamicObject.globalHashMap.getObject(dataSourceName.value) as IDataSource;
		}

		/**
		 * This is the hash code used to compare two IColumnReference objects for equality.
		 */
		public function getHashCode():String
		{
			if (_hash == null)
				_hash = _hashPrefix + ';' + ObjectUtil.toString(getSessionState(this));
			return _hash;
		}

		/**
		 * This function will invalidate the hash value of the IColumnReference object.
		 */
		protected function invalidateHash():void
		{
			_hash = null;
		}
		
		protected var _hash:String; // used internally to cache the current hash code
		
		protected var _hashPrefix:String = getQualifiedClassName(this); // prefix used in hash code
	}
}
