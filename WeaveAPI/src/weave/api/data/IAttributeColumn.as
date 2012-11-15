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
	import weave.api.core.ICallbackCollection;

	/**
	 * IAttributeColumn
	 * This is an interface to a mapping of keys to data values.
	 * 
	 * @author adufilie
	 */
	public interface IAttributeColumn extends ICallbackCollection, IKeySet
	{
		/**
		 * This function gets metadata associated with the column.
		 * For standard metadata property names, refer to the ColumnMetadata class.
		 * @param propertyName The name of the metadata property to retrieve.
		 * @result The value of the specified metadata property.
		 */
		function getMetadata(propertyName:String):String;
		
		//TODO: need a function for listing available metadata property names
		
		/**
		 * This function gets a value associated with a record key.
		 * @param key A record key.
		 * @return The value associated with the given record key.
		 */
		function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*;
	}
}
