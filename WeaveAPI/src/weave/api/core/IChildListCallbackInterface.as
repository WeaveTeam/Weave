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
	 * This is an interface for adding and removing callbacks that get triggered when
	 * a child object is added or removed.  The accessor functions in this interface
	 * return values that are only defined while immediate callbacks are running, not
	 * during grouped callbacks.
	 * 
	 * @author adufilie
	 */
	public interface IChildListCallbackInterface extends ICallbackInterface
	{
		/**
		 * This is the object that was added prior to running immediate callbacks.
		 */
		function get lastObjectAdded():ILinkableObject;

		/**
		 * This is the name of the object that was added prior to running immediate callbacks.
		 */
		function get lastNameAdded():String;
		
		/**
		 * This is the object that was removed prior to running immediate callbacks.
		 */
		function get lastObjectRemoved():ILinkableObject;
		
		/**
		 * This is the name of the object that was removed prior to running immediate callbacks.
		 */
		function get lastNameRemoved():String;
	}
}
