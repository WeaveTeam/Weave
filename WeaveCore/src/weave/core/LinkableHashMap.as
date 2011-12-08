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
	import flash.debugger.enterDebugger;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import weave.api.WeaveAPI;
	import weave.api.copySessionState;
	import weave.api.core.IChildListCallbackInterface;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.disposeObjects;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	
	use namespace weave_internal;
	
	/**
	 * This contains an ordered list of name-to-object mappings.
	 * 
	 * @author adufilie
	 */
	public class LinkableHashMap extends CallbackCollection implements ILinkableHashMap
	{
		/**
		 * @param typeRestriction If specified, this will limit the type of objects that can be added to this LinkableHashMap.
		 */
		public function LinkableHashMap(typeRestriction:Class = null)
		{
			if (typeRestriction != null)
			{
				_typeRestriction = typeRestriction;
				_typeRestrictionClassName = getQualifiedClassName(typeRestriction);
			}
		}
		private const _childListCallbacks:ChildListCallbackInterface = newLinkableChild(this, ChildListCallbackInterface);
		private const _orderedNames:Array = []; // an ordered list of names appearing in _nameToObjectMap
		private const _nameToObjectMap:Object = {}; // maps an identifying name to an object
		private const _objectToNameMap:Dictionary = new Dictionary(true); // maps an object to an identifying name
		private const _nameIsLocked:Object = {}; // maps an identifying name to a value of true if that name is locked.
		private const _previousNameMap:Object = {}; // maps a previously used name to a value of true.  used when generating unique names.
		private var _hashMapIsLocked:Boolean = false; // true if the LinkableHashMap is locked.
		private var _typeRestriction:Class = null; // restricts the type of object that can be stored
		private var _typeRestrictionClassName:String = null; // qualified class name of _typeRestriction
		
		
		/**
		 * This is an interface for adding and removing callbacks that will get triggered immediately
		 * when an object is added or removed.
		 * @return An interface for adding callbacks that get triggered when the list of child objects changes.
		 */
		public function get childListCallbacks():IChildListCallbackInterface
		{
			return _childListCallbacks;
		}

		/**
		 * @param filter If specified, names of objects that are not of this type will be filtered out.
		 * @return A copy of the ordered list of names of objects contained in this LinkableHashMap.
		 */
		public function getNames(filter:Class = null):Array
		{
			var result:Array = [];
			for (var i:int = 0; i < _orderedNames.length; i++)
			{
				var name:String = _orderedNames[i];
				if (filter == null || _nameToObjectMap[name] is filter)
					result.push(name);
			}
			return result;
		}
		/**
		 * @param filter If specified, objects that are not of this type will be filtered out.
		 * @return An ordered Array of objects that correspond to the names returned by getNames(filter).
		 */
		public function getObjects(filter:Class = null):Array
		{
			var result:Array = [];
			for (var i:int = 0; i < _orderedNames.length; i++)
			{
				var name:String = _orderedNames[i];
				var object:ILinkableObject = _nameToObjectMap[name] as ILinkableObject;
				if (filter == null || object is filter)
					result.push(object);
			}
			return result;
		}
		/**
		 * @param name The identifying name to associate with an object.
		 * @return The object associated with the given name.
		 */
		public function getObject(name:String):ILinkableObject
		{
			return _nameToObjectMap[name] as ILinkableObject;
		}
		/**
		 * @param object An object contained in this LinkableHashMap.
		 * @return The name associated with the object, or null if the object was not found. 
		 */
		public function getName(object:ILinkableObject):String
		{
			return _objectToNameMap[object] as String;
		}
		/**
		 * This will reorder the names returned by getNames() and the objects returned by getObjects().
		 * Any names appearing in newOrder that do not appear in getNames() will be ignored.
		 * Callbacks will be called if the new child order differs from the old order.
		 * @param newOrder The new desired ordering of names and their corresponding objects.
		 */
		public function setNameOrder(newOrder:Array):void
		{
			if (_hashMapIsLocked)
				return;
			
			var changeDetected:Boolean = false;
			var name:String;
			var i:int;
			var originalNameCount:int = _orderedNames.length; // remembers how many names existed before appending
			var haveSeen:Object = {}; // to remember which names have been seen in newOrder
			// append each name in newOrder to the end of _orderedNames
			for (i = 0; i < newOrder.length; i++)
			{
				name = newOrder[i];
				// ignore bogus names and append each name only once.
				if (_nameToObjectMap[name] == undefined || haveSeen[name] != undefined)
					continue;
				haveSeen[name] = true; // remember that this name was appended to the end of the list
				_orderedNames.push(name); // add this name to the end of the list
			}
			// Now compare the ordered appended items to the end of the original list.
			// If the order differs, set _nameOrderChanged to true.
			// Meanwhile, set old name entries to null so they will be removed in the next pass.
			var appendedCount:int = _orderedNames.length - originalNameCount;
			for (i = 0; i < appendedCount; i++)
			{
				var newIndex:int = originalNameCount + i;
				var oldIndex:int = _orderedNames.indexOf(_orderedNames[newIndex]);
				if (newIndex - oldIndex != appendedCount)
					changeDetected = true;
				_orderedNames[oldIndex] = null;
			}
			// remove array items that have been set to null
			for (i = _orderedNames.length - 1; i >= 0; i--)
				if (_orderedNames[i] == null)
					_orderedNames.splice(i, 1);
			// if the name order changed, run child list callbacks
			if (changeDetected)
				_childListCallbacks.runCallbacks(null, null, null);
		}
		/**
		 * This function creates an object in the hash map if it doesn't already exist.
		 * If there is an existing object associated with the specified name, it will be kept if it
		 * is the specified type, or replaced with a new instance of the specified type if it is not.
		 * @param name The identifying name of a new or existing object.
		 * @param classDef The Class of the desired object type.
		 * @param lockObject If this is true, the object will be locked in place under the specified name.
		 * @return The object under the requested name of the requested type, or null if an error occurred.
		 */
		public function requestObject(name:String, classDef:Class, lockObject:Boolean):*
		{
			if (classDef == null)
			{
				if (lockObject)
					this.lockObject(name);
				return getObject(name);
			}
			return initObjectByClassName(name, getQualifiedClassName(classDef), lockObject) as classDef;
		}
		
		/**
		 * This function will copy the session state of an ILinkableObject to a new object under the given name in this LinkableHashMap.
		 * @param newName A name for the object to be initialized in this LinkableHashMap.
		 * @param objectToCopy An object to copy the session state from.
		 * @return The new object of the same type, or null if an error occurred.
		 */
		public function requestObjectCopy(name:String, objectToCopy:ILinkableObject):ILinkableObject
		{
			if (objectToCopy == null)
				return null;
			
			delayCallbacks(); // make sure callbacks only trigger once
			var className:String = getQualifiedClassName(objectToCopy);
			var classDef:Class = ClassUtils.getClassDefinition(className);
			var object:ILinkableObject = requestObject(name, classDef, false);
			if (object != null)
				copySessionState(objectToCopy, object);
			resumeCallbacks();
			
			return object;
		}
		
		/**
		 * If there is an existing object associated with the specified name, it will be kept if it
		 * is the specified type, or replaced with a new instance of the specified type if it is not.
		 * @param name The identifying name of a new or existing object.  If this is null, a new one will be generated.
		 * @param className The qualified class name of the desired object type.
		 * @param lockObject If this is set to true, lockObject() will be called on the given name.
		 * @return The object associated with the given name, or null if an error occurred.
		 */
		private function initObjectByClassName(name:String, className:String, lockObject:Boolean = false):ILinkableObject
		{
			// do nothing if locked or className is null
			if (!_hashMapIsLocked && className != null)
			{
				// if no name is specified, generate a unique one now.
				if (name == null)
				{
					if (className.indexOf("::") >= 0)
						name = generateUniqueName(className.split("::")[1]);
					else
						name = generateUniqueName(className);
				}
				if ( ClassUtils.classImplements(className, SessionManager.ILinkableObjectQualifiedClassName)
					&& (_typeRestriction == null || ClassUtils.classIs(className, _typeRestrictionClassName)) )
				{
					try
					{
						// If this name is not associated with an object of the specified type,
						// associate the name with a new object of the specified type.
						var classDef:Class = ClassUtils.getClassDefinition(className) as Class;
						if (!(_nameToObjectMap[name] is classDef))
							createAndSaveNewObject(name, classDef);
						if (lockObject)
							this.lockObject(name);
					}
					catch (e:Error)
					{
						reportError(e);
						enterDebugger();
					}
				}
				else
				{
					removeObject(name);
				}
			}
			return _nameToObjectMap[name] as ILinkableObject;
		}
		/**
		 * (private)
		 * @param name The identifying name to associate with a new object.
		 * @param classDef The Class definition used to instantiate a new object.
		 */
	    private function createAndSaveNewObject(name:String, classDef:Class):void
	    {
	    	if (_nameIsLocked[name] != undefined)
	    		return;

			// remove any object currently using this name
			removeObject(name);
			// create a new object
			var object:ILinkableObject = new classDef();
			// register the object as a child of this LinkableHashMap
			registerLinkableChild(this, object);
			// save the name-object mappings
			_nameToObjectMap[name] = object;
			_objectToNameMap[object] = name;
			// add the name to the end of _orderedNames
			_orderedNames.push(name);
			// remember that this name was used.
			_previousNameMap[name] = true;

			// make sure the callback variables signal that the object was added
			_childListCallbacks.runCallbacks(name, object, null);
	    }
		/**
		 * This function will lock an object in place for a given identifying name.
		 * If there is no object using the specified name, this function will have no effect.
		 * @param name The identifying name of an object to lock in place.
		 */
	    private function lockObject(name:String):void
	    {
	    	if (name != null && _nameToObjectMap[name] != null)
		    	_nameIsLocked[name] = true;
	    }
		/**
		 * This function will call lockObject() on all objects in this LinkableHashMap.
		 * The LinkableHashMap will also be locked so that no new objects can be initialized.
		 */
		public function lock():void
		{
			_hashMapIsLocked = true;
			for (var name:String in _nameToObjectMap)
				_nameIsLocked[name] = true;
		}
		/**
		 * @param name The identifying name of an object previously saved with setObject().
		 * @see weave.api.core.ILinkableHashMap#removeObject
		 */
		public function removeObject(name:String):void
		{
			if (_nameIsLocked[name] != undefined)
				return;
			
			var object:ILinkableObject = _nameToObjectMap[name] as ILinkableObject;
			if (object == null)
				return; // do nothing if the name isn't mapped to an object.
			
			//trace(LinkableHashMap, "removeObject",name,object);
			// remove name & associated object
			delete _nameToObjectMap[name];
			delete _objectToNameMap[object];
			var index:int = _orderedNames.indexOf(name);
			_orderedNames.splice(index, 1);

			// make sure the callback variables signal that the object was removed
			_childListCallbacks.runCallbacks(name, null, object);

			// dispose of the object AFTER the callbacks know that the object was removed
			disposeObjects(object);
		}

		/**
		 * This function attempts to removes all objects from this LinkableHashMap.
		 * Any objects that are locked will remain.
		 */
		public function removeAllObjects():void
		{
			for each (var name:String in getNames())
				removeObject(name);
		}
		
		/**
		 * This function removes all objects from this LinkableHashMap.
		 */
		override public function dispose():void
		{
			super.dispose();
			
			for each (var name:String in _orderedNames.concat()) // iterate over a copy of the list
			{
				_nameIsLocked[name] = undefined; // make sure removeObject() will carry out its action
				removeObject(name);
			}
		}

		/**
		 * This will generate a new name for an object that is different from all the names of objects previously used in this LinkableHashMap.
		 * @param baseName The name to start with.  If the name is already in use, an integer will be appended to create a unique name.
		 */
		public function generateUniqueName(baseName:String):String
		{
			var count:int = 1;
			var name:String = baseName;
			while (_previousNameMap[name] != undefined)
				name = baseName + (++count);
			return name;
		}

		/**
		 * @return An Array of DynamicState objects which compose the session state for this object.
		 */
		public function getSessionState():Array
		{
			var result:Array = new Array(_orderedNames.length);
			for (var i:int = 0; i < _orderedNames.length; i++)
			{
				var name:String = _orderedNames[i];
				var object:ILinkableObject = _nameToObjectMap[name];
				result[i] = new DynamicState(
						name,
						getQualifiedClassName(object),
						WeaveAPI.SessionManager.getSessionState(object)
					);
			}
			//trace(LinkableHashMap, "getSessionState LinkableHashMap " + ObjectUtil.toString(result));
			return result;
		}
		
		/**
		 * This function will update the list of child objects based on an absolute or incremental session state.
		 * @param newState An Array of child name Strings or DynamicState objects containing the new values and types for child objects.
		 * @param removeMissingDynamicObjects If true, this will remove any child objects that do not appear in the session state.
 		 */
		public function setSessionState(newStateArray:Array, removeMissingDynamicObjects:Boolean):void
		{
			delayCallbacks();
			
			//trace(LinkableHashMap, "setSessionState "+setMissingValuesToNull, ObjectUtil.toString(newState.qualifiedClassNames), ObjectUtil.toString(newState));
			// first pass: make sure the types match and sessioned properties are instantiated.
			var i:int;
			var objectName:String;
			var className:String;
			var typedState:Object;
			var remainingObjects:Object = removeMissingDynamicObjects ? {} : null; // maps an objectName to a value of true
			var newObjects:Object = {}; // maps an objectName to a value of true if the object is newly created as a result of setting the session state
			var newNameOrder:Array = []; // the order the object names appear in the vector
			if (newStateArray != null)
			{
				// initialize all the objects before setting their session states because they may refer to each other.
				for (i = 0; i < newStateArray.length; i++)
				{
					typedState = newStateArray[i];
					if (!DynamicState.objectHasProperties(typedState))
						continue;
					objectName = typedState[DynamicState.OBJECT_NAME];
					className = typedState[DynamicState.CLASS_NAME];
					// ignore objects that do not have a name because they may not load the same way on different application instances.
					if (objectName == null)
						continue;
					// if className is not specified, make no change
					if (className == null)
						continue;
					// initialize object and remember if a new one was just created
					if (_nameToObjectMap[objectName] != initObjectByClassName(objectName, className))
						newObjects[objectName] = true;
				}
				// second pass: copy the session state for each property that is defined.
				// Also remember the ordered list of names that appear in the session state.
				for (i = 0; i < newStateArray.length; i++)
				{
					typedState = newStateArray[i];
					if (typedState is String)
					{
						objectName = typedState as String;
						if (removeMissingDynamicObjects)
							remainingObjects[objectName] = true;
						newNameOrder.push(objectName);
						continue;
					}
					
					if (!DynamicState.objectHasProperties(typedState))
						continue;
					objectName = typedState[DynamicState.OBJECT_NAME];
					if (objectName == null)
						continue;
					var object:ILinkableObject = _nameToObjectMap[objectName] as ILinkableObject;
					if (object == null)
						continue;
					// if object is newly created, we want to apply an absolute session state
					WeaveAPI.SessionManager.setSessionState(object, typedState[DynamicState.SESSION_STATE], newObjects[objectName] || removeMissingDynamicObjects);
					if (removeMissingDynamicObjects)
						remainingObjects[objectName] = true;
					newNameOrder.push(objectName);
				}
			}
			if (removeMissingDynamicObjects)
			{
				// third pass: remove objects based on the Boolean flags in remainingObjects.
				for (i = _orderedNames.length - 1; i >= 0; i--)
				{
					objectName = _orderedNames[i];
					if (remainingObjects[objectName] !== true)
					{
						//trace(LinkableHashMap, "missing value: "+objectName);
						removeObject(objectName);
					}
				}
			}
			// update name order AFTER objects have been added and removed.
			setNameOrder(newNameOrder);
			
			resumeCallbacks();
		}
	}
}
