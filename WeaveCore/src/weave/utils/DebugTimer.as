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
	import flash.utils.getTimer;
	
	import weave.compiler.StandardLib;
	
	/**
	 * This class acts like a stop watch that supports nested begin/end times.
	 * Pairs of calls to begin() and end() may be nested.
	 * 
	 * @author adufilie
	 */
	public class DebugTimer
	{
		/**
		 * This is a list of nested start times.
		 */
		private static const debugTimes:Array = [];
		
		/**
		 * This will record the current time as a new start time for comparison when lap() or end() is called.
		 * Pairs of calls to begin() and end() may be nested.
		 */
		public static function begin():void
		{
			debugTimes.push(getTimer());
		}
		
		/**
		 * This will report the time since the last call to begin() or lap().
		 * @param debugString A string to print using trace().
		 * @param debugStrings Additional strings to print using trace(), which will be separated by spaces.
		 */
		public static function lap(debugString:String, ...debugStrings):void
		{
			debugStrings.unshift(debugString);
			end.apply(null, debugStrings);
			begin();
		}
		
		/**
		 * This will reset the timer so that higher-level functions can resume their use of DebugTimer.
		 * Pairs of calls to begin() and end() may be nested.
		 * @param debugString A string to print using trace().
		 * @param debugStrings Additional strings to print using trace(), which will be separated by spaces.
		 */
		public static function end(debugString:String, ...debugStrings):void
		{
			debugStrings.unshift(debugString);
			var elapsedTime:int = (getTimer() - debugTimes.pop());
			var elapsed:String = '['+elapsedTime+' ms elapsed] ';
			var elapsedIndent:String = StandardLib.lpad('| ', elapsed.length);
			var indent:String = StandardLib.rpad('', debugTimes.length * 2, '| ');
			var lines:Array = debugStrings.join(' ').split('\n');
			for (var i:int = 0; i < lines.length; i++)
			{
				if (lines.length == 1)
					lines[i] = (indent + ',-' + elapsed + lines[i]);
				else if (i == 0)
					lines[i] = (indent + ',-' + elapsed + lines[i]);
				else if (i > 0 && i < lines.length - 1)
					lines[i] = (indent + '| ' + elapsedIndent + lines[i]);
				else
					lines[i] = (indent + '|-' + elapsed + lines[i]);
			}
			trace(lines.join('\n'));
		}
	}
}
