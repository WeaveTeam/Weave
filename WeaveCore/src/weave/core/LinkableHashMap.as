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
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import weave.api.core.IChildListCallbackInterface;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.disposeObject;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	
	/**
	 * Allows dynamically creating instances of objects implementing ILinkableObject at runtime.
	 * The session state is an Array of DynamicState objects.
	 * @see weave.core.DynamicState
	 * 
	 * @author adufilie
	 */
	public class LinkableHashMap extends CallbackCollection implements ILinkableHashMap
	{
		/**
		 * Constructor.
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
		private var _typeRestriction:Class = null; // restricts the type of object that can be stored
		private var _typeRestrictionClassName:String = null; // qualified class name of _typeRestriction
		
		/**
		 * @inheritDoc
		 */
		public function get typeRestriction():Class
		{
			return _typeRestriction;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get childListCallbacks():IChildListCallbackInterface
		{
			return _childListCallbacks;
		}

		/**
		 * @inheritDoc
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
		 * @inheritDoc
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
		 * @inheritDoc
		 */
		public function getObject(name:String):ILinkableObject
		{
			return _nameToObjectMap[name] as ILinkableObject;
		}
		/**
		 * @inheritDoc
		 */
		public function getName(object:ILinkableObject):String
		{
			return _objectToNameMap[object] as String;
		}
		/**
		 * @inheritDoc
		 */
		public function setNameOrder(newOrder:Array):void
		{
			var changeDetected:Boolean = false;
			var name:String;
			var i:int;
			var originalNameCount:int = _orderedNames.length; // remembers how many names existed before appending
			var haveSeen:Object = {}; // to remember which names have been seen in newOrder
			// append each name in newOrder to the end of _orderedNames
			for (i = 0; i < newOrder.length; i++)
			{
				name = newOrder[i] as String;
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
			var out:int = 0;
			for (i = 0; i < _orderedNames.length; i++)
				if (_orderedNames[i] != null)
					_orderedNames[out++] = _orderedNames[i];
			_orderedNames.length = out;
			// if the name order changed, run child list callbacks
			if (changeDetected)
				_childListCallbacks.runCallbacks(null, null, null);
		}
		/**
		 * @inheritDoc
		 */
		public function requestObject(name:String, classDef:Class, lockObject:Boolean):*
		{
			var className:String = classDef ? getQualifiedClassName(classDef) : null;
			var result:* = initObjectByClassName(name, className, lockObject);
			return classDef ? result as classDef : null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function requestObjectCopy(name:String, objectToCopy:ILinkableObject):ILinkableObject
		{
			if (objectToCopy == null)
			{
				removeObject(name);
				return null;
			}
			
			delayCallbacks(); // make sure callbacks only trigger once
			//var className:String = getQualifiedClassName(objectToCopy);
			var classDef:Class = Object(objectToCopy).constructor; //ClassUtils.getClassDefinition(className);
			var sessionState:Object = WeaveAPI.SessionManager.getSessionState(objectToCopy);
			var object:ILinkableObject = requestObject(name, classDef, false);
			if (object != null)
				WeaveAPI.SessionManager.setSessionState(object, sessionState);
			resumeCallbacks();
			
			return object;
		}
		
		/**
		 * @inheritDoc
		 */
		public function renameObject(oldName:String, newName:String):ILinkableObject
		{
			if (oldName != newName)
			{
				delayCallbacks();
				
				// prepare a name order that will put the new name in the same place the old name was
				var newNameOrder:Array = _orderedNames.concat();
				var index:int = newNameOrder.indexOf(oldName);
				if (index >= 0)
					newNameOrder.splice(index, 1, newName);
				
				requestObjectCopy(newName, getObject(oldName));
				removeObject(oldName);
				setNameOrder(newNameOrder);
				
				resumeCallbacks();
			}
			return getObject(newName);
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
			if (className)
			{
				// if no name is specified, generate a unique one now.
				if (!name)
					name = generateUniqueName(className.split("::").pop());
				if ( ClassUtils.classImplements(className, SessionManager.ILinkableObjectQualifiedClassName)
					&& (_typeRestriction == null || ClassUtils.classIs(className, _typeRestrictionClassName)) )
				{
//					try
//					{
						// If this name is not associated with an object of the specified type,
						// associate the name with a new object of the specified type.
						var classDef:Class = ClassUtils.getClassDefinition(className);
						var object:Object = _nameToObjectMap[name];
						if (!object || object.constructor != classDef)
							createAndSaveNewObject(name, classDef, lockObject);
						else if (lockObject)
							this.lockObject(name);
//					}
//					catch (e:Error)
//					{
//						reportError(e);
//						enterDebugger();
//					}
				}
				else
				{
					removeObject(name);
				}
			}
			else
			{
				removeObject(name);
			}
			return _nameToObjectMap[name] as ILinkableObject;
		}
		/**
		 * (private)
		 * @param name The identifying name to associate with a new object.
		 * @param classDef The Class definition used to instantiate a new object.
		 */
	    private function createAndSaveNewObject(name:String, classDef:Class, lockObject:Boolean):void
	    {
	    	if (_nameIsLocked[name])
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
			
			if (lockObject)
				this.lockObject(name);

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
		 * @inheritDoc
		 */
		public function objectIsLocked(name:String):Boolean
		{
			return _nameIsLocked[name] ? true : false;
		}
		/**
		 * @inheritDoc
		 */
		public function removeObject(name:String):void
		{
			if (!name || _nameIsLocked[name])
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
			disposeObject(object);
		}

		/**
		 * @inheritDoc
		 */
		public function removeAllObjects():void
		{
			delayCallbacks();
			for each (var name:String in _orderedNames.concat()) // iterate over a copy of the list
				removeObject(name);
			resumeCallbacks();
		}
		
		/**
		 * This function removes all objects from this LinkableHashMap.
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			
			// first, remove all objects that aren't locked
			removeAllObjects();
			
			// remove all locked objects
			for each (var name:String in _orderedNames.concat()) // iterate over a copy of the list
			{
				_nameIsLocked[name] = undefined; // make sure removeObject() will carry out its action
				removeObject(name);
			}
		}

		/**
		 * @inheritDoc
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
		 * @inheritDoc
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
		 * @inheritDoc
 		 */
		public function setSessionState(newStateArray:Array, removeMissingDynamicObjects:Boolean):void
		{
			// special case - no change
			if (newStateArray == null)
				return;
			
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
				for each (objectName in _orderedNames.concat()) // iterate over a copy of the list
				{
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
