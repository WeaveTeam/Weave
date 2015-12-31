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
	import weavejs.api.core.DynamicState;
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.IChildListCallbackInterface;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.core.ILinkableObject;
	import weavejs.util.JS;
	
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
			super();
			_typeRestriction = typeRestriction;
		}
		
		private var _childListCallbacks:ChildListCallbackInterface = Weave.linkableChild(this, ChildListCallbackInterface);
		private var _orderedNames:Array = []; // an ordered list of names appearing in _nameToObjectMap
		private var _nameToObjectMap:Object = {}; // maps an identifying name to an object
		private var _map_objectToNameMap:Object = new JS.WeakMap(); // maps an object to an identifying name
		private var _nameIsLocked:Object = {}; // maps an identifying name to a value of true if that name is locked.
		private var _previousNameMap:Object = {}; // maps a previously used name to a value of true.  used when generating unique names.
		private var _typeRestriction:Class; // restricts the type of object that can be stored
		
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
				var object:ILinkableObject = _nameToObjectMap[name];
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
			return _nameToObjectMap[name];
		}
		/**
		 * @inheritDoc
		 */
		public function getName(object:ILinkableObject):String
		{
			return _map_objectToNameMap.get(object);
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
			var className:String = classDef ? Weave.className(classDef) : null;
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
			//var className:String = Weave.className(objectToCopy);
			var classDef:Class = Object(objectToCopy).constructor; //ClassUtils.getClassDefinition(className);
			var sessionState:Object = Weave.getState(objectToCopy);
			//  if the name refers to the same object, remove the existing object so it can be replaced with a new one.
			if (name == getName(objectToCopy))
				removeObject(name);
			var object:ILinkableObject = requestObject(name, classDef, false);
			if (object != null)
				Weave.setState(object, sessionState);
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
				var classDef:Class = Weave.getDefinition(className);
				if (Weave.isLinkable(classDef)
					&& (_typeRestriction == null || classDef.prototype is _typeRestriction) )
				{
//					try
//					{
						// If this name is not associated with an object of the specified type,
						// associate the name with a new object of the specified type.
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
			return _nameToObjectMap[name];
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
			Weave.linkableChild(this, object);
			// save the name-object mappings
			_nameToObjectMap[name] = object;
			_map_objectToNameMap.set(object, name);
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
			
			var object:ILinkableObject = _nameToObjectMap[name];
			if (object == null)
				return; // do nothing if the name isn't mapped to an object.
			
			//trace(LinkableHashMap, "removeObject",name,object);
			// remove name & associated object
			delete _nameToObjectMap[name];
			_map_objectToNameMap['delete'](object);
			var index:int = _orderedNames.indexOf(name);
			_orderedNames.splice(index, 1);

			// make sure the callback variables signal that the object was removed
			_childListCallbacks.runCallbacks(name, null, object);

			// dispose the object AFTER the callbacks know that the object was removed
			Weave.dispose(object);
		}

		/**
		 * @inheritDoc
		 */
		public function removeAllObjects():void
		{
			delayCallbacks();
			var names:Array = _orderedNames.concat(); // iterate over a copy of the list
			for each (var name:String in names)
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
			var names:Array = _orderedNames.concat(); // iterate over a copy of the list
			for each (var name:String in names)
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
				result[i] = DynamicState.create(
						name,
						Weave.className(object),
						Weave.getState(object)
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
			var delayed:Array = [];
			var callbacks:ICallbackCollection;
			var objectName:String;
			var className:String;
			var typedState:Object;
			var remainingObjects:Object = removeMissingDynamicObjects ? {} : null; // maps an objectName to a value of true
			var newObjects:Object = {}; // maps an objectName to a value of true if the object is newly created as a result of setting the session state
			var newNameOrder:Array = []; // the order the object names appear in the array
			if (newStateArray != null)
			{
				// first pass: delay callbacks of all children
				for each (objectName in _orderedNames)
				{
					callbacks = Weave.getCallbacks(_nameToObjectMap[objectName]);
					delayed.push(callbacks)
					callbacks.delayCallbacks();
				}
				
				// initialize all the objects before setting their session states because they may refer to each other.
				for (i = 0; i < newStateArray.length; i++)
				{
					typedState = newStateArray[i];
					if (!DynamicState.isDynamicState(typedState, true))
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
				
				// next pass: delay callbacks of all children (again, because there may be new children)
				for each (objectName in _orderedNames)
				{
					callbacks = Weave.getCallbacks(_nameToObjectMap[objectName]);
					delayed.push(callbacks)
					callbacks.delayCallbacks();
				}
				
				// next pass: copy the session state for each property that is defined.
				// Also remember the ordered list of names that appear in the session state.
				for (i = 0; i < newStateArray.length; i++)
				{
					typedState = newStateArray[i];
					if (typeof typedState === 'string')
					{
						objectName = String(typedState);
						if (removeMissingDynamicObjects)
							remainingObjects[objectName] = true;
						newNameOrder.push(objectName);
						continue;
					}
					
					if (!DynamicState.isDynamicState(typedState, true))
						continue;
					objectName = typedState[DynamicState.OBJECT_NAME];
					if (objectName == null)
						continue;
					var object:ILinkableObject = _nameToObjectMap[objectName];
					if (object == null)
						continue;
					// if object is newly created, we want to apply an absolute session state
					Weave.setState(object, typedState[DynamicState.SESSION_STATE], newObjects[objectName] || removeMissingDynamicObjects);
					if (removeMissingDynamicObjects)
						remainingObjects[objectName] = true;
					newNameOrder.push(objectName);
				}
			}
			if (removeMissingDynamicObjects)
			{
				// third pass: remove objects based on the Boolean flags in remainingObjects.
				var names:Array = _orderedNames.concat(); // iterate over a copy of the list
				for each (objectName in names)
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
			
			// final pass: resume all callbacks
			
			// next pass: delay callbacks of all children
			for each (callbacks in delayed)
				if (!Weave.wasDisposed(callbacks))
					callbacks.resumeCallbacks();
			
			resumeCallbacks();
		}
	}
}
