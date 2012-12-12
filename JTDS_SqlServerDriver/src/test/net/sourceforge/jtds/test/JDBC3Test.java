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

import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ParameterMetaData;
import java.sql.Types;
import java.math.BigDecimal;

/**
 * Test for miscellaneous JDBC 3.0 features.
 *
 * @author Alin Sinpalean
 * @version $Id: JDBC3Test.java,v 1.3.2.1 2009-08-04 10:33:54 ickzon Exp $
 */
public class JDBC3Test extends TestBase {
    public JDBC3Test(String name) {
        super(name);
    }

    /**
     * Test return of multiple open result sets from one execute.
     */
    public void testMultipleResults() throws Exception {
        Statement stmt = con.createStatement(
                ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
        //
        // Create 4 test tables
        //
        for (int rs = 1; rs <= 4; rs++) {
            stmt.execute("CREATE TABLE #TESTRS" + rs + " (id int, data varchar(255))");
            for (int row = 1; row <= 10; row++) {
                assertEquals(1, stmt.executeUpdate("INSERT INTO #TESTRS" + rs +
                        " VALUES(" + row + ", 'TABLE " + rs + " ROW " + row + "')"));
            }
        }

        assertTrue(stmt.execute(
                "SELECT * FROM #TESTRS1\r\n" +
                "SELECT * FROM #TESTRS2\r\n" +
                "SELECT * FROM #TESTRS3\r\n" +
                "SELECT * FROM #TESTRS4\r\n"));
        ResultSet rs = stmt.getResultSet();
        assertTrue(rs.next());
        assertEquals("TABLE 1 ROW 1", rs.getString(2));
        // Get RS 2 keeping RS 1 open
        assertTrue(stmt.getMoreResults(Statement.KEEP_CURRENT_RESULT));
        ResultSet rs2 = stmt.getResultSet();
        assertTrue(rs2.next());
        assertEquals("TABLE 2 ROW 1", rs2.getString(2));
        // Check RS 1 still open and on row 1
        assertEquals("TABLE 1 ROW 1", rs.getString(2));
        // Read a cached row from RS 1
        assertTrue(rs.next());
        assertEquals("TABLE 1 ROW 2", rs.getString(2));
        // Close RS 2 but keep RS 1 open and get RS 3
        assertTrue(stmt.getMoreResults(Statement.CLOSE_CURRENT_RESULT));
        ResultSet rs3 = stmt.getResultSet();
        assertTrue(rs3.next());
        assertEquals("TABLE 3 ROW 1", rs3.getString(2));
        // Check RS 2 is closed
        try {
            assertEquals("TABLE 2 ROW 1", rs2.getString(2));
            fail("Expected RS 2 to be closed!");
        } catch (SQLException e) {
            // Ignore
        }
        // Check RS 1 is still open
        assertEquals("TABLE 1 ROW 2", rs.getString(2));
        // Close all result sets and get RS 4
        assertTrue(stmt.getMoreResults(Statement.CLOSE_ALL_RESULTS));
        ResultSet rs4 = stmt.getResultSet();
        assertTrue(rs4.next());
        assertEquals("TABLE 4 ROW 1", rs4.getString(2));
        // check RS 1 is now closed as well
        try {
            assertEquals("TABLE 1 ROW 2", rs.getString(2));
            fail("Expected RS 1 to be closed!");
        } catch (SQLException e) {
            // Ignore
        }
        assertFalse(stmt.getMoreResults());
        stmt.close();
    }

    /**
     * Test closing a <code>ResultSet</code> when it's out of scope.
     * <p/>
     * If a finalize() method which tries to call close() is added to
     * JtdsResultSet the next() calls will be executed concurrently with any
     * other result processing, with no synchronization whatsoever.
     */
    public void testSocketConcurrency5() throws Exception {
        Statement stmt = con.createStatement();
        assertTrue(stmt.execute(
                "SELECT 1 SELECT 2, 3"));
        ResultSet rs = stmt.getResultSet();
        assertTrue(stmt.getMoreResults(Statement.KEEP_CURRENT_RESULT));
        ResultSet rs2 = stmt.getResultSet();

        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));
        assertFalse(rs.next());
        rs.close();

        assertTrue(rs2.next());
        assertEquals(2, rs2.getInt(1));
        assertEquals(3, rs2.getInt(2));
        assertFalse(rs2.next());
        rs2.close();

        stmt.close();
    }

    /**
     * Test for bug [1222205] getParameterMetaData returns not implemented.
     */
    public void testGetParamMetaData() throws SQLException {
        PreparedStatement pstmt = con.prepareStatement("SELECT ?,?,?");
        pstmt.setString(1, "TEST");
        pstmt.setBigDecimal(2, new BigDecimal("123.45"));
        pstmt.setBoolean(3, true);

        ParameterMetaData pmd = pstmt.getParameterMetaData();
        assertEquals(3, pmd.getParameterCount());
        assertEquals(Types.VARCHAR, pmd.getParameterType(1));
        assertEquals("java.lang.String", pmd.getParameterClassName(1));
        assertEquals(2, pmd.getScale(2));
        assertEquals(38, pmd.getPrecision(2));
        assertEquals(ParameterMetaData.parameterModeIn,
                pmd.getParameterMode(3));

        pstmt.close();
    }
}
