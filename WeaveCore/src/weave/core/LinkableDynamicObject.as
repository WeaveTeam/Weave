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
	import flash.utils.getQualifiedClassName;
	
	import weave.api.core.DynamicState;
	import weave.api.core.IChildListCallbackInterface;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.disposeObject;
	import weave.api.getLinkableDescendants;
	import weave.api.getLinkableOwner;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;

	/**
	 * This object links to an internal ILinkableObject.
	 * The internal object can be either a local one or a global one identified by a global name.
	 * 
	 * @author adufilie
	 */
	public class LinkableDynamicObject extends CallbackCollection implements ILinkableDynamicObject
	{
		/**
		 * @param typeRestriction If specified, this will limit the type of objects that can be added to this LinkableHashMap.
		 */
		public function LinkableDynamicObject(typeRestriction:Class = null)
		{
			// set up the watcher which automatically enforces the type restriction
			_watcher = registerLinkableChild(this, new LinkableWatcher(typeRestriction));
			if (typeRestriction)
			{
				_typeRestrictionClass = typeRestriction;
				_typeRestrictionClassName = getQualifiedClassName(typeRestriction);
			}
		}
		
		// this is a constraint on the type of object that can be linked
		private var _typeRestrictionClass:Class = null;
		private var _typeRestrictionClassName:String = null;
		
		// when this is true, the linked object cannot be changed
		private var _locked:Boolean = false;
		
		// this is the local object factory
		private var _watcher:LinkableWatcher = null;
		
		private static const ARRAY_CLASS_NAME:String = 'Array';
		
		/**
		 * @inheritDoc
		 */
		public function get internalObject():ILinkableObject
		{
			return _watcher.target;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getSessionState():Array
		{
			var target:Object = _watcher.targetPath || _watcher.target;
			if (!target)
				return [];
			
			var className:String = getQualifiedClassName(target);
			var sessionState:Object = target as Array || WeaveAPI.SessionManager.getSessionState(target as ILinkableObject);
			return [DynamicState.create(null, className, sessionState)];
		}
		
		/**
		 * @inheritDoc
		 */
		public function setSessionState(newState:Array, removeMissingDynamicObjects:Boolean):void
		{
			//trace(debugId(this), removeMissingDynamicObjects ? 'diff' : 'state', Compiler.stringify(newState, null, '\t'));
			
			// special case - no change
			if (newState == null)
				return;
			
			try
			{
				// make sure callbacks only run once
				delayCallbacks();
				
				// stop if there are no items
				if (!newState.length)
				{
					if (removeMissingDynamicObjects)
						removeObject();
					return;
				}
				
				// if it's not a dynamic state array, treat it as a path
				if (!DynamicState.isDynamicStateArray(newState))
				{
					setTargetPath(newState);
					return;
				}
				
				// if there is more than one item, it's in a deprecated format
				if (newState.length > 1)
				{
					handleDeprecatedSessionState(newState, removeMissingDynamicObjects);
					return;
				}
				
				var dynamicState:Object = newState[0];
				var className:String = dynamicState[DynamicState.CLASS_NAME];
				var objectName:String = dynamicState[DynamicState.OBJECT_NAME];
				var sessionState:Object = dynamicState[DynamicState.SESSION_STATE];
				
				// backwards compatibility
				if (className == 'weave.core::GlobalObjectReference' || className == 'GlobalObjectReference')
				{
					className = ARRAY_CLASS_NAME;
					sessionState = [objectName];
				}
				
				if (className == ARRAY_CLASS_NAME)
					setTargetPath(sessionState as Array);
				else if (className == SessionManager.DIFF_DELETE)
					removeObject();
				else
				{
					setLocalObjectType(className);
					var classDef:Class = ClassUtils.getClassDefinition(className);
					if (_watcher.target is classDef)
						WeaveAPI.SessionManager.setSessionState(_watcher.target, sessionState);
				}
			}
			finally
			{
				// allow callbacks to run once now
				resumeCallbacks();
			}
		}
		
		private function setTargetPath(newPath:Array):void
		{
			// make sure we trigger callbacks if the path changes
			if (StandardLib.compare(_watcher.targetPath, newPath) != 0)
			{
				delayCallbacks();
				_watcher.targetPath = newPath;
				triggerCallbacks();
				resumeCallbacks();
			}
		}
		
		private function setLocalObjectType(className:String):void
		{
			// stop if locked
			if (_locked)
				return;
			
			delayCallbacks();
			
			setTargetPath(null);
			
			if ( ClassUtils.classImplements(className, SessionManager.ILinkableObjectQualifiedClassName)
				&& (_typeRestrictionClass == null || ClassUtils.classIs(className, _typeRestrictionClassName)) )
			{
				var classDef:Class = ClassUtils.getClassDefinition(className);
				var target:Object = _watcher.target;
				if (!target || target.constructor != classDef)
					_watcher.target = new classDef();
			}
			else
			{
				_watcher.target = null;
			}
			
			resumeCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function requestLocalObject(objectType:Class, lockObject:Boolean):*
		{
			delayCallbacks();
			
			if (objectType)
				setLocalObjectType(getQualifiedClassName(objectType));
			else
				removeObject();
			
			if (lockObject)
				_locked = true;
			
			resumeCallbacks();
			
			if (objectType)
				return _watcher.target as objectType;
			return _watcher.target;
		}
		
		/**
		 * @inheritDoc
		 */
		public function requestGlobalObject(name:String, objectType:Class, lockObject:Boolean):*
		{
			if (!name)
				return requestLocalObject(objectType, lockObject);
			
			if (!_locked)
			{
				delayCallbacks();
				
				setTargetPath([name]);
				WeaveAPI.globalHashMap.requestObject(name, objectType, lockObject);
				if (lockObject)
					_locked = true;
				
				resumeCallbacks();
			}
			
			if (objectType)
				return _watcher.target as objectType;
			return _watcher.target;
		}
		
		/**
		 * @inheritDoc
		 */
		public function requestLocalObjectCopy(objectToCopy:ILinkableObject):void
		{
			delayCallbacks(); // make sure callbacks only trigger once
			var classDef:Class = Object(objectToCopy).constructor//ClassUtils.getClassDefinition(getQualifiedClassName(objectToCopy));
			var object:ILinkableObject = requestLocalObject(classDef, false);
			if (object != null && objectToCopy != null)
			{
				var state:Object = WeaveAPI.SessionManager.getSessionState(objectToCopy);
				WeaveAPI.SessionManager.setSessionState(object, state, true);
			}
			resumeCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function get globalName():String
		{
			var path:Array = _watcher.targetPath;
			if (path && path.length == 1)
				return path[0];
			return null;
		}

		/**
		 * @inheritDoc
		 */
		public function set globalName(newGlobalName:String):void
		{
			if (_locked)
				return;
			
			// change empty string to null
			if (!newGlobalName)
				newGlobalName = null;
			
			var oldGlobalName:String = globalName;
			if (oldGlobalName == newGlobalName)
				return;
			
			delayCallbacks();
			
			if (newGlobalName == null)
			{
				// unlink from global object and copy session state into a local object
				requestLocalObjectCopy(internalObject);
			}
			else
			{
				// when switcing from a local object to a global one that doesn't exist yet, copy the local object
				if (_watcher.target && !_watcher.targetPath && !WeaveAPI.globalHashMap.getObject(newGlobalName))
					WeaveAPI.globalHashMap.requestObjectCopy(newGlobalName, internalObject);
				
				// link to new global name
				setTargetPath([newGlobalName]);
			}
			
			resumeCallbacks();
		}

		/**
		 * Handles backwards compatibility.
		 * @param newState An Array with two or more items.
		 * @param removeMissingDynamicObjects true when applying an absolute session state, false if applying a diff
		 * @return An Array with one item.
		 */
		private function handleDeprecatedSessionState(newState:Array, removeMissingDynamicObjects:Boolean):void
		{
			// Loop backwards because when diffs are combined, most recent entries
			// are added last and we want to use the most recently applied diff.
			var i:int = newState.length;
			while (i--)
			{
				var item:Object = newState[i];
				
				// handle item as a global Array
				if (item is String)
					item = DynamicState.create(null, ARRAY_CLASS_NAME, [item]);
				
				// stop if it's not a typed state
				if (!DynamicState.isDynamicState(item))
					break;
				
				if (item[DynamicState.CLASS_NAME] == SessionManager.DIFF_DELETE)
				{
					// remove object if name matches
					if (globalName == (item[DynamicState.OBJECT_NAME] || null)) // convert empty string to null
						removeObject();
				}
				else
				{
					// use the first item we see that isn't a deleted object
					setSessionState([item], removeMissingDynamicObjects);
					return;
				}
			}
			if (removeMissingDynamicObjects)
				removeObject();
		}
		
		/**
		 * @inheritDoc
		 */
		public function lock():void
		{
			_locked = true;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get locked():Boolean
		{
			return _locked;
		}

		/**
		 * @inheritDoc
		 */
		public function removeObject():void
		{
			if (_locked)
				return;
			
			delayCallbacks();
			
			setTargetPath(null);
			_watcher.target = null;
			
			resumeCallbacks();
		}
	}
}
