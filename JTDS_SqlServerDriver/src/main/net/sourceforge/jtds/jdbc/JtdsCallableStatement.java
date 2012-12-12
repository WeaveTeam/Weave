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
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Map;

/**
 * jTDS implementation of the java.sql.CallableStatement interface.
 *<p>
 * Implementation note:
 * <ol>
 * <li>This class is a simple subclass of PreparedStatement and mainly adds support for
 * setting parameters.
 * <li>The class supports named parameters in a similar way to the
 * patch supplied by Tommy Sandstrom to the original jTDS code.
 * </ol>
 *
 * @author Mike Hutchinson
 * @version $Id: JtdsCallableStatement.java,v 1.23.2.4 2009-12-30 11:37:21 ickzon Exp $
 */
public class JtdsCallableStatement extends JtdsPreparedStatement implements CallableStatement {
    /** Last parameter retrieved was null. */
    protected boolean paramWasNull;

    /**
     * Construct a CallableStatement object.
     *
     * @param connection The connection owning this statement.
     * @param sql The SQL statement specifying the procedure to call.
     * @param resultSetType The result set type eg FORWARD_ONLY.
     * @param concurrency   The result set concurrency eg READ_ONLY.
     * @throws SQLException
     */
    JtdsCallableStatement(ConnectionJDBC2 connection, String sql, int resultSetType, int concurrency)
        throws SQLException {
        super(connection, sql, resultSetType, concurrency, false);
    }

    /**
     * Find a parameter by name.
     *
     * @param name The name of the parameter to locate.
     * @param set True if function is called from a set / register method.
     * @return The parameter index as an <code>int</code>.
     * @throws SQLException
     */
    int findParameter(String name, boolean set)
        throws SQLException {
        checkOpen();
        for (int i = 0; i < parameters.length; i++){
            if (parameters[i].name != null && parameters[i].name.equalsIgnoreCase(name))
                return i + 1;
        }

        if (set && !name.equalsIgnoreCase("@return_status")) {
            for (int i = 0; i < parameters.length; i++){
                if (parameters[i].name == null) {
                    parameters[i].name = name;

                    return i + 1;
                }
            }
        }

        throw new SQLException(Messages.get("error.callable.noparam", name), "07000");
    }

    /**
     * Retrieve the value of an output parameter.
     *
     * @param parameterIndex the ordinal position of the parameter
     * @return the parameter value as an <code>Object</code>
     * @throws SQLException if the parameter has not been set
     */
    protected Object getOutputValue(int parameterIndex)
            throws SQLException {
        checkOpen();
        ParamInfo parameter = getParameter(parameterIndex);
        if (!parameter.isOutput) {
            throw new SQLException(
                    Messages.get("error.callable.notoutput",
                            new Integer(parameterIndex)),
                    "07000");
        }
        Object value = parameter.getOutValue();
        paramWasNull = (value == null);
        return value;
    }

    /**
     * Check that this statement is still open.
     *
     * @throws SQLException if statement closed.
     */
    protected void checkOpen() throws SQLException {
        if (closed) {
            throw new SQLException(
                    Messages.get("error.generic.closed", "CallableStatement"), "HY010");
        }
    }
    
    /**
     * Execute the SQL batch on a MS server.
     * @param size the total size of the batch.
     * @param executeSize the maximum number of statements to send in one request.
     * @param counts the returned update counts.
     * @return Chained exceptions linked to a <code>SQLException</code>.
     * @throws SQLException
     */
    protected SQLException executeMSBatch(int size, int executeSize, ArrayList counts)
    throws SQLException {
        if (parameters.length == 0) {
            // No parameters so we can execute as a simple batch
            return super.executeMSBatch(size, executeSize, counts);
        }
        SQLException sqlEx = null;
        for (int i = 0; i < size;) {
            Object value = batchValues.get(i);
            ++i;
            // Execute batch now if max size reached or end of batch
            boolean executeNow = (i % executeSize == 0) || i == size;

            tds.startBatch();
            tds.executeSQL(sql, procName, (ParamInfo[]) value, false, 0, -1, -1, executeNow);

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
     * For the rare case of CallableStatement batches each statement is executed individually. This ensures that
     * problems with the server reading into the middle of a statement are avoided. See bug report [1374518] for more
     * details.
     *
     * @param size        the total size of the batch
     * @param executeSize the maximum number of statements to send in one request (ignored for this version of the
     *                    method as only one statement will be sent at a time)
     * @param counts the returned update counts
     * @return chained exceptions linked to a <code>SQLException</code>
     * @throws SQLException if a serious error occurs during execution
     */
    protected SQLException executeSybaseBatch(int size, int executeSize, ArrayList counts)
    throws SQLException
    {
        if (parameters.length == 0) {
            // No parameters so we can execute as a simple batch
            return super.executeSybaseBatch(size, executeSize, counts);
        }

        SQLException sqlEx = null;

        for (int i = 0; i < size;) {
            Object value = batchValues.get(i);
            ++i;
            tds.executeSQL(sql, procName, (ParamInfo[]) value, false, 0, -1, -1, true);

            // If the batch has been sent, process the results
            sqlEx = tds.getBatchCounts(counts, sqlEx);

            // If a serious error then we stop execution now as count
            // is too small.
            if (sqlEx != null && counts.size() != i) {
                break;
            }
        }
        return sqlEx;
    }


// ---------- java.sql.CallableStatement methods follow ----------

    public boolean wasNull() throws SQLException {
        checkOpen();

        return paramWasNull;
    }

    public byte getByte(int parameterIndex) throws SQLException {
        return ((Integer) Support.convert(this, getOutputValue(parameterIndex), java.sql.Types.TINYINT, null)).byteValue();
    }

    public double getDouble(int parameterIndex) throws SQLException {
        return ((Double) Support.convert(this, getOutputValue(parameterIndex), java.sql.Types.DOUBLE, null)).doubleValue();
    }

    public float getFloat(int parameterIndex) throws SQLException {
        return ((Float) Support.convert(this, getOutputValue(parameterIndex), java.sql.Types.REAL, null)).floatValue();
    }

    public int getInt(int parameterIndex) throws SQLException {
        return ((Integer) Support.convert(this, getOutputValue(parameterIndex), java.sql.Types.INTEGER, null)).intValue();
    }

    public long getLong(int parameterIndex) throws SQLException {
        return ((Long) Support.convert(this, getOutputValue(parameterIndex), java.sql.Types.BIGINT, null)).longValue();
    }

    public short getShort(int parameterIndex) throws SQLException {
        return ((Integer) Support.convert(this, getOutputValue(parameterIndex), java.sql.Types.SMALLINT, null)).shortValue();
    }

    public boolean getBoolean(int parameterIndex) throws SQLException {
        return ((Boolean) Support.convert(this, getOutputValue(parameterIndex), BOOLEAN, null)).booleanValue();
    }

    public byte[] getBytes(int parameterIndex) throws SQLException {
        checkOpen();
        return ((byte[]) Support.convert(this, getOutputValue(parameterIndex), java.sql.Types.VARBINARY, connection.getCharset()));
    }

    public void registerOutParameter(int parameterIndex, int sqlType) throws SQLException {
        if (sqlType == java.sql.Types.DECIMAL
            || sqlType == java.sql.Types.NUMERIC) {
            registerOutParameter(parameterIndex, sqlType, TdsData.DEFAULT_SCALE);
        } else {
            registerOutParameter(parameterIndex, sqlType, 0);
        }
    }

    public void registerOutParameter(int parameterIndex, int sqlType, int scale)
        throws SQLException {
        checkOpen();

        if (scale < 0 || scale > connection.getMaxPrecision()) {
            throw new SQLException(Messages.get("error.generic.badscale"), "HY092");
        }

        ParamInfo pi = getParameter(parameterIndex);

        pi.isOutput = true;

        if ("ERROR".equals(Support.getJdbcTypeName(sqlType))) {
            throw new SQLException(Messages.get("error.generic.badtype",
                    Integer.toString(sqlType)), "HY092");
        }

        if (sqlType == java.sql.Types.CLOB) {
            pi.jdbcType = java.sql.Types.LONGVARCHAR;
        } else if (sqlType == java.sql.Types.BLOB) {
            pi.jdbcType = java.sql.Types.LONGVARBINARY;
        } else {
            pi.jdbcType = sqlType;
        }

        pi.scale = scale;
    }

    public Object getObject(int parameterIndex) throws SQLException {
        Object value = getOutputValue(parameterIndex);

        // Don't return UniqueIdentifier objects as the user won't know how to
        // handle them
        if (value instanceof UniqueIdentifier) {
            return value.toString();
        }

        // If the user requested String/byte[] instead of LOBs, do the conversion
        if (!connection.getUseLOBs()) {
            value = Support.convertLOB(value);
        }

        return value;
    }

    public String getString(int parameterIndex) throws SQLException {
        checkOpen();
        return (String) Support.convert(this, getOutputValue(parameterIndex),
                java.sql.Types.VARCHAR, connection.getCharset());
    }

    public void registerOutParameter(int parameterIndex, int sqlType, String typeName)
        throws SQLException {
        notImplemented("CallableStatement.registerOutParameter(int, int, String");
    }

    public byte getByte(String parameterName) throws SQLException {
        return getByte(findParameter(parameterName, false));
    }

    public double getDouble(String parameterName) throws SQLException {
        return getDouble(findParameter(parameterName, false));
    }

    public float getFloat(String parameterName) throws SQLException {
        return getFloat(findParameter(parameterName, false));
    }

    public int getInt(String parameterName) throws SQLException {
        return getInt(findParameter(parameterName, false));
    }

    public long getLong(String parameterName) throws SQLException {
        return getLong(findParameter(parameterName, false));
    }

    public short getShort(String parameterName) throws SQLException {
        return getShort(findParameter(parameterName, false));
    }

    public boolean getBoolean(String parameterName) throws SQLException {
        return getBoolean(findParameter(parameterName, false));
    }

    public byte[] getBytes(String parameterName) throws SQLException {
        return getBytes(findParameter(parameterName, false));
    }

    public void setByte(String parameterName, byte x) throws SQLException {
        setByte(findParameter(parameterName, true), x);
    }

    public void setDouble(String parameterName, double x) throws SQLException {
        setDouble(findParameter(parameterName, true), x);
    }

    public void setFloat(String parameterName, float x) throws SQLException {
        setFloat(findParameter(parameterName, true), x);
    }

    public void registerOutParameter(String parameterName, int sqlType)
        throws SQLException {
        registerOutParameter(findParameter(parameterName, true), sqlType);
    }

    public void setInt(String parameterName, int x) throws SQLException {
        setInt(findParameter(parameterName, true), x);
    }

    public void setNull(String parameterName, int sqlType) throws SQLException {
        setNull(findParameter(parameterName, true), sqlType);
    }

    public void registerOutParameter(String parameterName, int sqlType, int scale)
        throws SQLException {
        registerOutParameter(findParameter(parameterName, true), sqlType, scale);
    }

    public void setLong(String parameterName, long x) throws SQLException {
        setLong(findParameter(parameterName, true), x);
    }

    public void setShort(String parameterName, short x) throws SQLException {
        setShort(findParameter(parameterName, true), x);
    }

    public void setBoolean(String parameterName, boolean x) throws SQLException {
        setBoolean(findParameter(parameterName, true), x);
    }

    public void setBytes(String parameterName, byte[] x) throws SQLException {
        setBytes(findParameter(parameterName, true), x);
    }

    public BigDecimal getBigDecimal(int parameterIndex) throws SQLException {
        return (BigDecimal) Support.convert(this,
                getOutputValue(parameterIndex), java.sql.Types.DECIMAL, null);
    }

    public BigDecimal getBigDecimal(int parameterIndex, int scale) throws SQLException {
        BigDecimal bd = (BigDecimal) Support.convert(this,
                getOutputValue(parameterIndex), java.sql.Types.DECIMAL, null);

        return bd.setScale(scale);
    }

    public URL getURL(int parameterIndex) throws SQLException {
        checkOpen();
        String url = (String) Support.convert(this,
                getOutputValue(parameterIndex), java.sql.Types.VARCHAR,
                connection.getCharset());

        try {
            return new java.net.URL(url);
        } catch (MalformedURLException e) {
            throw new SQLException(Messages.get("error.resultset.badurl", url), "22000");
        }
    }

    public Array getArray(int parameterIndex) throws SQLException {
        notImplemented("CallableStatement.getArray");
        return null;
    }

    public Blob getBlob(int parameterIndex) throws SQLException {
        byte[] value = getBytes(parameterIndex);

        if (value == null) {
            return null;
        }

        return new BlobImpl(connection, value);
    }

    public Clob getClob(int parameterIndex) throws SQLException {
        String value = getString(parameterIndex);

        if (value == null) {
            return null;
        }

        return new ClobImpl(connection, value);
    }

    public Date getDate(int parameterIndex) throws SQLException {
        return (java.sql.Date) Support.convert(this,
                getOutputValue(parameterIndex), java.sql.Types.DATE, null);
    }

    public Ref getRef(int parameterIndex) throws SQLException {
        notImplemented("CallableStatement.getRef");
        return null;
    }

    public Time getTime(int parameterIndex) throws SQLException {
        return (Time) Support.convert(this, getOutputValue(parameterIndex), java.sql.Types.TIME, null);
    }

    public Timestamp getTimestamp(int parameterIndex) throws SQLException {
        return (Timestamp) Support.convert(this, getOutputValue(parameterIndex), java.sql.Types.TIMESTAMP, null);
    }

    public void setAsciiStream(String parameterName, InputStream x, int length)
        throws SQLException {
        setAsciiStream(findParameter(parameterName, true), x, (int)length);
    }

    public void setBinaryStream(String parameterName, InputStream x, int length)
        throws SQLException {
        setBinaryStream(findParameter(parameterName, true), x, length);
    }

    public void setCharacterStream(String parameterName, Reader reader, int length)
        throws SQLException {
        setCharacterStream(findParameter(parameterName, true), reader, length);
    }

    public Object getObject(String parameterName) throws SQLException {
        return getObject(findParameter(parameterName, false));
    }

    public void setObject(String parameterName, Object x) throws SQLException {
        setObject(findParameter(parameterName, true), x);
    }

    public void setObject(String parameterName, Object x, int targetSqlType)
        throws SQLException {
        setObject(findParameter(parameterName, true), x, targetSqlType);
    }

    public void setObject(String parameterName, Object x, int targetSqlType, int scale)
        throws SQLException {
        setObject(findParameter(parameterName, true), x, targetSqlType, scale);
    }

    public Object getObject(int parameterIndex, Map map) throws SQLException {
        notImplemented("CallableStatement.getObject(int, Map)");
        return null;
    }

    public String getString(String parameterName) throws SQLException {
        return getString(findParameter(parameterName, false));
    }

    public void registerOutParameter(String parameterName, int sqlType, String typeName)
        throws SQLException {
        notImplemented("CallableStatement.registerOutParameter(String, int, String");
    }

    public void setNull(String parameterName, int sqlType, String typeName)
        throws SQLException {
        notImplemented("CallableStatement.setNull(String, int, String");
    }

    public void setString(String parameterName, String x) throws SQLException {
        setString(findParameter(parameterName, true), x);
    }

    public BigDecimal getBigDecimal(String parameterName) throws SQLException {
        return getBigDecimal(findParameter(parameterName, false));
    }

    public void setBigDecimal(String parameterName, BigDecimal x)
        throws SQLException {
        setBigDecimal(findParameter(parameterName, true), x);
    }

    public URL getURL(String parameterName) throws SQLException {
        return getURL(findParameter(parameterName, false));
    }

    public void setURL(String parameterName, URL x) throws SQLException {
        setObject(findParameter(parameterName, true), x);
    }

    public Array getArray(String parameterName) throws SQLException {
        return getArray(findParameter(parameterName, false));
    }

    public Blob getBlob(String parameterName) throws SQLException {
        return getBlob(findParameter(parameterName, false));
    }

    public Clob getClob(String parameterName) throws SQLException {
        return getClob(findParameter(parameterName, false));
    }

    public Date getDate(String parameterName) throws SQLException {
        return getDate(findParameter(parameterName, false));
    }

    public void setDate(String parameterName, Date x) throws SQLException {
        setDate(findParameter(parameterName, true), x);
    }

    public Date getDate(int parameterIndex, Calendar cal) throws SQLException {
        java.sql.Date date = getDate(parameterIndex);

        if (date != null && cal != null) {
            date = new java.sql.Date(Support.timeToZone(date, cal));
        }

        return date;
    }

    public Ref getRef(String parameterName) throws SQLException {
        return getRef(findParameter(parameterName, false));
    }

    public Time getTime(String parameterName) throws SQLException {
        return getTime(findParameter(parameterName, false));
    }

    public void setTime(String parameterName, Time x) throws SQLException {
        setTime(findParameter(parameterName, true), x);
    }

    public Time getTime(int parameterIndex, Calendar cal) throws SQLException {
        java.sql.Time time = getTime(parameterIndex);

        if (time != null && cal != null) {
            time = new java.sql.Time(Support.timeToZone(time, cal));
        }

        return time;
    }

    public Timestamp getTimestamp(String parameterName) throws SQLException {
        return getTimestamp(findParameter(parameterName, false));
    }

    public void setTimestamp(String parameterName, Timestamp x) throws SQLException {
        setTimestamp(findParameter(parameterName, true), x);
    }

    public Timestamp getTimestamp(int parameterIndex, Calendar cal)
        throws SQLException {
        Timestamp timestamp = getTimestamp(parameterIndex);

        if (timestamp != null && cal != null) {
            timestamp = new Timestamp(Support.timeToZone(timestamp, cal));
        }

        return timestamp;
    }

    public Object getObject(String parameterName, Map map) throws SQLException {
         return getObject(findParameter(parameterName, false), map);
    }

    public Date getDate(String parameterName, Calendar cal) throws SQLException {
        return getDate(findParameter(parameterName, false), cal);
    }

    public Time getTime(String parameterName, Calendar cal) throws SQLException {
        return getTime(findParameter(parameterName, false), cal);
    }

    public Timestamp getTimestamp(String parameterName, Calendar cal)
        throws SQLException {
        return getTimestamp(findParameter(parameterName, false), cal);
    }

    public void setDate(String parameterName, Date x, Calendar cal)
        throws SQLException {
        setDate(findParameter(parameterName, true), x, cal);
    }

    public void setTime(String parameterName, Time x, Calendar cal)
        throws SQLException {
        setTime(findParameter(parameterName, true), x, cal);
    }

    public void setTimestamp(String parameterName, Timestamp x, Calendar cal)
        throws SQLException {
        setTimestamp(findParameter(parameterName, true), x, cal);
    }
    
    /////// JDBC4 demarcation, do NOT put any JDBC3 code below this line ///////

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#getCharacterStream(int)
     */
    public Reader getCharacterStream(int parameterIndex) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#getCharacterStream(java.lang.String)
     */
    public Reader getCharacterStream(String parameterName) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#getNCharacterStream(int)
     */
    public Reader getNCharacterStream(int parameterIndex) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#getNCharacterStream(java.lang.String)
     */
    public Reader getNCharacterStream(String parameterName) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#getNClob(int)
     */
    public NClob getNClob(int parameterIndex) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#getNClob(java.lang.String)
     */
    public NClob getNClob(String parameterName) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#getNString(int)
     */
    public String getNString(int parameterIndex) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#getNString(java.lang.String)
     */
    public String getNString(String parameterName) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#getRowId(int)
     */
    public RowId getRowId(int parameterIndex) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#getRowId(java.lang.String)
     */
    public RowId getRowId(String parameterName) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#getSQLXML(int)
     */
    public SQLXML getSQLXML(int parameterIndex) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#getSQLXML(java.lang.String)
     */
    public SQLXML getSQLXML(String parameterName) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setAsciiStream(java.lang.String, java.io.InputStream)
     */
    public void setAsciiStream(String parameterName, InputStream x)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setAsciiStream(java.lang.String, java.io.InputStream, long)
     */
    public void setAsciiStream(String parameterName, InputStream x, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setBinaryStream(java.lang.String, java.io.InputStream)
     */
    public void setBinaryStream(String parameterName, InputStream x)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setBinaryStream(java.lang.String, java.io.InputStream, long)
     */
    public void setBinaryStream(String parameterName, InputStream x, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setBlob(java.lang.String, java.sql.Blob)
     */
    public void setBlob(String parameterName, Blob x) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setBlob(java.lang.String, java.io.InputStream)
     */
    public void setBlob(String parameterName, InputStream inputStream)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setBlob(java.lang.String, java.io.InputStream, long)
     */
    public void setBlob(String parameterName, InputStream inputStream,
            long length) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setCharacterStream(java.lang.String, java.io.Reader)
     */
    public void setCharacterStream(String parameterName, Reader reader)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setCharacterStream(java.lang.String, java.io.Reader, long)
     */
    public void setCharacterStream(String parameterName, Reader reader,
            long length) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setClob(java.lang.String, java.sql.Clob)
     */
    public void setClob(String parameterName, Clob x) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setClob(java.lang.String, java.io.Reader)
     */
    public void setClob(String parameterName, Reader reader)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setClob(java.lang.String, java.io.Reader, long)
     */
    public void setClob(String parameterName, Reader reader, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setNCharacterStream(java.lang.String, java.io.Reader)
     */
    public void setNCharacterStream(String parameterName, Reader value)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setNCharacterStream(java.lang.String, java.io.Reader, long)
     */
    public void setNCharacterStream(String parameterName, Reader value,
            long length) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setNClob(java.lang.String, java.sql.NClob)
     */
    public void setNClob(String parameterName, NClob value) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setNClob(java.lang.String, java.io.Reader)
     */
    public void setNClob(String parameterName, Reader reader)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setNClob(java.lang.String, java.io.Reader, long)
     */
    public void setNClob(String parameterName, Reader reader, long length)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setNString(java.lang.String, java.lang.String)
     */
    public void setNString(String parameterName, String value)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setRowId(java.lang.String, java.sql.RowId)
     */
    public void setRowId(String parameterName, RowId x) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.CallableStatement#setSQLXML(java.lang.String, java.sql.SQLXML)
     */
    public void setSQLXML(String parameterName, SQLXML xmlObject)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.PreparedStatement#setAsciiStream(int, java.io.InputStream)
     */
    public void setAsciiStream(int parameterIndex, InputStream x)
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