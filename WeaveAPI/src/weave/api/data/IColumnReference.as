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
	import weave.api.core.ILinkableObject;

	/**
	 * A column reference contains all the information required to retrieve a column of data.
	 * This interface requires a function to get a hash value for the column reference that can be used to tell if two references are equal.
	 * 
	 * @author adufilie
	 */
	public interface IColumnReference extends ILinkableObject
	{
		/**
		 * This function returns the IDataSource that knows how to get the column this object refers to.
		 * @return The IDataSource that can be used to retrieve the column that this object refers to.
		 */
		function getDataSource():IDataSource;
		
		/**
		 * This function gets a hash code that can be used to compare two IColumnReference objects for equality.
		 * @return The hash code for comparing two IColumnReferences.
		 */
		function getHashCode():String;
		
		/**
		 * This function gets metadata associated with the column.
		 * For standard metadata property names, refer to the AttributeColumnMetadata class.
		 * @param propertyName The name of the metadata property to retrieve.
		 * @result The value of the specified metadata property.
		 */
		function getMetadata(propertyName:String):String;
	}
}
