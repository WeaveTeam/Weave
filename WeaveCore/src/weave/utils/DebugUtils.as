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

package weave.utils
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.TimerEvent;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.StringUtil;
	
	import weave.compiler.StandardLib;
	
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
		
		private static var _idToObjRef:Dictionary = new Dictionary();
		private static var _objToId:Dictionary = new Dictionary(true);
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
		
		public static function debugDisplayList(root:DisplayObject, maxDepth:int = -1, currentDepth:int = 0):String
		{
			var str:String = StringUtil.substitute(
				'{0}{1} ({2})\n',
				StandardLib.lpad('', currentDepth * 2, '| '),
				root.name,
				debugId(root)
			);
			var container:DisplayObjectContainer = root as DisplayObjectContainer;
			if (container && currentDepth != maxDepth)
				for (var i:int = 0; i < container.numChildren; i++)
					str += debugDisplayList(container.getChildAt(i), maxDepth, currentDepth + 1);
			if (currentDepth == 0)
				debugTrace(str);
			return str;
		}
		
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
			for (var i:int = 0; i < lines.length; i++)
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
				
				lines[i] = line.substring(start, end) + lineNumber;
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
		 * @param delay The delay before the function is called.
		 */
		public static function callLater(delay:int, func:Function, params:Array = null):void
		{
			var t:Timer = new Timer(delay, 1);
			t.addEventListener(TimerEvent.TIMER, function(..._):*{ func.apply(null, params); });
			t.start();
		}
	}
}
