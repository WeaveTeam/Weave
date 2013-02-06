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

import java.sql.BatchUpdateException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.SQLWarning;
import java.sql.Types;
import java.util.ArrayList;
import java.util.LinkedList;

/**
 * jTDS implementation of the java.sql.Statement interface.<p>
 * NB. As allowed by the JDBC standard and like most other drivers,
 * this implementation only allows one open result set at a time.
 * <p>
 * Implementation notes:
 * <p>
 * I experimented with allowing multiple open result sets as supported
 * by the origianal jTDS but rejected this approach for the following
 * reasons:
 * <ol>
 * <li>It is more difficult to ensure that there are no memory leaks and that
 *     cursors are closed if multiple open sets are allowed.
 * <li>The use of one result set allows cursor and non cursor result sets to
 *     be derived from exeuteQuery() or execute() and getResultSet() in the
 *     same way that other drivers do.
 * </ol>
 * In the event of an IO failure the setClosed() method forces this statement
 * and associated result set to close preventing the propogation of errors.
 * This class includes a finalize method which increases the chances of the
 * statement being closed tidly in a pooled environment where the user has
 * forgotten to explicitly close the statement before it goes out of scope.
 *
 * @see java.sql.Statement
 * @see java.sql.Connection#createStatement()
 * @see java.sql.ResultSet
 *
 * @author Mike Hutchinson
 * @version $Id: JtdsStatement.java,v 1.64.2.4 2009-12-30 08:45:34 ickzon Exp $
 */
public class JtdsStatement implements java.sql.Statement {
    /*
     * Constants used for backwards compatibility with JDK 1.3
     */
    static final int RETURN_GENERATED_KEYS = 1;
    static final int NO_GENERATED_KEYS = 2;
    static final int CLOSE_CURRENT_RESULT = 1;
    static final int KEEP_CURRENT_RESULT = 2;
    static final int CLOSE_ALL_RESULTS = 3;
    static final int BOOLEAN = 16;
    static final int DATALINK = 70;
    static final Integer SUCCESS_NO_INFO = new Integer(-2);
    static final Integer EXECUTE_FAILED = new Integer(-3);
    static final int DEFAULT_FETCH_SIZE = 100;

    /** The connection owning this statement object. */
    protected ConnectionJDBC2 connection;
    /** The TDS object used for server access. */
    protected TdsCore tds;
    /** The read query timeout in seconds */
    protected int queryTimeout;
    /** The current <code>ResultSet</code>. */
    protected JtdsResultSet currentResult;
    /** The current update count. */
    private int updateCount = -1;
    /** The fetch direction for result sets. */
    protected int fetchDirection = ResultSet.FETCH_FORWARD;
    /** The type of result sets created by this statement. */
    protected int resultSetType = ResultSet.TYPE_FORWARD_ONLY;
    /** The concurrency of result sets created by this statement. */
    protected int resultSetConcurrency = ResultSet.CONCUR_READ_ONLY;
    /** The fetch size (default 100, only used by cursor
     * <code>ResultSet</code>s).
     */
    protected int fetchSize = DEFAULT_FETCH_SIZE;
    /** The cursor name to be used for positioned updates. */
    protected String cursorName;
    /** True if this statement is closed. */
    protected boolean closed;
    /** The maximum field size (not used at present). */
    protected int maxFieldSize;
    /** The maximum number of rows to return (not used at present). */
    protected int maxRows;
    /** True if SQL statements should be preprocessed. */
    protected boolean escapeProcessing = true;
    /** SQL Diagnostic exceptions and warnings. */
    protected final SQLDiagnostic messages;
    /** Batched SQL Statement array. */
    protected ArrayList batchValues;
    /** Dummy result set for getGeneratedKeys. */
    protected JtdsResultSet genKeyResultSet;
    /**
     * List of queued results (update counts, possibly followed by a
     * <code>ResultSet</code>).
     */
    protected final LinkedList resultQueue = new LinkedList();
    /** List of open result sets. */
    protected ArrayList openResultSets;
    /** The cached column meta data. */
    protected ColInfo[] colMetaData;

    /**
     * Construct a new Statement object.
     *
     * @param connection The parent connection.
     * @param resultSetType The result set type for example TYPE_FORWARD_ONLY.
     * @param resultSetConcurrency The concurrency for example CONCUR_READ_ONLY.
     */
    JtdsStatement(ConnectionJDBC2 connection,
                  int resultSetType,
                  int resultSetConcurrency) throws SQLException {
        //
        // This is a good point to do common validation of the result set type
        //
        if (resultSetType < ResultSet.TYPE_FORWARD_ONLY
                || resultSetType > ResultSet.TYPE_SCROLL_SENSITIVE + 1) {
            String method;
            if (this instanceof JtdsCallableStatement) {
                method = "prepareCall";
            } else if (this instanceof JtdsPreparedStatement) {
                method = "prepareStatement";
            } else {
                method = "createStatement";
            }
            throw new SQLException(
                       Messages.get("error.generic.badparam",
                               "resultSetType",
                               method),
                    "HY092");
        }
        //
        // Ditto for the result set concurrency
        //
        if (resultSetConcurrency < ResultSet.CONCUR_READ_ONLY
                || resultSetConcurrency > ResultSet.CONCUR_UPDATABLE + 2) {
                String method;
                if (this instanceof JtdsCallableStatement) {
                    method = "prepareCall";
                } else if (this instanceof JtdsPreparedStatement) {
                    method = "prepareStatement";
                } else {
                    method = "createStatement";
                }
                throw new SQLException(
                        Messages.get("error.generic.badparam",
                                "resultSetConcurrency",
                                method),
                        "HY092");
        }

        this.connection = connection;
        this.resultSetType = resultSetType;
        this.resultSetConcurrency = resultSetConcurrency;

        this.tds = connection.getCachedTds();
        if (this.tds == null) {
            this.messages = new SQLDiagnostic(connection.getServerType());
            this.tds = new TdsCore(this.connection, messages);
        } else {
            this.messages = tds.getMessages();
        }
    }

    /**
     * Called when this object goes out of scope to close any
     * <code>ResultSet</code> object and this statement.
     */
    protected void finalize() throws Throwable {
        super.finalize();
        try {
            close();
        } catch (SQLException e) {
            // Ignore errors
        }
    }

    /**
     * Get the Statement's TDS object.
     *
     * @return The TDS support as a <code>TdsCore</core> Object.
     */
    TdsCore getTds() {
        return tds;
    }

    /**
     * Get the statement's warnings list.
     *
     * @return The warnings list as a <code>SQLDiagnostic</code>.
     */
    SQLDiagnostic getMessages() {
        return messages;
    }

    /**
     * Check that this statement is still open.
     *
     * @throws SQLException if statement closed.
     */
    protected void checkOpen() throws SQLException {
        if (closed || connection == null || connection.isClosed()) {
            throw new SQLException(
                    Messages.get("error.generic.closed", "Statement"), "HY010");
        }
    }

    /**
     * Check that the exception is caused by the failure to open a
     * cursor and not by a more serious SQL error.
     *
     * @param e the exception returned by the cursor class
     * @throws SQLException if exception is not due to a cursor error
     */
    protected void checkCursorException(SQLException e) throws SQLException{
        if (connection == null
                || connection.isClosed()
                || "HYT00".equals(e.getSQLState())
                || "HY008".equals(e.getSQLState())) {
                // Serious error or timeout so return exception to caller
                throw e;
            }
        if (connection.getServerType() == Driver.SYBASE) {
            // Allow retry for Sybase
            return;
        }
        //
        // Check cursor specific errors and ranges for SQL Server
        //
        int error = e.getErrorCode();
        if (error >= 16900 && error <= 16999) {
            // Errors in this range are all related to the cursor API.
            // This is true for all versions of SQL Server.
            return;
        }
        if (error == 6819) {
            // A FOR XML clause was found
            return;
        }
        if (error == 8654) {
            // A inrow textptr exists
            return;
        }
        if (error == 8162) {
            // Formal parameter '%.*ls' was defined as OUTPUT but the actual
            // parameter not declared OUTPUT. This happens when trying to
            // execute a stored procedure with output parameters via a cursor.
            return;
        }
        //
        // More serious error we should rethrow the error and
        // not allow the driver to re-execute sql.
        //
        throw e;
    }

    /**
     * Report that user tried to call a method which has not been implemented.
     *
     * @param method The method name to report in the error message.
     * @throws SQLException
     */
    static void notImplemented(String method) throws SQLException {
        throw new SQLException(
                Messages.get("error.generic.notimp", method), "HYC00");
    }

    /**
     * Close current result set (if any).
     */
    void closeCurrentResultSet() throws SQLException {
        try {
            if (currentResult != null) {
                currentResult.close();
            }
//        } catch (SQLException e) {
            // Ignore
        } finally {
            currentResult = null;
        }
    }

    /**
     * Close all result sets.
     */
    void closeAllResultSets() throws SQLException {
        try {
            if (openResultSets != null) {
                for (int i = 0; i < openResultSets.size(); i++) {
                    JtdsResultSet rs = (JtdsResultSet) openResultSets.get(i);
                    if (rs != null) {
                        rs.close();
                    }
                }
            }
            closeCurrentResultSet();
        } finally {
            openResultSets = null;
        }
    }

    /**
     * Add an SQLWarning object to the statment warnings list.
     *
     * @param w The SQLWarning to add.
     */
    void addWarning(SQLWarning w) {
        messages.addWarning(w);
    }

    /**
     * Execute the SQL batch on a MS server.
     *
     * @param size the total size of the batch
     * @param executeSize the maximum number of statements to send in one request
     * @param counts the returned update counts
     * @return chained exceptions linked to a <code>SQLException</code>
     * @throws SQLException if a serious error occurs during execution
     */
    protected SQLException executeMSBatch(int size, int executeSize, ArrayList counts) throws SQLException {
        SQLException sqlEx = null;
        for (int i = 0; i < size;) {
            Object value = batchValues.get(i);
            ++i;
            // Execute batch now if max size reached or end of batch
            boolean executeNow = (i % executeSize == 0) || i == size;

            tds.startBatch();
            tds.executeSQL((String) value, null, null, false, 0, -1, -1, executeNow);

            // If the batch has been sent, process the results
            if (executeNow) {
                sqlEx = tds.getBatchCounts(counts, sqlEx);

                // If a serious error then we stop execution now as count
                // is too small.
                if (sqlEx != null && counts.size() != i) {
                    break;
                }
            }
        }
        return sqlEx;
    }

    /**
     * Execute the SQL batch on a Sybase server.
     * <p/>
     * Sybase needs to have the SQL concatenated into one TDS language packet. This method will be overriden for
     * <code>PreparedStatements</code>.
     *
     * @param size the total size of the batch
     * @param executeSize the maximum number of statements to send in one request
     * @param counts the returned update counts
     * @return chained exceptions linked to a <code>SQLException</code>
     * @throws SQLException if a serious error occurs during execution
     */
    protected SQLException executeSybaseBatch(int size, int executeSize, ArrayList counts) throws SQLException {
        StringBuffer sql = new StringBuffer(size * 32); // Make buffer reasonable size
        SQLException sqlEx = null;

        for (int i = 0; i < size;) {
            Object value = batchValues.get(i);
            ++i;
            // Execute batch now if max size reached or end of batch
            boolean executeNow = (i % executeSize == 0) || i == size;

            sql.append((String) value).append(' ');

            if (executeNow) {
                tds.executeSQL(sql.toString(), null, null, false, 0, -1, -1, true);
                sql.setLength(0);
                // If the batch has been sent, process the results
                sqlEx = tds.getBatchCounts(counts, sqlEx);

                // If a serious error or a server error then we stop
                // execution now as count is too small.
                if (sqlEx != null && counts.size() != i) {
                    break;
                }
            }
        }
        return sqlEx;
    }

    /**
     * Executes SQL to obtain a result set.
     *
     * @param sql       the SQL statement to execute
     * @param spName    optional stored procedure name
     * @param params    optional parameters
     * @param useCursor whether a cursor should be created for the SQL
     * @return the result set generated by the query
     */
    protected ResultSet executeSQLQuery(String sql,
                                        String spName,
                                        ParamInfo[] params,
                                        boolean useCursor)
            throws SQLException {
        String warningMessage = null;

        //
        // Try to open a cursor result set if required
        //
        if (useCursor) {
            try {
                if (connection.getServerType() == Driver.SQLSERVER) {
                    currentResult =
                            new MSCursorResultSet(this,
                                    sql,
                                    spName,
                                    params,
                                    resultSetType,
                                    resultSetConcurrency);

                    return currentResult;
                } else {
                    // Use client side cursor for Sybase
                    currentResult =
                        new CachedResultSet(this,
                                sql,
                                spName,
                                params,
                                resultSetType,
                                resultSetConcurrency);

                    return currentResult;
                }
            } catch (SQLException e) {
                checkCursorException(e);
                warningMessage = '[' + e.getSQLState() + "] " + e.getMessage();
            }
        }

        //
        // Could not open a cursor (or was not requested) so try a direct select
        //
        if (spName != null
                && connection.getUseMetadataCache()
                && connection.getPrepareSql() == TdsCore.PREPARE
                && colMetaData != null
                && connection.getServerType() == Driver.SQLSERVER) {
            // There is cached meta data available for this
            // prepared statement
            tds.setColumns(colMetaData);
            tds.executeSQL(sql, spName, params, true, queryTimeout, maxRows,
                    maxFieldSize, true);
        } else {
            tds.executeSQL(sql, spName, params, false, queryTimeout, maxRows,
                    maxFieldSize, true);
        }

        // Update warning chain if cursor was downgraded before processing results
        if (warningMessage != null) {
            addWarning(new SQLWarning(
                    Messages.get("warning.cursordowngraded", warningMessage), "01000"));
        }

        // Ignore update counts preceding the result set. All drivers seem to
        // do this.
        while (!tds.getMoreResults() && !tds.isEndOfResponse());

        // check for server side errors
        messages.checkErrors();

        if (tds.isResultSet()) {
            currentResult = new JtdsResultSet(this,
                                              ResultSet.TYPE_FORWARD_ONLY,
                                              ResultSet.CONCUR_READ_ONLY,
                                              tds.getColumns());
        } else {
            throw new SQLException(
                    Messages.get("error.statement.noresult"), "24000");
        }

        return currentResult;
    }

    /**
     * Executes any type of SQL.
     *
     * @param sql        the SQL statement to execute
     * @param spName     optional stored procedure name
     * @param params     optional parameters
     * @param returnKeys whether the statement returns generated keys
     * @param update     whether the caller is {@link #executeUpdate}
     * @param useCursor  whether the requested result set type or concurrency
     *                   or connection properties request usage of a cursor
     * @return <code>true</code> if the first result is a result set
     * @throws SQLException if an error condition occurs
     */
    protected boolean executeSQL(String sql,
                                 String spName,
                                 ParamInfo[] params,
                                 boolean returnKeys,
                                 boolean update,
                                 boolean useCursor)
            throws SQLException {
        String warningMessage = null;

        //
        // For SQL Server, try to open a cursor result set if required
        // (and possible).
        //
        if (connection.getServerType() == Driver.SQLSERVER && !update && useCursor) {
            try {
                currentResult = new MSCursorResultSet(this, sql, spName,
                        params, resultSetType, resultSetConcurrency);

                return true;
            } catch (SQLException e) {
                checkCursorException(e);
                warningMessage = '[' + e.getSQLState() + "] " + e.getMessage();
            }
        }

        //
        // We are talking to a Sybase server or we could not open a cursor
        // or we did not have a SELECT so just execute the SQL normally.
        //
        tds.executeSQL(sql, spName, params, false, queryTimeout, maxRows,
                maxFieldSize, true);

        if (warningMessage != null) {
            // Update warning chain if cursor was downgraded
            addWarning(new SQLWarning(Messages.get(
                    "warning.cursordowngraded", warningMessage), "01000"));
        }

        if (processResults(returnKeys, update)) {
            Object nextResult = resultQueue.removeFirst();

            // Next result is an update count
            if (nextResult instanceof Integer) {
                updateCount = ((Integer) nextResult).intValue();
                return false;
            }

            // Next result is a ResultSet. Set currentResult and remove it.
            currentResult = (JtdsResultSet) nextResult;
            return true;
        } else {
            return false;
        }
    }

    /**
     * Queue up update counts into {@link #resultQueue} until the end of the
     * response is reached or a <code>ResultSet</code> is encountered. Calling
     * <code>processResults</code> while a <code>ResultSet</code> is open will
     * not close it, but will consume all remaining rows.
     *
     * @param returnKeys <code>true</code> if a generated keys
     *                   <code>ResultSet</code> is expected
     * @param update     <code>true</code> if the method is called from within
     *                   <code>executeUpdate</code>
     * @return           <code>true</code> if there are any results,
     *                   <code>false</code> otherwise
     * @throws SQLException if an error condition occurs
     */
    private boolean processResults(boolean returnKeys, boolean update) throws SQLException {
        if (!resultQueue.isEmpty()) {
            throw new IllegalStateException(
                    "There should be no queued results.");
        }

        while (!tds.isEndOfResponse()) {
            if (!tds.getMoreResults()) {
                if (tds.isUpdateCount()) {
                    if (update && connection.getLastUpdateCount()) {
                        resultQueue.clear();
                    }
                    resultQueue.addLast(new Integer(tds.getUpdateCount()));
                }
            } else {
                if (returnKeys) {
                    // This had better be the generated key
                    // FIXME We could use SELECT @@IDENTITY AS jTDS_SOMETHING and check the column name to make sure
                    if (tds.getNextRow()) {
                        genKeyResultSet = new CachedResultSet(this,
                                tds.getColumns(),
                                tds.getRowData());
                    }
                } else {
                    if (update && resultQueue.isEmpty()) {
                        // Throw exception but queue up any previous ones
                        SQLException ex = new SQLException(
                                Messages.get("error.statement.nocount"), "07000");
                        ex.setNextException(messages.exceptions);
                        throw ex;
                    }

                    resultQueue.add(new JtdsResultSet(
                            this,
                            ResultSet.TYPE_FORWARD_ONLY,
                            ResultSet.CONCUR_READ_ONLY,
                            tds.getColumns()));
                    break;
                }
            }
        }

        // Check for server side errors
        getMessages().checkErrors();

        return !resultQueue.isEmpty();
    }

    /**
     * Cache as many results as possible (up to the first
     * <code>ResultSet</code>). Called by <code>ResultSet</code>s when the
     * end is reached.
     */
    protected void cacheResults() throws SQLException {
        // Cache results
        processResults(false, false);
    }

    /**
     * Initialize the <code>Statement</code>, by cleaning up all queued and
     * unprocessed results. Called by all execute methods.
     *
     * @throws SQLException if an error occurs
     */
    protected void initialize() throws SQLException {
        updateCount = -1;
        resultQueue.clear();
        genKeyResultSet = null;
        tds.clearResponseQueue();
        // FIXME Should old exceptions found now be thrown instead of lost?
        messages.exceptions = null;
        messages.clearWarnings();
        closeAllResultSets();
    }

    /**
     * Implements the common functionality for plain statement {@link #execute}
     * and {#link #executeUpdate}: basic checks, cleaning up of previous
     * results, setting up and executing the query and loading the first
     * results.
     *
     * @param sql    an SQL <code>INSERT</code>, <code>UPDATE</code> or
     *               <code>DELETE</code> statement or an SQL statement that
     *               returns nothing, such as an SQL DDL statement
     * @param autoGeneratedKeys a flag indicating whether auto-generated keys
     *               should be made available for retrieval
     * @param update boolean flag indicating whether the caller is
     *               {@link #executeUpdate} -- in this case an exception is
     *               thrown if the first result is not an update count and no
     *               cursor is created (direct execution)
     * @return <code>true</code> if the first result is a
     *         <code>ResultSet</code>, <code>false</code> if it's an update
     *         count
     * @see #execute
     * @see #executeUpdate
     */
    private boolean executeImpl(String sql, int autoGeneratedKeys, boolean update)
            throws SQLException {
        initialize();

        if (sql == null || sql.length() == 0) {
            throw new SQLException(Messages.get("error.generic.nosql"), "HY000");
        }

        boolean returnKeys;
        String sqlWord = "";
        if (escapeProcessing) {
            String tmp[] = SQLParser.parse(sql, null, connection, false);

            if (tmp[1].length() != 0) {
                throw new SQLException(
                        Messages.get("error.statement.badsql"), "07000");
            }

            sql = tmp[0];
            sqlWord = tmp[2];
        } else {
            // Escape processing turned off so
            // see if we can extract "insert" from start of statement
            sql = sql.trim();
            if (sql.length() > 5) {
                sqlWord = sql.substring(0,6).toLowerCase();
            }
        }

        if (autoGeneratedKeys == RETURN_GENERATED_KEYS) {
            returnKeys = "insert".equals(sqlWord);
        } else if (autoGeneratedKeys == NO_GENERATED_KEYS) {
            returnKeys = false;
        } else {
            throw new SQLException(
                    Messages.get("error.generic.badoption",
                            Integer.toString(autoGeneratedKeys),
                            "autoGeneratedKeys"),
                    "HY092");
        }

        if (returnKeys) {
            if (connection.getServerType() == Driver.SQLSERVER
                    && connection.getDatabaseMajorVersion() >= 8) {
                sql += " SELECT SCOPE_IDENTITY() AS ID";
            } else {
                sql += " SELECT @@IDENTITY AS ID";
            }
        }

        return executeSQL(sql, null, null, returnKeys, update,
                !update && useCursor(returnKeys, sqlWord));
    }

    /**
     * Determines whether a cursor should be used based on the requested result
     * set type and concurrency, whether a cursor name has been set, the
     * <code>useCursors</code> connection property has been set, the first
     * word in the SQL query is either SELECT or EXEC/EXECUTE and no generated
     * keys are returned.
     *
     * @param returnKeys indicates whether keys will be returned by the query
     * @param sqlWord    the first word in the SQL query; can be
     *                   <code>null</code> if the caller is
     *                   {@link #executeQuery}
     * @return <code>true</code> if a cursor should be used, <code>false</code>
     *         if not
     */
    protected boolean useCursor(boolean returnKeys, String sqlWord) {
        return (resultSetType != ResultSet.TYPE_FORWARD_ONLY
                    || resultSetConcurrency != ResultSet.CONCUR_READ_ONLY
                    || connection.getUseCursors()
                    || cursorName != null)
                && !returnKeys
                && (sqlWord == null || "select".equals(sqlWord) || sqlWord.startsWith("exec"));
    }

    /**
     * Retrieve the default fetch size for this statement.
     *
     * @return the default fetch size for a new <code>ResultSet</code>
     */
    int getDefaultFetchSize() {
        return (0 < this.maxRows && this.maxRows < DEFAULT_FETCH_SIZE)
                ? this.maxRows : DEFAULT_FETCH_SIZE;
    }

// ------------------ java.sql.Statement methods ----------------------

    public int getFetchDirection() throws SQLException {
        checkOpen();

        return this.fetchDirection;
    }

    public int getFetchSize() throws SQLException {
        checkOpen();

        return this.fetchSize;
    }

    public int getMaxFieldSize() throws SQLException {
        checkOpen();

        return this.maxFieldSize;
    }

    public int getMaxRows() throws SQLException {
        checkOpen();

        return this.maxRows;
    }

    public int getQueryTimeout() throws SQLException {
        checkOpen();

        return this.queryTimeout;
    }

    public int getResultSetConcurrency() throws SQLException {
        checkOpen();

        return this.resultSetConcurrency;
    }

    public int getResultSetHoldability() throws SQLException {
        checkOpen();

        return JtdsResultSet.HOLD_CURSORS_OVER_COMMIT;
    }

    public int getResultSetType() throws SQLException {
        checkOpen();

        return resultSetType;
    }

    public int getUpdateCount() throws SQLException {
        checkOpen();

        return updateCount;
    }

    public void cancel() throws SQLException {
        checkOpen();

        if (tds != null) {
            tds.cancel(false);
        }
    }

    public void clearBatch() throws SQLException {
        checkOpen();

        if (batchValues != null) {
            batchValues.clear();
        }
    }

    public void clearWarnings() throws SQLException {
        checkOpen();

        messages.clearWarnings();
    }

    public void close() throws SQLException {
        if (!closed) {
            SQLException closeEx = null;
            try {
                closeAllResultSets();
            } catch (SQLException ex) {
                if (!"HYT00".equals(ex.getSQLState())
                        && !"HY008".equals(ex.getSQLState())) {
                    // Only throw exceptions not caused by cancels or timeouts
                    closeEx = ex;
                }
            } finally {
                SQLException releaseEx = null;
                try {
                    if (!connection.isClosed()) {
                        connection.releaseTds(tds);
                    }
                    // Check for server side errors
                    tds.getMessages().checkErrors();
                } catch (SQLException ex) {
                    // Remember any exception thrown
                    releaseEx = ex;
                    // Queue up any result set close exceptions
                    if (closeEx != null) {
                        releaseEx.setNextException(closeEx);
                    }
                } finally {
                    // Clean up everything
                    closed = true;
                    tds = null;
                    connection.removeStatement(this);
                    connection = null;

                    // Re-throw any caught exception
                    if (releaseEx != null) {
                        throw releaseEx;
                    }
                }
            }
            // Throw any exception caught during result set close
            if (closeEx != null) {
                throw closeEx;
            }
        }
    }

    public boolean getMoreResults() throws SQLException {
        checkOpen();

        return getMoreResults(CLOSE_ALL_RESULTS);
    }

    /**
     * Execute batch of SQL Statements.
     * <p/>
     * The JDBC3 standard says that the behavior of this method must be
     * consistent for any DBMS. As Sybase (and to a lesser extent SQL Server)
     * will sometimes continue after a batch execution error, the only way to
     * comply with the standard is to always return an array of update counts
     * the same size as the batch list. Slots in the array beyond the last
     * executed statement are set to <code>EXECUTE_FAILED</code>. <p/>
     *
     * There is a problem with certain statements, returning more update counts
     * than there are batch operations. (see bug [])
     *
     * @return update counts as an <code>int[]</code>
     */
    public int[] executeBatch()
            throws SQLException, BatchUpdateException {
        checkOpen();
        initialize();

        if (batchValues == null || batchValues.size() == 0) {
            return new int[0];
        }

        int size = batchValues.size();
        int executeSize = connection.getBatchSize();
        executeSize = (executeSize == 0) ? Integer.MAX_VALUE : executeSize;
        SQLException sqlEx;
        ArrayList counts = new ArrayList(size);

        try {
            // Lock the connection, making sure the batch executes atomically. This is especially important in the
            // case of prepared statement batches (where we don't want the prepares rolled back before being executed)
            // but should also provide some level of sanity in the general case.
            synchronized (connection) {
                if (connection.getServerType() == Driver.SYBASE
                    && connection.getTdsVersion() == Driver.TDS50) {
                    sqlEx = executeSybaseBatch(size, executeSize, counts);
                } else {
                    sqlEx = executeMSBatch(size, executeSize, counts);
                }
            }

            // Ensure array is the same size as the original statement list
            int updateCounts[] = new int[size];
            // Copy the update counts into the int array
            int results = counts.size();
            for (int i = 0; i < results && i < size; i++) {
                updateCounts[i] = ((Integer) counts.get(i)).intValue();
            }
            // Pad any remaining slots with EXECUTE_FAILED
            for (int i = results; i < updateCounts.length; i++) {
                updateCounts[i] = EXECUTE_FAILED.intValue();
            }

            // See if we should return an exception
            if (sqlEx != null) {
                BatchUpdateException batchEx =
                        new BatchUpdateException(sqlEx.getMessage(),
                                                 sqlEx.getSQLState(),
                                                 sqlEx.getErrorCode(),
                                                 updateCounts);
                // Chain any other exceptions
                batchEx.setNextException(sqlEx.getNextException());
                throw batchEx;
            }
            return updateCounts;
        } catch (BatchUpdateException ex) {
            // If it's a BatchUpdateException let it go
            throw ex;
        } catch (SQLException ex) {
            // An SQLException can only occur while sending the batch
            // (getBatchCounts() doesn't throw SQLExceptions), so we have to
            // end the batch and return the partial results
            // FIXME What should we send here to flush out the batch?
            // Come to think of it, is there any circumstance under which this
            // could actually happen without the connection getting closed?
            // No counts will have been returned either as last packet will not
            // have been sent.
            throw new BatchUpdateException(ex.getMessage(), ex.getSQLState(),
                    ex.getErrorCode(), new int[0]);
        } finally {
            clearBatch();
        }
    }

    public void setFetchDirection(int direction) throws SQLException {
        checkOpen();
        switch (direction) {
        case ResultSet.FETCH_UNKNOWN:
        case ResultSet.FETCH_REVERSE:
        case ResultSet.FETCH_FORWARD:
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

        if (rows < 0) {
            throw new SQLException(
                    Messages.get("error.generic.optltzero", "setFetchSize"),
                    "HY092");
        } else if (maxRows > 0 && rows > maxRows) {
            throw new SQLException(
                    Messages.get("error.statement.gtmaxrows"), "HY092");
        }
        if (rows == 0) {
            rows = getDefaultFetchSize();
        }
        this.fetchSize = rows;
    }

    public void setMaxFieldSize(int max) throws SQLException {
        checkOpen();

        if (max < 0) {
            throw new SQLException(
                Messages.get("error.generic.optltzero", "setMaxFieldSize"),
                    "HY092");
        }

        maxFieldSize = max;
    }

    public void setMaxRows(int max) throws SQLException {
        checkOpen();

        if (max < 0) {
            throw new SQLException(
                Messages.get("error.generic.optltzero", "setMaxRows"),
                    "HY092");
        }
        if (max > 0 && max < this.fetchSize) {
            // Just for consistency with setFetchSize()
            this.fetchSize = max;
        }
        this.maxRows = max;
    }

    public void setQueryTimeout(int seconds) throws SQLException {
        checkOpen();

        if (seconds < 0) {
            throw new SQLException(
                Messages.get("error.generic.optltzero", "setQueryTimeout"),
                    "HY092");
        }

        this.queryTimeout = seconds;
    }

    public boolean getMoreResults(int current) throws SQLException {
        checkOpen();

        switch (current) {
            case CLOSE_ALL_RESULTS:
                updateCount = -1;
                closeAllResultSets();
                break;
            case CLOSE_CURRENT_RESULT:
                updateCount = -1;
                closeCurrentResultSet();
                break;
            case KEEP_CURRENT_RESULT:
                updateCount = -1;
                // If there is an open result set it is transferred to
                // the list of open result sets. For JtdsResultSet
                // result sets we cache the remaining data. For CachedResultSet
                // result sets the data is already cached.
                if (openResultSets == null) {
                    openResultSets = new ArrayList();
                }
                if (currentResult instanceof MSCursorResultSet
                        || currentResult instanceof CachedResultSet) {
                    // NB. Due to restrictions on the way API cursors are
                    // created, MSCursorResultSet can never be followed by
                    // any other result sets, update counts or return variables.
                    openResultSets.add(currentResult);
                } else if (currentResult != null) {
                    currentResult.cacheResultSetRows();
                    openResultSets.add(currentResult);
                }
                currentResult = null;
                break;
            default:
                throw new SQLException(
                        Messages.get("error.generic.badoption",
                                Integer.toString(current),
                                "current"),
                        "HY092");
        }

        // Check for server side errors
        messages.checkErrors();

        // Dequeue any results
        if (!resultQueue.isEmpty() || processResults(false, false)) {
            Object nextResult = resultQueue.removeFirst();

            // Next result is an update count
            if (nextResult instanceof Integer) {
                updateCount = ((Integer) nextResult).intValue();
                return false;
            }

            // Next result is a ResultSet. Set currentResult and remove it.
            currentResult = (JtdsResultSet) nextResult;
            return true;
        } else {
            return false;
        }
    }

    public void setEscapeProcessing(boolean enable) throws SQLException {
        checkOpen();

        this.escapeProcessing = enable;
    }

    public int executeUpdate(String sql) throws SQLException {
        return executeUpdate(sql, NO_GENERATED_KEYS);
    }

    public void addBatch(String sql) throws SQLException {
        checkOpen();

        if (sql == null) {
            throw new NullPointerException();
        }

        if (batchValues == null) {
            batchValues = new ArrayList();
        }

        if (escapeProcessing) {
            String tmp[] = SQLParser.parse(sql, null, connection, false);

            if (tmp[1].length() != 0) {
                throw new SQLException(
                        Messages.get("error.statement.badsql"), "07000");
            }

            sql = tmp[0];
        }

        batchValues.add(sql);
    }

    public void setCursorName(String name) throws SQLException {
        checkOpen();
        this.cursorName = name;
        if (name != null) {
            // Reset statement type to JDBC 1 default.
            this.resultSetType = ResultSet.TYPE_FORWARD_ONLY;
            this.fetchSize = 1; // Needed for positioned updates
        }
    }

    public boolean execute(String sql) throws SQLException {
        checkOpen();

        return executeImpl(sql, NO_GENERATED_KEYS, false);
    }

    public int executeUpdate(String sql, int autoGeneratedKeys) throws SQLException {
        checkOpen();

        executeImpl(sql, autoGeneratedKeys, true);

        int res = getUpdateCount();
        return res == -1 ? 0 : res;
    }

    public boolean execute(String sql, int autoGeneratedKeys) throws SQLException {
        checkOpen();

        return executeImpl(sql, autoGeneratedKeys, false);
    }

    public int executeUpdate(String sql, int[] columnIndexes) throws SQLException {
        checkOpen();

        if (columnIndexes == null) {
            throw new SQLException(
                Messages.get("error.generic.nullparam", "executeUpdate"),"HY092");
        } else if (columnIndexes.length != 1) {
            throw new SQLException(
                Messages.get("error.generic.needcolindex", "executeUpdate"),"HY092");
        }

        return executeUpdate(sql, RETURN_GENERATED_KEYS);
    }

    public boolean execute(String sql, int[] columnIndexes) throws SQLException {
        checkOpen();

        if (columnIndexes == null) {
            throw new SQLException(
                Messages.get("error.generic.nullparam", "execute"),"HY092");
        } else if (columnIndexes.length != 1) {
            throw new SQLException(
                Messages.get("error.generic.needcolindex", "execute"),"HY092");
        }

        return executeImpl(sql, RETURN_GENERATED_KEYS, false);
    }

    public Connection getConnection() throws SQLException {
        checkOpen();

        return this.connection;
    }

    public ResultSet getGeneratedKeys() throws SQLException {
        checkOpen();

        if (genKeyResultSet == null) {
            String colNames[] = {"ID"};
            int    colTypes[] = {Types.INTEGER};
            //
            // Return an empty result set
            //
            CachedResultSet rs = new CachedResultSet(this, colNames, colTypes);
            rs.setConcurrency(ResultSet.CONCUR_READ_ONLY);
            genKeyResultSet = rs;
        }

        return genKeyResultSet;
    }

    public ResultSet getResultSet() throws SQLException {
        checkOpen();
        //
        if (currentResult instanceof MSCursorResultSet ||
            currentResult instanceof CachedResultSet) {
            return currentResult;
        }
        //
        // See if we are returning a forward read only resultset
        //
        if (currentResult == null ||
            (resultSetType == ResultSet.TYPE_FORWARD_ONLY &&
             resultSetConcurrency == ResultSet.CONCUR_READ_ONLY)) {
            return currentResult;
        }
        //
        // OK Now create a CachedResultSet based on the existng result set.
        //
        currentResult = new CachedResultSet(currentResult, true);

        return currentResult;
    }

    public SQLWarning getWarnings() throws SQLException {
        checkOpen();

        return messages.getWarnings();
    }

    public int executeUpdate(String sql, String[] columnNames) throws SQLException {
        checkOpen();

        if (columnNames == null) {
            throw new SQLException(
                Messages.get("error.generic.nullparam", "executeUpdate"),"HY092");
        } else if (columnNames.length != 1) {
            throw new SQLException(
                Messages.get("error.generic.needcolname", "executeUpdate"),"HY092");
        }

        return executeUpdate(sql, RETURN_GENERATED_KEYS);
    }

    public boolean execute(String sql, String[] columnNames) throws SQLException {
        checkOpen();

        if (columnNames == null) {
            throw new SQLException(
                Messages.get("error.generic.nullparam", "execute"),"HY092");
        } else if (columnNames.length != 1) {
            throw new SQLException(
                Messages.get("error.generic.needcolname", "execute"),"HY092");
        }

        return executeImpl(sql, RETURN_GENERATED_KEYS, false);
    }

    public ResultSet executeQuery(String sql) throws SQLException {
        checkOpen();
        initialize();

        if (sql == null || sql.length() == 0) {
            throw new SQLException(Messages.get("error.generic.nosql"), "HY000");
        }
        if (escapeProcessing) {
            String tmp[] = SQLParser.parse(sql, null, connection, false);

            if (tmp[1].length() != 0) {
                throw new SQLException(
                    Messages.get("error.statement.badsql"), "07000");
            }

            sql = tmp[0];
        }

        return this.executeSQLQuery(sql, null, null, useCursor(false, null));
    }

    /////// JDBC4 demarcation, do NOT put any JDBC3 code below this line ///////

    /* (non-Javadoc)
     * @see java.sql.Statement#isClosed()
     */
    public boolean isClosed() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Statement#isPoolable()
     */
    public boolean isPoolable() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Statement#setPoolable(boolean)
     */
    public void setPoolable(boolean poolable) throws SQLException {
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