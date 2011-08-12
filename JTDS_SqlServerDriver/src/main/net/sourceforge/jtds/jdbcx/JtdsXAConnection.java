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
package net.sourceforge.jtds.jdbcx;

import java.sql.Connection;
import java.sql.SQLException;
import javax.sql.XAConnection;
import javax.transaction.xa.XAResource;

import net.sourceforge.jtds.jdbc.XASupport;

/**
 * jTDS implementation of the <code>XAConnection</code> interface.
 *
 * @version $Id: JtdsXAConnection.java,v 1.4 2005-04-28 14:29:30 alin_sinpalean Exp $
 */
public class JtdsXAConnection extends PooledConnection implements XAConnection {
    /** The XAResource used by the transaction manager to control this connection.*/
    private final XAResource resource;
    private final JtdsDataSource dataSource;
    private final int xaConnectionId;

    /**
     * Construct a new <code>XAConnection</code> object.
     *
     * @param dataSource the parent <code>DataSource</code> object
     * @param connection the real database connection
     */
    public JtdsXAConnection(JtdsDataSource dataSource, Connection connection)
    throws SQLException {
        super(connection);
        this.resource = new JtdsXAResource(this, connection);
        this.dataSource = dataSource;
        xaConnectionId = XASupport.xa_open(connection);
    }

    /**
     * Retrieves the XA Connection ID to pass to server.
     *
     * @return the XA connection ID as an <code>Integer</code>
     */
    int getXAConnectionID() {
        return this.xaConnectionId;
    }

    //
    // ------------------- javax.sql.XAConnection interface methods -------------------
    //

    public XAResource getXAResource() throws SQLException {
        return resource;
    }

    public synchronized void close() throws SQLException {
        try {
            XASupport.xa_close(connection, xaConnectionId);
        } catch (SQLException e) {
            // Ignore close errors
        }
        super.close();
    }

    protected JtdsDataSource getXADataSource() {
        return this.dataSource;
    }
}
