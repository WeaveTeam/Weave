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
package net.sourceforge.jtds.test;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import javax.sql.XAConnection;
import javax.sql.XADataSource;
import javax.transaction.xa.XAException;
import javax.transaction.xa.XAResource;
import javax.transaction.xa.Xid;

import net.sourceforge.jtds.jdbc.Messages;
import net.sourceforge.jtds.jdbc.Driver;
import net.sourceforge.jtds.jdbcx.JtdsDataSource;
import net.sourceforge.jtds.jdbcx.JtdsXid;

/**
 * Test suite for XA Distributed Transactions. These tests are derived from
 * examples found in the following article at
 * <a href="http://archive.devx.com/java/free/articles/dd_jta/jta-2.asp">DevX</a>.
 *
 * @version $Id: XaTest.java,v 1.5 2004-12-03 16:52:09 alin_sinpalean Exp $
 */
public class XaTest extends DatabaseTestCase {

    public XaTest(String name) {
        super(name);
    }

    /**
     * Obtain an XADataSource.
     *
     * @return the <code>XADataSource.
     * @throws SQLException if an error condition occurs
     */
    public XADataSource getDataSource() throws SQLException {
        JtdsDataSource xaDS = new JtdsDataSource();
        String user     = props.getProperty(Messages.get(Driver.USER));
        String pwd      = props.getProperty(Messages.get(Driver.PASSWORD));
        String host     = props.getProperty(Messages.get(Driver.SERVERNAME));
        String port     = props.getProperty(Messages.get(Driver.PORTNUMBER));
        String database = props.getProperty(Messages.get(Driver.DATABASENAME));
        String xaMode   = props.getProperty(Messages.get(Driver.XAEMULATION));
        String tds      = props.getProperty(Messages.get(Driver.TDS));
        String serverType = props.getProperty(Messages.get(Driver.SERVERTYPE));
        int portn;
        try {
            portn = Integer.parseInt(port);
        } catch (NumberFormatException e) {
            portn = 1433;
        }
        xaDS.setServerName(host);
        xaDS.setPortNumber(portn);
        xaDS.setUser(user);
        xaDS.setPassword(pwd);
        xaDS.setDatabaseName(database);
        xaDS.setXaEmulation(xaMode.equalsIgnoreCase("true"));
        xaDS.setTds(tds);
        xaDS.setServerType("2".equals(serverType)? 2: 1);
        return xaDS;
    }

    /**
     * Test to demonstrate the XA_COMMIT function.
     *
     * @throws Exception if an error condition occurs
     */
    public void testXaCommit() throws Exception {
        Connection con2 = null;
        XAConnection xaCon = null;

        try {
            dropTable("jTDS_XATEST");

            Statement stmt = con.createStatement();
            stmt.execute("CREATE TABLE jTDS_XATEST (id int primary key, data varchar(255))");
            assertNotNull(stmt.executeQuery("SELECT * FROM jTDS_XATEST"));
            stmt.close();

            XADataSource xaDS = getDataSource();
            XAResource xaRes;
            Xid  xid;
            xaCon = xaDS.getXAConnection();
            xaRes = xaCon.getXAResource();
            con2 = xaCon.getConnection();
            stmt = con2.createStatement();
            xid = new JtdsXid(new byte[]{0x01}, new byte[]{0x02});

            xaRes.start(xid, XAResource.TMNOFLAGS);
            stmt.executeUpdate("INSERT INTO jTDS_XATEST VALUES (1, 'TEST LINE')");
            xaRes.end(xid, XAResource.TMSUCCESS);
            int ret = xaRes.prepare(xid);
            if (ret == XAResource.XA_OK) {
                xaRes.commit(xid, false);
            }
            stmt.close();
            stmt = con.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT * FROM jTDS_XATEST");
            assertNotNull(rs);
            assertTrue(rs.next());
            stmt.close();
        } finally {
            if (con2 != null) {
                con2.close();
            }
            if (xaCon != null) {
                xaCon.close();
            }

            dropTable("jTDS_XATEST");
        }
    }

    /**
     * Test to demonstrate the single phase XA_COMMIT function.
     *
     * @throws Exception if an error condition occurs
     */
    public void testXaOnePhaseCommit() throws Exception {
        Connection con2 = null;
        XAConnection xaCon = null;

        try {
            dropTable("jTDS_XATEST");

            Statement stmt = con.createStatement();
            stmt.execute("CREATE TABLE jTDS_XATEST (id int primary key, data varchar(255))");
            assertNotNull(stmt.executeQuery("SELECT * FROM jTDS_XATEST"));
            stmt.close();

            XADataSource xaDS = getDataSource();
            XAResource xaRes;
            Xid  xid;
            xaCon = xaDS.getXAConnection();
            xaRes = xaCon.getXAResource();
            con2 = xaCon.getConnection();
            stmt = con2.createStatement();
            xid = new JtdsXid(new byte[]{0x01}, new byte[]{0x02});

            xaRes.start(xid, XAResource.TMNOFLAGS);
            stmt.executeUpdate("INSERT INTO jTDS_XATEST VALUES (1, 'TEST LINE')");
            xaRes.end(xid, XAResource.TMSUCCESS);
            xaRes.commit(xid, true);
            stmt.close();
            stmt = con.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT * FROM jTDS_XATEST");
            assertNotNull(rs);
            assertTrue(rs.next());
            stmt.close();
        } finally {
            if (con2 != null) {
                con2.close();
            }
            if (xaCon != null) {
                xaCon.close();
            }

            dropTable("jTDS_XATEST");
        }
    }

    /**
     * Test to demonstrate the use of the XA_ROLLBACK command.
     *
     * @throws Exception if an error condition occurs
     */
    public void testXaRollback() throws Exception {
        Connection con2 = null;
        XAConnection xaCon = null;

        try {
            dropTable("jTDS_XATEST");

            Statement stmt = con.createStatement();
            stmt.execute("CREATE TABLE jTDS_XATEST (id int primary key, data varchar(255))");
            assertNotNull(stmt.executeQuery("SELECT * FROM jTDS_XATEST"));
            stmt.close();

            XADataSource xaDS = getDataSource();
            XAResource xaRes;
            Xid  xid;
            xaCon = xaDS.getXAConnection();
            xaRes = xaCon.getXAResource();
            con2 = xaCon.getConnection();
            stmt = con2.createStatement();
            xid = new JtdsXid(new byte[]{0x01}, new byte[]{0x02});

            xaRes.start(xid, XAResource.TMNOFLAGS);
            stmt.executeUpdate("INSERT INTO jTDS_XATEST VALUES (1, 'TEST LINE')");
            xaRes.end(xid, XAResource.TMSUCCESS);
            xaRes.rollback(xid);
            stmt.close();
            stmt = con.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT * FROM jTDS_XATEST");
            assertNotNull(rs);
            assertFalse(rs.next());
            stmt.close();
        } finally {
            if (con2 != null) {
                con2.close();
            }
            if (xaCon != null) {
                xaCon.close();
            }

            dropTable("jTDS_XATEST");
        }
    }

    /**
     * Demonstrate interleaving local transactions and distributed
     * transactions.
     *
     * @throws Exception if an error condition occurs
     */
    public void testLocalTran() throws Exception {
        if ("true".equalsIgnoreCase(props.getProperty(Messages.get(Driver.XAEMULATION)))) {
            // Emulation mode does not support suspending transactions.
            return;
        }
        Connection con2 = null;
        XAConnection xaCon = null;

        try {
            dropTable("jTDS_XATEST");
            dropTable("jTDS_XATEST2");

            Statement stmt = con.createStatement();
            stmt.execute("CREATE TABLE jTDS_XATEST (id int primary key, data varchar(255))");
            stmt.execute("CREATE TABLE jTDS_XATEST2 (id int primary key, data varchar(255))");
            assertNotNull(stmt.executeQuery("SELECT * FROM jTDS_XATEST"));
            assertNotNull(stmt.executeQuery("SELECT * FROM jTDS_XATEST2"));
            stmt.close();

            XADataSource xaDS = getDataSource();
            XAResource xaRes;
            Xid  xid;
            xaCon = xaDS.getXAConnection();
            xaRes = xaCon.getXAResource();
            con2 = xaCon.getConnection();
            stmt = con2.createStatement();
            xid = new JtdsXid(new byte[]{0x01}, new byte[]{0x02});

            xaRes.start(xid, XAResource.TMNOFLAGS);
            stmt.executeUpdate("INSERT INTO jTDS_XATEST VALUES (1, 'TEST LINE')");
            xaRes.end(xid, XAResource.TMSUSPEND);
            stmt.executeUpdate("INSERT INTO jTDS_XATEST2 VALUES (1, 'TEST LINE')");
            xaRes.start(xid, XAResource.TMRESUME);
            stmt.executeUpdate("INSERT INTO jTDS_XATEST VALUES (2, 'TEST LINE 2')");
            xaRes.end(xid, XAResource.TMSUCCESS);
            xaRes.rollback(xid);
            stmt.close();
            stmt = con.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT * FROM jTDS_XATEST");
            assertNotNull(rs);
            assertFalse(rs.next());
            rs = stmt.executeQuery("SELECT * FROM jTDS_XATEST2");
            assertNotNull(rs);
            assertTrue(rs.next());
            stmt.close();
        } finally {
            if (con2 != null) {
                con2.close();
            }
            if (xaCon != null) {
                xaCon.close();
            }

            dropTable("jTDS_XATEST");
            dropTable("jTDS_XATEST2");
        }
    }

    /**
     * Test to demonstrate the use of the XA_JOIN command.
     *
     * @throws Exception if an error condition occurs
     */
    public void testXAJoinTran() throws Exception {
        if ("true".equalsIgnoreCase(props.getProperty(Messages.get(Driver.XAEMULATION)))) {
            // Emulation mode does not joining transactions.
            return;
        }
        Connection con2 = null;
        Connection con3 = null;
        XAConnection xaCon = null;
        XAConnection xaCon2 = null;

        try {
            dropTable("jTDS_XATEST");
            dropTable("jTDS_XATEST2");

            Statement stmt = con.createStatement();
            stmt.execute("CREATE TABLE jTDS_XATEST (id int primary key, data varchar(255))");
            stmt.execute("CREATE TABLE jTDS_XATEST2 (id int primary key, data varchar(255))");
            assertNotNull(stmt.executeQuery("SELECT * FROM jTDS_XATEST"));
            assertNotNull(stmt.executeQuery("SELECT * FROM jTDS_XATEST2"));
            stmt.close();

            XADataSource xaDS = getDataSource();
            XAResource xaRes;
            XAResource xaRes2;
            Xid  xid;
            xaCon = xaDS.getXAConnection();
            xaRes = xaCon.getXAResource();
            xaCon2 = xaDS.getXAConnection();
            xaRes2 = xaCon2.getXAResource();
            con2 = xaCon.getConnection();
            con3 = xaCon2.getConnection();
            stmt = con2.createStatement();
            Statement stmt2 = con3.createStatement();
            xid = new JtdsXid(new byte[]{0x01}, new byte[]{0x02});

            xaRes.start(xid, XAResource.TMNOFLAGS);
            stmt.executeUpdate("INSERT INTO jTDS_XATEST VALUES (1, 'TEST LINE')");
            assertTrue(xaRes.isSameRM(xaRes2));
            xaRes2.start(xid, XAResource.TMJOIN);
            stmt2.executeUpdate("INSERT INTO jTDS_XATEST2 VALUES (1, 'TEST LINE 2')");
            xaRes.end(xid, XAResource.TMSUCCESS);
            xaRes2.end(xid, XAResource.TMSUCCESS);

            int ret = xaRes.prepare(xid);
            if (ret == XAResource.XA_OK) {
                xaRes.commit(xid, false);
            }
            stmt.close();
            stmt2.close();
            stmt = con.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT * FROM jTDS_XATEST");
            assertNotNull(rs);
            assertTrue(rs.next());
            rs = stmt.executeQuery("SELECT * FROM jTDS_XATEST2");
            assertNotNull(rs);
            assertTrue(rs.next());
            stmt.close();
        } finally {
            if (con2 != null) {
                con2.close();
            }
            if (con3 != null) {
                con3.close();
            }
            if (xaCon != null) {
                xaCon.close();
            }
            if (xaCon2 != null) {
                xaCon2.close();
            }

            dropTable("jTDS_XATEST");
            dropTable("jTDS_XATEST2");
        }
    }

    /**
     * Test to demonstrate the use of the XA_RECOVER command.
     *
     * @throws Exception if an error condition occurs
     */
    public void testXARecover() throws Exception {
        XAConnection xaCon = null;

        try {
            dropTable("jTDS_XATEST");

            Statement stmt = con.createStatement();
            stmt.execute("CREATE TABLE jTDS_XATEST (id int primary key, data varchar(255))");
            assertNotNull(stmt.executeQuery("SELECT * FROM jTDS_XATEST"));
            stmt.close();

            XADataSource xaDS  = getDataSource();
            xaCon = xaDS.getXAConnection();
            Connection con2 = xaCon.getConnection();
            XAResource xaRes  = xaCon.getXAResource();
            stmt = con2.createStatement();
            Xid xid;
            xid = new JtdsXid(new byte[]{0x01}, new byte[]{0x02});

            xaRes.start(xid, XAResource.TMNOFLAGS);
            stmt.executeUpdate("INSERT INTO jTDS_XATEST VALUES (1, 'TEST LINE')");
            xaRes.end(xid, XAResource.TMSUCCESS);
            xaRes.prepare(xid);
            stmt.close();
            con2.close();
            xaCon.close();
            xaCon = xaDS.getXAConnection();
            xaRes = xaCon.getXAResource();
            Xid[] list = xaRes.recover(XAResource.TMSTARTRSCAN);
            for (int i = 0; i < list.length; i++) {
               //System.out.println("Xid="+list[i].toString());
               try {
                    xaRes.rollback(list[i]);
               } catch (XAException e) {
                //  System.out.println("Forgetting");
                    xaRes.forget(list[i]);
               }
           }
        } finally {
            if (xaCon != null) {
                xaCon.close();
            }

            dropTable("jTDS_XATEST");
        }
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(XaTest.class);
    }
}
