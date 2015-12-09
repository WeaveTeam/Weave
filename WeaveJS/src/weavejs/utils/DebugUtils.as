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

package weavejs.utils
{
	import weavejs.api.core.DynamicState;
	import weavejs.api.core.ILinkableObject;
	import weavejs.core.LinkableHashMap;
	import weavejs.core.LinkableString;
	import weavejs.core.LinkableVariable;
	
	/**
	 * Tools for debugging.
	 * 
	 * @author adufilie
	 */
	public class DebugUtils
	{
		/****************************
		 **  Object id and lookup  **
		 ****************************/
		
		private static var map_id_obj:Object = new JS.Map();
		private static var map_obj_id:Object = new JS.Map();
		private static var _nextId:int = 0;
		
		/**
		 * This function calls trace() using debugId() on each parameter.
		 */
		public static function debugTrace(...args):void
		{
			for (var i:int = 0; i < args.length; i++)
				args[i] = debugId(args[i]);
			
			JS.log.apply(JS, args);
		}
		
		/**
		 * This function generates or returns a previously generated identifier for an object.
		 */
		public static function debugId(object:Object):String
		{
			if (JS.isPrimitive(object))
				return String(object);
			var idString:String = map_obj_id.get(object);
			if (!idString)
			{
				var idNumber:int = _nextId++;
				var className:String = Weave.className(object).split(':').pop();
				idString = className + '#' + idNumber;
				
				// save lookup from object to idString
				map_obj_id.set(object, idString);
				// save lookup from idString and idNumber to object
				map_id_obj.set(idNumber, object);
				map_id_obj.set(idString, object);
			}
			return idString;
		}
		
		/**
		 * This function will look up the object corresponding to the specified debugId.
		 * @param debugId A debugId String or integer.
		 */
		public static function debugLookup(debugId:* = undefined):Object
		{
			if (debugId === undefined)
				return getAllDebugIds();
			return map_id_obj.get(debugId);
		}
		
		public static function getAllDebugIds():Array
		{
			var ids:Array = new Array(_nextId);
			for (var i:int = 0; i < _nextId; i++)
				ids[i] = map_obj_id.get(map_id_obj.get(i));
			return ids;
		}
		
		/**
		 * This will clear all saved ids and pointers to corresponding objects.
		 */		
		public static function resetDebugIds():void
		{
			map_id_obj = new JS.Map();
			map_obj_id = new JS.Map();
			_nextId = 0;
		}
		
		/**************
		 ** Watching **
		 **************/
		
		private static const map_target_callback:Object = new JS.WeakMap();
		
		public static function watch(target:ILinkableObject = null, callbackReturnsString:Function = null):void
		{
			if (!target)
			{
				JS.log('Usage: watch(target, optional_callbackReturnsString)');
				return;
			}
			
			unwatch(target);
			var callback:Function = function():void {
				var str:String = '';
				var path:Array = Weave.findPath(Weave.getRoot(target), target) || [];
				if (path.length)
					str += " " + JSON.stringify(path.pop());
				if (callbackReturnsString != null)
					str += ': ' + callbackReturnsString.call(target, target);
				debugTrace(target, str);
			};
			map_target_callback.set(target, callback);
			Weave.getCallbacks(target).addImmediateCallback(target, callback);
		}
		
		public static function watchState(target:ILinkableObject = null, indent:* = null):void
		{
			if (!target)
			{
				JS.log('Usage: watchState(target, optional_indent)');
				return;
			}
			watch(target, function(object:ILinkableObject):String { return Weave.stringify(Weave.getState(object), null, indent); });
		}
		
		public static function unwatch(target:ILinkableObject):void
		{
			var callback:Function = map_target_callback.get(target);
			map_target_callback['delete'](target);
			Weave.getCallbacks(target).removeCallback(target, callback);
		}
		
		/*********************
		 **  Miscellaneous  **
		 *********************/
		
		/**
		 * @param state A session state.
		 * @return An Array of Arrays, each like [path, value].
		 */
		public static function flattenSessionState(state:Object, pathPrefix:Array = null, output:Array = null):Array
		{
			if (!pathPrefix)
				pathPrefix = [];
			if (!output)
				output = [];
			if (DynamicState.isDynamicStateArray(state))
			{
				var names:Array = [];
				for each (var obj:Object in state)
				{
					if (DynamicState.isDynamicState(obj))
					{
						var objectName:String = obj[DynamicState.OBJECT_NAME];
						var className:String = obj[DynamicState.CLASS_NAME];
						var sessionState:Object = obj[DynamicState.SESSION_STATE];
						pathPrefix.push(objectName);
						if (className)
							output.push([pathPrefix.concat('class'), className]);
						flattenSessionState(sessionState, pathPrefix, output);
						pathPrefix.pop();
						
						if (objectName)
							names.push(objectName);
					}
					else
						names.push(obj);
				}
				if (names.length)
					output.push([pathPrefix.concat(), names]);
			}
			else if (state is Array)
			{
				output.push([pathPrefix.concat(), state]);
			}
			else if (typeof state === 'object' && state !== null)
			{
				for (var key:String in state)
				{
					pathPrefix.push(key);
					flattenSessionState(state[key], pathPrefix, output);
					pathPrefix.pop();
				}
			}
			else
			{
				output.push([pathPrefix.concat(), state]);
			}
			
			return output;
		}
		
		/**
		 * Traverses a path in a session state using the logic used by SessionManager.
		 * @param state A full session state.
		 * @param path A path.
		 * @return The session state at the specified path.
		 */
		public static function traverseStatePath(state:Object, path:Array):*
		{
			try
			{
				outerLoop: for each (var property:* in path)
				{
					if (DynamicState.isDynamicStateArray(state))
					{
						if (property is Number)
						{
							state = state[property][DynamicState.SESSION_STATE];
						}
						else
						{
							for each (var obj:Object in state)
							{
								if (obj[DynamicState.OBJECT_NAME] == property)
								{
									state = obj[DynamicState.SESSION_STATE];
									continue outerLoop;
								}
							}
							return undefined;
						}
					}
					else
						state = state[property];
				}
				return state;
			}
			catch (e:Error)
			{
				return undefined;
			}
		}
		
		private static function isValidSymbolName(str:String):Boolean
		{
			return true; // temporary solution
		}
		
//		public static function historyToCSV(weave:Weave):String
//		{
//			var data:Array = [['t','path','value']].concat.apply(null, weave.history.undoHistory.map((e,t)=>flattenSessionState(e.forward).map((a,i)=>[t,'Weave'+a[0].map(n=>isValidSymbolName(n)?'.'+n:Weave.stringify([n])).join(''),Weave.stringify(a[1])])));
//			var name:String = WeaveAPI.globalHashMap.generateUniqueName("Session History");
//			var csv:CSVDataSource = WeaveAPI.globalHashMap.requestObject(name, CSVDataSource, false);
//			csv.csvData.setSessionState(data);
//			var table:TableTool = weave.root.requestObject(null, TableTool, false);
//			data[0].forEach(n=>csv.putColumnInHashMap(n, table.columns));
//		}
		
		public static function replaceUnknownObjectsInState(stateToModify:Object, className:String = null):Object
		{
			if (DynamicState.isDynamicStateArray(stateToModify))
			{
				for each (var obj:Object in stateToModify)
				{
					if (DynamicState.isDynamicState(obj) && !Weave.getDefinition(obj[DynamicState.CLASS_NAME]))
					{
						obj[DynamicState.CLASS_NAME] = Weave.className(LinkableHashMap);
						obj[DynamicState.SESSION_STATE] = replaceUnknownObjectsInState(obj[DynamicState.SESSION_STATE], obj[DynamicState.CLASS_NAME]);
					}
				}
			}
			else if (!JS.isPrimitive(stateToModify))
			{
				var newState:Array = [DynamicState.create("class", Weave.className(LinkableString), className)];
				for (var key:String in stateToModify)
				{
					var value:Object = stateToModify[key];
					var type:String = Weave.className(JS.isPrimitive(value) ? LinkableVariable : LinkableHashMap);
					newState.push(DynamicState.create(key, type, value));
				}
				stateToModify = newState;
			}
			return stateToModify;
		}
	}
}
