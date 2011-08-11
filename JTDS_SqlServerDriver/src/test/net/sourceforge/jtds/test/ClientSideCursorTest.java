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
package net.sourceforge.jtds.test;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Test case to illustrate use of Cached cursor result set.
 *
 * @version 1.0
 * @author Mike Hutchinson
 */
public class ClientSideCursorTest extends DatabaseTestCase {

    public ClientSideCursorTest(String name) {
        super(name);
    }

    /**
     * General test of scrollable cursor functionality.
     * <p/>
     * When running on SQL Server this test will exercise MSCursorResultSet.
     * When running on Sybase this test will exercise CachedResultSet.
     */
    public void testCachedCursor() throws Exception {
        try {
            dropTable("jTDS_CachedCursorTest");
            Statement stmt = con.createStatement();
            stmt.execute("CREATE TABLE jTDS_CachedCursorTest " +
                    "(key1 int NOT NULL, key2 char(4) NOT NULL," +
                    "data varchar(255))\r\n" +
                    "ALTER TABLE jTDS_CachedCursorTest " +
                    "ADD CONSTRAINT PK_jTDS_CachedCursorTest PRIMARY KEY CLUSTERED" +
                    "( key1, key2)");
            for (int i = 1; i <= 16; i++) {
                assertEquals(1, stmt.executeUpdate("INSERT INTO jTDS_CachedCursorTest VALUES(" + i + ", 'XXXX','LINE " + i + "')"));
            }
            stmt.close();
            stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
            ResultSet rs = stmt.executeQuery("SELECT * FROM jTDS_CachedCursorTest ORDER BY key1");
            assertNotNull(rs);
            assertEquals(null, stmt.getWarnings());
            assertTrue(rs.isBeforeFirst());
            assertTrue(rs.first());
            assertEquals(1, rs.getInt(1));
            assertTrue(rs.isFirst());
            assertTrue(rs.last());
            assertEquals(16, rs.getInt(1));
            assertTrue(rs.isLast());
            assertFalse(rs.next());
            assertTrue(rs.isAfterLast());
            rs.beforeFirst();
            assertTrue(rs.next());
            assertEquals(1, rs.getInt(1));
            rs.afterLast();
            assertTrue(rs.previous());
            assertEquals(16, rs.getInt(1));
            assertTrue(rs.absolute(8));
            assertEquals(8, rs.getInt(1));
            assertTrue(rs.relative(-1));
            assertEquals(7, rs.getInt(1));
            rs.updateString(3, "New line 7");
            rs.updateRow();
//            assertTrue(rs.rowUpdated()); // MS API cursors appear not to support this
            rs.moveToInsertRow();
            rs.updateInt(1, 17);
            rs.updateString(2, "XXXX");
            rs.updateString(3, "LINE 17");
            rs.insertRow();
            rs.moveToCurrentRow();
            rs.last();
//            assertTrue(rs.rowInserted()); // MS API cursors appear not to support this
            Statement stmt2 = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_READ_ONLY);
            ResultSet rs2 = stmt2.executeQuery("SELECT * FROM jTDS_CachedCursorTest ORDER BY key1");
            rs.updateString(3, "NEW LINE 17");
            rs.updateRow();
            assertTrue(rs2.last());
            assertEquals(17, rs2.getInt(1));
            assertEquals("NEW LINE 17", rs2.getString(3));
            rs.deleteRow();
            rs2.refreshRow();
            assertTrue(rs2.rowDeleted());
            rs2.close();
            stmt2.close();
            rs.close();
            stmt.close();
        } finally {
            dropTable("jTDS_CachedCursorTest");
        }
    }

    /**
     * Test support for JDBC 1 style positioned updates with named cursors.
     * <p/>
     * When running on SQL Server this test will exercise MSCursorResultSet.
     * When running on Sybase this test will exercise CachedResultSet.
     */
     public void testPositionedUpdate() throws Exception {
         assertTrue(con.getMetaData().supportsPositionedDelete());
         assertTrue(con.getMetaData().supportsPositionedUpdate());
         Statement stmt = con.createStatement();
         stmt.execute("CREATE TABLE #TESTPOS (id INT primary key, data VARCHAR(255))");
         for (int i = 1; i <  5; i++) {
             stmt.execute("INSERT INTO #TESTPOS VALUES(" + i + ", 'This is line " + i + "')");
         }
         stmt.setCursorName("curname");
         ResultSet rs = stmt.executeQuery("SELECT * FROM #TESTPOS FOR UPDATE");
         Statement stmt2 = con.createStatement();
         while (rs.next()) {
             if (rs.getInt(1) == 1) {
                 stmt2.execute("UPDATE #TESTPOS SET data = 'Updated' WHERE CURRENT OF curname");
             } else
             if (rs.getInt(1) == 3) {
                 stmt2.execute("DELETE FROM #TESTPOS WHERE CURRENT OF curname");
             }
         }
         rs.close();
         stmt.setFetchSize(100);
         rs = stmt.executeQuery("SELECT * FROM #TESTPOS");
         while (rs.next()) {
             int id = rs.getInt(1);
             assertTrue(id != 3); // Should have been deleted
             if (id == 1) {
                 assertEquals("Updated", rs.getString(2));
             }
         }
         stmt2.close();
         stmt.close();
     }

     /**
      * Test optimistic updates throw exception if row is changed on disk.
      * <p/>
      * When running on SQL Server this test will exercise MSCursorResultSet.
      * When running on Sybase this test will exercise CachedResultSet.
      */
     public void testOptimisticUpdates() throws Exception {
         Connection con2 = getConnection();
         try {
             dropTable("jTDS_CachedCursorTest");
             Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
             ResultSet rs;
             stmt.execute("CREATE TABLE jTDS_CachedCursorTest (id int primary key, data varchar(255))");
             for (int i = 0; i < 4; i++) {
                 stmt.executeUpdate("INSERT INTO jTDS_CachedCursorTest VALUES("+i+", 'Table A line "+i+"')");
             }
             // Open cursor
             rs = stmt.executeQuery("SELECT id, data FROM jTDS_CachedCursorTest");
             Statement stmt2 = con2.createStatement();
             while (rs.next()) {
                 if (rs.getInt(1) == 1) {
                     assertEquals(1, stmt2.executeUpdate("UPDATE jTDS_CachedCursorTest SET data = 'NEW VALUE' WHERE id = 1"));
                     rs.updateString(2, "TEST UPDATE");
                     try {
                         rs.updateRow();
                         assertNotNull(rs.getWarnings());
                         assertEquals("Expected optimistic update exception",
                                 "24000", rs.getWarnings().getSQLState());
                     } catch (SQLException e) {
                         // Expected exception as row has been modified on disk
                         assertEquals("24000", e.getSQLState());
                     }
                 }
             }
             rs.close();
             stmt.close();
         } finally {
             if (con2 != null) {
                 con2.close();
             }
             dropTable("jTDS_CachedCursorTest");
         }
     }

     /**
      * Test updateable result set where table is not keyed.
      * Uses a server side cursor and positioned updates on Sybase.
      */
    public void testUpdateNoKeys() throws Exception
    {
        Statement stmt = con.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE);
        stmt.execute("CREATE TABLE ##TESTNOKEY (id int, data varchar(255))");
        for (int i = 0; i < 4; i++) {
            stmt.executeUpdate("INSERT INTO ##TESTNOKEY VALUES("+i+", 'Test line "+i+"')");
        }
        ResultSet rs = stmt.executeQuery("SELECT * FROM ##TESTNOKEY");
        assertTrue(rs.next());
        assertTrue(rs.next());
        rs.updateString(2, "UPDATED");
        rs.updateRow();
        rs.close();
        rs = stmt.executeQuery("SELECT * FROM ##TESTNOKEY");
        while (rs.next()) {
            if (rs.getInt(1) == 1) {
                assertEquals("UPDATED", rs.getString(2));
            }
        }
        stmt.close();
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(ClientSideCursorTest.class);
    }
}
