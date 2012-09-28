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
	 * This is an interface to an object that decides which IQualifiedKey objects are included in a set or not.
	 * 
	 * @author adufilie
	 */
	public interface IKeyFilter extends ILinkableObject
	{
		/**
		 * This function tests if a IQualifiedKey object is contained in this IKeySet.
		 * @param key A IQualifiedKey object.
		 * @return true if the IQualifiedKey object is contained in the IKeySet.
		 */
		function containsKey(key:IQualifiedKey):Boolean;
	}
}
