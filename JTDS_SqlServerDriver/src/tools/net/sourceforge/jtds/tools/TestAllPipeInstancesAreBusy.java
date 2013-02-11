// jTDS JDBC Driver for Microsoft SQL Server and Sybase
// Copyright (C) 2005 The jTDS Project
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
package net.sourceforge.jtds.tools;

import junit.framework.TestCase;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;
import java.io.PrintWriter;



/**
 * JUnit test class to expose the "All pipe instances are busy" error.
 * <p>
 * Run this class from two or more different computers (Linux and/or Windows)
 * so that multiple requests for the named pipe are hitting the server at the
 * same time.  There are many factors that exacerbate the issue, although
 * using SQL Server 6.5, slow (higher latency) TCP/IP connections and adding
 * more computers hitting the server simultaneously seem to be the top three.
 * <p>
 * See also <a href="http://support.microsoft.com/default.aspx?scid=KB;EN-US;165189">
 * INF: Multiple Named Pipes Connections May Cause Error 17832</a> on
 * Microsoft's knowledgebase web site.
 *
 * @author David D. Kilzer
 * @version $Id: TestAllPipeInstancesAreBusy.java,v 1.2 2005-09-06 22:57:08 ddkilzer Exp $
 */
public class TestAllPipeInstancesAreBusy extends TestCase {

    private static final Properties CONNECTION_PROPERTIES = new Properties();
    private static final String CONNECTION_URL = "jdbc:jtds:sqlserver://HOSTNAME/DATABASENAME;namedPipe=true;TDS=4.2";


    public static void main(String[] args) {
        new TestAllPipeInstancesAreBusy("main").testAllPipeInstancesAreBusy();
    }


    static {
        //DriverManager.setLogWriter(new PrintWriter(System.err));
        try {
            // Register the driver
            Class.forName("net.sourceforge.jtds.jdbc.Driver");
        }
        catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }
    }


    public TestAllPipeInstancesAreBusy(String name) {
        super(name);
    }


    /**
     * Test method that creates <code>concurrentCount</code> threads, then calls
     * {@link #connectToDatabaseAndClose()} to connect to the database.  This keeps
     * the computer running this method very busy trying to establish connections
     * to the database.  One computer is not enough to cause the "All pipe
     * instances are busy" error, though.
     */
    public void testAllPipeInstancesAreBusy() {

        final int concurrentCount = 100;

        final ConnectionRunnable[] cr = new ConnectionRunnable[concurrentCount];
        final Thread[] t = new Thread[concurrentCount];

        for (int i = 0; i < concurrentCount; i++) {
            cr[i] = new ConnectionRunnable("r" + String.valueOf(i));
            t[i] = new Thread(cr[i]);
        }

        for (int i = 0; i < concurrentCount; i++) {
            t[i].start();
        }

        try {
            for (int i = 0; i < concurrentCount; i++) {
                t[i].join();
            }
        }
        catch (InterruptedException e) {
            e.printStackTrace(System.err);
            throw new RuntimeException(e);
        }

        boolean result = true;
        for (int i = 0; i < concurrentCount; i++) {
            result = result && cr[i].isPassed();
        }
        if (!result) {
            throw new AssertionError();
        }
    }


    /**
     * Connects to the database, does (optional) work, then disconnects.
     *
     * @throws SQLException on error.
     */
    private void connectToDatabaseAndClose() throws SQLException {
        DriverManager.getConnection(CONNECTION_URL, CONNECTION_PROPERTIES).close();
    }



    /**
     * Class instantiated for each thread that calls
     * {@link TestAllPipeInstancesAreBusy#connectToDatabaseAndClose()}
     * continuously.
     */
    private class ConnectionRunnable implements Runnable {

        private boolean passed;
        private String name;
        private int count;


        public ConnectionRunnable(String name) {
            this.name = name;
        }


        public void run() {
            try {
                passed = true;
                count = 0;
                while (true) {
                    connectToDatabaseAndClose();
                    count++;
                }
            }
            catch (Exception e) {
                System.err.print(name + ": " + count + ": ");
                e.printStackTrace(System.err);
                passed = false;
            }
        }


        public boolean isPassed() {
            return passed;
        }
    }

}
