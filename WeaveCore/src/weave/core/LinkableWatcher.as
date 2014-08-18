/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.core
{
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.compiler.StandardLib;
	
	/**
	 * This is used to dynamically attach a set of callbacks to different targets.
	 * The callbacks of the LinkableWatcher will be triggered automatically when the
	 * target triggers callbacks, changes, becomes null or is disposed.
	 * @author adufilie
	 */
	public class LinkableWatcher implements ILinkableObject, IDisposableObject
	{
		/**
		 * Instead of calling this constructor directly, consider using one of the global functions
		 * newLinkableChild() or newDisposableChild() to make sure the watcher will get disposed automatically.
		 * @param typeRestriction Optionally restricts which type of targets this watcher accepts.
		 * @param immediateCallback A function to add as an immediate callback.
		 * @param groupedCallback A function to add as a grouped callback.
		 * @see weave.api.core.newLinkableChild()
		 * @see weave.api.core.newDisposableChild()
		 */
		public function LinkableWatcher(typeRestriction:Class = null, immediateCallback:Function = null, groupedCallback:Function = null)
		{
			_typeRestriction = typeRestriction;
			
			if (immediateCallback != null)
				WeaveAPI.SessionManager.getCallbackCollection(this).addImmediateCallback(null, immediateCallback);
			
			if (groupedCallback != null)
				WeaveAPI.SessionManager.getCallbackCollection(this).addGroupedCallback(null, groupedCallback);
		}
		
		private var _typeRestriction:Class;
		private var _target:ILinkableObject; // the current target or ancestor of the to-be-target
		private var _foundTarget:Boolean = true; // false when _target is not the desired target
		private var _targetPath:Array; // the path that is being watched
		
		/**
		 * This is the linkable object currently being watched.
		 */		
		public function get target():ILinkableObject
		{
			return _foundTarget ? _target : null;
		}
		
		/**
		 * This sets the new target to which should be watched.
		 * Callbacks will be triggered immediately if the new target is different from the old one.
		 */
		public function set target(newTarget:ILinkableObject):void
		{
			if (_foundTarget && _typeRestriction)
				newTarget = newTarget as _typeRestriction as ILinkableObject;
			
			// do nothing if the targets are the same.
			if (_target == newTarget)
				return;
			
			var sm:SessionManager = WeaveAPI.SessionManager as SessionManager;
			
			// unlink from old target
			if (_target)
			{
				sm.getCallbackCollection(_target).removeCallback(_handleTargetTrigger);
				sm.getCallbackCollection(_target).removeCallback(_handleTargetDispose);
				
				// if we own the previous target, dispose it
				if (sm.getLinkableOwner(_target) == this)
					sm.disposeObject(_target);
				else
					sm.unregisterLinkableChild(this, _target);
			}
			
			_target = newTarget;
			
			// link to new target
			if (_target)
			{
				// we want to register the target as a linkable child (for busy status)
				sm.registerLinkableChild(this, _target);
				// we don't want the target triggering our callbacks directly
				sm.getCallbackCollection(_target).removeCallback(sm.getCallbackCollection(this).triggerCallbacks);
				sm.getCallbackCollection(_target).addImmediateCallback(this, _handleTargetTrigger, false, true);
				// we need to know when the target is disposed
				sm.getCallbackCollection(_target).addDisposeCallback(this, _handleTargetDispose);
			}
			
			if (_foundTarget)
				_handleTargetTrigger();
		}
		
		private function _handleTargetTrigger():void
		{
			if (_foundTarget)
				WeaveAPI.SessionManager.getCallbackCollection(this).triggerCallbacks();
			else
				handlePath();
		}
		
		private function _handleTargetDispose():void
		{
			if (_targetPath)
			{
				handlePath();
			}
			else
			{
				_target = null;
				WeaveAPI.SessionManager.getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		/**
		 * This will set a path which should be watched for new targets.
		 * Callbacks will be triggered immediately if the path points to a new target.
		 */
		public function set targetPath(path:Array):void
		{
			// do not allow watching the globalHashMap
			if (path && path.length == 0)
				path = null;
			if (StandardLib.arrayCompare(_targetPath, path) != 0)
			{
				_targetPath = path;
				handlePath();
			}
		}
		
		private function handlePath():void
		{
			if (!_targetPath)
			{
				_foundTarget = true;
				target = null;
				return;
			}
			
			var sm:SessionManager = WeaveAPI.SessionManager as SessionManager;
			var obj:ILinkableObject = sm.getObject(WeaveAPI.globalHashMap, _targetPath);
			if (obj)
			{
				// we found a desired target if there is no type restriction or the object fits the restriction
				_foundTarget = !_typeRestriction || obj is _typeRestriction;
			}
			else
			{
				_foundTarget = false;
				var path:Array = _targetPath.concat();
				while (!obj && path.length)
				{
					path.pop();
					obj = sm.getObject(WeaveAPI.globalHashMap, path);
				}
				
				if (obj is ILinkableHashMap)
				{
					// watching childListCallbacks instead of the hash map accomplishes two things:
					// 1. eliminate unnecessary calls to handlePath()
					// 2. avoid watching the root hash map (and registering the root as a child of the watcher)
					obj = (obj as ILinkableHashMap).childListCallbacks;
				}
			}
			target = obj;
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			_target = null; // everything else will be cleaned up automatically
		}
	}
}
