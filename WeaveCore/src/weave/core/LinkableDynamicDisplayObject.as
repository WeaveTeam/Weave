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
	
	import weave.api.objectWasDisposed;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableDisplayObject;

	/**
	 * This is an generic wrapper for a dynamically created DisplayObject.
	 * 
	 * @author adufilie
	 */	
	public class LinkableDynamicDisplayObject extends LinkableDynamicObject implements ILinkableDisplayObject, IDisposableObject
	{
		public function LinkableDynamicDisplayObject()
		{
			super(DisplayObject);
			
			this.addImmediateCallback(this, firstCallback);
		}
		
		private static const objectToLDDO:Dictionary = new Dictionary(true);
		private var _parent:DisplayObjectContainer = null;
		private var _object:DisplayObject = null;
		
		private function firstCallback():void
		{
			var oldObject:DisplayObject = _object;
			var newObject:DisplayObject = target as DisplayObject;
			if (oldObject != newObject)
			{
				// make sure two instances don't try to take the same target
				var lddo:LinkableDynamicDisplayObject = objectToLDDO[newObject];
				if (lddo && !objectWasDisposed(lddo) && lddo != this)
					newObject = null;
				else
					objectToLDDO[newObject] = this;
				delete objectToLDDO[oldObject];
				
				_object = newObject;
				changeParent(oldObject, _parent, null);
				updateParentLater();
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
		override public function dispose():void
		{
			super.dispose();
			parent = null;
		}
	}
}
