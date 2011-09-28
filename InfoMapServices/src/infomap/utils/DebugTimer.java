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

package infomap.utils;

/**
 * DebugTimer
 * 
 * @author Andy Dufilie
 */
public class DebugTimer
{
	public DebugTimer()
	{
		start();
	}
	private long startTime;
	private String debugText = "";
	public void start()
	{
		startTime = System.currentTimeMillis();
	}
	public long get()
	{
		return System.currentTimeMillis() - startTime;
	}
	public void lap(String str)
	{
		String time = "" + get();
		String indent = new String("    ".getBytes(), 0, Math.max(0, 5 - time.length()));
		debugText += indent + time + " ms: " + str + "\n";
		start();
	}
	public void report(String lapText)
	{
		lap(lapText);
		report();
	}
	public void report()
	{
		//System.out.println(debugText);
		debugText = "";
	}
}
