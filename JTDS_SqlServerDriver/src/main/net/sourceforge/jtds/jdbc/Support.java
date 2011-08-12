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
import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.sql.*;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.HashMap;

import net.sourceforge.jtds.util.Logger;

/**
 * This class contains static utility methods designed to support the
 * main driver classes.
 * <p>
 * Implementation notes:
 * <ol>
 * <li>The methods in this class incorporate some code from previous versions
 *     of jTDS to handle dates, BLobs etc.
 * <li>This class contains routines to generate runtime messages from the resource file.
 * <li>The key data conversion logic used in Statements and result sets is implemented here.
 * <li>There is nothing here which is TDS specific.
 * </ol>
 *
 * @author Mike Hutchinson
 * @author jTDS project
 * @version $Id: Support.java,v 1.56.2.5 2009-10-22 07:28:23 ickzon Exp $
 */
public class Support {
    // Constants used in datatype conversions to avoid object allocations.
    private static final Integer INTEGER_ZERO = new Integer(0);
    private static final Integer INTEGER_ONE = new Integer(1);
    private static final Long LONG_ZERO = new Long(0L);
    private static final Long LONG_ONE = new Long(1L);
    private static final Float FLOAT_ZERO = new Float(0.0);
    private static final Float FLOAT_ONE = new Float(1.0);
    private static final Double DOUBLE_ZERO = new Double(0.0);
    private static final Double DOUBLE_ONE = new Double(1.0);
    private static final BigDecimal BIG_DECIMAL_ZERO = new BigDecimal(0.0);
    private static final BigDecimal BIG_DECIMAL_ONE = new BigDecimal(1.0);
    private static final java.sql.Date DATE_ZERO = new java.sql.Date(0);
    private static final java.sql.Time TIME_ZERO = new java.sql.Time(0);
    private static final BigInteger MIN_VALUE_LONG_BI = new BigInteger(String.valueOf(Long.MIN_VALUE));
    private static final BigInteger MAX_VALUE_LONG_BI = new BigInteger(String.valueOf(Long.MAX_VALUE));
    private static final BigDecimal MIN_VALUE_LONG_BD = new BigDecimal(String.valueOf(Long.MIN_VALUE));
    private static final BigDecimal MAX_VALUE_LONG_BD = new BigDecimal(String.valueOf(Long.MAX_VALUE));
    private static final BigInteger MAX_VALUE_28 = new BigInteger("9999999999999999999999999999");
    private static final BigInteger MAX_VALUE_38 = new BigInteger("99999999999999999999999999999999999999");

    /**
     * Convert java clases to java.sql.Type constant.
     */
    private static final HashMap typeMap = new HashMap();

    static {
        typeMap.put(Byte.class,               new Integer(java.sql.Types.TINYINT));
        typeMap.put(Short.class,              new Integer(java.sql.Types.SMALLINT));
        typeMap.put(Integer.class,            new Integer(java.sql.Types.INTEGER));
        typeMap.put(Long.class,               new Integer(java.sql.Types.BIGINT));
        typeMap.put(Float.class,              new Integer(java.sql.Types.REAL));
        typeMap.put(Double.class,             new Integer(java.sql.Types.DOUBLE));
        typeMap.put(BigDecimal.class,         new Integer(java.sql.Types.DECIMAL));
        typeMap.put(Boolean.class,            new Integer(JtdsStatement.BOOLEAN));
        typeMap.put(byte[].class,             new Integer(java.sql.Types.VARBINARY));
        typeMap.put(java.sql.Date.class,      new Integer(java.sql.Types.DATE));
        typeMap.put(java.sql.Time.class,      new Integer(java.sql.Types.TIME));
        typeMap.put(java.sql.Timestamp.class, new Integer(java.sql.Types.TIMESTAMP));
        typeMap.put(BlobImpl.class,           new Integer(java.sql.Types.LONGVARBINARY));
        typeMap.put(ClobImpl.class,           new Integer(java.sql.Types.LONGVARCHAR));
        typeMap.put(String.class,             new Integer(java.sql.Types.VARCHAR));
        typeMap.put(Blob.class,               new Integer(java.sql.Types.LONGVARBINARY));
        typeMap.put(Clob.class,               new Integer(java.sql.Types.LONGVARCHAR));
    }

    /**
     *  Hex constants to use in conversion routines.
     */
    private static final char hex[] = {'0', '1', '2', '3', '4', '5', '6','7',
        '8', '9', 'A', 'B', 'C', 'D', 'E','F'
    };

    /**
     * Thread-bound utility Calendar object.
     */
    private static final ThreadLocal calendar = new ThreadLocal() {
        protected Object initialValue() {
            return new GregorianCalendar();
            }
        };

    /**
     * Convert a byte[] object to a hex string.
     *
     * @param bytes The byte array to convert.
     * @return The hex equivalent as a <code>String</code>.
     */
    public static String toHex(byte[] bytes) {
        int len = bytes.length;

        if (len > 0) {
            StringBuffer buf = new StringBuffer(len * 2);

            for (int i = 0; i < len; i++) {
                int b1 = bytes[i] & 0xFF;

                buf.append(hex[b1 >> 4]);
                buf.append(hex[b1 & 0x0F]);
            }

            return buf.toString();
        }

        return "";
    }

    /**
     * Normalize a BigDecimal value so that it fits within the
     * available precision.
     *
     * @param value The decimal value to normalize.
     * @param maxPrecision The decimal precision supported by the server
     *        (assumed to be a value of either 28 or 38).
     * @return The possibly normalized decimal value as a <code>BigDecimal</code>.
     * @throws SQLException If the number is too big.
     */
    static BigDecimal normalizeBigDecimal(BigDecimal value, int maxPrecision)
            throws SQLException {

        if (value == null) {
            return null;
        }

        if (value.scale() < 0) {
            // Java 1.5 BigDecimal allows negative scales.
            // jTDS cannot send these so re-scale.
            value = value.setScale(0);
        }

        if (value.scale() > maxPrecision) {
            // This is an optimization to quickly adjust the scale of a
            // very precise BD value. For example
            // BigDecimal((double)1.0/3.0) yields a BD 54 digits long!
            value = value.setScale(maxPrecision, BigDecimal.ROUND_HALF_UP);
        }

        BigInteger max = (maxPrecision == TdsData.DEFAULT_PRECISION_28) ? MAX_VALUE_28 : MAX_VALUE_38;

        while (value.abs().unscaledValue().compareTo(max) > 0) {
            // OK we need to reduce the scale if possible to preserve
            // the integer part of the number and still fit within the
            // available precision.
            int scale = value.scale() - 1;

            if (scale < 0) {
                // Can't do it number just too big
                throw new SQLException(Messages.get("error.normalize.numtoobig",
                        String.valueOf(maxPrecision)), "22000");
            }

            value = value.setScale(scale, BigDecimal.ROUND_HALF_UP);
        }

        return value;
    }

    static Object castNumeric(Object orig, int sourceType, int targetType) {

        
        
        return null;
    }
    

    /**
     * Convert an existing data object to the specified JDBC type.
     *
     * @param callerReference an object reference to the caller of this method;
     *                        must be a <code>Connection</code>,
     *                        <code>Statement</code> or <code>ResultSet</code>
     * @param x               the data object to convert
     * @param jdbcType        the required type constant from
     *                        <code>java.sql.Types</code>
     * @return the converted data object
     * @throws SQLException if the conversion is not supported or fails
     */
    static Object convert(Object callerReference, Object x, int jdbcType, String charSet)
            throws SQLException {
        // handle null value
        if (x == null) {
            switch (jdbcType) {
                case java.sql.Types.BIT:
                case JtdsStatement.BOOLEAN:
                    return Boolean.FALSE;
    
                case java.sql.Types.TINYINT:
                case java.sql.Types.SMALLINT:
                case java.sql.Types.INTEGER:
                    return INTEGER_ZERO;
    
                case java.sql.Types.BIGINT:
                    return LONG_ZERO;
    
                case java.sql.Types.REAL:
                    return FLOAT_ZERO;
    
                case java.sql.Types.FLOAT:
                case java.sql.Types.DOUBLE:
                    return DOUBLE_ZERO;

                default:
                    return null;
            }
        }

        try {
            switch (jdbcType) {
                case java.sql.Types.TINYINT:
                    if (x instanceof Boolean) {
                        return ((Boolean) x).booleanValue() ? INTEGER_ONE : INTEGER_ZERO;
                    } else if (x instanceof Byte) {
                        return new Integer(((Byte)x).byteValue() & 0xFF);
                    } else  {
                        long val;
                        if (x instanceof Number) {
                            val = ((Number)x).longValue();
                        } else if (x instanceof String) {
                            val = new Long(((String) x).trim()).longValue();
                        } else {
                            break;
                        }
                        if (val < Byte.MIN_VALUE || val > Byte.MAX_VALUE) {
                            throw new SQLException(Messages.get("error.convert.numericoverflow", x, getJdbcTypeName(jdbcType)), "22003");
                        } else {
                            return new Integer(new Long(val).intValue());
                        }
                    }

                case java.sql.Types.SMALLINT:
                    if (x instanceof Boolean) {
                        return ((Boolean) x).booleanValue() ? INTEGER_ONE : INTEGER_ZERO;
                    } else if (x instanceof Short) {
                        return new Integer(((Short)x).shortValue());
                    } else if (x instanceof Byte) {
                        return new Integer(((Byte)x).byteValue() & 0xFF);
                    } else  {
                        long val;
                        if (x instanceof Number) {
                            val = ((Number)x).longValue();
                        } else if (x instanceof String) {
                            val = new Long(((String) x).trim()).longValue();
                        } else {
                            break;
                        }
                        if (val < Short.MIN_VALUE || val > Short.MAX_VALUE) {
                            throw new SQLException(Messages.get("error.convert.numericoverflow", x, getJdbcTypeName(jdbcType)), "22003");
                        } else {
                            return new Integer(new Long(val).intValue());
                        }
                    }

                case java.sql.Types.INTEGER:
                    if (x instanceof Integer) {
                        return x;
                    }
                    else if (x instanceof Boolean) {
                        return ((Boolean) x).booleanValue() ? INTEGER_ONE : INTEGER_ZERO;
                    } else if (x instanceof Short) {
                        return new Integer(((Short)x).shortValue());
                    } else if (x instanceof Byte) {
                        return new Integer(((Byte)x).byteValue() & 0xFF);
                    } else  {
                        long val;
                        if (x instanceof Number) {
                            val = ((Number)x).longValue();
                        } else if (x instanceof String) {
                            val = new Long(((String) x).trim()).longValue();
                        } else {
                            break;
                        }
                        if (val < Integer.MIN_VALUE || val > Integer.MAX_VALUE) {
                            throw new SQLException(Messages.get("error.convert.numericoverflow", x, getJdbcTypeName(jdbcType)), "22003");
                        } else {
                            return new Integer(new Long(val).intValue());
                        }
                    }

                case java.sql.Types.BIGINT:
                    if (x instanceof BigDecimal ) {
                        BigDecimal val = (BigDecimal) x;
                        if (val.compareTo(MIN_VALUE_LONG_BD) < 0 || val.compareTo(MAX_VALUE_LONG_BD) > 0) {
                            throw new SQLException(Messages.get("error.convert.numericoverflow", x, getJdbcTypeName(jdbcType)), "22003");
                        } else {
                            return new Long(val.longValue());
                        }
                    } else if (x instanceof Long) {
                        return x;
                    } else if (x instanceof Boolean) {
                        return ((Boolean) x).booleanValue() ? LONG_ONE : LONG_ZERO;
                    } else if (x instanceof Byte) {
                        return new Long(((Byte)x).byteValue() & 0xFF);
                    } else if (x instanceof BigInteger) {
                        BigInteger val = (BigInteger) x;
                        if (val.compareTo(MIN_VALUE_LONG_BI) < 0 || val.compareTo(MAX_VALUE_LONG_BI) > 0) {
                            throw new SQLException(Messages.get("error.convert.numericoverflow", x, getJdbcTypeName(jdbcType)), "22003");
                        } else {
                            return new Long(val.longValue());
                        }
                    } else if (x instanceof Number) {
                        return new Long(((Number) x).longValue());
                    } else if (x instanceof String) {
                        return new Long(((String) x).trim());
                    } else {
                        break;
                    }

                case java.sql.Types.REAL:
                    if (x instanceof Float) {
                        return x;
                    } else if (x instanceof Byte) {
                        return new Float(((Byte)x).byteValue() & 0xFF);
                    } else if (x instanceof Number) {
                        return new Float(((Number) x).floatValue());
                    } else if (x instanceof String) {
                        return new Float(((String) x).trim());
                    } else if (x instanceof Boolean) {
                        return ((Boolean) x).booleanValue() ? FLOAT_ONE : FLOAT_ZERO;
                    }

                break;

                case java.sql.Types.FLOAT:
                case java.sql.Types.DOUBLE:
                    if (x instanceof Double) {
                        return x;
                    } else if (x instanceof Byte) {
                        return new Double(((Byte)x).byteValue() & 0xFF);
                    } else if (x instanceof Number) {
                        return new Double(((Number) x).doubleValue());
                    } else if (x instanceof String) {
                        return new Double(((String) x).trim());
                    } else if (x instanceof Boolean) {
                        return ((Boolean) x).booleanValue() ? DOUBLE_ONE : DOUBLE_ZERO;
                    }

                    break;

                case java.sql.Types.NUMERIC:
                case java.sql.Types.DECIMAL:
                    if (x instanceof BigDecimal) {
                        return x;
                    } else if (x instanceof Number) {
                        return new BigDecimal(x.toString());
                    } else if (x instanceof String) {
                        return new BigDecimal((String) x);
                    } else if (x instanceof Boolean) {
                        return ((Boolean) x).booleanValue() ? BIG_DECIMAL_ONE : BIG_DECIMAL_ZERO;
                    }

                    break;

                case java.sql.Types.VARCHAR:
                case java.sql.Types.CHAR:
                    if (x instanceof String) {
                        return x;
                    } else if (x instanceof Number) {
                        return x.toString();
                    } else if (x instanceof Boolean) {
                        return((Boolean) x).booleanValue() ? "1" : "0";
                    } else if (x instanceof Clob) {
                        Clob clob = (Clob) x;
                        long length = clob.length();

                        if (length > Integer.MAX_VALUE) {
                            throw new SQLException(Messages.get("error.normalize.lobtoobig"),
                                                   "22000");
                        }

                        return clob.getSubString(1, (int) length);
                    } else if (x instanceof Blob) {
                        Blob blob = (Blob) x;
                        long length = blob.length();

                        if (length > Integer.MAX_VALUE) {
                            throw new SQLException(Messages.get("error.normalize.lobtoobig"),
                                                   "22000");
                        }

                        x = blob.getBytes(1, (int) length);
                    }

                    if (x instanceof byte[]) {
                        return toHex((byte[])x);
                    }

                    return x.toString(); // Last hope!

                case java.sql.Types.BIT:
                case JtdsStatement.BOOLEAN:
                    if (x instanceof Boolean) {
                        return x;
                    } else if (x instanceof Number) {
                        return(((Number) x).intValue() == 0) ? Boolean.FALSE : Boolean.TRUE;
                    } else if (x instanceof String) {
                        String tmp = ((String) x).trim();

                        return ("1".equals(tmp) || "true".equalsIgnoreCase(tmp)) ? Boolean.TRUE : Boolean.FALSE;
                    }

                    break;

                case java.sql.Types.VARBINARY:
                case java.sql.Types.BINARY:
                    if (x instanceof byte[]) {
                        return x;
                    } else if (x instanceof Blob) {
                        Blob blob = (Blob) x;

                        return blob.getBytes(1, (int) blob.length());
                    } else if (x instanceof Clob) {
                        Clob clob = (Clob) x;
                        long length = clob.length();

                        if (length > Integer.MAX_VALUE) {
                            throw new SQLException(Messages.get("error.normalize.lobtoobig"),
                                                   "22000");
                        }

                        x = clob.getSubString(1, (int) length);
                    }

                    if (x instanceof String) {
                        //
                        // Strictly speaking this conversion is not required by
                        // the JDBC standard but jTDS has always supported it.
                        //
                        if (charSet == null) {
                            charSet = "ISO-8859-1";
                        }

                        try {
                            return ((String) x).getBytes(charSet);
                        } catch (UnsupportedEncodingException e) {
                            return ((String) x).getBytes();
                        }
                    } else if (x instanceof UniqueIdentifier) {
                        return ((UniqueIdentifier) x).getBytes();
                    }

                    break;

                case java.sql.Types.TIMESTAMP:
                    if (x instanceof DateTime) {
                        return ((DateTime) x).toTimestamp();
                    } else if (x instanceof java.sql.Timestamp) {
                        return x;
                    } else if (x instanceof java.sql.Date) {
                        return new java.sql.Timestamp(((java.sql.Date) x).getTime());
                    } else if (x instanceof java.sql.Time) {
                        return new java.sql.Timestamp(((java.sql.Time) x).getTime());
                    } else if (x instanceof java.lang.String) {
                        return java.sql.Timestamp.valueOf(((String)x).trim());
                    }

                    break;

                case java.sql.Types.DATE:
                    if (x instanceof DateTime) {
                        return ((DateTime) x).toDate();
                    } else if (x instanceof java.sql.Date) {
                        return x;
                    } else if (x instanceof java.sql.Time) {
                        return DATE_ZERO;
                    } else if (x instanceof java.sql.Timestamp) {
                        GregorianCalendar cal = (GregorianCalendar) calendar.get();
                        cal.setTime((java.util.Date) x);
                        cal.set(Calendar.HOUR_OF_DAY, 0);
                        cal.set(Calendar.MINUTE, 0);
                        cal.set(Calendar.SECOND, 0);
                        cal.set(Calendar.MILLISECOND, 0);
// VM1.4+ only              return new java.sql.Date(cal.getTimeInMillis());
                        return new java.sql.Date(cal.getTime().getTime());
                    } else if (x instanceof java.lang.String) {
                        return java.sql.Date.valueOf(((String) x).trim());
                    }

                    break;

                case java.sql.Types.TIME:
                    if (x instanceof DateTime) {
                        return ((DateTime) x).toTime();
                    } else if (x instanceof java.sql.Time) {
                        return x;
                    } else if (x instanceof java.sql.Date) {
                        return TIME_ZERO;
                    } else if (x instanceof java.sql.Timestamp) {
                        GregorianCalendar cal = (GregorianCalendar) calendar.get();
// VM 1.4+ only             cal.setTimeInMillis(((java.sql.Timestamp)x).getTime());
                        cal.setTime((java.util.Date)x);
                        cal.set(Calendar.YEAR, 1970);
                        cal.set(Calendar.MONTH, 0);
                        cal.set(Calendar.DAY_OF_MONTH,1);
// VM 1.4+ only             return new java.sql.Time(cal.getTimeInMillis());*/
                        return new java.sql.Time(cal.getTime().getTime());
                    } else if (x instanceof java.lang.String) {
                        return java.sql.Time.valueOf(((String) x).trim());
                    }

                    break;

                case java.sql.Types.OTHER:
                    return x;

                case java.sql.Types.JAVA_OBJECT:
                    throw new SQLException(
                            Messages.get("error.convert.badtypes",
                                    x.getClass().getName(),
                                    getJdbcTypeName(jdbcType)), "22005");

                case java.sql.Types.LONGVARBINARY:
                case java.sql.Types.BLOB:
                    if (x instanceof Blob) {
                        return x;
                    } else if (x instanceof byte[]) {
                        return new BlobImpl(getConnection(callerReference), (byte[]) x);
                    } else if (x instanceof Clob) {
                        //
                        // Convert CLOB to BLOB. Not required by the standard but we will
                        // do it anyway.
                        //
                        Clob clob = (Clob) x;
                        try {
                            if (charSet == null) {
                                charSet = "ISO-8859-1";
                            }
                            Reader rdr = clob.getCharacterStream();
                            BlobImpl blob = new BlobImpl(getConnection(callerReference));
                            BufferedWriter out =
                                new BufferedWriter(new OutputStreamWriter(blob.setBinaryStream(1), charSet));
                            // TODO Use a buffer to improve performance
                            int c;
                            while ((c = rdr.read()) >= 0) {
                                out.write(c);
                            }
                            out.close();
                            rdr.close();
                            return blob;
                        } catch (UnsupportedEncodingException e) {
                            // Unlikely to happen but fall back on in memory copy
                            x = clob.getSubString(1, (int) clob.length());
                        } catch (IOException e) {
                            throw new SQLException(Messages.get("error.generic.ioerror", e.getMessage()),
                            "HY000");
                        }
                    }

                    if (x instanceof String) {
                        //
                        // Strictly speaking this conversion is also not required by
                        // the JDBC standard but jTDS has always supported it.
                        //
                        BlobImpl blob = new BlobImpl(getConnection(callerReference));
                        String data = (String) x;

                        if (charSet == null) {
                            charSet = "ISO-8859-1";
                        }

                        try {
                            blob.setBytes(1, data.getBytes(charSet));
                        } catch (UnsupportedEncodingException e) {
                            blob.setBytes(1, data.getBytes());
                        }

                        return blob;
                    }

                    break;

                case java.sql.Types.LONGVARCHAR:
                case java.sql.Types.CLOB:
                    if (x instanceof Clob) {
                        return x;
                    } else if (x instanceof Blob) {
                        //
                        // Convert BLOB to CLOB
                        //
                        Blob blob = (Blob) x;
                        try {
                            InputStream is = blob.getBinaryStream();
                            ClobImpl clob = new ClobImpl(getConnection(callerReference));
                            Writer out = clob.setCharacterStream(1);
                            // TODO Use a buffer to improve performance
                            int b;
                            // These reads/writes are buffered by the underlying blob buffers
                            while ((b = is.read()) >= 0) {
                                out.write(hex[b >> 4]);
                                out.write(hex[b & 0x0F]);
                            }
                            out.close();
                            is.close();
                            return clob;
                        } catch (IOException e) {
                            throw new SQLException(Messages.get("error.generic.ioerror", e.getMessage()),
                            "HY000");
                        }
                    } else if (x instanceof Boolean) {
                        x = ((Boolean) x).booleanValue() ? "1" : "0";
                    } else if (!(x instanceof byte[])) {
                        x = x.toString();
                    }

                    if (x instanceof byte[]) {
                        ClobImpl clob = new ClobImpl(getConnection(callerReference));
                        clob.setString(1, toHex((byte[]) x));

                        return clob;
                    } else if (x instanceof String) {
                        return new ClobImpl(getConnection(callerReference), (String) x);
                    }

                    break;

                default:
                    throw new SQLException(
                            Messages.get("error.convert.badtypeconst",
                                    getJdbcTypeName(jdbcType)), "HY004");
            }

            throw new SQLException(
                    Messages.get("error.convert.badtypes",
                            x.getClass().getName(),
                            getJdbcTypeName(jdbcType)), "22005");
        } catch (NumberFormatException nfe) {
            throw new SQLException(
                    Messages.get("error.convert.badnumber",
                            getJdbcTypeName(jdbcType)), "22000");
        }
    }

    /**
     * Get the JDBC type constant which matches the supplied Object type.
     *
     * @param value The object to analyse.
     * @return The JDBC type constant as an <code>int</code>.
     */
    static int getJdbcType(Object value) {
        if (value == null) {
            return java.sql.Types.NULL;
        }

        return getJdbcType(value.getClass());
    }

    /**
     * Get the JDBC type constant which matches the supplied <code>Class</code>.
     *
     * @param typeClass the <code>Class</code> to analyse
     * @return          the JDBC type constant as an <code>int</code>
     */
    static int getJdbcType(Class typeClass) {
        if (typeClass == null) {
            return java.sql.Types.JAVA_OBJECT;
        }

        Object type = typeMap.get(typeClass);

        if (type == null) {
            // not in typeMap - try recursion through superclass hierarchy
            return getJdbcType(typeClass.getSuperclass());
        }

        return ((Integer) type).intValue();
    }

    /**
     * Get a String describing the supplied JDBC type constant.
     *
     * @param jdbcType The constant to be decoded.
     * @return The text decode of the type constant as a <code>String</code>.
     */
    static String getJdbcTypeName(int jdbcType) {
        switch (jdbcType) {
            case java.sql.Types.ARRAY:         return "ARRAY";
            case java.sql.Types.BIGINT:        return "BIGINT";
            case java.sql.Types.BINARY:        return "BINARY";
            case java.sql.Types.BIT:           return "BIT";
            case java.sql.Types.BLOB:          return "BLOB";
            case JtdsStatement.BOOLEAN:        return "BOOLEAN";
            case java.sql.Types.CHAR:          return "CHAR";
            case java.sql.Types.CLOB:          return "CLOB";
            case JtdsStatement.DATALINK:       return "DATALINK";
            case java.sql.Types.DATE:          return "DATE";
            case java.sql.Types.DECIMAL:       return "DECIMAL";
            case java.sql.Types.DISTINCT:      return "DISTINCT";
            case java.sql.Types.DOUBLE:        return "DOUBLE";
            case java.sql.Types.FLOAT:         return "FLOAT";
            case java.sql.Types.INTEGER:       return "INTEGER";
            case java.sql.Types.JAVA_OBJECT:   return "JAVA_OBJECT";
            case java.sql.Types.LONGVARBINARY: return "LONGVARBINARY";
            case java.sql.Types.LONGVARCHAR:   return "LONGVARCHAR";
            case java.sql.Types.NULL:          return "NULL";
            case java.sql.Types.NUMERIC:       return "NUMERIC";
            case java.sql.Types.OTHER:         return "OTHER";
            case java.sql.Types.REAL:          return "REAL";
            case java.sql.Types.REF:           return "REF";
            case java.sql.Types.SMALLINT:      return "SMALLINT";
            case java.sql.Types.STRUCT:        return "STRUCT";
            case java.sql.Types.TIME:          return "TIME";
            case java.sql.Types.TIMESTAMP:     return "TIMESTAMP";
            case java.sql.Types.TINYINT:       return "TINYINT";
            case java.sql.Types.VARBINARY:     return "VARBINARY";
            case java.sql.Types.VARCHAR:       return "VARCHAR";
            default:                           return "ERROR";
        }
    }

    /**
     * Retrieve the fully qualified java class name for the
     * supplied JDBC Types constant.
     *
     * @param jdbcType The JDBC Types constant.
     * @return The fully qualified java class name as a <code>String</code>.
     */
    static String getClassName(int jdbcType) {
        switch (jdbcType) {
            case JtdsStatement.BOOLEAN:
            case java.sql.Types.BIT:
                return "java.lang.Boolean";

            case java.sql.Types.TINYINT:
            case java.sql.Types.SMALLINT:
            case java.sql.Types.INTEGER:
                return  "java.lang.Integer";

            case java.sql.Types.BIGINT:
                return "java.lang.Long";

            case java.sql.Types.NUMERIC:
            case java.sql.Types.DECIMAL:
                return "java.math.BigDecimal";

            case java.sql.Types.REAL:
                return "java.lang.Float";

            case java.sql.Types.FLOAT:
            case java.sql.Types.DOUBLE:
                return "java.lang.Double";

            case java.sql.Types.CHAR:
            case java.sql.Types.VARCHAR:
                return "java.lang.String";

            case java.sql.Types.BINARY:
            case java.sql.Types.VARBINARY:
                return "[B";

            case java.sql.Types.LONGVARBINARY:
            case java.sql.Types.BLOB:
                return "java.sql.Blob";

            case java.sql.Types.LONGVARCHAR:
            case java.sql.Types.CLOB:
                return "java.sql.Clob";

            case java.sql.Types.DATE:
                return "java.sql.Date";

            case java.sql.Types.TIME:
                return "java.sql.Time";

            case java.sql.Types.TIMESTAMP:
                return "java.sql.Timestamp";
        }

        return "java.lang.Object";
    }

    /**
     * Embed the data object as a string literal in the buffer supplied.
     *
     * @param buf The buffer in which the data will be embedded.
     * @param value The data object.
     * @param isUnicode Set to <code>true</code> if Unicode strings should be used, else <code>false</code>.
     * @param connection The {@link ConnectionJDBC2} object.
     */
    static void embedData(StringBuffer buf, Object value, boolean isUnicode, ConnectionJDBC2 connection)
            throws SQLException {
        buf.append(' ');
        if (value == null) {
            buf.append("NULL ");
            return;
        }

        if (value instanceof Blob) {
            Blob blob = (Blob) value;

            value = blob.getBytes(1, (int) blob.length());
        } else if (value instanceof Clob) {
            Clob clob = (Clob) value;

            value = clob.getSubString(1, (int) clob.length());
        }

        if (value instanceof DateTime) {
            buf.append('\'');
            buf.append(value);
            buf.append('\'');
        } else
        if (value instanceof byte[]) {
            byte[] bytes = (byte[]) value;

            int len = bytes.length;

            if (len >= 0) {
                buf.append('0').append('x');
                if (len == 0 && connection.getTdsVersion() < Driver.TDS70) {
                    // Zero length binary values are not allowed
                    buf.append('0').append('0');
                } else {
                    for (int i = 0; i < len; i++) {
                        int b1 = bytes[i] & 0xFF;

                        buf.append(hex[b1 >> 4]);
                        buf.append(hex[b1 & 0x0F]);
                    }
                }
            }
        } else if (value instanceof String) {
            String tmp = (String) value;
            int len = tmp.length();

            if (isUnicode) {
                buf.append('N');
            }
            buf.append('\'');

            for (int i = 0; i < len; i++) {
                char c = tmp.charAt(i);

                if (c == '\'') {
                    buf.append('\'');
                }

                buf.append(c);
            }

            buf.append('\'');
        } else if (value instanceof java.sql.Date) {
            DateTime dt = new DateTime((java.sql.Date)value);
            buf.append('\'');
            buf.append(dt);
            buf.append('\'');
        } else if (value instanceof java.sql.Time) {
            DateTime dt = new DateTime((java.sql.Time)value);
            buf.append('\'');
            buf.append(dt);
            buf.append('\'');
        } else if (value instanceof java.sql.Timestamp) {
            DateTime dt = new DateTime((java.sql.Timestamp)value);
            buf.append('\'');
            buf.append(dt);
            buf.append('\'');
        } else if (value instanceof Boolean) {
            buf.append(((Boolean) value).booleanValue() ? '1' : '0');
        } else if (value instanceof BigDecimal) {
            //
            // Ensure large decimal number does not overflow the
            // maximum precision of the server.
            // Main problem is with small numbers e.g. BigDecimal(1.0).toString() =
            // 0.1000000000000000055511151231....
            //
            String tmp = value.toString();
            int maxlen = connection.getMaxPrecision();
            if (tmp.charAt(0) == '-') {
                maxlen++;
            }
            if (tmp.indexOf('.') >= 0) {
                maxlen++;
            }
            if (tmp.length() > maxlen) {
                buf.append(tmp.substring(0, maxlen));
            } else {
                buf.append(tmp);
            }
        } else {
            buf.append(value.toString());
        }
        buf.append(' ');
    }

    /**
     * Generates a unique statement key for a given SQL statement.
     *
     * @param sql        the sql statement to generate the key for
     * @param params     the statement parameters
     * @param serverType the type of server to generate the key for
     * @param catalog    the catalog is required for uniqueness on Microsoft
     *                   SQL Server
     * @param autoCommit true if in auto commit mode
     * @param cursor     true if this is a prepared cursor
     * @return the unique statement key
     */
    static String getStatementKey(String sql, ParamInfo[] params,
                                  int serverType, String catalog,
                                  boolean autoCommit, boolean cursor) {
        StringBuffer key;

        if (serverType == Driver.SQLSERVER) {
            key = new StringBuffer(1 + catalog.length() + sql.length()
                    + 11 * params.length);
            // Need to distinguish otherwise identical SQL for cursor and
            // non cursor prepared statements (sp_prepare/sp_cursorprepare).
            key.append((cursor) ? 'C':'X');
            // Need to ensure that the current database is included in the key
            // as procedures and handles are database specific.
            key.append(catalog);
            // Now the actual SQL statement
            key.append(sql);
            //
            // Append parameter data types to key.
            //
            for (int i = 0; i < params.length; i++) {
                key.append(params[i].sqlType);
            }
        } else {
            key = new StringBuffer(sql.length() + 2);
            // A simple key works for Sybase just need to know if
            // proc created in chained mode or not.
            key.append((autoCommit) ? 'T': 'F');
            // Now the actual SQL statement
            key.append(sql);
        }

        return key.toString();
    }

    /**
     * Constructs a parameter definition string for use with
     * sp_executesql, sp_prepare, sp_prepexec, sp_cursoropen,
     * sp_cursorprepare and sp_cursorprepexec.
     *
     * @param parameters Parameters to construct the definition for
     * @return a parameter definition string
     */
    static String getParameterDefinitions(ParamInfo[] parameters) {
        StringBuffer sql = new StringBuffer(parameters.length * 15);

        // Build parameter descriptor
        for (int i = 0; i < parameters.length; i++) {
            if (parameters[i].name == null) {
                sql.append("@P");
                sql.append(i);
            } else {
                sql.append(parameters[i].name);
            }

            sql.append(' ');
            sql.append(parameters[i].sqlType);

            if (i + 1 < parameters.length) {
                sql.append(',');
            }
        }

        return sql.toString();
    }

    /**
     * Update the SQL string and replace the ? markers with parameter names
     * eg @P0, @P1 etc.
     *
     * @param sql  the SQL containing markers to substitute
     * @param list the parameter list
     * @return the modified SQL as a <code>String</code>
     */
    static String substituteParamMarkers(String sql, ParamInfo[] list) {
        // A parameter can have at most 8 characters: " @P" plus at most 4
        // digits plus " ". We subtract the "?" placeholder, that's at most
        // 7 extra characters needed for each parameter.
        char[] buf = new char[sql.length() + list.length * 7];
        int bufferPtr = 0; // Output buffer pointer
        int start = 0;     // Input string pointer
        StringBuffer number = new StringBuffer(4);

        for (int i = 0; i < list.length; i++) {
            int pos = list[i].markerPos;

            if (pos > 0) {
                sql.getChars(start, pos, buf, bufferPtr);
                bufferPtr += (pos - start);
                start = pos + 1;

                // Append " @P"
                buf[bufferPtr++] = ' ';
                buf[bufferPtr++] = '@';
                buf[bufferPtr++] = 'P';

                // Append parameter number
                // Rather complicated, but it's the only way in which no
                // unnecessary objects are created
                number.setLength(0);
                number.append(i);
                number.getChars(0, number.length(), buf, bufferPtr);
                bufferPtr += number.length();

                // Append " "
                buf[bufferPtr++] = ' ';
            }
        }

        if (start < sql.length()) {
            sql.getChars(start, sql.length(), buf, bufferPtr);
            bufferPtr += (sql.length() - start);
        }

        return new String(buf, 0, bufferPtr);
    }

    /**
     * Substitute actual data for the parameter markers to simulate
     * parameter substitution in a PreparedStatement.
     *
     * @param sql The SQL containing parameter markers to substitute.
     * @param list The parameter descriptors.
     * @param connection The current connection.
     * @return The modified SQL statement.
     */
    static String substituteParameters(String sql, ParamInfo[] list, ConnectionJDBC2 connection)
            throws SQLException {
        int len = sql.length();

        for (int i = 0; i < list.length; i++) {
            if (!list[i].isRetVal && !list[i].isSet && !list[i].isOutput) {
                throw new SQLException(Messages.get("error.prepare.paramnotset",
                                                          Integer.toString(i+1)),
                                       "07000");
            }

            Object value = list[i].value;

            if (value instanceof java.io.InputStream
                    || value instanceof java.io.Reader) {
                try {
                    if (list[i].jdbcType == java.sql.Types.LONGVARCHAR ||
                        list[i].jdbcType == java.sql.Types.CLOB ||
                        list[i].jdbcType == java.sql.Types.VARCHAR) {
                        // TODO: Should improve the character set handling here
                        value = list[i].getString("US-ASCII");
                    } else {
                        value = list[i].getBytes("US-ASCII");
                    }
                    // Replace the stream/reader with the String/byte[]
                    list[i].value = value;
                } catch (java.io.IOException e) {
                    throw new SQLException(Messages.get("error.generic.ioerror",
                                                              e.getMessage()),
                                           "HY000");
                }
            }

            if (value instanceof String) {
                len += ((String) value).length() + 5;
            } else if (value instanceof byte[]) {
                len += ((byte[]) value).length * 2 + 4;
            } else {
                len += 32; // Default size
            }
        }

        StringBuffer buf = new StringBuffer(len + 16);
        int start = 0;

        for (int i = 0; i < list.length; i++) {
            int pos = list[i].markerPos;

            if (pos > 0) {
                buf.append(sql.substring(start, list[i].markerPos));
                start = pos + 1;
                final boolean isUnicode = connection.getTdsVersion() >= Driver.TDS70 && list[i].isUnicode;
                Support.embedData(buf, list[i].value, isUnicode, connection);
            }
        }

        if (start < sql.length()) {
            buf.append(sql.substring(start));
        }

        return buf.toString();
    }

    /**
     * Encode a string into a byte array using the specified character set.
     *
     * @param cs The Charset name.
     * @param value The value to encode.
     * @return The value of the String as a <code>byte[]</code>.
     */
    static byte[] encodeString(String cs, String value) {
        try {
            return value.getBytes(cs);
        } catch (UnsupportedEncodingException e) {
            return value.getBytes();
        }
    }

    /**
     * Link the original cause to an <code>SQLWarning</code>.
     * <p>
     * This convenience method calls {@link #linkException(Exception, Throwable)}
     * and casts the result for cleaner code elsewhere.
     *
     * @param sqle The <code>SQLWarning</code> to enhance.
     * @param cause The <code>Throwable</code> to link.
     * @return The original <code>SQLWarning</code> object.
     */
    public static SQLWarning linkException(SQLWarning sqle, Throwable cause) {
        return (SQLWarning) linkException((Exception) sqle, cause);
    }

    /**
     * Link the original cause to an <code>SQLException</code>.
     * <p>
     * This convenience method calls {@link #linkException(Exception, Throwable)}
     * and casts the result for cleaner code elsewhere.
     *
     * @param sqle The <code>SQLException</code> to enhance.
     * @param cause The <code>Throwable</code> to link.
     * @return The original <code>SQLException</code> object.
     */
    public static SQLException linkException(SQLException sqle, Throwable cause) {
        return (SQLException) linkException((Exception) sqle, cause);
    }

    /**
     * Link the original cause to an <code>Exception</code>.
     * <p>
     * If running under JVM 1.4+ the <code>Throwable.initCause(Throwable)</code>
     * method will be invoked to chain the exception, else the exception is
     * logged via the {@link Logger} class.
     * Modeled after the code written by Brian Heineman.
     *
     * @param exception The <code>Exception</code> to enhance.
     * @param cause The <code>Throwable</code> to link.
     * @return The original <code>Exception</code> object.
     */
    public static Throwable linkException(Exception exception, Throwable cause) {
        Class exceptionClass = exception.getClass();
        Class[] parameterTypes = new Class[] {Throwable.class};
        Object[] arguments = new Object[] {cause};

        try {
            Method initCauseMethod = exceptionClass.getMethod("initCause", parameterTypes);
            initCauseMethod.invoke(exception, arguments);
        } catch (NoSuchMethodException e) {
            // Best we can do; this method does not exist in older JVMs.
            if (Logger.isActive()) {
                Logger.logException((Exception) cause);
            }
        } catch (Exception e) {
            // Ignore all other exceptions.  Do not prevent the main exception
            // from being returned if reflection fails for any reason.
        }

        return exception;
    }

    /**
     * Convert a timestamp to a different Timezone.
     *
     * @param value  the timestamp value
     * @param target the <code>Calendar</code> containing the TimeZone
     * @return the new timestamp value as a <code>long</code>
     */
    public static long timeToZone(java.util.Date value, Calendar target) {
        java.util.Date tmp = target.getTime();
        try {
            GregorianCalendar cal = (GregorianCalendar) calendar.get();
            cal.setTime(value);
            if (!Driver.JDBC3 && value instanceof Timestamp) {
                // Not Running under 1.4 so need to add milliseconds
                cal.set(Calendar.MILLISECOND,
                        ((Timestamp)value).getNanos() / 1000000);
            }
            target.set(Calendar.HOUR_OF_DAY, cal.get(Calendar.HOUR_OF_DAY));
            target.set(Calendar.MINUTE, cal.get(Calendar.MINUTE));
            target.set(Calendar.SECOND, cal.get(Calendar.SECOND));
            target.set(Calendar.MILLISECOND, cal.get(Calendar.MILLISECOND));
            target.set(Calendar.YEAR, cal.get(Calendar.YEAR));
            target.set(Calendar.MONTH, cal.get(Calendar.MONTH));
            target.set(Calendar.DAY_OF_MONTH, cal.get(Calendar.DAY_OF_MONTH));
            return target.getTime().getTime();
        }
        finally {
            target.setTime(tmp);
        }
    }

    /**
     * Convert a timestamp from a different Timezone.
     * @param value the timestamp value.
     * @param target the Calendar containing the TimeZone.
     * @return The new timestamp value as a <code>long</code>.
     */
    public static long timeFromZone(java.util.Date value , Calendar target) {
        java.util.Date tmp = target.getTime();
        try {
            GregorianCalendar cal = (GregorianCalendar) calendar.get();
            target.setTime(value);
            if (!Driver.JDBC3 && value instanceof Timestamp) {
                // Not Running under 1.4 so need to add milliseconds
                target.set(Calendar.MILLISECOND,
                        ((Timestamp)value).getNanos() / 1000000);
            }
            cal.set(Calendar.HOUR_OF_DAY, target.get(Calendar.HOUR_OF_DAY));
            cal.set(Calendar.MINUTE, target.get(Calendar.MINUTE));
            cal.set(Calendar.SECOND, target.get(Calendar.SECOND));
            cal.set(Calendar.MILLISECOND, target.get(Calendar.MILLISECOND));
            cal.set(Calendar.YEAR, target.get(Calendar.YEAR));
            cal.set(Calendar.MONTH, target.get(Calendar.MONTH));
            cal.set(Calendar.DAY_OF_MONTH, target.get(Calendar.DAY_OF_MONTH));
            return cal.getTime().getTime();
        }
        finally {
            target.setTime(tmp);
        }
    }

    /**
     * Converts a LOB to the equivalent Java type, i.e. <code>Clob</code> to
     * <code>String</code> and <code>Blob</code> to <code>byte[]</code>. If the
     * value passed is not a LOB object, it is left unchanged and no exception
     * is thrown; the idea is to transparently convert only LOBs.
     *
     * @param value an object that may be a LOB
     * @return if the value was a LOB, the equivalent Java object, otherwise
     *         the original value
     * @throws SQLException if an error occurs while reading the LOB contents
     */
    public static Object convertLOB(Object value) throws SQLException {
        if (value instanceof Clob) {
            Clob c = (Clob) value;
            return c.getSubString(1, (int) c.length());
        }

        if (value instanceof Blob) {
            Blob b = (Blob) value;
            return b.getBytes(1, (int) b.length());
        }

        return value;
    }

    /**
     * Converts a LOB type constant to the equivalent Java type constant, i.e.
     * <code>Types.CLOB</code> to <code>Types.LONGVARCHAR</code> and
     * <code>Types.BLOB</code> to <code>Types.LONGVARBINARY</code>. If the
     * type passed is not that of a LOB, it is left unchanged and no exception
     * is thrown; the idea is to transparently convert only LOB types.
     *
     * @param type a {@link Types} constant defining a JDBC type, possibly a
     *             LOB
     * @return if the type was that of a LOB, the equivalent Java object type,
     *         otherwise the original type
     */
    public static int convertLOBType(int type) {
        switch (type) {
            case Types.BLOB:
                return Types.LONGVARBINARY;
            case Types.CLOB:
                return Types.LONGVARCHAR;
            default:
                return type;
        }
    }

    /**
     * Checks the <code>os.name</code> system property to see if it starts
     * with "windows".
     *
     * @return <code>true</code> if <code>os.name</code> starts with "windows",
     * else <code>false</code>.
     */
    public static boolean isWindowsOS() {
        return System.getProperty("os.name").toLowerCase().startsWith("windows");
    }

    // ------------- Private methods  ---------

    /**
     * Returns the connection for a given <code>ResultSet</code>,
     * <code>Statement</code> or <code>Connection</code> object.
     *
     * @param callerReference an object reference to the caller of this method;
     *        must be a <code>Connection</code>, <code>Statement</code> or
     *        <code>ResultSet</code>
     * @return a connection
     */
    private static ConnectionJDBC2 getConnection(Object callerReference) {
        if (callerReference == null) {
            throw new IllegalArgumentException("callerReference cannot be null.");
        }

        Connection connection;

        try {
            if (callerReference instanceof Connection) {
                connection = (Connection) callerReference;
            } else if (callerReference instanceof Statement) {
                connection = ((Statement) callerReference).getConnection();
            } else if (callerReference instanceof ResultSet) {
                connection = ((ResultSet) callerReference).getStatement().getConnection();
            } else {
                throw new IllegalArgumentException("callerReference is invalid.");
            }
        } catch (SQLException e) {
            throw new IllegalStateException(e.getMessage());
        }

        return (ConnectionJDBC2) connection;
    }

    private Support() {
        // Prevent an instance of this class being created.
    }

    /**
     * Calculate the buffer size to use when buffering the <code>InputStream</code>
     * for named pipes.
     * <p/>
     * The buffer size is tied directly to the packet size because each request
     * to the <code>SmbNamedPipe</code> will send a request for a particular
     * size of packet.  In other words, if you only request 1 byte, the
     * <code>SmbNamedPipe</code> will send a request out and only ask for 1 byte
     * back.  Buffering the expected packet size ensures that all of the data
     * will be returned in the buffer without wasting any space.
     *
     * @param tdsVersion the TDS version for the connection
     * @param packetSize requested packet size for the connection
     * @return minimum default packet size if <code>packetSize == 0</code>,
     *         else <code>packetSize</code>
     */
    static int calculateNamedPipeBufferSize(final int tdsVersion, final int packetSize) {

        if (packetSize == 0) {
            if (tdsVersion >= Driver.TDS70) {
                return TdsCore.DEFAULT_MIN_PKT_SIZE_TDS70;
            }

            return TdsCore.MIN_PKT_SIZE;
        }

        return packetSize;
    }
}
