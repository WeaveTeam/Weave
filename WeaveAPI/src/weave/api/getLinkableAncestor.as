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

package weave.api
{
	import weave.api.core.ILinkableObject;
	import weave.api.core.ISessionManager;
	
	/**
	 * Finds the closest ancestor of a descendant given the ancestor type.
	 * @param descendant An object with ancestors.
	 * @param ancestorType The Class definition used to determine which ancestor to return.
	 * @return The closest ancestor of the given type.
	 * @see weave.api.core.ISessionManager#getLinkableOwner()
	 */
	public function getLinkableAncestor(descendant:ILinkableObject, ancestorType:Class):ILinkableObject
	{
		var sm:ISessionManager = WeaveAPI.SessionManager;
		do {
			descendant = sm.getLinkableOwner(descendant);
		} while (descendant && !(descendant is ancestorType));
		
		return descendant;
	}
}
