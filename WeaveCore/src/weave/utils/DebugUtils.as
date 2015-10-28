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

package weave.utils
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	
	import avmplus.DescribeType;
	
	import weave.api.getCallbackCollection;
	import weave.api.getSessionState;
	import weave.api.core.DynamicState;
	import weave.api.core.ILinkableObject;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	
	/**
	 * Tools for debugging.
	 * 
	 * @author adufilie
	 */
	public class DebugUtils
	{
		public static function _testVariableLengthEncoding(random:Boolean = true, count:uint = 10000, max:uint = int.MAX_VALUE):void
		{
			var i:uint;
			var b:uint;
			var value:uint;
			var array:Array = new Array(count);
			var bytes1:ByteArray = new ByteArray();
			var bytes2:ByteArray = new ByteArray();
			for (i = 0; i < array.length; i++)
			{
				value = random ? uint(Math.random() * max) : i;
				array[i] = value;
				bytes1.writeUnsignedInt(value);
				
				do {
					b = value & 0x7F;
					value = (value >> 7) & 0x01FFFFFF;
					if (value == 0)
					{
						bytes2.writeByte(b);
						break;
					}
					
					bytes2.writeByte(b | 0x80);
				} while (true);
			}
			bytes1.position = 0;
			bytes2.position = 0;
			
			weaveTrace(StandardLib.substitute('array.length {0}, bytes1.length {1}, bytes2.length {2}',array.length,bytes1.length, bytes2.length));
			
			DebugTimer.begin();
			
			i = 0;
			while (bytes1.bytesAvailable)
			{
				value = bytes1.readUnsignedInt();
				if (array[i++] != value)
					throw "bytes1 fail";
			}
			
			DebugTimer.lap('bytes1');
			
			i = 0;
			while (bytes2.bytesAvailable)
			{
				value = (b = bytes2.readUnsignedByte()) & 0x7F;
				for (var s:uint = 7; b & 0x80; s += 7)
					value |= ((b = bytes2.readUnsignedByte()) & 0x7F) << s;
				
				if (array[i++] != value)
					throw "bytes2 fail";
			}
			
			DebugTimer.end('bytes2');
		}
		
		
		/****************************
		 **  Object id and lookup  **
		 ****************************/
		
		private static var _idToObjRef:Dictionary = new Dictionary();
		private static var _objToId:Dictionary = new Dictionary(true); // weakKeys=true to avoid memory leak
		private static var _nextId:int = 0;
		
		/**
		 * This function calls trace() using debugId() on each parameter.
		 */
		public static function debugTrace(...args):void
		{
			for (var i:int = 0; i < args.length; i++)
				args[i] = debugId(args[i]);
			
			weaveTrace.apply(null, args);
		}
		
		/**
		 * This function generates or returns a previously generated identifier for an object.
		 */
		public static function debugId(object:Object):String
		{
			var type:String = typeof(object);
			if (object == null || type != 'object' && type != 'function')
				return String(object);
			var idString:String = _objToId[object];
			if (!idString)
			{
				var idNumber:int = _nextId++;
				var className:String = getQualifiedClassName(object).split(':').pop();
				idString = className + '#' + idNumber;
				
				var ref:Dictionary = new Dictionary(className != 'MethodClosure');
				ref[object] = true;
				// save lookup from object to idString
				_objToId[object] = idString;
				// save lookup from idString and idNumber to weak object reference
				_idToObjRef[idNumber] = ref;
				_idToObjRef[idString] = ref;
			}
			return idString;
		}
		
		/**
		 * This function will look up the object corresponding to the specified debugId.
		 * @param debugId A debugId String or integer.
		 */
		public static function debugLookup(debugId:* = undefined):Object
		{
			if (debugId == undefined)
				return getAllDebugIds();
			for (var object:Object in _idToObjRef[debugId])
				return object;
			return null;
		}
		
		public static function getAllDebugIds():Array
		{
			var ids:Array = new Array(_nextId);
			for (var i:int = 0; i < _nextId; i++)
				for (var object:Object in _idToObjRef[i])
					ids[i] = _objToId[object];
			return ids;
		}
		
		/**
		 * This will clear all saved ids and pointers to corresponding objects.
		 */		
		public static function resetDebugIds():void
		{
			_idToObjRef = new Dictionary();
			_objToId = new Dictionary(true);
			_nextId = 0;
		}
		
		/**
		 * This will keep strong pointers to identified objects if enabled.
		 */		
		public static function keepDebugIds(enable:Boolean = true):void
		{
			var old:Dictionary = _objToId;
			_objToId = new Dictionary(!enable);
			for (var key:Object in old)
				_objToId[key] = old[key];
		}
		
		/**************
		 ** Watching **
		 **************/
		
		public static function getObject(target:Object):ILinkableObject
		{
			if (target == null || target is ILinkableObject)
				return target as ILinkableObject;
			if (!(target is Array))
				target = WeaveAPI.CSVParser.parseCSVRow(String(target));
			return WeaveAPI.getObject(target as Array);
		}
		
		private static const watchLookup:Dictionary = new Dictionary(true);
		
		public static function watch(target:Object = null, callbackReturnsString:Function = null):void
		{
			if (!target)
			{
				weaveTrace('Usage: watch(target, optional_callbackReturnsString)');
				return;
			}
			
			keepDebugIds();
			
			var linkableTarget:ILinkableObject = getObject(target);
			unwatch(linkableTarget);
			var callback:Function = function():void {
				var str:String = '';
				var path:Array = WeaveAPI.getPath(linkableTarget) || []
				if (path.length)
					str += " " + Compiler.stringify(path.pop());
				if (callbackReturnsString != null)
					str += ': ' + callbackReturnsString.call(linkableTarget, linkableTarget);
				debugTrace(linkableTarget, str);
			};
			watchLookup[linkableTarget] = callback;
			getCallbackCollection(linkableTarget).addImmediateCallback(null, callback);
		}
		
		public static function watchState(target:Object = null, indent:* = null):void
		{
			if (!target)
			{
				weaveTrace('Usage: watchState(target, optional_indent)');
				return;
			}
			watch(target, function(object:ILinkableObject):String { return Compiler.stringify(getSessionState(object), null, indent); });
		}
		
		public static function unwatch(target:Object):void
		{
			var linkableTarget:ILinkableObject = getObject(target);
			var callback:Function = watchLookup[linkableTarget];
			delete watchLookup[linkableTarget];
			getCallbackCollection(linkableTarget).removeCallback(callback);
		}
		
		/*****************
		 **  Profiling  **
		 *****************/
		
		private static var _profileLookup:Object = null;
		private static var _canGetStackTrace:Boolean = new Error().getStackTrace() != null;
		
		/**
		 * This function will increment a counter associated with a line of code that is causing this function to be called.
		 * @param stackDepth The stack depth to record in the profile data.  Default zero will profile the line that is calling this function.
		 */
		public static function profile(description:String = null, stackDepth:int = 0):uint
		{
			var lookup:String = '';
			if (_canGetStackTrace)
			{
				var stackTrace:String = new Error().getStackTrace();
				var stack:Array = stackTrace.split(STACK_TRACE_DELIM);
				// stack[1] is the line in this file
				// stack[2] is the line that called this function
				lookup += stack[2 + stackDepth];
			}
			else if (!description)
			{
				// do nothing if we can't get a stack trace and there is no description
				return 0;
			}
			
			if (description)
				lookup += ' ' + description;
			if (!_profileLookup)
				_profileLookup = {};
			
			return _profileLookup[lookup] = uint(_profileLookup[lookup]) + 1;
		}
		
		/**
		 * This will retrieve a dynamic object containing the current profile data,
		 * mapping a line of code to a number indicating how many times that line was executed.
		 * @param reset Set this to true to clear the current profile data.
		 * @return The current profile data.
		 */
		public static function profileDump(reset:Boolean = false):Object
		{
			var dump:Object = _profileLookup;
			if (reset)
				_profileLookup = null;
			return dump;
		}
		
		
		/*********************
		 **  Miscellaneous  **
		 *********************/
		
		public static function debugDisplayList(root:DisplayObject = null, maxDepth:int = -1, labelPropertyOrFunction:* = 'name'):String
		{
			return _debugDisplayList(root || WeaveAPI.StageUtils.stage, maxDepth, labelPropertyOrFunction, 0, '', '');
		}
		private static function _debugDisplayList(root:DisplayObject, maxDepth:int, labelPropertyOrFunction:*, currentDepth:int, indent:String, childIndent:String):String
		{
			var rect:Rectangle = root.getRect(root.parent);
			var label:String;
			try
			{
				if (labelPropertyOrFunction is Function)
					label = labelPropertyOrFunction(root);
				else
					label = root[labelPropertyOrFunction];
			}
			catch (e:*) { }
			
			var str:String = StandardLib.substitute("{0}{1}({2}) {3}\n", indent, label != null ? label + ' ' : '', debugId(root), rect);
			
			var container:DisplayObjectContainer = root as DisplayObjectContainer;
			if (container && currentDepth != maxDepth)
			{
				var n:int = container.numChildren;
				for (var i:int = 0; i < n; i++)
				{
					var nextIndent:String = childIndent + (i < n - 1 ? indents[0] : indents[1]);
					var nextChildIndent:String = childIndent + (i < n - 1 ? indents[2] : indents[3]);
					str += _debugDisplayList(container.getChildAt(i), maxDepth, labelPropertyOrFunction, currentDepth + 1, nextIndent, nextChildIndent);
				}
			}
			return str;
		}
		private static const indents:Array = ['|- ', '`- ', '|  ', '   '];
		private static const indentsHeavy:Array = ['\u2523 ', '\u2517 ', '\u2503 ', '   '];
		private static const indentsLight:Array = ['\u251c ', '\u2514 ', '\u2502 ', '   '];
		
		private static const STACK_TRACE_DELIM:String = '\n\tat ';
		/**
		 * format debug info from stack trace
		 */
		public static function getCompactStackTrace(error_or_stack_trace:Object):Array
		{
			if (!Capabilities.isDebugger)
				return null;
			if (error_or_stack_trace is Error)
				error_or_stack_trace = (error_or_stack_trace as Error).getStackTrace();
			var lines:Array = String(error_or_stack_trace).split(STACK_TRACE_DELIM);
			lines.shift(); // remove the first line which is not part of the stack trace
			var i:int = 0;
			while (i < lines.length)
			{
				var line:String = lines[i];
				// remove namespace
				line = line.replace('http://www.adobe.com/2006/flex/mx/internal::', '');
				// skip package name
				var start:int = line.indexOf('::') + 2;
				if (start == 1) // if indexOf was -1
					start = 0;
				var end:int = 0;
				while (end < line.length && line.charAt(end) != '[')
					end++;

				var lineNumberIndex:int = line.length - 1;
				while (lineNumberIndex > end && line.charAt(lineNumberIndex) != ':')
					lineNumberIndex--;
				var lineNumber:String = '';
				if (lineNumberIndex > end)
					lineNumber = line.substring(lineNumberIndex, line.length - 1);
				
				var label:String = line.substring(start, end);
				if (label == 'Function/<anonymous>()')
				{
					var slashIndex:int = Math.max(line.lastIndexOf('/'), line.lastIndexOf('\\'));
					if (slashIndex >= 0)
						label = line.substring(slashIndex + 1, lineNumberIndex);
				}
				
				var newLine:String = label + lineNumber;
				if (newLine == 'apply()')
					lines.splice(i, 1);
				else
					lines[i++] = newLine;
			}
			return lines;
		}

		public static function getHexString(bytes:ByteArray):String
		{
			var hex:String = "0123456789ABCDEF";
			var buf:String = "";
			for (var i:int = 0; i < bytes.length; i++)
			{
				buf += hex.charAt(((bytes[i] & 0xFF) / 16) % 16);
				buf += hex.charAt((bytes[i] & 0xFF) % 16);
				
				// debug
				//buf += ((bytes[i] & 0xFF) as int).toString() + " ";
			}
			return buf;
		}
		
		/**
		 * @param func The function to call.
		 * @param params An array of parameters to pass to the function.
		 * @param delay The number of milliseconds to delay before the function is called.
		 */
		public static function callLater(delay:int, func:Function, params:Array = null):void
		{
			var t:Timer = new Timer(delay, 1);
			t.addEventListener(TimerEvent.TIMER, function(..._):*{ func.apply(null, params); });
			t.start();
		}
		
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
					}
				}
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
		
		public static function copyProperties(object:Object):Object
		{
			var result:Object = {};
			for each (var list:Array in DescribeType.getInfo(object, DescribeType.ACCESSOR_FLAGS | DescribeType.VARIABLE_FLAGS)['traits'])
			for each (var item:Object in list)
			if (item.access != 'writeonly')
			{
				try
				{
					var name:* = item.uri ? new QName(item.uri, item.name) : item.name;
					result[String(name)] = object[name];
				}
				catch (e:Error)
				{
				}
			}
			return result;
		}
		
		public static function stringifyProperties(object:Object):String
		{
			var keys:Array = [];
			for (var key:String in object)
				keys.push(key);
			StandardLib.sortOn(keys, function(key:String):String { return key.split('::').pop(); });
			return keys.map(function(key:String, i:int, a:Array):String { return '\t' + key + ': ' + debugId(object[key]); }).join('\n');
		}
		
		public static const HISTORY_TO_CSV:String = StandardLib.unIndent(<![CDATA[
			var data = [['t','path','value']].concat.apply(null, Weave.history.undoHistory.map((e,t)=>flattenSessionState(e.forward).map((a,i)=>[t,'Weave'+a[0].map(n=>EquationColumn.compiler.isValidSymbolName(n)?'.'+n:Compiler.stringify([n])).join(''),Compiler.stringify(a[1])])));
			var name = WeaveAPI.globalHashMap.generateUniqueName("Session History");
			var csv = WeaveAPI.globalHashMap.requestObject(name, CSVDataSource, false);
			csv.csvData.setSessionState(data);
			var table = WeaveAPI.globalHashMap.requestObject(null, TableTool, false);
			data[0].forEach(n=>csv.putColumnInHashMap(n, table.columns));
		]]>);
	}
}
