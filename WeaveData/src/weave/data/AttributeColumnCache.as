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

package weave.data
{
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IAttributeColumnCache;
	import weave.api.data.IDataSource;
	import weave.compiler.Compiler;
	import weave.utils.Dictionary2D;
	import weave.utils.WeakReference;
	
	/**
	 * @inheritDoc
	 */
	public class AttributeColumnCache implements IAttributeColumnCache
	{
		/**
		 * The metadata property name used to identify a column appearing in WeaveAPI.globalHashMap.
		 */
		public static const GLOBAL_COLUMN_METADATA_NAME:String = 'name';

		/**
		 * @inheritDoc
		 */
		public function getColumn(dataSource:IDataSource, metadata:Object):IAttributeColumn
		{
			// null means no column
			if (metadata === null)
				return null;
			
			// special case - if dataSource is null, use WeaveAPI.globalHashMap
			if (dataSource == null)
			{
				if (!metadata)
					return null;
				var name:String;
				if (typeof metadata == 'object')
					name = metadata[GLOBAL_COLUMN_METADATA_NAME];
				else
					name = String(metadata);
				return WeaveAPI.globalHashMap.getObject(name) as IAttributeColumn;
			}

			// Get the column pointer associated with the hash value.
			var hashCode:String = Compiler.stringify(metadata);
			var weakRef:WeakReference = d2d_dataSource_metadataHash.get(dataSource, hashCode) as WeakReference;
			if (weakRef != null && weakRef.value != null)
			{
				if (WeaveAPI.SessionManager.objectWasDisposed(weakRef.value))
					d2d_dataSource_metadataHash.remove(dataSource, hashCode);
				else
					return weakRef.value as IAttributeColumn;
			}
			
			// If no column is associated with this hash value, request the
			// column from its data source and save the column pointer.
			var column:IAttributeColumn = dataSource.getAttributeColumn(metadata);
			d2d_dataSource_metadataHash.set(dataSource, hashCode, new WeakReference(column));

			return column;
		}
		
		private const d2d_dataSource_metadataHash:Dictionary2D = new Dictionary2D(true, true);
	}
}
