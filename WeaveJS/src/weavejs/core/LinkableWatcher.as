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
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.IDisposableObject;
	import weavejs.api.core.ILinkableCompositeObject;
	import weavejs.api.core.ILinkableDynamicObject;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.core.ISessionManager;
	import weavejs.compiler.StandardLib;
	import weavejs.utils.Dictionary2D;
	import weavejs.utils.JS;
	
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
				Weave.getCallbacks(this).addImmediateCallback(null, immediateCallback);
			
			if (groupedCallback != null)
				Weave.getCallbacks(this).addGroupedCallback(null, groupedCallback);
		}
		
		protected var _typeRestriction:Class;
		private var _target:ILinkableObject; // the current target or ancestor of the to-be-target
		private var _foundTarget:Boolean = true; // false when _target is not the desired target
		protected var _targetPath:Array; // the path that is being watched
		private var _pathDependencies:Dictionary2D = new Dictionary2D(); // (ILinkableCompositeObject, String) -> child object
		
		/**
		 * This is the linkable object currently being watched.
		 * Setting this will unset the targetPath.
		 */		
		public function get target():ILinkableObject
		{
			return _foundTarget ? _target : null;
		}
		public function set target(newTarget:ILinkableObject):void
		{
			var cc:ICallbackCollection = Weave.getCallbacks(this);
			cc.delayCallbacks();
			targetPath = null;
			internalSetTarget(newTarget);
			cc.resumeCallbacks();
		}
		
		/**
		 * This sets the new target to be watched without resetting targetPath.
		 * Callbacks will be triggered immediately if the new target is different from the old one.
		 */
		protected function internalSetTarget(newTarget:ILinkableObject):void
		{
			if (_foundTarget && _typeRestriction)
				newTarget = JS.AS(newTarget, _typeRestriction) as ILinkableObject;
			
			// do nothing if the targets are the same.
			if (_target == newTarget)
				return;
			
			// unlink from old target
			if (_target)
			{
				Weave.getCallbacks(_target).removeCallback(_handleTargetTrigger);
				Weave.getCallbacks(_target).removeCallback(_handleTargetDispose);
				
				// if we own the previous target, dispose it
				if (Weave.getOwner(_target) == this)
					Weave.dispose(_target);
				else
					(WeaveAPI.SessionManager as SessionManager).unregisterLinkableChild(this, _target);
			}
			
			_target = newTarget;
			
			// link to new target
			if (_target)
			{
				// we want to register the target as a linkable child (for busy status)
				Weave.linkableChild(this, _target);
				// we don't want the target triggering our callbacks directly
				Weave.getCallbacks(_target).removeCallback(Weave.getCallbacks(this).triggerCallbacks);
				Weave.getCallbacks(_target).addImmediateCallback(this, _handleTargetTrigger, false, true);
				// we need to know when the target is disposed
				Weave.getCallbacks(_target).addDisposeCallback(this, _handleTargetDispose);
			}
			
			if (_foundTarget)
				_handleTargetTrigger();
		}
		
		private function _handleTargetTrigger():void
		{
			if (_foundTarget)
				Weave.getCallbacks(this).triggerCallbacks();
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
				Weave.getCallbacks(this).triggerCallbacks();
			}
		}
		
		/**
		 * This is the path that is currently being watched for linkable object targets.
		 */
		public function get targetPath():Array
		{
			return _targetPath ? _targetPath.concat() : null;
		}
		
		/**
		 * This will set a path which should be watched for new targets.
		 * Callbacks will be triggered immediately if the path changes or points to a new target.
		 */
		public function set targetPath(path:Array):void
		{
			// do not allow watching the globalHashMap
			if (path && path.length == 0)
				path = null;
			if (StandardLib.compare(_targetPath, path) != 0)
			{
				var cc:ICallbackCollection = Weave.getCallbacks(this);
				cc.delayCallbacks();
				
				resetPathDependencies();
				_targetPath = path;
				handlePath();
				cc.triggerCallbacks();
				
				cc.resumeCallbacks();
			}
		}
		
		private function handlePath():void
		{
			if (!_targetPath)
			{
				_foundTarget = true;
				internalSetTarget(null);
				return;
			}
			
			// traverse the path, finding ILinkableDynamicObject path dependencies along the way
			var node:ILinkableObject = Weave.getRoot(this);
			var subPath:Array = [];
			for each (var name:* in _targetPath)
			{
				if (node is ILinkableCompositeObject)
					addPathDependency(node as ILinkableCompositeObject, name);
				
				subPath[0] = name;
				var child:ILinkableObject = Weave.followPath(node, subPath);
				if (child)
				{
					node = child;
				}
				else
				{
					// the path points to an object that doesn't exist yet
					if (node is ILinkableHashMap)
					{
						// watching childListCallbacks instead of the hash map accomplishes two things:
						// 1. eliminate unnecessary calls to handlePath()
						// 2. avoid watching the root hash map (and registering the root as a child of the watcher)
						node = (node as ILinkableHashMap).childListCallbacks;
					}
					if (node is ILinkableDynamicObject)
					{
						// path dependency code will detect changes to this node, so we don't need to set the target
						node = null;
					}
					
					var lostTarget:Boolean = _foundTarget;
					_foundTarget = false;
					
					internalSetTarget(node);
					
					// must trigger here when we lose the target because internalSetTarget() won't trigger when _foundTarget is false
					if (lostTarget)
						Weave.getCallbacks(this).triggerCallbacks();
					
					return;
				}
			}
			
			// we found a desired target if there is no type restriction or the object fits the restriction
			_foundTarget = !_typeRestriction || JS.IS(node, _typeRestriction);
			internalSetTarget(node);
		}
		
		private function addPathDependency(parent:ILinkableCompositeObject, pathElement:Object):void
		{
			// if parent is an ILinkableHashMap and pathElement is a String, we don't need to add the dependency
			var lhm:ILinkableHashMap = parent as ILinkableHashMap;
			if (lhm && pathElement is String)
				return;
			
			var ldo:ILinkableDynamicObject = parent as ILinkableDynamicObject;
			if (ldo)
				pathElement = null;
			
			if (!_pathDependencies.get(parent, pathElement))
			{
				var child:ILinkableObject = Weave.followPath(parent, [pathElement]);
				_pathDependencies.set(parent, pathElement, child);
				var dependencyCallbacks:ICallbackCollection = getDependencyCallbacks(parent);
				dependencyCallbacks.addImmediateCallback(this, handlePathDependencies);
				dependencyCallbacks.addDisposeCallback(this, handlePathDependencies);
			}
		}
		
		private function getDependencyCallbacks(parent:ILinkableObject):ICallbackCollection
		{
			var lhm:ILinkableHashMap = parent as ILinkableHashMap;
			if (lhm)
				return lhm.childListCallbacks;
			return Weave.getCallbacks(parent);
		}
		
		private function handlePathDependencies():void
		{
			_pathDependencies.forEach(handlePathDependencies_each, this);
		}
		private function handlePathDependencies_each(parent:ILinkableObject, pathElement:String, child:ILinkableObject):Boolean
		{
			var newChild:ILinkableObject = Weave.followPath(parent, [pathElement]);
			if (Weave.wasDisposed(parent) || child != newChild)
			{
				resetPathDependencies();
				handlePath();
				return true; // stop iterating
			}
			return false; // continue iterating
		}
		
		private function resetPathDependencies():void
		{
			_pathDependencies.map.forEach(resetPathDependencies_each, this);
			_pathDependencies = new Dictionary2D();
		}
		private function resetPathDependencies_each(map_child:Object, parent:ILinkableObject):void
		{
			getDependencyCallbacks(parent).removeCallback(handlePathDependencies);
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			_targetPath = null;
			_target = null;
			// everything else will be cleaned up automatically
		}
		
		/*
			// JavaScript test code for path dependency case
			var lhm = weave.path('lhm').remove().request('LinkableHashMap');
			
			var a = lhm.push('a').request('LinkableDynamicObject').state(lhm.getPath('b', null));
			
			a.addCallback(function () {
			if (a.getType(null))
			console.log('a.getState(null): ', JSON.stringify(a.getState(null)));
			else
			console.log('a has no internal object');
			}, false, true);
			
			var b = lhm.push('b').request('LinkableDynamicObject').state(lhm.getPath('c'));
			
			// a has no internal object
			
			var c = lhm.push('c').request('LinkableDynamicObject').request(null, 'LinkableString').state(null, 'c value');
			
			// a.getState(null): []
			// a.getState(null): [{"className":"weave.core::LinkableString","objectName":null,"sessionState":null}]
			// a.getState(null): [{"className":"weave.core::LinkableString","objectName":null,"sessionState":"c value"}]
			
			b.remove(null);
			
			// a has no internal object
			
			b.request(null, 'LinkableString').state(null, 'b value');
			
			// a.getState(null): null
			// a.getState(null): "b value"
		*/
	}
}
