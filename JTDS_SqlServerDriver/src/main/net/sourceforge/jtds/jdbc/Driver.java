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

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.DriverPropertyInfo;
import java.sql.SQLException;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;

import net.sourceforge.jtds.ssl.Ssl;

/**
 * jTDS implementation of the java.sql.Driver interface.
 * <p>
 * Implementation note:
 * <ol>
 * <li>Property text names and descriptions are loaded from an external file resource.
 *     This allows the actual names and descriptions to be changed or localised without
 *     impacting this code.
 * <li>The way in which the URL is parsed and converted to properties is rather
 *     different from the original jTDS Driver class.
 *     See parseURL and Connection.unpackProperties methods for more detail.
 * </ol>
 * @see java.sql.Driver
 * @author Brian Heineman
 * @author Mike Hutchinson
 * @author Alin Sinpalean
 * @version $Id: Driver.java,v 1.70.2.4 2009-12-30 11:19:40 ickzon Exp $
 */
public class Driver implements java.sql.Driver {
    /** URL prefix used by the driver (i.e <code>jdbc:jtds:</code>). */
    private static String driverPrefix = "jdbc:jtds:";
    /** Driver major version. */
    static final int MAJOR_VERSION = 1;
    /** Driver minor version. */
    static final int MINOR_VERSION = 2;
    /** Driver version miscellanea (e.g "-rc2", ".1" or <code>null</code>). */
    static final String MISC_VERSION = ".5";
    /** Set if the JDBC specification to implement is 3.0 or greater. */
    public static final boolean JDBC3 =
            "1.4".compareTo(System.getProperty("java.specification.version")) <= 0;
    /** TDS 4.2 protocol (SQL Server 6.5 and later and Sybase 9 and later). */
    public static final int TDS42 = 1;
    /** TDS 5.0 protocol (Sybase 10 and later). */
    public static final int TDS50 = 2;
    /** TDS 7.0 protocol (SQL Server 7.0 and later). */
    public static final int TDS70 = 3;
    /** TDS 8.0 protocol (SQL Server 2000 and later)*/
    public static final int TDS80 = 4;
    /** TDS 8.1 protocol (SQL Server 2000 SP1 and later). */
    public static final int TDS81 = 5;
    /** Microsoft SQL Server. */
    public static final int SQLSERVER = 1;
    /** Sybase ASE. */
    public static final int SYBASE = 2;

    //
    // Property name keys
    //
    public static final String APPNAME       = "prop.appname";
    public static final String BATCHSIZE     = "prop.batchsize";
    public static final String BINDADDRESS   = "prop.bindaddress";
    public static final String BUFFERDIR     = "prop.bufferdir";
    public static final String BUFFERMAXMEMORY = "prop.buffermaxmemory";
    public static final String BUFFERMINPACKETS = "prop.bufferminpackets";
    public static final String CACHEMETA     = "prop.cachemetadata";
    public static final String CHARSET       = "prop.charset";
    public static final String DATABASENAME  = "prop.databasename";
    public static final String DOMAIN        = "prop.domain";
    public static final String INSTANCE      = "prop.instance";
    public static final String LANGUAGE      = "prop.language";
    public static final String LASTUPDATECOUNT = "prop.lastupdatecount";
    public static final String LOBBUFFER     = "prop.lobbuffer";
    public static final String LOGFILE       = "prop.logfile";
    public static final String LOGINTIMEOUT  = "prop.logintimeout";
    public static final String MACADDRESS    = "prop.macaddress";
    public static final String MAXSTATEMENTS = "prop.maxstatements";
    public static final String NAMEDPIPE     = "prop.namedpipe";
    public static final String PACKETSIZE    = "prop.packetsize";
    public static final String PASSWORD      = "prop.password";
    public static final String PORTNUMBER    = "prop.portnumber";
    public static final String PREPARESQL    = "prop.preparesql";
    public static final String PROGNAME      = "prop.progname";
    public static final String SERVERNAME    = "prop.servername";
    public static final String SERVERTYPE    = "prop.servertype";
    public static final String SOTIMEOUT     = "prop.sotimeout";
    public static final String SOKEEPALIVE   = "prop.sokeepalive";
    public static final String PROCESSID     = "prop.processid";
    public static final String SSL           = "prop.ssl";
    public static final String TCPNODELAY    = "prop.tcpnodelay";
    public static final String TDS           = "prop.tds";
    public static final String USECURSORS    = "prop.usecursors";
    public static final String USEJCIFS      = "prop.usejcifs";
    public static final String USENTLMV2     = "prop.usentlmv2";
    public static final String USELOBS       = "prop.uselobs";
    public static final String USER          = "prop.user";
    public static final String SENDSTRINGPARAMETERSASUNICODE = "prop.useunicode";
    public static final String WSID          = "prop.wsid";
    public static final String XAEMULATION   = "prop.xaemulation";

    static {
        try {
            // Register this with the DriverManager
            DriverManager.registerDriver(new Driver());
        } catch (SQLException e) {
        }
    }

    public int getMajorVersion() {
        return MAJOR_VERSION;
    }

    public int getMinorVersion() {
        return MINOR_VERSION;
    }

    /**
     * Returns the driver version.
     * <p>
     * Per [908906] 0.7: Static Version information, please.
     *
     * @return the driver version
     */
    public static final String getVersion() {
        return MAJOR_VERSION + "." + MINOR_VERSION
                + ((MISC_VERSION == null) ? "" : MISC_VERSION);
    }

    /**
     * Returns the string form of the object.
     * <p>
     * Per [887120] DriverVersion.getDriverVersion(); this will return a short
     * version name.
     * <p>
     * Added back to driver per [1006449] 0.9rc1: Driver version broken
     *
     * @return the driver version
     */
    public String toString() {
        return "jTDS " + getVersion();
    }

    public boolean jdbcCompliant() {
        return false;
    }

    public boolean acceptsURL(String url) throws SQLException {
        if (url == null) {
            return false;
        }

        return url.toLowerCase().startsWith(driverPrefix);
    }

    public Connection connect(String url, Properties info)
        throws SQLException  {
        if (url == null || !url.toLowerCase().startsWith(driverPrefix)) {
            return null;
        }

        Properties props = setupConnectProperties(url, info);

        if (JDBC3) {
            return new ConnectionJDBC3(url, props);
        }

        return new ConnectionJDBC2(url, props);
    }

    public DriverPropertyInfo[] getPropertyInfo(final String url, final Properties props)
            throws SQLException {

        Properties parsedProps = parseURL(url, (props == null ? new Properties() : props));

        if (parsedProps == null) {
            throw new SQLException(
                        Messages.get("error.driver.badurl", url), "08001");
        }

        parsedProps = DefaultProperties.addDefaultProperties(parsedProps);

        final Map propertyMap = new HashMap();
        final Map descriptionMap = new HashMap();
        Messages.loadDriverProperties(propertyMap, descriptionMap);

        final Map choicesMap = createChoicesMap();
        final Map requiredTrueMap = createRequiredTrueMap();

        final DriverPropertyInfo[] dpi = new DriverPropertyInfo[propertyMap.size()];
        final Iterator iterator = propertyMap.entrySet().iterator();
        for (int i = 0; iterator.hasNext(); i++) {

            final Map.Entry entry = (Map.Entry) iterator.next();
            final String key = (String) entry.getKey();
            final String name = (String) entry.getValue();

            final DriverPropertyInfo info = new DriverPropertyInfo(name, parsedProps.getProperty(name));
            info.description = (String) descriptionMap.get(key);
            info.required = requiredTrueMap.containsKey(name);

            if (choicesMap.containsKey(name)) {
                info.choices = (String[]) choicesMap.get(name);
            }

            dpi[i] = info;
        }

        return dpi;
    }

    /**
     * Sets up properties for the {@link #connect(String, java.util.Properties)} method.
     *
     * @param url the URL of the database to which to connect
     * @param info a list of arbitrary string tag/value pairs as
     * connection arguments.
     * @return the set of properties for the connection
     * @throws SQLException if an error occurs parsing the URL
     */
    private Properties setupConnectProperties(String url, Properties info) throws SQLException {

        Properties props = parseURL(url, info);

        if (props == null) {
            throw new SQLException(Messages.get("error.driver.badurl", url), "08001");
        }

        if (props.getProperty(Messages.get(Driver.LOGINTIMEOUT)) == null) {
            props.setProperty(Messages.get(Driver.LOGINTIMEOUT), Integer.toString(DriverManager.getLoginTimeout()));
        }

        // Set default properties
        props = DefaultProperties.addDefaultProperties(props);
        return props;
    }

    /**
     * Creates a map of driver properties whose <code>choices</code>
     * field should be set when calling
     * {@link #getPropertyInfo(String, Properties)}.
     * <p/>
     * The values in the map are the <code>String[]</code> objects
     * that should be set to the <code>choices</code> field.
     *
     * @return The map of {@link DriverPropertyInfo} objects whose
     *         <code>choices</code> should be set.
     */
    private static Map createChoicesMap() {

        final HashMap choicesMap = new HashMap();

        final String[] booleanChoices = new String[]{"true", "false"};
        choicesMap.put(Messages.get(Driver.CACHEMETA), booleanChoices);
        choicesMap.put(Messages.get(Driver.LASTUPDATECOUNT), booleanChoices);
        choicesMap.put(Messages.get(Driver.NAMEDPIPE), booleanChoices);
        choicesMap.put(Messages.get(Driver.TCPNODELAY), booleanChoices);
        choicesMap.put(Messages.get(Driver.SENDSTRINGPARAMETERSASUNICODE), booleanChoices);
        choicesMap.put(Messages.get(Driver.USECURSORS), booleanChoices);
        choicesMap.put(Messages.get(Driver.USELOBS), booleanChoices);
        choicesMap.put(Messages.get(Driver.XAEMULATION), booleanChoices);

        final String[] prepareSqlChoices = new String[]{
            String.valueOf(TdsCore.UNPREPARED),
            String.valueOf(TdsCore.TEMPORARY_STORED_PROCEDURES),
            String.valueOf(TdsCore.EXECUTE_SQL),
            String.valueOf(TdsCore.PREPARE),
        };
        choicesMap.put(Messages.get(Driver.PREPARESQL), prepareSqlChoices);

        final String[] serverTypeChoices = new String[]{
            String.valueOf(SQLSERVER),
            String.valueOf(SYBASE),
        };
        choicesMap.put(Messages.get(Driver.SERVERTYPE), serverTypeChoices);

        final String[] tdsChoices = new String[]{
            DefaultProperties.TDS_VERSION_42,
            DefaultProperties.TDS_VERSION_50,
            DefaultProperties.TDS_VERSION_70,
            DefaultProperties.TDS_VERSION_80,
        };
        choicesMap.put(Messages.get(Driver.TDS), tdsChoices);

        final String[] sslChoices = new String[]{
            Ssl.SSL_OFF,
            Ssl.SSL_REQUEST,
            Ssl.SSL_REQUIRE,
            Ssl.SSL_AUTHENTICATE
        };
        choicesMap.put(Messages.get(Driver.SSL), sslChoices);

        return choicesMap;
    }

    /**
     * Creates a map of driver properties that should be marked as
     * required when calling {@link #getPropertyInfo(String, Properties)}.
     * <p/>
     * Note that only the key of the map is used to determine whether
     * the <code>required</code> field should be set to <code>true</code>.
     * If the key does not exist in the map, then the <code>required</code>
     * field is set to <code>false</code>.
     *
     * @return The map of {@link DriverPropertyInfo} objects where
     *         <code>required</code> should be set to <code>true</code>.
     */
    private static Map createRequiredTrueMap() {
        final HashMap requiredTrueMap = new HashMap();
        requiredTrueMap.put(Messages.get(Driver.SERVERNAME), null);
        requiredTrueMap.put(Messages.get(Driver.SERVERTYPE), null);
        return requiredTrueMap;
    }

    /**
     * Parse the driver URL and extract the properties.
     *
     * @param url  the URL to parse
     * @param info any existing properties already loaded in a
     *             <code>Properties</code> object
     * @return the URL properties as a <code>Properties</code> object
     */
    private static Properties parseURL(String url, Properties info) {
        Properties props = new Properties();

        // Take local copy of existing properties
        for (Enumeration e = info.propertyNames(); e.hasMoreElements();) {
            String key = (String) e.nextElement();
            String value = info.getProperty(key);

            if (value != null) {
                props.setProperty(key.toUpperCase(), value);
            }
        }

        StringBuffer token = new StringBuffer(16);
        int pos = 0;

        pos = nextToken(url, pos, token); // Skip jdbc

        if (!"jdbc".equalsIgnoreCase(token.toString())) {
            return null; // jdbc: missing
        }

        pos = nextToken(url, pos, token); // Skip jtds

        if (!"jtds".equalsIgnoreCase(token.toString())) {
            return null; // jtds: missing
        }

        pos = nextToken(url, pos, token); // Get server type
        String type = token.toString().toLowerCase();

        Integer serverType = DefaultProperties.getServerType(type);
        if (serverType == null) {
            return null; // Bad server type
        }
        props.setProperty(Messages.get(Driver.SERVERTYPE), String.valueOf(serverType));

        pos = nextToken(url, pos, token); // Null token between : and //

        if (token.length() > 0) {
            return null; // There should not be one!
        }

        pos = nextToken(url, pos, token); // Get server name
        String host = token.toString();

        if (host.length() == 0) {
            host = props.getProperty(Messages.get(Driver.SERVERNAME));
            if (host == null || host.length() == 0) {
                return null; // Server name missing
            }
        }

        props.setProperty(Messages.get(Driver.SERVERNAME), host);

        if (url.charAt(pos - 1) == ':' && pos < url.length()) {
            pos = nextToken(url, pos, token); // Get port number

            try {
                int port = Integer.parseInt(token.toString());
                props.setProperty(Messages.get(Driver.PORTNUMBER), Integer.toString(port));
            } catch(NumberFormatException e) {
                return null; // Bad port number
            }
        }

        if (url.charAt(pos - 1) == '/' && pos < url.length()) {
            pos = nextToken(url, pos, token); // Get database name
            props.setProperty(Messages.get(DATABASENAME), token.toString());
        }

        //
        // Process any additional properties in URL
        //
        while (url.charAt(pos - 1) == ';' && pos < url.length()) {
            pos = nextToken(url, pos, token);
            String tmp = token.toString();
            int index = tmp.indexOf('=');

            if (index > 0 && index < tmp.length() - 1) {
                props.setProperty(tmp.substring(0, index).toUpperCase(), tmp.substring(index + 1));
            } else {
                props.setProperty(tmp.toUpperCase(), "");
            }
        }

        return props;
    }

    /**
     * Extract the next lexical token from the URL.
     *
     * @param url The URL being parsed
     * @param pos The current position in the URL string.
     * @param token The buffer containing the extracted token.
     * @return The updated position as an <code>int</code>.
     */
    private static int nextToken(String url, int pos, StringBuffer token) {
        token.setLength(0);

        while (pos < url.length()) {
            char ch = url.charAt(pos++);

            if (ch == ':' || ch == ';') {
                break;
            }

            if (ch == '/') {
                if (pos < url.length() && url.charAt(pos) == '/') {
                    pos++;
                }

                break;
            }

            token.append(ch);
        }

        return pos;
    }

    public static void main(String[] args) {
        System.out.println("jTDS " + getVersion());
    }
}
