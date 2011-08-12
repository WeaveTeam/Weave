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

import java.io.InputStream;
import java.io.Reader;
import java.math.BigDecimal;
import java.sql.*;
import java.util.Calendar;

import net.sourceforge.jtds.jdbc.*;

/**
 * This class would be better implemented as a java.lang.reflect.Proxy.  However, this
 * feature was not added until 1.3 and reflection performance was not improved until 1.4.
 * Since the driver still needs to be compatible with 1.2 and 1.3 this class is used
 * to delegate the calls to a prepared statement with minimal overhead.
 *
 * @version $Id: PreparedStatementProxy.java,v 1.3.4.3 2009-12-30 08:45:34 ickzon Exp $
 */
public class PreparedStatementProxy
extends StatementProxy
implements PreparedStatement {
    private JtdsPreparedStatement _preparedStatement;
    
    PreparedStatementProxy(ConnectionProxy connection, JtdsPreparedStatement preparedStatement) {
        super(connection, preparedStatement);
        
        _preparedStatement = preparedStatement;
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public ResultSet executeQuery() throws SQLException {
        validateConnection();

        try {
            return _preparedStatement.executeQuery();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return null;
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public int executeUpdate() throws SQLException {
        validateConnection();

        try {
            return _preparedStatement.executeUpdate();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return Integer.MIN_VALUE;
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setNull(int parameterIndex, int sqlType) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setNull(parameterIndex, sqlType);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setBoolean(int parameterIndex, boolean x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setBoolean(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setByte(int parameterIndex, byte x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setByte(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setShort(int parameterIndex, short x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setShort(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setInt(int parameterIndex, int x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setInt(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setLong(int parameterIndex, long x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setLong(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setFloat(int parameterIndex, float x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setFloat(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setDouble(int parameterIndex, double x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setDouble(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setBigDecimal(int parameterIndex, BigDecimal x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setBigDecimal(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setString(int parameterIndex, String x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setString(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setBytes(int parameterIndex, byte[] x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setBytes(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setDate(int parameterIndex, java.sql.Date x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setDate(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setTime(int parameterIndex, java.sql.Time x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setTime(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setTimestamp(int parameterIndex, java.sql.Timestamp x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setTimestamp(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setAsciiStream(int parameterIndex, java.io.InputStream x, int length) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setAsciiStream(parameterIndex, x, length);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setUnicodeStream(int parameterIndex, java.io.InputStream x, int length) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setUnicodeStream(parameterIndex, x, length);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setBinaryStream(int parameterIndex, java.io.InputStream x, int length) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setBinaryStream(parameterIndex, x, length);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void clearParameters() throws SQLException {
        validateConnection();

        try {
            _preparedStatement.clearParameters();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setObject(int parameterIndex, Object x, int targetSqlType, int scale) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setObject(parameterIndex, x, targetSqlType, scale);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setObject(int parameterIndex, Object x, int targetSqlType) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setObject(parameterIndex, x, targetSqlType);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setObject(int parameterIndex, Object x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setObject(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public boolean execute() throws SQLException {
        validateConnection();

        try {
            return _preparedStatement.execute();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return false;
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void addBatch() throws SQLException {
        validateConnection();

        try {
            _preparedStatement.addBatch();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setCharacterStream(int parameterIndex, java.io.Reader x, int length) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setCharacterStream(parameterIndex, x, length);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setRef(int parameterIndex, Ref x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setRef(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setBlob(int parameterIndex, Blob x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setBlob(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setClob(int parameterIndex, Clob x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setClob(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setArray(int parameterIndex, Array x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setArray(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public ResultSetMetaData getMetaData() throws SQLException {
        validateConnection();

        try {
            return _preparedStatement.getMetaData();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return null;
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setDate(int parameterIndex, java.sql.Date x, Calendar cal) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setDate(parameterIndex, x, cal);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setTime(int parameterIndex, java.sql.Time x, Calendar cal) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setTime(parameterIndex, x, cal);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setTimestamp(int parameterIndex, java.sql.Timestamp x, Calendar cal) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setTimestamp(parameterIndex, x, cal);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setNull (int parameterIndex, int sqlType, String typeName) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setNull(parameterIndex, sqlType, typeName);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public void setURL(int parameterIndex, java.net.URL x) throws SQLException {
        validateConnection();

        try {
            _preparedStatement.setURL(parameterIndex, x);
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
    }

    /**
     * Delgates calls to the prepared statement; SQLExceptions thrown from the
     * prepared statement will cause an event to be fired on the connection
     * pool listeners.
     *
     * @throws SQLException if an error occurs
     */
    public ParameterMetaData getParameterMetaData() throws SQLException {
        validateConnection();

        try {
            return _preparedStatement.getParameterMetaData();
        } catch (SQLException sqlException) {
            processSQLException(sqlException);
        }
        
        return null;
    }

    /////// JDBC4 demarcation, do NOT put any JDBC3 code below this line ///////

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setAsciiStream(int, java.io.InputStream)
     */
    public void setAsciiStream(int parameterIndex, InputStream x)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setAsciiStream(int, java.io.InputStream, long)
     */
    public void setAsciiStream(int parameterIndex, InputStream x, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setBinaryStream(int, java.io.InputStream)
     */
    public void setBinaryStream(int parameterIndex, InputStream x)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setBinaryStream(int, java.io.InputStream, long)
     */
    public void setBinaryStream(int parameterIndex, InputStream x, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setBlob(int, java.io.InputStream)
     */
    public void setBlob(int parameterIndex, InputStream inputStream)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setBlob(int, java.io.InputStream, long)
     */
    public void setBlob(int parameterIndex, InputStream inputStream, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setCharacterStream(int, java.io.Reader)
     */
    public void setCharacterStream(int parameterIndex, Reader reader)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setCharacterStream(int, java.io.Reader, long)
     */
    public void setCharacterStream(int parameterIndex, Reader reader,
            long length) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setClob(int, java.io.Reader)
     */
    public void setClob(int parameterIndex, Reader reader) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setClob(int, java.io.Reader, long)
     */
    public void setClob(int parameterIndex, Reader reader, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setNCharacterStream(int, java.io.Reader)
     */
    public void setNCharacterStream(int parameterIndex, Reader value)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setNCharacterStream(int, java.io.Reader, long)
     */
    public void setNCharacterStream(int parameterIndex, Reader value,
            long length) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setNClob(int, java.sql.NClob)
     */
    public void setNClob(int parameterIndex, NClob value) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setNClob(int, java.io.Reader)
     */
    public void setNClob(int parameterIndex, Reader reader) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setNClob(int, java.io.Reader, long)
     */
    public void setNClob(int parameterIndex, Reader reader, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setNString(int, java.lang.String)
     */
    public void setNString(int parameterIndex, String value)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setRowId(int, java.sql.RowId)
     */
    public void setRowId(int parameterIndex, RowId x) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setSQLXML(int, java.sql.SQLXML)
     */
    public void setSQLXML(int parameterIndex, SQLXML xmlObject)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

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