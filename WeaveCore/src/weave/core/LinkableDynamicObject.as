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
	
	import weave.api.WeaveAPI;
	import weave.api.core.IChildListCallbackInterface;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.disposeObjects;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableOwner;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;

	use namespace weave_internal;
	
	/**
	 * This object links to an internal ILinkableObject.
	 * The internal object can be either a local one or a global one identified by a global name.
	 * 
	 * @author adufilie
	 */
	public class LinkableDynamicObject extends CallbackCollection implements ILinkableDynamicObject
	{
		public function LinkableDynamicObject(typeRestriction:Class = null)
		{
			// set up the local hash map which automatically enforces the type restriction
			_localHashMap = registerDisposableChild(this, new LinkableHashMap(typeRestriction)); // won't trigger callbacks
			_localHashMap.childListCallbacks.addImmediateCallback(this, childListCallback); // handle when internal object is added or removed
			if (typeRestriction)
			{
				_typeRestrictionClass = typeRestriction;
				_typeRestrictionClassName = getQualifiedClassName(typeRestriction);
			}
		}
		
		/**
		 * This function creates a local object using the given Class definition if it doesn't already exist.
		 * If the existing object is locked, this function does nothing.
		 * @param objectType The Class used to initialize the object.
		 * @param lockObject If this is true, this object will be locked so the internal object cannot be removed or replaced.
		 * @return The local object of the specified type, or null if the object could not be created.
		 */
		public function requestLocalObject(objectType:Class, lockObject:Boolean):*
		{
			initInternalObject(null, objectType, lockObject);
			if (objectType != null)
				return _internalObject as objectType;
			return _internalObject;
		}
		
		/**
		 * This function creates a global object using the given Class definition if it doesn't already exist.
		 * If the object gets disposed of later, this object will still be linked to the global name.
		 * If the existing object under the specified name is locked, this function does nothing.
		 * @param name The name of the global object to link to.
		 * @param objectType The Class used to initialize the object.
		 * @param lockObject If this is true, this object will be locked so the internal object cannot be removed or replaced.
		 * @return The global object of the specified name and type, or null if the object could not be created.
		 */
		public function requestGlobalObject(name:String, objectType:Class, lockObject:Boolean):*
		{
			initInternalObject(name, objectType, lockObject);
			if (objectType != null)
				return _internalObject as objectType;
			return _internalObject;
		}
		
		/**
		 * This function will copy the session state of an ILinkableObject to a new local internalObject of the same type.
		 * @param objectToCopy An object to copy the session state from.
		 */
		public function requestLocalObjectCopy(objectToCopy:ILinkableObject):void
		{
			delayCallbacks();
			var classDef:Class = ClassUtils.getClassDefinition(getQualifiedClassName(objectToCopy));
			var object:ILinkableObject = requestLocalObject(classDef, false);
			if (object != null && objectToCopy != null)
			{
				var state:Object = WeaveAPI.SessionManager.getSessionState(objectToCopy);
				WeaveAPI.SessionManager.setSessionState(object, state, true);
			}
			resumeCallbacks();
		}
		
		/**
		 * This is the name of the linked global object.
		 */
		public function get globalName():String
		{
			return _globalName;
		}

		/**
		 * This function will change the internalObject if the new globalName is different.
		 * If a new global name is given, the session state of the new global object will take precedence.
		 * @param newGlobalName This is the name of the global object to link to, or null to unlink from the current global object.
		 */
		public function set globalName(newGlobalName:String):void
		{
			if (_globalName == newGlobalName)
				return;
			
			if (newGlobalName == null)
			{
				// unlink from global object and copy session state into a local object
				requestLocalObjectCopy(internalObject);
			}
			else if (getLinkableOwner(this) != globalHashMap) // don't allow globalName on global objects
			{
				// if there is no global object of this name, create it now
				if (globalHashMap.getObject(newGlobalName) == null)
					globalHashMap.requestObjectCopy(newGlobalName, internalObject);
				// link to new global name
				initInternalObject(newGlobalName, null);
			}
		}

		/**
		 * This is the local or global internal object.
		 */
		public function get internalObject():ILinkableObject
		{
			return _internalObject;
		}
		
		/**
		 * This gets the session state of this object.
		 * @return An Array of DynamicState objects which compose the session state for this object.
		 */
		public function getSessionState():Array
		{
			// handle global link
			if (_globalName != null)
				return [ new DynamicState(_globalName, GlobalObjectReference.qualifiedClassName, null) ];
			
			// handle local link or no link
			var state:Array = _localHashMap.getSessionState();
			if (state.length == 1)
				(state[0] as DynamicState).objectName = null;
			return state;
		}

		/**
		 * This sets the session state of this object.
		 * @param newStateArray An Array of DynamicState objects containing the new values and types for child objects.
		 * @param removeMissingDynamicObjects If true, this will remove any child objects that do not appear in the session state.
 		 */
		public function setSessionState(newState:Array, removeMissingDynamicObjects:Boolean):void
		{
			var dynamicState:DynamicState = null;
			if (newState && newState.length > 0)
				dynamicState = DynamicState.cast(newState[0]);

			if (dynamicState == null)
			{
				if (removeMissingDynamicObjects)
					removeObject();
				return;
			}

			try
			{
				// make sure callbacks only run once
				delayCallbacks();

				var objectName:String = dynamicState.objectName;
				if (objectName == null)
				{
					initInternalObject(null, dynamicState.className); // init local object
					if (_internalObject != null)
						WeaveAPI.SessionManager.setSessionState(_internalObject, dynamicState.sessionState, removeMissingDynamicObjects);
				}
				else if (getLinkableOwner(this) != globalHashMap) // don't allow globalName on global objects
				{
					initInternalObject(objectName, null); // link to global object
				}
			}
			finally
			{
				// allow callbacks to run once now
				resumeCallbacks();
			}
		}
		
		/**
		 * @private
		 */
		private function initInternalObject(newGlobalName:String, newClassNameOrDef:Object, lockObject:Boolean = false):void
		{
			// stop if locked
			if (_locked)
				return;
			
			// lock if necessary
			if (lockObject)
				_locked = true;
			
			// to avoid possible problems with String casting, don't support empty string
			if (newGlobalName == '')
				newGlobalName = null;

			// make sure callbacks only run once when initializing the internal object
			delayCallbacks();
			
			// handle both class definitions and class names
			var newClassDef:Class = newClassNameOrDef as Class || ClassUtils.getClassDefinition(String(newClassNameOrDef));
			
			if (newGlobalName == null) // local object
			{
				// initialize the local object -- this may trigger childListCallback()
				var result:ILinkableObject = _localHashMap.requestObject(LOCAL_OBJECT_NAME, newClassDef, lockObject);
				// if the object fails to be created, remove any existing object (may be a global one).
				if (!result)
					removeObject();
			}
			else // global object
			{
				// initialize global object if class definition is specified
				if (newClassDef != null && newClassDef != GlobalObjectReference)
					_globalHashMap.requestObject(newGlobalName, newClassDef, lockObject);
				
				// if the new global name is different from the current one, create a new link
				if (_globalName != newGlobalName)
				{
					// remove any existing link
					removeObject();
					// save the new global name
					_globalName = newGlobalName;
					// get the Array of links to the global object
					var links:Array = _globalNameToLinksMap[newGlobalName] as Array;
					// initialize the Array if necessary
					if (links == null)
						_globalNameToLinksMap[newGlobalName] = links = [];
					// create a link to the new global name
					links.push(this);
					// save a pointer to the global object (as long as it fits the type restriction) and add a callback
					_internalObject = _globalHashMap.getObject(_globalName);
					if (_typeRestrictionClass != null)
						_internalObject = (_internalObject as _typeRestrictionClass) as ILinkableObject;
					if (_internalObject != null)
						registerLinkableChild(this, _internalObject);
					
					// since the global name has changed, we need to make sure the callbacks run now
					triggerCallbacks();
				}
			}

			// allow callbacks to run once now
			resumeCallbacks();
		}

		/**
		 * This function manages pointers to linked global objects when those objects get added or removed from the global object map.
		 */
		private static function handleGlobalListChange():void
		{
			var name:String;
			var links:Array;
			var link:LinkableDynamicObject;
			var linksThatChanged:Array = [];

			// handle a global object being created
			var newObject:ILinkableObject = _globalHashMap.childListCallbacks.lastObjectAdded;
			if (newObject != null)
			{
				// point existing links having this global name to the newly created object
				name = _globalHashMap.childListCallbacks.lastNameAdded;
				links = _globalNameToLinksMap[name] as Array;
				if (links != null)
				{
					for each (link in links)
					{
						// sanity checks
						if (link._globalName != name)
							throw new Error("LinkableDynamicObject did not link to expected global name.");
						if (link._internalObject != null)
							throw new Error("LinkableDynamicObject was not pointing to a null global object as expected.");
						
						// enforce each link's type restriction separately
						if (link._typeRestrictionClass == null || newObject is link._typeRestrictionClass)
						{
							link._internalObject = registerLinkableChild(link, newObject);
							linksThatChanged.push(link);
						}
					}
				}
			}

			// handle a global object being removed
			var oldObject:ILinkableObject = _globalHashMap.childListCallbacks.lastObjectRemoved;
			if (oldObject != null)
			{
				// point existing links having this global name to null
				name = _globalHashMap.childListCallbacks.lastNameRemoved;
				links = _globalNameToLinksMap[name] as Array;
				if (links != null)
				{
					for each (link in links)
					{
						// sanity check
						if (link._globalName != name)
							throw new Error("LinkableDynamicObject did not link to expected global name.");
						
						if (link._internalObject != null)
						{
							// sanity checks
							if (link._locked)
								throw new Error("LinkableDynamicObject was locked while referenced global object was disposed of.");
							if (link._internalObject != oldObject)
								throw new Error("LinkableDynamicObject was pointing to the wrong global object.");
							
							// clean up pointers
							link._internalObject = null;
							linksThatChanged.push(link);
						}
					}
				}
			}

			// run callbacks for each link after all links have been updated.
			for each (link in linksThatChanged)
				link.triggerCallbacks();
		}

		/**
		 * This function will call lockObject() on the ILinkableHashMap that contains the internal object.
		 * This object will also be locked so that no new objects can be requested.
		 */
		public function lock():void
		{
			_locked = true;
		}

		/**
		 * This function gets the internal object, whether local or global.
		 * @return The internal, dynamically created object.
		 */
		public function getObject():Object
		{
			return internalObject;
		}

		/**
		 * If the internal object is local, this will remove the object (unless it is locked).
		 * If the internal object is global, this will remove the link to it.
		 */
		public function removeObject():void
		{
			if (_locked)
				return;
			
//			if (_globalName != null)
//				trace("remove link:", _globalName, getQualifiedClassName(internalObject));
			
			if (_globalName == null)
			{
				// remove the local object -- this may trigger childListCallback()
				_localHashMap.removeObject(LOCAL_OBJECT_NAME);
			}
			else
			{
				// undo registerLinkableChild()
				var object:ILinkableObject = _internalObject;
				if (object)
					(WeaveAPI.SessionManager as SessionManager).unregisterLinkableChild(this, object);
	
				var name:String = _globalName;
				// clean up variables
				_globalName = null;
				_internalObject = null;
				// remove this link to the object.
				var links:Array = _globalNameToLinksMap[name];
				links.splice(links.indexOf(this), 1);
				if (links.length == 0)
				{
					delete _globalNameToLinksMap[name];
				}
				
				// notify the listeners
				triggerCallbacks();
			}
		}

		
		/**
		 * This function will be called when the _localHashMap runs its child list callbacks.
		 * This callback is needed in case _localHashMap is manipulated directly via getLinkableOwner().
		 */		
		private function childListCallback():void
		{
			var childListCallbacks:IChildListCallbackInterface = _localHashMap.childListCallbacks;
			if (childListCallbacks.lastNameAdded)
			{
				if (childListCallbacks.lastNameAdded != LOCAL_OBJECT_NAME)
				{
					// don't allow other object names
					_localHashMap.removeObject(childListCallbacks.lastNameAdded);
				}
				else if (childListCallbacks.lastObjectAdded != _internalObject)
				{
					// handle new local object
					// if the current object is global, remove the link
					if (_globalName != null)
						removeObject();
					_internalObject = registerLinkableChild(this, childListCallbacks.lastObjectAdded);
					triggerCallbacks();
				}
			}
			if (childListCallbacks.lastNameRemoved == LOCAL_OBJECT_NAME)
			{
				// handle local object removed
				_internalObject = null;
				triggerCallbacks();
			}
		}

		/**
		 * This function gets called by SessionManager.dispose().
		 */
		override public function dispose():void
		{
			super.dispose();
			_locked = false;
			removeObject();
			disposeObjects(_localHashMap); // just in case this function is called directly
			_locked = true;
		}
		
		// this is a constraint on the type of object that can be linked
		private var _typeRestrictionClass:Class = null;
		private var _typeRestrictionClassName:String = null;
		// when this is true, the linked object cannot be changed
		private var _locked:Boolean = false;
		// this is the linked internal object
		private var _internalObject:ILinkableObject = null;

		// this is the local object factory
		private var _localHashMap:ILinkableHashMap = null;
		// this is the name of the local object created inside _localHashMap
		private static const LOCAL_OBJECT_NAME:String = 'localObject';

		// this is the name of the linked global object
		private var _globalName:String = null;
		// this is the global object factory
		private static var _globalHashMap:ILinkableHashMap = null;
		// this maps a global name to an Array of LinkableDynamicObjects
		private static const _globalNameToLinksMap:Object = new Object();
		
		/**
		 * This is the mapping from global names to objects.
		 */
		public static function get globalHashMap():ILinkableHashMap
		{
			if (!_globalHashMap)
			{
				_globalHashMap = new LinkableHashMap();
				_globalHashMap.childListCallbacks.addImmediateCallback(null, handleGlobalListChange);
			}
			return _globalHashMap;
		}
	}
}
