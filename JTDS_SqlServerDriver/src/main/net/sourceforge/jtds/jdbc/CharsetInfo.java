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

import java.sql.SQLException;
import java.util.HashMap;
import java.util.Properties;
import java.util.Enumeration;
import java.io.InputStream;
import java.io.IOException;

import net.sourceforge.jtds.util.Logger;

/**
 * Loads and stores information about character sets. Static fields and methods
 * are concerned with loading, storing and retrieval of all character set
 * information, while non-static fields and methods describe a particular
 * character set (Java charset name and whether it's a multi-byte charset).
 * <p>
 * <b>Note:</b> Only one <code>CharsetInfo</code> instance exists per charset.
 * This allows simple equality comparisons between instances retrieved with any
 * of the <code>get</code> methods.
 *
 * @author Alin Sinpalean
 * @version $Id: CharsetInfo.java,v 1.5 2007-07-08 17:28:23 bheineman Exp $
 */
public final class CharsetInfo {
    //
    // Static fields and methods
    //

    /** Name of the <code>Charsets.properties</code> resource. */
    private static final String CHARSETS_RESOURCE_NAME
            = "net/sourceforge/jtds/jdbc/Charsets.properties";

    /** Server charset to Java charset map. */
    private static final HashMap charsets = new HashMap();

    /** Locale id to Java charset map. */
    private static final HashMap lcidToCharsetMap = new HashMap();

    /** Sort order to Java charset map. */
    private static final CharsetInfo[] sortToCharsetMap = new CharsetInfo[256];

    static {
        // Load character set mappings
        try {
            InputStream stream = null;
            // getContextClassLoader needed to ensure driver
            // works with Tomcat class loading rules.
            ClassLoader classLoader =
                    Thread.currentThread().getContextClassLoader();

            if (classLoader != null) {
                stream = classLoader.getResourceAsStream(
                        CHARSETS_RESOURCE_NAME);
            }

            if (stream == null) {
                // The doPrivileged() call stops the SecurityManager from
                // checking further in the stack trace whether all callers have
                // the permission to load Charsets.properties
                stream = (InputStream) java.security.AccessController.doPrivileged(
                        new java.security.PrivilegedAction() {
                            public Object run() {
                                ClassLoader loader = CharsetInfo.class.getClassLoader();
                                // getClassLoader() may return null if the class was loaded by
                                // the bootstrap ClassLoader
                                if (loader == null) {
                                    loader = ClassLoader.getSystemClassLoader();
                                }

                                return loader.getResourceAsStream(
                                        CHARSETS_RESOURCE_NAME);
                            }
                        }
                );
            }

            if (stream != null) {
                Properties tmp = new Properties();
                tmp.load(stream);

                HashMap instances = new HashMap();

                for (Enumeration e = tmp.propertyNames(); e.hasMoreElements();) {
                    String key = (String) e.nextElement();
                    CharsetInfo value = new CharsetInfo(tmp.getProperty(key));

                    // Ensure only one CharsetInfo instance exists per charset
                    CharsetInfo prevInstance = (CharsetInfo) instances.get(
                            value.getCharset());
                    if (prevInstance != null) {
                        if (prevInstance.isWideChars() != value.isWideChars()) {
                            throw new IllegalStateException(
                                    "Inconsistent Charsets.properties");
                        }
                        value = prevInstance;
                    }

                    if (key.startsWith("LCID_")) {
                        Integer lcid = new Integer(key.substring(5));
                        lcidToCharsetMap.put(lcid, value);
                    } else if (key.startsWith("SORT_")) {
                        sortToCharsetMap[Integer.parseInt(key.substring(5))] = value;
                    } else {
                        charsets.put(key, value);
                    }
                }
            } else {
                Logger.println("Can't load Charsets.properties");
            }
        } catch (IOException e) {
            // Can't load properties file for some reason
            Logger.logException(e);
        }
    }

    /**
     * Retrieves the <code>CharsetInfo</code> instance asociated with the
     * specified server charset.
     *
     * @param serverCharset the server-specific character set name
     * @return the associated <code>CharsetInfo</code>
     */
    public static CharsetInfo getCharset(String serverCharset) {
        return (CharsetInfo) charsets.get(serverCharset.toUpperCase());
    }

    /**
     * Retrieves the <code>CharsetInfo</code> instance asociated with the
     * specified LCID.
     *
     * @param lcid the server LCID
     * @return the associated <code>CharsetInfo</code>
     */
    public static CharsetInfo getCharsetForLCID(int lcid) {
        return (CharsetInfo) lcidToCharsetMap.get(new Integer(lcid));
    }

    /**
     * Retrieves the <code>CharsetInfo</code> instance asociated with the
     * specified sort order.
     *
     * @param sortOrder the server sort order
     * @return the associated <code>CharsetInfo</code>
     */
    public static CharsetInfo getCharsetForSortOrder(int sortOrder) {
        return sortToCharsetMap[sortOrder];
    }

    /**
     * Retrieves the <code>CharsetInfo</code> instance asociated with the
     * specified collation.
     *
     * @param collation the server LCID
     * @return the associated <code>CharsetInfo</code>
     */
    public static CharsetInfo getCharset(byte[] collation)
            throws SQLException {
        CharsetInfo charset;

        if (collation[4] != 0) {
            // The charset is determined by the sort order
            charset = getCharsetForSortOrder((int) collation[4] & 0xFF);
        } else {
            // The charset is determined by the LCID
            charset = getCharsetForLCID(
                    ((int) collation[2] & 0x0F) << 16
                    | ((int) collation[1] & 0xFF) << 8
                    | ((int) collation[0] & 0xFF));
        }

        if (charset == null) {
            throw new SQLException(
                    Messages.get("error.charset.nocollation", Support.toHex(collation)),
                    "2C000");
        }

        return charset;
    }

    //
    // Non-static fields and methods
    //

    /** The Java character set name. */
    private final String charset;
    /** Indicates whether current charset is wide (ie multi-byte). */
    private final boolean wideChars;

    /**
     * Constructs a <code>CharsetInfo</code> object from a character set
     * descriptor of the form: charset preceded by a numeric value indicating
     * whether it's a multibyte character set (&gt;1) or not (1) and a vertical
     * bar (|), eg &quot;1|Cp1252&quot; or &quot;2|MS936&quot;.
     *
     * @param descriptor the charset descriptor
     */
    public CharsetInfo(String descriptor) {
        wideChars = !"1".equals(descriptor.substring(0, 1));
        charset = descriptor.substring(2);
    }

    /**
     * Retrieves the charset name.
     */
    public String getCharset() {
        return charset;
    }

    /**
     * Retrieves whether the caracter set is wide (ie multi-byte).
     */
    public boolean isWideChars() {
        return wideChars;
    }

    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof CharsetInfo)) {
            return false;
        }

        final CharsetInfo charsetInfo = (CharsetInfo) o;
        if (!charset.equals(charsetInfo.charset)) {
            return false;
        }

        return true;
    }

    public int hashCode() {
        return charset.hashCode();
    }

    public String toString() {
        return charset;
    }
}
