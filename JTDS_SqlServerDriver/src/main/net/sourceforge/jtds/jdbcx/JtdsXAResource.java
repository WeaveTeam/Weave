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
import javax.transaction.xa.XAException;
import javax.transaction.xa.XAResource;
import javax.transaction.xa.Xid;

import net.sourceforge.jtds.jdbc.ConnectionJDBC2;
import net.sourceforge.jtds.jdbc.XASupport;
import net.sourceforge.jtds.util.Logger;

/**
 * jTDS implementation of the XAResource interface.
 *
 * @version $Id: JtdsXAResource.java,v 1.4 2005-04-28 14:29:30 alin_sinpalean Exp $
 */
public class JtdsXAResource implements XAResource {
    private final Connection connection;
    private final JtdsXAConnection xaConnection;
    private final String rmHost;

    public JtdsXAResource(JtdsXAConnection xaConnection, Connection connection) {
        this.xaConnection = xaConnection;
        this.connection = connection;
        rmHost = ((ConnectionJDBC2) connection).getRmHost();
        Logger.println("JtdsXAResource created");
    }

    protected JtdsXAConnection getResourceManager() {
        return xaConnection;
    }

    protected String getRmHost() {
        return this.rmHost;
    }

//
// ------------------- javax.transaction.xa.XAResource interface methods -------------------
//

    public int getTransactionTimeout() throws XAException {
        Logger.println("XAResource.getTransactionTimeout()");
        return 0;
    }

    public boolean setTransactionTimeout(int arg0) throws XAException {
        Logger.println("XAResource.setTransactionTimeout("+arg0+')');
        return false;
    }

    public boolean isSameRM(XAResource xares) throws XAException {
        Logger.println("XAResource.isSameRM("+xares.toString()+')');
        if (xares instanceof JtdsXAResource) {
            if (((JtdsXAResource)xares).getRmHost().equals(this.rmHost)) {
                return true;
            }
        }
        return false;
    }

    public Xid[] recover(int flags) throws XAException {
        Logger.println("XAResource.recover("+flags+')');
        return XASupport.xa_recover(connection, xaConnection.getXAConnectionID(), flags);
    }

    public int prepare(Xid xid) throws XAException {
        Logger.println("XAResource.prepare("+xid.toString()+')');
        return XASupport.xa_prepare(connection, xaConnection.getXAConnectionID(), xid);
    }

    public void forget(Xid xid) throws XAException {
        Logger.println("XAResource.forget(" + xid + ')');
        XASupport.xa_forget(connection, xaConnection.getXAConnectionID(), xid);
    }

    public void rollback(Xid xid) throws XAException {
        Logger.println("XAResource.rollback(" +xid.toString()+')');
        XASupport.xa_rollback(connection, xaConnection.getXAConnectionID(), xid);
    }

    public void end(Xid xid, int flags) throws XAException {
        Logger.println("XAResource.end(" +xid.toString()+')');
        XASupport.xa_end(connection, xaConnection.getXAConnectionID(), xid, flags);
    }

    public void start(Xid xid, int flags) throws XAException {
        Logger.println("XAResource.start(" +xid.toString()+','+flags+')');
        XASupport.xa_start(connection, xaConnection.getXAConnectionID(), xid, flags);
    }

    public void commit(Xid xid, boolean commit) throws XAException {
        Logger.println("XAResource.commit(" +xid.toString()+','+commit+')');
        XASupport.xa_commit(connection, xaConnection.getXAConnectionID(), xid, commit);
    }

}
