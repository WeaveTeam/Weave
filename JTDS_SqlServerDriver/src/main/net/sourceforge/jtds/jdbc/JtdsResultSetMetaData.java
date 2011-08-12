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

import java.sql.ResultSetMetaData;
import java.sql.SQLException;

/**
 * jTDS implementation of the java.sql.ResultSetMetaData interface.
 * <p>
 * Implementation notes:
 * <ol>
 * <li>New simple implementation required by the new column info structure.
 * <li>Unlike the equivalent in the older jTDS, this version is generic and does
 *     not need to know details of the TDS protocol.
 * </ol>
 *
 * @author Mike Hutchinson
 * @version $Id: JtdsResultSetMetaData.java,v 1.9.2.3 2009-12-30 08:45:34 ickzon Exp $
 */
public class JtdsResultSetMetaData implements ResultSetMetaData {
    private final ColInfo[] columns;
    private final int columnCount;
    private final boolean useLOBs;

    /**
     * Construct ResultSetMetaData object over the current ColInfo array.
     *
     * @param columns The current ColInfo row descriptor array.
     * @param columnCount The number of visible columns.
     */
    JtdsResultSetMetaData(ColInfo[] columns, int columnCount, boolean useLOBs) {
        this.columns = columns;
        this.columnCount = columnCount;
        this.useLOBs = useLOBs;
    }

    /**
     * Return the column descriptor given a column index.
     *
     * @param column The column index (from 1 .. n).
     * @return The column descriptor as a <code>ColInfo<code>.
     * @throws SQLException
     */
    ColInfo getColumn(int column) throws SQLException {
        if (column < 1 || column > columnCount) {
            throw new SQLException(
                    Messages.get("error.resultset.colindex",
                            Integer.toString(column)), "07009");
        }

        return columns[column - 1];
    }

// ------  java.sql.ResultSetMetaData methods follow -------

    public int getColumnCount() throws SQLException {
        return this.columnCount;
    }

    public int getColumnDisplaySize(int column) throws SQLException {
        return getColumn(column).displaySize;
    }

    public int getColumnType(int column) throws SQLException {
        if (useLOBs) {
            return getColumn(column).jdbcType;
        } else {
            return Support.convertLOBType(getColumn(column).jdbcType);
        }
    }

    public int getPrecision(int column) throws SQLException {
        return getColumn(column).precision;
    }

    public int getScale(int column) throws SQLException {
        return getColumn(column).scale;
    }

    public int isNullable(int column) throws SQLException {
        return getColumn(column).nullable;
    }

    public boolean isAutoIncrement(int column) throws SQLException {
        return getColumn(column).isIdentity;
    }

    public boolean isCaseSensitive(int column) throws SQLException {
        return getColumn(column).isCaseSensitive;
    }

    public boolean isCurrency(int column) throws SQLException {
        return TdsData.isCurrency(getColumn(column));
    }

    public boolean isDefinitelyWritable(int column) throws SQLException {
        getColumn(column);

        return false;
    }

    public boolean isReadOnly(int column) throws SQLException {
        return !getColumn(column).isWriteable;
    }

    public boolean isSearchable(int column) throws SQLException {
        return TdsData.isSearchable(getColumn(column));
    }

    public boolean isSigned(int column) throws SQLException {
        return TdsData.isSigned(getColumn(column));
    }

    public boolean isWritable(int column) throws SQLException {
        return getColumn(column).isWriteable;
    }

    public String getCatalogName(int column) throws SQLException {
        ColInfo col = getColumn(column);

        return (col.catalog == null) ? "" : col.catalog;
    }

    public String getColumnClassName(int column) throws SQLException {
        String c = Support.getClassName(getColumnType(column));
        
        if (!useLOBs) {
            if ("java.sql.Clob".equals(c)) {
                return "java.lang.String";
            }
            
            if ("java.sql.Blob".equals(c)) {
                return "[B";
            }
        }
        
        return c;
    }

    public String getColumnLabel(int column) throws SQLException {
        return getColumn(column).name;
    }

    public String getColumnName(int column) throws SQLException {
        return getColumn(column).name;
    }

    public String getColumnTypeName(int column) throws SQLException {
        return getColumn(column).sqlType;
    }

    public String getSchemaName(int column) throws SQLException {
        ColInfo col = getColumn(column);

        return (col.schema == null) ? "" : col.schema;
    }

    public String getTableName(int column) throws SQLException {
        ColInfo col = getColumn(column);

        return (col.tableName == null) ? "" : col.tableName;
    }

    /////// JDBC4 demarcation, do NOT put any JDBC3 code below this line ///////

    /* (non-Javadoc)
     * @see java.sql.Wrapper#isWrapperFor(java.lang.Class)
     */
    public boolean isWrapperFor(Class arg0) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Wrapper#unwrap(java.lang.Class)
     */
    public Object unwrap(Class arg0) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

}