/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Weave API.
 *
 * The Initial Developer of the Original Code is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
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
	 * The parent passed to the setParentContainer() function should be remembered and the
	 * internal DisplayObject should be added as a child of that parent if the child is
	 * created later.  The internal DisplayObject should be removed from the parent when
	 * the dispose() function is called.
	 * 
	 * @author adufilie
	 */
	public interface ILinkableDisplayObject extends ILinkableObject
	{
		/**
		 * This function will set the DisplayObjectContainer that the DisplayObject should be added to.
		 * This function should be used instead of parent.addChild() because the internal DisplayObject may change.
		 * @param parent The parent DisplayObjectContainer.
		 */
		function setParentContainer(parent:DisplayObjectContainer):void;
		
		/**
		 * This function gets the DisplayObject this objects is a wrapper for.
		 * @return The internal DisplayObject.
		 */		
		function getDisplayObject():DisplayObject;
	}
}
