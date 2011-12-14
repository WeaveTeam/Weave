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
	/**
	 * This is an interface for adding and removing callback functions.
	 * 
	 * @author adufilie
	 */
	public interface ICallbackInterface
	{
		/**
		 * This function will add a callback using the given function and parameters.
		 * Any callback previously added for the same function will be overwritten.
		 * The callback function will not be called recursively as a result of it triggering callbacks recursively.
		 * @param relevantContext If this is not null, then the callback will be removed when the relevantContext object is disposed via SessionManager.dispose().  This parameter is typically a 'this' pointer.
		 * @param callback The function to call when callbacks are triggered.
		 * @param parameters An array of parameters that will be used as parameters to the callback function.
		 * @param runCallbackNow If this is set to true, the callback will be run immediately after it is added.
		 * @param alwaysCallLast If this is set to true, the callback will be always be called after any callbacks that were added with alwaysCallLast=false.  Use this to establish the desired child-to-parent triggering order.
		 */
		function addImmediateCallback(relevantContext:Object, callback:Function, parameters:Array = null, runCallbackNow:Boolean = false, alwaysCallLast:Boolean = false):void;
		
		/**
		 * This function will add a callback that will be delayed except during a scheduled time each frame.  Grouped callbacks use a
		 * central trigger list, meaning that if multiple CallbackCollections trigger the same grouped callback before the scheduled
		 * time, it will behave as if it were only triggered once.  Adding a grouped callback to a CallbackCollection will replace
		 * any previous effects of addImmediateCallback() or addGroupedCallback() made to the same CallbackCollection.  The callback function
		 * will not be called recursively as a result of it triggering callbacks recursively.
		 * @param relevantContext If this is not null, then the callback will be removed when the relevantContext object is disposed via SessionManager.dispose().  This parameter is typically a 'this' pointer.
		 * @param groupedCallback The callback function that will only be allowed to run during a scheduled time each frame.  It must not require any parameters.
		 * @param triggerCallbackNow If this is set to true, the callback will be triggered to run during the scheduled time after it is added.
		 */
		function addGroupedCallback(relevantContext:Object, groupedCallback:Function, triggerCallbackNow:Boolean = false):void;

		/**
		 * This function will remove a callback that was previously added.
		 * @param callback The function to remove from the list of callbacks.
		 */
		function removeCallback(callback:Function):void;
		
		/**
		 * This counter gets incremented at the time that callbacks are triggered and before they are actually called.
		 * It is necessary in some situations to check this counter to determine if cached data should be used.
		 */
		function get triggerCounter():uint;
	}
}
