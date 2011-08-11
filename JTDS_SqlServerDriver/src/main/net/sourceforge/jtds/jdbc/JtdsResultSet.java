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

import java.io.InputStream;
import java.io.Reader;
import java.math.BigDecimal;
import java.net.URL;
import java.net.MalformedURLException;
import java.sql.*;
import java.util.Calendar;
import java.util.HashMap;
import java.util.Map;
import java.util.ArrayList;
import java.text.NumberFormat;
import java.io.UnsupportedEncodingException;
import java.io.InputStreamReader;

/**
 * jTDS Implementation of the java.sql.ResultSet interface supporting forward read
 * only result sets.
 * <p>
 * Implementation notes:
 * <ol>
 * <li>This class is also the base for more sophisticated result sets and
 * incorporates the update methods required by them.
 * <li>The class supports the BLOB/CLOB objects added by Brian.
 * </ol>
 *
 * @author Mike Hutchinson
 * @version $Id: JtdsResultSet.java,v 1.46.2.5 2009-12-30 11:37:21 ickzon Exp $
 */
public class JtdsResultSet implements ResultSet {
    /*
     * Constants for backwards compatibility with JDK 1.3
     */
    static final int HOLD_CURSORS_OVER_COMMIT = 1;
    static final int CLOSE_CURSORS_AT_COMMIT = 2;

    protected static final int POS_BEFORE_FIRST = 0;
    protected static final int POS_AFTER_LAST = -1;

    /** Initial size for row array. */
    protected static final int INITIAL_ROW_COUNT = 1000;

    /*
     * Protected Instance variables.
     */
    /** The current row number. */
    protected int pos = POS_BEFORE_FIRST;
    /** The number of rows in the result. */
    protected int rowsInResult;
    /** The fetch direction. */
    protected int direction = FETCH_FORWARD;
    /** The result set type. */
    protected int resultSetType;
    /** The result set concurrency. */
    protected int concurrency;
    /** Number of visible columns in row. */
    protected int columnCount;
    /** The array of column descriptors. */
    protected ColInfo[] columns;
    /** The current result set row. */
    protected Object[] currentRow;
    /** Cached row data for forward only result set. */
    protected ArrayList rowData;
    /** Index of current row in rowData. */
    protected int rowPtr;
    /** True if last column retrieved was null. */
    protected boolean wasNull;
    /** The parent statement. */
    protected JtdsStatement statement;
    /** True if this result set is closed. */
    protected boolean closed;
    /** True if the query has been cancelled by another thread. */
    protected boolean cancelled;
    /** The fetch direction. */
    protected int fetchDirection = FETCH_FORWARD;
    /** The fetch size (only applies to cursor <code>ResultSet</code>s). */
    protected int fetchSize;
    /** The cursor name to be used for positioned updates. */
    protected String cursorName;
    /** Cache to optimize findColumn(String) lookups */
    private HashMap columnMap;

    /*
     * Private instance variables.
     */
    /** Used to format numeric values when scale is specified. */
    private static NumberFormat f = NumberFormat.getInstance();

    /**
     * Construct a simple result set from a statement, metadata or generated keys.
     *
     * @param statement The parent statement object or null.
     * @param resultSetType one of FORWARD_ONLY, SCROLL_INSENSITIVE, SCROLL_SENSITIVE.
     * @param concurrency One of CONCUR_READ_ONLY, CONCUR_UPDATE.
     * @param columns The array of column descriptors for the result set row.
     * @throws SQLException
     */
    JtdsResultSet(JtdsStatement statement,
                  int resultSetType,
                  int concurrency,
                  ColInfo[] columns)
        throws SQLException {
        if (statement == null) {
            throw new IllegalArgumentException("Statement parameter must not be null");
        }
        this.statement = statement;
        this.resultSetType = resultSetType;
        this.concurrency = concurrency;
        this.columns = columns;
        this.fetchSize = statement.fetchSize;
        this.fetchDirection = statement.fetchDirection;
        this.cursorName  = statement.cursorName;

        if (columns != null) {
            columnCount  = getColumnCount(columns);
            rowsInResult = (statement.getTds().isDataInResultSet()) ? 1 : 0;
        }
    }

    /**
     * Retrieve the column count excluding hidden columns
     *
     * @param columns The columns array
     * @return The new column count as an <code>int</code>.
     */
    protected static int getColumnCount(ColInfo[] columns) {
        // MJH - Modified to cope with more than one hidden column
        int i;
        for (i = columns.length - 1; i >= 0 && columns[i].isHidden; i--);
        return i + 1;
    }

    /**
     * Retrieve the column descriptor array.
     *
     * @return The column descriptors as a <code>ColInfo[]</code>.
     */
    protected ColInfo[] getColumns() {
        return this.columns;
    }

    /**
     * Set the specified column's name.
     *
     * @param colIndex The index of the column in the row.
     * @param name The new name.
     */
    protected void setColName(int colIndex, String name) {
        if (colIndex < 1 || colIndex > columns.length) {
            throw new IllegalArgumentException("columnIndex "
                    + colIndex + " invalid");
        }

        columns[colIndex - 1].realName = name;
    }

    /**
     * Set the specified column's label.
     *
     * @param colIndex The index of the column in the row.
     * @param name The new label.
     */
    protected void setColLabel(int colIndex, String name) {
        if (colIndex < 1 || colIndex > columns.length) {
            throw new IllegalArgumentException("columnIndex "
                    + colIndex + " invalid");
        }

        columns[colIndex - 1].name = name;
    }

    /**
     * Set the specified column's JDBC type.
     *
     * @param colIndex The index of the column in the row.
     * @param jdbcType The new type value.
     */
    protected void setColType(int colIndex, int jdbcType) {
        if (colIndex < 1 || colIndex > columns.length) {
            throw new IllegalArgumentException("columnIndex "
                    + colIndex + " invalid");
        }

        columns[colIndex - 1].jdbcType = jdbcType;
    }

    /**
     * Set the specified column's data value.
     *
     * @param colIndex index of the column
     * @param value    new column value
     * @param length   the length of a stream parameter
     * @return the value, possibly converted to an internal type
     */
    protected Object setColValue(int colIndex, int jdbcType, Object value, int length)
        throws SQLException {
        checkOpen();
        checkUpdateable();
        if (colIndex < 1 || colIndex > columnCount) {
            throw new SQLException(Messages.get("error.resultset.colindex",
                    Integer.toString(colIndex)),
                    "07009");
        }
        //
        // Convert java date/time objects to internal DateTime objects
        //
        if (value instanceof java.sql.Timestamp) {
            value = new DateTime((java.sql.Timestamp) value);
        } else if (value instanceof java.sql.Date) {
            value = new DateTime((java.sql.Date) value);
        } else if (value instanceof java.sql.Time) {
            value = new DateTime((java.sql.Time) value);
        }

        return value;
    }

    /**
     * Set the current row's column count.
     *
     * @param columnCount The number of visible columns in the row.
     */
    protected void setColumnCount(int columnCount) {
        if (columnCount < 1 || columnCount > columns.length) {
            throw new IllegalArgumentException("columnCount "
                    + columnCount + " is invalid");
        }

        this.columnCount = columnCount;
    }

    /**
     * Get the specified column's data item.
     *
     * @param index the column index in the row
     * @return the column value as an <code>Object</code>
     * @throws SQLException if the connection is closed;
     *         if <code>index</code> is less than <code>1</code>;
     *         if <code>index</code> is greater that the number of columns;
     *         if there is no current row
     */
    protected Object getColumn(int index) throws SQLException {
        checkOpen();

        if (index < 1 || index > columnCount) {
            throw new SQLException(Messages.get("error.resultset.colindex",
                                                      Integer.toString(index)),
                                                       "07009");
        }

        if (currentRow == null) {
            throw new SQLException(Messages.get("error.resultset.norow"), "24000");
        }

        Object data = currentRow[index - 1];

        wasNull = data == null;

        return data;
    }

    /**
     * Check that this connection is still open.
     *
     * @throws SQLException if connection closed.
     */
    protected void checkOpen() throws SQLException {
        if (closed) {
            throw new SQLException(Messages.get("error.generic.closed", "ResultSet"),
                                        "HY010");
        }

        if (cancelled) {
            throw new SQLException(Messages.get("error.generic.cancelled", "ResultSet"),
                                        "HY010");
        }
    }

    /**
     * Check that this resultset is scrollable.
     *
     * @throws SQLException if connection closed.
     */
    protected void checkScrollable() throws SQLException {
        if (resultSetType == ResultSet.TYPE_FORWARD_ONLY) {
            throw new SQLException(Messages.get("error.resultset.fwdonly"), "24000");
        }
    }

    /**
     * Check that this resultset is updateable.
     *
     * @throws SQLException if connection closed.
     */
    protected void checkUpdateable() throws SQLException {
        if (concurrency == ResultSet.CONCUR_READ_ONLY) {
            throw new SQLException(Messages.get("error.resultset.readonly"), "24000");
        }
    }

    /**
     * Report that user tried to call a method which has not been implemented.
     *
     * @param method The method name to report in the error message.
     * @throws SQLException
     */
    protected static void notImplemented(String method) throws SQLException {
        throw new SQLException(Messages.get("error.generic.notimp", method), "HYC00");
    }

    /**
     * Create a new row containing empty data items.
     *
     * @return the new row as an <code>Object</code> array
     */
    protected Object[] newRow() {
        Object row[] = new Object[columns.length];

        return row;
    }

    /**
     * Copy an existing result set row.
     *
     * @param row the result set row to copy
     * @return the new row as an <code>Object</code> array
     */
    protected Object[] copyRow(Object[] row) {
        Object copy[] = new Object[columns.length];

        System.arraycopy(row, 0, copy, 0, row.length);

        return copy;
    }

    /**
     * Copy an existing result set column descriptor array.
     *
     * @param info The result set column descriptors to copy.
     * @return The new descriptors as a <code>ColInfo[]</code>.
     */
    protected ColInfo[] copyInfo(ColInfo[] info) {
        ColInfo copy[] = new ColInfo[info.length];

        System.arraycopy(info, 0, copy, 0, info.length);

        return copy;
    }

    /**
     * Retrieve the current row data.
     * @return The current row data as an <code>Object[]</code>.
     */
    protected Object[] getCurrentRow()
    {
        return this.currentRow;
    }

    /**
     * Cache the remaining results to free up connection.
     * @throws SQLException
     */
    protected void cacheResultSetRows() throws SQLException {
        if (rowData == null) {
            rowData = new ArrayList(INITIAL_ROW_COUNT);
        }
        if (currentRow != null) {
            // Need to create local copy of currentRow
            // as this is currently a reference to the
            // row defined in TdsCore
            currentRow = copyRow(currentRow);
        }
        //
        // Now load the remaining result set rows into memory
        //
        while (statement.getTds().getNextRow()) {
            rowData.add(copyRow(statement.getTds().getRowData()));
        }
        // Allow statement to process output vars etc
        statement.cacheResults();
    }

    /**
     * Returns the {@link ConnectionJDBC2} object referenced by the
     * {@link #statement} instance variable.
     *
     * @return {@link ConnectionJDBC2} object.
     * @throws SQLException on error.
     */
    private ConnectionJDBC2 getConnection() throws SQLException {
        return (ConnectionJDBC2) statement.getConnection();
    }


//
// -------------------- java.sql.ResultSet methods -------------------
//
    public int getConcurrency() throws SQLException {
        checkOpen();

        return this.concurrency;
    }

    public int getFetchDirection() throws SQLException {
        checkOpen();

        return this.fetchDirection;
    }

    public int getFetchSize() throws SQLException {
        checkOpen();

        return fetchSize;
    }

    public int getRow() throws SQLException {
        checkOpen();

        return pos > 0 ? pos : 0;
    }

    public int getType() throws SQLException {
        checkOpen();

        return resultSetType;
    }

    public void afterLast() throws SQLException {
        checkOpen();
        checkScrollable();
    }

    public void beforeFirst() throws SQLException {
        checkOpen();
        checkScrollable();
    }

    public void cancelRowUpdates() throws SQLException {
        checkOpen();
        checkUpdateable();
    }

    public void clearWarnings() throws SQLException {
        checkOpen();

        statement.clearWarnings();
    }

    public void close() throws SQLException {
        if (!closed) {
            try {
                if (!getConnection().isClosed()) {
                   // Skip to end of result set
                   // Could send cancel but this is safer as
                   // cancel could kill other statements in a batch.
                   while (next());
                }
            } finally {
                closed = true;
                statement = null;
            }
        }
    }

    public void deleteRow() throws SQLException {
        checkOpen();
        checkUpdateable();
    }

    public void insertRow() throws SQLException {
        checkOpen();
        checkUpdateable();
    }

    public void moveToCurrentRow() throws SQLException {
        checkOpen();
        checkUpdateable();
    }


    public void moveToInsertRow() throws SQLException {
        checkOpen();
        checkUpdateable();
    }

    public void refreshRow() throws SQLException {
        checkOpen();
        checkUpdateable();
    }

    public void updateRow() throws SQLException {
        checkOpen();
        checkUpdateable();
    }

    public boolean first() throws SQLException {
        checkOpen();
        checkScrollable();

        return false;
    }

    public boolean isAfterLast() throws SQLException {
        checkOpen();

        return (pos == POS_AFTER_LAST) && (rowsInResult != 0);
    }

    public boolean isBeforeFirst() throws SQLException {
        checkOpen();

        return (pos == POS_BEFORE_FIRST) && (rowsInResult != 0);
    }

    public boolean isFirst() throws SQLException {
        checkOpen();

        return pos == 1;
    }

    public boolean isLast() throws SQLException {
        checkOpen();

        if (statement.getTds().isDataInResultSet()) {
            rowsInResult = pos + 1; // Keep rowsInResult 1 ahead of pos
        }

        return (pos == rowsInResult) && (rowsInResult != 0);
    }

    public boolean last() throws SQLException {
        checkOpen();
        checkScrollable();

        return false;
    }

    public boolean next() throws SQLException {
        checkOpen();

        if (pos == POS_AFTER_LAST) {
            // Make sure nothing will happen after the end has been reached
            return false;
        }

        if (rowData != null) {
            // The rest of the result rows have been cached so
            // return the next row from the buffer.
            if (rowPtr < rowData.size()) {
                currentRow = (Object[])rowData.get(rowPtr);
                // This is a forward only result set so null out the buffer ref
                // to allow for garbage collection (we can never access the row
                // again once we have moved on).
                rowData.set(rowPtr++, null);
                pos++;
                rowsInResult = pos;
            } else {
                pos = POS_AFTER_LAST;
                currentRow = null;
            }
        } else {
            // Need to read from server response
            if (!statement.getTds().getNextRow()) {
                statement.cacheResults();
                pos = POS_AFTER_LAST;
                currentRow = null;
            } else {
                currentRow = statement.getTds().getRowData();
                pos++;
                rowsInResult = pos;
            }
        }

        // Check for server side errors
        statement.getMessages().checkErrors();

        return currentRow != null;
    }

    public boolean previous() throws SQLException {
        checkOpen();
        checkScrollable();

        return false;
    }

    public boolean rowDeleted() throws SQLException {
        checkOpen();
        checkUpdateable();

        return false;
    }

    public boolean rowInserted() throws SQLException {
        checkOpen();
        checkUpdateable();

        return false;
    }

    public boolean rowUpdated() throws SQLException {
        checkOpen();
        checkUpdateable();

        return false;
    }

    public boolean wasNull() throws SQLException {
        checkOpen();

        return wasNull;
    }

    public byte getByte(int columnIndex) throws SQLException {
        return ((Integer) Support.convert(this, getColumn(columnIndex), java.sql.Types.TINYINT, null)).byteValue();
    }

    public short getShort(int columnIndex) throws SQLException {
        return ((Integer) Support.convert(this, getColumn(columnIndex), java.sql.Types.SMALLINT, null)).shortValue();
    }

    public int getInt(int columnIndex) throws SQLException {
        return ((Integer) Support.convert(this, getColumn(columnIndex), java.sql.Types.INTEGER, null)).intValue();
    }

    public long getLong(int columnIndex) throws SQLException {
        return ((Long) Support.convert(this, getColumn(columnIndex), java.sql.Types.BIGINT, null)).longValue();
    }

    public float getFloat(int columnIndex) throws SQLException {
        return ((Float) Support.convert(this, getColumn(columnIndex), java.sql.Types.REAL, null)).floatValue();
    }

    public double getDouble(int columnIndex) throws SQLException {
        return ((Double) Support.convert(this, getColumn(columnIndex), java.sql.Types.DOUBLE, null)).doubleValue();
    }

    public void setFetchDirection(int direction) throws SQLException {
        checkOpen();
        switch (direction) {
        case FETCH_UNKNOWN:
        case FETCH_REVERSE:
            if (this.resultSetType == ResultSet.TYPE_FORWARD_ONLY) {
                throw new SQLException(Messages.get("error.resultset.fwdonly"), "24000");
            }
            // Fall through

        case FETCH_FORWARD:
            this.fetchDirection = direction;
            break;

        default:
            throw new SQLException(
                    Messages.get("error.generic.badoption",
                            Integer.toString(direction),
                            "direction"),
                    "24000");
        }
    }

    public void setFetchSize(int rows) throws SQLException {
        checkOpen();

        if (rows < 0 || (statement.getMaxRows() > 0 && rows > statement.getMaxRows())) {
            throw new SQLException(
                    Messages.get("error.generic.badparam",
                            Integer.toString(rows),
                            "rows"),
                    "HY092");
        }
        if (rows == 0) {
            rows = statement.getDefaultFetchSize();
        }
        this.fetchSize = rows;
    }

    public void updateNull(int columnIndex) throws SQLException {
        setColValue(columnIndex, Types.NULL, null, 0);
    }

    public boolean absolute(int row) throws SQLException {
        checkOpen();
        checkScrollable();
        return false;
    }

    public boolean getBoolean(int columnIndex) throws SQLException {
        return ((Boolean) Support.convert(this, getColumn(columnIndex), JtdsStatement.BOOLEAN, null)).booleanValue();
    }

    public boolean relative(int row) throws SQLException {
        checkOpen();
        checkScrollable();
        return false;
    }

    public byte[] getBytes(int columnIndex) throws SQLException {
        checkOpen();
        return (byte[]) Support.convert(this, getColumn(columnIndex), java.sql.Types.BINARY, getConnection().getCharset());
    }

    public void updateByte(int columnIndex, byte x) throws SQLException {
        setColValue(columnIndex, Types.INTEGER, new Integer(x & 0xFF), 0);
    }

    public void updateDouble(int columnIndex, double x) throws SQLException {
        setColValue(columnIndex, Types.DOUBLE, new Double(x), 0);
    }

    public void updateFloat(int columnIndex, float x) throws SQLException {
        setColValue(columnIndex, Types.REAL, new Float(x), 0);
    }

    public void updateInt(int columnIndex, int x) throws SQLException {
        setColValue(columnIndex, Types.INTEGER, new Integer(x), 0);
    }

    public void updateLong(int columnIndex, long x) throws SQLException {
        setColValue(columnIndex, Types.BIGINT, new Long(x), 0);
    }

    public void updateShort(int columnIndex, short x) throws SQLException {
        setColValue(columnIndex, Types.INTEGER, new Integer(x), 0);
    }

    public void updateBoolean(int columnIndex, boolean x) throws SQLException {
        setColValue(columnIndex, Types.BIT, x ? Boolean.TRUE : Boolean.FALSE, 0);
    }

    public void updateBytes(int columnIndex, byte[] x) throws SQLException {
        setColValue(columnIndex, Types.VARBINARY, x, (x != null)? x.length: 0);
    }

    public InputStream getAsciiStream(int columnIndex) throws SQLException {
        Clob clob = getClob(columnIndex);

        if (clob == null) {
            return null;
        }

        return clob.getAsciiStream();
    }

    public InputStream getBinaryStream(int columnIndex) throws SQLException {
        Blob blob = getBlob(columnIndex);

        if (blob == null) {
            return null;
        }

        return blob.getBinaryStream();
    }

    public InputStream getUnicodeStream(int columnIndex) throws SQLException {
        ClobImpl clob = (ClobImpl) getClob(columnIndex);

        if (clob == null) {
            return null;
        }

        return clob.getBlobBuffer().getUnicodeStream();
    }

    public void updateAsciiStream(int columnIndex, InputStream inputStream, int length)
        throws SQLException {
        if (inputStream == null || length < 0) {
             updateCharacterStream(columnIndex, null, 0);
        } else {
            try {
                updateCharacterStream(columnIndex, new InputStreamReader(inputStream, "US-ASCII"), length);
            } catch (UnsupportedEncodingException e) {
                // Should never happen!
            }
         }
    }

    public void updateBinaryStream(int columnIndex, InputStream inputStream, int length)
        throws SQLException {

        if (inputStream == null || length < 0) {
            updateBytes(columnIndex, null);
            return;
        }

        setColValue(columnIndex, java.sql.Types.VARBINARY, inputStream, length);
    }

    public Reader getCharacterStream(int columnIndex) throws SQLException {
        Clob clob = getClob(columnIndex);

        if (clob == null) {
            return null;
        }

        return clob.getCharacterStream();
    }

    public void updateCharacterStream(int columnIndex, Reader reader, int length)
        throws SQLException {

        if (reader == null || length < 0) {
            updateString(columnIndex, null);
            return;
        }

        setColValue(columnIndex, java.sql.Types.VARCHAR, reader, length);
    }

    public Object getObject(int columnIndex) throws SQLException {
        Object value = getColumn(columnIndex);

        // Don't return UniqueIdentifier objects as the user won't know how to
        // handle them
        if (value instanceof UniqueIdentifier) {
            return value.toString();
        }
        // Don't return DateTime objects as the user won't know how to
        // handle them
        if (value instanceof DateTime) {
            return ((DateTime) value).toObject();
        }
        // If the user requested String/byte[] instead of LOBs, do the conversion
        if (!getConnection().getUseLOBs()) {
            value = Support.convertLOB(value);
        }

        return value;
    }

    public void updateObject(int columnIndex, Object x) throws SQLException {
        checkOpen();
        int length = 0;
        int jdbcType = Types.VARCHAR; // Use for NULL values

        if (x != null) {
            // Need to do some conversion and testing here
            jdbcType = Support.getJdbcType(x);
            if (x instanceof BigDecimal) {
                int prec = getConnection().getMaxPrecision();
                x = Support.normalizeBigDecimal((BigDecimal)x, prec);
            } else if (x instanceof Blob) {
                Blob blob = (Blob) x;
                x = blob.getBinaryStream();
                length = (int) blob.length();
            } else if (x instanceof Clob) {
                Clob clob = (Clob) x;
                x = clob.getCharacterStream();
                length = (int) clob.length();
            } else if (x instanceof String) {
                length = ((String)x).length();
            } else if (x instanceof byte[]) {
                length = ((byte[])x).length;
            }
            if (jdbcType == Types.JAVA_OBJECT) {
                // Unsupported class of object
                if (columnIndex < 1 || columnIndex > columnCount) {
                    throw new SQLException(Messages.get("error.resultset.colindex",
                            Integer.toString(columnIndex)),
                            "07009");
                }
                ColInfo ci = columns[columnIndex-1];
                throw new SQLException(
                        Messages.get("error.convert.badtypes",
                                x.getClass().getName(),
                                Support.getJdbcTypeName(ci.jdbcType)), "22005");
            }
        }

        setColValue(columnIndex, jdbcType, x, length);
    }

    public void updateObject(int columnIndex, Object x, int scale) throws SQLException {
        checkOpen();
        if (scale < 0 || scale > getConnection().getMaxPrecision()) {
            throw new SQLException(Messages.get("error.generic.badscale"), "HY092");
        }

        if (x instanceof BigDecimal) {
            updateObject(columnIndex, ((BigDecimal) x).setScale(scale, BigDecimal.ROUND_HALF_UP));
        } else if (x instanceof Number) {
            synchronized (f) {
                f.setGroupingUsed(false);
                f.setMaximumFractionDigits(scale);
                updateObject(columnIndex, f.format(x));
            }
        } else {
            updateObject(columnIndex, x);
        }
    }

    public String getCursorName() throws SQLException {
        checkOpen();
        if (cursorName != null) {
            return this.cursorName;
        }
        throw new SQLException(Messages.get("error.resultset.noposupdate"), "24000");
    }

    public String getString(int columnIndex) throws SQLException {
        Object tmp = getColumn(columnIndex);

        if (tmp instanceof String) {
            return (String) tmp;
        }
        return (String) Support.convert(this, tmp, java.sql.Types.VARCHAR, getConnection().getCharset());
    }

    public void updateString(int columnIndex, String x) throws SQLException {
        setColValue(columnIndex, Types.VARCHAR, x , (x != null)? x.length(): 0);
    }

    public byte getByte(String columnName) throws SQLException {
        return getByte(findColumn(columnName));
    }

    public double getDouble(String columnName) throws SQLException {
        return getDouble(findColumn(columnName));
    }

    public float getFloat(String columnName) throws SQLException {
        return getFloat(findColumn(columnName));
    }

    public int findColumn(String columnName) throws SQLException {
        checkOpen();

        if (columnMap == null) {
            columnMap = new HashMap(columnCount);
        } else {
            Object pos = columnMap.get(columnName);
            if (pos != null) {
                return ((Integer) pos).intValue();
            }
        }

        // Rather than use toUpperCase()/toLowerCase(), which are costly,
        // just do a sequential search. It's actually faster in most cases.
        for (int i = 0; i < columnCount; i++) {
            if (columns[i].name.equalsIgnoreCase(columnName)) {
                columnMap.put(columnName, new Integer(i + 1));

                return i + 1;
            }
        }

        throw new SQLException(Messages.get("error.resultset.colname", columnName), "07009");
    }

    public int getInt(String columnName) throws SQLException {
        return getInt(findColumn(columnName));
    }

    public long getLong(String columnName) throws SQLException {
        return getLong(findColumn(columnName));
    }

    public short getShort(String columnName) throws SQLException {
        return getShort(findColumn(columnName));
    }

    public void updateNull(String columnName) throws SQLException {
        updateNull(findColumn(columnName));
    }

    public boolean getBoolean(String columnName) throws SQLException {
        return getBoolean(findColumn(columnName));
    }

    public byte[] getBytes(String columnName) throws SQLException {
        return getBytes(findColumn(columnName));
    }

    public void updateByte(String columnName, byte x) throws SQLException {
        updateByte(findColumn(columnName), x);
    }

    public void updateDouble(String columnName, double x) throws SQLException {
        updateDouble(findColumn(columnName), x);
    }

    public void updateFloat(String columnName, float x) throws SQLException {
        updateFloat(findColumn(columnName), x);
    }

    public void updateInt(String columnName, int x) throws SQLException {
        updateInt(findColumn(columnName), x);
    }

    public void updateLong(String columnName, long x) throws SQLException {
        updateLong(findColumn(columnName), x);
    }

    public void updateShort(String columnName, short x) throws SQLException {
        updateShort(findColumn(columnName), x);
    }

    public void updateBoolean(String columnName, boolean x) throws SQLException {
        updateBoolean(findColumn(columnName), x);
    }

    public void updateBytes(String columnName, byte[] x) throws SQLException {
        updateBytes(findColumn(columnName), x);
    }

    public BigDecimal getBigDecimal(int columnIndex) throws SQLException {
        return (BigDecimal) Support.convert(this, getColumn(columnIndex), java.sql.Types.DECIMAL, null);
    }

    public BigDecimal getBigDecimal(int columnIndex, int scale) throws SQLException {
        BigDecimal result = (BigDecimal) Support.convert(this, getColumn(columnIndex), java.sql.Types.DECIMAL, null);

        if (result == null) {
            return null;
        }

        return result.setScale(scale, BigDecimal.ROUND_HALF_UP);
    }

    public void updateBigDecimal(int columnIndex, BigDecimal x)
        throws SQLException {
        checkOpen();
        checkUpdateable();
        if (x != null) {
            int prec = getConnection().getMaxPrecision();
            x = Support.normalizeBigDecimal(x, prec);
        }
        setColValue(columnIndex, Types.DECIMAL, x, 0);
    }

    public URL getURL(int columnIndex) throws SQLException {
        String url = getString(columnIndex);

        try {
            return new java.net.URL(url);
        } catch (MalformedURLException e) {
            throw new SQLException(Messages.get("error.resultset.badurl", url), "22000");
        }
    }

    public Array getArray(int columnIndex) throws SQLException {
        checkOpen();
        notImplemented("ResultSet.getArray()");
        return null;
    }

    public void updateArray(int columnIndex, Array x) throws SQLException {
        checkOpen();
        checkUpdateable();
        notImplemented("ResultSet.updateArray()");
    }

    public Blob getBlob(int columnIndex) throws SQLException {
        return (Blob) Support.convert(this, getColumn(columnIndex), java.sql.Types.BLOB, null);
    }

    public void updateBlob(int columnIndex, Blob x) throws SQLException {
        if (x == null) {
            updateBinaryStream(columnIndex, null, 0);
        } else {
            updateBinaryStream(columnIndex, x.getBinaryStream(), (int) x.length());
        }
    }

    public Clob getClob(int columnIndex) throws SQLException {
        return (Clob) Support.convert(this, getColumn(columnIndex), java.sql.Types.CLOB, null);
    }

    public void updateClob(int columnIndex, Clob x) throws SQLException {
        if (x == null) {
            updateCharacterStream(columnIndex, null, 0);
        } else {
            updateCharacterStream(columnIndex, x.getCharacterStream(), (int) x.length());
        }
    }

    public Date getDate(int columnIndex) throws SQLException {
        return (java.sql.Date)Support.convert(this, getColumn(columnIndex), java.sql.Types.DATE, null);
    }

    public void updateDate(int columnIndex, Date x) throws SQLException {
        setColValue(columnIndex, Types.DATE, x, 0);
    }

    public Ref getRef(int columnIndex) throws SQLException {
        checkOpen();
        notImplemented("ResultSet.getRef()");

        return null;
    }

    public void updateRef(int columnIndex, Ref x) throws SQLException {
        checkOpen();
        checkUpdateable();
        notImplemented("ResultSet.updateRef()");
    }

    public ResultSetMetaData getMetaData() throws SQLException {
        checkOpen();

        // If this is a DatabaseMetaData built result set, avoid getting an
        // exception because the statement is closed and assume no LOBs
        boolean useLOBs = this instanceof CachedResultSet && statement.closed
                ? false
                : getConnection().getUseLOBs();
        return new JtdsResultSetMetaData(this.columns, this.columnCount,
                useLOBs);
    }

    public SQLWarning getWarnings() throws SQLException {
        checkOpen();

        return statement.getWarnings();
    }

    public Statement getStatement() throws SQLException {
        checkOpen();

        return this.statement;
    }

    public Time getTime(int columnIndex) throws SQLException {
        return (java.sql.Time) Support.convert(this, getColumn(columnIndex), java.sql.Types.TIME, null);
    }

    public void updateTime(int columnIndex, Time x) throws SQLException {
        setColValue(columnIndex, Types.TIME, x, 0);
    }

    public Timestamp getTimestamp(int columnIndex) throws SQLException {
        return (Timestamp) Support.convert(this, getColumn(columnIndex), java.sql.Types.TIMESTAMP, null);
    }

    public void updateTimestamp(int columnIndex, Timestamp x) throws SQLException {
        setColValue(columnIndex, Types.TIMESTAMP, x, 0);
    }

    public InputStream getAsciiStream(String columnName) throws SQLException {
        return getAsciiStream(findColumn(columnName));
    }

    public InputStream getBinaryStream(String columnName) throws SQLException {
        return getBinaryStream(findColumn(columnName));
    }

    public InputStream getUnicodeStream(String columnName) throws SQLException {
        return getUnicodeStream(findColumn(columnName));
    }

    public void updateAsciiStream(String columnName, InputStream x, int length)
        throws SQLException {
        updateAsciiStream(findColumn(columnName), x, length);
    }

    public void updateBinaryStream(String columnName, InputStream x, int length)
        throws SQLException {
        updateBinaryStream(findColumn(columnName), x, length);
    }

    public Reader getCharacterStream(String columnName) throws SQLException {
        return getCharacterStream(findColumn(columnName));
    }

    public void updateCharacterStream(String columnName, Reader x, int length)
        throws SQLException {
        updateCharacterStream(findColumn(columnName), x, length);
    }

    public Object getObject(String columnName) throws SQLException {
        return getObject(findColumn(columnName));
    }

    public void updateObject(String columnName, Object x) throws SQLException {
        updateObject(findColumn(columnName), x);
    }

    public void updateObject(String columnName, Object x, int scale)
        throws SQLException {
        updateObject(findColumn(columnName), x, scale);
    }

    public Object getObject(int columnIndex, Map map) throws SQLException {
        notImplemented("ResultSet.getObject(int, Map)");
        return null;
    }

    public String getString(String columnName) throws SQLException {
        return getString(findColumn(columnName));
    }

    public void updateString(String columnName, String x) throws SQLException {
        updateString(findColumn(columnName), x);
    }

    public BigDecimal getBigDecimal(String columnName) throws SQLException {
        return getBigDecimal(findColumn(columnName));
    }

    public BigDecimal getBigDecimal(String columnName, int scale)
        throws SQLException {
        return getBigDecimal(findColumn(columnName), scale);
    }

    public void updateBigDecimal(String columnName, BigDecimal x)
        throws SQLException {
        updateObject(findColumn(columnName), x);
    }

    public URL getURL(String columnName) throws SQLException {
        return getURL(findColumn(columnName));
    }

    public Array getArray(String columnName) throws SQLException {
        return getArray(findColumn(columnName));
    }

    public void updateArray(String columnName, Array x) throws SQLException {
        updateArray(findColumn(columnName), x);
    }

    public Blob getBlob(String columnName) throws SQLException {
        return getBlob(findColumn(columnName));
    }

    public void updateBlob(String columnName, Blob x) throws SQLException {
        updateBlob(findColumn(columnName), x);
    }

    public Clob getClob(String columnName) throws SQLException {
        return getClob(findColumn(columnName));
    }

    public void updateClob(String columnName, Clob x) throws SQLException {
        updateClob(findColumn(columnName), x);
    }

    public Date getDate(String columnName) throws SQLException {
        return getDate(findColumn(columnName));
    }

    public void updateDate(String columnName, Date x) throws SQLException {
        updateDate(findColumn(columnName), x);
    }

    public Date getDate(int columnIndex, Calendar cal) throws SQLException {
        java.sql.Date date = getDate(columnIndex);

        if (date != null && cal != null) {
            date = new java.sql.Date(Support.timeToZone(date, cal));
        }

        return date;
    }

    public Ref getRef(String columnName) throws SQLException {
        return getRef(findColumn(columnName));
    }

    public void updateRef(String columnName, Ref x) throws SQLException {
        updateRef(findColumn(columnName), x);
    }

    public Time getTime(String columnName) throws SQLException {
        return getTime(findColumn(columnName));
    }

    public void updateTime(String columnName, Time x) throws SQLException {
        updateTime(findColumn(columnName), x);
    }

    public Time getTime(int columnIndex, Calendar cal) throws SQLException {
        checkOpen();
        java.sql.Time time = getTime(columnIndex);

        if (time != null && cal != null) {
            return new Time(Support.timeToZone(time, cal));
        }

        return time;
    }

    public Timestamp getTimestamp(String columnName) throws SQLException {
        return getTimestamp(findColumn(columnName));
    }

    public void updateTimestamp(String columnName, Timestamp x)
        throws SQLException {
        updateTimestamp(findColumn(columnName), x);
    }

    public Timestamp getTimestamp(int columnIndex, Calendar cal)
        throws SQLException {
            checkOpen();
            Timestamp timestamp = getTimestamp(columnIndex);

            if (timestamp != null && cal != null) {
                timestamp = new Timestamp(Support.timeToZone(timestamp, cal));
            }

            return timestamp;
    }

    public Object getObject(String columnName, Map map) throws SQLException {
        return getObject(findColumn(columnName), map);
    }

    public Date getDate(String columnName, Calendar cal) throws SQLException {
        return getDate(findColumn(columnName), cal);
    }

    public Time getTime(String columnName, Calendar cal) throws SQLException {
        return getTime(findColumn(columnName), cal);
    }

    public Timestamp getTimestamp(String columnName, Calendar cal)
        throws SQLException {
        return getTimestamp(findColumn(columnName), cal);
    }

    /////// JDBC4 demarcation, do NOT put any JDBC3 code below this line ///////

    /* (non-Javadoc)
     * @see java.sql.ResultSet#getHoldability()
     */
    public int getHoldability() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#getNCharacterStream(int)
     */
    public Reader getNCharacterStream(int columnIndex) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#getNCharacterStream(java.lang.String)
     */
    public Reader getNCharacterStream(String columnLabel) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#getNClob(int)
     */
    public NClob getNClob(int columnIndex) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#getNClob(java.lang.String)
     */
    public NClob getNClob(String columnLabel) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#getNString(int)
     */
    public String getNString(int columnIndex) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#getNString(java.lang.String)
     */
    public String getNString(String columnLabel) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#getRowId(int)
     */
    public RowId getRowId(int columnIndex) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#getRowId(java.lang.String)
     */
    public RowId getRowId(String columnLabel) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#getSQLXML(int)
     */
    public SQLXML getSQLXML(int columnIndex) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#getSQLXML(java.lang.String)
     */
    public SQLXML getSQLXML(String columnLabel) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#isClosed()
     */
    public boolean isClosed() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateAsciiStream(int, java.io.InputStream)
     */
    public void updateAsciiStream(int columnIndex, InputStream x)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateAsciiStream(java.lang.String, java.io.InputStream)
     */
    public void updateAsciiStream(String columnLabel, InputStream x)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateAsciiStream(int, java.io.InputStream, long)
     */
    public void updateAsciiStream(int columnIndex, InputStream x, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateAsciiStream(java.lang.String, java.io.InputStream, long)
     */
    public void updateAsciiStream(String columnLabel, InputStream x, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateBinaryStream(int, java.io.InputStream)
     */
    public void updateBinaryStream(int columnIndex, InputStream x)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateBinaryStream(java.lang.String, java.io.InputStream)
     */
    public void updateBinaryStream(String columnLabel, InputStream x)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateBinaryStream(int, java.io.InputStream, long)
     */
    public void updateBinaryStream(int columnIndex, InputStream x, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateBinaryStream(java.lang.String, java.io.InputStream, long)
     */
    public void updateBinaryStream(String columnLabel, InputStream x,
            long length) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateBlob(int, java.io.InputStream)
     */
    public void updateBlob(int columnIndex, InputStream inputStream)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateBlob(java.lang.String, java.io.InputStream)
     */
    public void updateBlob(String columnLabel, InputStream inputStream)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateBlob(int, java.io.InputStream, long)
     */
    public void updateBlob(int columnIndex, InputStream inputStream, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateBlob(java.lang.String, java.io.InputStream, long)
     */
    public void updateBlob(String columnLabel, InputStream inputStream,
            long length) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateCharacterStream(int, java.io.Reader)
     */
    public void updateCharacterStream(int columnIndex, Reader x)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateCharacterStream(java.lang.String, java.io.Reader)
     */
    public void updateCharacterStream(String columnLabel, Reader reader)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateCharacterStream(int, java.io.Reader, long)
     */
    public void updateCharacterStream(int columnIndex, Reader x, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateCharacterStream(java.lang.String, java.io.Reader, long)
     */
    public void updateCharacterStream(String columnLabel, Reader reader,
            long length) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateClob(int, java.io.Reader)
     */
    public void updateClob(int columnIndex, Reader reader) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateClob(java.lang.String, java.io.Reader)
     */
    public void updateClob(String columnLabel, Reader reader)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateClob(int, java.io.Reader, long)
     */
    public void updateClob(int columnIndex, Reader reader, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateClob(java.lang.String, java.io.Reader, long)
     */
    public void updateClob(String columnLabel, Reader reader, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateNCharacterStream(int, java.io.Reader)
     */
    public void updateNCharacterStream(int columnIndex, Reader x)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateNCharacterStream(java.lang.String, java.io.Reader)
     */
    public void updateNCharacterStream(String columnLabel, Reader reader)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateNCharacterStream(int, java.io.Reader, long)
     */
    public void updateNCharacterStream(int columnIndex, Reader x, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateNCharacterStream(java.lang.String, java.io.Reader, long)
     */
    public void updateNCharacterStream(String columnLabel, Reader reader,
            long length) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateNClob(int, java.sql.NClob)
     */
    public void updateNClob(int columnIndex, NClob clob) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateNClob(java.lang.String, java.sql.NClob)
     */
    public void updateNClob(String columnLabel, NClob clob) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateNClob(int, java.io.Reader)
     */
    public void updateNClob(int columnIndex, Reader reader) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateNClob(java.lang.String, java.io.Reader)
     */
    public void updateNClob(String columnLabel, Reader reader)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateNClob(int, java.io.Reader, long)
     */
    public void updateNClob(int columnIndex, Reader reader, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateNClob(java.lang.String, java.io.Reader, long)
     */
    public void updateNClob(String columnLabel, Reader reader, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateNString(int, java.lang.String)
     */
    public void updateNString(int columnIndex, String string)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateNString(java.lang.String, java.lang.String)
     */
    public void updateNString(String columnLabel, String string)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateRowId(int, java.sql.RowId)
     */
    public void updateRowId(int columnIndex, RowId x) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateRowId(java.lang.String, java.sql.RowId)
     */
    public void updateRowId(String columnLabel, RowId x) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateSQLXML(int, java.sql.SQLXML)
     */
    public void updateSQLXML(int columnIndex, SQLXML xmlObject)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.ResultSet#updateSQLXML(java.lang.String, java.sql.SQLXML)
     */
    public void updateSQLXML(String columnLabel, SQLXML xmlObject)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

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