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
		
		private var _parent:DisplayObjectContainer = null;
		private var _object:DisplayObject = null;
		
		private function firstCallback():void
		{
			var oldObject:DisplayObject = _object;
			var newObject:DisplayObject = target as DisplayObject;
			if (oldObject != newObject)
			{
				_object = newObject;
				changeParent(oldObject, _parent, null);
				changeParent(newObject, null, _parent);
			}
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
			var oldParent:DisplayObjectContainer = _parent;
			_parent = newParent;
			changeParent(object, oldParent, newParent);
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
