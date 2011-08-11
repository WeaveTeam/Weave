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

import java.util.Hashtable;
import java.util.Properties;
import javax.naming.Context;
import javax.naming.Reference;
import javax.naming.Name;

import junit.framework.Test;
import junit.framework.TestSuite;

import net.sourceforge.jtds.jdbc.Support;
import net.sourceforge.jtds.jdbcx.JtdsDataSource;
import net.sourceforge.jtds.jdbcx.JtdsObjectFactory;

/**
 * Unit tests for the {@link JtdsObjectFactory} class.
 *
 * @author David D. Kilzer
 * @author Alin Sinpalean
 * @version $Id: JtdsObjectFactoryUnitTest.java,v 1.12 2007-07-12 21:20:03 bheineman Exp $
 */
public class JtdsObjectFactoryUnitTest extends UnitTestBase {

    /**
     * Construct a test suite for this class.
     * <p/>
     * The test suite includes the tests in this class, and adds tests from
     * {@link DefaultPropertiesTestLibrary} after creating an anonymous
     * {@link DefaultPropertiesTester} object.
     *
     * @return The test suite to run.
     */
    public static Test suite() {

        TestSuite testSuite = new TestSuite(JtdsObjectFactoryUnitTest.class);

        testSuite.addTest(new TestSuite(
                JtdsObjectFactoryUnitTest.Test_JtdsObjectFactory_getObjectInstance_DefaultValues.class,
                "test_getObjectInstance_DefaultValues"));

        return testSuite;
    }

    /**
     * Constructor.
     *
     * @param name The name of the test.
     */
    public JtdsObjectFactoryUnitTest(String name) {
        super(name);
    }

    /**
     * Tests that the factory can correctly rebuild a DataSource with no
     * properties set (i.e. all values should be null and no NPE should be
     * thrown).
     */
    public void testNoProperties() throws Exception {
        JtdsDataSource ds = new JtdsDataSource();

        Reference dsRef = ds.getReference();
        assertEquals("net.sourceforge.jtds.jdbcx.JtdsObjectFactory",
                     dsRef.getFactoryClassName());
        assertEquals("net.sourceforge.jtds.jdbcx.JtdsDataSource",
                     dsRef.getClassName());

        ds = (JtdsDataSource) new JtdsObjectFactory()
                .getObjectInstance(dsRef, null, null, null);

        assertNull(ds.getServerName());
        assertEquals(0, ds.getServerType());
        assertEquals(0, ds.getPortNumber());
        assertNull(ds.getDatabaseName());
        assertNull(ds.getDatabaseName());
        assertEquals(0, ds.getPortNumber());
        assertNull(ds.getTds());
        assertNull(ds.getCharset());
        assertNull(ds.getLanguage());
        assertNull(ds.getDomain());
        assertNull(ds.getInstance());
        assertEquals(false, ds.getLastUpdateCount());
        assertEquals(false, ds.getSendStringParametersAsUnicode());
        assertEquals(false, ds.getNamedPipe());
        assertNull(ds.getMacAddress());
        assertEquals(0, ds.getPrepareSql());
        assertEquals(0, ds.getPacketSize());
        assertEquals(false, ds.getTcpNoDelay());
        assertNull(ds.getUser());
        assertNull(ds.getPassword());
        assertEquals(0, ds.getLoginTimeout());
        assertEquals(0, ds.getLobBuffer());
        assertEquals(0, ds.getMaxStatements());
        assertNull(ds.getAppName());
        assertNull(ds.getProgName());
        assertEquals(false, ds.getXaEmulation());
        assertNull(ds.getLogFile());
        assertNull(ds.getSsl());
        assertEquals(0, ds.getBatchSize());
        assertNull(ds.getDescription());
        assertNull(ds.getBindAddress());
        assertEquals(false, ds.getUseJCIFS());
    }


    /** Class used to test {@link JtdsObjectFactory#getObjectInstance(Object, Name, Context, Hashtable)}. */
    public static class Test_JtdsObjectFactory_getObjectInstance_DefaultValues
            extends DefaultPropertiesTestLibrary {

        /**
         * Default constructor.
         */
        public Test_JtdsObjectFactory_getObjectInstance_DefaultValues() {
            setTester(
                    new DefaultPropertiesTester() {

                        public void assertDefaultProperty(
                                String message, String url, Properties properties, String fieldName,
                                String key, String expected) {

                            try {
                                // Hack for JtdsDataSource.cacheMetaData
                                {
                                    if ("useMetadataCache".equals(fieldName)) {
                                        fieldName = "cacheMetaData";
                                    }
                                }

                                JtdsDataSource referenceDataSource = new JtdsDataSource();
                                invokeSetInstanceField(referenceDataSource, fieldName, expected);
                                Reference reference = referenceDataSource.getReference();
                                JtdsObjectFactory jtdsObjectFactory = new JtdsObjectFactory();
                                JtdsDataSource dataSource =
                                        (JtdsDataSource) jtdsObjectFactory.getObjectInstance(reference, null, null, null);

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
                            catch (Exception e) {
                                RuntimeException runtimeException = new RuntimeException(e.getMessage());
                                Support.linkException(runtimeException, e);
                                throw runtimeException;
                            }
                        }
                    }
            );
        }
    }

}
