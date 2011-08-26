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
package net.sourceforge.jtds.jdbcx.proxy;

import java.sql.*;

import net.sourceforge.jtds.jdbc.*;

/**
 * This class would be better implemented as a java.lang.reflect.Proxy.  However, this
 * feature was not added until 1.3 and reflection performance was not improved until 1.4.
 * Since the driver still needs to be compatible with 1.2 and 1.3 this class is used
 * to delegate the calls to a statement with minimal overhead.
 *
 * @version $Id: StatementProxy.java,v 1.4.4.3 2009-12-30 08:45:34 ickzon Exp $
 */
public class StatementProxy implements Statement {
    private ConnectionProxy _connection;
    private JtdsStatement _statement;

    StatementProxy(ConnectionProxy connection, JtdsStatement statement) {
        _connection = connection;
        _statement = statement;
    }
    
    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public ResultSet executeQuery(String sql) throws SQLException {
        validateConnection();

        try {
            return _statement.executeQuery(sql);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return null;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int executeUpdate(String sql) throws SQLException {
        validateConnection();

        try {
            return _statement.executeUpdate(sql);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void close() throws SQLException {
        validateConnection();

        try {
            _statement.close();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int getMaxFieldSize() throws SQLException {
        validateConnection();

        try {
            return _statement.getMaxFieldSize();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }
    
    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setMaxFieldSize(int max) throws SQLException {
        validateConnection();

        try {
            _statement.setMaxFieldSize(max);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int getMaxRows() throws SQLException {
        validateConnection();

        try {
            return _statement.getMaxRows();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setMaxRows(int max) throws SQLException {
        validateConnection();

        try {
            _statement.setMaxRows(max);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setEscapeProcessing(boolean enable) throws SQLException {
        validateConnection();

        try {
            _statement.setEscapeProcessing(enable);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int getQueryTimeout() throws SQLException {
        validateConnection();

        try {
            return _statement.getQueryTimeout();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setQueryTimeout(int seconds) throws SQLException {
        validateConnection();

        try {
            _statement.setQueryTimeout(seconds);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void cancel() throws SQLException {
        validateConnection();

        try {
            _statement.cancel();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public SQLWarning getWarnings() throws SQLException {
        validateConnection();

        try {
            return _statement.getWarnings();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return null;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void clearWarnings() throws SQLException {
        validateConnection();

        try {
            _statement.clearWarnings();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setCursorName(String name) throws SQLException {
        validateConnection();

        try {
            _statement.setCursorName(name);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }
    
    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public boolean execute(String sql) throws SQLException {
        validateConnection();

        try {
            return _statement.execute(sql);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return false;
    }
    
    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public ResultSet getResultSet() throws SQLException {
        validateConnection();

        try {
            return _statement.getResultSet();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return null;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int getUpdateCount() throws SQLException {
        validateConnection();

        try {
            return _statement.getUpdateCount();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public boolean getMoreResults() throws SQLException {
        validateConnection();

        try {
            return _statement.getMoreResults();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return false;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setFetchDirection(int direction) throws SQLException {
        validateConnection();

        try {
            _statement.setFetchDirection(direction);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int getFetchDirection() throws SQLException {
        validateConnection();

        try {
            return _statement.getFetchDirection();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setFetchSize(int rows) throws SQLException {
        validateConnection();

        try {
            _statement.setFetchSize(rows);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }
  
    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int getFetchSize() throws SQLException {
        validateConnection();

        try {
            return _statement.getFetchSize();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int getResultSetConcurrency() throws SQLException {
        validateConnection();

        try {
            return _statement.getResultSetConcurrency();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int getResultSetType() throws SQLException {
        validateConnection();

        try {
            return _statement.getResultSetType();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void addBatch(String sql) throws SQLException {
        validateConnection();

        try {
            _statement.addBatch(sql);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void clearBatch() throws SQLException {
        validateConnection();

        try {
            _statement.clearBatch();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int[] executeBatch() throws SQLException {
        validateConnection();

        try {
            return _statement.executeBatch();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return null;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public Connection getConnection()  throws SQLException {
        validateConnection();

        try {
            return _statement.getConnection();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return null;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public boolean getMoreResults(int current) throws SQLException {
        validateConnection();

        try {
            return _statement.getMoreResults(current);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return false;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public ResultSet getGeneratedKeys() throws SQLException {
        validateConnection();

        try {
            return _statement.getGeneratedKeys();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return null;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int executeUpdate(String sql, int autoGeneratedKeys) throws SQLException {
        validateConnection();

        try {
            return _statement.executeUpdate(sql, autoGeneratedKeys);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int executeUpdate(String sql, int[] columnIndexes) throws SQLException {
        validateConnection();

        try {
            return _statement.executeUpdate(sql, columnIndexes);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int executeUpdate(String sql, String[] columnNames) throws SQLException {
        validateConnection();

        try {
            return _statement.executeUpdate(sql, columnNames);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public boolean execute(String sql, int autoGeneratedKeys) throws SQLException {
        validateConnection();

        try {
            return _statement.execute(sql, autoGeneratedKeys);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return false;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public boolean execute(String sql, int[] columnIndexes) throws SQLException {
        validateConnection();

        try {
            return _statement.execute(sql, columnIndexes);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return false;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public boolean execute(String sql, String[] columnNames) throws SQLException {
        validateConnection();

        try {
            return _statement.execute(sql, columnNames);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return false;
    }

    /**
     * Delgates calls to the statement; SQLExceptions thrown from the statement
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int getResultSetHoldability() throws SQLException {
        validateConnection();

        try {
            return _statement.getResultSetHoldability();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Validates the connection state.
     */
    protected void validateConnection() throws SQLException {
        if (_connection.isClosed()) {
            throw new SQLException(Messages.get("error.conproxy.noconn"), "HY010");
        }
    }

    /**
     * Processes SQLExceptions.
     */
    protected void processSQLException(SQLException sqlException) throws SQLException {
        _connection.processSQLException(sqlException);

        throw sqlException;
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