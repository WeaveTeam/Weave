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

import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.SQLWarning;
import java.sql.Types;
import java.util.ArrayList;
import java.util.HashSet;

/**
 * A memory cached scrollable/updateable result set.
 * <p/>
 * Notes:
 * <ol>
 *   <li>For maximum performance use the scroll insensitive result set type.
 *   <li>As the result set is cached in memory this implementation is limited
 *     to small result sets.
 *   <li>Updateable or scroll sensitive result sets are limited to selects
 *     which reference one table only.
 *   <li>Scroll sensitive result sets must have primary keys.
 *   <li>Updates are optimistic. To guard against lost updates it is
 *     recommended that the table includes a timestamp column.
 *   <li>This class is a plug-in replacement for the MSCursorResultSet class
 *     which may be advantageous in certain applications as the scroll
 *     insensitive result set implemented here is much faster than the server
 *     side cursor.
 *   <li>Updateable result sets cannot be built from the output of stored
 *     procedures.
 *   <li>This implementation uses 'select ... for browse' to obtain the column
 *     meta data needed to generate update statements etc.
 *   <li>Named forward updateable cursors are also supported in which case
 *     positioned updates and deletes are used referencing a server side
 *     declared cursor.
 *   <li>Named forward read only declared cursors can have a larger fetch size
 *     specified allowing a cursor alternative to the default direct select
 *     method.
 * </ol>
 *
 * @author Mike Hutchinson
 * @version $Id: CachedResultSet.java,v 1.26 2007-07-08 17:28:23 bheineman Exp $
 * @todo Should add a "close statement" flag to the constructors
 */
public class CachedResultSet extends JtdsResultSet {

    /** Indicates currently inserting. */
    protected boolean onInsertRow;
    /** Buffer row used for inserts. */
    protected ParamInfo[] insertRow;
    /** The "update" row. */
    protected ParamInfo[] updateRow;
    // FIXME Remember if the row was updated/deleted for each row in the ResultSet
    /** Indicates that row has been updated. */
    protected boolean rowUpdated;
    /** Indicates that row has been deleted. */
    protected boolean rowDeleted;
    /** The row count of the initial result set. */
    protected int initialRowCnt;
    /** True if this is a local temporary result set. */
    protected final boolean tempResultSet;
    /** Cursor TdsCore object. */
    protected final TdsCore cursorTds;
    /** Updates TdsCore object used for positioned updates. */
    protected final TdsCore updateTds;
    /** Flag to indicate Sybase. */
    protected boolean isSybase;
    /** Fetch size has been changed. */
    protected boolean sizeChanged;
    /** Original SQL statement. */
    protected String sql;
    /** Original procedure name. */
    protected final String procName;
    /** Original parameters. */
    protected final ParamInfo[] procedureParams;
    /** Table is keyed. */
    protected boolean isKeyed;
    /** First table name in select. */
    protected String tableName;
    /** The parent connection object */
    protected ConnectionJDBC2 connection;

    /**
     * Constructs a new cached result set.
     * <p/>
     * This result set will either be cached in memory or, if the cursor name
     * is set, can be a forward only server side cursor. This latter form of
     * cursor can also support positioned updates.
     *
     * @param statement       the parent statement object
     * @param sql             the SQL statement used to build the result set
     * @param procName        an optional stored procedure name
     * @param procedureParams parameters for prepared statements
     * @param resultSetType   the result set type eg scrollable
     * @param concurrency     the result set concurrency eg updateable
     * @exception SQLException if an error occurs
     */
    CachedResultSet(JtdsStatement statement,
            String sql,
            String procName,
            ParamInfo[] procedureParams,
            int resultSetType,
            int concurrency) throws SQLException {
        super(statement, resultSetType, concurrency, null);
        this.connection = (ConnectionJDBC2) statement.getConnection();
        this.cursorTds = statement.getTds();
        this.sql = sql;
        this.procName = procName;
        this.procedureParams = procedureParams;
        if (resultSetType == ResultSet.TYPE_FORWARD_ONLY
                && concurrency != ResultSet.CONCUR_READ_ONLY
                && cursorName != null) {
            // Need an addtional TDS for positioned updates
            this.updateTds = new TdsCore(connection, statement.getMessages());
        } else {
            this.updateTds = this.cursorTds;
        }
        this.isSybase = Driver.SYBASE == connection.getServerType();
        this.tempResultSet = false;
        //
        // Now create the specified type of cursor
        //
        cursorCreate();
    }

    /**
     * Constructs a cached result set based on locally generated data.
     *
     * @param statement the parent statement object
     * @param colName   array of column names
     * @param colType   array of corresponding data types
     * @exception SQLException if an error occurs
     */
    CachedResultSet(JtdsStatement statement,
                    String[] colName, int[] colType) throws SQLException {
        super(statement, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE, null);
        //
        // Construct the column descriptor array
        //
        this.columns = new ColInfo[colName.length];
        for (int i = 0; i < colName.length; i++) {
            ColInfo ci = new ColInfo();
            ci.name     = colName[i];
            ci.realName = colName[i];
            ci.jdbcType = colType[i];
            ci.isCaseSensitive = false;
            ci.isIdentity = false;
            ci.isWriteable = false;
            ci.nullable = 2;
            ci.scale = 0;
            TdsData.fillInType(ci);
            columns[i] = ci;
        }
        this.columnCount   = getColumnCount(columns);
        this.rowData       = new ArrayList(INITIAL_ROW_COUNT);
        this.rowsInResult  = 0;
        this.initialRowCnt = 0;
        this.pos           = POS_BEFORE_FIRST;
        this.tempResultSet = true;
        this.cursorName    = null;
        this.cursorTds     = null;
        this.updateTds     = null;
        this.procName      = null;
        this.procedureParams = null;
    }

    /**
     * Creates a cached result set with the same columns (and optionally data)
     * as an existing result set.
     *
     * @param rs   the result set to copy
     * @param load load data from the supplied result set
     * @throws SQLException if an error occurs
     */
    CachedResultSet(JtdsResultSet rs, boolean load) throws SQLException {
        super((JtdsStatement)rs.getStatement(),
                rs.getStatement().getResultSetType(),
                rs.getStatement().getResultSetConcurrency(), null);
        //
        JtdsStatement stmt = ((JtdsStatement) rs.getStatement());
        //
        // OK If the user requested an updateable result set tell them
        // they can't have one!
        //
        if (concurrency != ResultSet.CONCUR_READ_ONLY) {
            concurrency = ResultSet.CONCUR_READ_ONLY;
            stmt.addWarning(new SQLWarning(
                Messages.get("warning.cursordowngraded",
                             "CONCUR_READ_ONLY"), "01000"));
        }
        //
        // If the user requested a scroll sensitive cursor tell them
        // they can't have that either!
        //
        if (resultSetType >= ResultSet.TYPE_SCROLL_SENSITIVE) {
            resultSetType = ResultSet.TYPE_SCROLL_INSENSITIVE;
            stmt.addWarning(new SQLWarning(
                Messages.get("warning.cursordowngraded",
                             "TYPE_SCROLL_INSENSITIVE"), "01000"));
        }

        this.columns       = rs.getColumns();
        this.columnCount   = getColumnCount(columns);
        this.rowData       = new ArrayList(INITIAL_ROW_COUNT);
        this.rowsInResult  = 0;
        this.initialRowCnt = 0;
        this.pos           = POS_BEFORE_FIRST;
        this.tempResultSet = true;
        this.cursorName    = null;
        this.cursorTds     = null;
        this.updateTds     = null;
        this.procName      = null;
        this.procedureParams = null;
        //
        // Load result set into buffer
        //
        if (load) {
            while (rs.next()) {
                rowData.add(copyRow(rs.getCurrentRow()));
            }
            this.rowsInResult  = rowData.size();
            this.initialRowCnt = rowsInResult;
        }
    }

    /**
     * Creates a cached result set containing one row.
     *
     * @param statement the parent statement object
     * @param columns   the column descriptor array
     * @param data      the row data
     * @throws SQLException if an error occurs
     */
    CachedResultSet(JtdsStatement statement,
            ColInfo columns[], Object data[]) throws SQLException {
        super(statement, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY, null);
        this.columns       = columns;
        this.columnCount   = getColumnCount(columns);
        this.rowData       = new ArrayList(1);
        this.rowsInResult  = 1;
        this.initialRowCnt = 1;
        this.pos           = POS_BEFORE_FIRST;
        this.tempResultSet = true;
        this.cursorName    = null;
        this.rowData.add(copyRow(data));
        this.cursorTds     = null;
        this.updateTds     = null;
        this.procName      = null;
        this.procedureParams = null;
    }

    /**
     * Modify the concurrency of the result set.
     * <p/>
     * Use to make result set read only once loaded.
     *
     * @param concurrency the concurrency value eg
     *                    <code>ResultSet.CONCUR_READ_ONLY</code>
     */
    void setConcurrency(int concurrency) {
        this.concurrency = concurrency;
    }

    /**
     * Creates a new scrollable result set in memory or a named server cursor.
     *
     * @exception SQLException if an error occurs
     */
    private void cursorCreate()
            throws SQLException {
        //
        boolean isSelect = false;
        int requestedConcurrency = concurrency;
        int requestedType = resultSetType;

        //
        // If the useCursor property is set we will try and use a server
        // side cursor for forward read only cursors. With the default
        // fetch size of 100 this is a reasonable emulation of the
        // MS fast forward cursor.
        //
        if (cursorName == null
                && connection.getUseCursors()
                && resultSetType == ResultSet.TYPE_FORWARD_ONLY
                && concurrency == ResultSet.CONCUR_READ_ONLY) {
        	// The useCursors connection property was set true
        	// so we need to create a private cursor name
        	cursorName = connection.getCursorName();
        }
        //
        // Validate the SQL statement to ensure we have a select.
        //
        if (resultSetType != ResultSet.TYPE_FORWARD_ONLY
            || concurrency != ResultSet.CONCUR_READ_ONLY
            || cursorName != null) {
            //
            // We are going to need access to a SELECT statement for
            // this to work. Reparse the SQL now and check.
            //
            String tmp[] = SQLParser.parse(sql, new ArrayList(),
                    (ConnectionJDBC2) statement.getConnection(), true);

            if ("select".equals(tmp[2])) {
                isSelect = true;
            	if (tmp[3] != null && tmp[3].length() > 0) {
            		// OK We have a select with at least one table.
            		tableName = tmp[3];
            	} else {
            		// Can't find a table name so can't update
                    concurrency = ResultSet.CONCUR_READ_ONLY;
            	}
            } else {
                // No good we can't update and we can't declare a cursor
                cursorName = null;
                concurrency = ResultSet.CONCUR_READ_ONLY;
                if (resultSetType != ResultSet.TYPE_FORWARD_ONLY) {
                    resultSetType = ResultSet.TYPE_SCROLL_INSENSITIVE;
                }
            }
        }
        //
        // If a cursor name is specified we try and declare a conventional cursor.
        // A server error will occur if we try to create a named cursor on a non
        // select statement.
        //
        if (cursorName != null) {
            //
            // Create and execute DECLARE CURSOR
            //
            StringBuffer cursorSQL =
                    new StringBuffer(sql.length() + cursorName.length()+ 128);
            cursorSQL.append("DECLARE ").append(cursorName)
                    .append(" CURSOR FOR ");
            //
            // We need to adjust any parameter offsets now as the prepended
            // DECLARE CURSOR will throw the parameter positions off.
            //
            ParamInfo[] parameters = procedureParams;
            if (procedureParams != null && procedureParams.length > 0) {
                parameters = new ParamInfo[procedureParams.length];
                int offset = cursorSQL.length();
                for (int i = 0; i < parameters.length; i++) {
                    // Clone parameters to avoid corrupting offsets in original
                    parameters[i] = (ParamInfo) procedureParams[i].clone();
                    parameters[i].markerPos += offset;
                }
            }
            cursorSQL.append(sql);
            cursorTds.executeSQL(cursorSQL.toString(), null, parameters,
                    false, statement.getQueryTimeout(), statement.getMaxRows(),
                    statement.getMaxFieldSize(), true);
            cursorTds.clearResponseQueue();
            cursorTds.getMessages().checkErrors();
            //
            // OK now open cursor and fetch the first set (fetchSize) rows
            //
            cursorSQL.setLength(0);
            cursorSQL.append("\r\nOPEN ").append(cursorName);
            if (fetchSize > 1 && isSybase) {
                cursorSQL.append("\r\nSET CURSOR ROWS ").append(fetchSize);
                cursorSQL.append(" FOR ").append(cursorName);
            }
            cursorSQL.append("\r\nFETCH ").append(cursorName);
            cursorTds.executeSQL(cursorSQL.toString(), null, null, false,
                    statement.getQueryTimeout(), statement.getMaxRows(),
                    statement.getMaxFieldSize(), true);
            //
            // Check we have a result set
            //
            while (!cursorTds.getMoreResults() && !cursorTds.isEndOfResponse());

            if (!cursorTds.isResultSet()) {
                // Throw exception but queue up any others
                SQLException ex = new SQLException(
                        Messages.get("error.statement.noresult"), "24000");
                ex.setNextException(statement.getMessages().exceptions);
                throw ex;
            }
            columns = cursorTds.getColumns();
            if (connection.getServerType() == Driver.SQLSERVER) {
                // Last column will be rowstat but will not be marked as hidden
                // as we do not have the Column meta data returned by the API
                // cursor.
                // Hide it now to avoid confusion (also should not be updated).
                if (columns.length > 0) {
                    columns[columns.length - 1].isHidden = true;
                }
            }
            columnCount = getColumnCount(columns);
            rowsInResult = cursorTds.isDataInResultSet() ? 1 : 0;
        } else {
            //
            // Open a memory cached scrollable or forward only possibly updateable cursor
            //
            if (isSelect && (concurrency != ResultSet.CONCUR_READ_ONLY
                    || resultSetType >= ResultSet.TYPE_SCROLL_SENSITIVE)) {
                // Need to execute SELECT .. FOR BROWSE to get
                // the MetaData we require for updates etc
                // OK Should have an SQL select statement
                // append " FOR BROWSE" to obtain table names
                // NB. We can't use any jTDS temporary stored proc
                    cursorTds.executeSQL(sql + " FOR BROWSE", null, procedureParams,
                            false, statement.getQueryTimeout(),
                            statement.getMaxRows(), statement.getMaxFieldSize(),
                            true);
                while (!cursorTds.getMoreResults() && !cursorTds.isEndOfResponse());
                if (!cursorTds.isResultSet()) {
                    // Throw exception but queue up any others
                    SQLException ex = new SQLException(
                            Messages.get("error.statement.noresult"), "24000");
                    ex.setNextException(statement.getMessages().exceptions);
                    throw ex;
                }
                columns = cursorTds.getColumns();
                columnCount = getColumnCount(columns);
                rowData = new ArrayList(INITIAL_ROW_COUNT);
                //
                // Load result set into buffer
                //
                cacheResultSetRows();
                rowsInResult  = rowData.size();
                initialRowCnt = rowsInResult;
                pos = POS_BEFORE_FIRST;
                //
                // If cursor is built over one table and the table has
                // key columns then the result set is updateable and / or
                // can be used as a scroll sensitive result set.
                //
                if (!isCursorUpdateable()) {
                    // No so downgrade
                    concurrency = ResultSet.CONCUR_READ_ONLY;
                    if (resultSetType != ResultSet.TYPE_FORWARD_ONLY) {
                        resultSetType = ResultSet.TYPE_SCROLL_INSENSITIVE;
                    }
                }
            } else {
                //
                // Create a read only cursor using direct SQL
                //
                cursorTds.executeSQL(sql, procName, procedureParams, false,
                        statement.getQueryTimeout(), statement.getMaxRows(),
                        statement.getMaxFieldSize(), true);
                while (!cursorTds.getMoreResults() && !cursorTds.isEndOfResponse());

                if (!cursorTds.isResultSet()) {
                    // Throw exception but queue up any others
                    SQLException ex = new SQLException(
                            Messages.get("error.statement.noresult"), "24000");
                    ex.setNextException(statement.getMessages().exceptions);
                    throw ex;
                }
                columns = cursorTds.getColumns();
                columnCount = getColumnCount(columns);
                rowData = new ArrayList(INITIAL_ROW_COUNT);
                //
                // Load result set into buffer
                //
                cacheResultSetRows();
                rowsInResult  = rowData.size();
                initialRowCnt = rowsInResult;
                pos = POS_BEFORE_FIRST;
            }
        }
        //
        // Report any cursor downgrade warnings
        //
        if (concurrency < requestedConcurrency) {
            statement.addWarning(new SQLWarning(
                    Messages.get("warning.cursordowngraded",
                            "CONCUR_READ_ONLY"), "01000"));
        }
        if (resultSetType < requestedType) {
            statement.addWarning(new SQLWarning(
                    Messages.get("warning.cursordowngraded",
                            "TYPE_SCROLL_INSENSITIVE"), "01000"));
        }
        //
        // Report any SQLExceptions
        //
        statement.getMessages().checkErrors();
    }

    /**
     * Analyses the tables in the result set and determines if the primary key
     * columns needed to make it updateable exist.
     * <p/>
     * Sybase (and SQL 6.5) will automatically include any additional key and
     * timestamp columns as hidden fields even if the user does not reference
     * them in the select statement.
     * <p/>
     * If the table is unkeyed but there is an identity column then this is
     * promoted to a key.
     * <p/>
     * Alternatively we can update, provided all the columns in the table row
     * have been selected, by regarding all of them as keys.
     * <p/>
     * SQL Server 7+ does not return the correct primary key meta data for
     * temporary tables so the driver has to query the catalog to locate any
     * keys.
     *
     * @return <code>true<code> if there is one table and it is keyed
     */
    boolean isCursorUpdateable() throws SQLException {
        //
        // Get fully qualified table names and check keys
        //
        isKeyed = false;
        HashSet tableSet = new HashSet();
        for (int i = 0; i < columns.length; i++) {
            ColInfo ci = columns[i];
            if (ci.isKey) {
                // If a table lacks a key Sybase flags all columns except timestamps as keys.
                // This does not make much sense in the case of text or image fields!
                if ("text".equals(ci.sqlType) || "image".equals(ci.sqlType)) {
                    ci.isKey = false;
                } else {
                    isKeyed = true;
                }
            } else
            if (ci.isIdentity) {
                // This is a good choice for a row identifier!
                ci.isKey = true;
                isKeyed = true;
            }
            StringBuffer key = new StringBuffer();
            if (ci.tableName != null && ci.tableName.length() > 0) {
                key.setLength(0);
                if (ci.catalog != null) {
                    key.append(ci.catalog).append('.');
                    if (ci.schema == null) {
                        key.append('.');
                    }
                }
                if (ci.schema != null) {
                    key.append(ci.schema).append('.');
                }
                key.append(ci.tableName);
                tableName = key.toString();
                tableSet.add(tableName);
            }
        }
        //
        // MJH - SQL Server 7/2000 does not return key information for temporary tables.
        // I regard this as a bug!
        // See if we can find up to the first 8 index columns for ourselves.
        //
        if (tableName.startsWith("#") && cursorTds.getTdsVersion() >= Driver.TDS70) {
            StringBuffer sql = new StringBuffer(1024);
            sql.append("SELECT ");
            for (int i = 1; i <= 8; i++) {
                if (i > 1) {
                    sql.append(',');
                }
                sql.append("index_col('tempdb..").append(tableName);
                sql.append("', indid, ").append(i).append(')');
            }
            sql.append(" FROM tempdb..sysindexes WHERE id = object_id('tempdb..");
            sql.append(tableName).append("') AND indid > 0 AND ");
            sql.append("(status & 2048) = 2048");
            cursorTds.executeSQL(sql.toString(), null, null, false, 0,
                    statement.getMaxRows(), statement.getMaxFieldSize(), true);
            while (!cursorTds.getMoreResults() && !cursorTds.isEndOfResponse());

            if (cursorTds.isResultSet() && cursorTds.getNextRow())
            {
                Object row[] = cursorTds.getRowData();
                for (int i =0 ; i < row.length; i++) {
                    String name = (String)row[i];
                    if (name != null) {
                        for (int c = 0; c < columns.length; c++) {
                            if (columns[c].realName != null &&
                                columns[c].realName.equalsIgnoreCase(name)) {
                                columns[c].isKey = true;
                                isKeyed = true;
                                break;
                            }
                        }
                    }
                }
            }
            // Report any errors found
            statement.getMessages().checkErrors();
        }
        //
        // Final fall back make all columns pseudo keys!
        // Sybase seems to do this automatically.
        //
        if (!isKeyed) {
            for (int i = 0; i < columns.length; i++) {
                String type = columns[i].sqlType;
                if (!"ntext".equals(type) &&
                        !"text".equals(type) &&
                        !"image".equals(type) &&
                        !"timestamp".equals(type) &&
                        columns[i].tableName != null) {
                    columns[i].isKey = true;
                    isKeyed = true;
                }
            }
        }

        return (tableSet.size() == 1 && isKeyed);
    }

    /**
     * Fetches the next result row from the internal row array.
     *
     * @param rowNum the row number to fetch
     * @return <code>true</code> if a result set row is returned
     * @throws SQLException if an error occurs
     */
    private boolean cursorFetch(int rowNum)
            throws SQLException {
        rowUpdated = false;
        //
        if (cursorName != null) {
            //
            // Using a conventional forward only server cursor
            //
            if (!cursorTds.getNextRow()) {
                // Need to fetch more rows from server
                StringBuffer sql = new StringBuffer(128);
                if (isSybase && sizeChanged) {
                    // Sybase allows us to set a fetch size
                    sql.append("SET CURSOR ROWS ").append(fetchSize);
                    sql.append(" FOR ").append(cursorName);
                    sql.append("\r\n");
                }
                sql.append("FETCH ").append(cursorName);
                // Get the next row or block of rows.
                cursorTds.executeSQL(sql.toString(), null, null, false,
                        statement.getQueryTimeout(), statement.getMaxRows(),
                        statement.getMaxFieldSize(), true);
                while (!cursorTds.getMoreResults() && !cursorTds.isEndOfResponse());

                sizeChanged = false; // Indicate fetch size updated

                if (!cursorTds.isResultSet() || !cursorTds.getNextRow()) {
                    pos = POS_AFTER_LAST;
                    currentRow = null;
                    statement.getMessages().checkErrors();
                    return false;
                }
            }
            currentRow = statement.getTds().getRowData();
            pos++;
            rowsInResult = pos;
            statement.getMessages().checkErrors();

            return currentRow != null;

        }
        //
        // JDBC2 style Scrollable and/or Updateable cursor
        //
        if (rowsInResult == 0) {
            pos = POS_BEFORE_FIRST;
            currentRow = null;
            return false;
        }
        if (rowNum == pos) {
            // On current row
            //
            return true;
        }
        if (rowNum < 1) {
            currentRow = null;
            pos = POS_BEFORE_FIRST;
            return false;
        }
        if (rowNum > rowsInResult) {
            currentRow = null;
            pos = POS_AFTER_LAST;
            return false;
        }
        pos = rowNum;
        currentRow = (Object[])rowData.get(rowNum-1);
        rowDeleted = currentRow == null;

        if (resultSetType >= ResultSet.TYPE_SCROLL_SENSITIVE &&
            currentRow != null) {
            refreshRow();
        }

        return true;
    }

    /**
     * Closes the result set.
     */
    private void cursorClose() throws SQLException {
        if (cursorName != null) {
            statement.clearWarnings();
            String sql;
            if (isSybase) {
                sql = "CLOSE " + cursorName +
                      "\r\nDEALLOCATE CURSOR " + cursorName;
            } else {
                sql = "CLOSE " + cursorName +
                      "\r\nDEALLOCATE " + cursorName;
            }
            cursorTds.submitSQL(sql);
        }
        rowData = null;
    }

    /**
     * Creates a parameter object for an UPDATE, DELETE or INSERT statement.
     *
     * @param pos   the substitution position of the parameter marker in the SQL
     * @param info  the <code>ColInfo</code> column descriptor
     * @param value the column data item
     * @return the new parameter as a <code>ParamInfo</code> object
     */
    protected static ParamInfo buildParameter(int pos, ColInfo info, Object value, boolean isUnicode)
            throws SQLException {

        int length = 0;
        if (value instanceof String) {
            length = ((String)value).length();
        } else
        if (value instanceof byte[]) {
            length = ((byte[])value).length;
        } else
        if (value instanceof BlobImpl) {
            BlobImpl blob = (BlobImpl)value;
            value   = blob.getBinaryStream();
            length  = (int)blob.length();
        } else
        if (value instanceof ClobImpl) {
            ClobImpl clob = (ClobImpl)value;
            value   = clob.getCharacterStream();
            length  = (int)clob.length();
        }
        ParamInfo param = new ParamInfo(info, null, value, length);
        param.isUnicode = "nvarchar".equals(info.sqlType) ||
				          "nchar".equals(info.sqlType) ||
				          "ntext".equals(info.sqlType) ||
                          isUnicode;
        param.markerPos = pos;

        return param;
    }

    /**
     * Sets the specified column's data value.
     *
     * @param colIndex index of the column
     * @param value    new column value
     * @return the value, possibly converted to an internal type
     */
    protected Object setColValue(int colIndex, int jdbcType, Object value, int length)
            throws SQLException {

        value = super.setColValue(colIndex, jdbcType, value, length);

        if (!onInsertRow && currentRow == null) {
            throw new SQLException(Messages.get("error.resultset.norow"), "24000");
        }
        colIndex--;
        ParamInfo pi;
        ColInfo ci = columns[colIndex];
        boolean isUnicode = TdsData.isUnicode(ci);

        if (onInsertRow) {
            pi = insertRow[colIndex];
            if (pi == null) {
                pi = new ParamInfo(-1, isUnicode);
                pi.collation = ci.collation;
                pi.charsetInfo = ci.charsetInfo;
                insertRow[colIndex] = pi;
            }
        } else {
            if (updateRow == null) {
                updateRow = new ParamInfo[columnCount];
            }
            pi = updateRow[colIndex];
            if (pi == null) {
                pi = new ParamInfo(-1, isUnicode);
                pi.collation = ci.collation;
                pi.charsetInfo = ci.charsetInfo;
                updateRow[colIndex] = pi;
            }
        }

        if (value == null) {
            pi.value    = null;
            pi.length   = 0;
            pi.jdbcType = ci.jdbcType;
            pi.isSet    = true;
            if (pi.jdbcType == Types.NUMERIC || pi.jdbcType == Types.DECIMAL) {
                pi.scale = TdsData.DEFAULT_SCALE;
            } else {
                pi.scale = 0;
            }
        } else {
            pi.value     = value;
            pi.length    = length;
            pi.isSet     = true;
            pi.jdbcType  = jdbcType;
            if (pi.value instanceof BigDecimal) {
                pi.scale = ((BigDecimal)pi.value).scale();
            } else {
                pi.scale = 0;
            }
        }

        return value;
    }

    /**
     * Builds a WHERE clause for UPDATE or DELETE statements.
     *
     * @param sql    the SQL Statement to append the WHERE clause to
     * @param params the parameter descriptor array for this statement
     * @param select true if this WHERE clause will be used in a select
     *               statement
     * @return the parameter list as a <code>ParamInfo[]</code>
     * @throws SQLException if an error occurs
     */
    ParamInfo[] buildWhereClause(StringBuffer sql, ArrayList params, boolean select)
            throws SQLException {
        //
        // Now construct where clause
        //
        sql.append(" WHERE ");
        if (cursorName != null) {
            //
            // Use a positioned update
            //
            sql.append(" CURRENT OF ").append(cursorName);
        } else {
            int count = 0;
            for (int i = 0; i < columns.length; i++) {
                if (currentRow[i] == null) {
                    if (!"text".equals(columns[i].sqlType)
                            && !"ntext".equals(columns[i].sqlType)
                            && !"image".equals(columns[i].sqlType)
                            && columns[i].tableName != null) {
                        if (count > 0) {
                            sql.append(" AND ");
                        }
                        sql.append(columns[i].realName);
                        sql.append(" IS NULL");
                    }
                } else {
                    if (isKeyed && select) {
                        // For refresh select only include key columns
                        if (columns[i].isKey) {
                            if (count > 0) {
                                sql.append(" AND ");
                            }
                            sql.append(columns[i].realName);
                            sql.append("=?");
                            count++;
                            params.add(buildParameter(sql.length() - 1, columns[i],
                                    currentRow[i], connection.getUseUnicode()));
                        }
                    } else {
                        // Include all available 'searchable' columns in updates/deletes to protect
                        // against lost updates.
                        if (!"text".equals(columns[i].sqlType)
                                && !"ntext".equals(columns[i].sqlType)
                                && !"image".equals(columns[i].sqlType)
                                && columns[i].tableName != null) {
                            if (count > 0) {
                                sql.append(" AND ");
                            }
                            sql.append(columns[i].realName);
                            sql.append("=?");
                            count++;
                            params.add(buildParameter(sql.length() - 1, columns[i],
                                    currentRow[i], connection.getUseUnicode()));
                        }
                    }
                }
            }
        }
        return (ParamInfo[]) params.toArray(new ParamInfo[params.size()]);
    }

    /**
     * Refreshes a result set row from keyed tables.
     * <p/>
     * If all the tables in the result set have primary keys then the result
     * set row can be refreshed by refetching the individual table rows.
     *
     * @throws SQLException if an error occurs
     */
    protected void refreshKeyedRows() throws SQLException
    {
        //
        // Construct a SELECT statement
        //
        StringBuffer sql = new StringBuffer(100 + columns.length * 10);
        sql.append("SELECT ");
        int count = 0;
        for (int i = 0; i < columns.length; i++) {
            if (!columns[i].isKey && columns[i].tableName != null) {
                if (count > 0) {
                    sql.append(',');
                }
                sql.append(columns[i].realName);
                count++;
            }
        }
        if (count == 0) {
            // No non key columns in this table?
            return;
        }
        sql.append(" FROM ");
        sql.append(tableName);
        //
        // Construct a where clause using keyed columns only
        //
        ArrayList params = new ArrayList();
        buildWhereClause(sql, params, true);
        ParamInfo parameters[] = (ParamInfo[]) params.toArray(new ParamInfo[params.size()]);
        //
        // Execute the select
        //
        TdsCore tds = statement.getTds();
        tds.executeSQL(sql.toString(), null, parameters, false, 0,
                statement.getMaxRows(), statement.getMaxFieldSize(), true);
        if (!tds.isEndOfResponse()) {
            if (tds.getMoreResults() && tds.getNextRow()) {
                // refresh the row data
                Object col[] = tds.getRowData();
                count = 0;
                for (int i = 0; i < columns.length; i++) {
                    if (!columns[i].isKey) {
                        currentRow[i] = col[count++];
                    }
                }
            } else {
                currentRow = null;
            }
        } else {
            currentRow = null;
        }
        tds.clearResponseQueue();
        statement.getMessages().checkErrors();
        if (currentRow == null) {
            rowData.set(pos-1, null);
            rowDeleted = true;
        }
    }

    /**
     * Refreshes the row by rereading the result set.
     * <p/>
     * Obviously very slow on large result sets but may be the only option if
     * tables do not have keys.
     */
    protected void refreshReRead() throws SQLException
    {
        int savePos = pos;
        cursorCreate();
        absolute(savePos);
    }

//
//  -------------------- java.sql.ResultSet methods -------------------
//

     public void setFetchSize(int size) throws SQLException {
         sizeChanged = size != fetchSize;
         super.setFetchSize(size);
     }

     public void afterLast() throws SQLException {
         checkOpen();
         checkScrollable();
         if (pos != POS_AFTER_LAST) {
             cursorFetch(rowsInResult+1);
         }
     }

     public void beforeFirst() throws SQLException {
         checkOpen();
         checkScrollable();

         if (pos != POS_BEFORE_FIRST) {
             cursorFetch(0);
         }
     }

     public void cancelRowUpdates() throws SQLException {
         checkOpen();
         checkUpdateable();
         if (onInsertRow) {
             throw new SQLException(Messages.get("error.resultset.insrow"), "24000");
         }
         if (updateRow != null) {
             rowUpdated = false;
             for (int i = 0; i < updateRow.length; i++) {
                 if (updateRow[i] != null) {
                     updateRow[i].clearInValue();
                 }
             }
         }
     }

     public void close() throws SQLException {
         if (!closed) {
             try {
                 cursorClose();
             } finally {
                 closed    = true;
                 statement = null;
             }
         }
     }

     public void deleteRow() throws SQLException {
         checkOpen();
         checkUpdateable();

         if (currentRow == null) {
             throw new SQLException(Messages.get("error.resultset.norow"), "24000");
         }

         if (onInsertRow) {
             throw new SQLException(Messages.get("error.resultset.insrow"), "24000");
         }

         //
         // Construct an SQL DELETE statement
         //
         StringBuffer sql = new StringBuffer(128);
         ArrayList params = new ArrayList();
         sql.append("DELETE FROM ");
         sql.append(tableName);
         //
         // Create the WHERE clause
         //
         ParamInfo parameters[] = buildWhereClause(sql, params, false);
         //
         // Execute the delete statement
         //
         updateTds.executeSQL(sql.toString(), null, parameters, false, 0,
                 statement.getMaxRows(), statement.getMaxFieldSize(), true);
         int updateCount = 0;
         while (!updateTds.isEndOfResponse()) {
             if (!updateTds.getMoreResults()) {
                 if (updateTds.isUpdateCount()) {
                     updateCount = updateTds.getUpdateCount();
                 }
             }
         }
         updateTds.clearResponseQueue();
         statement.getMessages().checkErrors();
         if (updateCount == 0) {
             // No delete. Possibly row was changed on database by another user?
             throw new SQLException(Messages.get("error.resultset.deletefail"), "24000");
         }
         rowDeleted = true;
         currentRow = null;
         if (resultSetType != ResultSet.TYPE_FORWARD_ONLY) {
             // Leave a 'hole' in the result set array.
             rowData.set(pos-1, null);
         }
     }

     public void insertRow() throws SQLException {
         checkOpen();

         checkUpdateable();

         if (!onInsertRow) {
             throw new SQLException(Messages.get("error.resultset.notinsrow"), "24000");
         }

         if (!tempResultSet) {
             //
             // Construct an SQL INSERT statement
             //
             StringBuffer sql = new StringBuffer(128);
             ArrayList params = new ArrayList();
             sql.append("INSERT INTO ");
             sql.append(tableName);
             int sqlLen = sql.length();
             //
             // Create column list
             //
             sql.append(" (");
             int count = 0;
             for (int i = 0; i < columnCount; i++) {
                 if (insertRow[i] != null) {
                     if (count > 0) {
                         sql.append(", ");
                     }
                     sql.append(columns[i].realName);
                     count++;
                 }
             }
             //
             // Create new values list
             //
             sql.append(") VALUES(");
             count = 0;
             for (int i = 0; i < columnCount; i++) {
                 if (insertRow[i] != null) {
                     if (count > 0) {
                         sql.append(", ");
                     }
                     sql.append('?');
                     insertRow[i].markerPos = sql.length()-1;
                     params.add(insertRow[i]);
                     count++;
                 }
             }
             sql.append(')');
             if (count == 0) {
                 // Empty insert
                 sql.setLength(sqlLen);
                 if (isSybase) {
                     sql.append(" VALUES()");
                 } else {
                     sql.append(" DEFAULT VALUES");
                 }
             }
             ParamInfo parameters[] = (ParamInfo[]) params.toArray(new ParamInfo[params.size()]);
             //
             // execute the insert statement
             //
             updateTds.executeSQL(sql.toString(), null, parameters, false, 0,
                     statement.getMaxRows(), statement.getMaxFieldSize(), true);
             int updateCount = 0;
             while (!updateTds.isEndOfResponse()) {
                 if (!updateTds.getMoreResults()) {
                     if (updateTds.isUpdateCount()) {
                         updateCount = updateTds.getUpdateCount();
                     }
                 }
             }
             updateTds.clearResponseQueue();
             statement.getMessages().checkErrors();
             if (updateCount < 1) {
                 // No Insert. Probably will not get here as duplicate key etc
                 // will have already been reported as an exception.
                 throw new SQLException(Messages.get("error.resultset.insertfail"), "24000");
             }
         }
         //
         if (resultSetType >= ResultSet.TYPE_SCROLL_SENSITIVE
                 || (resultSetType == ResultSet.TYPE_FORWARD_ONLY && cursorName == null))
         {
             //
             // Now insert copy of row into result set buffer
             //
             ConnectionJDBC2 con = (ConnectionJDBC2)statement.getConnection();
             Object row[] = newRow();
             for (int i = 0; i < insertRow.length; i++) {
                 if (insertRow[i] != null) {
                     row[i] = Support.convert(con, insertRow[i].value,
                             columns[i].jdbcType, con.getCharset());
                 }
             }
             rowData.add(row);
         }
         rowsInResult++;
         initialRowCnt++;
         //
         // Clear row data
         //
         for (int i = 0; insertRow != null && i < insertRow.length; i++) {
             if (insertRow[i] != null) {
                 insertRow[i].clearInValue();
             }
         }
     }

     public void moveToCurrentRow() throws SQLException {
         checkOpen();
         checkUpdateable();
         insertRow = null;
         onInsertRow = false;
     }


     public void moveToInsertRow() throws SQLException {
         checkOpen();
         checkUpdateable();
         insertRow   = new ParamInfo[columnCount];
         onInsertRow = true;
     }

     public void refreshRow() throws SQLException {
         checkOpen();

         if (onInsertRow) {
             throw new SQLException(Messages.get("error.resultset.insrow"), "24000");
         }

         //
         // If row is being updated discard updates now
         //
         if (concurrency != ResultSet.CONCUR_READ_ONLY) {
             cancelRowUpdates();
             rowUpdated = false;
         }
         if (resultSetType == ResultSet.TYPE_FORWARD_ONLY ||
             currentRow == null) {
             // Do not try and refresh the row in these cases.
             return;
         }
         //
         // If result set is keyed we can refresh the row data from the
         // database using the key.
         // NB. MS SQL Server #Temporary tables with keys are not identified correctly
         // in the column meta data sent after 'for browse'. This means that
         // temporary tables can not be used with this logic.
         //
         if (isKeyed) {
             // OK all tables are keyed
             refreshKeyedRows();
         } else {
             // No good have to use brute force approach
             refreshReRead();
         }
     }

     public void updateRow() throws SQLException {
         checkOpen();
         checkUpdateable();

         rowUpdated = false;
         rowDeleted = false;
         if (currentRow == null) {
             throw new SQLException(Messages.get("error.resultset.norow"), "24000");
         }

         if (onInsertRow) {
             throw new SQLException(Messages.get("error.resultset.insrow"), "24000");
         }

         if (updateRow == null) {
             // Nothing to update
             return;
         }
         boolean keysChanged = false;
         //
         // Construct an SQL UPDATE statement
         //
         StringBuffer sql = new StringBuffer(128);
         ArrayList params = new ArrayList();
         sql.append("UPDATE ");
         sql.append(tableName);
         //
         // OK now create assign new values
         //
         sql.append(" SET ");
         int count = 0;
         for (int i = 0; i < columnCount; i++) {
             if (updateRow[i] != null) {
                 if (count > 0) {
                     sql.append(", ");
                 }
                 sql.append(columns[i].realName);
                 sql.append("=?");
                 updateRow[i].markerPos = sql.length()-1;
                 params.add(updateRow[i]);
                 count++;
                 if (columns[i].isKey) {
                     // Key is changing so in memory row will need to be deleted
                     // and reinserted at end of row buffer.
                     keysChanged = true;
                 }
             }
         }
         if (count == 0) {
             // There are no columns to update in this table
             // so bail out now.
             return;
         }
         //
         // Now construct where clause
         //
         ParamInfo parameters[] = buildWhereClause(sql, params, false);
         //
         // Now execute update
         //
         updateTds.executeSQL(sql.toString(), null, parameters, false, 0,
                 statement.getMaxRows(), statement.getMaxFieldSize(), true);
         int updateCount = 0;
         while (!updateTds.isEndOfResponse()) {
             if (!updateTds.getMoreResults()) {
                 if (updateTds.isUpdateCount()) {
                     updateCount = updateTds.getUpdateCount();
                 }
             }
         }
         updateTds.clearResponseQueue();
         statement.getMessages().checkErrors();

         if (updateCount == 0) {
             // No update. Possibly row was changed on database by another user?
             throw new SQLException(Messages.get("error.resultset.updatefail"), "24000");
         }
         //
         // Update local copy of data
         //
         if (resultSetType != ResultSet.TYPE_SCROLL_INSENSITIVE) {
             // Make in memory copy reflect database update
             // Could use refreshRow but this is much faster.
             ConnectionJDBC2 con = (ConnectionJDBC2)statement.getConnection();
             for (int i = 0; i < updateRow.length; i++) {
                 if (updateRow[i] != null) {
                     if (updateRow[i].value instanceof byte[]
                         && (columns[i].jdbcType == Types.CHAR ||
                             columns[i].jdbcType == Types.VARCHAR ||
                             columns[i].jdbcType == Types.LONGVARCHAR)) {
                         // Need to handle byte[] to varchar otherwise field
                         // will be set to hex string rather than characters.
                         try {
                             currentRow[i] = new String((byte[])updateRow[i].value, con.getCharset());
                         } catch (UnsupportedEncodingException e) {
                             currentRow[i] = new String((byte[])updateRow[i].value);
                         }
                     } else {
                         currentRow[i] = Support.convert(con, updateRow[i].value,
                                                 columns[i].jdbcType, con.getCharset());
                     }
                 }
             }
         }
         //
         // Update state of cached row data
         //
         if (keysChanged && resultSetType >= ResultSet.TYPE_SCROLL_SENSITIVE) {
             // Leave hole at current position and add updated row to end of set
             rowData.add(currentRow);
             rowsInResult = rowData.size();
             rowData.set(pos-1, null);
             currentRow = null;
             rowDeleted = true;
         } else {
             rowUpdated = true;
         }
         //
         // Clear update values
         //
         cancelRowUpdates();
     }

     public boolean first() throws SQLException {
         checkOpen();
         checkScrollable();
         return cursorFetch(1);
     }

     public boolean isLast() throws SQLException {
         checkOpen();

         return(pos == rowsInResult) && (rowsInResult != 0);
     }

     public boolean last() throws SQLException {
         checkOpen();
         checkScrollable();
         return cursorFetch(rowsInResult);
     }

     public boolean next() throws SQLException {
         checkOpen();
         if (pos != POS_AFTER_LAST) {
             return cursorFetch(pos+1);
         } else {
             return false;
         }
     }

     public boolean previous() throws SQLException {
         checkOpen();
         checkScrollable();
         if (pos == POS_AFTER_LAST) {
             pos = rowsInResult+1;
         }
         return cursorFetch(pos-1);
     }

     public boolean rowDeleted() throws SQLException {
         checkOpen();

         return rowDeleted;
     }

     public boolean rowInserted() throws SQLException {
         checkOpen();

//         return pos > initialRowCnt;
         return false; // Same as MSCursorResultSet
     }

     public boolean rowUpdated() throws SQLException {
         checkOpen();

//         return rowUpdated;
         return false; // Same as MSCursorResultSet
     }

     public boolean absolute(int row) throws SQLException {
         checkOpen();
         checkScrollable();
         if (row < 1) {
             row = (rowsInResult + 1) + row;
         }

         return cursorFetch(row);
     }

     public boolean relative(int row) throws SQLException {
         checkScrollable();
         if (pos == POS_AFTER_LAST) {
             return absolute((rowsInResult+1)+row);
         } else {
             return absolute(pos+row);
         }
     }

     public String getCursorName() throws SQLException {
        checkOpen();
        // Hide internal cursor names
        if (cursorName != null && !cursorName.startsWith("_jtds")) {
            return this.cursorName;
        }
        throw new SQLException(Messages.get("error.resultset.noposupdate"), "24000");
    }
}
