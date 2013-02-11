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
import java.util.*;

import net.sourceforge.jtds.jdbc.*;

/**
 * Simple test suite to exercise batch execution.
 *
 * @version $Id: BatchTest.java,v 1.11.2.6 2009-12-30 13:33:24 ickzon Exp $
 */
public class BatchTest extends DatabaseTestCase {
    // Constants to use instead of the JDBC 3.0-only Statement constants
    private static int SUCCESS_NO_INFO = -2;
    private static int EXECUTE_FAILED  = -3;

    public BatchTest(String name) {
        super(name);
    }

    /**
     * This test should generate an error as the second statement in the batch
     * returns a result set.
     */
    public void testResultSetError() throws Exception {
        Statement stmt = con.createStatement();
        stmt.addBatch("create table #testbatch (id int, data varchar(255))");
        stmt.addBatch("insert into #testbatch VALUES(1, 'Test line')");
        stmt.addBatch("SELECT 'This is an error'");
        int x[];
        try {
            x = stmt.executeBatch();
            fail("Expecting BatchUpdateException");
        } catch (BatchUpdateException e) {
            x = e.getUpdateCounts();
        }
        assertEquals(3, x.length);
        assertEquals(SUCCESS_NO_INFO, x[0]);
        assertEquals(1, x[1]);
        assertEquals(EXECUTE_FAILED, x[2]);
    }

    /**
     * The first statement in this batch does not return an update count.
     * SUCCESS_NO_INFO is expected instead.
     */
    public void testNoCount() throws Exception {
        Statement stmt = con.createStatement();
        stmt.addBatch("create table #testbatch (id int, data varchar(255))");
        stmt.addBatch("insert into #testbatch VALUES(1, 'Test line')");
        int x[] = stmt.executeBatch();
        assertEquals(2, x.length);
        assertEquals(SUCCESS_NO_INFO, x[0]);
        assertEquals(1, x[1]);
    }

    /**
     * Test batched statements.
     */
    public void testBatch() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create table #testbatch (id int, data varchar(255))");
        for (int i = 0; i < 5; i++) {
            if (i == 2) {
                // This statement will generate an error
                stmt.addBatch("INSERT INTO #testbatch VALUES ('xx', 'This is line " + i + "')");
            } else {
                stmt.addBatch("INSERT INTO #testbatch VALUES (" + i + ", 'This is line " + i + "')");
            }
        }
        int x[];
        try {
            x = stmt.executeBatch();
        } catch (BatchUpdateException e) {
            x = e.getUpdateCounts();
        }
        if (con.getMetaData().getDatabaseProductName().toLowerCase().startsWith("microsoft")
            && ((JtdsDatabaseMetaData) con.getMetaData()).getDatabaseMajorVersion() > 6 ) {
            assertEquals(5, x.length);
            assertEquals(1, x[0]);
            assertEquals(1, x[1]);
            assertEquals(EXECUTE_FAILED, x[2]);
            assertEquals(EXECUTE_FAILED, x[3]);
            assertEquals(EXECUTE_FAILED, x[4]);
        } else {
            // Sybase or SQL Server 6.5 - Entire batch fails due to data conversion error 
            // detected in statement 3
            assertEquals(5, x.length);
            assertEquals(EXECUTE_FAILED, x[0]);
            assertEquals(EXECUTE_FAILED, x[1]);
            assertEquals(EXECUTE_FAILED, x[2]);
            assertEquals(EXECUTE_FAILED, x[3]);
            assertEquals(EXECUTE_FAILED, x[4]);
        }
        // Now without errors
        stmt.execute("TRUNCATE TABLE #testbatch");
        for (int i = 0; i < 5; i++) {
            stmt.addBatch("INSERT INTO #testbatch VALUES (" + i + ", 'This is line " + i + "')");
        }
        x = stmt.executeBatch();
        assertEquals(5, x.length);
        assertEquals(1, x[0]);
        assertEquals(1, x[1]);
        assertEquals(1, x[2]);
        assertEquals(1, x[3]);
        assertEquals(1, x[4]);
    }

    /**
     * Test batched prepared statements.
     */
    public void testPrepStmtBatch() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create table #testbatch (id int, data varchar(255))");
        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #testbatch VALUES (?, ?)");
        for (int i = 0; i < 5; i++) {
            if (i == 2) {
                pstmt.setString(1, "xxx");
            } else {
                pstmt.setInt(1, i);
            }
            pstmt.setString(2, "This is line " + i);
            pstmt.addBatch();
        }
        int x[];
        try {
            x = pstmt.executeBatch();
        } catch (BatchUpdateException e) {
            x = e.getUpdateCounts();
        }
        if (con.getMetaData().getDatabaseProductName().toLowerCase().startsWith("microsoft")) {
            assertEquals(5, x.length);
            assertEquals(1, x[0]);
            assertEquals(1, x[1]);
            assertEquals(EXECUTE_FAILED, x[2]);
            assertEquals(EXECUTE_FAILED, x[3]);
            assertEquals(EXECUTE_FAILED, x[4]);
        } else {
            // Sybase - Entire batch fails due to data conversion error 
            // detected in statement 3
            assertEquals(5, x.length);
            assertEquals(EXECUTE_FAILED, x[0]);
            assertEquals(EXECUTE_FAILED, x[1]);
            assertEquals(EXECUTE_FAILED, x[2]);
            assertEquals(EXECUTE_FAILED, x[3]);
            assertEquals(EXECUTE_FAILED, x[4]);
        }
        // Now without errors
        stmt.execute("TRUNCATE TABLE #testbatch");
        for (int i = 0; i < 5; i++) {
            pstmt.setInt(1, i);
            pstmt.setString(2, "This is line " + i);
            pstmt.addBatch();
        }
        x = pstmt.executeBatch();
        assertEquals(5, x.length);
        assertEquals(1, x[0]);
        assertEquals(1, x[1]);
        assertEquals(1, x[2]);
        assertEquals(1, x[3]);
        assertEquals(1, x[4]);
    }

    /**
     * Test batched callable statements.
     */
    public void testCallStmtBatch() throws Exception {
        dropProcedure("jTDS_PROC");
        try {
            Statement stmt = con.createStatement();
            stmt.execute("create table #testbatch (id int, data varchar(255))");
            stmt.execute("create proc jTDS_PROC @p1 varchar(10), @p2 varchar(255) as " +
                    "INSERT INTO #testbatch VALUES (convert(int, @p1), @p2)");
            CallableStatement cstmt = con.prepareCall("{call jTDS_PROC (?, ?)}");
            for (int i = 0; i < 5; i++) {
                cstmt.setString(1, Integer.toString(i));
                cstmt.setString(2, "This is line " + i);
                cstmt.addBatch();
            }
            int x[];
            try {
                x = cstmt.executeBatch();
            } catch (BatchUpdateException e) {
                x = e.getUpdateCounts();
            }
            assertEquals(5, x.length);
            assertEquals(1, x[0]);
            assertEquals(1, x[1]);
            assertEquals(1, x[2]);
            assertEquals(1, x[3]);
            assertEquals(1, x[4]);
            // Now with errors
            stmt.execute("TRUNCATE TABLE #testbatch");
            for (int i = 0; i < 5; i++) {
                if (i == 2) {
                    cstmt.setString(1, "XXX");
                } else {
                    cstmt.setString(1, Integer.toString(i));
                }
                cstmt.setString(2, "This is line " + i);
                cstmt.addBatch();
            }
            try {
                x = cstmt.executeBatch();
            } catch (BatchUpdateException e) {
                x = e.getUpdateCounts();
            }
            if (con.getMetaData().getDatabaseProductName().toLowerCase().startsWith("microsoft")) {
                assertEquals(5, x.length);
                assertEquals(1, x[0]);
                assertEquals(1, x[1]);
                assertEquals(EXECUTE_FAILED, x[2]);
                assertEquals(EXECUTE_FAILED, x[3]);
                assertEquals(EXECUTE_FAILED, x[4]);
            } else {
                assertEquals(5, x.length);
                assertEquals(1, x[0]);
                assertEquals(1, x[1]);
                assertEquals(EXECUTE_FAILED, x[2]);
                assertEquals(1, x[3]);
                assertEquals(1, x[4]);
            }
        } finally {
            dropProcedure("jTDS_PROC");
        }
    }

    /**
     * Test batched callable statements where the call includes literal parameters which prevent the use of RPC calls.
     */
    public void testCallStmtBatch2() throws Exception {
        dropProcedure("jTDS_PROC");
        try {
            Statement stmt = con.createStatement();
            stmt.execute("create table #testbatch (id int, data varchar(255))");
            stmt.execute("create proc jTDS_PROC @p1 varchar(10), @p2 varchar(255) as " +
                    "INSERT INTO #testbatch VALUES (convert(int, @p1), @p2)");
            CallableStatement cstmt = con.prepareCall("{call jTDS_PROC (?, 'literal parameter')}");
            for (int i = 0; i < 5; i++) {
                if (i == 2) {
                    cstmt.setString(1, "XXX");
                } else {
                    cstmt.setString(1, Integer.toString(i));
                }
                cstmt.addBatch();
            }
            int x[];
            try {
                x = cstmt.executeBatch();
            } catch (BatchUpdateException e) {
                x = e.getUpdateCounts();
            }
            if (con.getMetaData().getDatabaseProductName().toLowerCase().startsWith("microsoft")) {
                assertEquals(5, x.length);
                assertEquals(1, x[0]);
                assertEquals(1, x[1]);
                assertEquals(EXECUTE_FAILED, x[2]);
                assertEquals(EXECUTE_FAILED, x[3]);
                assertEquals(EXECUTE_FAILED, x[4]);
            } else {
                assertEquals(5, x.length);
                assertEquals(1, x[0]);
                assertEquals(1, x[1]);
                assertEquals(EXECUTE_FAILED, x[2]);
                assertEquals(1, x[3]);
                assertEquals(1, x[4]);
            }
            // Now without errors
            stmt.execute("TRUNCATE TABLE #testbatch");
            for (int i = 0; i < 5; i++) {
                cstmt.setString(1, Integer.toString(i));
                cstmt.addBatch();
            }
            try {
                x = cstmt.executeBatch();
            } catch (BatchUpdateException e) {
                x = e.getUpdateCounts();
            }
            assertEquals(5, x.length);
            assertEquals(1, x[0]);
            assertEquals(1, x[1]);
            assertEquals(1, x[2]);
            assertEquals(1, x[3]);
            assertEquals(1, x[4]);
        } finally {
            dropProcedure("jTDS_PROC");
        }
    }

    /**
     * Test large batch behavior.
     */
    public void testLargeBatch() throws Exception {
        final int n = 5000;
        getConnection().close();

        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #testLargeBatch (val int)");
        stmt.executeUpdate("insert into #testLargeBatch (val) values (0)");

        PreparedStatement pstmt = con.prepareStatement(
                "update #testLargeBatch set val=? where val=?");
        for (int i = 0; i < n; i++) {
            pstmt.setInt(1, i + 1);
            pstmt.setInt(2, i);
            pstmt.addBatch();
        }
        int counts[] =pstmt.executeBatch();
//        System.out.println(pstmt.getWarnings());
        assertEquals(n, counts.length);
        for (int i = 0; i < n; i++) {
            assertEquals(1, counts[i]);
        }
        pstmt.close();

        ResultSet rs =
                stmt.executeQuery("select count(*) from #testLargeBatch");
        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();
        stmt.close();
    }

    /**
     * Test for bug [1180169] JDBC escapes not allowed with Sybase addBatch.
     */
    public void testBatchEsc() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #TESTBATCH (ts datetime)");
        stmt.addBatch("INSERT INTO #TESTBATCH VALUES ({ts '1999-01-01 23:50:00'})");
        int counts[] = stmt.executeBatch();
        assertEquals(1, counts[0]);
        stmt.close();
    }

    /**
     * Test for bug [1371295] SQL Server continues after duplicate key error.
     */
    public void testPrepStmtBatchDupKey() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create table #testbatch (id int, data varchar(255), PRIMARY KEY (id))");
        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #testbatch VALUES (?, ?)");
        for (int i = 0; i < 5; i++) {
            if (i == 2) {
                pstmt.setInt(1, 1); // Will cause duplicate key batch will continue
            } else {
                pstmt.setInt(1, i);
            }
            pstmt.setString(2, "This is line " + i);
            pstmt.addBatch();
        }
        int x[];
        try {
            x = pstmt.executeBatch();
        } catch (BatchUpdateException e) {
            x = e.getUpdateCounts();
        }
        assertEquals(5, x.length);
        assertEquals(1, x[0]);
        assertEquals(1, x[1]);
        assertEquals(EXECUTE_FAILED, x[2]);
        assertEquals(1, x[3]);
        assertEquals(1, x[4]);
        // Now without errors
        stmt.execute("TRUNCATE TABLE #testbatch");
        for (int i = 0; i < 5; i++) {
            pstmt.setInt(1, i);
            pstmt.setString(2, "This is line " + i);
            pstmt.addBatch();
        }
        x = pstmt.executeBatch();
        assertEquals(5, x.length);
        assertEquals(1, x[0]);
        assertEquals(1, x[1]);
        assertEquals(1, x[2]);
        assertEquals(1, x[3]);
        assertEquals(1, x[4]);
    }

    /**
     * Test for bug [1371295] SQL Server continues after duplicate key error.
     */
    public void testBatchDupKey() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create table #testbatch (id int, data varchar(255), PRIMARY KEY (id))");
        for (int i = 0; i < 5; i++) {
            if (i == 2) {
                // This statement will generate an duplicate key error
                stmt.addBatch("INSERT INTO #testbatch VALUES (1, 'This is line " + i + "')");
            } else {
                stmt.addBatch("INSERT INTO #testbatch VALUES (" + i + ", 'This is line " + i + "')");
            }
        }
        int x[];
        try {
            x = stmt.executeBatch();
        } catch (BatchUpdateException e) {
            x = e.getUpdateCounts();
        }
        assertEquals(5, x.length);
        assertEquals(1, x[0]);
        assertEquals(1, x[1]);
        assertEquals(EXECUTE_FAILED, x[2]);
        assertEquals(1, x[3]);
        assertEquals(1, x[4]);
        // Now without errors
        stmt.execute("TRUNCATE TABLE #testbatch");
        for (int i = 0; i < 5; i++) {
            stmt.addBatch("INSERT INTO #testbatch VALUES (" + i + ", 'This is line " + i + "')");
        }
        x = stmt.executeBatch();
        assertEquals(5, x.length);
        assertEquals(1, x[0]);
        assertEquals(1, x[1]);
        assertEquals(1, x[2]);
        assertEquals(1, x[3]);
        assertEquals(1, x[4]);
    }
    
    /**
     * Test for PreparedStatement batch with no parameters.
     */
    public void testPrepStmtNoParams() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create table #testbatch (id numeric(10) identity, data varchar(255), PRIMARY KEY (id))");
        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #testbatch (data) VALUES ('Same each time')");
        for (int i = 0; i < 5; i++) {
            pstmt.addBatch();
        }
        int x[];
        try {
            x = pstmt.executeBatch();
        } catch (BatchUpdateException e) {
            x = e.getUpdateCounts();
        }
        assertEquals(5, x.length);
        assertEquals(1, x[0]);
        assertEquals(1, x[1]);
        assertEquals(1, x[2]);
        assertEquals(1, x[3]);
        assertEquals(1, x[4]);
    }

    /**
     * Test for PreparedStatement batch with variable parameter types.
     */
    public void testPrepStmtVariableParams() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create table #testbatch (id int, data int, PRIMARY KEY (id))");
        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #testbatch VALUES (?, convert(int, ?))");
        for (int i = 0; i < 5; i++) {
            pstmt.setInt(1, i);
            if (i == 2) {
                // This statement will require a string param instead of an int
                pstmt.setString(2, "123");
            } else {
                pstmt.setInt(2, 123);
            }
            pstmt.addBatch();
        }
        int x[];
        try {
            x = pstmt.executeBatch();
        } catch (BatchUpdateException e) {
            x = e.getUpdateCounts();
        }
        assertEquals(5, x.length);
        assertEquals(1, x[0]);
        assertEquals(1, x[1]);
        assertEquals(1, x[2]);
        assertEquals(1, x[3]);
        assertEquals(1, x[4]);
        ResultSet rs = stmt.executeQuery("SELECT * FROM #testbatch");
        assertNotNull(rs);
        int i = 0;
        while (rs.next()) {
            assertEquals(123, rs.getInt(2));
            i++;
        }
        assertEquals(5, i);
    }
    
    /**
     * Test batched callable statements where the call has no parameters.
     */
    public void testCallStmtNoParams() throws Exception {
        dropProcedure("jTDS_PROC");
        try {
            Statement stmt = con.createStatement();
            stmt.execute("create table #testbatch (id numeric(10) identity, data varchar(255))");
            stmt.execute("create proc jTDS_PROC  as " +
                    "INSERT INTO #testbatch (data) VALUES ('same each time')");
            CallableStatement cstmt = con.prepareCall("{call jTDS_PROC}");
            for (int i = 0; i < 5; i++) {
                cstmt.addBatch();
            }
            int x[];
            try {
                x = cstmt.executeBatch();
            } catch (BatchUpdateException e) {
                x = e.getUpdateCounts();
            }
            assertEquals(5, x.length);
            assertEquals(1, x[0]);
            assertEquals(1, x[1]);
            assertEquals(1, x[2]);
            assertEquals(1, x[3]);
            assertEquals(1, x[4]);
        } finally {
            dropProcedure("jTDS_PROC");
        }
    }


    /**
     * Helper thread used by <code>testConcurrentBatching()</code> to execute a batch within a transaction that is
     * then rolled back. Starting a couple of these threads concurrently should show whether there are any race
     * conditions WRT preparation and execution in the batching implementation.
     */
    private class ConcurrentBatchingHelper extends Thread {
        /** Connection on which to do the work. */
        private Connection con;
        /** Container to store any exceptions into. */
        private Vector exceptions;

        ConcurrentBatchingHelper(Connection con, Vector exceptions) {
            this.con = con;
            this.exceptions = exceptions;
        }

        public void run() {
            try {
                PreparedStatement pstmt = con.prepareStatement(
                        "insert into #testConcurrentBatch (v1, v2, v3, v4, v5, v6) values (?, ?, ?, ?, ?, ?)");
                for (int i = 0; i < 64; ++i) {
                    // Make sure we end up with 64 different prepares, use the binary representation of i to set each
                    // of the 6 parameters to either an int or a string.
                    int mask = i;
                    for (int j = 1; j <= 6; ++j, mask >>= 1) {
                        if ((mask & 1) != 0) {
                            pstmt.setInt(j, i);
                        } else {
                            pstmt.setString(j, String.valueOf(i));
                        }
                    }
                    pstmt.addBatch();
                }
                int x[];
                try {
                    x = pstmt.executeBatch();
                } catch (BatchUpdateException e) {
                    e.printStackTrace();
                    x = e.getUpdateCounts();
                }
                if (x.length != 64) {
                    throw new SQLException("Expected 64 update counts, got " + x.length);
                }
                for (int i = 0; i < x.length; ++i) {
                    if (x[i] != 1) {
                        throw new SQLException("Error at position " + i + ", got " + x[i] + " instead of 1");
                    }
                }
                // Rollback the transaction, exposing any race conditions.
                con.rollback();
                pstmt.close();
            } catch (SQLException ex) {
                ex.printStackTrace();
                exceptions.add(ex);
            }
        }
    }

    /**
     * Test batched prepared statement concurrency. Batch prepares must not disappear between the moment when they
     * were created and when they are executed.
     */
    public void testConcurrentBatching() throws Exception {
        // Create a connection with a batch size of 1. This should cause prepares and actual batch execution to become
        // interspersed (if correct synchronization is not in place) and greatly increase the chance of prepares
        // being rolled back before getting executed.
        Properties props = new Properties();
        props.setProperty(Messages.get(net.sourceforge.jtds.jdbc.Driver.BATCHSIZE), "1");
        props.setProperty(Messages.get(net.sourceforge.jtds.jdbc.Driver.PREPARESQL),
                          String.valueOf(TdsCore.TEMPORARY_STORED_PROCEDURES));
        Connection con = getConnection(props);
        
        try {
            Statement stmt = con.createStatement();
            stmt.execute("create table #testConcurrentBatch (v1 int, v2 int, v3 int, v4 int, v5 int, v6 int)");
            stmt.close();

            Vector exceptions = new Vector();
            con.setAutoCommit(false);

            Thread t1 = new ConcurrentBatchingHelper(con, exceptions);
            Thread t2 = new ConcurrentBatchingHelper(con, exceptions);
            t1.start();
            t2.start();
            t1.join();
            t2.join();

            assertEquals(0, exceptions.size());
        } finally {
            con.close();
        }
    }

    /**
     * this is a test for the data truncation problem described in bug [2731952]
     */
    public void testDataTruncation() throws SQLException {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #DATATRUNC (id int, data text)");
        stmt.close();

        // create 2 different strings
        StringBuffer sb1 = new StringBuffer(10000);
        StringBuffer sb2 = new StringBuffer(100);

        for (int i=1; i<=1000; i++) {
            sb1.append(" +++ ").append("    ".substring(String.valueOf(i).length())).append(i).append("\n");
        }

        for (int i=1; i<=10; i++) {
            sb2.append(" --- ").append("    ".substring(String.valueOf(i).length())).append(i).append("\n");
        }

        String string1 = sb1.toString();
        String string2 = sb2.toString();

        PreparedStatement pstmt = con.prepareStatement("insert into #DATATRUNC (id, data) values (?, ?)");

        // insert both values into DB in batch mode
        pstmt.setInt(1, 1);
        pstmt.setString(2, string1);
        pstmt.addBatch();

        pstmt.setInt(1, 2);
        pstmt.setString(2, string2);
        pstmt.addBatch();

        assertTrue(Arrays.equals(new int[] {1, 1},pstmt.executeBatch()));

        // insert first string again, no batch
        pstmt.setInt(1, 3);
        pstmt.setString(2, string1);

        assertEquals(1,pstmt.executeUpdate());
        pstmt.close();

        // ensure all 3 entries are still intact
        stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("select data from #DATATRUNC order by id asc");

        // 1st value, should be string1
        assertTrue(rs.next());
        String value = rs.getString(1);
        assertEquals(string1.length(), value.length());
        assertEquals(string1, value);

        // 2nd value, should be string2
        assertTrue(rs.next());
        value = rs.getString(1);
        assertEquals(string2.length(), value.length());
        assertEquals(string2, value);

        // 3rd value, should be string1
        assertTrue(rs.next());
        value = rs.getString(1);
        assertEquals(string1.length(), value.length());
        assertEquals(string1, value);

        rs.close();
        stmt.close();
    }

    /**
     * test for bug [2827931] that implicitly also tests for bug [1811383]
     *
     * example for statement that produces multiple update counts unexpectedly:
     * IF sessionproperty('ARITHABORT') = 0 SET ARITHABORT ON
     */
    public void testBatchUpdateCounts() throws SQLException {
        Statement statement = con.createStatement();
        statement.execute("CREATE TABLE #BATCHUC (id int)");
        statement.addBatch("insert into #BATCHUC values (1)");
        statement.addBatch("insert into #BATCHUC values (2);insert into #BATCHUC values (3)");
        statement.addBatch("insert into #BATCHUC values (4);insert into #BATCHUC values (5);insert into #BATCHUC values (6)");
        // below: create identifiable update counts to show if/how far they have been shifted due to bug [2827931]
        statement.addBatch("insert into #BATCHUC select * from #BATCHUC");
        statement.addBatch("insert into #BATCHUC select * from #BATCHUC where id=999");
        statement.addBatch("insert into #BATCHUC select * from #BATCHUC where id=999");
        statement.addBatch("insert into #BATCHUC select * from #BATCHUC where id=999");
        statement.addBatch("insert into #BATCHUC select * from #BATCHUC where id=999");
        assertEquals(array2String(new int[]{1,2,3,6,0,0,0,0,0,0}),array2String(statement.executeBatch()));
        statement.close();
    }

    private static String array2String(int[] a) {
        if (a == null)
            return "null";
        int iMax = a.length - 1;
        if (iMax == -1)
            return "[]";

        StringBuffer b = new StringBuffer();
        b.append('[');
        for (int i = 0; ; i++) {
            b.append(a[i]);
            if (i == iMax)
                return b.append(']').toString();
            b.append(", ");
        }
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(BatchTest.class);
    }

}