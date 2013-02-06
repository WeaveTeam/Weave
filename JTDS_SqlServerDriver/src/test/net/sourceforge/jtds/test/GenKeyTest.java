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

import java.sql.*;

/**
 * Test case to illustrate JDBC 3 GetGeneratedKeys() function.
 *
 * @version    1.0
 */
public class GenKeyTest extends TestBase {

    public GenKeyTest(String name) {
        super(name);
    }

    public void testParams() throws Exception {
        //
        // Test data
        //
        Statement stmt = con.createStatement();

        stmt.execute("CREATE TABLE #gktemp (id INT IDENTITY (1,1) PRIMARY KEY, dummyx VARCHAR(50))");

        stmt.close();
        //
        // Test PrepareStatement(sql, int) option
        //
        PreparedStatement pstmt =
        con.prepareStatement("INSERT INTO #gktemp (dummyx) VALUES (?)", Statement.RETURN_GENERATED_KEYS);
        pstmt.setString(1, "TEST01");
        assertEquals("First Insert failed", 1, pstmt.executeUpdate());
        ResultSet rs = pstmt.getGeneratedKeys();
        assertTrue("ResultSet empty", rs.next());
        assertEquals("Bad inserted row ID ", 1, rs.getInt(1));
        rs.close();
        pstmt.close();
        //
        // Test PrepareStatement(sql, int[]) option
        //
        int cols[] = new int[1];
        cols[0] = 1;
        pstmt =
        con.prepareStatement("INSERT INTO #gktemp (dummyx) VALUES (?)", cols);
        pstmt.setString(1, "TEST02");
        assertEquals("Second Insert failed", 1, pstmt.executeUpdate());
        rs = pstmt.getGeneratedKeys();
        assertTrue("ResultSet 2 empty", rs.next());
        assertEquals("Bad inserted row ID ", 2, rs.getInt(1));
        rs.close();
        pstmt.close();
        //
        // Test PrepareStatement(sql, String[]) option
        //
        String colNames[] = new String[1];
        colNames[0] = "ID";
        pstmt =
        con.prepareStatement("INSERT INTO #gktemp (dummyx) VALUES (?)", colNames);
        pstmt.setString(1, "TEST03");
        pstmt.execute();
        assertEquals("Third Insert failed", 1, pstmt.getUpdateCount());
        rs = pstmt.getGeneratedKeys();
        assertTrue("ResultSet 3 empty", rs.next());
        assertEquals("Bad inserted row ID ", 3, rs.getInt(1));
        rs.close();
        pstmt.close();
        //
        // Test CreateStatement()
        //
        stmt = con.createStatement();
        assertEquals("Fourth Insert failed", 1,
                     stmt.executeUpdate("INSERT INTO #gktemp (dummyx) VALUES ('TEST04')",
                                        Statement.RETURN_GENERATED_KEYS));
        rs = stmt.getGeneratedKeys();
        assertTrue("ResultSet 4 empty", rs.next());
        assertEquals("Bad inserted row ID ", 4, rs.getInt(1));
        rs.close();
        stmt.close();

        stmt = con.createStatement();

        stmt.execute("DROP TABLE #gktemp");

        stmt.close();
    }

    /**
     * Test for bug [930305] getGeneratedKeys() does not work with triggers
     */
    public void testTrigger1() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE jtdsTestTrigger1 (id INT IDENTITY (1,1) PRIMARY KEY, data INT)");
        stmt.execute("CREATE TABLE jtdsTestTrigger2 (id INT IDENTITY (1,1) PRIMARY KEY, data INT)");
        stmt.close();

        try {
            stmt = con.createStatement();
            stmt.execute("CREATE TRIGGER testTrigger1 ON jtdsTestTrigger1 FOR INSERT AS "
                    + "INSERT INTO jtdsTestTrigger2 (data) VALUES (1)");
            stmt.close();

            PreparedStatement pstmt = con.prepareStatement(
                    "INSERT INTO jtdsTestTrigger1 (data) VALUES (?)",
                    Statement.RETURN_GENERATED_KEYS);

            for (int i = 0; i < 10; i++) {
                pstmt.setInt(1, i);
                assertEquals("Insert failed: " + i, 1, pstmt.executeUpdate());

                ResultSet rs = pstmt.getGeneratedKeys();

                assertTrue("ResultSet empty: " + i, rs.next());
                assertEquals("Bad inserted row ID: " + i, i + 1, rs.getInt(1));
                assertTrue("ResultSet not empty: " + i, !rs.next());
                rs.close();
            }

            pstmt.close();
        } finally {
            stmt = con.createStatement();
            stmt.execute("DROP TABLE jtdsTestTrigger1");
            stmt.execute("DROP TABLE jtdsTestTrigger2");
            stmt.close();
        }
    }

    /**
     * Test empty result set returned when no keys available.
     */
    public void testNoKeys() throws Exception {
        Statement stmt = con.createStatement();
        ResultSet rs = stmt.getGeneratedKeys();
        assertEquals("ID", rs.getMetaData().getColumnName(1));
        assertFalse(rs.next());
    }

    /**
     * Test that SELECT statements work correctly with
     * <code>PreparedStatement</code>s created with
     * <code>RETURN_GENERATED_KEYS</code>.
     */
    public void testSelect() throws SQLException {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #colors (id int, color varchar(255))");
        stmt.executeUpdate("insert into #colors values (1, 'red')");
        stmt.executeUpdate("insert into #colors values (1, 'green')");
        stmt.executeUpdate("insert into #colors values (1, 'blue')");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement(
                "select * from #colors", Statement.RETURN_GENERATED_KEYS);

        assertTrue(pstmt.execute());
        ResultSet rs = pstmt.getResultSet();
        assertEquals(2, rs.getMetaData().getColumnCount());
        assertTrue(rs.next());
        assertTrue(rs.next());
        assertTrue(rs.next());
        assertFalse(rs.next());
        rs.close();
        assertFalse(pstmt.getMoreResults());
        assertEquals(-1, pstmt.getUpdateCount());

        rs = pstmt.executeQuery();
        assertEquals(2, rs.getMetaData().getColumnCount());
        assertTrue(rs.next());
        assertTrue(rs.next());
        assertTrue(rs.next());
        assertFalse(rs.next());
        rs.close();
        pstmt.close();
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(GenKeyTest.class);
    }
}
