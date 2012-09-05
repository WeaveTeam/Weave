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
	 * This is an interface for a column that is a wrapper for another column.
	 * The data should always be retrieved from the wrapper class because the getValueFromKey() function may modify the data before returning it.
	 * The purpose of this interface is to allow you to check the type of the internal column.
	 * One example usage of this is to check if the internal column is a StreamedGeometryColumn
	 * so that you can request more detail from the tile service.
	 * 
	 * @author adufilie
	 */
	public interface IColumnWrapper extends IAttributeColumn
	{
		/**
		 * @return The internal column this object is a wrapper for.
		 */
		function getInternalColumn():IAttributeColumn;
	}
}
