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

package weave.api.data
{
	/**
	 * This is a cache used to avoid making duplicate column requests.
	 * 
	 * @author adufilie
	 */
	public interface IAttributeColumnCache
	{
		/**
		 * This function will return the same IAttributeColumn for identical metadata values.
		 * Use this function to avoid downloading duplicate column data.
		 * @param dataSource The data source to request the column from if it is not already cached.
		 * @param metadata The metadata to be passed to dataSource.getAttributeColumn().
		 * @return The cached column object.
		 * @see weave.api.data.IDataSource#getAttributeColumn()
		 */
		function getColumn(dataSource:IDataSource, metadata:Object):IAttributeColumn;
	}
}
