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

package weavejs.core
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.ui.IEditorManager;
	import weavejs.util.JS;

	/**
	 * Manages implementations of ILinkableObjectEditor.
	 */
	public class EditorManager implements IEditorManager
	{
		private const labels:Object = new JS.WeakMap();
		
		/**
		 * @inheritDoc
		 */
		public function setLabel(object:ILinkableObject, label:String):void
		{
			labels.set(object, label);
			WeaveAPI.SessionManager.getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function getLabel(object:ILinkableObject):String
		{
			return labels.get(object);
		}
	}
}
