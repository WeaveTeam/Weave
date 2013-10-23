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

package weave.api.ui
{
	import mx.core.IUIComponent;
	
	import weave.api.core.ILinkableObject;

	/**
	 * This is an interface to a LinkableObject Editor
	 * 
	 * @author skolman
	 */
	public interface ILinkableObjectEditor extends IUIComponent
	{
		/**
		 * Sets the target object to be edited.
		 * @param object The target object.
		 */		
		function setTarget(object:ILinkableObject):void;
		
		/**
		 * Checks if the user has made any unsaved changes.
		 * @return true if there are unsaved changes.
		 */		
		function hasPendingChanges():Boolean;
		
		/**
		 * Applies any unsaved changes.
		 */		
		function applyChanges():void;
	}
}