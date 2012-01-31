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
	 * A Qualified Key contains a namespace (keyType) and a local name within that namespace.
	 * 
	 * @author adufilie
	 */
	public interface IQualifiedKey
	{
		// This is the namespace of the IQualifiedKey. Read-only.
		function get keyType():String;

		// This is local record identifier in the namespace of the IQualifiedKey. Read-only.
		function get localName():String;
	}
}
