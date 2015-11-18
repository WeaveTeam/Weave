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

package weave.core
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import weave.api.getCallbackCollection;
	import weave.api.objectWasDisposed;
	import weave.api.registerDisposableChild;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableDisplayObject;
	import weave.api.core.ILinkableVariable;
	import weave.compiler.StandardLib;

	/**
	 * This is an generic wrapper for a dynamically created DisplayObject.
	 * 
	 * @author adufilie
	 */	
	public class LinkableDynamicDisplayObject implements ILinkableVariable, ILinkableDisplayObject, IDisposableObject
	{
		public function LinkableDynamicDisplayObject()
		{
		}
		
		private static const objectToLDDO:Dictionary = new Dictionary(true);
		private var _parent:DisplayObjectContainer = null;
		private var _object:DisplayObject = null;
		private var _watcher:LinkableWatcher = registerDisposableChild(this, new LinkableWatcher(DisplayObject, handleWatcher));
		
		public function getSessionState():Object
		{
			return _watcher.targetPath;
		}
		
		public function setSessionState(state:Object):void
		{
			if (StandardLib.compare(state, _watcher.targetPath))
			{
				var cc:ICallbackCollection = getCallbackCollection(this);
				cc.delayCallbacks();
				_watcher.targetPath = state as Array;
				cc.triggerCallbacks();
				cc.resumeCallbacks();
			}
		}
		
		private function handleWatcher():void
		{
			var oldObject:DisplayObject = _object;
			var newObject:DisplayObject = _watcher.target as DisplayObject;
			
			// make sure two instances don't try to take the same target
			if (oldObject != newObject)
			{
				var lddo:LinkableDynamicDisplayObject = objectToLDDO[newObject];
				if (lddo && !objectWasDisposed(lddo) && lddo != this)
					newObject = null;
				else
					objectToLDDO[newObject] = this;
				delete objectToLDDO[oldObject];
			}
			
			if (oldObject != newObject)
			{
				_object = newObject;
				changeParent(oldObject, _parent, null);
				updateParentLater();
				
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		private function updateParentLater():void
		{
			if (_object)
				WeaveAPI.StageUtils.callLater(this, updateParentNow);
		}
		
		private function updateParentNow():void
		{
			changeParent(_object, null, _parent);
		}
		
		private static function changeParent(child:DisplayObject, oldParent:DisplayObjectContainer, newParent:DisplayObjectContainer):void
		{
			if (!child || oldParent == newParent)
				return;
			if (oldParent && oldParent == child.parent)
				UIUtils.spark_removeChild(oldParent, child);
			if (newParent && newParent != child.parent)
				UIUtils.spark_addChild(newParent, child);
		}
		
		/**
		 * @inheritDoc
		 */
		public function get object():DisplayObject
		{
			return _object;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set parent(newParent:DisplayObjectContainer):void
		{
			changeParent(_object, _parent, null);
			_parent = newParent;
			updateParentLater();
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			parent = null;
		}
	}
}
