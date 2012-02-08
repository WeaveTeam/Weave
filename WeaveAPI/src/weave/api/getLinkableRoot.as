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

package weave.api
{
	import weave.api.core.ILinkableObject;
	
	/**
	 * This function will return the most distant ancestor of a linkable object.
	 * Note that the object will likely have no ancestors until its initialization has completed.
	 * @param linkableObject The object.
	 * @return The most distant ancestor of the object, or the object itself if it has no owner.
	 * 
	 * @author adufilie
	 */
	public function getLinkableRoot(linkableObject:ILinkableObject):ILinkableObject
	{
		var root:ILinkableObject;
		while (linkableObject)
		{
			root = linkableObject;
			linkableObject = getLinkableOwner(linkableObject);
		}
		return root;
	}
}
