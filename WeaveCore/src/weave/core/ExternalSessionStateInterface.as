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
	
	import weave.api.core.IExternalSessionStateInterface;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.compiler.Compiler;
	import weave.compiler.ICompiledObject;
	import weave.compiler.StandardLib;
	import weave.utils.Dictionary2D;

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
		private var _rootObject:ILinkableObject = WeaveAPI.globalHashMap;
		
		/**
		 * @inheritDoc
		 */
		public function getSessionState(objectPath:Array):Object
		{
			var object:ILinkableObject = WeaveAPI.SessionManager.getObject(_rootObject, objectPath);
			if (object)
			{
				var state:Object = WeaveAPI.SessionManager.getSessionState(object);
				convertSessionStateToPrimitives(state); // do not allow XML objects to be returned
				return state;
			}
			
			externalWarning("No ILinkableObject from which to get session state at path {0}", Compiler.stringify(objectPath));
			return null;
		}
		
		/**
		 * This function modifies a session state, converting any nested XML objects to Strings.
		 * @param state A session state that may contain nested XML objects.
		 */
		private function convertSessionStateToPrimitives(state:Object):void
		{
			for (var key:* in state)
			{
				var value:* = state[key];
				if (value is XML)
					state[key] = (value as XML).toXMLString();
				else
					convertSessionStateToPrimitives(value);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function setSessionState(objectPath:Array, newState:Object, removeMissingObjects:Boolean = true):Boolean
		{
			var object:ILinkableObject = WeaveAPI.SessionManager.getObject(_rootObject, objectPath);
			if (object)
			{
				WeaveAPI.SessionManager.setSessionState(object, newState, removeMissingObjects);
				return true;
			}
			
			externalError("No ILinkableObject for which to set session state at path {0}", Compiler.stringify(objectPath));
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getObjectType(objectPath:Array):String
		{
			var object:ILinkableObject = WeaveAPI.SessionManager.getObject(_rootObject, objectPath);
			if (object)
				return getQualifiedClassName(object);
			
			// no warning since getObjectType() may be used to check whether or not an object exists.
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getChildNames(objectPath:Array):Array
		{
			var object:ILinkableObject = WeaveAPI.SessionManager.getObject(_rootObject, objectPath);
			if (object)
			{
				if (object is ILinkableHashMap)
					return (object as ILinkableHashMap).getNames();
				if (object is ILinkableDynamicObject)
					return [(object as ILinkableDynamicObject).globalName];
				return (WeaveAPI.SessionManager as SessionManager).getLinkablePropertyNames(object);
			}
			
			externalWarning("No ILinkableObject for which to get child names at path {0}", Compiler.stringify(objectPath));
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function setChildNameOrder(hashMapPath:Array, orderedChildNames:Array):Boolean
		{
			var hashMap:ILinkableHashMap = WeaveAPI.SessionManager.getObject(_rootObject, hashMapPath) as ILinkableHashMap;
			if (hashMap)
			{
				// it's ok if there are no names specified, because that wouldn't accomplish anything anyway
				if (orderedChildNames)
					hashMap.setNameOrder(orderedChildNames);
				return true;
			}
			
			externalError("No ILinkableHashMap for which to reorder children at path {0}", Compiler.stringify(hashMapPath));
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function requestObject(objectPath:Array, objectType:String):Boolean
		{
			// get class definition
			var classQName:String = WeaveXMLDecoder.getClassName(objectType);
			var classDef:Class = ClassUtils.getClassDefinition(classQName);
			if (classDef == null)
			{
				externalError("No class definition for {0}", Compiler.stringify(classQName));
				return false;
			}
			if (ClassUtils.isClassDeprecated(classQName))
				externalWarning("{0} is deprecated.", objectType);
			
			// stop if there is no path specified
			if (!objectPath || !objectPath.length)
			{
				if (Object(_rootObject).constructor == classDef)
					return true;
				
				externalError("Cannot request an object at the root path");
				return false;
			}
			
			// Get parent object first in case there is some backwards compatibility code that gets
			// executed when it is accessed (registering deprecated class definitions, for example).
			var parentPath:Array = objectPath.concat();
			var childName:Object = parentPath.pop();
			var parent:ILinkableObject = WeaveAPI.SessionManager.getObject(_rootObject, parentPath);
			
			// request the child object
			var hashMap:ILinkableHashMap = parent as ILinkableHashMap;
			var dynamicObject:ILinkableDynamicObject = parent as ILinkableDynamicObject;
			var child:Object = null;
			if (hashMap)
			{
				if (childName is Number)
					childName = hashMap.getNames()[childName];
				child = hashMap.requestObject(childName as String, classDef, false);
			}
			else if (dynamicObject)
				child = dynamicObject.requestGlobalObject(childName as String, classDef, false);
			else
				child = WeaveAPI.SessionManager.getObject(_rootObject, objectPath);
			
			if (child && child.constructor == classDef)
				return true;
			
			externalError("Request for {0} failed at path {1}", objectType, Compiler.stringify(objectPath));
			return false;
		}

		/**
		 * @inheritDoc
		 */
		public function removeObject(objectPath:Array):Boolean
		{
			if (!objectPath || !objectPath.length)
			{
				externalError("Cannot remove root object");
				return false;
			}
			
			var parentPath:Array = objectPath.concat();
			var childName:Object = parentPath.pop();
			var parent:ILinkableObject = WeaveAPI.SessionManager.getObject(_rootObject, parentPath);
			
			var hashMap:ILinkableHashMap = parent as ILinkableHashMap;
			if (hashMap)
			{
				if (childName is Number)
					childName = hashMap.getNames()[childName];
				
				if (hashMap.objectIsLocked(childName as String))
				{
					externalError("Object is locked and cannot be removed (path: {0})", Compiler.stringify(objectPath));
					return false;
				}
				
				hashMap.removeObject(childName as String);
				return true;
			}
			
			var dynamicObject:ILinkableDynamicObject = parent as ILinkableDynamicObject;
			if (dynamicObject)
			{
				if (dynamicObject.locked)
				{
					externalError("Object is locked and cannot be removed (path: {0})", Compiler.stringify(objectPath));
					return false;
				}
				
				dynamicObject.removeObject();
				return true;
			}
			
			if (parent)
				externalError("Parent object does not support dynamic children, so cannot remove child at path {0}", Compiler.stringify(objectPath));
			else
				externalError("No parent from which to remove a child at path {0}", Compiler.stringify(objectPath));
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function convertSessionStateObjectToXML(sessionState:Object, tagName:String = null):String
		{
			var result:XML = WeaveXMLEncoder.encode(sessionState, tagName || "sessionState");
			return result.toXMLString();
		}

		/**
		 * @inheritDoc
		 */
		public function convertSessionStateXMLToObject(sessionStateXML:String):Object
		{
			var xml:XML = XML(sessionStateXML);
			var state:Object = WeaveXMLDecoder.decode(xml);
			convertSessionStateToPrimitives(state); // do not allow XML objects to be returned
			return state;
		}
		
		/**
		 * This object maps an expression name to the saved expression function.
		 */		
		private const _variables:Object = {};
		
		/**
		 * Gets an object from a path or a variable name and sets getObjectFromPathOrVariableName_error.
		 * If the path was invalid or the variable uninitialized, getObjectFromPathOrVariableName_error will be set with an appropriate error message.
		 * @param objectPathOrVariableName Either an Array for a path or a String for a variable name.
		 * @return The object at the specified path, the value of the specified variable, or null if the parameter was null.
		 */
		private function getObjectFromPathOrVariableName(objectPathOrVariableName:Object):*
		{
			getObjectFromPathOrVariableName_error = null;
			
			if (objectPathOrVariableName == null)
				return null;
			
			if (objectPathOrVariableName is Array)
			{
				var object:ILinkableObject = WeaveAPI.SessionManager.getObject(_rootObject, objectPathOrVariableName as Array);
				if (object)
					return object;
				
				getObjectFromPathOrVariableName_error = "No ILinkableObject at path " + Compiler.stringify(objectPathOrVariableName);
				return null;
			}
			
			var variableName:String = String(objectPathOrVariableName);
			if (variableName)
			{
				if (_variables.hasOwnProperty(variableName))
					return _variables[variableName];
				
				getObjectFromPathOrVariableName_error = "Undefined variable " + Compiler.stringify(variableName);
				return null;
			}
			
			return null;
		}
		
		private var getObjectFromPathOrVariableName_error:String = null;
		
		private const _compiler:Compiler = new Compiler();
		
		/**
		 * @inheritDoc
		 */
		public function evaluateExpression(scopeObjectPathOrVariableName:Object, expression:String, variables:Object = null, staticLibraries:Array = null, assignVariableName:String = null):*
		{
			try
			{
				if (staticLibraries)
					_compiler.includeLibraries.apply(null, staticLibraries);
				
				var isAssignment:Boolean = (assignVariableName != null); // allows '' to be used to ignore resulting value
				if (assignVariableName && !_compiler.isValidSymbolName(assignVariableName))
					throw new Error("Invalid variable name: " + Compiler.encodeString(assignVariableName));
				
				var thisObject:Object = getObjectFromPathOrVariableName(scopeObjectPathOrVariableName);
				if (getObjectFromPathOrVariableName_error)
					throw new Error(getObjectFromPathOrVariableName_error);
				var compiledObject:ICompiledObject = _compiler.compileToObject(expression);
				var isFuncDef:Boolean = _compiler.compiledObjectIsFunctionDefinition(compiledObject);
				// passed-in variables take precedence over stored ActionScript _variables
				var compiledMethod:Function = _compiler.compileObjectToFunction(
					compiledObject,
					[variables, _variables],
					WeaveAPI.ErrorManager.reportError,
					thisObject != null
				);
				var result:*;
				if (isAssignment && isFuncDef)
				{
					// bind 'this' scope
					result = Compiler.bind(compiledMethod, thisObject);
				}
				else
				{
					result = compiledMethod.apply(thisObject);
				}
				
				if (isAssignment)
					_variables[assignVariableName] = result;
				else
					return result;
			}
			catch (e:*)
			{
				externalError(e);
			}
			return undefined;
		}
		
		/**
		 * Stores information for removeCallback() and removeAllCallbacks()
		 */
		private static var _d2d_callback_target:Dictionary2D = new Dictionary2D(true, true);

		/**
		 * @inheritDoc
		 */
		public function addCallback(scopeObjectPathOrVariableName:Object, callback:Function, triggerCallbackNow:Boolean = false, immediateMode:Boolean = false):Boolean
		{
			try
			{
				if (scopeObjectPathOrVariableName == null)
				{
					externalError("addCallback(): No path or variable name given");
					return false;
				}
				
				var object:ILinkableObject = getObjectFromPathOrVariableName(scopeObjectPathOrVariableName) as ILinkableObject;
				if (getObjectFromPathOrVariableName_error)
				{
					externalError(getObjectFromPathOrVariableName_error);
					return false;
				}
				if (object == null)
				{
					externalError("No ILinkableObject to which to add a callback at path or variable {0}", Compiler.stringify(scopeObjectPathOrVariableName));
					return false;
				}
				
				_d2d_callback_target.set(callback, object, true);
				if (immediateMode)
					getCallbackCollection(object).addImmediateCallback(null, callback, triggerCallbackNow);
				else
					getCallbackCollection(object).addGroupedCallback(null, callback, triggerCallbackNow);
				return true;
			}
			catch (e:Error)
			{
				// unexpected error reported in Weave interface
				WeaveAPI.ErrorManager.reportError(e);
			}
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeCallback(objectPathOrVariableName:Object, callback:Function, everywhere:Boolean = false):Boolean
		{
			if (everywhere)
			{
				for (var target:Object in _d2d_callback_target.dictionary[callback])
					getCallbackCollection(target as ILinkableObject).removeCallback(callback);
				delete _d2d_callback_target.dictionary[callback];
				return true;
			}
			
			try
			{
				if (objectPathOrVariableName == null)
				{
					externalWarning("removeCallback(): No path or variable name given");
					return false;
				}

				var object:ILinkableObject = getObjectFromPathOrVariableName(objectPathOrVariableName) as ILinkableObject;
				if (getObjectFromPathOrVariableName_error)
				{
					externalError(getObjectFromPathOrVariableName_error);
					return false;
				}
				if (object == null)
				{
					externalWarning("No ILinkableObject from which to remove a callback at path or variable {0}", Compiler.stringify(objectPathOrVariableName));
					return false;
				}
				
				_d2d_callback_target.remove(callback, object);
				getCallbackCollection(object).removeCallback(callback);
				return true;
			}
			catch (e:Error)
			{
				// unexpected error reported in Weave interface
				WeaveAPI.ErrorManager.reportError(e);
			}
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeAllCallbacks():void
		{
			for (var callback:* in _d2d_callback_target.dictionary)
				for (var target:Object in _d2d_callback_target.dictionary[callback])
					getCallbackCollection(target as ILinkableObject).removeCallback(callback as Function);
			_d2d_callback_target = new Dictionary2D(true, true);
		}
		
		private static function externalError(format:String, ...args):void
		{
			var prefix:String = "Error: ";
			if (format.indexOf(prefix) != 0)
				format = prefix + format;
			WeaveAPI.externalError(StandardLib.substitute(format, args));
		}
		
		private static function externalWarning(format:String, ...args):void
		{
			WeaveAPI.externalError(StandardLib.substitute("Warning: " + format, args));
		}
	}
}
