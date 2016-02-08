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
	 * A column reference contains all the information required to retrieve a column of data.
	 * This interface requires a function to get a hash value for the column reference that can be used to tell if two references are equal.
	 * 
	 * @author adufilie
	 */
	public interface IColumnReference
	{
		/**
		 * This function returns the IDataSource that knows how to get the column this object refers to.
		 * @return The IDataSource that can be used to retrieve the column that this object refers to.
		 */
		function getDataSource():IDataSource;
		
		/**
		 * This function gets metadata associated with the column.
		 * Make sure to test for a null return value.
		 * For standard metadata property names, refer to the ColumnMetadata class.
		 * @return An Object mapping metadata property names to values, or null if there is no column referenced.
		 */
		function getColumnMetadata():Object;
	}
}
