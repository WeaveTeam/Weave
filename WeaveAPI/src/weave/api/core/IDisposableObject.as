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
	 * This is an interface for an object that should be cleaned up when it is no longer needed.
	 * It is recommended not to extend IDisposableObject in an interface.  Instead, make the
	 * implementation of that interface implement IDisposableObject.  To dispose of an object in
	 * Weave, disposeObjects() should be called instead of directly calling the actual
	 * object's dispose function so parent-child relationships get cleaned up automatically.
	 * 
	 * @author adufilie
	 */
	public /* final */ interface IDisposableObject
	{
		/**
		 * This function should not be called directly.  It will be called when the object is no longer needed.
		 */
		function dispose():void;
	}
}
