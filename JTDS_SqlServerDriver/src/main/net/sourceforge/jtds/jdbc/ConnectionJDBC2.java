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

import java.lang.ref.WeakReference;
import java.sql.*;
import java.net.UnknownHostException;
import java.io.*;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;
import java.util.HashSet;
import java.util.Random;

import net.sourceforge.jtds.jdbc.cache.*;
import net.sourceforge.jtds.util.*;

/**
 * jTDS implementation of the java.sql.Connection interface.
 * <p>
 * Implementation notes:
 * <ol>
 * <li>Environment setting code carried over from old jTDS otherwise
 *     generally a new implementation of Connection.
 * <li>Connection properties and SQLException text messages are loaded from
 *     a properties file.
 * <li>Character set choices are also loaded from a resource file and the original
 *     Encoder class has gone.
 * <li>Prepared SQL statements are converted to procedures in the prepareSQL method.
 * <li>Use of Stored procedures is optional and controlled via connection property.
 * <li>This Connection object maintains a table of weak references to associated
 *     statements. This allows the connection object to control the statements (for
 *     example to close them) but without preventing them being garbage collected in
 *     a pooled environment.
 * </ol>
 *
 * @author Mike Hutchinson
 * @author Alin Sinpalean
 * @version $Id: ConnectionJDBC2.java,v 1.119.2.12 2009-12-30 11:37:21 ickzon Exp $
 */
public class ConnectionJDBC2 implements java.sql.Connection {
    /**
     * SQL query to determine the server charset on Sybase.
     */
    private static final String SYBASE_SERVER_CHARSET_QUERY
            = "select name from master.dbo.syscharsets where id ="
            + " (select value from master.dbo.sysconfigures where config=131)";

    /**
     * SQL query to determine the server charset on MS SQL Server 6.5.
     */
    private static final String SQL_SERVER_65_CHARSET_QUERY
            = "select name from master.dbo.syscharsets where id ="
            + " (select csid from master.dbo.syscharsets, master.dbo.sysconfigures"
            + " where config=1123 and id = value)";

    /** Sybase initial connection string. */
    private static final String SYBASE_INITIAL_SQL =     "SET TRANSACTION ISOLATION LEVEL 1\r\n" +
                                                         "SET CHAINED OFF\r\n" +
                                                         "SET QUOTED_IDENTIFIER ON\r\n"+
                                                         "SET TEXTSIZE 2147483647";
    /**
     * SQL Server initial connection string. Also contains a
     * <code>SELECT @@MAX_PRECISION</code> query to retrieve
     * the maximum precision for DECIMAL/NUMERIC data. */
    private static final String SQL_SERVER_INITIAL_SQL = "SELECT @@MAX_PRECISION\r\n" +
                                                         "SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n" +
                                                         "SET IMPLICIT_TRANSACTIONS OFF\r\n" +
                                                         "SET QUOTED_IDENTIFIER ON\r\n"+
                                                         "SET TEXTSIZE 2147483647";
    /**
     * SQL Server custom transaction isolation level.
     */
    public static final int TRANSACTION_SNAPSHOT = 4096;

    /*
     * Conection attributes
     */

    /** The orginal connection URL. */
    private final String url;
    /** The server host name. */
    private String serverName;
    /** The server port number. */
    private int portNumber;
    /** The make of SQL Server (sybase/microsoft). */
    private int serverType;
    /** The SQL Server instance. */
    private String instanceName;
    /** The requested database name. */
    private String databaseName;
    /** The current database name. */
    private String currentDatabase;
    /** The Windows Domain name. */
    private String domainName;
    /** The database user ID. */
    private String user;
    /** The user password. */
    private String password;
    /** The server character set. */
    private String serverCharset;
    /** The application name. */
    private String appName;
    /** The program name. */
    private String progName;
    /** Workstation ID. */
    private String wsid;
    /** The server message language. */
    private String language;
    /** The client MAC Address. */
    private String macAddress;
    /** The server protocol version. */
    private int tdsVersion;
    /** The network TCP/IP socket. */
    private final SharedSocket socket;
    /** The cored TDS protocol object. */
    private final TdsCore baseTds;
    /** The initial network packet size. */
    private int netPacketSize = TdsCore.MIN_PKT_SIZE;
    /** User requested packet size. */
    private int packetSize;
    /** SQL Server 2000 collation. */
    private byte collation[];
    /** True if user specifies an explicit charset. */
    private boolean charsetSpecified;
    /** The database product name eg SQL SERVER. */
    private String databaseProductName;
    /** The product version eg 11.92. */
    private String databaseProductVersion;
    /** The major version number eg 11. */
    private int databaseMajorVersion;
    /** The minor version number eg 92. */
    private int databaseMinorVersion;
    /** True if this connection is closed. */
    private boolean closed;
    /** True if this connection is read only. */
    private boolean readOnly;
    /** List of statements associated with this connection. */
    private final ArrayList statements = new ArrayList();
    /** Default transaction isolation level. */
    private int transactionIsolation = java.sql.Connection.TRANSACTION_READ_COMMITTED;
    /** Default auto commit state. */
    private boolean autoCommit = true;
    /** Diagnostc messages for this connection. */
    private final SQLDiagnostic messages;
    /** Connection's current rowcount limit. */
    private int rowCount;
    /** Connection's current maximum field size limit. */
    private int textSize;
    /** Maximum decimal precision. */
    private int maxPrecision = TdsData.DEFAULT_PRECISION_38; // Sybase default
    /** Stored procedure unique ID number. */
    private int spSequenceNo = 1;
    /** Cursor unique ID number. */
    private int cursorSequenceNo = 1;
    /** Procedures in this transaction. */
    private final ArrayList procInTran = new ArrayList();
    /** Java charset for encoding. */
    private CharsetInfo charsetInfo;
    /** Method for preparing SQL used in Prepared Statements. */
    private int prepareSql;
    /** The amount of LOB data to buffer in memory. */
    private long lobBuffer;
    /** The maximum number of statements to keep open. */
    private int maxStatements;
    /** Statement cache.*/
    private StatementCache statementCache;
    /** Send parameters as unicode. */
    private boolean useUnicode = true;
    /** Use named pipe IPC instead of TCP/IP sockets. */
    private boolean namedPipe;
    /** Only return the last update count. */
    private boolean lastUpdateCount;
    /** TCP_NODELAY */
    private boolean tcpNoDelay = true;
    /** Login timeout value in seconds or 0. */
    private int loginTimeout;
    /** Sybase capability mask.*/
    private int sybaseInfo;
    /** True if running distributed transaction. */
    private boolean xaTransaction;
    /** Current emulated XA State eg start/end/prepare etc. */
    private int xaState;
    /** Current XA Transaction ID. */
    private Object xid;
    /** True if driver should emulate distributed transactions. */
    private boolean xaEmulation = true;
    /** Mutual exclusion lock to control access to connection. */
    private final Semaphore mutex = new Semaphore(1);
    /** Socket timeout value in seconds or 0. */
    private int socketTimeout;
    /** True to enable socket keep alive. */
    private boolean socketKeepAlive;
    /** The process ID to report to a server when connecting. */
    private static Integer processId;
    /** SSL setting. */
    private String ssl;
    /** The maximum size of a batch. */
    private int batchSize;
    /** Use metadata cache for prepared statements. */
    private boolean useMetadataCache;
    /** Use fast forward cursors for forward only result sets. */
    private boolean useCursors;
    /** The directory to buffer data to */
    private File bufferDir;
    /** The global buffer memory limit for all connections (in kilobytes). */
    private int bufferMaxMemory;
    /** The minimum number of packets per statement to buffer to memory. */
    private int bufferMinPackets;
    /** Map large types (IMAGE and TEXT/NTEXT) to LOBs by default. */
    private boolean useLOBs;
    /** A cached <code>TdsCore</code> instance to reuse on new statements. */
    private TdsCore cachedTds;
    /** The local address to bind to when connecting to a database via TCP/IP. */
    private String bindAddress;
    /** Force use of jCIFS library on Windows when connecting via named pipes. */
    private boolean useJCIFS;
    /** When doing NTLM authentication, send NTLMv2 response rather than regular response */
    private boolean useNTLMv2 = false;

    /** the number of currently open connections */
    private static int connections;

    /**
     * Default constructor.
     * <p/>
     * Used for testing.
     */
    private ConnectionJDBC2() {
        connections++;
        url = null;
        socket = null;
        baseTds = null;
        messages = null;
    }

    /**
     * Create a new database connection.
     *
     * @param url The connection URL starting jdbc:jtds:.
     * @param info The additional connection properties.
     * @throws SQLException
     */
    ConnectionJDBC2(String url, Properties info)
            throws SQLException {
        connections++;
        this.url = url;
        //
        // Extract properties into instance variables
        //
        unpackProperties(info);
        this.messages = new SQLDiagnostic(serverType);
        //
        // Get the instance port, if it is specified.
        // Named pipes use instance names differently.
        //
        if (instanceName.length() > 0 && !namedPipe) {
            final MSSqlServerInfo msInfo = new MSSqlServerInfo(serverName);

            portNumber = msInfo.getPortForInstance(instanceName);

            if (portNumber == -1) {
                throw new SQLException(
                                      Messages.get("error.msinfo.badinst", serverName, instanceName),
                                      "08003");
            }
        }

        SharedSocket.setMemoryBudget(bufferMaxMemory * 1024);
        SharedSocket.setMinMemPkts(bufferMinPackets);
        SQLWarning warn;

        Object timer = null;
        boolean loginError = false;
        try {
            if (loginTimeout > 0) {
                // Start a login timer
                timer = TimerThread.getInstance().setTimer(loginTimeout * 1000,
                        new TimerThread.TimerListener() {
                            public void timerExpired() {
                                if (socket != null) {
                                    socket.forceClose();
                                }
                            }
                        });
            }

            if (namedPipe) {
                // Use named pipe
                socket = createNamedPipe(this);
            } else {
                // Use plain TCP/IP socket
                socket = new SharedSocket(this);
            }

            if (timer != null && TimerThread.getInstance().hasExpired(timer)) {
                // If the timer has expired during the connection phase, close
                // the socket and throw an exception
                socket.forceClose();
                throw new IOException("Login timed out");
            }

            if ( charsetSpecified ) {
                loadCharset(serverCharset);
            } else {
                // Need a default charset to process login packets for TDS 4.2/5.0
                // Will discover the actual serverCharset later
                loadCharset("iso_1");
                serverCharset = ""; // But don't send charset name to server!
            }

            //
            // Create TDS protocol object
            //
            baseTds = new TdsCore(this, messages);

            //
            // Negotiate SSL connection if required
            //
            if (tdsVersion >= Driver.TDS80 && !namedPipe) {
                baseTds.negotiateSSL(instanceName, ssl);
            }

            //
            // Now try to login
            //
            baseTds.login(serverName,
                          databaseName,
                          user,
                          password,
                          domainName,
                          serverCharset,
                          appName,
                          progName,
                          wsid,
                          language,
                          macAddress,
                          packetSize);

            //
            // Save any login warnings so that they will not be overwritten by
            // the internal configuration SQL statements e.g. setCatalog() etc.
            //
            warn = messages.warnings;

            // Update the tdsVersion with the value in baseTds. baseTds sets
            // the TDS version for the socket and there are no other objects
            // with cached TDS versions at this point.
            tdsVersion = baseTds.getTdsVersion();
            if (tdsVersion < Driver.TDS70 && databaseName.length() > 0) {
                // Need to select the default database
                setCatalog(databaseName);
            }
             
            // If charset is still unknown and the collation is not set either,
            // determine the charset by querying (we're using Sybase or SQL Server
            // 6.5)
            if ((serverCharset == null || serverCharset.length() == 0)
                    && collation == null) {
                loadCharset(determineServerCharset());
            }

            // Initial database settings.
            // Sets: auto commit mode  = true
            //       transaction isolation = read committed.
            if (serverType == Driver.SYBASE) {
                baseTds.submitSQL(SYBASE_INITIAL_SQL);
            } else {
                // Also discover the maximum decimal precision:  28 (default)
                // or 38 for MS SQL Server 6.5/7, or 38 for 2000 and later.
                Statement stmt = this.createStatement();
                ResultSet rs = stmt.executeQuery(SQL_SERVER_INITIAL_SQL);

                if (rs.next()) {
                    maxPrecision = rs.getByte(1);
                }

                rs.close();
                stmt.close();
            }
        } catch (UnknownHostException e) {
            loginError = true;
            throw Support.linkException(
                    new SQLException(Messages.get("error.connection.badhost",
                            e.getMessage()), "08S03"), e);
        } catch (IOException e) {
            loginError = true;
            if (loginTimeout > 0 && e.getMessage().indexOf("timed out") >= 0) {
                throw Support.linkException(
                        new SQLException(Messages.get("error.connection.timeout"), "HYT01"), e);
            }
            throw Support.linkException(
                    new SQLException(Messages.get("error.connection.ioerror",
                            e.getMessage()), "08S01"), e);
        } catch (SQLException e) {
            loginError = true;
            if (loginTimeout > 0 && e.getMessage().indexOf("socket closed") >= 0) {
                throw Support.linkException(
                        new SQLException(Messages.get("error.connection.timeout"), "HYT01"), e);
            }
            throw e;
        } catch (RuntimeException e) {
            loginError = true;
            throw e;
        }
        finally {
            // fix for bug [1755448], socket not closed after login error
            if (loginError) {
                 close();
            } else if (timer != null) {
                // Cancel loginTimer
                TimerThread.getInstance().cancelTimer(timer);
            }
        }

        //
        // Restore any login warnings so that the user can retrieve them
        // by calling Connection.getWarnings()
        //
        messages.warnings = warn;
    }

    /**
     * Ensure all resources are released.
     */
    protected void finalize() throws Throwable {
        try {
            close();
        } catch (Exception e) {
            // ignore any error
        } finally {
            super.finalize();
        }
    }

    /**
     * Creates a {@link SharedSocket} object representing a connection to a named
     * pipe.  If the <code>os.name</code> system property starts with "Windows"
     * (case-insensitive) and the <code>useJCIFS</code> parameter is
     * <code>false</code>, a {@link SharedLocalNamedPipe} object is created.
     * Else a {@link SharedNamedPipe} is created which uses
     * <a href="http://jcifs.samba.org/">jCIFS</a> to provide a pure-Java
     * implementation of Windows named pipes.
     * <p>
     * This method will retry for <code>loginTimeout</code> seconds to create a
     * named pipe if an <code>IOException</code> continues to be thrown stating,
     * "All pipe instances are busy".  If <code>loginTimeout</code> is set to
     * zero (e.g., not set), a default of 20 seconds will be used.
     *
     * @param connection the connection object
     * @return an object representing the named pipe connection
     * @throws IOException on error; if an <code>IOException</code> is thrown with
     * a message stating "All pipe instances are busy", then the method timed out
     * after <code>loginTimeout</code> milliseconds attempting to create a named pipe.
     */
    private SharedSocket createNamedPipe(ConnectionJDBC2 connection) throws IOException {

        final long loginTimeout = connection.getLoginTimeout();
        final long retryTimeout = (loginTimeout > 0 ? loginTimeout : 20) * 1000;
        final long startLoginTimeout = System.currentTimeMillis();
        final Random random = new Random(startLoginTimeout);
        final boolean isWindowsOS = Support.isWindowsOS();

        SharedSocket socket = null;
        IOException lastIOException = null;
        int exceptionCount = 0;

        do {
            try {
                if (isWindowsOS && !connection.getUseJCIFS()) {
                    socket = new SharedLocalNamedPipe(connection);
                }
                else {
                    socket = new SharedNamedPipe(connection);
                }
            }
            catch (IOException ioe) {
                exceptionCount++;
                lastIOException = ioe;
                if (ioe.getMessage().toLowerCase().indexOf("all pipe instances are busy") >= 0) {
                    // Per a Microsoft knowledgebase article, wait 200 ms to 1 second each time
                    // we get an "All pipe instances are busy" error.
                    // http://support.microsoft.com/default.aspx?scid=KB;EN-US;165189
                    final int randomWait = random.nextInt(800) + 200;
                    if (Logger.isActive()) {
                        Logger.println("Retry #" + exceptionCount + " Wait " + randomWait + " ms: " +
                                       ioe.getMessage());
                    }
                    try {
                        Thread.sleep(randomWait);
                    }
                    catch (InterruptedException ie) {
                        // Do nothing; retry again
                    }
                }
                else {
                    throw ioe;
                }
            }
        } while (socket == null && (System.currentTimeMillis() - startLoginTimeout) < retryTimeout);

        if (socket == null) {
            final IOException ioException = new IOException("Connection timed out to named pipe");
            Support.linkException(ioException, lastIOException);
            throw ioException;
        }

        return socket;
    }


    /**
     * Retrive the shared socket.
     *
     * @return The <code>SharedSocket</code> object.
     */
    SharedSocket getSocket() {
        return this.socket;
    }

    /**
     * Retrieve the TDS protocol version.
     *
     * @return The TDS version as an <code>int</code>.
     */
    int getTdsVersion() {
        return this.tdsVersion;
    }

    /**
     * Retrieves the next unique stored procedure name.
     * <p>Notes:
     * <ol>
     * <li>Some versions of Sybase require an id with
     * a length of &lt;= 10.
     * <li>The format of this name works for sybase and Microsoft
     * and allows for 16M names per session.
     * <li>The leading '#jtds' indicates this is a temporary procedure and
     * the '#' is removed by the lower level TDS5 routines.
     * </ol>
     * Not synchronized because it's only called from the synchronized
     * {@link #prepareSQL} method.
     *
     * @return the next temporary SP name as a <code>String</code>
     */
    String getProcName() {
        String seq = "000000" + Integer.toHexString(spSequenceNo++).toUpperCase();

        return "#jtds" + seq.substring(seq.length() - 6, seq.length());
    }

    /**
     * Retrieves the next unique cursor name.
     *
     * @return the next cursor name as a <code>String</code>
     */
    synchronized String getCursorName() {
        String seq = "000000" + Integer.toHexString(cursorSequenceNo++).toUpperCase();

        return "_jtds" + seq.substring(seq.length() - 6, seq.length());
    }

    /**
     * Try to convert the SQL statement into a statement prepare.
     * <p>
     * Synchronized because it accesses the procedure cache and the
     * <code>baseTds</code>, but the method call also needs to made in a
     * <code>synchronized (connection)</code> block together with the execution
     * (if the prepared statement is actually executed) to ensure the
     * transaction isn't rolled back between this method call and the actual
     * execution.
     *
     * @param pstmt        the target prepared statement
     * @param sql          the SQL statement to prepare
     * @param params       the parameters
     * @param returnKeys   indicates whether the statement will return
     *                     generated keys
     * @param cursorNeeded indicates whether a cursor prepare is needed
     * @return the SQL procedure name as a <code>String</code> or null if the
     *         SQL cannot be prepared
     */
    synchronized String prepareSQL(JtdsPreparedStatement pstmt,
                                   String sql,
                                   ParamInfo[] params,
                                   boolean returnKeys,
                                   boolean cursorNeeded)
            throws SQLException {
        if (prepareSql == TdsCore.UNPREPARED
                || prepareSql == TdsCore.EXECUTE_SQL) {
            return null; // User selected not to use procs
        }

        if (serverType == Driver.SYBASE) {
            if (tdsVersion != Driver.TDS50) {
                return null; // No longer support stored procs with 4.2
            }

            if (returnKeys) {
                return null; // Sybase cannot use @@IDENTITY in proc
            }

            if (cursorNeeded) {
                //
                // We are going to use the CachedResultSet so there is
                // no point in preparing the SQL as it will be discarded
                // in favour of a version with "FOR BROWSE" appended.
                //
                return null;
            }
        }

        //
        // Check parameters set and obtain native types
        //
        for (int i = 0; i < params.length; i++) {
            if (!params[i].isSet) {
                throw new SQLException(Messages.get("error.prepare.paramnotset",
                                                    Integer.toString(i+1)),
                                       "07000");
            }

            TdsData.getNativeType(this, params[i]);

            if (serverType == Driver.SYBASE) {
                if ("text".equals(params[i].sqlType)
                    || "image".equals(params[i].sqlType)) {
                    return null; // Sybase does not support text/image params
                }
            }
        }

        String key = Support.getStatementKey(sql, params, serverType,
                getCatalog(), autoCommit, cursorNeeded);

        //
        // See if we have already built this one
        //
        ProcEntry proc = (ProcEntry) statementCache.get(key);

        if (proc != null) {
            //
            // Yes found in cache OK
            //

            // If already used by the statement, decrement use count
            if (pstmt.handles != null && pstmt.handles.contains(proc)) {
                proc.release();
            }

            pstmt.setColMetaData(proc.getColMetaData());
            if (serverType == Driver.SYBASE) {
                pstmt.setParamMetaData(proc.getParamMetaData());
            }
        } else {
            //
            // No, so create the stored procedure now
            //
            proc = new ProcEntry();

            if (serverType == Driver.SQLSERVER) {
                proc.setName(
                        baseTds.microsoftPrepare(
                                sql, params, cursorNeeded,
                                pstmt.getResultSetType(),
                                pstmt.getResultSetConcurrency()));

                if (proc.toString() == null) {
                    proc.setType(ProcEntry.PREP_FAILED);
                } else if (prepareSql == TdsCore.TEMPORARY_STORED_PROCEDURES) {
                    proc.setType(ProcEntry.PROCEDURE);
                } else {
                    proc.setType((cursorNeeded) ? ProcEntry.CURSOR : ProcEntry.PREPARE);
                    // Meta data may be returned by sp_prepare
                    proc.setColMetaData(baseTds.getColumns());
                    pstmt.setColMetaData(proc.getColMetaData());
                }
                // TODO Find some way of getting parameter meta data for MS
            } else {
                proc.setName(baseTds.sybasePrepare(sql, params));

                if (proc.toString() == null) {
                    proc.setType(ProcEntry.PREP_FAILED);
                } else {
                    proc.setType(ProcEntry.PROCEDURE);
                }
                // Sybase gives us lots of useful information about the result set
                proc.setColMetaData(baseTds.getColumns());
                proc.setParamMetaData(baseTds.getParameters());
                pstmt.setColMetaData(proc.getColMetaData());
                pstmt.setParamMetaData(proc.getParamMetaData());
            }
            // OK we have built a proc so add it to the cache.
            addCachedProcedure(key, proc);
        }
        // Add the handle to the prepared statement so that the handles
        // can be used to clean up the statement cache properly when the
        // prepared statement is closed.
        if (pstmt.handles == null) {
            pstmt.handles = new HashSet(10);
        }

        pstmt.handles.add(proc);

        // Give the user the name will be null if prepare failed
        return proc.toString();
    }

    /**
     * Add a stored procedure to the cache.
     * <p>
     * Not explicitly synchronized because it's only called by synchronized
     * methods.
     *
     * @param key The signature of the procedure to cache.
     * @param proc The stored procedure descriptor.
     */
    void addCachedProcedure(String key, ProcEntry proc) {
        statementCache.put(key, proc);

        if (!autoCommit
                && proc.getType() == ProcEntry.PROCEDURE
                && serverType == Driver.SQLSERVER) {
            procInTran.add(key);
        }
    }

    /**
     * Remove a stored procedure from the cache.
     * <p>
     * Not explicitly synchronized because it's only called by synchronized
     * methods.
     *
     * @param key The signature of the procedure to remove from the cache.
     */
    void removeCachedProcedure(String key) {
        statementCache.remove(key);

        if (!autoCommit) {
            procInTran.remove(key);
        }
    }

    /**
     * Retrieves the maximum statement cache size.
     *
     * @return the maximum statement cache size
     */
    int getMaxStatements() {
        return maxStatements;
    }

    /**
     * Retrieves the server type.
     *
     * @return the server type as an <code>int</code> where 1 == SQLSERVER and
     *         2 == SYBASE.
     */
    public int getServerType() {
        return this.serverType;
    }

    /**
     * Sets the network packet size.
     *
     * @param size the new packet size
     */
    void setNetPacketSize(int size) {
        this.netPacketSize = size;
    }

    /**
     * Retrieves the network packet size.
     *
     * @return the packet size as an <code>int</code>
     */
    int getNetPacketSize() {
        return this.netPacketSize;
    }

    /**
     * Retrieves the current row count on this connection.
     *
     * @return the row count as an <code>int</code>
     */
    int getRowCount() {
        return this.rowCount;
    }

    /**
     * Sets the current row count on this connection.
     *
     * @param count the new row count
     */
    void setRowCount(int count) {
        rowCount = count;
    }

    /**
     * Retrieves the current maximum textsize on this connection.
     *
     * @return the maximum textsize as an <code>int</code>
     */
    public int getTextSize() {
        return textSize;
    }

    /**
     * Sets the current maximum textsize on this connection.
     *
     * @param textSize the new maximum textsize
     */
    public void setTextSize(int textSize) {
        this.textSize = textSize;
    }

    /**
     * Retrieves the status of the lastUpdateCount flag.
     *
     * @return the lastUpdateCount flag as a <code>boolean</code>
     */
    boolean getLastUpdateCount() {
        return this.lastUpdateCount;
    }

    /**
     * Retrieves the maximum decimal precision.
     *
     * @return the precision as an <code>int</code>
     */
    int getMaxPrecision() {
        return this.maxPrecision;
    }

    /**
     * Retrieves the LOB buffer size.
     *
     * @return the LOB buffer size as a <code>long</code>
     */
    long getLobBuffer() {
        return this.lobBuffer;
    }

    /**
     * Retrieves the Prepared SQL method.
     *
     * @return the Prepared SQL method
     */
    int getPrepareSql() {
        return this.prepareSql;
    }

    /**
     * Retrieves the batch size to be used internally.
     *
     * @return the batch size as an <code>int</code>
     */
    int getBatchSize() {
        return this.batchSize;
    }

    /**
     * Retrieves the boolean indicating whether metadata caching
     * is enabled.
     *
     * @return <code>true</code> if metadata caching is enabled,
     *         <code>false</code> if caching is disabled
     */
    boolean getUseMetadataCache() {
        return this.useMetadataCache;
    }

    /**
     * Indicates whether fast forward only cursors should be used for forward
     * only result sets.
     *
     * @return <code>true</code> if fast forward cursors are requested
     */
    boolean getUseCursors() {
        return this.useCursors;
    }

    /**
     * Indicates whether large types (IMAGE and TEXT/NTEXT) should be mapped by
     * default to LOB types or <code>String</code> and <code>byte[]</code>
     * respectively.
     *
     * @return <code>true</code> if the default mapping should be to LOBs,
     *         <code>false</code> otherwise
     */
    boolean getUseLOBs() {
        return this.useLOBs;
    }

    /**
     * Indicates whether, when doing Windows authentication to an MS SQL server,
     * NTLMv2 should be used. When this is set to "false", LM and NTLM responses
     * are sent to the server, which should work fine in most cases. However,
     * some servers are configured to require LMv2 and NTLMv2. In these rare
     * cases, this property should be set to "true".
     */
    boolean getUseNTLMv2() {
        return this.useNTLMv2;
    }

    /**
     * Retrieves the application name for this connection.
     *
     * @return the application name
     */
    String getAppName() {
        return this.appName;
    }

    /**
     * Retrieves the bind address for this connection.
     *
     * @return the bind address
     */
    String getBindAddress() {
        return this.bindAddress;
    }

    /**
     * Returns the directory where data should be buffered to.
     *
     * @return the directory where data should be buffered to.
     */
    File getBufferDir() {
        return this.bufferDir;
    }

    /**
     * Retrieves the maximum amount of memory in Kb to buffer for <em>all</em> connections.
     *
     * @return the maximum amount of memory in Kb to buffer for <em>all</em> connections
     */
    int getBufferMaxMemory() {
        return this.bufferMaxMemory;
    }

    /**
     * Retrieves the minimum number of packets to buffer per {@link Statement} for this connection.
     *
     * @return the minimum number of packets to buffer per {@link Statement}
     */
    int getBufferMinPackets() {
        return this.bufferMinPackets;
    }

    /**
     * Retrieves the database name for this connection.
     *
     * @return the database name
     */
    String getDatabaseName() {
        return this.databaseName;
    }

    /**
     * Retrieves the domain name for this connection.
     *
     * @return the domain name
     */
    String getDomainName() {
        return this.domainName;
    }

    /**
     * Retrieves the instance name for this connection.
     *
     * @return the instance name
     */
    String getInstanceName() {
        return this.instanceName;
    }

    /**
     * Retrieves the login timeout for this connection.
     *
     * @return the login timeout
     */
    int getLoginTimeout() {
        return this.loginTimeout;
    }

    /**
     * Retrieves the socket timeout for this connection.
     *
     * @return the socket timeout
     */
    int getSocketTimeout() {
        return this.socketTimeout;
    }

    /**
     * Retrieves whether to enable socket keep alive.
     *
     * @return <code>true</code> if the socket keep alive is enabled
     */
    boolean getSocketKeepAlive() {
        return this.socketKeepAlive;
    }

    /**
     * Retrieves the process ID to send to a server when a connection is
     * established.
     *
     * @return the process ID
     */
    int getProcessId() {
        return ConnectionJDBC2.processId.intValue();
    }

    /**
     * Retrieves the MAC (ethernet) address for this connection.
     *
     * @return the MAC (ethernet) address
     */
    String getMacAddress() {
        return this.macAddress;
    }

    /**
     * Retrieves the named pipe setting for this connection.
     *
     * @return the named pipe setting
     */
    boolean getNamedPipe() {
        return this.namedPipe;
    }

    /**
     * Retrieves the packet size for this connection.
     *
     * @return the packet size
     */
    int getPacketSize() {
        return this.packetSize;
    }

    /**
     * Retrieves the password for this connection.
     *
     * @return the password
     */
    String getPassword() {
        return this.password;
    }

    /**
     * Retrieves the port number for this connection.
     *
     * @return the port number
     */
    int getPortNumber() {
        return this.portNumber;
    }

    /**
     * Retrieves the program name for this connection.
     *
     * @return the program name
     */
    String getProgName() {
        return this.progName;
    }

    /**
     * Retrieves the server name for this connection.
     *
     * @return the server name
     */
    String getServerName() {
        return this.serverName;
    }

    /**
     * Retrieves the tcpNoDelay setting for this connection.
     *
     * @return the tcpNoDelay setting
     */
    boolean getTcpNoDelay() {
        return this.tcpNoDelay;
    }

    /**
     * Retrieves the useJCIFS setting for this connection.
     *
     * @return the useJCIFS setting
     */
    boolean getUseJCIFS() {
        return this.useJCIFS;
    }

    /**
     * Retrieves the user for this connection.
     *
     * @return the user
     */
    String getUser() {
        return this.user;
    }

    /**
     * Retrieves the workstation ID (WSID) for this connection.
     *
     * @return the workstation ID (WSID)
     */
    String getWsid() {
        return this.wsid;
    }

    /**
     * Transfers the properties to the local instance variables.
     *
     * @param info The connection properties Object.
     * @throws SQLException If an invalid property value is found.
     */
    protected void unpackProperties(Properties info)
            throws SQLException {

        serverName = info.getProperty(Messages.get(Driver.SERVERNAME));
        portNumber = parseIntegerProperty(info, Driver.PORTNUMBER);
        serverType = parseIntegerProperty(info, Driver.SERVERTYPE);
        databaseName = info.getProperty(Messages.get(Driver.DATABASENAME));
        instanceName = info.getProperty(Messages.get(Driver.INSTANCE));
        domainName = info.getProperty(Messages.get(Driver.DOMAIN));
        user = info.getProperty(Messages.get(Driver.USER));
        password = info.getProperty(Messages.get(Driver.PASSWORD));
        macAddress = info.getProperty(Messages.get(Driver.MACADDRESS));
        appName = info.getProperty(Messages.get(Driver.APPNAME));
        progName = info.getProperty(Messages.get(Driver.PROGNAME));
        wsid = info.getProperty(Messages.get(Driver.WSID));
        serverCharset = info.getProperty(Messages.get(Driver.CHARSET));
        language = info.getProperty(Messages.get(Driver.LANGUAGE));
        bindAddress = info.getProperty(Messages.get(Driver.BINDADDRESS));
        lastUpdateCount = parseBooleanProperty(info,Driver.LASTUPDATECOUNT);
        useUnicode = parseBooleanProperty(info,Driver.SENDSTRINGPARAMETERSASUNICODE);
        namedPipe = parseBooleanProperty(info,Driver.NAMEDPIPE);
        tcpNoDelay = parseBooleanProperty(info,Driver.TCPNODELAY);
        useCursors = (serverType == Driver.SQLSERVER) && parseBooleanProperty(info,Driver.USECURSORS);
        useLOBs = parseBooleanProperty(info,Driver.USELOBS);
        useMetadataCache = parseBooleanProperty(info,Driver.CACHEMETA);
        xaEmulation = parseBooleanProperty(info,Driver.XAEMULATION);
        useJCIFS = parseBooleanProperty(info,Driver.USEJCIFS);
        charsetSpecified = serverCharset.length() > 0;
        useNTLMv2 = parseBooleanProperty(info,Driver.USENTLMV2);

        //note:mdb in certain cases (e.g. NTLMv2) the domain name must be
        //  all upper case for things to work.
        if( domainName != null )
            domainName = domainName.toUpperCase();

        Integer parsedTdsVersion =
                DefaultProperties.getTdsVersion(info.getProperty(Messages.get(Driver.TDS)));
        if (parsedTdsVersion == null) {
            throw new SQLException(Messages.get("error.connection.badprop",
                    Messages.get(Driver.TDS)), "08001");
        }
        tdsVersion = parsedTdsVersion.intValue();

        packetSize = parseIntegerProperty(info, Driver.PACKETSIZE);
        if (packetSize < TdsCore.MIN_PKT_SIZE) {
            if (tdsVersion >= Driver.TDS70) {
                // Default of 0 means let the server specify packet size
                packetSize = (packetSize == 0) ? 0 : TdsCore.DEFAULT_MIN_PKT_SIZE_TDS70;
            } else if (tdsVersion == Driver.TDS42) {
                // Sensible minimum for older versions of TDS
                packetSize = TdsCore.MIN_PKT_SIZE;
            } // else for TDS 5 can auto negotiate
        }
        if (packetSize > TdsCore.MAX_PKT_SIZE) {
            packetSize = TdsCore.MAX_PKT_SIZE;
        }
        packetSize = (packetSize / 512) * 512;

        loginTimeout = parseIntegerProperty(info, Driver.LOGINTIMEOUT);
        socketTimeout = parseIntegerProperty(info, Driver.SOTIMEOUT);
        socketKeepAlive = parseBooleanProperty(info,Driver.SOKEEPALIVE);

        String pid = info.getProperty(Messages.get(Driver.PROCESSID));
        if ("compute".equals(pid)) {
            // only determine a single PID for the VM's (or classloader's) life time
            if (processId == null) {
                // random number until the real process ID can be determined
                processId = new Integer(new Random(System.currentTimeMillis()).nextInt(32768));
            }
        } else if (pid.length() > 0) {
            processId = new Integer(parseIntegerProperty(info, Driver.PROCESSID));
        }

        lobBuffer = parseLongProperty(info, Driver.LOBBUFFER);

        maxStatements = parseIntegerProperty(info, Driver.MAXSTATEMENTS);

        statementCache = new ProcedureCache(maxStatements);
        prepareSql = parseIntegerProperty(info, Driver.PREPARESQL);
        if (prepareSql < 0) {
            prepareSql = 0;
        } else if (prepareSql > 3) {
            prepareSql = 3;
        }
        // For Sybase use equivalent of sp_executesql.
        if (tdsVersion < Driver.TDS70 && prepareSql == TdsCore.PREPARE) {
            prepareSql = TdsCore.EXECUTE_SQL;
        }
        // For SQL 6.5 sp_executesql not available so use stored procedures.
        if (tdsVersion < Driver.TDS50 && prepareSql == TdsCore.EXECUTE_SQL) {
            prepareSql = TdsCore.TEMPORARY_STORED_PROCEDURES;
        }

        ssl = info.getProperty(Messages.get(Driver.SSL));

        batchSize = parseIntegerProperty(info, Driver.BATCHSIZE);
        if (batchSize < 0) {
            throw new SQLException(Messages.get("error.connection.badprop",
                    Messages.get(Driver.BATCHSIZE)), "08001");
        }
        
        bufferDir = new File(info.getProperty(Messages.get(Driver.BUFFERDIR)));
        if (!bufferDir.isDirectory()) {
        	if (!bufferDir.mkdirs()) {
                throw new SQLException(Messages.get("error.connection.badprop",
                        Messages.get(Driver.BUFFERDIR)), "08001");
        	}
        }

        bufferMaxMemory = parseIntegerProperty(info, Driver.BUFFERMAXMEMORY);
        if (bufferMaxMemory < 0) {
            throw new SQLException(Messages.get("error.connection.badprop",
                    Messages.get(Driver.BUFFERMAXMEMORY)), "08001");
        }

        bufferMinPackets = parseIntegerProperty(info, Driver.BUFFERMINPACKETS);
        if (bufferMinPackets < 1) {
            throw new SQLException(Messages.get("error.connection.badprop",
                    Messages.get(Driver.BUFFERMINPACKETS)), "08001");
        }
    }

    /**
     * Parse a string property value into an boolean value.
     *
     * @param info The connection properties object.
     * @param key The message key used to retrieve the property name.
     * @return The boolean value of the string property value.
     * @throws SQLException If the property value can't be parsed.
     */
    private static boolean parseBooleanProperty(final Properties info, final String key)
            throws SQLException {
        final String propertyName = Messages.get(key);
        String prop = info.getProperty(propertyName);
        if (! (prop == null || "true".equalsIgnoreCase(prop) || "false".equalsIgnoreCase(prop)))
                throw new SQLException( Messages.get("error.connection.badprop", propertyName), "08001");

        return "true".equalsIgnoreCase(prop);
    }

    /**
     * Parse a string property value into an integer value.
     *
     * @param info The connection properties object.
     * @param key The message key used to retrieve the property name.
     * @return The integer value of the string property value.
     * @throws SQLException If the property value can't be parsed.
     */
    private static int parseIntegerProperty(final Properties info, final String key)
            throws SQLException {

        final String propertyName = Messages.get(key);
        try {
            return Integer.parseInt(info.getProperty(propertyName));
        } catch (NumberFormatException e) {
            throw new SQLException(
                    Messages.get("error.connection.badprop", propertyName), "08001");
        }
    }

    /**
     * Parse a string property value into a long value.
     *
     * @param info The connection properties object.
     * @param key The message key used to retrieve the property name.
     * @return The long value of the string property value.
     * @throws SQLException If the property value can't be parsed.
     */
    private static long parseLongProperty(final Properties info, final String key)
            throws SQLException {

        final String propertyName = Messages.get(key);
        try {
            return Long.parseLong(info.getProperty(propertyName));
        } catch (NumberFormatException e) {
            throw new SQLException(
                    Messages.get("error.connection.badprop", propertyName), "08001");
        }
    }

    /**
     * Retrieve the Java charset to use for encoding.
     *
     * @return the Charset name as a <code>String</code>
     */
    protected String getCharset() {
        return charsetInfo.getCharset();
    }

    /**
     * Retrieve the multibyte status of the current character set.
     *
     * @return <code>boolean</code> true if a multi byte character set
     */
    protected boolean isWideChar() {
        return charsetInfo.isWideChars();
    }

    /**
     * Retrieve the <code>CharsetInfo</code> instance used by this connection.
     *
     * @return the default <code>CharsetInfo</code> for this connection
     */
    protected CharsetInfo getCharsetInfo() {
        return charsetInfo;
    }

    /**
     * Retrieve the sendParametersAsUnicode flag.
     *
     * @return <code>boolean</code> true if parameters should be sent as unicode.
     */
    protected boolean getUseUnicode() {
        return this.useUnicode;
    }

    /**
     * Retrieve the Sybase capability data.
     *
     * @return Capability bit mask as an <code>int</code>.
     */
    protected boolean getSybaseInfo(int flag) {
        return (this.sybaseInfo & flag) != 0;
    }

    /**
     * Set the Sybase capability data.
     *
     * @param mask The capability bit mask.
     */
    protected void setSybaseInfo(int mask) {
        this.sybaseInfo = mask;
    }

    /**
     * Called by the protocol to change the current character set.
     *
     * @param charset the server character set name
     */
    protected void setServerCharset(final String charset) throws SQLException {
        // If the user specified a charset, ignore environment changes
        if (charsetSpecified) {
            Logger.println("Server charset " + charset +
                    ". Ignoring as user requested " + serverCharset + '.');
            return;
        }

        if (!charset.equals(serverCharset)) {
            loadCharset(charset);

            if (Logger.isActive()) {
                Logger.println("Set charset to " + serverCharset + '/'
                        + charsetInfo);
            }
        }
    }

    /**
     * Load the Java charset to match the server character set.
     *
     * @param charset the server character set
     */
    private void loadCharset(String charset) throws SQLException {
        // MS SQL Server's iso_1 is Cp1252 not ISO-8859-1!
        if (getServerType() == Driver.SQLSERVER
                && charset.equalsIgnoreCase("iso_1")) {
            charset = "Cp1252";
        }

        // Do not default to any charset; if the charset is not found we want
        // to know about it
        CharsetInfo tmp = CharsetInfo.getCharset(charset);

        if (tmp == null) {
            throw new SQLException(
                    Messages.get("error.charset.nomapping", charset), "2C000");
        }

        loadCharset(tmp, charset);
        serverCharset = charset;
    }

    /**
     * Load the Java charset to match the server character set.
     *
     * @param ci the <code>CharsetInfo</code> to load
     */
    private void loadCharset(CharsetInfo ci, String ref) throws SQLException {
        try {
            "This is a test".getBytes(ci.getCharset());

            charsetInfo = ci;
        } catch (UnsupportedEncodingException ex) {
            throw new SQLException(
                    Messages.get("error.charset.invalid", ref,
                            ci.getCharset()),
                    "2C000");
        }

        socket.setCharsetInfo(charsetInfo);
    }

    /**
     * Discovers the server charset for server versions that do not send
     * <code>ENVCHANGE</code> packets on login ack, by executing a DB
     * vendor/version specific query.
     * <p>
     * Will throw an <code>SQLException</code> if used on SQL Server 7.0 or
     * 2000; the idea is that the charset should already be determined from
     * <code>ENVCHANGE</code> packets for these DB servers.
     * <p>
     * Should only be called from the constructor.
     *
     * @return the default server charset
     * @throws SQLException if an error condition occurs
     */
    private String determineServerCharset() throws SQLException {
        String queryStr = null;

        switch (serverType) {
            case Driver.SQLSERVER:
                if (databaseProductVersion.indexOf("6.5") >= 0) {
                    queryStr = SQL_SERVER_65_CHARSET_QUERY;
                } else {
                    // This will never happen. Versions 7.0 and 2000 of SQL
                    // Server always send ENVCHANGE packets, even over TDS 4.2.
                    throw new SQLException(
                            "Please use TDS protocol version 7.0 or higher");
                }
                break;
            case Driver.SYBASE:
                // There's no need to check for versions here
                queryStr = SYBASE_SERVER_CHARSET_QUERY;
                break;
        }

        Statement stmt = this.createStatement();
        ResultSet rs = stmt.executeQuery(queryStr);
        rs.next();
        String charset = rs.getString(1);
        rs.close();
        stmt.close();

        return charset;
    }

    /**
     * Set the default collation for this connection.
     * <p>
     * Set by a SQL Server 2000 environment change packet. The collation
     * consists of the following fields:
     * <ul>
     * <li>bits 0-19  - The locale eg 0x0409 for US English which maps to code
     *                  page 1252 (Latin1_General).
     * <li>bits 20-31 - Reserved.
     * <li>bits 32-39 - Sort order (csid from syscharsets)
     * </ul>
     * If the sort order is non-zero it determines the character set, otherwise
     * the character set is determined by the locale id.
     *
     * @param collation The new collation.
     */
    void setCollation(byte[] collation) throws SQLException {
        String strCollation = "0x" + Support.toHex(collation);
        // If the user specified a charset, ignore environment changes
        if (charsetSpecified) {
            Logger.println("Server collation " + strCollation +
                    ". Ignoring as user requested " + serverCharset + '.');
            return;
        }

        CharsetInfo tmp = CharsetInfo.getCharset(collation);

        loadCharset(tmp, strCollation);
        this.collation = collation;

        if (Logger.isActive()) {
            Logger.println("Set collation to " + strCollation + '/'
                    + charsetInfo);
        }
    }

    /**
     * Retrieve the SQL Server 2000 default collation.
     *
     * @return The collation as a <code>byte[5]</code>.
     */
    byte[] getCollation() {
        return this.collation;
    }

    /**
     * Retrieves whether a specific charset was requested on creation. If this
     * is the case, all character data should be encoded/decoded using that
     * charset.
     */
    boolean isCharsetSpecified() {
        return charsetSpecified;
    }

    /**
     * Called by the protcol to change the current database context.
     *
     * @param newDb The new database selected on the server.
     * @param oldDb The old database as known by the server.
     * @throws SQLException
     */
    protected void setDatabase(final String newDb, final String oldDb)
            throws SQLException {
        if (currentDatabase != null && !oldDb.equalsIgnoreCase(currentDatabase)) {
            throw new SQLException(Messages.get("error.connection.dbmismatch",
                                                      oldDb, databaseName),
                                   "HY096");
        }

        currentDatabase = newDb;

        if (Logger.isActive()) {
            Logger.println("Changed database from " + oldDb + " to " + newDb);
        }
    }

    /**
     * Update the connection instance with information about the server.
     *
     * @param databaseProductName The server name eg SQL Server.
     * @param databaseMajorVersion The major version eg 11
     * @param databaseMinorVersion The minor version eg 92
     * @param buildNumber The server build number.
     */
    protected void setDBServerInfo(String databaseProductName,
                                   int databaseMajorVersion,
                                   int databaseMinorVersion,
                                   int buildNumber) {
        this.databaseProductName = databaseProductName;
        this.databaseMajorVersion = databaseMajorVersion;
        this.databaseMinorVersion = databaseMinorVersion;

        if (tdsVersion >= Driver.TDS70) {
            StringBuffer buf = new StringBuffer(10);

            if (databaseMajorVersion < 10) {
                buf.append('0');
            }

            buf.append(databaseMajorVersion).append('.');

            if (databaseMinorVersion < 10) {
                buf.append('0');
            }

            buf.append(databaseMinorVersion).append('.');
            buf.append(buildNumber);

            while (buf.length() < 10) {
                buf.insert(6, '0');
            }

            this.databaseProductVersion = buf.toString();
        } else {
            databaseProductVersion =
            databaseMajorVersion + "." + databaseMinorVersion;
        }
    }

    /**
     * Removes a statement object from the list maintained by the connection
     * and cleans up the statement cache if necessary.
     * <p>
     * Synchronized because it accesses the statement list, the statement cache
     * and the <code>baseTds</code>.
     *
     * @param statement the statement to remove
     */
    synchronized void removeStatement(JtdsStatement statement)
            throws SQLException {
        // Remove the JtdsStatement from the statement list
        synchronized (statements) {
            for (int i = 0; i < statements.size(); i++) {
                WeakReference wr = (WeakReference) statements.get(i);

                if (wr != null) {
                    Statement stmt = (Statement) wr.get();

                    // Remove the statement if found but also remove all
                    // statements that have already been garbage collected
                    if (stmt == null || stmt == statement) {
                        statements.set(i, null);
                    }
                }
            }
        }

        if (statement instanceof JtdsPreparedStatement) {
            // Clean up the prepared statement cache; getObsoleteHandles will
            // decrement the usage count for the set of used handles
            Collection handles = statementCache.getObsoleteHandles(
                                          ((JtdsPreparedStatement) statement).handles);

            if (handles != null) {
                if (serverType == Driver.SQLSERVER) {
                    // SQL Server unprepare
                    StringBuffer cleanupSql = new StringBuffer(handles.size() * 32);
                    for (Iterator iterator = handles.iterator(); iterator.hasNext(); ) {
                        ProcEntry pe = (ProcEntry) iterator.next();
                        // Could get put back if in a transaction that is
                        // rolled back
                        pe.appendDropSQL(cleanupSql);
                    }
                    if (cleanupSql.length() > 0) {
                        baseTds.executeSQL(cleanupSql.toString(), null, null, true, 0,
                                            -1, -1, true);
                        baseTds.clearResponseQueue();
                    }
                } else {
                    // Sybase unprepare
                    for (Iterator iterator = handles.iterator(); iterator.hasNext(); ) {
                        ProcEntry pe = (ProcEntry)iterator.next();
                        if (pe.toString() != null) {
                            // Remove the Sybase light weight proc
                            baseTds.sybaseUnPrepare(pe.toString());
                        }
                    }
                }
            }
        }
    }

    /**
     * Adds a statement object to the list maintained by the connection.
     * <p/>
     * WeakReferences are used so that statements can still be closed and
     * garbage collected even if not explicitly closed by the connection.
     *
     * @param statement statement to add
     */
    void addStatement(JtdsStatement statement) {
        synchronized (statements) {
            for (int i = 0; i < statements.size(); i++) {
                WeakReference wr = (WeakReference) statements.get(i);

                // FIXME: entries from statements should be dropped immediately
                // on GC, instead of being kept until overwritten or connection
                // being closed  

                if (wr == null || wr.get() == null) {
                    statements.set(i, new WeakReference(statement));
                    return;
                }
            }

            statements.add(new WeakReference(statement));
        }
    }

    /**
     * Checks that the connection is still open.
     *
     * @throws SQLException if the connection is closed
     */
    void checkOpen() throws SQLException {
        if (closed) {
            throw new SQLException(
                                  Messages.get("error.generic.closed", "Connection"), "HY010");
        }
    }

    /**
     * Checks that this connection is in local transaction mode.
     *
     * @param method the method name being tested
     * @throws SQLException if in XA distributed transaction mode
     */
    void checkLocal(String method) throws SQLException {
        if (xaTransaction) {
            throw new SQLException(
                    Messages.get("error.connection.badxaop", method), "HY010");
        }
    }

    /**
     * Reports that user tried to call a method which has not been implemented.
     *
     * @param method the method name to report in the error message
     * @throws SQLException always, with the not implemented message
     */
    static void notImplemented(String method) throws SQLException {
        throw new SQLException(
                Messages.get("error.generic.notimp", method), "HYC00");
    }

    /**
     * Retrieves the DBMS major version.
     *
     * @return the version as an <code>int</code>
     */
    public int getDatabaseMajorVersion() {
        return this.databaseMajorVersion;
    }

    /**
     * Retrieves the DBMS minor version.
     *
     * @return the version as an <code>int</code>
     */
    public int getDatabaseMinorVersion() {
        return this.databaseMinorVersion;
    }

    /**
     * Retrieves the DBMS product name.
     *
     * @return the name as a <code>String</code>
     */
    String getDatabaseProductName() {
        return this.databaseProductName;
    }

    /**
     * Retrieves the DBMS product version.
     *
     * @return the version as a <code>String</code>
     */
    String getDatabaseProductVersion() {
        return this.databaseProductVersion;
    }

    /**
     * Retrieves the original connection URL.
     *
     * @return the connection url as a <code>String</code>
     */
    String getURL() {
        return this.url;
    }

    /**
     * Retrieves the host and port for this connection.
     * <p>
     * Used to identify same resource manager in XA transactions.
     *
     * @return the hostname and port as a <code>String</code>
     */
    public String getRmHost() {
        return serverName + ':' + portNumber;
    }

    /**
     * Forces the closed status on the statement if an I/O error has occurred.
     */
    void setClosed() {
        if (!closed) {
            closed = true;

            // Make sure we release the socket and all data buffered at the socket
            // level
            try {
                socket.close();
            } catch (IOException e) {
                // Ignore; shouldn't happen anyway
            }
        }
    }

    /**
     * Invokes the <code>xp_jtdsxa</code> extended stored procedure on the
     * server.
     * <p/>
     * Synchronized because it accesses the <code>baseTds</code>.
     *
     * @param args the arguments eg cmd, rmid, flags etc.
     * @param data option byte data eg open string xid etc.
     * @return optional byte data eg OLE cookie
     * @throws SQLException if an error condition occurs
     */
    synchronized byte[][] sendXaPacket(int args[], byte[] data)
            throws SQLException {
        ParamInfo params[] = new ParamInfo[6];
        params[0] = new ParamInfo(Types.INTEGER, null, ParamInfo.RETVAL);
        params[1] = new ParamInfo(Types.INTEGER, new Integer(args[1]), ParamInfo.INPUT);
        params[2] = new ParamInfo(Types.INTEGER, new Integer(args[2]), ParamInfo.INPUT);
        params[3] = new ParamInfo(Types.INTEGER, new Integer(args[3]), ParamInfo.INPUT);
        params[4] = new ParamInfo(Types.INTEGER, new Integer(args[4]), ParamInfo.INPUT);
        params[5] = new ParamInfo(Types.VARBINARY, data, ParamInfo.OUTPUT);
        //
        // Execute our extended stored procedure (let's hope it is installed!).
        //
        baseTds.executeSQL(null, "master..xp_jtdsxa", params, false, 0, -1, -1,
                true);
        //
        // Now process results
        //
        ArrayList xids = new ArrayList();
        while (!baseTds.isEndOfResponse()) {
            if (baseTds.getMoreResults()) {
                // This had better be the results from a xa_recover command
                while (baseTds.getNextRow()) {
                    Object row[] = baseTds.getRowData();
                    if (row.length == 1 && row[0] instanceof byte[]) {
                        xids.add(row[0]);
                    }
                }
            }
        }
        messages.checkErrors();
        if (params[0].getOutValue() instanceof Integer) {
            // Should be return code from XA command
            args[0] = ((Integer)params[0].getOutValue()).intValue();
        } else {
            args[0] = -7; // XAException.XAER_RMFAIL
        }
        if (xids.size() > 0) {
            // List of XIDs from xa_recover
            byte list[][] = new byte[xids.size()][];
            for (int i = 0; i < xids.size(); i++) {
                list[i] = (byte[])xids.get(i);
            }
            return list;
        } else
        if (params[5].getOutValue() instanceof byte[]) {
            // xa_open  the xa connection ID
            // xa_start OLE Transaction cookie
            byte cookie[][] = new byte[1][];
            cookie[0] = (byte[])params[5].getOutValue();
            return cookie;
        } else {
            // All other cases
            return null;
        }
    }

    /**
     * Enlists the current connection in a distributed transaction.
     *
     * @param oleTranID the OLE transaction cookie or null to delist
     * @throws SQLException if an error condition occurs
     */
    synchronized void enlistConnection(byte[] oleTranID)
            throws SQLException {
        if (oleTranID != null) {
            // TODO: Stored procs are no good but maybe prepare will be OK.
            this.prepareSql = TdsCore.EXECUTE_SQL;
            baseTds.enlistConnection(1, oleTranID);
            xaTransaction = true;
        } else {
            baseTds.enlistConnection(1, null);
            xaTransaction = false;
        }
    }

    /**
     * Sets the XA transaction ID when running in emulation mode.
     *
     * @param xid the XA Transaction ID
     */
    void setXid(Object xid) {
        this.xid = xid;
        xaTransaction = xid != null;
    }

    /**
     * Gets the XA transaction ID when running in emulation mode.
     *
     * @return the transaction ID as an <code>Object</code>
     */
    Object getXid() {
        return xid;
    }

    /**
     * Sets the XA state variable.
     *
     * @param value the XA state value
     */
    void setXaState(int value) {
        this.xaState = value;
    }

    /**
     * Retrieves the XA state variable.
     *
     * @return the xa state variable as an <code>int</code>
     */
    int getXaState() {
        return this.xaState;
    }

    /**
     * Retrieves the XA Emulation flag.
     * @return True if in XA emulation mode.
     */
    boolean isXaEmulation() {
        return xaEmulation;
    }

    /**
     * Retrieves the connection mutex and acquires an exclusive lock on the
     * network connection.
     *
     * @return the mutex object as a <code>Semaphore</code>
     */
    Semaphore getMutex() {
        // Thread.interrupted() will clear the interrupt status
        boolean interrupted = Thread.interrupted();
        
        try {
            this.mutex.acquire();
        } catch (InterruptedException e) {
            throw new IllegalStateException("Thread execution interrupted");
        }
        
        if (interrupted) {
            // Bug [1596743] do not absorb interrupt status
            Thread.currentThread().interrupt();
        }
        
        return this.mutex;
    }


    /**
     * Releases (either closes or caches) a <code>TdsCore</code>.
     *
     * @param tds the <code>TdsCore</code> instance to release
     * @throws SQLException if an error occurs while closing or cleaning up
     * @todo Should probably synchronize on another object
     */
    synchronized void releaseTds(TdsCore tds) throws SQLException {
        if (cachedTds != null) {
            // There's already a cached TdsCore; close this one
            tds.close();
        } else {
            // No cached TdsCore; clean up this one and cache it
            tds.clearResponseQueue();
            tds.cleanUp();
            cachedTds = tds;
        }
    }

    /**
     * Retrieves the cached <code>TdsCore</code> or <code>null</code> if
     * nothing is cached and resets the cache (sets it to <code>null</code>).
     *
     * @return the value of {@link #cachedTds}
     * @todo Should probably synchronize on another object
     */
    synchronized TdsCore getCachedTds() {
        TdsCore result = cachedTds;
        cachedTds = null;
        return result;
    }

    //
    // ------------------- java.sql.Connection interface methods -------------------
    //

    public int getHoldability() throws SQLException {
        checkOpen();

        return JtdsResultSet.HOLD_CURSORS_OVER_COMMIT;
    }

    synchronized public int getTransactionIsolation() throws SQLException {
        checkOpen();

        return this.transactionIsolation;
    }

    synchronized public void clearWarnings() throws SQLException {
        checkOpen();
        messages.clearWarnings();
    }

    /**
     * Releases this <code>Connection</code> object's database and JDBC
     * resources immediately instead of waiting for them to be automatically
     * released.
     * <p>
     * Calling the method close on a <code>Connection</code> object that is
     * already closed is a no-op.
     * <p>
     * <b>Note:</b> A <code>Connection</code> object is automatically closed
     * when it is garbage collected. Certain fatal errors also close a
     * <code>Connection</code> object.
     * <p>
     * Synchronized because it accesses the statement list and the
     * <code>baseTds</code>.
     *
     * @throws SQLException if a database access error occurs
     */
    synchronized public void close() throws SQLException {
        if (!closed) {
            try {
                //
                // Close any open statements
                //
                ArrayList tmpList;

                synchronized (statements) {
                    tmpList = new ArrayList(statements);
                    statements.clear();
                }

                for (int i = 0; i < tmpList.size(); i++) {
                    WeakReference wr = (WeakReference)tmpList.get(i);

                    if (wr != null) {
                        Statement stmt = (Statement) wr.get();
                        if (stmt != null) {
                            try {
                                stmt.close();
                            } catch (SQLException ex) {
                                // Ignore
                            }
                        }
                    }
                }

                try {
                    // Tell the server the session is ending, close network connection
                    if (baseTds != null) {
                        baseTds.closeConnection();
                        baseTds.close();
                    }
                    // Close cached TdsCore
                    if (cachedTds != null) {
                        cachedTds.close();
                        cachedTds = null;
                    }
                } catch (SQLException ex) {
                    // Ignore
                }

                if (socket != null) {
                    socket.close();
                }
            } catch (IOException e) {
                // Ignore
            } finally {
                closed = true;
                if (--connections == 0) {
                    TimerThread.getInstance().stopTimer();
                }
            }
        }
    }

    synchronized public void commit() throws SQLException {
        checkOpen();
        checkLocal("commit");

        if (getAutoCommit()) {
            throw new SQLException(
                    Messages.get("error.connection.autocommit", "commit"),
                    "25000");
        }

        baseTds.submitSQL("IF @@TRANCOUNT > 0 COMMIT TRAN");
        procInTran.clear();
        clearSavepoints();
    }

    synchronized public void rollback() throws SQLException {
        checkOpen();
        checkLocal("rollback");

        if (getAutoCommit()) {
            throw new SQLException(
                    Messages.get("error.connection.autocommit", "rollback"),
                    "25000");
        }

        baseTds.submitSQL("IF @@TRANCOUNT > 0 ROLLBACK TRAN");

        for (int i = 0; i < procInTran.size(); i++) {
            String key = (String) procInTran.get(i);
            if (key != null) {
                statementCache.remove(key);
            }
        }
        procInTran.clear();

        clearSavepoints();
    }

    synchronized public boolean getAutoCommit() throws SQLException {
        checkOpen();

        return this.autoCommit;
    }

    public boolean isClosed() throws SQLException {
        return closed;
    }

    public boolean isReadOnly() throws SQLException {
        checkOpen();

        return this.readOnly;
    }

    public void setHoldability(int holdability) throws SQLException {
        checkOpen();
        switch (holdability) {
            case JtdsResultSet.HOLD_CURSORS_OVER_COMMIT:
                break;
            case JtdsResultSet.CLOSE_CURSORS_AT_COMMIT:
                throw new SQLException(
                        Messages.get("error.generic.optvalue",
                                "CLOSE_CURSORS_AT_COMMIT",
                                "setHoldability"),
                        "HY092");
            default:
                throw new SQLException(
                        Messages.get("error.generic.badoption",
                                Integer.toString(holdability),
                                "holdability"),
                        "HY092");
        }
    }

    synchronized public void setTransactionIsolation(int level) throws SQLException {
        checkOpen();

        if (transactionIsolation == level) {
            // No need to submit a request
            return;
        }

        String sql = "SET TRANSACTION ISOLATION LEVEL ";
        boolean sybase = serverType == Driver.SYBASE;

        switch (level) {
            case java.sql.Connection.TRANSACTION_READ_UNCOMMITTED:
                sql += (sybase) ? "0" : "READ UNCOMMITTED";
                break;
            case java.sql.Connection.TRANSACTION_READ_COMMITTED:
                sql += (sybase) ? "1" : "READ COMMITTED";
                break;
            case java.sql.Connection.TRANSACTION_REPEATABLE_READ:
                sql += (sybase) ? "2" : "REPEATABLE READ";
                break;
            case java.sql.Connection.TRANSACTION_SERIALIZABLE:
                sql += (sybase) ? "3" : "SERIALIZABLE";
                break;
            case TRANSACTION_SNAPSHOT:
                if (sybase) {
                    throw new SQLException(
                            Messages.get("error.generic.optvalue",
                                         "TRANSACTION_SNAPSHOT",
                                         "setTransactionIsolation"),
                            "HY024");
                } else {
                    sql += "SNAPSHOT";
                }
                break;
            case java.sql.Connection.TRANSACTION_NONE:
                throw new SQLException(
                        Messages.get("error.generic.optvalue",
                                "TRANSACTION_NONE",
                                "setTransactionIsolation"),
                        "HY024");
            default:
                throw new SQLException(
                        Messages.get("error.generic.badoption",
                                Integer.toString(level),
                                "level"),
                        "HY092");
        }

        transactionIsolation = level;
        baseTds.submitSQL(sql);
    }

    synchronized public void setAutoCommit(boolean autoCommit) throws SQLException {
        checkOpen();
        checkLocal("setAutoCommit");

        if (this.autoCommit == autoCommit) {
            // If we don't need to change the current auto commit mode, don't
            // submit a request and don't commit either. Section 10.1.1 of the
            // JDBC 3.0 spec states that the transaction should be committed
            // only "if the value of auto-commit is _changed_ in the middle of
            // a transaction". This takes precedence over the API docs, which
            // states that "if this method is called during a transaction, the
            // transaction is committed".
            return;
        }

        StringBuffer sql = new StringBuffer(70);
        //
        if (!this.autoCommit) {
            // If we're in manual commit mode the spec requires that we commit
            // the transaction when setAutoCommit() is called
            sql.append("IF @@TRANCOUNT > 0 COMMIT TRAN\r\n");
        }

        if (serverType == Driver.SYBASE) {
            if (autoCommit) {
                sql.append("SET CHAINED OFF");
            } else {
                sql.append("SET CHAINED ON");
            }
        } else {
            if (autoCommit) {
                sql.append("SET IMPLICIT_TRANSACTIONS OFF");
            } else {
                sql.append("SET IMPLICIT_TRANSACTIONS ON");
            }
        }

        baseTds.submitSQL(sql.toString());
        this.autoCommit = autoCommit;
    }

    public void setReadOnly(boolean readOnly) throws SQLException {
        checkOpen();
        this.readOnly = readOnly;
    }

    synchronized public String getCatalog() throws SQLException {
        checkOpen();

        return this.currentDatabase;
    }

    synchronized public void setCatalog(String catalog) throws SQLException {
        checkOpen();

        if (currentDatabase != null && currentDatabase.equals(catalog)) {
            return;
        }
        
        int maxlength = tdsVersion >= Driver.TDS70 ? 128 : 30;
        
        if (catalog.length() > maxlength || catalog.length() < 1) {
            throw new SQLException(
                    Messages.get("error.generic.badparam",
                            catalog,
                            "catalog"),
                    "3D000");
        }

        String sql = tdsVersion >= Driver.TDS70
                ? ("use [" + catalog + ']') : "use " + catalog;
        baseTds.submitSQL(sql);
    }

    public DatabaseMetaData getMetaData() throws SQLException {
        checkOpen();

        return new JtdsDatabaseMetaData(this);
    }

    public SQLWarning getWarnings() throws SQLException {
        checkOpen();

        return messages.getWarnings();
    }

    public Savepoint setSavepoint() throws SQLException {
        checkOpen();
        notImplemented("Connection.setSavepoint()");

        return null;
    }

    public void releaseSavepoint(Savepoint savepoint) throws SQLException {
        checkOpen();
        notImplemented("Connection.releaseSavepoint(Savepoint)");
    }

    public void rollback(Savepoint savepoint) throws SQLException {
        checkOpen();
        notImplemented("Connection.rollback(Savepoint)");
    }

    public Statement createStatement() throws SQLException {
        checkOpen();

        return createStatement(java.sql.ResultSet.TYPE_FORWARD_ONLY,
                               java.sql.ResultSet.CONCUR_READ_ONLY);
    }

    synchronized public Statement createStatement(int type, int concurrency)
            throws SQLException {
        checkOpen();

        JtdsStatement stmt = new JtdsStatement(this, type, concurrency);
        addStatement(stmt);

        return stmt;
    }

    public Statement createStatement(int type, int concurrency, int holdability)
            throws SQLException {
        checkOpen();
        setHoldability(holdability);

        return createStatement(type, concurrency);
    }

    public Map getTypeMap() throws SQLException {
        checkOpen();

        return new HashMap();
    }

    public void setTypeMap(Map map) throws SQLException {
        checkOpen();
        notImplemented("Connection.setTypeMap(Map)");
    }

    public String nativeSQL(String sql) throws SQLException {
        checkOpen();

        if (sql == null || sql.length() == 0) {
            throw new SQLException(Messages.get("error.generic.nosql"), "HY000");
        }

        String[] result = SQLParser.parse(sql, new ArrayList(), this, false);

        return result[0];
    }

    public CallableStatement prepareCall(String sql) throws SQLException {
        checkOpen();

        return prepareCall(sql,
                           java.sql.ResultSet.TYPE_FORWARD_ONLY,
                           java.sql.ResultSet.CONCUR_READ_ONLY);
    }

    synchronized public CallableStatement prepareCall(String sql, int type,
                                                      int concurrency)
            throws SQLException {
        checkOpen();

        if (sql == null || sql.length() == 0) {
            throw new SQLException(Messages.get("error.generic.nosql"), "HY000");
        }

        JtdsCallableStatement stmt = new JtdsCallableStatement(this,
                                                               sql,
                                                               type,
                                                               concurrency);
        addStatement(stmt);

        return stmt;
    }

    public CallableStatement prepareCall(
                                        String sql,
                                        int type,
                                        int concurrency,
                                        int holdability)
    throws SQLException {
        checkOpen();
        setHoldability(holdability);
        return prepareCall(sql, type, concurrency);
    }

    public PreparedStatement prepareStatement(String sql)
            throws SQLException {
        checkOpen();

        return prepareStatement(sql,
                                java.sql.ResultSet.TYPE_FORWARD_ONLY,
                                java.sql.ResultSet.CONCUR_READ_ONLY);
    }

    public PreparedStatement prepareStatement(String sql, int autoGeneratedKeys)
            throws SQLException {
        checkOpen();

        if (sql == null || sql.length() == 0) {
            throw new SQLException(Messages.get("error.generic.nosql"), "HY000");
        }

        if (autoGeneratedKeys != JtdsStatement.RETURN_GENERATED_KEYS &&
            autoGeneratedKeys != JtdsStatement.NO_GENERATED_KEYS) {
            throw new SQLException(
                    Messages.get("error.generic.badoption",
                            Integer.toString(autoGeneratedKeys),
                            "autoGeneratedKeys"),
                    "HY092");
        }

        JtdsPreparedStatement stmt = new JtdsPreparedStatement(this,
                sql,
                java.sql.ResultSet.TYPE_FORWARD_ONLY,
                java.sql.ResultSet.CONCUR_READ_ONLY,
                autoGeneratedKeys == JtdsStatement.RETURN_GENERATED_KEYS);
        addStatement(stmt);

        return stmt;
    }

    synchronized public PreparedStatement prepareStatement(String sql,
                                                           int type,
                                                           int concurrency)
            throws SQLException {
        checkOpen();

        if (sql == null || sql.length() == 0) {
            throw new SQLException(Messages.get("error.generic.nosql"), "HY000");
        }

        JtdsPreparedStatement stmt = new JtdsPreparedStatement(this,
                                                               sql,
                                                               type,
                                                               concurrency,
                                                               false);
        addStatement(stmt);

        return stmt;
    }

    public PreparedStatement prepareStatement(
                                             String sql,
                                             int type,
                                             int concurrency,
                                             int holdability)
    throws SQLException {
        checkOpen();
        setHoldability(holdability);

        return prepareStatement(sql, type, concurrency);
    }

    public PreparedStatement prepareStatement(String sql, int[] columnIndexes)
            throws SQLException {
        if (columnIndexes == null) {
            throw new SQLException(
                                  Messages.get("error.generic.nullparam", "prepareStatement"),"HY092");
        } else if (columnIndexes.length != 1) {
            throw new SQLException(
                                  Messages.get("error.generic.needcolindex", "prepareStatement"),"HY092");
        }

        return prepareStatement(sql, JtdsStatement.RETURN_GENERATED_KEYS);
    }

    public Savepoint setSavepoint(String name) throws SQLException {
        checkOpen();
        notImplemented("Connection.setSavepoint(String)");

        return null;
    }

    public PreparedStatement prepareStatement(String sql, String[] columnNames)
            throws SQLException {
        if (columnNames == null) {
            throw new SQLException(
                                  Messages.get("error.generic.nullparam", "prepareStatement"),"HY092");
        } else if (columnNames.length != 1) {
            throw new SQLException(
                                  Messages.get("error.generic.needcolname", "prepareStatement"),"HY092");
        }

        return prepareStatement(sql, JtdsStatement.RETURN_GENERATED_KEYS);
    }

    /**
     * Releases all savepoints. Used internally when committing or rolling back
     * a transaction.
     */
    void clearSavepoints() {
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