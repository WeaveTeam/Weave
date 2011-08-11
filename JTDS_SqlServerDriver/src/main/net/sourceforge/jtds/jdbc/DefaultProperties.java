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
package net.sourceforge.jtds.jdbc;

import java.io.*;
import java.util.Properties;
import java.util.Map;
import java.util.HashMap;

import net.sourceforge.jtds.ssl.Ssl;

/**
 * Container for default property constants.
 * <p/>
 * This class also provides static utility methods for
 * {@link Properties} and <code>Settings</code> objects.
 * <p/>
 * To add new properties to the jTDS driver, do the following:
 * <ol>
 * <li>Add <code>prop.<em>foo</em></code> and <code>prop.desc.<em>foo</em></code>
 *     properties to <code>Messages.properties</code>.</li>
 * <li>Add a <code>static final</code> default field to {@link DefaultProperties}.</li>
 * <li>Update {@link #addDefaultProperties(java.util.Properties)} to set the default.</li>
 * <li>Update <code>Driver.createChoicesMap()</code> and
 *     <code>DriverUnitTest.test_getPropertyInfo_Choices()</code> if the property
 *     has a specific set of inputs, e.g., "true" and "false", or "1" and "2".</li>
 * <li>Update <code>Driver.createRequiredTrueMap()</code> and
 *     <code>DriverUnitTest.test_getPropertyInfo_Required()</code> if the property
 *     is required.</li>
 * <li>Add a new test to <code>DefaultPropertiesTestLibrary</code> for the new
 *     property.</li>
 * </ol>
 *
 * @author David D. Kilzer
 * @version $Id: DefaultProperties.java,v 1.32.2.1 2009-08-07 14:02:09 ickzon Exp $
 */
public final class DefaultProperties {

    /** Default <code>appName</code> property. */
    public static final String APP_NAME = "jTDS";
    /** Default <code>batchSize</code> property for SQL Server. */
    public static final String BATCH_SIZE_SQLSERVER = "0";
    /** Default <code>batchSize</code> property for Sybase. */
    public static final String BATCH_SIZE_SYBASE = "1000";
    /** Default <code>bindAddress</code> property. */
    public static final String BIND_ADDRESS = "";
    /** Default <code>bufferMaxMemory</code> property. */
    public static final String BUFFER_MAX_MEMORY = "1024";
    /** Default <code>bufferMinPackets</code> property. */
    public static final String BUFFER_MIN_PACKETS = "8";
    /** Default <code>cacheMetaData</code> property. */
    public static final String CACHEMETA = "false";
    /** Default <code>charset</code> property. */
    public static final String CHARSET = "";
    /** Default <code>databaseName</code> property. */
    public static final String DATABASE_NAME = "";
    /** Default <code>instance</code> property. */
    public static final String INSTANCE = "";
    /** Default <code>domain</code> property. */
    public static final String DOMAIN = "";
    /** Default <code>lastUpdateCount</code> property. */
    public static final String LAST_UPDATE_COUNT = "true";
    /** Default <code>lobBufferSize</code> property. */
    public static final String LOB_BUFFER_SIZE = "32768";
    /** Default <code>loginTimeout</code> property. */
    public static final String LOGIN_TIMEOUT = "0";
    /** Default <code>macAddress</code> property. */
    public static final String MAC_ADDRESS = "000000000000";
    /** Default <code>maxStatements</code> property. */
    public static final String MAX_STATEMENTS = "500";
    /** Default <code>namedPipe</code> property. */
    public static final String NAMED_PIPE = "false";
    /** Default <code>namedPipePath</code> property for SQL Server. */
    public static final String NAMED_PIPE_PATH_SQLSERVER = "/sql/query";
    /** Default <code>namedPipePath</code> property for Sybase. */
    public static final String NAMED_PIPE_PATH_SYBASE = "/sybase/query";
    /** Default <code>packetSize</code> property for TDS 4.2. */
    public static final String PACKET_SIZE_42 = String.valueOf(TdsCore.MIN_PKT_SIZE);
    /** Default <code>packetSize</code> property for TDS 5.0. */
    public static final String PACKET_SIZE_50 = "0";
    /** Default <code>packetSize</code> property for TDS 7.0 and TDS 8.0. */
    public static final String PACKET_SIZE_70_80 = "0"; // server sets packet size
    /** Default <code>password</code> property. */
    public static final String PASSWORD = "";
    /** Default <code>portNumber</code> property for SQL Server. */
    public static final String PORT_NUMBER_SQLSERVER = "1433";
    /** Default <code>portNumber</code> property for Sybase. */
    public static final String PORT_NUMBER_SYBASE = "7100";
    /** Default <code>language</code> property. */
    public static final String LANGUAGE = "";
    /** Default <code>prepareSql</code> property for SQL Server. */
    public static final String PREPARE_SQLSERVER = String.valueOf(TdsCore.PREPARE);
    /** Default <code>prepareSql</code> property for Sybase. */
    public static final String PREPARE_SYBASE = String.valueOf(TdsCore.TEMPORARY_STORED_PROCEDURES);
    /** Default <code>progName</code> property. */
    public static final String PROG_NAME = "jTDS";
    /** Default <code>tcpNoDelay</code> property. */
    public static final String TCP_NODELAY = "true";
    /** Default <code>tmpDir</code> property. */
    public static final String BUFFER_DIR = new File(System.getProperty("java.io.tmpdir")).toString();
    /** Default <code>sendStringParametersAsUnicode</code> property. */
    public static final String USE_UNICODE = "true";
    /** Default <code>useCursors</code> property. */
    public static final String USECURSORS = "false";
    /** Default <code>useJCIFS</code> property. */
    public static final String USEJCIFS = "false";
    /** Default <code>useLOBs</code> property. */
    public static final String USELOBS = "true";
    /** Default <code>user</code> property. */
    public static final String USER = "";
    /** Default <code>wsid</code> property. */
    public static final String WSID = "";
    /** Default <code>XaEmulation</code> property. */
    public static final String XAEMULATION = "true";
    /** Default <code>logfile</code> property. */
    public static final String LOGFILE = "";
    /** Default <code>sockeTimeout</code> property. */
    public static final String SOCKET_TIMEOUT = "0";
    /** Default <code>socketKeepAlive</code> property. */
    public static final String SOCKET_KEEPALIVE = "false";
    /** Default <code>processId</code> property. */
    public static final String PROCESS_ID = "123";

    /** Default <code>serverType</code> property for SQL Server. */
    public static final String SERVER_TYPE_SQLSERVER = "sqlserver";
    /** Default <code>serverType</code> property for Sybase. */
    public static final String SERVER_TYPE_SYBASE = "sybase";

    /** Default <code>tds</code> property for TDS 4.2. */
    public static final String TDS_VERSION_42 = "4.2";
    /** Default <code>tds</code> property for TDS 5.0. */
    public static final String TDS_VERSION_50 = "5.0";
    /** Default <code>tds</code> property for TDS 7.0. */
    public static final String TDS_VERSION_70 = "7.0";
    /** Default <code>tds</code> property for TDS 8.0. */
    public static final String TDS_VERSION_80 = "8.0";

    /** Default <code>ssl</code> property. */
    public static final String SSL = Ssl.SSL_OFF;

    /** Default TDS version based on server type */
    private static final HashMap tdsDefaults;
    /** Default port number based on server type */
    private static final HashMap portNumberDefaults;
    /** Default packet size based on TDS version */
    private static final HashMap packetSizeDefaults;
    /** Default max batch size based on server type */
    private static final HashMap batchSizeDefaults;
    /** Default prepare SQL mode based on server type */
    private static final HashMap prepareSQLDefaults;

    static {
        tdsDefaults = new HashMap(2);
        tdsDefaults.put(String.valueOf(Driver.SQLSERVER), TDS_VERSION_80);
        tdsDefaults.put(String.valueOf(Driver.SYBASE), TDS_VERSION_50);

        portNumberDefaults = new HashMap(2);
        portNumberDefaults.put(String.valueOf(Driver.SQLSERVER), PORT_NUMBER_SQLSERVER);
        portNumberDefaults.put(String.valueOf(Driver.SYBASE), PORT_NUMBER_SYBASE);

        packetSizeDefaults = new HashMap(4);
        packetSizeDefaults.put(TDS_VERSION_42, PACKET_SIZE_42);
        packetSizeDefaults.put(TDS_VERSION_50, PACKET_SIZE_50);
        packetSizeDefaults.put(TDS_VERSION_70, PACKET_SIZE_70_80);
        packetSizeDefaults.put(TDS_VERSION_80, PACKET_SIZE_70_80);

        batchSizeDefaults = new HashMap(2);
        batchSizeDefaults.put(String.valueOf(Driver.SQLSERVER),
                BATCH_SIZE_SQLSERVER);
        batchSizeDefaults.put(String.valueOf(Driver.SYBASE),
                BATCH_SIZE_SYBASE);

        prepareSQLDefaults = new HashMap(2);
        prepareSQLDefaults.put(String.valueOf(Driver.SQLSERVER),
                PREPARE_SQLSERVER);
        prepareSQLDefaults.put(String.valueOf(Driver.SYBASE),
                PREPARE_SYBASE);
    }

    /**
     * Add default properties to the <code>props</code> properties object.
     *
     * @param props The properties object.
     * @return The updated <code>props</code> object, or <code>null</code>
     *         if the <code>serverType</code> property is not set.
     */
    public static Properties addDefaultProperties(final Properties props) {
        final String serverType = props.getProperty(Messages.get(Driver.SERVERTYPE));

        if (serverType == null) {
            return null;
        }

        addDefaultPropertyIfNotSet(props, Driver.TDS, Driver.SERVERTYPE, tdsDefaults);

        addDefaultPropertyIfNotSet(props, Driver.PORTNUMBER, Driver.SERVERTYPE, portNumberDefaults);

        addDefaultPropertyIfNotSet(props, Driver.USER, USER);
        addDefaultPropertyIfNotSet(props, Driver.PASSWORD, PASSWORD);

        addDefaultPropertyIfNotSet(props, Driver.DATABASENAME, DATABASE_NAME);
        addDefaultPropertyIfNotSet(props, Driver.INSTANCE, INSTANCE);
        addDefaultPropertyIfNotSet(props, Driver.DOMAIN, DOMAIN);
        addDefaultPropertyIfNotSet(props, Driver.APPNAME, APP_NAME);
        addDefaultPropertyIfNotSet(props, Driver.PROGNAME, PROG_NAME);
        addDefaultPropertyIfNotSet(props, Driver.WSID, WSID);
        addDefaultPropertyIfNotSet(props, Driver.BATCHSIZE, Driver.SERVERTYPE, batchSizeDefaults);
        addDefaultPropertyIfNotSet(props, Driver.LASTUPDATECOUNT, LAST_UPDATE_COUNT);
        addDefaultPropertyIfNotSet(props, Driver.LOBBUFFER, LOB_BUFFER_SIZE);
        addDefaultPropertyIfNotSet(props, Driver.LOGINTIMEOUT, LOGIN_TIMEOUT);
        addDefaultPropertyIfNotSet(props, Driver.SOTIMEOUT, SOCKET_TIMEOUT);
        addDefaultPropertyIfNotSet(props, Driver.SOKEEPALIVE, SOCKET_KEEPALIVE);
        addDefaultPropertyIfNotSet(props, Driver.PROCESSID, PROCESS_ID);
        addDefaultPropertyIfNotSet(props, Driver.MACADDRESS, MAC_ADDRESS);
        addDefaultPropertyIfNotSet(props, Driver.MAXSTATEMENTS, MAX_STATEMENTS);
        addDefaultPropertyIfNotSet(props, Driver.NAMEDPIPE, NAMED_PIPE);
        addDefaultPropertyIfNotSet(props, Driver.PACKETSIZE, Driver.TDS, packetSizeDefaults);
        addDefaultPropertyIfNotSet(props, Driver.CACHEMETA, CACHEMETA);
        addDefaultPropertyIfNotSet(props, Driver.CHARSET, CHARSET);
        addDefaultPropertyIfNotSet(props, Driver.LANGUAGE, LANGUAGE);
        addDefaultPropertyIfNotSet(props, Driver.PREPARESQL, Driver.SERVERTYPE, prepareSQLDefaults);
        addDefaultPropertyIfNotSet(props, Driver.SENDSTRINGPARAMETERSASUNICODE, USE_UNICODE);
        addDefaultPropertyIfNotSet(props, Driver.TCPNODELAY, TCP_NODELAY);
        addDefaultPropertyIfNotSet(props, Driver.XAEMULATION, XAEMULATION);
        addDefaultPropertyIfNotSet(props, Driver.LOGFILE, LOGFILE);
        addDefaultPropertyIfNotSet(props, Driver.SSL, SSL);
        addDefaultPropertyIfNotSet(props, Driver.USECURSORS, USECURSORS);
        addDefaultPropertyIfNotSet(props, Driver.BUFFERMAXMEMORY, BUFFER_MAX_MEMORY);
        addDefaultPropertyIfNotSet(props, Driver.BUFFERMINPACKETS, BUFFER_MIN_PACKETS);
        addDefaultPropertyIfNotSet(props, Driver.USELOBS, USELOBS);
        addDefaultPropertyIfNotSet(props, Driver.BINDADDRESS, BIND_ADDRESS);
        addDefaultPropertyIfNotSet(props, Driver.USEJCIFS, USEJCIFS);
        addDefaultPropertyIfNotSet(props, Driver.BUFFERDIR, BUFFER_DIR);

        return props;
    }

    /**
     * Sets a default property if the property is not already set.
     *
     * @param props The properties object.
     * @param key The message key to set.
     * @param defaultValue The default value to set.
     */
    private static void addDefaultPropertyIfNotSet(
            final Properties props, final String key, final String defaultValue) {
        final String messageKey = Messages.get(key);

        if (props.getProperty(messageKey) == null) {
            props.setProperty(messageKey, defaultValue);
        }
    }

    /**
     * Sets a default property if the property is not already set, using
     * the <code>defaultKey</code> and the <code>defaults</code> map to
     * determine the correct value.
     *
     * @param props The properties object.
     * @param key The message key to set.
     * @param defaultKey The key whose value determines which default
     *        value to set from <code>defaults</code>.
     * @param defaults The mapping of <code>defaultKey</code> values to
     *        the correct <code>key</code> value to set.
     */
    private static void addDefaultPropertyIfNotSet(
            final Properties props, final String key, final String defaultKey, final Map defaults) {
        final String defaultKeyValue = props.getProperty(Messages.get(defaultKey));

        if (defaultKeyValue == null) {
            return;
        }

        final String messageKey = Messages.get(key);

        if (props.getProperty(messageKey) == null) {
            final Object defaultValue = defaults.get(defaultKeyValue);

            if (defaultValue != null) {
                props.setProperty(messageKey, String.valueOf(defaultValue));
            }
        }
    }

    /**
     * Returns the default path for the named pipe for a given serverType.
     *
     * @param serverType {@link Driver#SQLSERVER} or {@link Driver#SYBASE} or <code>0</code> (default)
     * @return default named pipe path
     * @throws IllegalArgumentException if an invalid serverType is given
     */
    public static String getNamedPipePath(int serverType) {
        if (serverType == 0 || serverType == Driver.SQLSERVER) {
            return NAMED_PIPE_PATH_SQLSERVER;
        }
        else if (serverType == Driver.SYBASE) {
            return NAMED_PIPE_PATH_SYBASE;
        }
        throw new IllegalArgumentException("Unknown serverType: " + serverType);
    }

    /**
     * Converts an integer server type to its string representation.
     *
     * @param serverType the server type as an <code>int</code>
     * @return the server type as a string if known, or <code>null</code> if unknown
     */
    public static String getServerType(int serverType) {
        if (serverType == Driver.SQLSERVER) {
            return SERVER_TYPE_SQLSERVER;
        } else if (serverType == Driver.SYBASE) {
            return SERVER_TYPE_SYBASE;
        }

        return null;
    }

    /**
     * Converts a string server type to its integer representation.
     *
     * @param serverType the server type as a string
     * @return the server type as an integer if known or <code>null</code> if
     *         unknown
     */
    public static Integer getServerType(String serverType) {
        if (DefaultProperties.SERVER_TYPE_SQLSERVER.equals(serverType)) {
            return new Integer(Driver.SQLSERVER);
        } else if (DefaultProperties.SERVER_TYPE_SYBASE.equals(serverType)) {
            return new Integer(Driver.SYBASE);
        }

        return null;
    }

    /**
     * Same as {@link #getServerType(int)}, only it returns the default server
     * type (<code>"sqlserver"</code>) if <code>serverType</code> is 0.
     *
     * @param serverType integer server type or 0 for default
     * @return the server type as a string if known or <code>"sqlserver"</code>
     *         if unknown
     */
    public static String getServerTypeWithDefault(int serverType) {
        if (serverType == 0) {
            return DefaultProperties.SERVER_TYPE_SQLSERVER;
        } else if (serverType == Driver.SQLSERVER
                || serverType == Driver.SYBASE) {
            return getServerType(serverType);
        } else {
            throw new IllegalArgumentException(
                    "Only 0, 1 and 2 accepted for serverType");
        }
    }

    /**
     * Converts a string TDS version to its integer representation.
     *
     * @param tdsVersion The TDS version as a string.
     * @return The TDS version as an integer if known, or <code>null</code> if unknown.
     */
    public static Integer getTdsVersion(String tdsVersion) {
        if (DefaultProperties.TDS_VERSION_42.equals(tdsVersion)) {
            return new Integer(Driver.TDS42);
        } else if (DefaultProperties.TDS_VERSION_50.equals(tdsVersion)) {
            return new Integer(Driver.TDS50);
        } else if (DefaultProperties.TDS_VERSION_70.equals(tdsVersion)) {
            return new Integer(Driver.TDS70);
        } else if (DefaultProperties.TDS_VERSION_80.equals(tdsVersion)) {
            return new Integer(Driver.TDS80);
        }

        return null;
    }
}
