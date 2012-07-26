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
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	
	/**
	 * This function will remove an immediate callback from one ILinkableObject or ICallbackCollection and add it to another.
	 * There is no option provided here to call the callback immediately because typically when this function is used, the
	 * current target is stored somewhere, and errors would easily arise if the callback was called before the current target
	 * variable was updated.  It would also be inconvenient to update the current target variable prior to calling this function.
	 * @param oldTarget The old target, which may be null.
	 * @param newTarget The new target, which may be null.
	 * @param relevantContext Corresponds to the relevantContext parameter of ICallbackCollection.addImmediateCallback().
	 * @param callback Corresponds to the callback parameter of ICallbackCollection.addImmediateCallback().
	 * @return A value of true if the new target is different from the old and the callback was juggled.
	 * @see weave.api.core.ICallbackCollection#addImmediateCallback
	 */
	public function juggleImmediateCallback(oldTarget:ILinkableObject, newTarget:ILinkableObject, relevantContext:Object, callback:Function):Boolean
	{
		// do nothing if the targets are the same.
		if (oldTarget == newTarget)
			return false;
		
		// remove callback from old target
		if (oldTarget)
			WeaveAPI.SessionManager.getCallbackCollection(oldTarget).removeCallback(callback);
		
		// add callback to new target
		if (newTarget)
			WeaveAPI.SessionManager.getCallbackCollection(newTarget).addImmediateCallback(relevantContext, callback);
		
		return true;
	}
}
