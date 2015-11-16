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
	import weavejs.Weave;
	import weavejs.WeaveAPI;
	import weavejs.api.core.IExternalSessionStateInterface;
	import weavejs.api.core.ILinkableDynamicObject;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.core.ILinkableObject;
	import weavejs.compiler.StandardLib;
	import weavejs.utils.Dictionary2D;
	import weavejs.utils.Utils;

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
		public function ExternalSessionStateInterface(root:ILinkableHashMap)
		{
			this.root = root;
			this._variables = {};
//			this._compiler = new Compiler();
			_d2d_callback_target = new Dictionary2D();
			_map_func_wrapper = new Utils.WeakMap();
		}
		
		/**
		 * The root object in the session state tree.
		 */
		private var root:ILinkableHashMap;
		
		/**
		 * This object maps an expression name to the saved expression function.
		 */		
		private var _variables:Object;
		
		private var getObjectFromPathOrVariableName_error:String;
		
//		private var _compiler:Compiler;
		
		/**
		 * @inheritDoc
		 */
		public function getSessionState(objectPath:Array):Object
		{
			var object:ILinkableObject = WeaveAPI.SessionManager.getObject(root, objectPath);
			if (object)
			{
				var state:Object = WeaveAPI.SessionManager.getSessionState(object);
				convertSessionStateToPrimitives(state); // do not allow XML objects to be returned
				return state;
			}
			
			externalWarning("No ILinkableObject from which to get session state at path {0}", JSON.stringify(objectPath));
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
			var object:ILinkableObject = WeaveAPI.SessionManager.getObject(root, objectPath);
			if (object)
			{
				WeaveAPI.SessionManager.setSessionState(object, newState, removeMissingObjects);
				return true;
			}
			
			externalError("No ILinkableObject for which to set session state at path {0}", JSON.stringify(objectPath));
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getObjectType(objectPath:Array):String
		{
			var object:ILinkableObject = WeaveAPI.SessionManager.getObject(root, objectPath);
			if (object)
				return Weave.className(object);
			
			// no warning since getObjectType() may be used to check whether or not an object exists.
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getChildNames(objectPath:Array):Array
		{
			var object:ILinkableObject = WeaveAPI.SessionManager.getObject(root, objectPath);
			if (object)
			{
				if (object is ILinkableHashMap)
					return (object as ILinkableHashMap).getNames();
				if (object is ILinkableDynamicObject)
					return [null];
				return (WeaveAPI.SessionManager as SessionManager).getLinkablePropertyNames(object, true);
			}
			
			externalError("No ILinkableObject for which to get child names at path {0}", JSON.stringify(objectPath));
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function setChildNameOrder(hashMapPath:Array, orderedChildNames:Array):Boolean
		{
			var hashMap:ILinkableHashMap = WeaveAPI.SessionManager.getObject(root, hashMapPath) as ILinkableHashMap;
			if (hashMap)
			{
				// it's ok if there are no names specified, because that wouldn't accomplish anything anyway
				if (orderedChildNames)
					hashMap.setNameOrder(orderedChildNames);
				return true;
			}
			
			externalError("No ILinkableHashMap for which to reorder children at path {0}", JSON.stringify(hashMapPath));
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function requestObject(objectPath:Array, objectType:String):Boolean
		{
			// get class definition
			var classDef:Class = Weave.getDefinition(objectType);
			if (classDef == null)
			{
				externalError("No class definition for {0}", JSON.stringify(objectType));
				return false;
			}
			
			// stop if there is no path specified
			if (!objectPath || !objectPath.length)
			{
				// check for exact match only
				if (Object(root).constructor == classDef)
					return true;
				
				externalError("Cannot request an object at the root path");
				return false;
			}
			
			// Get parent object first in case there is some backwards compatibility code that gets
			// executed when it is accessed (registering deprecated class definitions, for example).
			var parentPath:Array = objectPath.concat();
			var childName:Object = parentPath.pop();
			var parent:ILinkableObject = WeaveAPI.SessionManager.getObject(root, parentPath);
			
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
				child = WeaveAPI.SessionManager.getObject(root, objectPath);
			
			// check for exact match only
			if (child && child.constructor == classDef)
				return true;
			
			externalError("Request for {0} failed at path {1}", objectType, JSON.stringify(objectPath));
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
			var parent:ILinkableObject = WeaveAPI.SessionManager.getObject(root, parentPath);
			
			var hashMap:ILinkableHashMap = parent as ILinkableHashMap;
			if (hashMap)
			{
				if (childName is Number)
					childName = hashMap.getNames()[childName];
				
				if (hashMap.objectIsLocked(childName as String))
				{
					externalError("Object is locked and cannot be removed (path: {0})", JSON.stringify(objectPath));
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
					externalError("Object is locked and cannot be removed (path: {0})", JSON.stringify(objectPath));
					return false;
				}
				
				dynamicObject.removeObject();
				return true;
			}
			
			if (parent)
				externalError("Parent object does not support dynamic children, so cannot remove child at path {0}", JSON.stringify(objectPath));
			else
				externalError("No parent from which to remove a child at path {0}", JSON.stringify(objectPath));
			return false;
		}
		
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
				var object:ILinkableObject = WeaveAPI.SessionManager.getObject(root, objectPathOrVariableName as Array);
				if (object)
					return object;
				
				getObjectFromPathOrVariableName_error = "No ILinkableObject at path " + JSON.stringify(objectPathOrVariableName);
				return null;
			}
			
			var variableName:String = String(objectPathOrVariableName);
			if (variableName)
			{
				if (_variables.hasOwnProperty(variableName))
					return _variables[variableName];
				
				getObjectFromPathOrVariableName_error = "Undefined variable " + JSON.stringify(variableName);
				return null;
			}
			
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function evaluateExpression(scopeObjectPathOrVariableName:Object, expression:String, variables:Object = null, staticLibraries:Array = null, assignVariableName:String = null):*
		{
//			try
//			{
//				if (staticLibraries)
//					_compiler.includeLibraries.apply(null, staticLibraries);
//				
//				var isAssignment:Boolean = (assignVariableName != null); // allows '' to be used to ignore resulting value
//				if (assignVariableName && !_compiler.isValidSymbolName(assignVariableName))
//					throw new Error("Invalid variable name: " + Compiler.encodeString(assignVariableName));
//				
//				// To avoid "variable is undefined" errors, treat variables[''] as an Array of keys and set any missing properties to undefined
//				if (variables)
//					for each (var key:String in variables[''])
//						if (!variables.hasOwnProperty(key))
//							variables[key] = undefined;
//				
//				var thisObject:Object = getObjectFromPathOrVariableName(scopeObjectPathOrVariableName);
//				if (getObjectFromPathOrVariableName_error)
//					throw new Error(getObjectFromPathOrVariableName_error);
//				var compiledObject:ICompiledObject = _compiler.compileToObject(expression);
//				var isFuncDef:Boolean = _compiler.compiledObjectIsFunctionDefinition(compiledObject);
//				// passed-in variables take precedence over stored ActionScript _variables
//				var compiledMethod:Function = _compiler.compileObjectToFunction(
//					compiledObject,
//					[variables, _variables],
//					Weave.error,
//					thisObject != null,
//					null,
//					null,
//					true,
//					thisObject
//				);
//				var result:* = isFuncDef ? compiledMethod : compiledMethod.apply(thisObject);
//				if (isAssignment)
//					_variables[assignVariableName] = result;
//				else
//					return result;
//			}
//			catch (e:*)
//			{
//				externalError(e);
//			}
			return undefined;
		}
		
		/**
		 * Stores information for removeCallback() and removeAllCallbacks()
		 */
		private static var _d2d_callback_target:Dictionary2D;
		
		private static var _map_func_wrapper:Object;

		/**
		 * @inheritDoc
		 */
		public function addCallback(scopeObjectPathOrVariableName:Object, callback:Function, triggerCallbackNow:Boolean = false, immediateMode:Boolean = false, delayWhileBusy:Boolean = true):Boolean
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
					externalError("No ILinkableObject to which to add a callback at path or variable {0}", JSON.stringify(scopeObjectPathOrVariableName));
					return false;
				}
				
				if (delayWhileBusy)
				{
					callback = _map_func_wrapper.get(callback);
					if (!callback)
						_map_func_wrapper.set(callback, callback = generateBusyWaitWrapper(callback));
				}
				
				_d2d_callback_target.set(callback, object, true);
				if (immediateMode)
					WeaveAPI.SessionManager.getCallbackCollection(object).addImmediateCallback(null, callback, triggerCallbackNow);
				else
					WeaveAPI.SessionManager.getCallbackCollection(object).addGroupedCallback(null, callback, triggerCallbackNow);
				return true;
			}
			catch (e:Error)
			{
				// unexpected error
				Weave.error(e);
			}
			return false;
		}
		
		private function generateBusyWaitWrapper(callback:Function):Function
		{
			var wrapper:Function = function():void {
				var map_target:Object = _d2d_callback_target.map.get(wrapper);
				for each (var target:ILinkableObject in Weave.toArray(map_target.keys()))
					if (WeaveAPI.SessionManager.linkableObjectIsBusy(target))
						return;
				callback();
			};
			return wrapper;
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeCallback(objectPathOrVariableName:Object, callback:Function, everywhere:Boolean = false):Boolean
		{
			var wrapper:Function = _map_func_wrapper.get(callback);
			if (wrapper != null && !removeCallback(objectPathOrVariableName, wrapper, everywhere))
				return false;
			
			if (everywhere)
			{
				var map_target:Object = _d2d_callback_target.map.get(callback);
				if (map_target)
					for each (var target:ILinkableObject in Weave.toArray(map_target.keys()))
						WeaveAPI.SessionManager.getCallbackCollection(target).removeCallback(callback);
				
				_d2d_callback_target.removeAllPrimary(callback);
				_map_func_wrapper['delete'](callback);
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
					externalWarning("No ILinkableObject from which to remove a callback at path or variable {0}", JSON.stringify(objectPathOrVariableName));
					return false;
				}
				
				_d2d_callback_target.remove(callback, object);
				WeaveAPI.SessionManager.getCallbackCollection(object).removeCallback(callback);
				return true;
			}
			catch (e:Error)
			{
				// unexpected error
				Weave.error(e);
			}
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeAllCallbacks():void
		{
			_d2d_callback_target.forEach(removeAllCallbacks_each, this);
			_d2d_callback_target = new Dictionary2D();
		}
		private function removeAllCallbacks_each(callback:Function, target:ILinkableObject, value:*):void
		{
			WeaveAPI.SessionManager.getCallbackCollection(target).removeCallback(callback);
		}
		
		private static function externalError(format:String, ...args):void
		{
			var str:String = StandardLib.substitute(format, args);
			// temporary solution for Flash not escaping double-quotes when generating JavaScript throw statement
			str = StandardLib.replace(str, '"', "'");
			throw new Error(str);
		}
		
		private static function externalWarning(format:String, ...args):void
		{
			Weave.error(StandardLib.substitute("Warning: " + format, args));
		}
	}
}
