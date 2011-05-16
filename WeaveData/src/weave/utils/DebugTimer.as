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
	
	import weave.compiler.StringLib;
	
	/**
	 * DebugTimer
	 * This class acts like a stop watch.
	 * 
	 * @author adufilie
	 */
	public class DebugTimer
	{
		public function DebugTimer(autoStart:Boolean = true)
		{
			if (autoStart)
				start();
			else
				reset();
		}

		public var running:Boolean = false;

		// reset the time to 0, return time before start
		private var startTime:int;
		public function start():int
		{
			var prevTime:int = time;
			running = true;
			startTime = getTimer();
			return prevTime;
		}

		// save the current time and stop the timer, return current time
		public function stop():int
		{
			var prevTime:int = time; // get current time
			running = false;
			return prevTime;
		}

		// stop the timer and clear the time, return time before reset
		public function reset():int
		{
			var prevTime:int = stop();
			_time = -1;
			return prevTime;
		}

		// get the current time
		private var _time:int;
		public function get time():int
		{
			if (running)
				_time = getTimer() - startTime;
			return _time;
		}
		
		// get elapsed time, print it out with a debug string, and restart the timer
		public function debug(str:String):int
		{
			var elapsed:int = start();
			trace('[' + elapsed + ' ms elapsed] ' + str);
			return elapsed;
		}

		// get the current time
		public function toString():String
		{
			return time + " ms";
		}
		
		/**  static functions  **/
		
		private static const debugTimes:Array = [];
		public static function begin():void
		{
			debugTimes.push(getTimer());
		}
		public static function restart(...debugStrings):void
		{
			end.apply(null, debugStrings);
			begin();
		}
		public static function end(...debugStrings):void
		{
			var elapsedTime:int = (getTimer() - debugTimes.pop());
			var elapsed:String = '['+elapsedTime+' ms elapsed] ';
			var elapsedIndent:String = StringLib.lpad('| ', elapsed.length);
			var indent:String = StringLib.rpad('', debugTimes.length * 2, '| ');
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
