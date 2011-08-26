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
import net.sourceforge.jtds.jdbc.DefaultProperties;
import net.sourceforge.jtds.jdbc.Messages;
import net.sourceforge.jtds.jdbc.Driver;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;
import java.sql.Types;

/**
 * Test case to illustrate use of TDS 8 support
 *
 * @version 1.0
 */
public class Tds8Test extends DatabaseTestCase {

    public static Test suite() {

        if (!DefaultProperties.TDS_VERSION_80.equals(
                props.getProperty(Messages.get(Driver.TDS)))) {

            return new TestSuite();
        }

        return new TestSuite(Tds8Test.class);
    }

    public Tds8Test(String name) {
        super(name);
    }

    public void testBigInt1() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #bigint1 (num bigint, txt varchar(100))");
        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #bigint1 (num, txt) VALUES (?, ?)");
        pstmt.setLong(1, 1234567890123L);
        pstmt.setString(2, "1234567890123");
        assertEquals("Insert bigint failed", 1, pstmt.executeUpdate());
        ResultSet rs = stmt.executeQuery("SELECT * FROM #bigint1");
        assertNotNull(rs);
        assertTrue(rs.next());
        assertEquals(String.valueOf(rs.getLong(1)), rs.getString(2));
        stmt.close();
        pstmt.close();
    }

    /**
     * Test BIGINT data type.
     * Test for [989963] BigInt becomes Numeric
     */
    public void testBigInt2() throws Exception {
        long data = 1;

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #bigint2 (data BIGINT, minval BIGINT, maxval BIGINT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #bigint2 (data, minval, maxval) VALUES (?, ?, ?)");

        pstmt.setLong(1, data);
        pstmt.setLong(2, Long.MIN_VALUE);
        pstmt.setLong(3, Long.MAX_VALUE);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data, minval, maxval FROM #bigint2");

        assertTrue(rs.next());

        assertTrue(rs.getBoolean(1));
        assertTrue(rs.getByte(1) == 1);
        assertTrue(rs.getShort(1) == 1);
        assertTrue(rs.getInt(1) == 1);
        assertTrue(rs.getLong(1) == 1);
        assertTrue(rs.getFloat(1) == 1);
        assertTrue(rs.getDouble(1) == 1);
        assertTrue(rs.getBigDecimal(1).longValue() == 1);
        assertEquals(rs.getString(1), "1");

        Object tmpData = rs.getObject(1);

        assertTrue(tmpData instanceof Long);
        assertTrue(data == ((Long) tmpData).longValue());

        ResultSetMetaData resultSetMetaData = rs.getMetaData();

        assertNotNull(resultSetMetaData);
        assertEquals(resultSetMetaData.getColumnType(1), Types.BIGINT);

        assertEquals(rs.getLong(2), Long.MIN_VALUE);
        assertEquals(rs.getLong(3), Long.MAX_VALUE);

        assertTrue(!rs.next());
        stmt2.close();
        rs.close();
    }

    public void testSqlVariant() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #VARTEST (id int, data sql_variant)");
        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #VARTEST (id, data) VALUES (?, ?)");

        pstmt.setInt(1, 1);
        pstmt.setString(2, "TEST STRING");
        assertEquals("Insert 1 failed", pstmt.executeUpdate(), 1);
        pstmt.setInt(1, 2);
        pstmt.setInt(2, 255);
        assertEquals("Insert 2 failed", pstmt.executeUpdate(), 1);
        pstmt.setInt(1, 3);
        pstmt.setBigDecimal(2, new BigDecimal("10.23"));
        assertEquals("Insert 3 failed", pstmt.executeUpdate(), 1);
        pstmt.setInt(1, 4);
        byte bytes[] = {'X', 'X', 'X'};
        pstmt.setBytes(2, bytes);
        assertEquals("Insert 4 failed", pstmt.executeUpdate(), 1);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #VARTEST ORDER BY id");
        assertNotNull(rs);
        assertTrue(rs.next());
        assertEquals("TEST STRING", rs.getString(2));
        assertTrue(rs.next());
        assertEquals(255, rs.getInt(2));
        assertTrue(rs.next());
        assertEquals("java.math.BigDecimal", rs.getObject(2).getClass().getName());
        assertEquals("10.23", rs.getString(2));
        assertTrue(rs.next());
        assertEquals("585858", rs.getString(2));
        stmt.close();
        pstmt.close();
    }

    public void testUserFn() throws Exception {
        dropFunction("f_varret");
        Statement stmt = con.createStatement();
        stmt.execute(
                "CREATE FUNCTION f_varret(@data varchar(100)) RETURNS sql_variant AS\r\n" +
                "BEGIN\r\n" +
                "RETURN 'Test ' + @data\r\n" +
                "END");
        stmt.close();
        CallableStatement cstmt = con.prepareCall("{?=call f_varret(?)}");
        cstmt.registerOutParameter(1, java.sql.Types.OTHER);
        cstmt.setString(2, "String");
        cstmt.execute();
        assertEquals("Test String", cstmt.getString(1));
        cstmt.close();
        dropFunction("f_varret");
    }

    public void testMetaData() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create table #testrsmd (id int, data varchar(10), num decimal(10,2))");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("select * from #testrsmd where id = ?");
        ResultSetMetaData rsmd = pstmt.getMetaData();
        assertNotNull(rsmd);
        assertEquals(3, rsmd.getColumnCount());
        assertEquals("data", rsmd.getColumnName(2));
        assertEquals(2, rsmd.getScale(3));
        pstmt.close();
    }

    /**
     * Test for bug [1042272] jTDS doesn't allow null value into Boolean.
     */
    public void testNullBoolean() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create table #testNullBoolean (id int, value bit)");

        PreparedStatement pstmt = con.prepareStatement(
                "insert into #testNullBoolean (id, value) values (?, ?)");
        pstmt.setInt(1, 1);
        pstmt.setNull(2, 16 /* Types.BOOLEAN */);
        assertEquals(1, pstmt.executeUpdate());
        pstmt.close();

        ResultSet rs = stmt.executeQuery("select * from #testNullBoolean");
        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));
        assertEquals(null, rs.getObject(2));
        assertFalse(rs.next());
        rs.close();
        stmt.close();
    }

    /**
     * Test column collations.
     */
    public void testColumnCollations() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("create table #testColumnCollations (id int primary key, "
                + "cp437val varchar(255) collate SQL_Latin1_General_Cp437_CI_AS, "
                + "cp850val varchar(255) collate SQL_Latin1_General_Cp850_CI_AS, "
                + "ms874val varchar(255) collate Thai_CI_AS, "
                + "ms932val varchar(255) collate Japanese_CI_AS, "
                + "ms936val varchar(255) collate Chinese_PRC_CI_AS, "
                + "ms949val varchar(255) collate Korean_Wansung_CI_AS, "
                + "ms950val varchar(255) collate Chinese_Taiwan_Stroke_CI_AS, "
                + "cp1250val varchar(255) collate SQL_Romanian_Cp1250_CI_AS, "
                + "cp1252val varchar(255) collate SQL_Latin1_General_Cp1_CI_AS)");

        ResultSet rs = stmt.executeQuery("select * from #testColumnCollations");
        assertFalse(rs.next());
        rs.close();

        PreparedStatement pstmt = con.prepareStatement(
                "insert into #testColumnCollations "
                + "(id, cp437val, cp850val, ms874val, ms932val, "
                + "ms936val, ms949val, ms950val, cp1250val, cp1252val) "
                + "values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

        // Test inserting and retrieving pure-ASCII values
        pstmt.setInt(1, 1);
        for (int i = 2; i <= 10; i++) {
            pstmt.setString(i, "test");
        }
        assertEquals(1, pstmt.executeUpdate());

        rs = stmt.executeQuery("select * from #testColumnCollations");
        assertTrue(rs.next());
        for (int i = 2; i <= 10; i++) {
            assertEquals("test", rs.getString(i));
        }
        assertFalse(rs.next());
        rs.close();
        assertEquals(1, stmt.executeUpdate("delete from #testColumnCollations"));

        // Test inserting and retrieving charset-specific values via PreparedStatement
        String[] values = {
            "123abc\u2591\u2592\u2593\u221a\u221e\u03b1",
            "123abc\u00d5\u00f5\u2017\u00a5\u2591\u2592",
            "123abc\u20ac\u2018\u2019\u0e10\u0e1e\u0e3a",
            "123abc\uff67\uff68\uff9e\u60c6\u7210\ufa27",
            "123abc\u6325\u8140\u79a9\u9f1e\u9f32\ufa29",
            "123abc\uac4e\ub009\ubcde\u00de\u24d0\u30e5",
            "123abc\ufe4f\u00d7\uff5e\u515e\u65b0\u7881",
            "123abc\u20ac\u201a\u0103\u015e\u0162\u00f7",
            "123abc\u20ac\u201e\u017d\u00fe\u02dc\u00b8"
        };
        for (int i = 2; i <= 10; i++) {
            pstmt.setString(i, values[i - 2]);
        }
        assertEquals(1, pstmt.executeUpdate());
        pstmt.close();

        rs = stmt.executeQuery("select * from #testColumnCollations");
        assertTrue(rs.next());
        for (int i = 2; i <= 10; i++) {
            assertEquals("Column " + i + " doesn't match", values[i - 2], rs.getString(i));
        }
        assertFalse(rs.next());
        rs.close();
        pstmt.close();
        stmt.close();

        // Test inserting and retrieving charset-specific values via updateable ResultSet
        stmt = con.createStatement(
                ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        rs = stmt.executeQuery("select * from #testColumnCollations");
        assertTrue(rs.next());
        for (int i = 2; i <= 10; i++) {
            rs.updateString(i, rs.getString(i) + "updated");
            values[i - 2] = values[i - 2] + "updated";
        }
        rs.updateRow();
        for (int i = 2; i <= 10; i++) {
            assertEquals("Column " + i + " doesn't match", values[i - 2], rs.getString(i));
        }
        assertFalse(rs.next());
        rs.close();
        stmt.close();
    }

    /**
     * Test for bug [981958] PreparedStatement doesn't work correctly
     */
    public void testEncoding1251Test1() throws Exception {
        String value = "\u0441\u043b\u043e\u0432\u043e"; // String in Cp1251 encoding
        Statement stmt = con.createStatement();

        stmt.execute("CREATE TABLE #e1251t1 (data varchar(255) COLLATE Cyrillic_General_BIN)");
        assertEquals(stmt.executeUpdate("INSERT INTO #e1251t1 (data) VALUES (N'" + value + "')"), 1);
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("SELECT data FROM #e1251t1 WHERE data = ?");
        pstmt.setString(1, value);
        ResultSet rs = pstmt.executeQuery();

        assertTrue(rs.next());
        //assertEquals(value, rs.getString(1));
        assertTrue(!rs.next());
        pstmt.close();
        rs.close();
    }

    /**
     * Test for enhanced database metadata for SQL 2005.
     * E.g. distinguish between varchar(max) and text.
     * @throws Exception
     */
    public void testSQL2005MetaData() throws Exception
    {
        Statement stmt = con.createStatement();
        int dbVer = Integer.parseInt(con.getMetaData()
                    .getDatabaseProductVersion().
                    substring(0,2));
        if (dbVer <= 8) {
            // Not SQL 2005
            return;
        }
        stmt.execute("CREATE TABLE #test (" +
                    "id int primary key, " +
                    "txt text, ntxt ntext, img image, " +
                    "vc varchar(max), nvc nvarchar(max), vb varbinary(max))");
        ResultSet rs = con.getMetaData().getColumns("tempdb", null, "#test", "%");
        assertNotNull(rs);
        assertTrue(rs.next());
        // Skip int col
        assertTrue(rs.next());
        // Should be text
        assertEquals("text", rs.getString("TYPE_NAME"));
        assertTrue(rs.next());
        // Should be ntext
        assertEquals("ntext", rs.getString("TYPE_NAME"));
        assertTrue(rs.next());
        // Should be image
        assertEquals("image", rs.getString("TYPE_NAME"));
        assertTrue(rs.next());
        // Should be varchar(max)
        assertEquals("varchar", rs.getString("TYPE_NAME"));
        assertTrue(rs.next());
        // Should be nvarchar(max)
        assertEquals("nvarchar", rs.getString("TYPE_NAME"));
        assertTrue(rs.next());
        // Should be varbinary(max)
        assertEquals("varbinary", rs.getString("TYPE_NAME"));
        stmt.close();
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(Tds8Test.class);
    }
}
