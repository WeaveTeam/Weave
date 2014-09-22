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
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableObject;
	import weave.api.core.ISessionManager;

	/**
	 * This object links to an internal ILinkableObject.
	 * The internal object can be either a local one or a global one identified by a global name.
	 * 
	 * @author adufilie
	 */
	public class LinkableDynamicObject extends LinkableWatcher implements ILinkableDynamicObject, ICallbackCollection
	{
		/**
		 * @param typeRestriction If specified, this will limit the type of objects that can be added to this LinkableHashMap.
		 */
		public function LinkableDynamicObject(typeRestriction:Class = null)
		{
			super(typeRestriction);
			if (typeRestriction)
				_typeRestrictionClassName = getQualifiedClassName(typeRestriction);
		}
		
		// the callback collection for this object
		private const cc:CallbackCollection = WeaveAPI.SessionManager.newDisposableChild(this, CallbackCollection);
		
		// this is a constraint on the type of object that can be linked
		private var _typeRestrictionClassName:String = null;
		
		// when this is true, the linked object cannot be changed
		private var _locked:Boolean = false;
		
		private static const ARRAY_CLASS_NAME:String = 'Array';
		
		/**
		 * @inheritDoc
		 */
		public function get internalObject():ILinkableObject
		{
			return target;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getSessionState():Array
		{
			var obj:Object = targetPath || target;
			if (!obj)
				return [];
			
			var className:String = getQualifiedClassName(obj);
			var sessionState:Object = obj as Array || WeaveAPI.SessionManager.getSessionState(obj as ILinkableObject);
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
				cc.delayCallbacks();
				
				// stop if there are no items
				if (!newState.length)
				{
					if (removeMissingDynamicObjects)
						target = null;
					return;
				}
				
				// if it's not a dynamic state array, treat it as a path
				if (!DynamicState.isDynamicStateArray(newState))
				{
					targetPath = newState;
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
					targetPath = sessionState as Array;
				else if (className == SessionManager.DIFF_DELETE)
					target = null;
				else
				{
					setLocalObjectType(className);
					var classDef:Class = ClassUtils.getClassDefinition(className);
					if (target is classDef)
						WeaveAPI.SessionManager.setSessionState(target, sessionState);
				}
			}
			finally
			{
				// allow callbacks to run once now
				cc.resumeCallbacks();
			}
		}
		
		override public function set target(newTarget:ILinkableObject):void
		{
			if (_locked)
				return;
			
			if (!newTarget)
			{
				super.target = null;
				return;
			}
			
			cc.delayCallbacks();
			
			// if the target can be found by a path, use the path
			var sm:ISessionManager = WeaveAPI.SessionManager;
			var path:Array = sm.getPath(WeaveAPI.globalHashMap, newTarget);
			if (path)
			{
				targetPath = path;
			}
			else
			{
				// it's ok to assign a local object that we own or that doesn't have an owner yet
				// otherwise, unset the target
				var owner:ILinkableObject = sm.getLinkableOwner(newTarget);
				if (owner === this || !owner)
					super.target = newTarget;
				else
					super.target = null;
			}
			
			cc.resumeCallbacks();
		}
		
		override protected function internalSetTarget(newTarget:ILinkableObject):void
		{
			// don't allow recursive linking
			if (newTarget === this || WeaveAPI.SessionManager.getLinkableDescendants(newTarget, LinkableDynamicObject).indexOf(this) >= 0)
				newTarget = null;
			
			super.internalSetTarget(newTarget);
		}
		
		override public function set targetPath(path:Array):void
		{
			if (_locked)
				return;
			super.targetPath = path;
		}
		
		private function setLocalObjectType(className:String):void
		{
			// stop if locked
			if (_locked)
				return;
			
			cc.delayCallbacks();
			
			targetPath = null;
			
			if ( ClassUtils.classImplements(className, SessionManager.ILinkableObjectQualifiedClassName)
				&& (_typeRestriction == null || ClassUtils.classIs(className, _typeRestrictionClassName)) )
			{
				var classDef:Class = ClassUtils.getClassDefinition(className);
				var obj:Object = target;
				if (!obj || obj.constructor != classDef)
					super.target = new classDef();
			}
			else
			{
				super.target = null;
			}
			
			cc.resumeCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function requestLocalObject(objectType:Class, lockObject:Boolean):*
		{
			cc.delayCallbacks();
			
			if (objectType)
				setLocalObjectType(getQualifiedClassName(objectType));
			else
				target = null;
			
			if (lockObject)
				_locked = true;
			
			cc.resumeCallbacks();
			
			if (objectType)
				return target as objectType;
			return target;
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
				cc.delayCallbacks();
				
				targetPath = [name];
				WeaveAPI.globalHashMap.requestObject(name, objectType, lockObject);
				if (lockObject)
					_locked = true;
				
				cc.resumeCallbacks();
			}
			
			if (objectType)
				return target as objectType;
			return target;
		}
		
		/**
		 * @inheritDoc
		 */
		public function requestLocalObjectCopy(objectToCopy:ILinkableObject):void
		{
			cc.delayCallbacks(); // make sure callbacks only trigger once
			var classDef:Class = Object(objectToCopy).constructor//ClassUtils.getClassDefinition(getQualifiedClassName(objectToCopy));
			var object:ILinkableObject = requestLocalObject(classDef, false);
			if (object != null && objectToCopy != null)
			{
				var state:Object = WeaveAPI.SessionManager.getSessionState(objectToCopy);
				WeaveAPI.SessionManager.setSessionState(object, state, true);
			}
			cc.resumeCallbacks();
		}
		
		/**
		 * This is the name of the linked global object, or null if the internal object is local.
		 */
		public function get globalName():String
		{
			if (_targetPath && _targetPath.length == 1)
				return _targetPath[0];
			return null;
		}

		/**
		 * This function will change the internalObject if the new globalName is different, unless this object is locked.
		 * If a new global name is given, the session state of the new global object will take precedence.
		 * @param newGlobalName This is the name of the global object to link to, or null to unlink from the current global object.
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
			
			cc.delayCallbacks();
			
			if (newGlobalName == null)
			{
				// unlink from global object and copy session state into a local object
				requestLocalObjectCopy(internalObject);
			}
			else
			{
				// when switcing from a local object to a global one that doesn't exist yet, copy the local object
				if (target && !targetPath && !WeaveAPI.globalHashMap.getObject(newGlobalName))
					WeaveAPI.globalHashMap.requestObjectCopy(newGlobalName, internalObject);
				
				// link to new global name
				targetPath = [newGlobalName];
			}
			
			cc.resumeCallbacks();
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
						target = null;
				}
				else
				{
					// use the first item we see that isn't a deleted object
					setSessionState([item], removeMissingDynamicObjects);
					return;
				}
			}
			if (removeMissingDynamicObjects)
				target = null;
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
			if (!_locked)
				super.target = null;
		}
		
		override public function dispose():void
		{
			// explicitly dispose the CallbackCollection before anything else
			cc.dispose();
			super.dispose();
		}
		
		////////////////////////////////////////////////////////////////////////
		// ICallbackCollection interface included for backwards compatibility
		/** @inheritDoc */ public function addImmediateCallback(relevantContext:Object, callback:Function, runCallbackNow:Boolean = false, alwaysCallLast:Boolean = false):void { cc.addImmediateCallback(relevantContext, callback, runCallbackNow, alwaysCallLast); }
		/** @inheritDoc */ public function addGroupedCallback(relevantContext:Object, groupedCallback:Function, triggerCallbackNow:Boolean = false):void { cc.addGroupedCallback(relevantContext, groupedCallback, triggerCallbackNow); }
		/** @inheritDoc */ public function addDisposeCallback(relevantContext:Object, callback:Function):void { cc.addDisposeCallback(relevantContext, callback); }
		/** @inheritDoc */ public function removeCallback(callback:Function):void { cc.removeCallback(callback); }
		/** @inheritDoc */ public function get triggerCounter():uint { return cc.triggerCounter; }
		/** @inheritDoc */ public function triggerCallbacks():void { cc.triggerCallbacks(); }
		/** @inheritDoc */ public function get callbacksAreDelayed():Boolean { return cc.callbacksAreDelayed; }
		/** @inheritDoc */ public function delayCallbacks():void { cc.delayCallbacks(); }
		/** @inheritDoc */ public function resumeCallbacks():void { cc.resumeCallbacks(); }
	}
}
