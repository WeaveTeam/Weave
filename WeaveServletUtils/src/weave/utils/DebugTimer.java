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

package weave.utils;

/**
 * DebugTimer
 * 
 * @author Andy Dufilie
 */
public class DebugTimer
{
	private final long ONE_MILLISECOND = 1000000;

	private long startTime;
	private StringBuilder debugText = new StringBuilder();
	
	public long threshold = 5;
	
	public DebugTimer()
	{
		threshold = 5;
		start();
	}
	
	public DebugTimer(long threshold)
	{
		this.threshold = threshold;
		start();
	}
	
	public void start()
	{
		startTime = System.nanoTime();
	}
	
	/**
	 * @return The timer value in milliseconds
	 */
	public long get()
	{
		return (System.nanoTime() - startTime) / ONE_MILLISECOND;
	}
	
	public void lap(String str)
	{
		long ms = get();
		if (ms > threshold)
		{
			String time = "" + ms;
			int indentLength = Math.max(0, 5 - time.length());
			debugText.append( "    ", 0, indentLength ).append( time ).append( " ms: " ).append( str ).append( '\n' );
		}
		start();
	}
	
	public void report(String lapText)
	{
		lap(lapText);
		report();
	}
	
	public void report()
	{
		if (debugText.length() > 0)
			System.out.println(debugText);
		reset();
	}
	
	public void reset()
	{
		debugText.setLength(0);
		start();
	}
	
	////////////////////////////////////////
	// static instance ... not thread safe
	
	private static DebugTimer instance = new DebugTimer();
	public static void go()
	{
		instance.start();
	}
	public static void stop(String description)
	{
		if (instance.get() > instance.threshold)
			instance.report(description);
		else
			instance.reset();
	}
}
