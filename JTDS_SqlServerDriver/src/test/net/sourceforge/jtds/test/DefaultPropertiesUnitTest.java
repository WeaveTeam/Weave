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

import net.sourceforge.jtds.jdbc.DefaultProperties;
import net.sourceforge.jtds.jdbc.Messages;
import net.sourceforge.jtds.jdbc.Driver;
import java.util.Properties;
import java.util.Map;
import java.util.HashMap;



/**
 * Unit tests for the {@link net.sourceforge.jtds.jdbc.DefaultProperties} class.
 *
 * @author David D. Kilzer
 * @version $Id: DefaultPropertiesUnitTest.java,v 1.9 2007-07-08 18:08:54 bheineman Exp $
 */
public class DefaultPropertiesUnitTest extends UnitTestBase {

    /**
     * Constructor.
     *
     * @param name The name of the test.
     */
    public DefaultPropertiesUnitTest(String name) {
        super(name);
    }


    /**
     * Tests that
     * <code>DefaultProperties.addDefaultPropertyIfNotSet(java.util.Properties, java.lang.String, java.lang.String)</code>
     * sets a default property if the property is not already set.
     */
    public void test_addDefaultPropertyIfNotSet_PropertyNotSet() {
        final Properties properties = new Properties();
        final String key = Driver.DATABASENAME;
        final String defaultValue = "foobar";
        invokeStaticMethod(
                DefaultProperties.class, "addDefaultPropertyIfNotSet",
                new Class[]{Properties.class, String.class, String.class},
                new Object[]{properties, key, defaultValue});
        assertEquals(defaultValue, properties.get(Messages.get(key)));
    }


    /**
     * Tests that
     * <code>DefaultProperties.addDefaultPropertyIfNotSet(java.util.Properties, java.lang.String, java.lang.String)</code>
     * does <em>not</em> set a default property if the property is already set.
     */
    public void test_addDefaultPropertyIfNotSet_PropertyAlreadySet() {
        final Properties properties = new Properties();
        final String key = Driver.DATABASENAME;
        final String presetValue = "barbaz";
        final String defaultValue = "foobar";
        properties.setProperty(Messages.get(key), presetValue);
        invokeStaticMethod(DefaultProperties.class, "addDefaultPropertyIfNotSet",
                           new Class[]{Properties.class, String.class, String.class},
                           new Object[]{properties, key, defaultValue});
        assertEquals(presetValue, properties.get(Messages.get(key)));
    }


    /**
     * Tests that
     * <code>DefaultProperties.addDefaultPropertyIfNotSet(java.util.Properties, java.lang.String, java.lang.String, java.util.Map)</code>
     * does <em>not</em> set a default property if the <code>defaultKey</code> is not set.
     */
    public void test_addDefaultPropertyIfNotSet_DefaultKeyNotSet() {
        final Properties properties = new Properties();
        final String defaultKey = Driver.SERVERTYPE;
        final String key = Driver.PORTNUMBER;
        final HashMap defaults = new HashMap();
        invokeStaticMethod(DefaultProperties.class, "addDefaultPropertyIfNotSet",
                           new Class[]{Properties.class, String.class, String.class, Map.class},
                           new Object[]{properties, key, defaultKey, defaults});
        assertEquals(0, properties.size());
    }


    /**
     * Tests that
     * <code>DefaultProperties.addDefaultPropertyIfNotSet(java.util.Properties, java.lang.String, java.lang.String, java.util.Map)</code>
     * sets a default property if the property is not already set.
     */
    public void test_addDefaultPropertyIfNotSet_DefaultKeySet_PropertyNotSet() {
        final Properties properties = new Properties();
        final String defaultKey = Driver.SERVERTYPE;
        final String defaultKeyValue = "foobar";
        properties.put(Messages.get(defaultKey), defaultKeyValue);
        final String key = Driver.PORTNUMBER;
        final String defaultValue = "2004";
        final HashMap defaults = new HashMap();
        defaults.put(defaultKeyValue, defaultValue);
        invokeStaticMethod(DefaultProperties.class, "addDefaultPropertyIfNotSet",
                           new Class[]{Properties.class, String.class, String.class, Map.class},
                           new Object[]{properties, key, defaultKey, defaults});
        assertEquals(defaultValue, properties.get(Messages.get(key)));
    }


    /**
     * Tests that
     * <code>DefaultProperties.addDefaultPropertyIfNotSet(java.util.Properties, java.lang.String, java.lang.String, java.util.Map)</code>
     * does <em>not</em> set a default property if the property is already set.
     */
    public void test_addDefaultPropertyIfNotSet_DefaultKeySet_PropertyAlreadySet() {
        final Properties properties = new Properties();
        final String defaultKey = Driver.SERVERTYPE;
        final String defaultKeyValue = "foobar";
        properties.put(Messages.get(defaultKey), defaultKeyValue);
        final String key = Driver.PORTNUMBER;
        final String presetValue = "2020";
        properties.put(Messages.get(key), presetValue);
        final String defaultValue = "2004";
        final HashMap defaults = new HashMap();
        defaults.put(defaultKeyValue, defaultValue);
        invokeStaticMethod(DefaultProperties.class, "addDefaultPropertyIfNotSet",
                           new Class[]{Properties.class, String.class, String.class, Map.class},
                           new Object[]{properties, key, defaultKey, defaults});
        assertEquals(presetValue, properties.get(Messages.get(key)));
    }


    public void test_getServerType_intToString_Null() {
        final String message = "Did not return null for unknown server type ";
        final int[] testValues = new int[]{ -99, -1, 0, 3, 99 };
        for (int i = 0; i < testValues.length; i++) {
            assertNull(
                    message + String.valueOf(testValues[i]),
                    DefaultProperties.getServerType(testValues[i]));
        }
    }


    public void test_getServerType_intToString_SQLSERVER() {
        assertEquals(
                "Server type for SQL Server did not map correctly",
                DefaultProperties.SERVER_TYPE_SQLSERVER,
                DefaultProperties.getServerType(Driver.SQLSERVER));
    }


    public void test_getServerType_intToString_SYBASE() {
        assertEquals("Server type for Sybase did not map correctly",
                     DefaultProperties.SERVER_TYPE_SYBASE,
                     DefaultProperties.getServerType(Driver.SYBASE));
    }


    public void test_getServerType_StringToInteger_Null() {
        final String message = "Did not return null for unknown server type: ";
        final String[] testValues = new String[]{ null, "", "SQLServer", "Sybase", "sibase", "sq1server" };
        for (int i = 0; i < testValues.length; i++) {
            assertNull(
                    message + String.valueOf(testValues[i]),
                    DefaultProperties.getServerType(testValues[i]));
        }
    }


    public void test_getServerType_StringToInteger_SQLSERVER() {
        assertEquals(
                "Server type for SQL Server did not map correctly",
                new Integer(Driver.SQLSERVER),
                DefaultProperties.getServerType(DefaultProperties.SERVER_TYPE_SQLSERVER));
    }


    public void test_getServerType_StringToInteger_SYBASE() {
        assertEquals("Server type for Sybase did not map correctly",
                     new Integer(Driver.SYBASE),
                     DefaultProperties.getServerType(DefaultProperties.SERVER_TYPE_SYBASE));
    }


    public void test_getTdsVersion_StringToInteger_Null() {
        final String message = "Did not return null for unknown TDS version: ";
        final String[] testValues = new String[]{ null, "", "4.0", "5.2", "0.0", "8:0" };
        for (int i = 0; i < testValues.length; i++) {
            assertNull(
                    message + String.valueOf(testValues[i]),
                    DefaultProperties.getTdsVersion(testValues[i]));
        }
    }


    public void test_getTdsVersion_StringToInteger_TDS42() {
        assertEquals(
                "Tds version for TDS 4.2 did not map correctly",
                new Integer(Driver.TDS42),
                DefaultProperties.getTdsVersion(DefaultProperties.TDS_VERSION_42));
    }


    public void test_getTdsVersion_StringToInteger_TDS50() {
        assertEquals(
                "Tds version for TDS 5.0 did not map correctly",
                new Integer(Driver.TDS50),
                DefaultProperties.getTdsVersion(DefaultProperties.TDS_VERSION_50));
    }


    public void test_getTdsVersion_StringToInteger_TDS70() {
        assertEquals(
                "Tds version for TDS 7.0 did not map correctly",
                new Integer(Driver.TDS70),
                DefaultProperties.getTdsVersion(DefaultProperties.TDS_VERSION_70));
    }


    public void test_getTdsVersion_StringToInteger_TDS80() {
        assertEquals(
                "Tds version for TDS 8.0 did not map correctly",
                new Integer(Driver.TDS80),
                DefaultProperties.getTdsVersion(DefaultProperties.TDS_VERSION_80));
    }


    public void test_getNamedPipePath_DEFAULT() {
        assertEquals(
                "Default named pipe path for default (0) did not map correctly",
                DefaultProperties.NAMED_PIPE_PATH_SQLSERVER,
                DefaultProperties.getNamedPipePath(0));
    }


    public void test_getNamedPipePath_INVALID() {
        try {
            DefaultProperties.getNamedPipePath(3);
            fail("IllegalArgumentException was expected to be thrown");
        }
        catch (IllegalArgumentException expected) {
        }
    }


    public void test_getNamedPipePath_SQLSERVER() {
        assertEquals(
                "Default named pipe path for SQL Server did not map correctly",
                DefaultProperties.NAMED_PIPE_PATH_SQLSERVER,
                DefaultProperties.getNamedPipePath(DefaultProperties.getServerType(DefaultProperties.SERVER_TYPE_SQLSERVER).intValue()));
    }


    public void test_getNamedPipePath_SYBASE() {
        assertEquals(
                "Default named pipe path for Sybase did not map correctly",
                DefaultProperties.NAMED_PIPE_PATH_SYBASE,
                DefaultProperties.getNamedPipePath(DefaultProperties.getServerType(DefaultProperties.SERVER_TYPE_SYBASE).intValue()));
    }

}
