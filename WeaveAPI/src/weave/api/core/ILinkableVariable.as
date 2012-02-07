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
	 * This is an interface for a primitive ILinkableObject that implements its own session state definition.
	 * 
	 * @author adufilie
	 */
	public interface ILinkableVariable extends ILinkableObject
	{
		/**
		 * This gets the value of this linkable variable.
		 * @return The session state of this object.
		 */		
		function getSessionState():Object;

		/**
		 * This sets the value of this linkable variable.
		 * The implementation of the object determines how to handle unexpected values.
		 * @param value The new session state for this object.
		 */
		function setSessionState(value:Object):void;
	}
}
