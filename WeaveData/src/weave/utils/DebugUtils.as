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
	import flash.utils.*;
	
	import mx.controls.Alert;
	import mx.utils.StringUtil;
	
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	
	/**
	 * DebugUtils
	 * 
	 * @author abaumann
	 * @author adufilie
	 */
	public class DebugUtils
	{
		public static function debugDisplayList(root:DisplayObject, maxDepth:int = -1, currentDepth:int = 0):String
		{
			var str:String = StringUtil.substitute(
				'{0}{1} ({2})\n',
				StandardLib.lpad('', currentDepth * 2, '| '),
				root.name,
				getQualifiedClassName(root)
			);
			var container:DisplayObjectContainer = root as DisplayObjectContainer;
			if (container && currentDepth != maxDepth)
				for (var i:int = 0; i < container.numChildren; i++)
					str += debugDisplayList(container.getChildAt(i), maxDepth, currentDepth + 1);
			if (currentDepth == 0)
				trace(str);
			return str;
		}
		
		private static const STACK_TRACE_DELIM:String = '\n\tat ';
		/**
		 * format debug info from stack trace
		 * @author adufilie
		 */
		public static function getCompactStackTrace(e:Error):Array
		{
			if (!Capabilities.isDebugger)
				return null;
			var lines:Array = e.getStackTrace().split(STACK_TRACE_DELIM);
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

		/**
		 * This function returns a unique integer each time it is called.
		 */
		public static function generateID():int
		{
			return nextGeneratedID++;
		}
		private static var nextGeneratedID:int = 0;
		
		//		public static function debugLinkableObject(object:ILinkableObject):void
		//		{
		//			SessionManager.addImmediateCallback(object, _debugLinkableObject, [object], true);
		//		}
		//		
		//		private static function _debugLinkableObject(object:ILinkableObject):void
		//		{
		//			var state:Object = SessionManager.getSessionState(object);
		//			return; // add breakpoint here
		//		}
		
		public static const enableDebugAlert:LinkableBoolean = new LinkableBoolean(false);
		
		public static function _trace(...args):void { trace(args); };
		
		public static function debug_trace(originClass:Object, ... args):void
		{
			var classStr:String = "[" + getTimer() + "] {" + getQualifiedClassName(originClass) + "}";
			var traceStr:String = "";
			
			for each (var item:* in args)
			{
				if (item is Array)
				{
					for each (var arrayElement:* in item)
						traceStr += formatDebugItem(arrayElement);
				}
				else if (item is XML)
					traceStr += (item as XML).toXMLString();
				else
					traceStr += formatDebugItem(item);
			}
			
			if (enableDebugAlert.value)
				Alert.show(traceStr, classStr);
			
			trace(classStr + "\n" + traceStr);
		}
		
		private static function formatDebugItem(item:*):String
		{
			var indent:int = 24;
			var classStr:String = getQualifiedClassName(item);
			
			// get rid of path
			var pos:int = classStr.indexOf("::");
			if (pos >= 0)
				classStr = classStr.substr(pos + 2);
			
			// indent so ':' will line up
			classStr = "  {" + classStr + "}";
			while (classStr.length < indent)
				classStr += " ";
			
			return classStr + ":  " + item + "\n";
		}
		
		/**
		 * @author adufilie
		 */		
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
		 * 
		 * @author adufilie
		 */
		public static function callLater(delay:int, func:Function, params:Array = null):void
		{
			var t:Timer = new Timer(delay, 1);
			t.addEventListener(TimerEvent.TIMER, function(..._):*{ func.apply(null, params); });
			t.start();
		}
		
		/**
		 * This function will increment a counter associated with a line of code that is causing this function to be called.
		 * @param stackDepth The stack depth to record in the profile data.  Default zero will profile the line that is calling this function.
		 * 
		 * @author adufilie
		 */
		public static function profile(stackDepth:int = 0):void
		{
			// stop if disabled
			if (!_profileLookup)
				return;
			
			var stackTrace:String = new Error().getStackTrace();
			
			// disable when not running debug player
			if (!stackTrace)
			{
				_profileLookup = null;
				return;
			}
			
			var stack:Array = stackTrace.split(STACK_TRACE_DELIM);
			// stack[1] is the line in this file
			// stack[2] is the line that called this function
			var line:String = stack[2 + stackDepth];
			_profileLookup[line] = uint(_profileLookup[line]) + 1;
		}
		private static var _profileLookup:Object = {};
		
		/**
		 * This will retrieve a dynamic object containing the current profile data,
		 * mapping a line of code to a number indicating how many times that line was executed.
		 * @param reset Set this to true to clear the current profile data.
		 * @return The current profile data.
		 * 
		 * @author adufilie
		 */
		public static function profileDump(reset:Boolean = false):Object
		{
			// stop if disabled
			if (!_profileLookup)
				return null;
			
			var dump:Object = _profileLookup;
			if (reset)
				_profileLookup = {};
			return dump;
		}
	}
}