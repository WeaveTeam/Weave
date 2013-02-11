//jTDS JDBC Driver for Microsoft SQL Server and Sybase
//Copyright (C) 2004 The jTDS Project
//
//This library is free software; you can redistribute it and/or
//modify it under the terms of the GNU Lesser General Public
//License as published by the Free Software Foundation; either
//version 2.1 of the License, or (at your option) any later version.
//
//This library is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//Lesser General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public
//License along with this library; if not, write to the Free Software
//Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
package net.sourceforge.jtds.test;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import javax.naming.NamingException;
import javax.naming.Reference;

import junit.framework.Test;
import junit.framework.TestSuite;

import net.sourceforge.jtds.jdbcx.JtdsDataSource;
import net.sourceforge.jtds.jdbc.Messages;
import net.sourceforge.jtds.jdbc.Driver;


/**
 * Unit tests for the {@link JtdsDataSource} class.
 *
 * @author David D. Kilzer
 * @version $Id: JtdsDataSourceUnitTest.java,v 1.21 2007-07-08 18:08:54 bheineman Exp $
 */
public class JtdsDataSourceUnitTest extends UnitTestBase {

    /**
     * Construct a test suite for this class.
     * <p/>
     * The test suite includes the tests in this class as
     * well as {@link Test_JtdsDataSource_getConnection}.
     *
     * @return The test suite to run.
     */
    public static Test suite() {

        TestSuite testSuite = new TestSuite(JtdsDataSourceUnitTest.class);

        testSuite.addTest(new TestSuite(
                JtdsDataSourceUnitTest.Test_JtdsDataSource_fields.class, "test_fields_DefaultProperties"));

        testSuite.addTest(new TestSuite(
                JtdsDataSourceUnitTest.Test_JtdsDataSource_getReference.class, "test_getReference_DefaultProperties"));

        testSuite.addTest(new TestSuite(
                JtdsDataSourceUnitTest.Test_JtdsDataSource_addNonNullProperties.class, "test_addNonNullProperties_DefaultProperties"));

        testSuite.addTest(new TestSuite(
                JtdsDataSourceUnitTest.Test_JtdsDataSource_getConnection.class, "test_getConnection"));

        return testSuite;
    }


    /**
     * Constructor.
     *
     * @param name The name of the test.
     */
    public JtdsDataSourceUnitTest(String name) {
        super(name);
    }


    /**
     * Tests that the public constructor works.
     * <p/>
     * Needed so that this class has at least one test.
     */
    public void testPublicConstructor() {
        assertNotNull(new JtdsDataSource());
    }


    /** Class used to test {@link JtdsDataSource}. */
    public static class Test_JtdsDataSource_fields
            extends DefaultPropertiesTestLibrary {

        /**
         * Default constructor.
         */
        public Test_JtdsDataSource_fields() {
            setTester(
                    new DefaultPropertiesTester() {

                        public void assertDefaultProperty(
                                String message, String url, Properties properties, String fieldName,
                                String key, String expected) {

                            // Hack for JtdsDataSource.getCacheMetaData()
                            {
                                if ("useMetadataCache".equals(fieldName)) {
                                    fieldName = "cacheMetaData";
                                }
                            }

                            JtdsDataSource dataSource = new JtdsDataSource();
                            invokeSetInstanceField(dataSource, fieldName, expected);

                            // Hack for JtdsDataSource.getTds()
                            {
                                if ("tdsVersion".equals(fieldName)) {
                                    fieldName = "tds";
                                }
                            }

                            String actual =
                                    String.valueOf(
                                            invokeInstanceMethod(
                                                    dataSource,
                                                    "get" + ucFirst(fieldName),
                                                    new Class[]{}, new Object[]{}));
                            assertEquals(message, expected, actual);
                        }
                    }
            );
        }
    }


    /** Class used to test {@link JtdsDataSource#getReference()}. */
    public static class Test_JtdsDataSource_getReference
            extends DefaultPropertiesTestLibrary {

        /**
         * Default constructor.
         */
        public Test_JtdsDataSource_getReference() {
            setTester(
                    new DefaultPropertiesTester() {

                        public void assertDefaultProperty(
                                String message, String url, Properties properties, String fieldName,
                                String key, String expected) {

                            try {
                                // Hack for JtdsDataSource.getCacheMetaData()
                                {
                                    if ("useMetadataCache".equals(fieldName)) {
                                        fieldName = "cacheMetaData";
                                    }
                                }
                                JtdsDataSource dataSource = new JtdsDataSource();
                                invokeSetInstanceField(dataSource, fieldName, expected);
                                Reference reference = dataSource.getReference();
                                assertEquals(message, expected, reference.get(Messages.get(key)).getContent());
                            }
                            catch (NamingException e) {
                                throw new RuntimeException(e.getMessage());
                            }
                        }
                    }
            );
        }
    }


    /** Class used to test <code>JtdsDataSource.addNonNullProperties(Properties, String, String)</code>. */
    public static class Test_JtdsDataSource_addNonNullProperties
            extends DefaultPropertiesTestLibrary {

        /**
         * Default constructor.
         */
        public Test_JtdsDataSource_addNonNullProperties() {
            setTester(
                    new DefaultPropertiesTester() {

                        public void assertDefaultProperty(
                                String message, String url, Properties properties, String fieldName,
                                String key, String expected) {

                            // Hack for JtdsDataSource.cacheMetaData
                            {
                                if ("useMetadataCache".equals(fieldName)) {
                                    fieldName = "cacheMetaData";
                                }
                            }

                            JtdsDataSource dataSource = new JtdsDataSource();
                            dataSource.setServerName("non-null-value");
                            invokeSetInstanceField(dataSource, fieldName, expected);

                            Properties props = new Properties();
                            invokeInstanceMethod(dataSource, "addNonNullProperties",
                                                 new Class[]{Properties.class, String.class, String.class},
                                                 new Object[]{props, "", ""});

                            assertEquals(message, expected, props.getProperty(Messages.get(key)));
                        }
                    }
            );
        }
    }


    public static class Test_JtdsDataSource_getConnection extends UnitTestBase {
        // TODO Specify host name separately in the properties so that testing can be more accurate
        public Test_JtdsDataSource_getConnection(String name) {
            super(name);
        }

        /**
         * Provides a null test suite so that JUnit will not try to instantiate this class directly.
         *
         * @return The test suite (always <code>null</code>).
         */
        public static final Test suite() {
            return null;
        }

        /**
         * Test connecting without specifying a host. Should get an SQL state
         * of 08001 (SQL client unable to establish SQL connection).
         */
        public void testNoHost() {
            JtdsDataSource ds = new JtdsDataSource();
            ds.setUser(TestBase.props.getProperty(Messages.get(Driver.USER)));
            ds.setPassword(TestBase.props.getProperty(Messages.get(Driver.PASSWORD)));
            ds.setDatabaseName(TestBase.props.getProperty(Messages.get(Driver.DATABASENAME)));
            try {
                ds.setPortNumber(Integer.parseInt(
                        TestBase.props.getProperty(Messages.get(Driver.PORTNUMBER))));
            } catch (Exception ex) {
                // Ignore
            }
            try {
                assertNotNull(ds.getConnection());
                fail("What the?...");
            } catch (SQLException ex) {
                assertEquals("Expecting SQL state 08001. Got " + ex.getSQLState(), "08001", ex.getSQLState());
            } catch (Throwable t) {
                t.printStackTrace();
                fail(t.getClass().getName() + " caught while testing JtdsDataSource.getConnection(): " + t);
            }
        }

        /**
         * Test connecting without specifying a user. Should get an SQL state
         * of either 28000 (invalid authorization specification) or 08S01 (bad
         * host name).
         */
        public void testNoUser() {
            JtdsDataSource ds = new JtdsDataSource();
            ds.setServerName(TestBase.props.getProperty(Messages.get(Driver.SERVERNAME)));
            ds.setDatabaseName(TestBase.props.getProperty(Messages.get(Driver.DATABASENAME)));
            try {
                ds.setPortNumber(Integer.parseInt(
                        TestBase.props.getProperty(Messages.get(Driver.PORTNUMBER))));
            } catch (Exception ex) {
                // Ignore
            }
            try {
                assertNotNull(ds.getConnection());
                fail("What the?...");
            } catch (SQLException ex) {
                String sqlState = ex.getSQLState();
                if (!"28000".equals(sqlState) && !sqlState.startsWith("08")) {
                    ex.printStackTrace();
                    fail("Expecting SQL state 28000 or 08XXX. Got " + ex.getSQLState());
                }
            } catch (Throwable t) {
                t.printStackTrace();
                fail(t.getClass().getName() + " caught while testing JtdsDataSource.getConnection(): " + t);
            }
        }

        /**
         * Test connecting with the settings in connection.properties.
         * <p>
         * Should also test bug [1051595] jtdsDataSource connects only to
         * localhost.
         */
        public void testNormal() {
            JtdsDataSource ds = new JtdsDataSource();
            ds.setServerName(TestBase.props.getProperty(Messages.get(Driver.SERVERNAME)));
            ds.setUser(TestBase.props.getProperty(Messages.get(Driver.USER)));
            ds.setPassword(TestBase.props.getProperty(Messages.get(Driver.PASSWORD)));
            ds.setDatabaseName(TestBase.props.getProperty(Messages.get(Driver.DATABASENAME)));
            ds.setTds(TestBase.props.getProperty(Messages.get(Driver.TDS)));
            ds.setServerType("2".equals(TestBase.props.getProperty(Messages.get(Driver.SERVERTYPE))) ? 2 : 1);
            try {
                ds.setPortNumber(Integer.parseInt(
                        TestBase.props.getProperty(Messages.get(Driver.PORTNUMBER))));
            } catch (Exception ex) {
                // Ignore
            }
            try {
                Connection c = ds.getConnection();
                assertNotNull(c);
                c.close();
            } catch (SQLException ex) {
                ex.printStackTrace();
                fail("SQLException caught: " + ex.getMessage() + " SQLState=" + ex.getSQLState());
            } catch (Throwable t) {
                t.printStackTrace();
                fail(t.getClass().getName() + " caught while testing JtdsDataSource.getConnection(): " + t);
            }
        }

        /**
         * Test connecting without specifying TDS version.
         * <p/>
         * Test for bug [1113709] Connecting via DataSource. Issue was caused
         * by JtdsDataSource setting the default values in the constructor, so
         * the TDS version was always set to 8.0 unless explicitly modified.
         * <p/>
         * The incorrect behavior occured when connecting to Sybase (when the
         * TDS version should have been 5.0 by default).
         */
        public void testDefaultTdsVersion() {
            JtdsDataSource ds = new JtdsDataSource();
            ds.setServerName(TestBase.props.getProperty(Messages.get(Driver.SERVERNAME)));
            ds.setUser(TestBase.props.getProperty(Messages.get(Driver.USER)));
            ds.setPassword(TestBase.props.getProperty(Messages.get(Driver.PASSWORD)));
            ds.setDatabaseName(TestBase.props.getProperty(Messages.get(Driver.DATABASENAME)));
            ds.setServerType("2".equals(TestBase.props.getProperty(Messages.get(Driver.SERVERTYPE))) ? 2 : 1);
            try {
                ds.setPortNumber(Integer.parseInt(
                        TestBase.props.getProperty(Messages.get(Driver.PORTNUMBER))));
            } catch (Exception ex) {
                // Ignore
            }
            try {
                Connection c = ds.getConnection();
                assertNotNull(c);
                c.close();
            } catch (SQLException ex) {
                ex.printStackTrace();
                fail("SQLException caught: " + ex.getMessage() + " SQLState=" + ex.getSQLState());
            } catch (Throwable t) {
                t.printStackTrace();
                fail(t.getClass().getName() + " caught while testing JtdsDataSource.getConnection(): " + t);
            }
        }
    }
}
