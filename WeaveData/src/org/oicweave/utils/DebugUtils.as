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

package org.oicweave.utils
{
	import flash.events.TimerEvent;
	import flash.utils.*;
	
	import mx.controls.Alert;
	
	import org.oicweave.core.LinkableBoolean;
	import org.oicweave.core.SessionManager;
	
	/**
	 * DebugUtils
	 * 
	 * @author abaumann
	 * @author adufilie
	 */
	public class DebugUtils
	{
		// format debug info from stack trace
		public static function getCompactStackTrace(e:Error):Array
		{
			if (!SessionManager.runningDebugFlashPlayer)
				return null;
			var lines:Array = e.getStackTrace().split('\n\tat ');
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
		 * generateID
		 * This function returns a unique integer each time it is called.
		 */
		private static var nextGeneratedID:int = 0;
		public static function generateID():int
		{
			return nextGeneratedID++;
		}
		
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
		 * callLater
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
	}
}