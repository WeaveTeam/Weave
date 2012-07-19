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
	 * This function is used to detect if callbacks of a linkable object were triggered since the last time this function
	 * was called with the same parameters, likely by the observer.  Note that once this function returns true, subsequent calls will
	 * return false until the callbacks are triggered again, unless clearChangedNow is set to false.  It may be a good idea to specify
	 * a private object as the observer so no other code can call detectLinkableObjectChange with the same observer and linkableObject
	 * parameters.
	 * @param observer The object that is observing the change.
	 * @param linkableObject The object that is being observed.
	 * @param moreLinkableObjects More objects that are being observed.
	 * @return A value of true if the callbacks for any of the objects have triggered since the last time this function was called
	 *         with the same observer for any of the specified linkable objects.
	 */
	public function detectLinkableObjectChange(observer:Object, linkableObject:ILinkableObject, ...moreLinkableObjects):Boolean
	{
		var changeDetected:Boolean = false;
		moreLinkableObjects.unshift(linkableObject);
		// it's important not to short-circuit with a boolean OR (||) because we need to clear the 'changed' flag on each object.
		for each (linkableObject in moreLinkableObjects)
			if (Internal.detectLinkableObjectChange(observer, linkableObject, true)) // clear 'changed' flag
				changeDetected = true;
		return changeDetected;
	}
}

import flash.utils.Dictionary;

import weave.api.WeaveAPI;
import weave.api.core.ILinkableObject;

internal class Internal
{
	/**
	 * This function is used to detect if callbacks of a linkable object were triggered since the last time detectLinkableObjectChange
	 * was called with the same parameters, likely by the observer.  Note that once this function returns true, subsequent calls will
	 * return false until the callbacks are triggered again, unless clearChangedNow is set to false.  It may be a good idea to specify
	 * a private object as the observer so no other code can call detectLinkableObjectChange with the same observer and linkableObject
	 * parameters.
	 * @param observer The object that is observing the change.
	 * @param linkableObject The object that is being observed.
	 * @param clearChangedNow If this is true, the trigger counter will be reset to the current value now so that this function will
	 *        return false if called again with the same parameters before the next time the linkable object triggers its callbacks.
	 * @return A value of true if the callbacks for the linkableObject have triggered since the last time this function was called
	 *         with the same observer and linkableObject parameters.
	 */
	public static function detectLinkableObjectChange(observer:Object, linkableObject:ILinkableObject, clearChangedNow:Boolean = true):Boolean
	{
		if (!_triggerCounterMap[linkableObject])
			_triggerCounterMap[linkableObject] = new Dictionary(false); // weakKeys=false to allow observers to be Functions
		
		var previousCount:* = _triggerCounterMap[linkableObject][observer]; // untyped to handle undefined value
		var newCount:uint = WeaveAPI.SessionManager.getCallbackCollection(linkableObject).triggerCounter;
		if (previousCount !== newCount) // !== avoids casting to handle 0 !== undefined
		{
			if (clearChangedNow)
				_triggerCounterMap[linkableObject][observer] = newCount;
			return true;
		}
		return false;
	}
	
	/**
	 * This is a two-dimensional dictionary, where _triggerCounterMap[linkableObject][observer]
	 * equals the previous triggerCounter value from linkableObject observed by the observer.
	 */		
	private static const _triggerCounterMap:Dictionary = new Dictionary(true);
}
