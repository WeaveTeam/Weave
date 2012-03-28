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

import java.util.*;
import java.sql.*;

/**
 * Implements JDBC 3.0 specific functionality. Separated from {@link
 * ConnectionJDBC2} in order to allow the same classes to run under both J2SE 1.3
 * (<code>ConnectionJDBC2</code>)and 1.4 (<code>ConnectionJDBC3</code>).
 *
 * @author Alin Sinpalean
 * @author Brian Heineman
 * @author Mike Hutchinson
 * @created March 30, 2004
 * @version $Id: ConnectionJDBC3.java,v 1.15.2.2 2009-07-26 17:15:05 ickzon Exp $
 */
public class ConnectionJDBC3 extends ConnectionJDBC2 {
    /** The list of savepoints. */
    private ArrayList savepoints;
    /** Maps each savepoint to a list of tmep procedures created since the savepoint */
    private Map savepointProcInTran;
    /** Counter for generating unique savepoint identifiers */
    private int savepointId;

    /**
     * Create a new database connection.
     *
     * @param url The connection URL starting jdbc:jtds:.
     * @param props The additional connection properties.
     * @throws SQLException
     */
    ConnectionJDBC3(String url, Properties props) throws SQLException {
        super(url, props);
    }

    /**
     * Add a savepoint to the list maintained by this connection.
     *
     * @param savepoint The savepoint object to add.
     * @throws SQLException
     */
    private void setSavepoint(SavepointImpl savepoint) throws SQLException {
        Statement statement = null;

        try {
            statement = createStatement();
            statement.execute("IF @@TRANCOUNT=0 BEGIN "
                    + "SET IMPLICIT_TRANSACTIONS OFF; " + "BEGIN TRAN; " // Fix for bug []Patch: in SET IMPLICIT_TRANSACTIONS ON
                    + "SET IMPLICIT_TRANSACTIONS ON; " + "END "          // mode BEGIN TRAN actually starts two transactions!
                    + "SAVE TRAN jtds" + savepoint.getId());
        } finally {
            if (statement != null) {
                statement.close();
            }
        }

        synchronized (this) {
            if (savepoints == null) {
                savepoints = new ArrayList();
            }

            savepoints.add(savepoint);
        }
    }

    /**
     * Releases all savepoints. Used internally when committing or rolling back
     * a transaction.
     */
    synchronized void clearSavepoints() {
        if (savepoints != null) {
            savepoints.clear();
        }

        if (savepointProcInTran != null) {
            savepointProcInTran.clear();
        }

        savepointId = 0;
    }


// ------------- Methods implementing java.sql.Connection  -----------------

    public synchronized void releaseSavepoint(Savepoint savepoint)
            throws SQLException {
        checkOpen();

        if (savepoints == null) {
            throw new SQLException(
                Messages.get("error.connection.badsavep"), "25000");
        }

        int index = savepoints.indexOf(savepoint);

        if (index == -1) {
            throw new SQLException(
                Messages.get("error.connection.badsavep"), "25000");
        }

        Object tmpSavepoint = savepoints.remove(index);

        if (savepointProcInTran != null) {
            if (index != 0) {
                // If this wasn't the outermost savepoint, move all procedures
                // to the "wrapping" savepoint's list; when and if that
                // savepoint will be rolled back it will clear these procedures
                // too
                List keys = (List) savepointProcInTran.get(savepoint);

                if (keys != null) {
                    Savepoint wrapping = (Savepoint) savepoints.get(index - 1);
                    List wrappingKeys =
                            (List) savepointProcInTran.get(wrapping);
                    if (wrappingKeys == null) {
                        wrappingKeys = new ArrayList();
                    }
                    wrappingKeys.addAll(keys);
                    savepointProcInTran.put(wrapping, wrappingKeys);
                }
            }

            // If this was the outermost savepoint, just drop references to
            // all procedures; they will be managed by the connection
            savepointProcInTran.remove(tmpSavepoint);
        }
    }

    public synchronized void rollback(Savepoint savepoint) throws SQLException {
        checkOpen();
        checkLocal("rollback");

        if (savepoints == null) {
            throw new SQLException(
                Messages.get("error.connection.badsavep"), "25000");
        }

        int index = savepoints.indexOf(savepoint);

        if (index == -1) {
            throw new SQLException(
                Messages.get("error.connection.badsavep"), "25000");
        } else if (getAutoCommit()) {
            throw new SQLException(
                Messages.get("error.connection.savenorollback"), "25000");
        }

        Statement statement = null;

        try {
            statement = createStatement();
            statement.execute("ROLLBACK TRAN jtds" + ((SavepointImpl) savepoint).getId());
        } finally {
            if (statement != null) {
                statement.close();
            }
        }

        int size = savepoints.size();

        for (int i = size - 1; i >= index; i--) {
            Object tmpSavepoint = savepoints.remove(i);

            if (savepointProcInTran == null) {
                continue;
            }

            List keys = (List) savepointProcInTran.get(tmpSavepoint);

            if (keys == null) {
                continue;
            }

            for (Iterator iterator = keys.iterator(); iterator.hasNext();) {
                String key = (String) iterator.next();

                removeCachedProcedure(key);
            }
        }

        // recreate savepoint
        setSavepoint((SavepointImpl) savepoint);
    }

    synchronized public Savepoint setSavepoint() throws SQLException {
        checkOpen();
        checkLocal("setSavepoint");

        if (getAutoCommit()) {
            throw new SQLException(
                Messages.get("error.connection.savenoset"), "25000");
        }

        SavepointImpl savepoint = new SavepointImpl(getNextSavepointId());

        setSavepoint(savepoint);

        return savepoint;
    }

    synchronized public Savepoint setSavepoint(String name) throws SQLException {
        checkOpen();
        checkLocal("setSavepoint");

        if (getAutoCommit()) {
            throw new SQLException(
                Messages.get("error.connection.savenoset"), "25000");
        } else if (name == null) {
            throw new SQLException(
                Messages.get("error.connection.savenullname", "savepoint"),
                "25000");
        }

        SavepointImpl savepoint = new SavepointImpl(getNextSavepointId(), name);

        setSavepoint(savepoint);

        return savepoint;
    }

    /**
     * Returns the next savepoint identifier.
     *
     * @return the next savepoint identifier
     */
    private int getNextSavepointId() {
        return ++savepointId;
    }

    /**
     * Add a stored procedure to the cache.
     *
     * @param key The signature of the procedure to cache.
     * @param proc The stored procedure descriptor.
     */
    void addCachedProcedure(String key, ProcEntry proc) {
        super.addCachedProcedure(key, proc);
        if (getServerType() == Driver.SQLSERVER
                && proc.getType() == ProcEntry.PROCEDURE) {
            // Only need to track SQL Server temp stored procs
            addCachedProcedure(key);
        }
    }

    /**
     * Add a stored procedure to the savepoint cache.
     *
     * @param key The signature of the procedure to cache.
     */
    synchronized void addCachedProcedure(String key) {
        if (savepoints == null || savepoints.size() == 0) {
            return;
        }

        if (savepointProcInTran == null) {
            savepointProcInTran = new HashMap();
        }

        // Retrieve the current savepoint
        Object savepoint = savepoints.get(savepoints.size() - 1);

        List keys = (List) savepointProcInTran.get(savepoint);

        if (keys == null) {
            keys = new ArrayList();
        }

        keys.add(key);

        savepointProcInTran.put(savepoint, keys);
    }
}
