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

import java.sql.Connection;
import java.sql.SQLException;
import javax.transaction.xa.XAException;
import javax.transaction.xa.XAResource;
import javax.transaction.xa.Xid;

import net.sourceforge.jtds.jdbcx.JtdsXid;
import net.sourceforge.jtds.util.Logger;

/**
 * This class contains static utility methods used to implement distributed transactions.
 * For SQL Server 2000 the driver can provide true distributed transactions provided that
 * the external stored procedure in JtdsXA.dll is installed. For other types of server
 * only an emulation is available at this stage.
 */
public class XASupport {
    /**
     * The Resource Manager ID allocated by jTDS
     */
    private static final int XA_RMID = 1;
    /**
     * xa_open login string unique to jTDS.
     */
    private static final String TM_ID = "TM=JTDS,RmRecoveryGuid=434CDE1A-F747-4942-9584-04937455CAB4";
    //
    // XA Switch constants
    //
    private static final int XA_OPEN     = 1;
    private static final int XA_CLOSE    = 2;
    private static final int XA_START    = 3;
    private static final int XA_END      = 4;
    private static final int XA_ROLLBACK = 5;
    private static final int XA_PREPARE  = 6;
    private static final int XA_COMMIT   = 7;
    private static final int XA_RECOVER  = 8;
    private static final int XA_FORGET   = 9;
    private static final int XA_COMPLETE = 10;
    /**
     * Set this field to 1 to enable XA tracing.
     */
    private static final int XA_TRACE = 0;

    //
    //  ----- XA support routines -----
    //
    /**
     * Invoke the xa_open routine on the SQL Server.
     *
     * @param connection the parent XAConnection object
     * @return the XA connection ID allocated by xp_jtdsxa
     */
    public static int xa_open(Connection connection)
            throws SQLException {

        ConnectionJDBC2 con = (ConnectionJDBC2)connection;
        if (con.isXaEmulation()) {
            //
            // Emulate xa_open method
            //
            Logger.println("xa_open: emulating distributed transaction support");
            if (con.getXid() != null) {
                throw new SQLException(
                            Messages.get("error.xasupport.activetran", "xa_open"),
                                            "HY000");
            }
            con.setXaState(XA_OPEN);
            return 0;
        }
        //
        // Execute xa_open via MSDTC
        //
        // Check that we are using SQL Server 2000+
        //
        if (((ConnectionJDBC2) connection).getServerType() != Driver.SQLSERVER
                || ((ConnectionJDBC2) connection).getTdsVersion() < Driver.TDS80) {
            throw new SQLException(Messages.get("error.xasupport.nodist"), "HY000");
        }
        Logger.println("xa_open: Using SQL2000 MSDTC to support distributed transactions");
        //
        // OK Now invoke extended stored procedure to register this connection.
        //
        int args[] = new int[5];
        args[1] = XA_OPEN;
        args[2] = XA_TRACE;
        args[3] = XA_RMID;
        args[4] = XAResource.TMNOFLAGS;
        byte[][] id;
        id = ((ConnectionJDBC2) connection).sendXaPacket(args, TM_ID.getBytes());
        if (args[0] != XAResource.XA_OK
                || id == null
                || id[0] == null
                || id[0].length != 4) {
            throw new SQLException(
                            Messages.get("error.xasupport.badopen"), "HY000");
        }
        return (id[0][0] & 0xFF) |
                ((id[0][1] & 0xFF) << 8) |
                ((id[0][2] & 0xFF) << 16) |
                ((id[0][3] & 0xFF) << 24);
    }

    /**
     * Invoke the xa_close routine on the SQL Server.
     *
     * @param connection JDBC Connection to be enlisted in the transaction
     * @param xaConId    the connection ID allocated by the server
     */
    public static void xa_close(Connection connection, int xaConId)
            throws SQLException {

        ConnectionJDBC2 con = (ConnectionJDBC2)connection;
        if (con.isXaEmulation()) {
            //
            // Emulate xa_close method
            //
            con.setXaState(0);
            if (con.getXid() != null) {
                con.setXid(null);
                try {
                    con.rollback();
                } catch(SQLException e) {
                    Logger.println("xa_close: rollback() returned " + e);
                }
                try {
                    con.setAutoCommit(true);
                } catch(SQLException e) {
                    Logger.println("xa_close: setAutoCommit() returned " + e);
                }
                throw new SQLException(
                        Messages.get("error.xasupport.activetran", "xa_close"),
                                        "HY000");
            }
            return;
        }
        //
        // Execute xa_close via MSDTC
        //
        int args[] = new int[5];
        args[1] = XA_CLOSE;
        args[2] = xaConId;
        args[3] = XA_RMID;
        args[4] = XAResource.TMNOFLAGS;
        ((ConnectionJDBC2) connection).sendXaPacket(args, TM_ID.getBytes());
    }

    /**
     * Invoke the xa_start routine on the SQL Server.
     *
     * @param connection JDBC Connection to be enlisted in the transaction
     * @param xaConId    the connection ID allocated by the server
     * @param xid        the XA Transaction ID object
     * @param flags      XA Flags for start command
     * @exception javax.transaction.xa.XAException
     *             if an error condition occurs
     */
    public static void xa_start(Connection connection, int xaConId, Xid xid, int flags)
            throws XAException {

        ConnectionJDBC2 con = (ConnectionJDBC2)connection;
        if (con.isXaEmulation()) {
            //
            // Emulate xa_start method
            //
            JtdsXid lxid = new JtdsXid(xid);
            if (con.getXaState() == 0) {
                // Connection not opened
                raiseXAException(XAException.XAER_PROTO);
            }
            JtdsXid tran = (JtdsXid)con.getXid();
            if (tran != null) {
                if (tran.equals(lxid)) {
                    raiseXAException(XAException.XAER_DUPID);
                } else {
                    raiseXAException(XAException.XAER_PROTO);
                }
            }
            if (flags != XAResource.TMNOFLAGS) {
                // TMJOIN and TMRESUME cannot be supported
                raiseXAException(XAException.XAER_INVAL);
            }
            try {
                connection.setAutoCommit(false);
            } catch (SQLException e) {
                raiseXAException(XAException.XAER_RMERR);
            }
            con.setXid(lxid);
            con.setXaState(XA_START);
            return;
        }
        //
        // Execute xa_start via MSDTC
        //
        int args[] = new int[5];
        args[1] = XA_START;
        args[2] = xaConId;
        args[3] = XA_RMID;
        args[4] = flags;
        byte[][] cookie;
        try {
            cookie = ((ConnectionJDBC2) connection).sendXaPacket(args, toBytesXid(xid));
            if (args[0] == XAResource.XA_OK && cookie != null) {
                ((ConnectionJDBC2) connection).enlistConnection(cookie[0]);
            }
        } catch (SQLException e) {
            raiseXAException(e);
        }
        if (args[0] != XAResource.XA_OK) {
            raiseXAException(args[0]);
        }
    }

    /**
     * Invoke the xa_end routine on the SQL Server.
     *
     * @param connection JDBC Connection enlisted in the transaction
     * @param xaConId    the connection ID allocated by the server
     * @param xid        the XA Transaction ID object
     * @param flags      XA Flags for start command
     * @exception javax.transaction.xa.XAException
     *             if an error condition occurs
     */
    public static void xa_end(Connection connection, int xaConId, Xid xid, int flags)
            throws XAException {

        ConnectionJDBC2 con = (ConnectionJDBC2)connection;
        if (con.isXaEmulation()) {
            //
            // Emulate xa_end method
            //
            JtdsXid lxid = new JtdsXid(xid);
            if (con.getXaState() != XA_START) {
                // Connection not started
                raiseXAException(XAException.XAER_PROTO);
            }
            JtdsXid tran = (JtdsXid)con.getXid();
            if (tran == null || !tran.equals(lxid)) {
                raiseXAException(XAException.XAER_NOTA);
            }
            if (flags != XAResource.TMSUCCESS &&
                flags != XAResource.TMFAIL) {
                // TMSUSPEND and TMMIGRATE cannot be supported
                raiseXAException(XAException.XAER_INVAL);
            }
            con.setXaState(XA_END);
            return;
        }
        //
        // Execute xa_end via MSDTC
        //
        int args[] = new int[5];
        args[1] = XA_END;
        args[2] = xaConId;
        args[3] = XA_RMID;
        args[4] = flags;
        try {
            ((ConnectionJDBC2) connection).sendXaPacket(args, toBytesXid(xid));
            ((ConnectionJDBC2) connection).enlistConnection(null);
        } catch (SQLException e) {
            raiseXAException(e);
        }
        if (args[0] != XAResource.XA_OK) {
            raiseXAException(args[0]);
        }
    }

    /**
     * Invoke the xa_prepare routine on the SQL Server.
     *
     * @param connection JDBC Connection enlisted in the transaction.
     * @param xaConId    The connection ID allocated by the server.
     * @param xid        The XA Transaction ID object.
     * @return prepare status (XA_OK or XA_RDONLY) as an <code>int</code>.
     * @exception javax.transaction.xa.XAException
     *             if an error condition occurs
     */
    public static int xa_prepare(Connection connection, int xaConId, Xid xid)
            throws XAException {

        ConnectionJDBC2 con = (ConnectionJDBC2)connection;
        if (con.isXaEmulation()) {
            //
            // Emulate xa_prepare method
            // In emulation mode this is essentially a noop as we
            // are not able to offer true two phase commit.
            //
            JtdsXid lxid = new JtdsXid(xid);
            if (con.getXaState() != XA_END) {
                // Connection not ended
                raiseXAException(XAException.XAER_PROTO);
            }
            JtdsXid tran = (JtdsXid)con.getXid();
            if (tran == null || !tran.equals(lxid)) {
                raiseXAException(XAException.XAER_NOTA);
            }
            con.setXaState(XA_PREPARE);
            Logger.println("xa_prepare: Warning: Two phase commit not available in XA emulation mode.");
            return XAResource.XA_OK;
        }
        //
        // Execute xa_prepare via MSDTC
        //
        int args[] = new int[5];
        args[1] = XA_PREPARE;
        args[2] = xaConId;
        args[3] = XA_RMID;
        args[4] = XAResource.TMNOFLAGS;
        try {
            ((ConnectionJDBC2) connection).sendXaPacket(args, toBytesXid(xid));
        } catch (SQLException e) {
            raiseXAException(e);
        }
        if (args[0] != XAResource.XA_OK && args[0] != XAResource.XA_RDONLY) {
            raiseXAException(args[0]);
        }
        return args[0];
    }

    /**
     * Invoke the xa_commit routine on the SQL Server.
     *
     * @param connection JDBC Connection enlisted in the transaction
     * @param xaConId    the connection ID allocated by the server
     * @param xid        the XA Transaction ID object
     * @param onePhase   <code>true</code> if single phase commit required
     * @exception javax.transaction.xa.XAException
     *             if an error condition occurs
     */
    public static void xa_commit(Connection connection, int xaConId, Xid xid, boolean onePhase)
            throws XAException {

        ConnectionJDBC2 con = (ConnectionJDBC2)connection;
        if (con.isXaEmulation()) {
            //
            // Emulate xa_commit method
            //
            JtdsXid lxid = new JtdsXid(xid);
            if (con.getXaState() != XA_END &&
                con.getXaState() != XA_PREPARE) {
                // Connection not ended or prepared
                raiseXAException(XAException.XAER_PROTO);
            }
            JtdsXid tran = (JtdsXid)con.getXid();
            if (tran == null || !tran.equals(lxid)) {
                raiseXAException(XAException.XAER_NOTA);
            }
            con.setXid(null);
            try {
                con.commit();
            } catch (SQLException e) {
                raiseXAException(e);
            } finally {
                try {
                    con.setAutoCommit(true);
                } catch(SQLException e) {
                    Logger.println("xa_close: setAutoCommit() returned " + e);
                }
                con.setXaState(XA_OPEN);
            }
            return;
        }
        //
        // Execute xa_commit via MSDTC
        //
        int args[] = new int[5];
        args[1] = XA_COMMIT;
        args[2] = xaConId;
        args[3] = XA_RMID;
        args[4] = (onePhase) ? XAResource.TMONEPHASE : XAResource.TMNOFLAGS;
        try {
            ((ConnectionJDBC2) connection).sendXaPacket(args, toBytesXid(xid));
        } catch (SQLException e) {
            raiseXAException(e);
        }
        if (args[0] != XAResource.XA_OK) {
            raiseXAException(args[0]);
        }
    }

    /**
     * Invoke the xa_rollback routine on the SQL Server.
     *
     * @param connection JDBC Connection enlisted in the transaction
     * @param xaConId    the connection ID allocated by the server
     * @param xid        the XA Transaction ID object
     * @exception javax.transaction.xa.XAException
     *             if an error condition occurs
     */
    public static void xa_rollback(Connection connection, int xaConId, Xid xid)
            throws XAException {

        ConnectionJDBC2 con = (ConnectionJDBC2)connection;
        if (con.isXaEmulation()) {
            //
            // Emulate xa_rollback method
            //
            JtdsXid lxid = new JtdsXid(xid);
            if (con.getXaState()!= XA_END && con.getXaState() != XA_PREPARE) {
                // Connection not ended
                raiseXAException(XAException.XAER_PROTO);
            }
            JtdsXid tran = (JtdsXid)con.getXid();
            if (tran == null || !tran.equals(lxid)) {
                raiseXAException(XAException.XAER_NOTA);
            }
            con.setXid(null);
            try {
                con.rollback();
            } catch (SQLException e) {
                raiseXAException(e);
            } finally {
                try {
                    con.setAutoCommit(true);
                } catch(SQLException e) {
                    Logger.println("xa_close: setAutoCommit() returned " + e);
                }
                con.setXaState(XA_OPEN);
            }
            return;
        }
        //
        // Execute xa_rollback via MSDTC
        //
        int args[] = new int[5];
        args[1] = XA_ROLLBACK;
        args[2] = xaConId;
        args[3] = XA_RMID;
        args[4] = XAResource.TMNOFLAGS;
        try {
            ((ConnectionJDBC2) connection).sendXaPacket(args, toBytesXid(xid));
        } catch (SQLException e) {
            raiseXAException(e);
        }
        if (args[0] != XAResource.XA_OK) {
            raiseXAException(args[0]);
        }
    }

    /**
     * Invoke the xa_recover routine on the SQL Server.
     * <p/>
     * This version of xa_recover will return all XIDs on the first call.
     *
     * @param connection JDBC Connection enlisted in the transaction
     * @param xaConId    the connection ID allocated by the server
     * @param flags      XA Flags for start command
     * @return transactions to recover as a <code>Xid[]</code>
     * @exception javax.transaction.xa.XAException
     *             if an error condition occurs
     */
    public static Xid[] xa_recover(Connection connection, int xaConId, int flags)
            throws XAException {

        ConnectionJDBC2 con = (ConnectionJDBC2)connection;
        if (con.isXaEmulation()) {
            //
            // Emulate xa_recover method
            //
            // There is no state available all uncommited transactions
            // will have been rolled back by the server.
            if (flags != XAResource.TMSTARTRSCAN &&
                flags != XAResource.TMENDRSCAN &&
                flags != XAResource.TMNOFLAGS) {
                raiseXAException(XAException.XAER_INVAL);
            }
            return new JtdsXid[0];
        }
        //
        // Execute xa_recover via MSDTC
        //
        int args[] = new int[5];
        args[1] = XA_RECOVER;
        args[2] = xaConId;
        args[3] = XA_RMID;
        args[4] = XAResource.TMNOFLAGS;
        Xid[] list = null;

        if (flags != XAResource.TMSTARTRSCAN) {
            return new JtdsXid[0];
        }

        try {
            byte[][] buffer = ((ConnectionJDBC2) connection).sendXaPacket(args, null);
            if (args[0] >= 0) {
                int n = buffer.length;
                list = new JtdsXid[n];
                for (int i = 0; i < n; i++) {
                    list[i] = new JtdsXid(buffer[i], 0);
                }
            }
        } catch (SQLException e) {
            raiseXAException(e);
        }
        if (args[0] < 0) {
            raiseXAException(args[0]);
        }
        if (list == null) {
            list = new JtdsXid[0];
        }
        return list;
    }

    /**
     * Invoke the xa_forget routine on the SQL Server.
     *
     * @param connection JDBC Connection enlisted in the transaction
     * @param xaConId    the connection ID allocated by the server
     * @param xid        the XA Transaction ID object
     * @exception javax.transaction.xa.XAException
     *             if an error condition occurs
     */
    public static void xa_forget(Connection connection, int xaConId, Xid xid)
            throws XAException {

        ConnectionJDBC2 con = (ConnectionJDBC2)connection;
        if (con.isXaEmulation()) {
            //
            // Emulate xa_forget method
            //
            JtdsXid lxid = new JtdsXid(xid);
            JtdsXid tran = (JtdsXid)con.getXid();
            if (tran == null || !tran.equals(lxid)) {
                raiseXAException(XAException.XAER_NOTA);
            }
            if (con.getXaState() != XA_END && con.getXaState() != XA_PREPARE) {
               // Connection not ended
               raiseXAException(XAException.XAER_PROTO);
            }
            con.setXid(null);
            try {
                 con.rollback();
            } catch (SQLException e) {
                raiseXAException(e);
            } finally {
                try {
                    con.setAutoCommit(true);
                } catch(SQLException e) {
                    Logger.println("xa_close: setAutoCommit() returned " + e);
                }
                con.setXaState(XA_OPEN);
            }
            return;
        }
        //
        // Execute xa_forget via MSDTC
        //
        int args[] = new int[5];
        args[1] = XA_FORGET;
        args[2] = xaConId;
        args[3] = XA_RMID;
        args[4] = XAResource.TMNOFLAGS;
        try {
            ((ConnectionJDBC2) connection).sendXaPacket(args, toBytesXid(xid));
        } catch (SQLException e) {
            raiseXAException(e);
        }
        if (args[0] != XAResource.XA_OK) {
            raiseXAException(args[0]);
        }
    }

    /**
     * Construct and throw an <code>XAException</code> with an explanatory message derived from the
     * <code>SQLException</code> and the XA error code set to <code>XAER_RMFAIL</code>.
     *
     * @param sqle The SQLException.
     * @exception javax.transaction.xa.XAException
     *             exception derived from the code>SQLException</code>
     */
    public static void raiseXAException(SQLException sqle)
            throws XAException {
        XAException e = new XAException(sqle.getMessage());
        e.errorCode = XAException.XAER_RMFAIL;
        Logger.println("XAException: " + e.getMessage());
        throw e;
    }

    /**
     * Construct and throw an <code>XAException</code> with an explanatory message and the XA error code set.
     *
     * @param errorCode the XA Error code
     * @exception javax.transaction.xa.XAException
     *             the constructed exception
     */
    public static void raiseXAException(int errorCode)
            throws XAException {
        String err = "xaerunknown";
        switch (errorCode) {
            case XAException.XA_RBROLLBACK:
                err = "xarbrollback";
                break;
            case XAException.XA_RBCOMMFAIL:
                err = "xarbcommfail";
                break;
            case XAException.XA_RBDEADLOCK:
                err = "xarbdeadlock";
                break;
            case XAException.XA_RBINTEGRITY:
                err = "xarbintegrity";
                break;
            case XAException.XA_RBOTHER:
                err = "xarbother";
                break;
            case XAException.XA_RBPROTO:
                err = "xarbproto";
                break;
            case XAException.XA_RBTIMEOUT:
                err = "xarbtimeout";
                break;
            case XAException.XA_RBTRANSIENT:
                err = "xarbtransient";
                break;
            case XAException.XA_NOMIGRATE:
                err = "xanomigrate";
                break;
            case XAException.XA_HEURHAZ:
                err = "xaheurhaz";
                break;
            case XAException.XA_HEURCOM:
                err = "xaheurcom";
                break;
            case XAException.XA_HEURRB:
                err = "xaheurrb";
                break;
            case XAException.XA_HEURMIX:
                err = "xaheurmix";
                break;
            case XAException.XA_RETRY:
                err = "xaretry";
                break;
            case XAException.XA_RDONLY:
                err = "xardonly";
                break;
            case XAException.XAER_ASYNC:
                err = "xaerasync";
                break;
            case XAException.XAER_NOTA:
                err = "xaernota";
                break;
            case XAException.XAER_INVAL:
                err = "xaerinval";
                break;
            case XAException.XAER_PROTO:
                err = "xaerproto";
                break;
            case XAException.XAER_RMERR:
                err = "xaerrmerr";
                break;
            case XAException.XAER_RMFAIL:
                err = "xaerrmfail";
                break;
            case XAException.XAER_DUPID:
                err = "xaerdupid";
                break;
            case XAException.XAER_OUTSIDE:
                err = "xaeroutside";
                break;
        }
        XAException e = new XAException(Messages.get("error.xaexception." + err));
        e.errorCode = errorCode;
        Logger.println("XAException: " + e.getMessage());
        throw e;
    }

    // ------------- Private methods  ---------

    /**
     * Format an XA transaction ID into a 140 byte array.
     *
     * @param xid the XA transaction ID
     * @return the formatted ID as a <code>byte[]</code>
     */
    private static byte[] toBytesXid(Xid xid) {
        byte[] buffer = new byte[12 +
                xid.getGlobalTransactionId().length +
                xid.getBranchQualifier().length];
        int fmt = xid.getFormatId();
        buffer[0] = (byte) fmt;
        buffer[1] = (byte) (fmt >> 8);
        buffer[2] = (byte) (fmt >> 16);
        buffer[3] = (byte) (fmt >> 24);
        buffer[4] = (byte) xid.getGlobalTransactionId().length;
        buffer[8] = (byte) xid.getBranchQualifier().length;
        System.arraycopy(xid.getGlobalTransactionId(), 0, buffer, 12, buffer[4]);
        System.arraycopy(xid.getBranchQualifier(), 0, buffer, 12 + buffer[4], buffer[8]);
        return buffer;
    }

    private XASupport() {
        // Prevent an instance of this class being created.
    }
}
