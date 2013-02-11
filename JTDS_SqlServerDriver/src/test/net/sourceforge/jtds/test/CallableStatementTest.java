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
//
// MJH - Changes for new jTDS version
// Added registerOutParameter to testCallableStatementParsing2
//
/**
 * @version 1.0
 */
public class CallableStatementTest extends TestBase {
    public CallableStatementTest(String name) {
        super(name);
    }

    public void testCallableStatement() throws Exception {
        CallableStatement cstmt = con.prepareCall("{call sp_who}");

        cstmt.close();
    }

    public void testCallableStatement1() throws Exception {
        CallableStatement cstmt = con.prepareCall("sp_who");

        ResultSet rs = cstmt.executeQuery();
        dump(rs);

        rs.close();
        cstmt.close();
    }

    public void testCallableStatementCall1() throws Exception {
        CallableStatement cstmt = con.prepareCall("{call sp_who}");

        ResultSet rs = cstmt.executeQuery();
        dump(rs);

        rs.close();
        cstmt.close();
    }

    public void testCallableStatementCall2() throws Exception {
        CallableStatement cstmt = con.prepareCall("{CALL sp_who}");

        ResultSet rs = cstmt.executeQuery();
        dump(rs);

        rs.close();
        cstmt.close();
    }

    public void testCallableStatementCall3() throws Exception {
        CallableStatement cstmt = con.prepareCall("{cAlL sp_who}");

        ResultSet rs = cstmt.executeQuery();
        dump(rs);

        rs.close();
        cstmt.close();
    }

    /**
     * Test for bug [974801] stored procedure error in Northwind
     */
    public void testCallableStatementCall4() throws Exception {
        Statement stmt;

        try {
            stmt = con.createStatement();
            stmt.execute("create procedure \"#test space\" as SELECT COUNT(*) FROM sysobjects");
            stmt.close();

            CallableStatement cstmt = con.prepareCall("{call \"#test space\"}");

            ResultSet rs = cstmt.executeQuery();
            dump(rs);

            rs.close();
            cstmt.close();
        } finally {
            stmt = con.createStatement();
            stmt.execute("drop procedure \"#test space\"");
            stmt.close();
        }
    }

    public void testCallableStatementExec1() throws Exception {
        CallableStatement cstmt = con.prepareCall("exec sp_who");

        ResultSet rs = cstmt.executeQuery();
        dump(rs);

        rs.close();
        cstmt.close();
    }

    public void testCallableStatementExec2() throws Exception {
        CallableStatement cstmt = con.prepareCall("EXEC sp_who");

        ResultSet rs = cstmt.executeQuery();
        dump(rs);

        rs.close();
        cstmt.close();
    }

    public void testCallableStatementExec3() throws Exception {
        CallableStatement cstmt = con.prepareCall("execute sp_who");

        ResultSet rs = cstmt.executeQuery();
        dump(rs);

        rs.close();
        cstmt.close();
    }

    public void testCallableStatementExec4() throws Exception {
        CallableStatement cstmt = con.prepareCall("EXECUTE sp_who");

        ResultSet rs = cstmt.executeQuery();
        dump(rs);

        rs.close();
        cstmt.close();
    }

    public void testCallableStatementExec5() throws Exception {
        CallableStatement cstmt = con.prepareCall("eXeC sp_who");

        ResultSet rs = cstmt.executeQuery();
        dump(rs);

        rs.close();
        cstmt.close();
    }

    public void testCallableStatementExec6() throws Exception {
        CallableStatement cstmt = con.prepareCall("ExEcUtE sp_who");

        ResultSet rs = cstmt.executeQuery();
        dump(rs);

        rs.close();
        cstmt.close();
    }

    public void testCallableStatementExec7() throws Exception {
        CallableStatement cstmt = con.prepareCall("execute \"master\"..sp_who");

        ResultSet rs = cstmt.executeQuery();
        dump(rs);

        rs.close();
        cstmt.close();
    }

    public void testCallableStatementExec8() throws Exception {
        Statement stmt;

        try {
            stmt = con.createStatement();
            stmt.execute("create procedure #test as SELECT COUNT(*) FROM sysobjects");
            stmt.close();

            CallableStatement cstmt = con.prepareCall("execute #test");

            ResultSet rs = cstmt.executeQuery();
            dump(rs);

            rs.close();
            cstmt.close();
        } finally {
            stmt = con.createStatement();
            stmt.execute("drop procedure #test");
            stmt.close();
        }
    }

    /**
     * Test for bug [978175] 0.8: Stored Procedure call doesn't work anymore
     */
    public void testCallableStatementExec9() throws Exception {
        CallableStatement cstmt = con.prepareCall("{call sp_who}");

        assertTrue(cstmt.execute());

        ResultSet rs = cstmt.getResultSet();

        if (rs == null) {
            fail("Null ResultSet returned");
        } else {
            dump(rs);
            rs.close();
        }

        cstmt.close();
    }

    public void testCallableStatementParsing1() throws Exception {
        String data = "New {order} plus {1} more";
        Statement stmt = con.createStatement();

        stmt.execute("CREATE TABLE #csp1 (data VARCHAR(32))");
        stmt.close();

        stmt = con.createStatement();
        stmt.execute("create procedure #sp_csp1 @data VARCHAR(32) as INSERT INTO #csp1 (data) VALUES(@data)");
        stmt.close();

        CallableStatement cstmt = con.prepareCall("{call #sp_csp1(?)}");

        cstmt.setString(1, data);
        cstmt.execute();
        cstmt.close();

        stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT data FROM #csp1");

        assertTrue(rs.next());

        assertTrue(data.equals(rs.getString(1)));

        assertTrue(!rs.next());
        rs.close();
        stmt.close();
    }

    /**
     * Test for bug [938632] String index out of bounds error in 0.8rc1.
     */
    public void testCallableStatementParsing2() throws Exception {
        try {
            Statement stmt = con.createStatement();

            stmt.execute("create procedure #load_smtp_in_1gr_ls804192 as SELECT name FROM sysobjects");
            stmt.close();

            CallableStatement cstmt = con.prepareCall("{?=call #load_smtp_in_1gr_ls804192}");
            cstmt.registerOutParameter(1, java.sql.Types.INTEGER); // MJH 01/05/04
            cstmt.execute();
            cstmt.close();
        } finally {
            Statement stmt = con.createStatement();

            stmt.execute("drop procedure #load_smtp_in_1gr_ls804192");
            stmt.close();
        }
    }

    /**
     * Test for bug [1006845] Stored procedure with 18 parameters.
     */
    public void testCallableStatementParsing3() throws Exception {
        CallableStatement cstmt = con.prepareCall("{Call Test(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)}");
        cstmt.close();
    }

    /**
     * Test for incorrect exception thrown/no exception thrown when invalid
     * call escape is used.
     * <p/>
     * See https://sourceforge.net/forum/forum.php?thread_id=1144619&forum_id=104389
     * for more detail.
     */
    public void testCallableStatementParsing4() throws SQLException {
        try {
            con.prepareCall("{call ? = sp_create_employee (?, ?, ?, ?, ?, ?)}");
            fail("Was expecting an invalid escape sequence error");
        } catch (SQLException ex) {
            assertEquals("22025", ex.getSQLState());
        }
    }

    /**
     * Test for bug [1052942] Error processing JDBC call escape. (A blank
     * before the final <code>}</code> causes the parser to fail).
     */
    public void testCallableStatementParsing5() throws Exception {
        CallableStatement cstmt = con.prepareCall(" { Call Test(?,?) } ");
        cstmt.close();
    }

    /**
     * Test for incorrect exception thrown/no exception thrown when invalid
     * call escape is used.
     * <p/>
     * A message containing the correct missing terminator should be generated.
     */
    public void testCallableStatementParsing6() throws SQLException {
        try {
            con.prepareCall("{call sp_test(?, ?)");
            fail("Was expecting an invalid escape error");
        } catch (SQLException ex) {
            assertEquals("22025", ex.getSQLState());
            assertTrue(ex.getMessage().indexOf('}') != -1);
        }
    }

    /**
     * Test for incorrect exception thrown/no exception thrown when invalid
     * call escape is used.
     * <p/>
     * A message containing the correct missing terminator should be generated.
     */
    public void testCallableStatementParsing7() throws SQLException {
        try {
            con.prepareCall("{call sp_test(?, ?}");
            fail("Was expecting an invalid escape error");
        } catch (SQLException ex) {
            assertEquals("22025", ex.getSQLState());
            assertTrue(ex.getMessage().indexOf(')') != -1);
        }
    }

    /**
     * Test for reature request [956800] setNull(): Not implemented.
     */
    public void testCallableSetNull1() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #callablesetnull1 (data CHAR(1) NULL)");
        stmt.close();

        try {
            stmt = con.createStatement();
            stmt.execute("create procedure #procCallableSetNull1 @data char(1) "
            		+ "as INSERT INTO #callablesetnull1 (data) VALUES (@data)");
            stmt.close();

            CallableStatement cstmt = con.prepareCall("{call #procCallableSetNull1(?)}");
            // Test CallableStatement.setNull(int,Types.NULL)
            cstmt.setNull(1, Types.NULL);
            cstmt.execute();
            cstmt.close();

            stmt = con.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT data FROM #callablesetnull1");

            assertTrue(rs.next());

            // Test ResultSet.getString()
            assertNull(rs.getString(1));
            assertTrue(rs.wasNull());

            assertTrue(!rs.next());
            stmt.close();
            rs.close();
        } finally {
            stmt = con.createStatement();
            stmt.execute("drop procedure #procCallableSetNull1");
            stmt.close();
        }
    }

    /**
     * Test for bug [974284] retval on callable statement isn't handled correctly
     */
    public void testCallableRegisterOutParameter1() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create procedure #rop1 @a varchar(1), @b varchar(1) as\r\n "
                     + "begin\r\n"
                     + "return 1\r\n"
                     + "end");
        stmt.close();

        CallableStatement cstmt = con.prepareCall("{? = call #rop1(?, ?)}");

        cstmt.registerOutParameter(1, Types.INTEGER);
        cstmt.setString(2, "a");
        cstmt.setString(3, "b");
        cstmt.execute();

        assertEquals(1, cstmt.getInt(1));
        assertEquals("1", cstmt.getString(1));

        cstmt.close();
    }

    /**
     * Test for bug [994888] Callable statement and Float output parameter
     */
    public void testCallableRegisterOutParameter2() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create procedure #rop2 @data float OUTPUT as\r\n "
                     + "begin\r\n"
                     + "set @data = 1.1\r\n"
                     + "end");
        stmt.close();

        CallableStatement cstmt = con.prepareCall("{call #rop2(?)}");

        cstmt.registerOutParameter(1, Types.FLOAT);
        cstmt.execute();

        assertTrue(cstmt.getFloat(1) == 1.1f);
        cstmt.close();
    }

    /**
     * Test for bug [994988] Network error when null is returned via int output parm
     */
    public void testCallableRegisterOutParameter3() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create procedure #rop3 @data int OUTPUT as\r\n "
                     + "begin\r\n"
                     + "set @data = null\r\n"
                     + "end");
        stmt.close();

        CallableStatement cstmt = con.prepareCall("{call #rop3(?)}");

        cstmt.registerOutParameter(1, Types.INTEGER);
        cstmt.execute();

        cstmt.getInt(1);
        assertTrue(cstmt.wasNull());
        cstmt.close();
    }

    /**
     * Test for bug [983432] Prepared call doesn't work with jTDS 0.8
     */
    public void testCallableRegisterOutParameter4() throws Exception {
        CallableStatement cstmt = con.prepareCall("{call sp_addtype T_INTEGER, int, 'NULL'}");
        Statement stmt = con.createStatement();

        try {
            cstmt.execute();
            cstmt.close();

            stmt.execute("create procedure rop4 @data T_INTEGER OUTPUT as\r\n "
                         + "begin\r\n"
                         + "set @data = 1\r\n"
                         + "end");
            stmt.close();

            cstmt = con.prepareCall("{call rop4(?)}");

            cstmt.registerOutParameter(1, Types.VARCHAR);
            cstmt.execute();

            assertEquals(cstmt.getInt(1), 1);
            assertTrue(!cstmt.wasNull());
            cstmt.close();

            cstmt = con.prepareCall("rop4 ?");

            cstmt.registerOutParameter(1, Types.VARCHAR);
            cstmt.execute();

            assertEquals(cstmt.getInt(1), 1);
            assertTrue(!cstmt.wasNull());
            cstmt.close();
        } finally {
            stmt = con.createStatement();
            stmt.execute("drop procedure rop4");
            stmt.close();

            cstmt = con.prepareCall("{call sp_droptype 'T_INTEGER'}");
            cstmt.execute();
            cstmt.close();
        }
    }

    /**
     * Test for bug [991640] java.sql.Date error and RAISERROR problem
     */
    public void testCallableError1() throws Exception {
        String text = "test message";

        Statement stmt = con.createStatement();
        stmt.execute("create procedure #ce1 as\r\n "
                     + "begin\r\n"
                     + "RAISERROR('" + text + "', 16, 1 )\r\n"
                     + "end");
        stmt.close();

        CallableStatement cstmt = con.prepareCall("{call #ce1}");

        try {
            cstmt.execute();
            assertTrue(false);
        } catch (SQLException e) {
            assertTrue(e.getMessage().equals(text));
        }

        cstmt.close();
    }

    /**
     * Test that procedure outputs are available immediately for procedures
     * that do not return ResultSets (i.e that update counts are cached).
     */
    public void testProcessUpdateCounts1() throws SQLException {
        Statement stmt = con.createStatement();
        assertFalse(stmt.execute("CREATE TABLE #testProcessUpdateCounts1 (val INT)"));
        assertFalse(stmt.execute("CREATE PROCEDURE #procTestProcessUpdateCounts1"
                + " @res INT OUT AS"
                + " INSERT INTO #testProcessUpdateCounts1 VALUES (1)"
                + " UPDATE #testProcessUpdateCounts1 SET val = 2"
                + " INSERT INTO #testProcessUpdateCounts1 VALUES (1)"
                + " UPDATE #testProcessUpdateCounts1 SET val = 3"
                + " SET @res = 13"
                + " RETURN 14"));
        stmt.close();

        CallableStatement cstmt = con.prepareCall(
                "{?=call #procTestProcessUpdateCounts1(?)}");
        cstmt.registerOutParameter(1, Types.INTEGER);
        cstmt.registerOutParameter(2, Types.INTEGER);

        assertFalse(cstmt.execute());
        assertEquals(14, cstmt.getInt(1));
        assertEquals(13, cstmt.getInt(2));

        assertEquals(1, cstmt.getUpdateCount()); // INSERT

        assertFalse(cstmt.getMoreResults());
        assertEquals(1, cstmt.getUpdateCount()); // UPDATE

        assertFalse(cstmt.getMoreResults());
        assertEquals(1, cstmt.getUpdateCount()); // INSERT

        assertFalse(cstmt.getMoreResults());
        assertEquals(2, cstmt.getUpdateCount()); // UPDATE

        assertFalse(cstmt.getMoreResults());
        assertEquals(-1, cstmt.getUpdateCount());

        cstmt.close();
    }

    /**
     * Test that procedure outputs are available immediately after processing
     * the last ResultSet returned by the procedure (i.e that update counts
     * are cached).
     */
    public void testProcessUpdateCounts2() throws SQLException {
        Statement stmt = con.createStatement();
        assertFalse(stmt.execute("CREATE TABLE #testProcessUpdateCounts2 (val INT)"));
        assertFalse(stmt.execute("CREATE PROCEDURE #procTestProcessUpdateCounts2"
                + " @res INT OUT AS"
                + " INSERT INTO #testProcessUpdateCounts2 VALUES (1)"
                + " UPDATE #testProcessUpdateCounts2 SET val = 2"
                + " SELECT * FROM #testProcessUpdateCounts2"
                + " INSERT INTO #testProcessUpdateCounts2 VALUES (1)"
                + " UPDATE #testProcessUpdateCounts2 SET val = 3"
                + " SET @res = 13"
                + " RETURN 14"));
        stmt.close();

        CallableStatement cstmt = con.prepareCall(
                "{?=call #procTestProcessUpdateCounts2(?)}");
        cstmt.registerOutParameter(1, Types.INTEGER);
        cstmt.registerOutParameter(2, Types.INTEGER);

        assertFalse(cstmt.execute());
        try {
            assertEquals(14, cstmt.getInt(1));
            assertEquals(13, cstmt.getInt(2));
            // Don't fail the test if we got here. Another driver or a future
            // version could cache all the results and obtain the output
            // parameter values from the beginning.
        } catch (SQLException ex) {
            assertEquals("HY010", ex.getSQLState());
            assertTrue(ex.getMessage().indexOf("getMoreResults()") >= 0);
        }

        assertEquals(1, cstmt.getUpdateCount()); // INSERT

        assertFalse(cstmt.getMoreResults());
        assertEquals(1, cstmt.getUpdateCount()); // UPDATE

        assertTrue(cstmt.getMoreResults()); // SELECT

        assertFalse(cstmt.getMoreResults());
        assertEquals(14, cstmt.getInt(1));
        assertEquals(13, cstmt.getInt(2));
        assertEquals(1, cstmt.getUpdateCount()); // INSERT

        assertFalse(cstmt.getMoreResults());
        assertEquals(2, cstmt.getUpdateCount()); // UPDATE

        assertFalse(cstmt.getMoreResults());
        assertEquals(-1, cstmt.getUpdateCount());

        cstmt.close();
    }

    /**
     * Test that procedure outputs are available immediately after processing
     * the last ResultSet returned by the procedure (i.e that update counts
     * are cached) even if getMoreResults() is not called.
     */
    public void testProcessUpdateCounts3() throws SQLException {
        Statement stmt = con.createStatement();
        assertFalse(stmt.execute("CREATE TABLE #testProcessUpdateCounts3 (val INT)"));
        assertFalse(stmt.execute("CREATE PROCEDURE #procTestProcessUpdateCounts3"
                + " @res INT OUT AS"
                + " INSERT INTO #testProcessUpdateCounts3 VALUES (1)"
                + " UPDATE #testProcessUpdateCounts3 SET val = 2"
                + " SELECT * FROM #testProcessUpdateCounts3"
                + " INSERT INTO #testProcessUpdateCounts3 VALUES (1)"
                + " UPDATE #testProcessUpdateCounts3 SET val = 3"
                + " SET @res = 13"
                + " RETURN 14"));
        stmt.close();

        CallableStatement cstmt = con.prepareCall(
                "{?=call #procTestProcessUpdateCounts3(?)}");
        cstmt.registerOutParameter(1, Types.INTEGER);
        cstmt.registerOutParameter(2, Types.INTEGER);

        assertFalse(cstmt.execute());
        try {
            assertEquals(14, cstmt.getInt(1));
            assertEquals(13, cstmt.getInt(2));
            // Don't fail the test if we got here. Another driver or a future
            // version could cache all the results and obtain the output
            // parameter values from the beginning.
        } catch (SQLException ex) {
            assertEquals("HY010", ex.getSQLState());
            assertTrue(ex.getMessage().indexOf("getMoreResults()") >= 0);
        }

        assertEquals(1, cstmt.getUpdateCount()); // INSERT

        assertFalse(cstmt.getMoreResults());
        assertEquals(1, cstmt.getUpdateCount()); // UPDATE

        assertTrue(cstmt.getMoreResults()); // SELECT
        ResultSet rs = cstmt.getResultSet();
        assertNotNull(rs);
        // Close the ResultSet; this should cache the following update counts
        rs.close();

        assertEquals(14, cstmt.getInt(1));
        assertEquals(13, cstmt.getInt(2));

        assertFalse(cstmt.getMoreResults());
        assertEquals(1, cstmt.getUpdateCount()); // INSERT

        assertFalse(cstmt.getMoreResults());
        assertEquals(2, cstmt.getUpdateCount()); // UPDATE

        assertFalse(cstmt.getMoreResults());
        assertEquals(-1, cstmt.getUpdateCount());

        cstmt.close();
    }

    /**
     * Test that procedure outputs are available immediately after processing
     * the last ResultSet returned by the procedure (i.e that update counts
     * are cached) even if getMoreResults() and ResultSet.close() are not
     * called.
     */
    public void testProcessUpdateCounts4() throws SQLException {
        Statement stmt = con.createStatement();
        assertFalse(stmt.execute("CREATE TABLE #testProcessUpdateCounts4 (val INT)"));
        assertFalse(stmt.execute("CREATE PROCEDURE #procTestProcessUpdateCounts4"
                + " @res INT OUT AS"
                + " INSERT INTO #testProcessUpdateCounts4 VALUES (1)"
                + " UPDATE #testProcessUpdateCounts4 SET val = 2"
                + " SELECT * FROM #testProcessUpdateCounts4"
                + " INSERT INTO #testProcessUpdateCounts4 VALUES (1)"
                + " UPDATE #testProcessUpdateCounts4 SET val = 3"
                + " SET @res = 13"
                + " RETURN 14"));
        stmt.close();

        CallableStatement cstmt = con.prepareCall(
                "{?=call #procTestProcessUpdateCounts4(?)}");
        cstmt.registerOutParameter(1, Types.INTEGER);
        cstmt.registerOutParameter(2, Types.INTEGER);

        assertFalse(cstmt.execute());
        try {
            assertEquals(14, cstmt.getInt(1));
            assertEquals(13, cstmt.getInt(2));
            // Don't fail the test if we got here. Another driver or a future
            // version could cache all the results and obtain the output
            // parameter values from the beginning.
        } catch (SQLException ex) {
            assertEquals("HY010", ex.getSQLState());
            assertTrue(ex.getMessage().indexOf("getMoreResults()") >= 0);
        }

        assertEquals(1, cstmt.getUpdateCount()); // INSERT

        assertFalse(cstmt.getMoreResults());
        assertEquals(1, cstmt.getUpdateCount()); // UPDATE

        assertTrue(cstmt.getMoreResults()); // SELECT
        ResultSet rs = cstmt.getResultSet();
        assertNotNull(rs);
        // Process all rows; this should cache the following update counts
        assertTrue(rs.next());
        assertFalse(rs.next());

        assertEquals(14, cstmt.getInt(1));
        assertEquals(13, cstmt.getInt(2));

        // Only close the ResultSet now
        rs.close();

        assertFalse(cstmt.getMoreResults());
        assertEquals(1, cstmt.getUpdateCount()); // INSERT

        assertFalse(cstmt.getMoreResults());
        assertEquals(2, cstmt.getUpdateCount()); // UPDATE

        assertFalse(cstmt.getMoreResults());
        assertEquals(-1, cstmt.getUpdateCount());

        cstmt.close();
    }

    /**
     * Test for bug [ 1062671 ] SQLParser unable to parse CONVERT(char,{ts ?},102)
     */
    public void testTsEscape() throws Exception {
        Timestamp ts = Timestamp.valueOf("2004-01-01 23:56:56");
        Statement stmt = con.createStatement();
        assertFalse(stmt.execute("CREATE TABLE #testTsEscape (val DATETIME)"));
        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #testTsEscape VALUES({ts ?})");
        pstmt.setTimestamp(1, ts);
        assertEquals(1, pstmt.executeUpdate());
        ResultSet rs = stmt.executeQuery("SELECT * FROM #testTsEscape");
        assertTrue(rs.next());
        assertEquals(ts, rs.getTimestamp(1));
    }

    /**
     * Test for separation of IN and INOUT/OUT parameter values
     */
    public void testInOutParameters() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE PROC #testInOut @in int, @out int output as SELECT @out = @out + @in");
        CallableStatement cstmt = con.prepareCall("{ call #testInOut ( ?,? ) }");
        cstmt.setInt(1, 1);
        cstmt.registerOutParameter(2, Types.INTEGER);
        cstmt.setInt(2, 2);
        cstmt.execute();
        assertEquals(3, cstmt.getInt(2));
        cstmt.execute();
        assertEquals(3, cstmt.getInt(2));
    }

    /**
     * Test that procedure names containing semicolons are parsed correctly.
     */
    public void testSemicolonProcedures() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE PROC #testInOut @in int, @out int output as SELECT @out = @out + @in");
        CallableStatement cstmt = con.prepareCall("{call #testInOut;1(?,?)}");
        cstmt.setInt(1, 1);
        cstmt.registerOutParameter(2, Types.INTEGER);
        cstmt.setInt(2, 2);
        cstmt.execute();
        assertEquals(3, cstmt.getInt(2));
        cstmt.execute();
        assertEquals(3, cstmt.getInt(2));
    }

    /**
     * Test that procedure calls with both literal parameters and parameterr
     * markers are executed correctly (bug [1078927] Callable statement fails).
     */
    public void testNonRpcProc1() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute(
                "create proc #testsp1 @p1 int, @p2 int out as set @p2 = @p1");
        stmt.close();

        CallableStatement cstmt = con.prepareCall("{call #testsp1(100, ?)}");
        cstmt.setInt(1, 1);
        cstmt.execute();
        cstmt.close();
    }

    /**
     * Test that procedure calls with both literal parameters and parameterr
     * markers are executed correctly (bug [1078927] Callable statement fails).
     */
    public void testNonRpcProc2() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create proc #testsp2 @p1 int, @p2 int as return 99");
        stmt.close();

        CallableStatement cstmt = con.prepareCall("{?=call #testsp2(100, ?)}");
        cstmt.registerOutParameter(1, java.sql.Types.INTEGER);
        cstmt.setInt(2, 2);
        cstmt.execute();
        assertEquals(99, cstmt.getInt(1));
        cstmt.close();
    }

    /**
     * Test for bug [1152329] Spurious output params assigned (TIMESTMP).
     * <p/>
     * If a stored procedure execute WRITETEXT or UPDATETEXT commands, spurious
     * output parameter data is returned to the client. This additional data
     * can be confused with the real output parameter data leading to an output
     * string parameter returning the text ?TIMESTMP? on SQL Server 7+ or
     * binary garbage on other servers.
     */
    public void testWritetext() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute(
                "create proc #testWritetext @p1 varchar(20) output as "
                + "begin "
                + "create table #test (id int, txt text) "
                + "insert into #test (id, txt) values(1, '') "
                + "declare @ptr binary(16) "
                + "select @ptr = (select textptr(txt) from #test where id = 1) "
                + "writetext #test.txt @ptr 'This is a test' "
                + "select @p1 = 'done' "
                + "end");
        stmt.close();

        CallableStatement cstmt = con.prepareCall("{call #testWritetext(?)}");
        cstmt.registerOutParameter(1, Types.VARCHAR);
        cstmt.execute();
        assertEquals("done", cstmt.getString(1));
        cstmt.close();
    }

    /**
     * Test for bug [1047208] SQLException chaining not implemented correctly:
     * checks that all errors are returned and that output variables are also
     * returned.
     */
    public void testErrorOutputParams() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE PROC #error_proc @p1 int out AS \r\n" +
                     "RAISERROR ('TEST EXCEPTION', 15, 1)\r\n" +
                     "SELECT @P1=100\r\n" +
                     "CREATE TABLE #DUMMY (id int)\r\n" +
                     "INSERT INTO #DUMMY VALUES(1)\r\n"+
                     "INSERT INTO #DUMMY VALUES(1)");
        stmt.close();

        CallableStatement cstmt = con.prepareCall("{call #error_proc(?)}");
        cstmt.registerOutParameter(1, Types.INTEGER);
        try {
            cstmt.execute();
            fail("Expecting exception");
        } catch (SQLException e) {
            assertEquals("TEST EXCEPTION", e.getMessage());
        }
        assertEquals(100, cstmt.getInt(1));
        cstmt.close();
    }

    /**
     * Test for bug [1236078] Procedure doesn't get called for some BigDecimal
     * values - invalid bug.
     */
    public void testBigDecimal() throws Exception {
        Statement stmt = con.createStatement();
        assertEquals(0, stmt.executeUpdate("CREATE TABLE #dec_test "
                + "(ColumnVC varchar(50) NULL, ColumnDec decimal(18,4) NULL)"));
        assertEquals(0, stmt.executeUpdate("CREATE PROCEDURE #dec_test2"
                + "(@inVc varchar(32), @inBd decimal(18,4)) AS "
                + "begin "
                + "update #dec_test set columnvc = @inVc, columndec = @inBd "
                + "end"));
        assertEquals(1, stmt.executeUpdate(
                "insert #dec_test (columnvc, columndec) values (null, null)"));
        stmt.close();

        CallableStatement cstmt = con.prepareCall("{call #dec_test2 (?,?)}");
        cstmt.setString(1, "D: " + new java.util.Date());
        cstmt.setBigDecimal(2, new BigDecimal("2.9E+7"));
        assertEquals(1, cstmt.executeUpdate());
        cstmt.close();
    }

    /**
     * Test that output result sets, return values and output parameters are
     * correctly handled for a remote procedure call.
     * To set up this test you will a local and remote server where the remote
     * server allows logins from the local test server.
     * Install the following stored procedure on the remote server:
     *
     * create proc jtds_remote @in varchar(16), @out varchar(32) output as
     * begin
     *   select 'result set'
     *   set @out = 'Test ' + @in;
     *   return 1
     * end
     *
     * Uncomment this test and amend the remoteserver name in the prepareCall
     * statement below to be the actual name of your remote server.
     *
     * The TDS stream for this test will comprise a result set, a dummy return
     * (0x79) value and then the actual return and output parameter (0xAC) records.
     *
     * This call will fail with jtds 1.1 as the dummy return value of 0 in the
     * TDS stream will preempt the capture of the actual value 1. In addition the
     * return value will be assigned to the output parameter and the actual output
     * parameter value will be lost.
     *
     *
    public void testRemoteCallWithResultSet() throws Exception {
        CallableStatement cstmt = con.prepareCall(
                "{?=call remoteserver.database.user.jtds_remote(?,?)}");
        cstmt.registerOutParameter(1, Types.INTEGER);
        cstmt.setString(2, "data");
        cstmt.registerOutParameter(3, Types.VARCHAR);
        cstmt.execute();
        ResultSet rs = cstmt.getResultSet();
        assertNotNull(rs);
        assertTrue(rs.next());
        assertEquals("result set", rs.getString(1));
        assertFalse(rs.next());
        rs.close();
        assertEquals(1, cstmt.getInt(1));
        assertEquals("Test data", cstmt.getString(3));
        cstmt.close();
    }
    */

    public static void main(String[] args) {
        junit.textui.TestRunner.run(CallableStatementTest.class);
    }
}