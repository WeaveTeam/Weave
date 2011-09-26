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
	import flash.external.ExternalInterface;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import weave.api.WeaveAPI;
	import weave.api.core.IExternalSessionStateInterface;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.compiler.Compiler;
	import weave.compiler.ICompiledObject;

	use namespace weave_internal;
	
	/**
	 * A set of static functions intended for use as a JavaScript API.
	 * 
	 * The user interface in Weave is initially generated from a saved session state.
	 * User interactions affect the session state, and changes in the session state affect
	 * the display at runtime.  The API provides a window into the session state so most
	 * interactions that can be made through the GUI can also be made through JavaScript calls.
	 * 
	 * @author adufilie
	 */
	public class ExternalSessionStateInterface implements IExternalSessionStateInterface
	{
		/**
		 * This function sets the root object that will be used by the other functions in this class.
		 * This function must be called before the JavaScript API can be used.
		 * @param root The root ILinkableObject to be used by the external interface functions.
		 */
		public function setLinkableObjectRoot(root:ILinkableObject):void
		{
			_rootObject = root;
		}
		
		/**
		 * @private
		 */
		private var _rootObject:ILinkableObject = null;
		
		/**
		 * This function returns a pointer to an object appearing in the session state.
		 * This function is not intended to be accessible through JavaScript.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @return A pointer to the object referred to by objectPath.
		 */
		public function getObject(objectPath:Array):ILinkableObject
		{
			var object:ILinkableObject = _rootObject;
			for (var i:int = 0; i < objectPath.length; i++)
			{
				if (object == null)
					return null;
				var propertyName:String = objectPath[i];
				if (object is ILinkableHashMap)
				{
					object = (object as ILinkableHashMap).getObject(propertyName);
				}
				else if (object is ILinkableDynamicObject)
				{
					// ignore propertyName and always return the internalObject
					object = (object as ILinkableDynamicObject).internalObject;
				}
				else
				{
					if ((WeaveAPI.SessionManager as SessionManager).getLinkablePropertyNames(object).indexOf(propertyName) < 0)
					{
						return null;
					}
					object = object[propertyName] as ILinkableObject;
				}
			}
			return object;
		}
		/**
		 * This function gets the current session state of an object.  Nested XML objects will be converted to Strings before returning.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @return An object containing the values from the sessioned properties.
		 */
		public function getSessionState(objectPath:Array):Object
		{
			var object:ILinkableObject = getObject(objectPath);
			if (object == null)
				return null;
			var state:Object = WeaveAPI.SessionManager.getSessionState(object);
			convertSessionStateToPrimitives(state); // do not allow XML objects to be returned
			return state;
		}
		/**
		 * This function modifies a session state, converting any nested XML objects to Strings.
		 * @param state A session state that may contain nested XML objects.
		 */
		private function convertSessionStateToPrimitives(state:Object):void
		{
			if (state is Array)
			{
				for each (state in state)
					convertSessionStateToPrimitives(state);
			}
			else if (state is DynamicState)
			{
				convertSessionStateToPrimitives((state as DynamicState).sessionState);
			}
			else if (state is Object)
			{
				for (var name:String in state)
				{
					var value:Object = state[name];
					if (value is XML)
						state[name] = (value as XML).toXMLString();
					else
						convertSessionStateToPrimitives(value);
				}
			}
		}
		
		/**
		 * This function updates the current session state of an object.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @param newState An object containing the new values for sessioned properties in the sessioned object.
		 * @param removeMissingDynamicObjects If true, this will remove any properties from an ILinkableCompositeObject that do not appear in the new session state.
		 * @return true if objectPath refers to an existing object in the session state.
		 */
		public function setSessionState(objectPath:Array, newState:Object, removeMissingObjects:Boolean = true):Boolean
		{
			var object:ILinkableObject = getObject(objectPath);
			if (object == null)
				return false;
			WeaveAPI.SessionManager.setSessionState(object, newState, removeMissingObjects);
			return true;
		}
		
		/**
		 * This function will get the qualified class name of an object appearing in the session state.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @return The qualified class name of the object referred to by objectPath.
		 */
		public function getObjectType(objectPath:Array):String
		{
			return getQualifiedClassName(getObject(objectPath));
		}
		
		/**
		 * This function gets a list of names of children of an object appearing in the session state.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @return An Array of names of sessioned children of the object referred to by objectPath, or null if the object doesn't exist.
		 */
		public function getChildNames(objectPath:Array):Array
		{
			var object:ILinkableObject = getObject(objectPath);
			if (object == null)
				return null;
			if (object is ILinkableHashMap)
				return (object as ILinkableHashMap).getNames();
			if (object is ILinkableDynamicObject)
				return [(object as ILinkableDynamicObject).globalName];
			return (WeaveAPI.SessionManager as SessionManager).getLinkablePropertyNames(object);
		}
		
		/**
		 * This function will reorder children of an object implementing ILinkableHashMap.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @param orderedChildNames The new order to use for the children of the object specified by objectPath.
		 * @return true if objectPath refers to the location of an ILinkableHashMap.
		 */
		public function setChildNameOrder(hashMapPath:Array, orderedChildNames:Array):Boolean
		{
			var hashMap:ILinkableHashMap = getObject(hashMapPath) as ILinkableHashMap;
			if (hashMap == null)
				return false;
			hashMap.setNameOrder(orderedChildNames);
			return true;
		}
		/**
		 * This function will dynamically create an object at the specified location in the session state if its parent implements
		 * ILinkableCompositeObject.  If the object at the specified location already exists and is of the requested type,
		 * this function does nothing.
		 * If the parent of the dynamic object to be created implements ILinkableHashMap, a value of null for the child name
		 * will cause a new name to be generated.
		 * If the parent of the dynamic object to be created implements ILinkableDynamicObject, the name of the child refers to
		 * the name of a static object appearing at the top level of the session state.  A child name equal to null in this case
		 * will create a local object that does not appear at the top level of the session state.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @param objectType The qualified name of a class implementing ILinkableObject.
		 * @return true if, after calling this function, an object of the requested type exists at the requested location.
		 */
		public function requestObject(objectPath:Array, objectType:String):Boolean
		{
			var childName:String = objectPath.pop();
			var parent:ILinkableObject = getObject(objectPath);
			var hashMap:ILinkableHashMap = parent as ILinkableHashMap;
			var dynamicObject:ILinkableDynamicObject = parent as ILinkableDynamicObject;
			if (!hashMap && !dynamicObject)
				return false;
			var classDef:Class = WeaveXMLDecoder.getClassDefinition(objectType);
			if (classDef == null)
				return false;
			var child:Object = null;
			if (hashMap)
				child = hashMap.requestObject(childName, classDef, false);
			if (dynamicObject)
				child = dynamicObject.requestGlobalObject(childName, classDef, false);
			return child is classDef;
		}

		/**
		 * This function will remove a dynamically created object if it is the child of an ILinkableCompositeObject.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @return true if objectPath refers to a valid location where dynamically created objects can exist.
		 */
		public function removeObject(objectPath:Array):Boolean
		{
			var childName:String = objectPath.pop();
			var object:ILinkableObject = getObject(objectPath);
			var hashMap:ILinkableHashMap = object as ILinkableHashMap;
			var dynamicObject:ILinkableDynamicObject = object as ILinkableDynamicObject;
			if (!hashMap && !dynamicObject)
				return false;
			
			if (hashMap)
				hashMap.removeObject(childName);
			if (dynamicObject)
				dynamicObject.removeObject();
			return true;
		}
		
		/**
		 * This function serializes a session state from Object format to XML String format.
		 * @param sessionState A session state object.
		 * @param tagName The name to use for the root XML tag that gets generated from the session state.
		 * @return An XML serialization of the session state.
		 */
		public function convertSessionStateObjectToXML(sessionState:Object, tagName:String = "sessionState"):String
		{
			var result:XML = WeaveXMLEncoder.encode(sessionState, tagName);
			return result.toXMLString();
		}

		/**
		 * This function converts a session state from XML format to Object format.  Nested XML objects will be converted to Strings before returning.
		 * @param sessionState A session state that has been encoded in XML.  This can be supplied as either an XML object or a String.
		 * @return The deserialized session state object.
		 */
		public function convertSessionStateXMLToObject(sessionStateXML:Object):Object
		{
			if (!(sessionStateXML is XML))
				sessionStateXML = XML(sessionStateXML);
			var state:Object = WeaveXMLDecoder.decode(sessionStateXML as XML);
			convertSessionStateToPrimitives(state); // do not allow XML objects to be returned
			return state;
		}

		/**
		 * @see weave.api.core.IExternalSessionStateInterface
		 */   
		public function evaluateExpression(scopeObjectPath:Array, expression:String, variables:Object = null, staticLibraries:Array = null):*
		{
			var compiler:Compiler = new Compiler();
			var thisObject:ILinkableObject = (scopeObjectPath) ? getObject(scopeObjectPath) : null;
			var compiledMethod:Function = null;
			
			// first try to compile it
			try
			{
				for each (var qName:String in staticLibraries)
				{
					var classDef:Class = null;
					var wasIncluded:Boolean = false;
					
					classDef = Class(getDefinitionByName(qName));
					if (classDef)
						compiler.includeLibraries(classDef);
					else
						throw new Error("Unknown class: " + qName);
				}

				compiledMethod = compiler.compileToFunction(expression, variables, false, thisObject != null);
			}
			catch (e:Error)
			{
				WeaveAPI.ErrorManager.reportError(new Error("Unable to compile expression.\n" + e.message, e.errorID));
			}
			
			var result:* = undefined;
			if (compiledMethod != null)
			{
				try
				{
					result = compiledMethod.apply(thisObject, arguments);
				}
				catch (e:Error)
				{
					WeaveAPI.ErrorManager.reportError(new Error("Error evaluating expression.\n" + e.message, e.errorID));
				}
			}
			
			return result; 
		}
	}
}
