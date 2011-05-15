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

package org.oicweave.data
{
	import org.oicweave.api.WeaveAPI;
	import org.oicweave.api.data.IAttributeColumn;
	import org.oicweave.api.data.IAttributeColumnCache;
	import org.oicweave.api.data.IColumnReference;
	import org.oicweave.api.data.IDataSource;
	import org.oicweave.core.SessionManager;
	import org.oicweave.data.DataSources.MultiDataSource;
	import org.oicweave.primitives.WeakReference;
	
	/**
	 * This is a cache that maps IColumnReference hash values to IAttributeColumns.
	 * The getAttributeColumn() function is used to avoid making duplicate column requests.
	 * 
	 * @author adufilie
	 */
	public class AttributeColumnCache implements IAttributeColumnCache
	{
		/**
		 * This function will return the same IAttributeColumn for two IColumnReference objects having the same hash value.
		 * Use this function to avoid duplicate data downloads.
		 * @param columnReference A reference to a column.
		 * @return The column that the reference refers to.
		 */
		public function getColumn(columnReference:IColumnReference):IAttributeColumn
		{
			if (columnReference == null)
				return null;
			var dataSource:IDataSource = columnReference.getDataSource();
			if (dataSource == null)
			{
				// HACK
				return MultiDataSource.instance.getAttributeColumn(columnReference);
			}

			// Get the column pointer associated with the hash value.
			var weakRef:WeakReference = _hashToWeakColumnRefMap[columnReference.getHashCode()] as WeakReference;
			if (weakRef != null && weakRef.value != null && !(WeaveAPI.SessionManager as SessionManager).objectWasDisposed(weakRef.value))
				return weakRef.value as IAttributeColumn;
			
			// If no column is associated with this hash value, request the
			// column from its data source and save the column pointer.
			var column:IAttributeColumn = dataSource.getAttributeColumn(columnReference);
			// backwards compatibility: get hash value again in case getAttributeColumn() modified it
			_hashToWeakColumnRefMap[columnReference.getHashCode()] = new WeakReference(column);

			return column;
		}

		/**
		 * This object maps a hash value from an IColumnReference to a WeakReference that points to an IAttributeColumn.
		 */
		private const _hashToWeakColumnRefMap:Object = new Object();
	}
}
