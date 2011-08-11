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
import java.math.BigDecimal;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * @version 1.0
 */
public class ResultSetTest extends DatabaseTestCase {
    public ResultSetTest(String name) {
        super(name);
    }

    /**
     * Test BIT data type.
     */
    public void testGetObject1() throws Exception {
        boolean data = true;

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #getObject1 (data BIT, minval BIT, maxval BIT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #getObject1 (data, minval, maxval) VALUES (?, ?, ?)");

        pstmt.setBoolean(1, data);
        pstmt.setBoolean(2, false);
        pstmt.setBoolean(3, true);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data, minval, maxval FROM #getObject1");

        assertTrue(rs.next());

        assertTrue(rs.getBoolean(1));
        assertTrue(rs.getByte(1) == 1);
        assertTrue(rs.getShort(1) == 1);
        assertTrue(rs.getInt(1) == 1);
        assertTrue(rs.getLong(1) == 1);
        assertTrue(rs.getFloat(1) == 1);
        assertTrue(rs.getDouble(1) == 1);
        assertTrue(rs.getBigDecimal(1).byteValue() == 1);
        assertEquals("1", rs.getString(1));

        Object tmpData = rs.getObject(1);

        assertTrue(tmpData instanceof Boolean);
        assertEquals(true, ((Boolean) tmpData).booleanValue());

        ResultSetMetaData resultSetMetaData = rs.getMetaData();

        assertNotNull(resultSetMetaData);
        assertEquals(Types.BIT, resultSetMetaData.getColumnType(1));

        assertFalse(rs.getBoolean(2));
        assertTrue(rs.getBoolean(3));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    /**
     * Test TINYINT data type.
     */
    public void testGetObject2() throws Exception {
        byte data = 1;

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #getObject2 (data TINYINT, minval TINYINT, maxval TINYINT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #getObject2 (data, minval, maxval) VALUES (?, ?, ?)");

        pstmt.setByte(1, data);
        pstmt.setByte(2, (byte)0);
        pstmt.setShort(3, (short)255);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data, minval, maxval FROM #getObject2");

        assertTrue(rs.next());

        assertTrue(rs.getBoolean(1));
        assertTrue(rs.getByte(1) == 1);
        assertTrue(rs.getShort(1) == 1);
        assertTrue(rs.getInt(1) == 1);
        assertTrue(rs.getLong(1) == 1);
        assertTrue(rs.getFloat(1) == 1);
        assertTrue(rs.getDouble(1) == 1);
        assertTrue(rs.getBigDecimal(1).byteValue() == 1);
        assertEquals("1", rs.getString(1));

        Object tmpData = rs.getObject(1);

        assertTrue(tmpData instanceof Integer);
        assertEquals(data, ((Integer) tmpData).byteValue());

        ResultSetMetaData resultSetMetaData = rs.getMetaData();

        assertNotNull(resultSetMetaData);
        assertEquals(Types.TINYINT, resultSetMetaData.getColumnType(1));

        assertEquals(rs.getByte(2), 0);
        assertEquals(rs.getShort(3), 255);

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    /**
     * Test SMALLINT data type.
     */
    public void testGetObject3() throws Exception {
        short data = 1;

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #getObject3 (data SMALLINT, minval SMALLINT, maxval SMALLINT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #getObject3 (data, minval, maxval) VALUES (?, ?, ?)");

        pstmt.setShort(1, data);
        pstmt.setShort(2, Short.MIN_VALUE);
        pstmt.setShort(3, Short.MAX_VALUE);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data, minval, maxval FROM #getObject3");

        assertTrue(rs.next());

        assertTrue(rs.getBoolean(1));
        assertTrue(rs.getByte(1) == 1);
        assertTrue(rs.getShort(1) == 1);
        assertTrue(rs.getInt(1) == 1);
        assertTrue(rs.getLong(1) == 1);
        assertTrue(rs.getFloat(1) == 1);
        assertTrue(rs.getDouble(1) == 1);
        assertTrue(rs.getBigDecimal(1).shortValue() == 1);
        assertEquals("1", rs.getString(1));

        Object tmpData = rs.getObject(1);

        assertTrue(tmpData instanceof Integer);
        assertEquals(data, ((Integer) tmpData).shortValue());

        ResultSetMetaData resultSetMetaData = rs.getMetaData();

        assertNotNull(resultSetMetaData);
        assertEquals(Types.SMALLINT, resultSetMetaData.getColumnType(1));

        assertEquals(rs.getShort(2), Short.MIN_VALUE);
        assertEquals(rs.getShort(3), Short.MAX_VALUE);

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    /**
     * Test INT data type.
     */
    public void testGetObject4() throws Exception {
        int data = 1;

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #getObject4 (data INT, minval INT, maxval INT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #getObject4 (data, minval, maxval) VALUES (?, ?, ?)");

        pstmt.setInt(1, data);
        pstmt.setInt(2, Integer.MIN_VALUE);
        pstmt.setInt(3, Integer.MAX_VALUE);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data, minval, maxval FROM #getObject4");

        assertTrue(rs.next());

        assertTrue(rs.getBoolean(1));
        assertTrue(rs.getByte(1) == 1);
        assertTrue(rs.getShort(1) == 1);
        assertTrue(rs.getInt(1) == 1);
        assertTrue(rs.getLong(1) == 1);
        assertTrue(rs.getFloat(1) == 1);
        assertTrue(rs.getDouble(1) == 1);
        assertTrue(rs.getBigDecimal(1).intValue() == 1);
        assertEquals("1", rs.getString(1));

        Object tmpData = rs.getObject(1);

        assertTrue(tmpData instanceof Integer);
        assertEquals(data, ((Integer) tmpData).intValue());

        ResultSetMetaData resultSetMetaData = rs.getMetaData();

        assertNotNull(resultSetMetaData);
        assertEquals(Types.INTEGER, resultSetMetaData.getColumnType(1));

        assertEquals(rs.getInt(2), Integer.MIN_VALUE);
        assertEquals(rs.getInt(3), Integer.MAX_VALUE);

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    /**
     * Test BIGINT data type.
     */
    public void testGetObject5() throws Exception {
        long data = 1;

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #getObject5 (data DECIMAL(28, 0), minval DECIMAL(28, 0), maxval DECIMAL(28, 0))");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #getObject5 (data, minval, maxval) VALUES (?, ?, ?)");

        pstmt.setLong(1, data);
        pstmt.setLong(2, Long.MIN_VALUE);
        pstmt.setLong(3, Long.MAX_VALUE);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data, minval, maxval FROM #getObject5");

        assertTrue(rs.next());

        assertTrue(rs.getBoolean(1));
        assertTrue(rs.getByte(1) == 1);
        assertTrue(rs.getShort(1) == 1);
        assertTrue(rs.getInt(1) == 1);
        assertTrue(rs.getLong(1) == 1);
        assertTrue(rs.getFloat(1) == 1);
        assertTrue(rs.getDouble(1) == 1);
        assertTrue(rs.getBigDecimal(1).longValue() == 1);
        assertEquals("1", rs.getString(1));

        Object tmpData = rs.getObject(1);

        assertTrue(tmpData instanceof BigDecimal);
        assertEquals(data, ((BigDecimal) tmpData).longValue());

        ResultSetMetaData resultSetMetaData = rs.getMetaData();

        assertNotNull(resultSetMetaData);
        assertEquals(Types.DECIMAL, resultSetMetaData.getColumnType(1));

        assertEquals(rs.getLong(2), Long.MIN_VALUE);
        assertEquals(rs.getLong(3), Long.MAX_VALUE);

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    /**
     * Test for bug [961594] ResultSet.
     */
    public void testResultSetScroll1() throws Exception {
    	int count = 125;

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #resultSetScroll1 (data INT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #resultSetScroll1 (data) VALUES (?)");

        for (int i = 1; i <= count; i++) {
            pstmt.setInt(1, i);
            assertEquals(1, pstmt.executeUpdate());
        }

        pstmt.close();

        Statement stmt2 = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
        		ResultSet.CONCUR_READ_ONLY);
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #resultSetScroll1");

        assertTrue(rs.last());
        assertEquals(count, rs.getRow());

        stmt2.close();
        rs.close();
    }

    /**
     * Test for bug [945462] getResultSet() return null if you use scrollable/updatable.
     */
    public void testResultSetScroll2() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #resultSetScroll2 (data INT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #resultSetScroll2 (data) VALUES (?)");

        pstmt.setInt(1, 1);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                ResultSet.CONCUR_UPDATABLE);
        stmt2.executeQuery("SELECT data FROM #resultSetScroll2");

        ResultSet rs = stmt2.getResultSet();

        assertNotNull(rs);
        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));
        assertFalse(rs.next());

        stmt2.close();
        rs.close();
    }

    /**
     * Test for bug [1028881] statement.execute() causes wrong ResultSet type.
     */
    public void testResultSetScroll3() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #resultSetScroll3 (data INT)");
        stmt.execute("CREATE PROCEDURE #procResultSetScroll3 AS SELECT data FROM #resultSetScroll3");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #resultSetScroll3 (data) VALUES (?)");
        pstmt.setInt(1, 1);
        assertEquals(1, pstmt.executeUpdate());
        pstmt.close();

        // Test plain Statement
        Statement stmt2 = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                ResultSet.CONCUR_READ_ONLY);
        assertTrue("Was expecting a ResultSet", stmt2.execute("SELECT data FROM #resultSetScroll3"));

        ResultSet rs = stmt2.getResultSet();
        assertEquals("ResultSet not scrollable", ResultSet.TYPE_SCROLL_INSENSITIVE, rs.getType());

        rs.close();
        stmt2.close();

        // Test PreparedStatement
        pstmt = con.prepareStatement("SELECT data FROM #resultSetScroll3", ResultSet.TYPE_SCROLL_INSENSITIVE,
                ResultSet.CONCUR_READ_ONLY);
        assertTrue("Was expecting a ResultSet", pstmt.execute());

        rs = pstmt.getResultSet();
        assertEquals("ResultSet not scrollable", ResultSet.TYPE_SCROLL_INSENSITIVE, rs.getType());

        rs.close();
        pstmt.close();

        // Test CallableStatement
        CallableStatement cstmt = con.prepareCall("{call #procResultSetScroll3}",
                ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
        assertTrue("Was expecting a ResultSet", cstmt.execute());

        rs = cstmt.getResultSet();
        assertEquals("ResultSet not scrollable", ResultSet.TYPE_SCROLL_INSENSITIVE, rs.getType());

        rs.close();
        cstmt.close();
    }

    /**
     * Test for bug [1008208] 0.9-rc1 updateNull doesn't work.
     */
    public void testResultSetUpdate1() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #resultSetUpdate1 (id INT PRIMARY KEY, dsi SMALLINT NULL, di INT NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #resultSetUpdate1 (id, dsi, di) VALUES (?, ?, ?)");

        pstmt.setInt(1, 1);
        pstmt.setShort(2, (short) 1);
        pstmt.setInt(3, 1);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        stmt = con.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE);
        stmt.executeQuery("SELECT id, dsi, di FROM #resultSetUpdate1");

        ResultSet rs = stmt.getResultSet();

        assertNotNull(rs);
        assertTrue(rs.next());
        rs.updateNull("dsi");
        rs.updateNull("di");
        rs.updateRow();
        rs.moveToInsertRow();
        rs.updateInt(1, 2);
        rs.updateNull("dsi");
        rs.updateNull("di");
        rs.insertRow();

        stmt.close();
        rs.close();

        stmt = con.createStatement();
        stmt.executeQuery("SELECT id, dsi, di FROM #resultSetUpdate1 ORDER BY id");

        rs = stmt.getResultSet();

        assertNotNull(rs);
        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));
        rs.getShort(2);
        assertTrue(rs.wasNull());
        rs.getInt(3);
        assertTrue(rs.wasNull());
        assertTrue(rs.next());
        assertEquals(2, rs.getInt(1));
        rs.getShort(2);
        assertTrue(rs.wasNull());
        rs.getInt(3);
        assertTrue(rs.wasNull());
        assertFalse(rs.next());

        stmt.close();
        rs.close();
    }

    /**
     * Test for bug [1009233] ResultSet getColumnName, getColumnLabel return wrong values
     */
    public void testResultSetColumnName1() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #resultSetCN1 (data INT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #resultSetCN1 (data) VALUES (?)");

        pstmt.setInt(1, 1);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        stmt2.executeQuery("SELECT data as test FROM #resultSetCN1");

        ResultSet rs = stmt2.getResultSet();

        assertNotNull(rs);
        assertTrue(rs.next());
        assertEquals(1, rs.getInt("test"));
        assertFalse(rs.next());

        stmt2.close();
        rs.close();
    }

    /**
     * Test for fixed bugs in ResultSetMetaData:
     * <ol>
     * <li>isNullable() always returns columnNoNulls.
     * <li>isSigned returns true in error for TINYINT columns.
     * <li>Type names for numeric / decimal have (prec,scale) appended in error.
     * <li>Type names for auto increment columns do not have "identity" appended.
     * </ol>
     * NB: This test assumes getColumnName has been fixed to work as per the suggestion
     * in bug report [1009233].
     *
     * @throws Exception
     */
    public void testResultSetMetaData() throws Exception {
        Statement stmt = con.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE);
        stmt.execute("CREATE TABLE #TRSMD (id INT IDENTITY NOT NULL, byte TINYINT NOT NULL, num DECIMAL(28,10) NULL)");
        ResultSetMetaData rsmd = stmt.executeQuery("SELECT id as idx, byte, num FROM #TRSMD").getMetaData();
        assertNotNull(rsmd);
        // Check id
        assertEquals("idx", rsmd.getColumnName(1)); // no longer returns base name
        assertEquals("idx", rsmd.getColumnLabel(1));
        assertTrue(rsmd.isAutoIncrement(1));
        assertTrue(rsmd.isSigned(1));
        assertEquals(ResultSetMetaData.columnNoNulls, rsmd.isNullable(1));
        assertEquals("int identity", rsmd.getColumnTypeName(1));
        assertEquals(Types.INTEGER, rsmd.getColumnType(1));
        // Check byte
        assertFalse(rsmd.isAutoIncrement(2));
        assertFalse(rsmd.isSigned(2));
        assertEquals(ResultSetMetaData.columnNoNulls, rsmd.isNullable(2));
        assertEquals("tinyint", rsmd.getColumnTypeName(2));
        assertEquals(Types.TINYINT, rsmd.getColumnType(2));
        // Check num
        assertFalse(rsmd.isAutoIncrement(3));
        assertTrue(rsmd.isSigned(3));
        assertEquals(ResultSetMetaData.columnNullable, rsmd.isNullable(3));
        assertEquals("decimal", rsmd.getColumnTypeName(3));
        assertEquals(Types.DECIMAL, rsmd.getColumnType(3));
        stmt.close();
    }

    /**
     * Test for bug [1022445] Cursor downgrade warning not raised.
     */
    public void testCursorWarning() throws Exception
    {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #TESTCW (id INT PRIMARY KEY, DATA VARCHAR(255))");
        stmt.execute("CREATE PROC #SPTESTCW @P0 INT OUTPUT AS SELECT * FROM #TESTCW");
        stmt.close();
        CallableStatement cstmt = con.prepareCall("{call #SPTESTCW(?)}",
                ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
        cstmt.registerOutParameter(1, Types.INTEGER);
        ResultSet rs = cstmt.executeQuery();
        // This should generate a ResultSet type/concurrency downgraded error.
        assertNotNull(rs.getWarnings());
        cstmt.close();
    }

    /**
     * Test that the cursor fallback logic correctly discriminates between
     * "real" sql errors and cursor open failures.
     * <p/>
     * This illustrates the logic added to fix:
     * <ol>
     *   <li>[1323363] Deadlock Exception not reported (SQL Server)</li>
     *   <li>[1283472] Unable to cancel statement with cursor resultset</li>
     * </ol>
     */
    public void testCursorFallback() throws Exception {
        Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                                                ResultSet.CONCUR_READ_ONLY);
        //
        // This test should fail on the cursor open but fall back to normal
        // execution returning two result sets
        //
        stmt.execute("CREATE PROC #testcursor as SELECT 'data'  select 'data2'");
        stmt.execute("exec #testcursor");
        assertNotNull(stmt.getWarnings());
        ResultSet rs = stmt.getResultSet();
        assertNotNull(rs); // First result set OK
        assertTrue(stmt.getMoreResults());
        rs = stmt.getResultSet();
        assertNotNull(rs); // Second result set OK
        //
        // This test should fail on the cursor open (because of the for browse)
        // but fall back to normal execution returning a single result set
        //
        rs = stmt.executeQuery("SELECT description FROM master..sysmessages FOR BROWSE");
        assertNotNull(rs);
        assertNotNull(rs.getWarnings());
        rs.close();
        //
        // Enable logging to see that this test should just fail without
        // attempting to fall back on normal execution.
        //
        // DriverManager.setLogStream(System.out);
        try {
            stmt.executeQuery("select bad from syntax");
            fail("Expected SQLException");
        } catch (SQLException e) {
            assertEquals("S0002", e.getSQLState());
        }
        // DriverManager.setLogStream(null);
        stmt.close();
    }

    /**
     * Test for bug [1246270] Closing a statement after canceling it throws an
     * exception.
     */
    public void testCancelResultSet() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #TEST (id int primary key, data varchar(255))");
        for (int i = 1; i < 1000; i++) {
            stmt.executeUpdate("INSERT INTO #TEST VALUES (" + i +
                    ", 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" +
                    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')");
        }
        ResultSet rs = stmt.executeQuery("SELECT * FROM #TEST");
        assertNotNull(rs);
        assertTrue(rs.next());
        stmt.cancel();
        stmt.close();
    }

    /**
     * Test whether retrieval by name returns the first occurence (that's what
     * the spec requires).
     */
    public void testGetByName() throws Exception
    {
        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT 1 myCol, 2 myCol, 3 myCol");
        assertTrue(rs.next());
        assertEquals(1, rs.getInt("myCol"));
        assertFalse(rs.next());
        stmt.close();
    }

    /**
     * Test if COL_INFO packets are processed correctly for
     * <code>ResultSet</code>s with over 255 columns.
     */
    public void testMoreThan255Columns() throws Exception
    {
        Statement stmt = con.createStatement(ResultSet.TYPE_FORWARD_ONLY,
                ResultSet.CONCUR_UPDATABLE);

        // create the table
        int cols = 260;
        StringBuffer create = new StringBuffer("create table #manycolumns (");
        for (int i=0; i<cols; ++i) {
            create.append("col" + i + " char(10), ") ;
        }
        create.append(")");
        stmt.executeUpdate(create.toString());

        String query = "select * from #manycolumns";
        ResultSet rs = stmt.executeQuery(query);
        rs.close();
        stmt.close();
    }

    /**
     * Test that <code>insertRow()</code> works with no values set.
     */
    public void testEmptyInsertRow() throws Exception
    {
        int rows = 10;
        Statement stmt = con.createStatement(ResultSet.TYPE_FORWARD_ONLY,
                ResultSet.CONCUR_UPDATABLE);

        stmt.executeUpdate(
                "create table #emptyInsertRow (id int identity, val int default 10)");
        ResultSet rs = stmt.executeQuery("select * from #emptyInsertRow");

        for (int i=0; i<rows; i++) {
            rs.moveToInsertRow();
            rs.insertRow();
        }
        rs.close();

        rs = stmt.executeQuery("select count(*) from #emptyInsertRow");
        assertTrue(rs.next());
        assertEquals(rows, rs.getInt(1));
        rs.close();

        rs = stmt.executeQuery("select * from #emptyInsertRow order by id");
        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));
        assertEquals(10, rs.getInt(2));
        rs.close();
        stmt.close();
    }

    /**
     * Test that inserted rows are visible in a scroll sensitive
     * <code>ResultSet</code> and that they show up at the end.
     */
    public void testInsertRowVisible() throws Exception
    {
        int rows = 10;
        Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
                ResultSet.CONCUR_UPDATABLE);

        stmt.executeUpdate(
                "create table #insertRowNotVisible (val int primary key)");
        ResultSet rs = stmt.executeQuery("select * from #insertRowNotVisible");

        for (int i = 1; i <= rows; i++) {
            rs.moveToInsertRow();
            rs.updateInt(1, i);
            rs.insertRow();
            rs.moveToCurrentRow();
            rs.last();
            assertEquals(i, rs.getRow());
        }

        rs.close();
        stmt.close();
    }

    /**
     * Test that updated rows are marked as deleted and the new values inserted
     * at the end of the <code>ResultSet</code> if the primary key is updated.
     */
    public void testUpdateRowDuplicatesRow() throws Exception
    {
        Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
                ResultSet.CONCUR_UPDATABLE);

        stmt.executeUpdate(
                "create table #updateRowDuplicatesRow (val int primary key)");
        stmt.executeUpdate(
                "insert into #updateRowDuplicatesRow (val) values (1)");
        stmt.executeUpdate(
                "insert into #updateRowDuplicatesRow (val) values (2)");
        stmt.executeUpdate(
                "insert into #updateRowDuplicatesRow (val) values (3)");

        ResultSet rs = stmt.executeQuery(
                "select val from #updateRowDuplicatesRow order by val");

        for (int i = 0; i < 3; i++) {
            assertTrue(rs.next());
            assertFalse(rs.rowUpdated());
            assertFalse(rs.rowInserted());
            assertFalse(rs.rowDeleted());
            rs.updateInt(1, rs.getInt(1) + 10);
            rs.updateRow();
            assertFalse(rs.rowUpdated());
            assertFalse(rs.rowInserted());
            assertTrue(rs.rowDeleted());
        }

        for (int i = 11; i <= 13; i++) {
            assertTrue(rs.next());
            assertFalse(rs.rowUpdated());
            assertFalse(rs.rowInserted());
            assertFalse(rs.rowDeleted());
            assertEquals(i, rs.getInt(1));
        }

        rs.close();
        stmt.close();
    }

    /**
     * Test that updated rows are modified in place if the primary key is not
     * updated.
     */
    public void testUpdateRowUpdatesRow() throws Exception
    {
        Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
                ResultSet.CONCUR_UPDATABLE);

        stmt.executeUpdate(
                "create table #updateRowUpdatesRow (id int primary key, val int)");
        stmt.executeUpdate(
                "insert into #updateRowUpdatesRow (id, val) values (1, 1)");
        stmt.executeUpdate(
                "insert into #updateRowUpdatesRow (id, val) values (2, 2)");
        stmt.executeUpdate(
                "insert into #updateRowUpdatesRow (id, val) values (3, 3)");

        ResultSet rs = stmt.executeQuery(
                "select id, val from #updateRowUpdatesRow order by id");

        for (int i = 0; i < 3; i++) {
            assertTrue(rs.next());
            assertFalse(rs.rowUpdated());
            assertFalse(rs.rowInserted());
            assertFalse(rs.rowDeleted());
            rs.updateInt(2, rs.getInt(2) + 10);
            rs.updateRow();
            assertFalse(rs.rowUpdated());
            assertFalse(rs.rowInserted());
            assertFalse(rs.rowDeleted());
            assertEquals(rs.getInt(1) + 10, rs.getInt(2));
        }

        assertFalse(rs.next());

        rs.close();
        stmt.close();
    }

    /**
     * Test that deleted rows are not removed but rather marked as deleted.
     */
    public void testDeleteRowMarksDeleted() throws Exception
    {
        Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
                ResultSet.CONCUR_UPDATABLE);

        stmt.executeUpdate(
                "create table #deleteRowMarksDeleted (val int primary key)");
        stmt.executeUpdate(
                "insert into #deleteRowMarksDeleted (val) values (1)");
        stmt.executeUpdate(
                "insert into #deleteRowMarksDeleted (val) values (2)");
        stmt.executeUpdate(
                "insert into #deleteRowMarksDeleted (val) values (3)");

        ResultSet rs = stmt.executeQuery(
                "select val from #deleteRowMarksDeleted order by val");

        for (int i = 0; i < 3; i++) {
            assertTrue(rs.next());
            assertFalse(rs.rowUpdated());
            assertFalse(rs.rowInserted());
            assertFalse(rs.rowDeleted());
            rs.deleteRow();
            assertFalse(rs.rowUpdated());
            assertFalse(rs.rowInserted());
            assertTrue(rs.rowDeleted());
        }

        assertFalse(rs.next());
        rs.close();
        stmt.close();
    }

    /**
     * Test for bug [1170777] resultSet.updateRow() fails if no row has been
     * changed.
     */
    public void testUpdateRowNoChanges() throws Exception {
        Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
                ResultSet.CONCUR_UPDATABLE);

        stmt.executeUpdate(
                "create table #deleteRowMarksDeleted (val int primary key)");
        stmt.executeUpdate(
                "insert into #deleteRowMarksDeleted (val) values (1)");

        ResultSet rs = stmt.executeQuery(
                "select val from #deleteRowMarksDeleted order by val");
        assertTrue(rs.next());
        // This should not crash; it should be a no-op
        rs.updateRow();
        rs.refreshRow();
        assertEquals(1, rs.getInt(1));
        assertFalse(rs.next());

        rs.close();
        stmt.close();
    }

    /**
     * Test the behavior of <code>sp_cursorfetch</code> with fetch sizes
     * greater than 1.
     * <p>
     * <b>Assertions tested:</b>
     * <ul>
     *   <li>The <i>current row</i> is always the first row returned by the
     *     last fetch, regardless of what fetch type was used.
     *   <li>Row number parameter is ignored by fetch types other than absolute
     *     and relative.
     *   <li>Refresh fetch type simply reruns the previous request (it ignores
     *     both row number and number of rows) and will not affect the
     *     <i>current row</i>.
     *   <li>Fetch next returns the packet of rows right after the last row
     *     returned by the last fetch (regardless of what type of fetch that
     *     was).
     *   <li>Fetch previous returns the packet of rows right before the first
     *     row returned by the last fetch (regardless of what type of fetch
     *     that was).
     *   <li>If a fetch previous tries to read before the start of the
     *     <code>ResultSet</code> the requested number of rows is returned,
     *     starting with row 1 and the error code returned is non-zero (2).
     * </ul>
     */
    public void testCursorFetch() throws Exception
    {
        int rows = 10;
        Statement stmt = con.createStatement();
        stmt.executeUpdate(
                "create table #testCursorFetch (id int primary key, val int)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement(
                "insert into #testCursorFetch (id, val) values (?, ?)");
        for (int i = 1; i <= rows; i++) {
            pstmt.setInt(1, i);
            pstmt.setInt(2, i);
            pstmt.executeUpdate();
        }
        pstmt.close();

        //
        // Open cursor
        //
        CallableStatement cstmt = con.prepareCall(
                "{?=call sp_cursoropen(?, ?, ?, ?, ?)}");
        // Return value (OUT)
        cstmt.registerOutParameter(1, Types.INTEGER);
        // Cursor handle (OUT)
        cstmt.registerOutParameter(2, Types.INTEGER);
        // Statement (IN)
        cstmt.setString(3, "select * from #testCursorFetch order by id");
        // Scroll options (INOUT)
        cstmt.setInt(4, 1); // Keyset driven
        cstmt.registerOutParameter(4, Types.INTEGER);
        // Concurrency options (INOUT)
        cstmt.setInt(5, 2); // Scroll locks
        cstmt.registerOutParameter(5, Types.INTEGER);
        // Row count (OUT)
        cstmt.registerOutParameter(6, Types.INTEGER);

        ResultSet rs = cstmt.executeQuery();
        assertEquals(2, rs.getMetaData().getColumnCount());
        assertFalse(rs.next());

        assertEquals(0, cstmt.getInt(1));
        int cursor = cstmt.getInt(2);
        assertEquals(1, cstmt.getInt(4));
        assertEquals(2, cstmt.getInt(5));
        assertEquals(rows, cstmt.getInt(6));

        cstmt.close();

        //
        // Play around with fetch
        //
        cstmt = con.prepareCall("{?=call sp_cursorfetch(?, ?, ?, ?)}");
        // Return value (OUT)
        cstmt.registerOutParameter(1, Types.INTEGER);
        // Cursor handle (IN)
        cstmt.setInt(2, cursor);
        // Fetch type (IN)
        cstmt.setInt(3, 2); // Next row
        // Row number (INOUT)
        cstmt.setInt(4, 1); // Only matters for absolute and relative fetching
        // Number of rows (INOUT)
        cstmt.setInt(5, 2); // Read 2 rows

        // Fetch rows 1-2 (current row is 1)
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertTrue(rs.next());
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Fetch rows 3-4 (current row is 3)
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertTrue(rs.next());
        assertEquals(4, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Refresh rows 3-4 (current row is 3)
        cstmt.setInt(3, 0x80); // Refresh
        cstmt.setInt(4, 2);    // Try to refresh only 2nd row (will be ignored)
        cstmt.setInt(5, 1);    // Try to refresh only 1 row (will be ignored)
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertTrue(rs.next());
        assertEquals(4, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Fetch rows 5-6 (current row is 5)
        cstmt.setInt(3, 2); // Next
        cstmt.setInt(4, 1); // Row number 1
        cstmt.setInt(5, 2); // Get 2 rows
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertTrue(rs.next());
        assertEquals(6, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Fetch previous rows (3-4) (current row is 3)
        cstmt.setInt(3, 4); // Previous
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertEquals(3, rs.getInt(1));
        assertTrue(rs.next());
        assertEquals(4, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Refresh rows 3-4 (current row is 3)
        cstmt.setInt(3, 0x80); // Refresh
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertEquals(3, rs.getInt(1));
        assertTrue(rs.next());
        assertEquals(4, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Fetch previous rows (1-2) (current row is 1)
        cstmt.setInt(3, 4); // Previous
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));
        assertTrue(rs.next());
        assertEquals(2, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Fetch next rows (3-4) (current row is 3)
        cstmt.setInt(3, 2); // Next
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertEquals(3, rs.getInt(1));
        assertTrue(rs.next());
        assertEquals(4, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Fetch first rows (1-2) (current row is 1)
        cstmt.setInt(3, 1); // First
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));
        assertTrue(rs.next());
        assertEquals(2, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Fetch last rows (9-10) (current row is 9)
        cstmt.setInt(3, 8); // Last
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertEquals(9, rs.getInt(1));
        assertTrue(rs.next());
        assertEquals(10, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Fetch next rows; should not fail (current position is after last)
        cstmt.setInt(3, 2); // Next
        rs = cstmt.executeQuery();
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Fetch absolute starting with 6 (6-7) (current row is 6)
        cstmt.setInt(3, 0x10); // Absolute
        cstmt.setInt(4, 6);
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertEquals(6, rs.getInt(1));
        assertTrue(rs.next());
        assertEquals(7, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Fetch relative -4 (2-3) (current row is 2)
        cstmt.setInt(3, 0x20); // Relative
        cstmt.setInt(4, -4);
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertEquals(2, rs.getInt(1));
        assertTrue(rs.next());
        assertEquals(3, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        // Fetch previous 2 rows; should fail (current row is 1)
        cstmt.setInt(3, 4); // Previous
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));
        assertTrue(rs.next());
        assertEquals(2, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        // Returns 2 on error
        assertEquals(2, cstmt.getInt(1));

        // Fetch next rows (3-4) (current row is 3)
        cstmt.setInt(3, 2); // Next
        rs = cstmt.executeQuery();
        assertTrue(rs.next());
        assertEquals(3, rs.getInt(1));
        assertTrue(rs.next());
        assertEquals(4, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(0, cstmt.getInt(1));

        cstmt.close();

        //
        // Close cursor
        //
        cstmt = con.prepareCall("{?=call sp_cursorclose(?)}");
        // Return value (OUT)
        cstmt.registerOutParameter(1, Types.INTEGER);
        // Cursor handle (IN)
        cstmt.setInt(2, cursor);
        assertFalse(cstmt.execute());
        assertEquals(0, cstmt.getInt(1));
        cstmt.close();
    }

    /**
     * Test that <code>absolute(-1)</code> works the same as <code>last()</code>.
     */
    public void testAbsoluteMinusOne() throws Exception {
        Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                ResultSet.CONCUR_READ_ONLY);

        stmt.executeUpdate(
                "create table #absoluteMinusOne (val int primary key)");
        stmt.executeUpdate(
                "insert into #absoluteMinusOne (val) values (1)");
        stmt.executeUpdate(
                "insert into #absoluteMinusOne (val) values (2)");
        stmt.executeUpdate(
                "insert into #absoluteMinusOne (val) values (3)");

        ResultSet rs = stmt.executeQuery(
                "select val from #absoluteMinusOne order by val");

        rs.absolute(-1);
        assertTrue(rs.isLast());
        assertEquals(3, rs.getInt(1));
        assertFalse(rs.next());

        rs.last();
        assertTrue(rs.isLast());
        assertEquals(3, rs.getInt(1));
        assertFalse(rs.next());

        rs.close();
        stmt.close();
    }

    /**
     * Test that calling <code>absolute()</code> with very large positive
     * values positions the cursor after the last row and with very large
     * negative values positions the cursor before the first row.
     */
    public void testAbsoluteLargeValue() throws SQLException {
        Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                ResultSet.CONCUR_READ_ONLY);

        stmt.executeUpdate(
                "create table #absoluteLargeValue (val int primary key)");
        stmt.executeUpdate(
                "insert into #absoluteLargeValue (val) values (1)");
        stmt.executeUpdate(
                "insert into #absoluteLargeValue (val) values (2)");
        stmt.executeUpdate(
                "insert into #absoluteLargeValue (val) values (3)");

        ResultSet rs = stmt.executeQuery(
                "select val from #absoluteLargeValue order by val");

        assertFalse(rs.absolute(10));
        assertEquals(0, rs.getRow());
        assertTrue(rs.isAfterLast());
        assertFalse(rs.next());
        assertEquals(0, rs.getRow());
        assertTrue(rs.isAfterLast());

        assertFalse(rs.absolute(-10));
        assertEquals(0, rs.getRow());
        assertTrue(rs.isBeforeFirst());
        assertFalse(rs.previous());
        assertEquals(0, rs.getRow());
        assertTrue(rs.isBeforeFirst());

        rs.close();
        stmt.close();
    }

    /**
     * Test that calling <code>absolute()</code> with very large positive
     * values positions the cursor after the last row and with very large
     * negative values positions the cursor before the first row.
     */
    public void testRelativeLargeValue() throws SQLException {
        Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                ResultSet.CONCUR_READ_ONLY);

        stmt.executeUpdate(
                "create table #relativeLargeValue (val int primary key)");
        stmt.executeUpdate(
                "insert into #relativeLargeValue (val) values (1)");
        stmt.executeUpdate(
                "insert into #relativeLargeValue (val) values (2)");
        stmt.executeUpdate(
                "insert into #relativeLargeValue (val) values (3)");

        ResultSet rs = stmt.executeQuery(
                "select val from #relativeLargeValue order by val");

        assertFalse(rs.relative(10));
        assertEquals(0, rs.getRow());
        assertTrue(rs.isAfterLast());
        assertFalse(rs.next());
        assertEquals(0, rs.getRow());
        assertTrue(rs.isAfterLast());

        assertFalse(rs.relative(-10));
        assertEquals(0, rs.getRow());
        assertTrue(rs.isBeforeFirst());
        assertFalse(rs.previous());
        assertEquals(0, rs.getRow());
        assertTrue(rs.isBeforeFirst());

        rs.close();
        stmt.close();
    }

    /**
     * Test that <code>read()</code> works ok on the stream returned by
     * <code>ResultSet.getUnicodeStream()</code> (i.e. it doesn't always fill
     * the buffer, regardless of whether there's available data or not).
     */
    public void testUnicodeStream() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #unicodeStream (val varchar(255))");
        stmt.executeUpdate("insert into #unicodeStream (val) values ('test')");
        ResultSet rs = stmt.executeQuery("select val from #unicodeStream");

        if (rs.next()) {
            byte[] buf = new byte[8000];
            InputStream is = rs.getUnicodeStream(1);
            int length = is.read(buf);
            assertEquals(4 * 2, length);
        }

        rs.close();
        stmt.close();
    }

    /**
     * Check whether <code>Statement.setMaxRows()</code> works okay, bug
     * [1812686].
     */
    public void testMaxRows() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #statementMaxRows (val int)");
        stmt.close();

        // insert 1000 rows
        PreparedStatement pstmt = con.prepareStatement("insert into #statementMaxRows values (?)");
        for (int i = 0; i < 1000; i++) {
            pstmt.setInt(1, i);
            assertEquals(1, pstmt.executeUpdate());
        }
        pstmt.close();

        stmt = con.createStatement();

        // set maxRows to 100
        stmt.setMaxRows(100);

        // select all rows (should only return 100 rows)
        ResultSet rs = stmt.executeQuery("select * from #statementMaxRows");
        int rows = 0;
        while (rs.next()) {
           rows++;
        }

        assertEquals(100, rows);

        rs.close();
        stmt.close();
    }

    /**
     * Test that <code>Statement.setMaxRows()</code> works on cursor
     * <code>ResultSet</code>s.
     */
    public void testCursorMaxRows() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #cursorMaxRows (val int)");
        stmt.close();

        // Insert 10 rows
        PreparedStatement pstmt = con.prepareStatement(
                "insert into #cursorMaxRows (val) values (?)");
        for (int i = 0; i < 10; i++) {
            pstmt.setInt(1, i);
            assertEquals(1, pstmt.executeUpdate());
        }
        pstmt.close();

        // Create a cursor ResultSet
        stmt = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
        // Set maxRows to 5
        stmt.setMaxRows(5);

        // Select all (should only return 5 rows)
        ResultSet rs = stmt.executeQuery("select * from #cursorMaxRows");
        rs.last();
        assertEquals(5, rs.getRow());
        rs.beforeFirst();

        int cnt = 0;
        while (rs.next()) {
            cnt++;
        }
        assertEquals(5, cnt);

        rs.close();
        stmt.close();
    }

    /**
     * Test for bug [1075977] <code>setObject()</code> causes SQLException.
     * <p>
     * Conversion of <code>float</code> values to <code>String</code> adds
     * grouping to the value, which cannot then be parsed.
     */
    public void testSetObjectScale() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create table #testsetobj (i int)");
        PreparedStatement pstmt =
                con.prepareStatement("insert into #testsetobj values(?)");
        // next line causes sqlexception
        pstmt.setObject(1, new Float(1234.5667), Types.INTEGER, 0);
        assertEquals(1, pstmt.executeUpdate());
        ResultSet rs = stmt.executeQuery("select * from #testsetobj");
        assertTrue(rs.next());
        assertEquals("1234", rs.getString(1));
    }

    /**
     * Test that <code>ResultSet.previous()</code> works correctly on cursor
     * <code>ResultSet</code>s.
     */
    public void testCursorPrevious() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #cursorPrevious (val int)");
        stmt.close();

        // Insert 10 rows
        PreparedStatement pstmt = con.prepareStatement(
                "insert into #cursorPrevious (val) values (?)");
        for (int i = 0; i < 10; i++) {
            pstmt.setInt(1, i);
            assertEquals(1, pstmt.executeUpdate());
        }
        pstmt.close();

        // Create a cursor ResultSet
        stmt = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
        // Set fetch size to 2
        stmt.setFetchSize(2);

        // Select all
        ResultSet rs = stmt.executeQuery("select * from #cursorPrevious");
        rs.last();
        int i = 10;
        do {
            assertEquals(i, rs.getRow());
            assertEquals(--i, rs.getInt(1));
        } while (rs.previous());
        assertTrue(rs.isBeforeFirst());
        assertEquals(0, i);

        rs.close();
        stmt.close();
    }

    /**
     * Test the behavior of the ResultSet/Statement/Connection when the JVM
     * runs out of memory (hopefully) in the middle of a packet.
     * <p/>
     * Previously jTDS was not able to close a ResultSet/Statement/Connection
     * after an OutOfMemoryError because the input stream pointer usually
     * remained inside a packet and further attempts to dump the rest of the
     * response failed because of "protocol confusions".
     */
    public void testOutOfMemory() throws SQLException {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #testOutOfMemory (val binary(8000))");

        // Insert a 8KB value
        byte[] val = new byte[8000];
        PreparedStatement pstmt = con.prepareStatement(
                "insert into #testOutOfMemory (val) values (?)");
        pstmt.setBytes(1, val);
        assertEquals(1, pstmt.executeUpdate());
        pstmt.close();

        // Create a list and keep adding rows to it until we run out of memory
        // Most probably this will happen in the middle of a row packet, when
        // jTDS tries to allocate the array, after reading the data length
        ArrayList results = new ArrayList();
        ResultSet rs = null;
        try {
            while (true) {
                rs = stmt.executeQuery("select val from #testOutOfMemory");
                assertTrue(rs.next());
                results.add(rs.getBytes(1));
                assertFalse(rs.next());
                rs.close();
                rs = null;
            }
        } catch (OutOfMemoryError err) {
            // Do not remove this. Although not really used, it will free
            // memory, avoiding another OutOfMemoryError
            results = null;
            if (rs != null) {
                // This used to fail, because the parser got confused
                rs.close();
            }
        }

        // Make sure the Statement still works
        rs = stmt.executeQuery("select 1");
        assertTrue(rs.next());
        assertFalse(rs.next());
        rs.close();
        stmt.close();
    }

    /**
     * Test for bug [1182066] regression bug resultset: relative() not working
     * as expected.
     */
    public void testRelative() throws Exception {
        final int ROW_COUNT = 99;

        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #test2 (i int primary key, v varchar(100))");
        for (int i = 1; i <= ROW_COUNT; i++) {
            stmt.executeUpdate("insert into #test2 (i, v) values (" + i + ", 'This is a test')");
        }
        stmt.close();

        String sql = "select * from #test2";

        PreparedStatement pstmt = con.prepareStatement(sql,
                ResultSet.TYPE_SCROLL_INSENSITIVE,
                ResultSet.CONCUR_READ_ONLY);
        pstmt.setFetchSize(10);

        ResultSet rs = pstmt.executeQuery();

        int resCnt = 0;

        if (rs.next()) {
            do {
                assertEquals(++resCnt, rs.getInt(1));
            } while (rs.relative(1));
        }
        assertEquals(ROW_COUNT, resCnt);

        if (rs.previous()) {
            do {
                assertEquals(resCnt--, rs.getInt(1));
            } while (rs.relative(-1));
        }

        pstmt.close();
        assertEquals(0, resCnt);
    }

    /**
     * Test that after updateRow() the cursor is positioned correctly.
     */
    public void testUpdateRowPosition() throws Exception {
        final int ROW_COUNT = 99;
        final int TEST_ROW = 33;

        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #testPos (i int primary key, v varchar(100))");
        for (int i = 1; i <= ROW_COUNT; i++) {
            stmt.executeUpdate("insert into #testPos (i, v) values (" + i + ", 'This is a test')");
        }
        stmt.close();

        String sql = "select * from #testPos order by i";

        PreparedStatement pstmt = con.prepareStatement(sql,
                ResultSet.TYPE_SCROLL_SENSITIVE,
                ResultSet.CONCUR_UPDATABLE);
        pstmt.setFetchSize(10);

        ResultSet rs = pstmt.executeQuery();

        for (int i = 1; i <= TEST_ROW; i++) {
            assertTrue(rs.next());
            assertEquals(i, rs.getInt(1));
        }

        // We're on TEST_ROW now
        assertEquals(TEST_ROW, rs.getRow());
        rs.updateString(2, "This is another test");
        rs.updateRow();
        assertEquals(TEST_ROW, rs.getRow());
        assertEquals(TEST_ROW, rs.getInt(1));
        rs.refreshRow();
        assertEquals(TEST_ROW, rs.getRow());
        assertEquals(TEST_ROW, rs.getInt(1));

        for (int i = TEST_ROW + 1; i <= ROW_COUNT; i++) {
            assertTrue(rs.next());
            assertEquals(i, rs.getInt(1));
        }

        pstmt.close();
    }

    /**
     * Test for bug [1197603] Cursor downgrade error in CachedResultSet --
     * updateable result sets were incorrectly downgraded to read only forward
     * only ones when client side cursors were used.
     */
    public void testUpdateableClientCursor() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #testUpdateableClientCursor "
                + "(i int primary key, v varchar(100))");
        stmt.executeUpdate("insert into #testUpdateableClientCursor "
                + "(i, v) values (1, 'This is a test')");
        stmt.close();

        // Use a statement that the server won't be able to create a cursor on
        String sql = "select * from #testUpdateableClientCursor where i = ?";

        PreparedStatement pstmt = con.prepareStatement(sql,
                ResultSet.TYPE_SCROLL_SENSITIVE,
                ResultSet.CONCUR_UPDATABLE);
        pstmt.setInt(1, 1);
        ResultSet rs = pstmt.executeQuery();
        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));

        assertNull(pstmt.getWarnings());
        rs.updateString(2, "This is another test");
        rs.updateRow();
        rs.close();
        pstmt.close();

        stmt = con.createStatement();
        rs = stmt.executeQuery(
                "select * from #testUpdateableClientCursor");
        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));
        assertEquals("This is another test", rs.getString(2));
        assertFalse(rs.next());
        rs.close();
        stmt.close();
    }

    /**
     * Test bug with Sybase where readonly scrollable result set based on a
     * SELECT DISTINCT returns duplicate rows.
     */
    public void testDistinctBug() throws Exception {
        Statement stmt = con.createStatement(
                ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
        stmt.execute( "CREATE TABLE #testdistinct (id int primary key, c varchar(255))");
        stmt.addBatch("INSERT INTO #testdistinct VALUES(1, 'AAAA')");
        stmt.addBatch("INSERT INTO #testdistinct VALUES(2, 'AAAA')");
        stmt.addBatch("INSERT INTO #testdistinct VALUES(3, 'BBBB')");
        stmt.addBatch("INSERT INTO #testdistinct VALUES(4, 'BBBB')");
        stmt.addBatch("INSERT INTO #testdistinct VALUES(5, 'CCCC')");
        int counts[] = stmt.executeBatch();
        assertEquals(5, counts.length);

        ResultSet rs = stmt.executeQuery(
                "SELECT DISTINCT c FROM #testdistinct");
        assertNotNull(rs);
        int rowCount = 0;
        while (rs.next()) {
            rowCount++;
        }
        assertEquals(3, rowCount);
        stmt.close();
    }

    /**
     * Test pessimistic concurrency for SQL Server (for Sybase optimistic
     * concurrency will always be used).
     */
    public void testPessimisticConcurrency() throws Exception {
        dropTable("pessimisticConcurrency");
        Connection con2 = getConnection();
        Statement stmt = null;
        ResultSet rs = null;
        try {
            // Create statement using pessimistic locking.
            stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE + 1);
            stmt.execute("CREATE TABLE pessimisticConcurrency (id int primary key, data varchar(255))");
            for (int i = 0; i < 4; i++) {
                stmt.executeUpdate("INSERT INTO pessimisticConcurrency VALUES("+i+", 'Table A line "+i+"')");
            }

            // Fetch one row at a time, making sure we know exactly which row is locked
            stmt.setFetchSize(1);
            // Open cursor
            rs = stmt.executeQuery("SELECT id, data FROM pessimisticConcurrency ORDER BY id");
            assertNull(rs.getWarnings());
            assertEquals(ResultSet.TYPE_SCROLL_SENSITIVE, rs.getType());
            assertEquals(ResultSet.CONCUR_UPDATABLE + 1, rs.getConcurrency());
            // If not a MSCursorResultSet, give up as no locking will happen
            if (rs.getClass().getName().indexOf("MSCursorResultSet") == -1) {
                rs.close();
                stmt.close();
                return;
            }
            // Scroll to and lock row 3
            for (int i = 0; i < 3; ++i) {
                rs.next();
            }

            // Create a second statement
            final Statement stmt2 = con2.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
                                                         ResultSet.CONCUR_UPDATABLE + 1);

            // No better idea to store exceptions
            final ArrayList container = new ArrayList();
            // Launch a thread that will cancel the second statement if it hangs.
            new Thread() {
                public void run() {
                    try {
                        sleep(1000);
                        stmt2.cancel();
                    } catch (Exception ex) {
                        container.add(ex);
                    }
                }
            }.start();

            // Open second cursor
            ResultSet rs2 = stmt2.executeQuery("SELECT id, data FROM pessimisticConcurrency WHERE id = 2");
            assertNull(rs2.getWarnings());
            assertEquals(ResultSet.TYPE_SCROLL_SENSITIVE, rs2.getType());
            assertEquals(ResultSet.CONCUR_UPDATABLE + 1, rs2.getConcurrency());
            try {
                System.out.println(rs2.next());
            } catch (SQLException ex) {
                ex.printStackTrace();
                System.out.println(ex.getNextException());
                if ("HY010".equals(ex.getSQLState())) {
                    stmt2.getMoreResults();
                }
                if (!"HY008".equals(ex.getSQLState()) && !"HY010".equals(ex.getSQLState())) {
                    fail("Expecting cancel exception.");
                }
            }
            rs.close();
            stmt.close();
            rs2.close();
            stmt2.close();

            // Check for exceptions thrown in the cancel thread
            if (container.size() != 0) {
                throw (SQLException) container.get(0);
            }
        } finally {
            dropTable("pessimisticConcurrency");
            if (con2 != null) {
                con2.close();
            }
        }
    }

    /**
     * Test if dynamic cursors (<code>ResultSet.TYPE_SCROLL_SENSITIVE+1</code>)
     * see others' updates. SQL Server only.
     */
    public void testDynamicCursors() throws Exception {
        final int ROWS = 4;
        dropTable("dynamicCursors");
        Connection con2 = getConnection();
        try {
            Statement stmt = con.createStatement(
                    ResultSet.TYPE_SCROLL_SENSITIVE + 1,
                    ResultSet.CONCUR_READ_ONLY);
            stmt.execute("CREATE TABLE dynamicCursors (id int primary key, data varchar(255))");
            for (int i = 0; i < ROWS; i++) {
                stmt.executeUpdate("INSERT INTO dynamicCursors VALUES(" + i + ", 'Table A line " + i + "')");
            }

            // Open cursor
            ResultSet rs = stmt.executeQuery("SELECT id, data FROM dynamicCursors");
            // If not a MSCursorResultSet, give up as it will not see inserts
            if (rs.getClass().getName().indexOf("MSCursorResultSet") == -1) {
                rs.close();
                stmt.close();
                return;
            }

            // Insert new row from other connection
            Statement stmt2 = con2.createStatement();
            assertEquals(1, stmt2.executeUpdate(
                    "INSERT INTO dynamicCursors VALUES(" + ROWS + ", 'Table A line " + ROWS + "')"));
            stmt2.close();

            // Count rows and make sure the newly inserted row is visible
            int cnt;
            for (cnt = 0; rs.next(); cnt++);
            assertEquals(ROWS + 1, cnt);

            rs.close();
            stmt.close();
        } finally {
            dropTable("dynamicCursors");
            if (con2 != null) {
                con2.close();
            }
        }
    }

    /**
     * Test for bug [1232733] setFetchSize(0) causes exception.
     */
    public void testZeroFetchSize() throws Exception {
        Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                ResultSet.CONCUR_READ_ONLY);
        stmt.setFetchSize(0);

        ResultSet rs = stmt.executeQuery("SELECT 1 UNION SELECT 2");
        assertTrue(rs.next());

        rs.setFetchSize(0);
        assertTrue(rs.next());
        assertFalse(rs.next());

        rs.close();
        stmt.close();
    }

    /**
     * Test for bug [1329765] Pseudo column ROWSTAT is back with SQL 2005
     * (September CTP).
     */
    public void testRowstat() throws Exception {
        PreparedStatement stmt = con.prepareStatement("SELECT 'STRING' str",
                ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
        ResultSet rs = stmt.executeQuery();

        assertEquals(1, rs.getMetaData().getColumnCount());
        assertTrue(rs.next());
        assertFalse(rs.next());

        rs.close();
        stmt.close();
    }

    /**
     * Test for bug [2051585], TDS Protocol error when 2 ResultSets on the
     * same connection are being iterated at the same time.
     */
    public void testConcurrentResultSets() throws Exception {
        con.setAutoCommit(false);

        final int rows    = 100;
        final int threads = 100;

        // prepare test data
        Statement stmt = con.createStatement();
        stmt.execute("create table #conrs (id int,data varchar(20))");
        for (int r=0; r < rows; r++) {
            assertEquals(1, stmt.executeUpdate("insert into #conrs values(" + r + ",'test" + r + "')"));
        }
        stmt.close();

        final Thread[] workers = new Thread[threads];
        final List     errors  = new ArrayList();

        for (int i=0; i < threads; i++) {
            workers[i] = new Thread("thread " + i) {
                public void run() {
                    int i=0;
                    try {
                        Statement st = con.createStatement();
                        ResultSet rs = st.executeQuery("select * from #conrs order by id asc");

                        for ( ; i < rows; i++) {
                            assertTrue("premature end of result, only " + i + "of " + rows + " rows present", rs.next());
                            assertEquals("resultset contains wrong row:", i, rs.getInt(1));
                            assertEquals("resultset contains wrong column value:", "test" + i, rs.getString(2));

                            // random delays should ensure that threads are not executed one after another
                            if (Math.random() < 0.01) {
                               Thread.sleep(1);
                            }
                        }

                        rs.close();
                        st.close();
                    }
                    catch (Throwable t) {
                        synchronized (errors) {
                            errors.add(new Exception(this.getName() + " at row " + i + ": " + t.getMessage()));
                        }
                    }
                }
            };
        }

        // start all threads
        for (int i=0; i < threads; i++) {
            workers[i].start();
        }

        // wait for the threads to finish
        for (int i=0; i < threads; i++) {
            workers[i].join();
        }

        assertEquals("[]", array2String(errors.toArray()));

        con.setAutoCommit(true);
    }

    private static String array2String(Object[] a) {
        if (a == null)
            return "null";
        int iMax = a.length - 1;
        if (iMax == -1)
            return "[]";

        StringBuffer b = new StringBuffer();
        b.append('[');
        for (int i = 0; ; i++) {
            b.append(String.valueOf(a[i]));
            if (i == iMax)
                return b.append(']').toString();
            b.append(", ");
        }
    }

    /**
     * Test for bug [1855125], numeric overflow not reported by jTDS.
     */
    public void testNumericOverflow() throws SQLException {
        Statement st = con.createStatement();
        st.execute("create table #test(data numeric(30,10))");
        assertEquals(1, st.executeUpdate("insert into #test values (10000000000000000000.0000)"));

        ResultSet rs = st.executeQuery("select * from #test");
        
        assertTrue(rs.next());

        try {
            byte b = rs.getByte(1);
            assertTrue("expected numeric overflow error, got " + b, false);
        } catch (SQLException e) {
            assertEquals(e.getSQLState(), "22003");
        }

        try {
            short s = rs.getShort(1);
            assertTrue("expected numeric overflow error, got " + s, false);
        } catch (SQLException e) {
            assertEquals(e.getSQLState(), "22003");
        }

        try {
            int i = rs.getInt(1);
            assertTrue("expected numeric overflow error, got " + i, false);
        } catch (SQLException e) {
            assertEquals(e.getSQLState(), "22003");
        }

        try {
            long l = rs.getLong(1);
            assertTrue("expected numeric overflow error, got " + l, false);
        } catch (SQLException e) {
            assertEquals(e.getSQLState(), "22003");
        }
        
        rs.close();
        st.close();
    }

    /**
     * Test for bug [2860742], getByte() causes overflow error for negative
     * values.
     */
    public void testNegativeOverflow() throws SQLException
    {
        Statement st = con.createStatement();
        st.execute("create table #testNegativeOverflow(data int)");

        int    [] values   = new int    [] {   -1,  -128, -129,   127,  128};
        boolean[] overflow = new boolean[] {false, false, true, false, true};

        for (int i = 0; i < values.length; i++) {
            assertEquals(1, st.executeUpdate("insert into #testNegativeOverflow values (" + values[i] + ")"));
        }

        ResultSet rs = st.executeQuery("select * from #testNegativeOverflow");

        for (int i = 0; i < values.length; i++) {
            assertTrue(rs.next());
            try {
                byte b = rs.getByte(1);
                assertFalse("expected numeric overflow error for value " + values[i] + ", got " + b, overflow[i]);
            } catch (SQLException e) {
                assertTrue("unexpected numeric overflow for value " + values[i], overflow[i]);
            }
        }

        rs.close();
        st.close();
    }

    /**
     * Test for bug [1840116], Select statement very slow with date parameter.
     */
    public void testDatePerformance() throws SQLException {
        Statement st = con.createStatement();
        st.execute("create table #test(data datetime)");
        st.close();

        PreparedStatement ps = con.prepareStatement("insert into #test values(?)");

        final int iterations = 10000;
        final String dateString = "2009-09-03";

        // test date value
        Date date = Date.valueOf(dateString);

        System.gc();
        long start = System.currentTimeMillis();

        // insert test data using prepared statement
        for (int i = 0; i < iterations; i ++) {
            ps.setDate(1, date);
            ps.executeUpdate();
        }

        long prep = System.currentTimeMillis() - start; 
        System.out.println("prepared: " + prep + " ms");
        ps.close();

        // delete test data
        st = con.createStatement();
        assertEquals(iterations, st.executeUpdate("delete from #test"));
        st.close();

        st = con.createStatement();
        System.gc();
        start = System.currentTimeMillis();

        // insert test data using prepared statement
        for (int i = 0; i < iterations; i ++) {
            st.executeUpdate("insert into #test values(" + dateString + ")");
        }

        long unprep = System.currentTimeMillis() - start; 
        System.out.println("inlined : " + unprep + " ms");
        st.close();

        // prepared statement should be faster
        assertTrue(prep < unprep);
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(ResultSetTest.class);
    }

}