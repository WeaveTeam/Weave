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
package net.sourceforge.jtds.jdbc;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

/**
 * Represents an SQL data type as required by <code>getTypeInfo()</code>.
 * Provides a suitable natural ordering.
 * <p/>
 * This class probably shouldn't be public, but is required to be so by the
 * tests.
 *
 * @author David Eaves
 * @version $Id: TypeInfo.java,v 1.5 2005-07-27 11:02:34 alin_sinpalean Exp $
 */
public class TypeInfo implements Comparable {
    static final int NUM_COLS = 18;

    private final String typeName;
    private final int dataType;
    private final int precision;
    private final String literalPrefix;
    private final String literalSuffix;
    private final String createParams;
    private final short nullable;
    private final boolean caseSensitive;
    private final short searchable;
    private final boolean unsigned;
    private final boolean fixedPrecScale;
    private final boolean autoIncrement;
    private final String localTypeName;
    private final short minimumScale;
    private final short maximumScale;
    private final int sqlDataType;
    private final int sqlDatetimeSub;
    private final int numPrecRadix;

    private final int normalizedType;
    private final int distanceFromJdbcType;

    public TypeInfo(ResultSet rs, boolean useLOBs) throws SQLException {
        typeName = rs.getString(1);
        dataType = rs.getInt(2);
        precision = rs.getInt(3);
        literalPrefix = rs.getString(4);
        literalSuffix = rs.getString(5);
        createParams = rs.getString(6);
        nullable = rs.getShort(7);
        caseSensitive = rs.getBoolean(8);
        searchable = rs.getShort(9);
        unsigned = rs.getBoolean(10);
        fixedPrecScale = rs.getBoolean(11);
        autoIncrement = rs.getBoolean(12);
        localTypeName = rs.getString(13);
        if (rs.getMetaData().getColumnCount() >= 18) {
            // Some servers provide more information
            minimumScale = rs.getShort(14);
            maximumScale = rs.getShort(15);
            sqlDataType = rs.getInt(16);
            sqlDatetimeSub = rs.getInt(17);
            numPrecRadix = rs.getInt(18);
        } else {
            // Must initialize final fields
            minimumScale = 0;
            maximumScale = 0;
            sqlDataType = 0;
            sqlDatetimeSub = 0;
            numPrecRadix = 0;
        }
        normalizedType = normalizeDataType(dataType, useLOBs);
        distanceFromJdbcType = determineDistanceFromJdbcType();
    }

    /**
     * For testing only. Create an instance with just the properties utilised
     * in the <code>compareTo()</code> method (set name, type, and auto
     * increment).
     */
    public TypeInfo(String typeName, int dataType, boolean autoIncrement) {
        this.typeName = typeName;
        this.dataType = dataType;
        this.autoIncrement = autoIncrement;
        this.precision = 0;
        this.literalPrefix = null;
        this.literalSuffix = null;
        this.createParams = null;
        this.nullable = 0;
        this.caseSensitive = false;
        this.searchable = 0;
        this.unsigned = false;
        this.fixedPrecScale = false;
        this.localTypeName = null;
        this.minimumScale = 0;
        this.maximumScale = 0;
        this.sqlDataType = 0;
        this.sqlDatetimeSub = 0;
        this.numPrecRadix = 0;

        normalizedType = normalizeDataType(dataType, true);
        distanceFromJdbcType = determineDistanceFromJdbcType();
    }

    public boolean equals(Object o) {
        if (o instanceof TypeInfo) {
            return compareTo(o) == 0;
        }

        return false;
    }

    public int hashCode() {
        return normalizedType * dataType * (autoIncrement ? 7 : 11);
    }

    public String toString() {
        return typeName + " ("
                + (dataType != normalizedType ? dataType + "->" : "")
                + normalizedType + ')';
    }

    public void update(ResultSet rs) throws SQLException {
        rs.updateString(1, typeName);
        rs.updateInt(2, normalizedType);
        rs.updateInt(3, precision);
        rs.updateString(4, literalPrefix);
        rs.updateString(5, literalSuffix);
        rs.updateString(6, createParams);
        rs.updateShort(7, nullable);
        rs.updateBoolean(8, caseSensitive);
        rs.updateShort(9, searchable);
        rs.updateBoolean(10, unsigned);
        rs.updateBoolean(11, fixedPrecScale);
        rs.updateBoolean(12, autoIncrement);
        rs.updateString(13, localTypeName);
        if (rs.getMetaData().getColumnCount() >= 18) {
            // Some servers provide more information
            rs.updateShort(14, minimumScale);
            rs.updateShort(15, maximumScale);
            rs.updateInt(16, sqlDataType);
            rs.updateInt(17, sqlDatetimeSub);
            rs.updateInt(18, numPrecRadix);
        }
    }

    /**
     * Comparable implementation that orders by dataType, then by how closely
     * the data type maps to the corresponding JDBC SQL type.
     * <p/>
     * The data type values for the non-standard SQL Server types tend to have
     * negative numbers while the corresponding standard types have positive
     * numbers so utilise that in the sorting.
     */
    public int compareTo(Object o) {
        TypeInfo other = ((TypeInfo) o);

        // Order by normalised type, then proximity to standard JDBC type.
        return compare(normalizedType, other.normalizedType) * 10 +
                compare(distanceFromJdbcType, other.distanceFromJdbcType);
    }

    private int compare(int i1, int i2) {
        return i1 < i2 ? -1 : (i1 == i2 ? 0 : 1);
    }

    /**
     * Determine how close this type is to the corresponding JDBC type. Used in
     * sorting to distinguish between types that have the same
     * <code>normalizedType</code> value.
     *
     * @return positive integer indicating how far away the type is from the
     *         corresponding JDBC type, with zero being the nearest possible
     *         match and 9 being the least
     */
    private int determineDistanceFromJdbcType() {
        // TODO: Are these assumptions correct/complete?
        switch (dataType) {
            // Cases without an un-normalized alternative, so these are the
            // best available
            case 11: // Sybase DATETIME
            case 10: // Sybase TIME
            case 9: // Sybase DATE
            case 6: // FLOAT
                return 0;
            case 12: // VARCHAR, SYSNAME and NVARCHAR all together with Sybase
                if (typeName.equalsIgnoreCase("varchar")) {
                    return 0;
                }
                if (typeName.equalsIgnoreCase("nvarchar")) {
                    return 1;
                }
                return 2;
            // Special case as the same data type value is used for SYSNAME and
            // NVARCHAR (SYSNAME is essentially an alias for NVARCHAR). We
            // don't want applications preferring SYSNAME.
            case -9: // SYSNAME / NVARCHAR
                return typeName.equalsIgnoreCase("sysname") ? 4 : 3;

            // Particularly non-standard types
            case -11: // UNIQUEIDENTIFIER
                return 9;
            case -150: // SQL_VARIANT
                return 8;

            // Default behaviour is to assume that if type has not been
            // normalised it is the closest available match, unless it is an
            // auto incrementing type
            default:
                return (dataType == normalizedType && !autoIncrement) ? 0 : 5;
        }
    }

    /**
     * Return a {@link java.sql.Types}-defined type for an SQL Server specific data type.
     *
     * @param serverDataType the data type, as returned by the server
     * @param useLOBs        whether LOB data types are used for large types
     * @return the equivalent data type defined by <code>java.sql.Types</code>
     */
    public static int normalizeDataType(int serverDataType, boolean useLOBs) {
        switch (serverDataType) {
            case 35: // Sybase UNIVARCHAR
                return Types.VARCHAR;
            case 11: // Sybase DATETIME
                return Types.TIMESTAMP;
            case 10: // Sybase TIME
                return Types.TIME;
            case 9: // Sybase DATE
                return Types.DATE;
            case 6: // FLOAT
                return Types.DOUBLE;
            case -1: // LONGVARCHAR
                return useLOBs ? Types.CLOB : Types.LONGVARCHAR;
            case -4: // LONGVARBINARY
                return useLOBs ? Types.BLOB : Types.LONGVARBINARY;
            case -8: // NCHAR
                return Types.CHAR;
            case -9: // SYSNAME / NVARCHAR
                return Types.VARCHAR;
            case -10: // NTEXT
                return useLOBs ? Types.CLOB : Types.LONGVARCHAR;
            case -11: // UNIQUEIDENTIFIER
                return Types.CHAR;
            case -150: // SQL_VARIANT
                return Types.VARCHAR;
            default:
                return serverDataType;
        }
    }
}
