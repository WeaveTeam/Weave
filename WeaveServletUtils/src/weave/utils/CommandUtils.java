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

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;

public class CommandUtils
{
	
    public static int runCommand(String[] args) throws IOException
    {
    	return runCommand(args, null, null, false);
    }
    
    public static int runCommand(String[] args, boolean debug) throws IOException
    {
    	return runCommand(args, null, null, debug);
    }
    
	public static int runCommand(String[] args, String[] envp, File dir) throws IOException
	{
		return runCommand(args, envp, dir, false);
	}

    public static int runCommand(String[] args, String[] envp, File dir, boolean debug) throws IOException
	{
		Runtime run = Runtime.getRuntime();
        Process proc = null;
        proc = run.exec(args, envp, dir);
        BufferedReader stdout = new BufferedReader( new InputStreamReader(proc.getInputStream()) );
        BufferedReader stderr = new BufferedReader( new InputStreamReader(proc.getErrorStream()) );
        while (true)
        {
        	String line = null;
            try
            {
                // check both streams for new data
                if (stdout.ready())
                {
                	if (debug)
                		line = stdout.readLine();
                	else
                		stdout.skip(Long.MAX_VALUE);
                }
                else if (stderr.ready())
                {
                	if (debug)
                		line = stderr.readLine();
                	else
                		stderr.skip(Long.MAX_VALUE);
                }
                
				// print out data from stream
				if (line != null)
				{
					System.out.println(line);
					continue;
				}
            }
            catch (IOException ioe)
            {
                // stream error, get the return value of the process and return from this function
                try {
                    return proc.exitValue();
                } catch (IllegalThreadStateException itse) {
                    return -Integer.MAX_VALUE;
                }
            }
            try
            {
                // if process finished, return
                return proc.exitValue();
            }
            catch (IllegalThreadStateException itse)
            {
                // process is still running, continue
            }
        }
    }
}