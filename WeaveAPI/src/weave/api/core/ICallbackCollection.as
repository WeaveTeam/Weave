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
	 * This is an interface for adding and removing callback functions, and triggering them.
	 * 
	 * @author adufilie
	 */
	public interface ICallbackCollection extends ICallbackInterface, ILinkableObject
	{
		/**
		 * This will trigger every callback function to be called with their saved arguments.
		 * If the delay count is greater than zero, the callbacks will not be called immediately.
		 */
		function triggerCallbacks():void;

		/**
		 * While this is true, it means the delay count is greater than zero and the effects of
		 * triggerCallbacks() are delayed until resumeCallbacks() is called to reduce the delay count.
		 */
		function get callbacksAreDelayed():Boolean;
		
		/**
		 * This will increase the delay count by 1.  To decrease the delay count, use resumeCallbacks().
		 * As long as the delay count is greater than zero, effects of triggerCallbacks() will be delayed.
		 */
		function delayCallbacks():void;

		/**
		 * This will decrease the delay count if it is greater than zero.
		 * If triggerCallbacks() was called while the delay count was greater than zero, immediate callbacks will be called now.
		 * @param undoAllDelays If this is set to true, the delay count will be set to zero.  Otherwise, the delay count will be decreased by one.
		 */
		function resumeCallbacks(undoAllDelays:Boolean = false):void;
	}
}
