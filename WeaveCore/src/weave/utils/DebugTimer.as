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
		 * Cancels the last call to begin().
		 */
		public static function cancel():void
		{
			debugTimes.pop();
		}
		
		/**
		 * This will report the time since the last call to begin() or lap().
		 * @param debugString A string to print using trace().
		 * @param debugStrings Additional strings to print using trace(), which will be separated by spaces.
		 * @return The elapsed time.
		 */
		public static function lap(debugString:String, ...debugStrings):int
		{
			debugStrings.unshift(debugString);
			var elapsedTime:int = end.apply(null, debugStrings);
			begin();
			return elapsedTime;
		}
		
		/**
		 * This will reset the timer so that higher-level functions can resume their use of DebugTimer.
		 * Pairs of calls to begin() and end() may be nested.
		 * @param debugString A string to print using trace().
		 * @param debugStrings Additional strings to print using trace(), which will be separated by spaces.
		 * @return The elapsed time.
		 */
		public static function end(debugString:String, ...debugStrings):int
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
			
			if (elapsedTime > 1000)
				trace(); // put breakpoint here
			
			return elapsedTime;
		}
	}
}
