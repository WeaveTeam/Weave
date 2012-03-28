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

import junit.framework.Test;
import junit.framework.TestSuite;

import java.sql.*;
import java.math.BigDecimal;



/**
 * Test case to illustrate errors reported by SUN JBDC compatibility test suite.
 *
 * @version 1.0
 */
public class SunTest extends DatabaseTestCase {
    public static Test suite() {
        return new TestSuite(SunTest.class);
    }

    public SunTest(String name) {
        super(name);
    }

    /**
     * Test for SUN bug [ PrepStmt1.getMetaData() ]
     * Driver loops if select contains commas.
     *
     * @throws Exception
     */
    public void testGetMetaData() throws Exception {
        PreparedStatement pstmt = con.prepareStatement("SELECT name, id, type FROM sysobjects WHERE type = 'U'");
        ResultSetMetaData rsmd = pstmt.getMetaData();
        assertEquals("name", rsmd.getColumnName(1));
        pstmt.close();
    }

    /**
     * Generic Tests for SUN bugs such as
     * <ol>
     * <li>Can't convert  VARCHAR to Timestamp
     * <li>Can't convert  VARCHAR to Time
     * <li>Can't convert  VARCHAR to Date
     * <li>Internal time representation causes equals to fail
     * </ol>
     * @throws Exception
     */
    public void testDateTime() throws Exception {
        final String dateStr = "1983-01-31";
        final String timeStr = "12:59:59";
        final String tsStr   = "1983-01-31 23:59:59.333";

        Statement stmt = con.createStatement();
        stmt.execute("CREATE PROC #CTOT_PROC @tdate DATETIME OUTPUT, @ttime DATETIME OUTPUT, @tts DATETIME OUTPUT AS " +
                     "BEGIN SELECT @tdate=tdate, @ttime=ttime, @tts=tts FROM #CTOT END");
        stmt.execute("CREATE TABLE #CTOT (tdate DATETIME, ttime DATETIME, tts DATETIME, tnull DATETIME NULL)");
        stmt.close();
        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #CTOT (tdate, ttime, tts) VALUES(?,?,?)");
        pstmt.setObject(1, dateStr, java.sql.Types.DATE);
        pstmt.setObject(2, timeStr, java.sql.Types.TIME);
        pstmt.setObject(3, tsStr, java.sql.Types.TIMESTAMP);
        pstmt.execute();
        assertEquals(1, pstmt.getUpdateCount());
        pstmt.close();
        CallableStatement cstmt = con.prepareCall("{call #CTOT_PROC(?,?,?)}");
        cstmt.registerOutParameter(1, java.sql.Types.DATE);
        cstmt.registerOutParameter(2, java.sql.Types.TIME);
        cstmt.registerOutParameter(3, java.sql.Types.TIMESTAMP);
        cstmt.execute();
        assertEquals(dateStr, cstmt.getString(1));
        assertEquals(timeStr, cstmt.getString(2));
        assertEquals(java.sql.Time.valueOf(timeStr), cstmt.getTime(2));
        assertEquals(tsStr,   cstmt.getString(3));
        cstmt.close();
        stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT * FROM #CTOT");
        assertTrue(rs.next());
        java.sql.Time retval = rs.getTime(2);
        java.sql.Time tstval = java.sql.Time.valueOf(timeStr);
        assertEquals(tstval, retval);
        stmt.close();
        pstmt = con.prepareStatement("UPDATE #CTOT SET tnull = ?");
        pstmt.setTime(1, tstval);
        pstmt.execute();
        assertEquals(1, pstmt.getUpdateCount());
        pstmt.close();
        stmt = con.createStatement();
        rs = stmt.executeQuery("SELECT * FROM #CTOT");
        assertTrue(rs.next());
        retval = rs.getTime(4);
        assertEquals(tstval, retval);
        stmt.close();
    }

    /**
     * Generic test for errors caused by promotion out parameters of Float to Double by driver.
     * eg [ callStmt4.testGetObject34 ] Class cast exception Float.
     *
     * @throws Exception
     */
    public void testCharToReal() throws Exception {
        final String minStr = "3.4E38";
        final String maxStr = "1.18E-38";

        Statement stmt = con.createStatement();
        stmt.execute("CREATE PROC #CTOR_PROC @minval REAL OUTPUT, @maxval REAL OUTPUT AS " +
                     "BEGIN SELECT @minval=min_val, @maxval=max_val FROM #CTOR END");
        stmt.execute("CREATE TABLE #CTOR (min_val REAL, max_val REAL)");
        stmt.execute("INSERT INTO #CTOR VALUES(" + minStr +"," + maxStr + ")");
        assertEquals(1, stmt.getUpdateCount());
        ResultSet rs = stmt.executeQuery("SELECT * FROM #CTOR");
        assertNotNull(rs);
        assertTrue(rs.next());
        assertEquals(minStr, rs.getString(1));
        assertEquals(maxStr, rs.getString(2));
        assertTrue(rs.getObject(1) instanceof Float);
        stmt.close();
        CallableStatement cstmt = con.prepareCall("{call #CTOR_PROC(?,?)}");
        cstmt.registerOutParameter(1, java.sql.Types.REAL);
        cstmt.registerOutParameter(2, java.sql.Types.REAL);
        cstmt.execute();
        assertEquals(minStr, cstmt.getString(1));
        assertEquals(maxStr, cstmt.getString(2));
        cstmt.close();
    }

    /**
     * Generic test for SUN bugs: bigint null parameter values sent as integer size.
     *
     * @throws Exception
     */
    public void testCharToLong() throws Exception {
        final String minStr = "9223372036854775807";
        final String maxStr = "-9223372036854775808";

        Statement stmt = con.createStatement();
        stmt.execute("CREATE PROC #CTOL_PROC @minval BIGINT OUTPUT, @maxval BIGINT OUTPUT AS " +
                     "BEGIN SELECT @minval=min_val, @maxval=max_val FROM #CTOL END");
        stmt.execute("CREATE TABLE #CTOL (min_val BIGINT, max_val BIGINT)");
        stmt.execute("INSERT INTO #CTOL VALUES(" + minStr +"," + maxStr + ")");
        assertEquals(1, stmt.getUpdateCount());
        ResultSet rs = stmt.executeQuery("SELECT * FROM #CTOL");
        assertNotNull(rs);
        assertTrue(rs.next());
        assertEquals(minStr, rs.getString(1));
        assertEquals(maxStr, rs.getString(2));
        stmt.close();
        CallableStatement cstmt = con.prepareCall("{call #CTOL_PROC(?,?)}");
        cstmt.registerOutParameter(1, java.sql.Types.BIGINT);
        cstmt.registerOutParameter(2, java.sql.Types.BIGINT);
        cstmt.execute();
        assertEquals(minStr, cstmt.getString(1));
        assertEquals(maxStr, cstmt.getString(2));
        cstmt.close();
    }

    /**
     * Test for SUN bug [ dbMeta8.testGetProcedures ]
     * The wrong column names are returned by getProcedures().
     *
     * @throws Exception
     */
    public void testGetProcedures() throws Exception {
        String names[] = {"PROCEDURE_CAT","PROCEDURE_SCHEM","PROCEDURE_NAME","","","","REMARKS","PROCEDURE_TYPE"};
        DatabaseMetaData dbmd = con.getMetaData();
        ResultSet rs = dbmd.getProcedures(null, null, "%");
        ResultSetMetaData rsmd = rs.getMetaData();

        for (int i = 0; i < names.length; i++) {
            if (names[i].length() > 0) {
                assertEquals(names[i], rsmd.getColumnName(i+1));
            }
        }

        rs.close();
    }

    /**
     * Generic test for SUN bug where Float was promoted to Double
     * by driver leading to ClassCastExceptions in the tests.
     * Example [ prepStmt4.testSetObject16 ]
     *
     * @throws Exception
     */
    public void testGetFloatObject() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #GETF (val REAL)");
        stmt.execute("INSERT INTO #GETF (val) VALUES (1.7E10)");
        assertEquals(1,stmt.getUpdateCount());
        ResultSet rs = stmt.executeQuery("SELECT * FROM #GETF");
        assertTrue(rs.next());
        assertTrue(rs.getObject(1) instanceof Float);
        rs.close();
        stmt.close();
    }

    /**
     * Test for SUN bug [ resultSet1.testSetFetchSize02 ]
     * attempt to set non zero fetch size rejected.
     *
     * @throws Exception
     */
    public void testSetFetchSize() throws Exception {
        CallableStatement cstmt = con.prepareCall("{call sp_who}");
        ResultSet rs = cstmt.executeQuery();
        rs.setFetchSize(5);
        assertEquals(5, rs.getFetchSize());
        rs.close();
        cstmt.close();
    }

    /**
     * Test for SUN bug [ stmt2.testSetFetchDirection04 ]
     * fetch direction constant not validated.
     *
     * @throws Exception
     */
    public void testSetFetchDirectiion() throws Exception {
        Statement stmt = con.createStatement();

        try {
            stmt.setFetchDirection(-1);
            fail("setFecthDirection does not validate parameter");
        } catch (SQLException sqe) {
        }

        stmt.close();
    }

    /**
     * Test for bug [ 1012307 ] PreparedStatement.setObject(java.util.Date) not working.
     * The driver should throw an exception if the object is not of a valid
     * type according to table
     *
     * @throws Exception
     */
    public void testSetDateObject() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #SETD (val DATETIME)");
        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #SETD (val) VALUES (?)");
        long tval = 60907507200000L; //1999-12-31

        try {
            pstmt.setObject(1, new java.util.Date(tval));
            fail("No exception for setObject(java.util.Date)");
        } catch (SQLException e) {
            // OK unsupported object type trapped
        }

        pstmt.close();
        stmt.close();
    }

    /**
     * Test for bug [ 1012301 ] 0.9-rc1: Prepared statement execution error.
     *
     * @throws Exception
     */
    public void testPrepStmtError() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #PERR (val VARCHAR(255))\r\n" +
                     "INSERT INTO #PERR (val) VALUES('Test String')");
        PreparedStatement pstmt = con.prepareStatement(" SELECT * FROM #PERR WHERE val = ?");
        pstmt.setString(1,"Test String");
        assertTrue(pstmt.execute());
        ResultSet rs = pstmt.getResultSet();
        assertTrue(rs.next());
        rs.close();
        pstmt.close();
        stmt.close();
    }

    /**
     * Test for bug [ 1011650 ] 0.9-rc1: comments get parsed
     *
     * @throws Exception
     */
    public void testSqlComments() throws Exception {
        String testSql = "/* This is a test of the comment {fn test()} parser */\r\n" +
                         "SELECT * FROM XXXX -- In line comment {d 1999-01-01}\r\n"+
                         "INSERT INTO B VALUES({d 1999-01-01}) -- Unterminated in line comment";
        String outSql = "/* This is a test of the comment {fn test()} parser */\r\n" +
                         "SELECT * FROM XXXX -- In line comment {d 1999-01-01}\r\n"+
                         "INSERT INTO B VALUES('19990101') -- Unterminated in line comment";
        assertEquals(outSql, con.nativeSQL(testSql));
    }

    /**
     * Test for bug [ 1008126 ] Metadata getTimeDateFunctions() wrong
     *
     * @throws Exception
     */
    public void testDateTimeFn() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #DTFN (ttime SMALLDATETIME, tdate SMALLDATETIME, ftime SMALLDATETIME, fdate SMALLDATETIME, tnow DATETIME)");
        stmt.execute("INSERT INTO #DTFN (ttime, tdate, ftime, fdate, tnow) VALUES (getdate(), getdate(), {fn curtime()}, {fn curdate()}, {fn now()})");
        assertEquals(1, stmt.getUpdateCount());
        ResultSet rs = stmt.executeQuery("SELECT * FROM #DTFN");
        assertTrue(rs.next());
        assertEquals("curdate()",rs.getDate(2),rs.getDate(4));
        assertEquals("curtime()",rs.getTime(1),rs.getTime(3));
        assertEquals("now()",rs.getDate(1),rs.getDate(5));
        rs = stmt.executeQuery("SELECT {fn dayname('2004-08-21')}, " +
                                       "{fn dayofmonth('2004-08-21')}, " +
                                       "{fn dayofweek('2004-08-21')}," +
                                       "{fn dayofyear('2004-08-21')}," +
                                       "{fn hour('23:47:32')}," +
                                       "{fn minute('23:47:32')}," +
                                       "{fn second('23:47:32')}," +
                                       "{fn year('2004-08-21')}," +
                                       "{fn quarter('2004-08-21')}," +
                                       "{fn month('2004-08-21')}," +
                                       "{fn week('2004-08-21')}," +
                                       "{fn monthname('2004-08-21')}," +
                                       "{fn timestampdiff(SQL_TSI_DAY, '2004-08-19','2004-08-21')}," +
                                       "{fn timestampadd(SQL_TSI_MONTH, 1, '2004-08-21')}" +
                                       "");
        assertTrue(rs.next());
        assertEquals("dayname", "Saturday", rs.getString(1));
        assertEquals("dayofmonth", 21, rs.getInt(2));
        assertEquals("dayofweek", 7, rs.getInt(3));
        assertEquals("dayofyear", 234, rs.getInt(4));
        assertEquals("hour", 23, rs.getInt(5));
        assertEquals("minute", 47, rs.getInt(6));
        assertEquals("second", 32, rs.getInt(7));
        assertEquals("year", 2004, rs.getInt(8));
        assertEquals("quarter", 3, rs.getInt(9));
        assertEquals("month", 8, rs.getInt(10));
        assertEquals("week", 34, rs.getInt(11));
        assertEquals("monthname", "August", rs.getString(12));
        assertEquals("timestampdiff", 2, rs.getInt(13));
        assertEquals("timestampadd", java.sql.Date.valueOf("2004-09-21"), rs.getDate(14));
        stmt.close();
    }

    /**
     * Test for scalar string functions.
     *
     * @throws Exception
     */
    public void testStringFn() throws Exception {
        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT {fn ascii('X')}, "+
                                                "{fn char(88)}," +
                                                "{fn concat('X','B')}," +
                                                "{fn difference('X','B')}," +
                                                "{fn insert('XXX',2,1, 'Y')}," +
                                                "{fn lcase('XXX')}," +
                                                "{fn length('XXX')}," +
                                                "{fn ltrim(' XXX')}," +
                                                "{fn repeat('X', 3)}," +
                                                "{fn replace('XXXYYYXXX', 'YYY', 'FRED')}," +
                                                "{fn right('XXX', 1)}," +
                                                "{fn rtrim('XXX ')}, " +
                                                "{fn soundex('FRED')}," +
                                                "'X' + {fn space(1)} + 'X'," +
                                                "{fn substring('FRED', 2, 1)}," +
                                                "{fn ucase('xxx')}," +
                                                "{fn locate('fred', 'xxxfredyyy')}," +
                                                "{fn left('FRED', 1)}" +
                                                "");
        assertTrue(rs.next());
        assertEquals("ascii", 88, rs.getInt(1));
        assertEquals("char", "X", rs.getString(2));
        assertEquals("concat", "XB", rs.getString(3));
        assertEquals("difference", 3, rs.getInt(4));
        assertEquals("insert", "XYX", rs.getString(5));
        assertEquals("lcase", "xxx", rs.getString(6));
        assertEquals("insert", 3, rs.getInt(7));
        assertEquals("ltrim", "XXX", rs.getString(8));
        assertEquals("repeat", "XXX", rs.getString(9));
        assertEquals("replace", "XXXFREDXXX", rs.getString(10));
        assertEquals("right", "X", rs.getString(11));
        assertEquals("rtrim", "XXX", rs.getString(12));
        assertEquals("soundex", "F630", rs.getString(13));
        assertEquals("space", "X X", rs.getString(14));
        assertEquals("substring", "R", rs.getString(15));
        assertEquals("ucase", "XXX", rs.getString(16));
        assertEquals("locate", 4, rs.getInt(17));
        assertEquals("left", "F", rs.getString(18));

        stmt.close();
    }

    /**
     * Test nested escapes
     *
     * @throws Exception
     */
    public void testNestedEscapes() throws Exception {
        String sql = "SELECT {fn convert({fn month({fn now()})},varchar)} WHERE X";
        assertEquals("SELECT convert(varchar,datepart(month,getdate())) WHERE X", con.nativeSQL(sql));
        sql = "{?=call testproc(?, {fn now()})}";
        assertEquals("EXECUTE testproc ?,getdate()", con.nativeSQL(sql));
        sql = "SELECT * FROM {oj t1 LEFT OUTER JOIN {oj t2 LEFT OUTER JOIN t2 ON condition1} ON condition2}";
        assertEquals("SELECT * FROM t1 LEFT OUTER JOIN t2 LEFT OUTER JOIN t2 ON condition1 ON condition2", con.nativeSQL(sql));
    }

    /**
     * Test conversion of various types to LONGVARCHAR. This functionality was
     * broken in 0.9 because changes were made to handle LONGVARCHAR internally
     * as Clob rather than String (but these did not take into consideration
     * all possible cases.
     *
     * @throws SQLException
     */
    public void testConversionToLongvarchar() throws SQLException {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #testConversionToLongvarchar ("
                + " id INT,"
                + " val NTEXT)");

        int id = 0;
        String decimalValue = "1234.5678";
        String booleanValue = "true";
        String integerValue = "1234567";
        String longValue = "1234567890123";
        Date dateValue = new Date(System.currentTimeMillis());
        Time timeValue = new Time(System.currentTimeMillis());
        Timestamp timestampValue = new Timestamp(System.currentTimeMillis());

        PreparedStatement pstmt = con.prepareStatement(
                "INSERT INTO #testConversionToLongvarchar (id, val) VALUES (?, ?)");

        // Test BigDecimal to LONGVARCHAR conversion
        pstmt.setInt(1, ++id);
        pstmt.setObject(2, new BigDecimal(decimalValue), java.sql.Types.LONGVARCHAR);
        pstmt.executeUpdate();

        // Test Boolean to LONGVARCHAR conversion
        pstmt.setInt(1, ++id);
        pstmt.setObject(2, new Boolean(booleanValue), java.sql.Types.LONGVARCHAR);
        pstmt.executeUpdate();

        // Test Integer to LONGVARCHAR conversion
        pstmt.setInt(1, ++id);
        pstmt.setObject(2, new Integer(integerValue), java.sql.Types.LONGVARCHAR);
        pstmt.executeUpdate();

        // Test Long to LONGVARCHAR conversion
        pstmt.setInt(1, ++id);
        pstmt.setObject(2, new Long(longValue), java.sql.Types.LONGVARCHAR);
        pstmt.executeUpdate();

        // Test Float to LONGVARCHAR conversion
        pstmt.setInt(1, ++id);
        pstmt.setObject(2, new Float(integerValue), java.sql.Types.LONGVARCHAR);
        pstmt.executeUpdate();

        // Test Double to LONGVARCHAR conversion
        pstmt.setInt(1, ++id);
        pstmt.setObject(2, new Double(longValue), java.sql.Types.LONGVARCHAR);
        pstmt.executeUpdate();

        // Test Date to LONGVARCHAR conversion
        pstmt.setInt(1, ++id);
        pstmt.setObject(2, dateValue, java.sql.Types.LONGVARCHAR);
        pstmt.executeUpdate();

        // Test Time to LONGVARCHAR conversion
        pstmt.setInt(1, ++id);
        pstmt.setObject(2, timeValue, java.sql.Types.LONGVARCHAR);
        pstmt.executeUpdate();

        // Test Timestamp to LONGVARCHAR conversion
        pstmt.setInt(1, id);
        pstmt.setObject(2, timestampValue, java.sql.Types.LONGVARCHAR);
        pstmt.executeUpdate();
        pstmt.close();

        ResultSet rs = stmt.executeQuery(
                "SELECT * FROM #testConversionToLongvarchar ORDER BY id");
        assertTrue(rs.next());
        assertEquals(decimalValue, rs.getString("val"));
        assertTrue(rs.next());
        assertEquals("1", rs.getString("val"));
        assertTrue(rs.next());
        assertEquals(integerValue, rs.getString("val"));
        assertTrue(rs.next());
        assertEquals(longValue, rs.getString("val"));
        assertTrue(rs.next());
        assertEquals(Float.parseFloat(integerValue), Float.parseFloat(rs.getString("val")), 0);
        assertTrue(rs.next());
        assertEquals(Double.parseDouble(longValue), Double.parseDouble(rs.getString("val")), 0);
        assertTrue(rs.next());
        assertEquals(dateValue.toString(), rs.getString("val"));
        assertTrue(rs.next());
        assertEquals(timeValue.toString(), rs.getString("val"));
        assertTrue(rs.next());
        assertEquals(timestampValue.toString(), rs.getString("val"));

        rs.close();
        stmt.close();
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(SunTest.class);
    }
}
