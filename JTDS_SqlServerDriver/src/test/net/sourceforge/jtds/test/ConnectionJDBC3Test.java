// jTDS JDBC Driver for Microsoft SQL Server and Sybase
// Copyright (C) 2004 The jTDS Project
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
package net.sourceforge.jtds.test;

import java.io.File;
import java.io.FileInputStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.net.URL;
import java.net.URLClassLoader;
import java.sql.Connection;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.Savepoint;
import java.util.Enumeration;
import java.util.Properties;

/**
 * JDBC 3.0-only tests for Connection.
 *
 * @author Alin Sinpalean
 * @version $Id: ConnectionJDBC3Test.java,v 1.1.2.4 2009-12-30 13:25:54 ickzon Exp $
 */
public class ConnectionJDBC3Test extends DatabaseTestCase {

    public ConnectionJDBC3Test(String name) {
        super(name);
    }

    /**
     * Test that temporary procedures created within transactions with
     * savepoints which are released are still kept in the procedure cache.
     *
     * @test.manual when testing, prepareSQL will have to be set to 1 to make
     *              sure temp procedures are used
     */
    public void testSavepointRelease() throws SQLException {
        // Manual commit mode
        con.setAutoCommit(false);
        // Create two savepoints
        Savepoint sp1 = con.setSavepoint();
        Savepoint sp2 = con.setSavepoint();
        // Create and execute a prepared statement
        PreparedStatement stmt = con.prepareStatement("SELECT 1");
        assertTrue(stmt.execute());
        // Release the inner savepoint and rollback the outer
        con.releaseSavepoint(sp2);
        con.rollback(sp1);
        // Now make sure the temp stored procedure still exists
        assertTrue(stmt.execute());
        // Release resources
        stmt.close();
        con.close();
    }
    
    /**
     * Test for bug [1755448], login failure leaves unclosed sockets.
     */
    public void testUnclosedSocket() {
        final int count = 100;

        String url = props.getProperty("url") + ";loginTimeout=600";
        Properties p = new Properties(props);
        p.put( "PASSWORD", "invalid_password" );
        p.put( "loginTimeout", "60" );

        for (int i = 0; i < count; i ++) {
            try {
                DriverManager.getConnection(url, p);
                assertTrue(false);
            } catch (SQLException e) {
                assertEquals(18456, e.getErrorCode());
            }
        }
    }

    /**
     * Test for bug [2871274], TimerThread prevents classloader from being GCed.
     */
    public void testTimerStop() throws Throwable {
        // number of load/unload cycles (use large numbers > 1000 for real stress test)
        int RELOADS = 10;

        // counter for GCed class loaders
        final int[] counter = new int[] {0};

        try {
            // run the test RELOADS times to ensure everything is GCed correctly
            for (int i=0; i < RELOADS; i++) {

                // create new classloader for loading the actual test
                ClassLoader cloader = new URLClassLoader(new URL[]{new File("bin").toURI().toURL()},null) {
                    protected void finalize() throws Throwable {
                        counter[0] ++;
                        super.finalize();
                    }
                };

                // load the actual test class
                Class clazz = cloader.loadClass(testTimerStopHelper.class.getName());
                Constructor constructor = clazz.getDeclaredConstructor((Class[]) null);

                // start the test by 
                try {
                    constructor.newInstance((Object[]) null);
                } catch (InvocationTargetException e) {
                    // extract target exception
                    throw e.getTargetException();
                }
            }

            // squeeze out any remaining class loaders
            for (int i=0; i < 10; i++) {
                System.gc();
                System.runFinalization();
            }

            // ensure some of the created classloaders have been GCed at all
            assertTrue("jTDS prevented its classloader from being GCed", counter[0] > 0);

            // ensure that any of the created classloaders has been GCed
            assertEquals("not all of jTDS' classloaders have been GCed", RELOADS, counter[0]);
        } catch (OutOfMemoryError oome) {
            fail("jTDS leaked memory, maybe its classloaders could not be GCed");
        }
    }

    /**
     * Helper class for test for bug [2871274].
     */
    public static class testTimerStopHelper
    {
        /**
         * Constructor for helper class, simply starts method {@link #test()}. 
         */
        public testTimerStopHelper() throws Throwable {
            test();
        }

        /**
         * The actual test, creates and closes a number of connections.
         */
        public void test() throws Exception {
            // load driver
            Class.forName("net.sourceforge.jtds.jdbc.Driver");

            // load connection properties
            Properties p = loadProperties();

            Connection[] conns = new Connection[5];

            // create a number of connections
            for (int c = 0; c < conns.length; c++) {
                conns[c] = DriverManager.getConnection(p.getProperty( "url" ), p);
            }

            // close the previously created connections
            for (int c = 0; c < conns.length; c++) {
               conns[c].close();
            }

            // remove driver from DriverManager
            Enumeration e = DriverManager.getDrivers();
            while (e.hasMoreElements()) {
                Driver d = (Driver) e.nextElement();
                if (d.getClass().getName().equals("net.sourceforge.jtds.jdbc.Driver")) {
                    DriverManager.deregisterDriver(d);
                    break;
                }
            }

            // the class loader should be ready for GC now
        }

        /**
         * Loads the connection properties from config file.
         */
        private static Properties loadProperties() throws Exception {
            File propFile = new File("conf/connection.properties");

            if (!propFile.exists())
                fail("Connection properties not found (" + propFile + ").");

            Properties props = new Properties();
            props.load(new FileInputStream(propFile));
            props.put( "loginTimeout", "60" );
            return props;
        }
    }

}