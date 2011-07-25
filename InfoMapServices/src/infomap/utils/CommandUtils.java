package infomap.utils;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class CommandUtils

{

    public static int runCommand(String[] args) throws IOException

    {

        Runtime run = Runtime.getRuntime();

        Process proc = null;

        proc = run.exec(args);

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

                    stdout.skip(Long.MAX_VALUE);

                    //line = stdout.readLine();

                }

                else if (stderr.ready())

                {

                    stderr.skip(Long.MAX_VALUE);

                    //line = stderr.readLine();

                }

                // print out data from stream

                if (line != null)

                {

                    //System.out.println(line);

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