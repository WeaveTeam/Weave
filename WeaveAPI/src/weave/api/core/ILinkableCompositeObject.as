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

package weave.api.core
{
	/**
	 * This is an interface to a composite object with dynamic state, meaning child objects can be dynamically added or removed.
	 * The session state for this type of object is defined as an Array of DynamicState objects.
	 * DynamicState objects are defined as having exactly three properties: objectName, className, and sessionState.
	 * 
	 * @author adufilie
	 */
	public interface ILinkableCompositeObject extends ILinkableObject
	{
		/**
		 * This gets the session state of this composite object.
		 * @return An Array of DynamicState objects which compose the session state for this object.
		 */
		function getSessionState():Array;

		/**
		 * This sets the session state of this composite object.
		 * @param newState An Array of DynamicState objects defining child ILinkableObjects.
		 * @param removeMissingDynamicObjects If true, this will remove any child objects that do not appear in the session state.
 		 */
		function setSessionState(newState:Array, removeMissingDynamicObjects:Boolean):void;
	}
}
