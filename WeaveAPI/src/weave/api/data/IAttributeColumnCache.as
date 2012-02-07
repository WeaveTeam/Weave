/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
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
	 * This is a cache that maps IColumnReference hash values to IAttributeColumns.
	 * The getAttributeColumn() function is used to avoid making duplicate column requests.
	 * 
	 * @author adufilie
	 */
	public interface IAttributeColumnCache
	{
		/**
		 * This function will return the same IAttributeColumn for two IColumnReference objects having the same hash value.
		 * Use this function to avoid duplicate data downloads.
		 * @param columnReference A reference to a column.
		 * @return The column that the reference refers to.
		 */
		function getColumn(columnReference:IColumnReference):IAttributeColumn;
	}
}
