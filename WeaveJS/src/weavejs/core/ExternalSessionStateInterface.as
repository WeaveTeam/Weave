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
	import weavejs.path.WeavePath;
	import weavejs.utils.Dictionary2D;
	import weavejs.utils.JS;

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
		}
		
		/**
		 * The root object in the session state tree.
		 */
		private var root:ILinkableHashMap;
		
		/**
		 * @inheritDoc
		 */
		public function requestObject(path:WeavePath, objectType:String):Boolean
		{
			// get class definition
			var classDef:Class = Weave.getDefinition(objectType);
			if (classDef == null)
			{
				throwError("No class definition for {0}", JSON.stringify(objectType));
				return false;
			}
			
			// stop if there is no path specified
			var objectPath:Array = path.getPath();
			if (!objectPath || !objectPath.length)
			{
				// check for exact match only
				if (Object(root).constructor == classDef)
					return true;
				
				throwError("Cannot request an object at the root path");
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
			
			throwError("Request for {0} failed at path {1}", objectType, JSON.stringify(objectPath));
			return false;
		}

		/**
		 * @inheritDoc
		 */
		public function removeObject(path:WeavePath):Boolean
		{
			if (!path || !path.getPath().length)
			{
				throwError("Cannot remove root object");
				return false;
			}
			
			var parentPath:Array = path.getPath();
			var childName:Object = parentPath.pop();
			var parent:ILinkableObject = WeaveAPI.SessionManager.getObject(root, parentPath);
			
			var hashMap:ILinkableHashMap = parent as ILinkableHashMap;
			if (hashMap)
			{
				if (childName is Number)
					childName = hashMap.getNames()[childName];
				
				if (hashMap.objectIsLocked(childName as String))
				{
					throwError("Object is locked and cannot be removed: {0}", path);
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
					throwError("Object is locked and cannot be removed: {0}", path);
					return false;
				}
				
				dynamicObject.removeObject();
				return true;
			}
			
			if (parent)
				throwError("Parent object does not support dynamic children, so cannot remove child at {0}", path);
			else
				throwError("No parent from which to remove a child at {0}", path);
			return false;
		}
		
		/**
		 * Stores information for removeCallback() and removeAllCallbacks()
		 */
		private static var _d2d_callback_target:Dictionary2D = new Dictionary2D();
		
		private static var _map_func_wrapper:Object = new JS.Map();

		/**
		 * @inheritDoc
		 */
		public function addCallback(path:WeavePath, callback:Function, triggerCallbackNow:Boolean = false, immediateMode:Boolean = false, delayWhileBusy:Boolean = true):Boolean
		{
			try
			{
				if (!path)
				{
					throwError("addCallback(): No path given");
					return false;
				}
				
				var object:ILinkableObject = WeaveAPI.SessionManager.getObject(root, path.getPath());
				if (!object)
				{
					throwError("No ILinkableObject to which to add a callback at path or variable {0}", JSON.stringify(path));
					return false;
				}
				
				if (delayWhileBusy)
				{
					var wrapper:Function = _map_func_wrapper.get(callback);
					if (!wrapper)
					{
						wrapper = generateBusyWaitWrapper(callback, path);
						_map_func_wrapper.set(callback, wrapper);
					}
					callback = wrapper;
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
				JS.error(e);
			}
			return false;
		}
		
		private function generateBusyWaitWrapper(callback:Function, path:WeavePath):Function
		{
			var wrapper:Function = function():void {
				var targets:Array = _d2d_callback_target.secondaryKeys(wrapper);
				for each (var target:ILinkableObject in targets)
					if (WeaveAPI.SessionManager.linkableObjectIsBusy(target))
						return;
				callback.apply(path);
			};
			return wrapper;
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeCallback(path:WeavePath, callback:Function, everywhere:Boolean = false):Boolean
		{
			var wrapper:Function = _map_func_wrapper.get(callback);
			if (wrapper != null && !removeCallback(path, wrapper, everywhere))
				return false;
			
			if (everywhere)
			{
				var targets:Array = _d2d_callback_target.secondaryKeys(callback);
				for each (var target:ILinkableObject in targets)
					WeaveAPI.SessionManager.getCallbackCollection(target).removeCallback(callback);
				
				_d2d_callback_target.removeAllPrimary(callback);
				_map_func_wrapper['delete'](callback);
				return true;
			}
			
			try
			{
				if (!path)
				{
					warning("removeCallback(): No path or variable name given");
					return false;
				}

				var object:ILinkableObject = WeaveAPI.SessionManager.getObject(root, path.getPath());
				if (!object)
				{
					warning("No ILinkableObject from which to remove a callback at path or variable {0}", JSON.stringify(path));
					return false;
				}
				
				_d2d_callback_target.remove(callback, object);
				WeaveAPI.SessionManager.getCallbackCollection(object).removeCallback(callback);
				return true;
			}
			catch (e:Error)
			{
				// unexpected error
				JS.error(e);
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
		
		private static function throwError(format:String, ...args):void
		{
			throw new Error(StandardLib.substitute(format, args));
		}
		
		private static function warning(format:String, ...args):void
		{
			JS.error(StandardLib.substitute("Warning: " + format, args));
		}
	}
}
