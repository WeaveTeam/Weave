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
	import flash.utils.getQualifiedClassName;
	
	import weave.api.WeaveAPI;
	import weave.api.core.IExternalSessionStateInterface;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.reportError;
	import weave.compiler.Compiler;
	import weave.compiler.ICompiledObject;

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
		 * This function returns a pointer to an object appearing in the session state.
		 * This function is not intended to be accessible directly from JavaScript because
		 * the pointer to the ILinkableObject cannot be retained in JavaScript.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 *                   A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return A pointer to the object referred to by objectPath.
		 */
		public function getObject(objectPath:Array):ILinkableObject
		{
			var object:ILinkableObject = _rootObject;
			for each (var propertyName:Object in objectPath)
			{
				if (object == null)
					return null;
				if (object is ILinkableHashMap)
				{
					if (propertyName is Number)
						object = (object as ILinkableHashMap).getObjects()[propertyName];
					else
						object = (object as ILinkableHashMap).getObject(String(propertyName));
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
		 * @inheritDoc
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
		 * @inheritDoc
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
		 * @inheritDoc
		 */
		public function getObjectType(objectPath:Array):String
		{
			var object:ILinkableObject = getObject(objectPath);
			if (object == null)
				return null;
			return getQualifiedClassName(object);
		}
		
		/**
		 * @inheritDoc
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
		 * @inheritDoc
		 */
		public function setChildNameOrder(hashMapPath:Array, orderedChildNames:Array):Boolean
		{
			var hashMap:ILinkableHashMap = getObject(hashMapPath) as ILinkableHashMap;
			if (!hashMap || !orderedChildNames)
				return false;
			hashMap.setNameOrder(orderedChildNames);
			return true;
		}
		/**
		 * @inheritDoc
		 */
		public function requestObject(objectPath:Array, objectType:String):Boolean
		{
			if (!objectPath || !objectPath.length)
				return false;
			
			var classDef:Class = WeaveXMLDecoder.getClassDefinition(objectType);
			if (classDef == null)
				return false;
			
			var parentPath:Array = objectPath.concat();
			var childName:Object = parentPath.pop();
			var parent:ILinkableObject = getObject(parentPath);
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
				child = getObject(objectPath);
			return child is classDef;
		}

		/**
		 * @inheritDoc
		 */
		public function removeObject(objectPath:Array):Boolean
		{
			if (!objectPath || !objectPath.length)
				return false;
			objectPath = objectPath.concat();
			var childName:Object = objectPath.pop();
			var object:ILinkableObject = getObject(objectPath);
			var hashMap:ILinkableHashMap = object as ILinkableHashMap;
			var dynamicObject:ILinkableDynamicObject = object as ILinkableDynamicObject;
			if (hashMap)
			{
				if (childName is Number)
					childName = hashMap.getNames()[childName];
				hashMap.removeObject(childName as String);
			}
			else if (dynamicObject)
				dynamicObject.removeObject();
			else
				return false;
			return true;
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
		
		private function getObjectFromPathOrVariableName(objectPathOrVariableName:Object):*
		{
			if (objectPathOrVariableName is Array)
				return getObject(objectPathOrVariableName as Array);
			
			var variableName:String = objectPathOrVariableName as String;
			if (variableName)
			{
				if (_variables.hasOwnProperty(variableName))
					return _variables[variableName];
				
				reportError('Undefined variable "' + variableName + '"');
			}
			
			return null;
		}
		
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
				var compiledObject:ICompiledObject = _compiler.compileToObject(expression);
				var isFuncDef:Boolean = _compiler.compiledObjectIsFunctionDefinition(compiledObject);
				var compiledMethod:Function = _compiler.compileObjectToFunction(compiledObject, [_variables, variables], reportError, thisObject != null);
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
				reportError(e);
			}
			return undefined;
		}
		
		/**
		 * This object maps a JavaScript callback function, specified as a String, to a corresponding Function that will call it.
		 */		
		private const _callbackFunctionCache:Object = {};
		
		/**
		 * @private
		 */
		private function getCachedCallbackFunction(callback:String):Function
		{
			if (!_callbackFunctionCache[callback])
			{
				_callbackFunctionCache[callback] = function():void
				{
					var prev:Boolean = ExternalInterface.marshallExceptions;
					try
					{
						ExternalInterface.marshallExceptions = true;
						ExternalInterface.call(callback);
					}
					catch (e:*)
					{
						reportError(e);
					}
					finally
					{
						ExternalInterface.marshallExceptions = prev;
					}
				}
			}
			return _callbackFunctionCache[callback];
		}
		
		/**
		 * @inheritDoc
		 */
		public function addCallback(objectPathOrVariableName:Object, callback:String, triggerCallbackNow:Boolean = false, immediateMode:Boolean = false):Boolean
		{
			var object:ILinkableObject = getObjectFromPathOrVariableName(objectPathOrVariableName) as ILinkableObject;
			if (object == null)
				return false;
			if (immediateMode)
				getCallbackCollection(object).addImmediateCallback(null, getCachedCallbackFunction(callback), triggerCallbackNow);
			else
				getCallbackCollection(object).addGroupedCallback(null, getCachedCallbackFunction(callback), triggerCallbackNow);
			return true;
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeCallback(objectPathOrVariableName:Object, callback:String):Boolean
		{
			var object:ILinkableObject = getObjectFromPathOrVariableName(objectPathOrVariableName) as ILinkableObject;
			if (object == null)
				return false;
			getCallbackCollection(object).removeCallback(getCachedCallbackFunction(callback));
			return true;
		}
		
		/**
		 * This surrounds ExternalInterface.addCallback() with try/catch and reports the error.
		 * @see flash.external.ExternalInterface#addCallback
		 */
		public static function tryAddCallback(functionName:String, closure:Function):void
		{
			try
			{
				if (ExternalInterface.available)
					ExternalInterface.addCallback(functionName, closure);
			}
			catch (e:Error)
			{
				if (e.errorID == 2060)
					reportError(e, "In the HTML embedded object tag, make sure that the parameter 'allowScriptAccess' is set to 'always'. " + e.message);
				else
					reportError(e);
			}
		}
	}
}
