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
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.io.IOException;
import java.io.UnsupportedEncodingException;

/**
 * This class is a descriptor for procedure and prepared statement parameters.
 *
 * @author Mike Hutchinson
 * @version $Id: ParamInfo.java,v 1.16 2005-04-25 11:47:01 alin_sinpalean Exp $
 */
class ParamInfo implements Cloneable {
    /** Flag as an input parameter. */
    final static int INPUT   = 0;
    /** Flag as an output parameter. */
    final static int OUTPUT  = 1;
    /** Flag as an return value parameter. */
    final static int RETVAL  = 2;
    /** Flag as a unicode parameter. */
    final static int UNICODE = 4;

    /** Internal TDS data type */
    int tdsType;
    /** JDBC type constant from java.sql.Types */
    int jdbcType;
    /** Formal parameter name eg @P1 */
    String name;
    /** SQL type name eg varchar(10) */
    String sqlType;
    /** Parameter offset in target SQL statement */
    int markerPos = -1;
    /** Current parameter value */
    Object value;
    /** Parameter decimal precision */
    int precision = -1;
    /** Parameter decimal scale */
    int scale = -1;
    /** Length of InputStream */
    int length = -1;
    /** Parameter is an output parameter */
    boolean isOutput;
    /** Parameter is used as  SP return value */
    boolean isRetVal;
    /** IN parameter has been set */
    boolean isSet;
    /** Parameter should be sent as unicode */
    boolean isUnicode;
    /** TDS 8 Collation string. */
    byte collation[];
    /** Character set descriptor (if different from default) */
    CharsetInfo charsetInfo;
    /** OUT parameter value is set.*/
    boolean isSetOut;
    /** OUT Parameter value. */
    Object outValue;

    /**
     * Construct a parameter with parameter marker offset.
     *
     * @param pos       the offset of the ? symbol in the target SQL string
     * @param isUnicode <code>true</code> if the parameter is Unicode encoded
     */
    ParamInfo(int pos, boolean isUnicode) {
        markerPos = pos;
        this.isUnicode = isUnicode;
    }

    /**
     * Construct a parameter for statement caching.
     *
     * @param name      the formal name of the parameter
     * @param pos       the offset of the ? symbol in the parsed SQL string
     * @param isRetVal  <code>true</code> if the parameter is a return value
     * @param isUnicode <code>true</code> if the parameter is Unicode encoded
     */
    ParamInfo(String name, int pos, boolean isRetVal, boolean isUnicode) {
        this.name      = name;
        this.markerPos = pos;
        this.isRetVal  = isRetVal;
        this.isUnicode = isUnicode;
    }

    /**
     * Construct an initialised parameter with extra attributes.
     *
     * @param jdbcType the <code>java.sql.Type</code> constant describing this type
     * @param value    the initial parameter value
     * @param flags    the additional attributes eg OUTPUT, RETVAL, UNICODE etc.
     */
    ParamInfo(int jdbcType, Object value, int flags)
    {
        this.jdbcType  = jdbcType;
        this.value     = value;
        this.isSet     = true;
        this.isOutput  = ((flags & OUTPUT) > 0) || ((flags & RETVAL) > 0);
        this.isRetVal  = ((flags & RETVAL)> 0);
        this.isUnicode = ((flags & UNICODE) > 0);
        if (value instanceof String) {
            this.length = ((String)value).length();
        } else
        if (value instanceof byte[]) {
            this.length = ((byte[])value).length;
        }
    }

    /**
     * Construct a parameter based on a result set column.
     *
     * @param ci     the column descriptor
     * @param name   the name for this parameter or null
     * @param value  the column data value
     * @param length the column data length
     */
    ParamInfo(ColInfo ci, String name, Object value, int length) {
        this.name      = name;
        this.tdsType   = ci.tdsType;
        this.scale     = ci.scale;
        this.precision = ci.precision;
        this.jdbcType  = ci.jdbcType;
        this.sqlType   = ci.sqlType;
        this.collation = ci.collation;
        this.charsetInfo = ci.charsetInfo;
        this.isUnicode = TdsData.isUnicode(ci);
        this.isSet     = true;
        this.value     = value;
        this.length    = length;
    }

    /**
     * Get the output parameter value.
     *
     * @return the OUT value as an <code>Object</code>
     * @throws SQLException if the parameter has not been set
     */
    Object getOutValue()
        throws SQLException {
        if (!isSetOut) {
            throw new SQLException(
                    Messages.get("error.callable.outparamnotset"), "HY010");
        }
        return outValue;
    }

    /**
     * Set the OUT parameter value.
     * @param value The data value.
     */
    void setOutValue(Object value) {
        outValue= value;
        isSetOut = true;
    }

    /**
     * Clear the OUT parameter value and status.
     */
    void clearOutValue()
    {
        outValue = null;
        isSetOut = false;
    }

    /**
     * Clear the IN parameter value and status.
     */
    void clearInValue()
    {
        value = null;
        isSet = false;
    }

    /**
     * Get the string value of the parameter.
     *
     * @return The data value as a <code>String</code> or null.
     */
    String getString(String charset) throws IOException {
        if (value == null || value instanceof String) {
            return (String) value;
        }

        if (value instanceof InputStream) {
            try {
                value = loadFromReader(new InputStreamReader((InputStream) value, charset), length);
                length = ((String) value).length();

                return (String) value;
            } catch (UnsupportedEncodingException e) {
                throw new IOException("I/O Error: UnsupportedEncodingException: "+ e.getMessage());
            }
        }

        if (value instanceof Reader) {
            value = loadFromReader((Reader)value, length);
            return (String)value;
        }

        return value.toString();
    }

    /**
     * Get the byte array value of the parameter.
     *
     * @return The data value as a <code>byte[]</code> or null.
     */
    byte[] getBytes(String charset) throws IOException {
        if (value == null || value instanceof byte[]) {
            return (byte[])value;
        }

        if (value instanceof InputStream) {
            value = loadFromStream((InputStream) value, length);

            return (byte[]) value;
        }

        if (value instanceof Reader) {
            String tmp = loadFromReader((Reader) value, length);
            value = Support.encodeString(charset, tmp);
            return (byte[]) value;
        }

        if (value instanceof String) {
            return Support.encodeString(charset, (String) value);
        }

        return new byte[0];
    }

    /**
     * Load a byte array from an InputStream
     *
     * @param in The InputStream to read from.
     * @param length The length of the stream.
     * @return The data as a <code>byte[]</code>.
     * @throws IOException
     */
    private static byte[] loadFromStream(InputStream in, int length)
        throws IOException {
        byte[] buf = new byte[length];

        int pos = 0, res;
        while (pos != length && (res = in.read(buf, pos, length - pos)) != -1) {
            pos += res;
        }
        if (pos != length) {
            throw new java.io.IOException(
                "Data in stream less than specified by length");
        }

        if (in.read() >= 0) {
            throw new java.io.IOException(
                    "More data in stream than specified by length");
        }

        return buf;
    }

    /**
     * Create a String from a Reader stream.
     *
     * @param in The Reader object with the data.
     * @param length Number of characters to read.
     * @return The data as a <code>String</code>.
     * @throws IOException
     */
    private static String loadFromReader(Reader in, int length)
        throws IOException {
        char[] buf = new char[length];

        int pos = 0, res;
        while (pos != length && (res = in.read(buf, pos, length - pos)) != -1) {
            pos += res;
        }
        if (pos != length) {
            throw new java.io.IOException(
                "Data in stream less than specified by length");
        }

        if (in.read() >= 0) {
            throw new java.io.IOException(
                    "More data in stream than specified by length");
        }

        return new String(buf);
    }

    /**
     * Creates a shallow copy of this <code>ParamInfo</code> instance. Used by
     * the <code>PreparedStatement</code> batching implementation to duplicate
     * parameters.
     */
    public Object clone() {
        try {
            return super.clone();
        } catch (CloneNotSupportedException ex) {
            // Will not happen
            return null;
        }
    }
}
