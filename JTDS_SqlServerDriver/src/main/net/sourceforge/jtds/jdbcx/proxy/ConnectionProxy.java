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
import java.util.Map;
import java.util.Properties;

import net.sourceforge.jtds.jdbc.*;
import net.sourceforge.jtds.jdbcx.*;

/**
 * This class would be better implemented as a java.lang.reflect.Proxy.  However, this
 * feature was not added until 1.3 and reflection performance was not improved until 1.4.
 * Since the driver still needs to be compatible with 1.2 and 1.3 this class is used
 * to delegate the calls to the connection with minimal overhead.
 *
 * @version $Id: ConnectionProxy.java,v 1.7.2.3 2009-12-30 08:45:34 ickzon Exp $
 */
public class ConnectionProxy implements Connection {
    private PooledConnection _pooledConnection;
    private ConnectionJDBC2 _connection;
    private boolean _closed;

    /**
     * Constructs a new connection proxy.
     */
    public ConnectionProxy(PooledConnection pooledConnection,
                           Connection connection) {
        _pooledConnection = pooledConnection;
        _connection = (ConnectionJDBC2) connection;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void clearWarnings() throws SQLException {
        validateConnection();

        try {
            _connection.clearWarnings();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     */
    public void close() {
        if (_closed) {
            return;
        }

        _pooledConnection.fireConnectionEvent(true, null);
        _closed = true;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void commit() throws SQLException {
        validateConnection();

        try {
            _connection.commit();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public Statement createStatement() throws SQLException {
        validateConnection();

        try {
            return new StatementProxy(this, (JtdsStatement) _connection.createStatement());
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public Statement createStatement(int resultSetType, int resultSetConcurrency) throws SQLException {
        validateConnection();

        try {
            return new StatementProxy(this, (JtdsStatement) _connection.createStatement(resultSetType, resultSetConcurrency));
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public Statement createStatement(int resultSetType, int resultSetConcurrency, int resultSetHoldability) throws SQLException {
        validateConnection();

        try {
            return new StatementProxy(this, (JtdsStatement) _connection.createStatement(resultSetType, resultSetConcurrency, resultSetHoldability));
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public boolean getAutoCommit() throws SQLException {
        validateConnection();

        try {
            return _connection.getAutoCommit();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return false;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public String getCatalog() throws SQLException {
        validateConnection();

        try {
            return _connection.getCatalog();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int getHoldability() throws SQLException {
        validateConnection();

        try {
            return _connection.getHoldability();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int getTransactionIsolation() throws SQLException {
        validateConnection();

        try {
            return _connection.getTransactionIsolation();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public Map getTypeMap() throws SQLException {
        validateConnection();

        try {
            return _connection.getTypeMap();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public SQLWarning getWarnings() throws SQLException {
        validateConnection();

        try {
            return _connection.getWarnings();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public DatabaseMetaData getMetaData() throws SQLException {
        validateConnection();

        try {
            return _connection.getMetaData();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public boolean isClosed() throws SQLException {
        if (_closed) {
            return true;
        }

        try {
            return _connection.isClosed();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return _closed;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public boolean isReadOnly() throws SQLException {
        validateConnection();

        try {
            return _connection.isReadOnly();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return false;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public String nativeSQL(String sql) throws SQLException {
        validateConnection();

        try {
            return _connection.nativeSQL(sql);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public CallableStatement prepareCall(String sql) throws SQLException {
        validateConnection();

        try {
            return new CallableStatementProxy(this, (JtdsCallableStatement) _connection.prepareCall(sql));
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public CallableStatement prepareCall(String sql, int resultSetType, int resultSetConcurrency) throws SQLException {
        validateConnection();

        try {
            return new CallableStatementProxy(this, (JtdsCallableStatement) _connection.prepareCall(sql, resultSetType, resultSetConcurrency));
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public CallableStatement prepareCall(String sql, int resultSetType, int resultSetConcurrency, int resultSetHoldability) throws SQLException {
        validateConnection();

        try {
            return new CallableStatementProxy(this, (JtdsCallableStatement) _connection.prepareCall(sql, resultSetType, resultSetConcurrency, resultSetHoldability));
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public PreparedStatement prepareStatement(String sql) throws SQLException {
        validateConnection();

        try {
            return new PreparedStatementProxy(this, (JtdsPreparedStatement) _connection.prepareStatement(sql));
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public PreparedStatement prepareStatement(String sql, int autoGeneratedKeys) throws SQLException {
        validateConnection();

        try {
            return new PreparedStatementProxy(this, (JtdsPreparedStatement) _connection.prepareStatement(sql, autoGeneratedKeys));
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public PreparedStatement prepareStatement(String sql, int[] columnIndexes) throws SQLException {
        validateConnection();

        try {
            return new PreparedStatementProxy(this, (JtdsPreparedStatement) _connection.prepareStatement(sql, columnIndexes));
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public PreparedStatement prepareStatement(String sql, String[] columnNames) throws SQLException {
        validateConnection();

        try {
            return new PreparedStatementProxy(this, (JtdsPreparedStatement) _connection.prepareStatement(sql, columnNames));
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public PreparedStatement prepareStatement(String sql, int resultSetType, int resultSetConcurrency) throws SQLException {
        validateConnection();

        try {
            return new PreparedStatementProxy(this, (JtdsPreparedStatement) _connection.prepareStatement(sql, resultSetType, resultSetConcurrency));
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public PreparedStatement prepareStatement(String sql, int resultSetType, int resultSetConcurrency, int resultSetHoldability) throws SQLException {
        validateConnection();

        try {
            return new PreparedStatementProxy(this, (JtdsPreparedStatement) _connection.prepareStatement(sql, resultSetType, resultSetConcurrency, resultSetHoldability));
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void releaseSavepoint(Savepoint savepoint) throws SQLException {
        validateConnection();

        try {
            _connection.releaseSavepoint(savepoint);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void rollback() throws SQLException {
        validateConnection();

        try {
            _connection.rollback();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void rollback(Savepoint savepoint) throws SQLException {
        validateConnection();

        try {
            _connection.rollback(savepoint);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setAutoCommit(boolean autoCommit) throws SQLException {
        validateConnection();

        try {
            _connection.setAutoCommit(autoCommit);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setCatalog(String catalog) throws SQLException {
        validateConnection();

        try {
            _connection.setCatalog(catalog);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setHoldability(int holdability) throws SQLException {
        validateConnection();

        try {
            _connection.setHoldability(holdability);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setReadOnly(boolean readOnly) throws SQLException {
        validateConnection();

        try {
            _connection.setReadOnly(readOnly);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public Savepoint setSavepoint() throws SQLException {
        validateConnection();

        try {
            return _connection.setSavepoint();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public Savepoint setSavepoint(String name) throws SQLException {
        validateConnection();

        try {
            return _connection.setSavepoint(name);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }

        return null;
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setTransactionIsolation(int level) throws SQLException {
        validateConnection();

        try {
            _connection.setTransactionIsolation(level);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the connection; SQLExceptions thrown from the connection
     * will cause an event to be fired on the connection pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setTypeMap(Map map) throws SQLException {
        validateConnection();

        try {
            _connection.setTypeMap(map);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Validates the connection state.
     */
    private void validateConnection() throws SQLException {
        if (_closed) {
            throw new SQLException(Messages.get("error.conproxy.noconn"), "HY010");
        }
    }

    /**
     * Processes SQLExceptions.
     */
    void processSQLException(SQLException sqlException) throws SQLException {
        _pooledConnection.fireConnectionEvent(false, sqlException);

        throw sqlException;
    }

    /**
     * Closes the proxy, releasing the connection.
     */
    protected void finalize() {
        close();
    }

    /////// JDBC4 demarcation, do NOT put any JDBC3 code below this line ///////

    /* (non-Javadoc)
     * @see java.sql.Connection#createArrayOf(java.lang.String, java.lang.Object[])
     */
    public Array createArrayOf(String typeName, Object[] elements)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Connection#createBlob()
     */
    public Blob createBlob() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Connection#createClob()
     */
    public Clob createClob() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Connection#createNClob()
     */
    public NClob createNClob() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Connection#createSQLXML()
     */
    public SQLXML createSQLXML() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Connection#createStruct(java.lang.String, java.lang.Object[])
     */
    public Struct createStruct(String typeName, Object[] attributes)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Connection#getClientInfo()
     */
    public Properties getClientInfo() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Connection#getClientInfo(java.lang.String)
     */
    public String getClientInfo(String name) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Connection#isValid(int)
     */
    public boolean isValid(int timeout) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Connection#setClientInfo(java.util.Properties)
     */
    public void setClientInfo(Properties properties)
            throws SQLClientInfoException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Connection#setClientInfo(java.lang.String, java.lang.String)
     */
    public void setClientInfo(String name, String value)
            throws SQLClientInfoException {
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