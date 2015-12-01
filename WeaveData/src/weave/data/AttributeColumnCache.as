/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.data
{
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IAttributeColumnCache;
	import weave.api.data.IDataSource;
	import weave.compiler.Compiler;
	import weave.primitives.Dictionary2D;
	import weave.utils.WeakReference;
	
	/**
	 * @inheritDoc
	 */
	public class AttributeColumnCache implements IAttributeColumnCache
	{
		/**
		 * @inheritDoc
		 */
		public function getColumn(dataSource:IDataSource, metadata:Object):IAttributeColumn
		{
			// null means no column
			if (dataSource == null || metadata == null)
				return null;

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
