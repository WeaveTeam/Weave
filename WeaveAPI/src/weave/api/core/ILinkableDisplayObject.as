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

package weave.api.core
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	/**
	 * This is an interface for an ILinkableObject that is a wrapper for a DisplayObject.
	 * 
	 * Implementations of this interface should do the following:
	 * Callbacks should be triggered when the internal DisplayObject is created or removed.
	 * The parent passed to the parent setter should be remembered and the
	 * internal DisplayObject should be added as a child of that parent if the child is
	 * created later.  The internal DisplayObject should be removed from the parent when
	 * the dispose() function is called.
	 * 
	 * @author adufilie
	 */
	public interface ILinkableDisplayObject extends ILinkableObject
	{
		/**
		 * This will set the DisplayObjectContainer that the DisplayObject should be added to.
		 * This should be used instead of parent.addChild() because the internal DisplayObject may change.
		 * @param parent The parent DisplayObjectContainer.
		 */
		function set parent(parent:DisplayObjectContainer):void;
		
		/**
		 * This is the DisplayObject for which this object is a wrapper.
		 * @return The internal DisplayObject.
		 */		
		function get object():DisplayObject;
	}
}
