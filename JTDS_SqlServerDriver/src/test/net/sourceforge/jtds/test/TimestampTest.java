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

import java.math.BigDecimal;
import java.sql.*;
import java.util.Calendar;
import java.util.TimeZone;
import java.util.GregorianCalendar;

import net.sourceforge.jtds.jdbc.Driver;
import net.sourceforge.jtds.util.Logger;

import junit.framework.TestSuite;

/**
 * test getting timestamps from the database.
 *
 * @author Alin Sinpalean
 * @version $Id: TimestampTest.java,v 1.32.2.5 2009-08-20 19:44:04 ickzon Exp $
 */
public class TimestampTest extends DatabaseTestCase {
    public TimestampTest(String name) {
        super(name);
    }

    public static void main(String args[]) {
        boolean loggerActive = args.length > 0;
        Logger.setActive(loggerActive);

        if (args.length > 0) {
            junit.framework.TestSuite s = new TestSuite();
            for (int i = 0; i < args.length; i++) {
              s.addTest(new TimestampTest(args[i]));
            }
            junit.textui.TestRunner.run(s);
        } else {
            junit.textui.TestRunner.run(TimestampTest.class);
        }

        // new TimestampTest("test").testOutputParams();
    }

    public void testBigint0000() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0000 "
            + "  (i  decimal(28,10) not null, "
            + "   s  char(10) not null) ");

        final int rowsToAdd = 20;
        int count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            String sql = "insert into #t0000 values (" + i + ", 'row" + i + "')";
            count += stmt.executeUpdate(sql);
        }

        stmt.close();
        assertEquals(count, rowsToAdd);

        PreparedStatement pstmt = con.prepareStatement("select i from #t0000 where i = ?");

        pstmt.setLong(1, 7);
        ResultSet rs = pstmt.executeQuery();
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());
        assertEquals(rs.getLong(1), 7);
        assertTrue("Expected no result set", !rs.next());

        pstmt.setLong(1, 8);
        rs = pstmt.executeQuery();
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());
        assertEquals(rs.getLong(1), 8);
        assertTrue("Expected no result set", !rs.next());

        pstmt.close();
    }

    public void testTimestamps0001() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0001             "
                           + "  (t1 datetime not null,       "
                           + "   t2 datetime null,           "
                           + "   t3 smalldatetime not null,  "
                           + "   t4 smalldatetime null)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement(
            "insert into #t0001 values (?, '1998-03-09 15:35:06.4',        "
            + "                         ?, '1998-03-09 15:35:00')");
        Timestamp   t0 = Timestamp.valueOf("1998-03-09 15:35:06.4");
        Timestamp   t1 = Timestamp.valueOf("1998-03-09 15:35:00");

        pstmt.setTimestamp(1, t0);
        pstmt.setTimestamp(2, t1);
        int count = pstmt.executeUpdate();
        assertTrue(count == 1);
        pstmt.close();

        pstmt = con.prepareStatement("select t1, t2, t3, t4 from #t0001");

        ResultSet rs = pstmt.executeQuery();
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());

        assertEquals(t0, rs.getTimestamp(1));
        assertEquals(t0, rs.getTimestamp(2));
        assertEquals(t1, rs.getTimestamp(3));
        assertEquals(t1, rs.getTimestamp(4));

        pstmt.close();
    }

    public void testTimestamps0004() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0004 "
            + "  (mytime  datetime not null, "
            + "   mytime2 datetime null,     "
            + "   mytime3 datetime null     )");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement(
            "insert into #t0004 values ('1964-02-14 10:00:00.0', ?, ?)");

        Timestamp   t0 = Timestamp.valueOf("1964-02-14 10:00:00.0");
        pstmt.setTimestamp(1, t0);
        pstmt.setTimestamp(2, t0);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.setNull(2, java.sql.Types.TIMESTAMP);
        assertEquals(1, pstmt.executeUpdate());
        pstmt.close();

        pstmt = con.prepareStatement("select mytime, mytime2, mytime3 from #t0004");

        ResultSet rs = pstmt.executeQuery();
        assertNotNull(rs);
        Timestamp t1, t2, t3;

        assertTrue("Expected a result set", rs.next());
        t1 = rs.getTimestamp(1);
        t2 = rs.getTimestamp(2);
        t3 = rs.getTimestamp(3);
        assertEquals(t0, t1);
        assertEquals(t0, t2);
        assertEquals(t0, t3);

        assertTrue("Expected a result set", rs.next());
        t1 = rs.getTimestamp(1);
        t2 = rs.getTimestamp(2);
        t3 = rs.getTimestamp(3);
        assertEquals(t0, t1);
        assertEquals(t0, t2);
        assertEquals(null, t3);

        pstmt.close();
    }

    public void testEscape(String sql, String expected) throws Exception {
        String tmp = con.nativeSQL(sql);

        assertEquals(tmp, expected);
    }

    public void testEscapes0006() throws Exception {
        testEscape("select * from tmp where d={d 1999-09-19}",
            "select * from tmp where d='19990919'");
        testEscape("select * from tmp where d={d '1999-09-19'}",
            "select * from tmp where d='19990919'");
        testEscape("select * from tmp where t={t 12:34:00}",
            "select * from tmp where t='12:34:00'");
        testEscape("select * from tmp where ts={ts 1998-12-15 12:34:00.1234}",
            "select * from tmp where ts='19981215 12:34:00.123'");
        testEscape("select * from tmp where ts={ts 1998-12-15 12:34:00}",
            "select * from tmp where ts='19981215 12:34:00.000'");
        testEscape("select * from tmp where ts={ts 1998-12-15 12:34:00.1}",
            "select * from tmp where ts='19981215 12:34:00.100'");
        testEscape("select * from tmp where ts={ts 1998-12-15 12:34:00}",
            "select * from tmp where ts='19981215 12:34:00.000'");
        testEscape("select * from tmp where d={d 1999-09-19}",
            "select * from tmp where d='19990919'");
        testEscape("select * from tmp where a like '\\%%'",
            "select * from tmp where a like '\\%%'");
        testEscape("select * from tmp where a like 'b%%' {escape 'b'}",
            "select * from tmp where a like 'b%%' escape 'b'");
        testEscape("select * from tmp where a like 'bbb' {escape 'b'}",
            "select * from tmp where a like 'bbb' escape 'b'");
        testEscape("select * from tmp where a='{fn user}'",
            "select * from tmp where a='{fn user}'");
        testEscape("select * from tmp where a={fn user()}",
            "select * from tmp where a=user_name()");
    }

    public void testPreparedStatement0007() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0007 "
            + "  (i  integer  not null, "
            + "   s  char(10) not null) ");

        final int rowsToAdd = 20;
        int count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            String sql = "insert into #t0007 values (" + i + ", 'row" + i + "')";

            count += stmt.executeUpdate(sql);
        }

        stmt.close();
        assertEquals(count, rowsToAdd);

        PreparedStatement pstmt = con.prepareStatement("select s from #t0007 where i = ?");

        pstmt.setInt(1, 7);
        ResultSet rs = pstmt.executeQuery();
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());
        assertEquals(rs.getString(1).trim(), "row7");
        // assertTrue("Expected no result set", !rs.next());

        pstmt.setInt(1, 8);
        rs = pstmt.executeQuery();
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());
        assertEquals(rs.getString(1).trim(), "row8");
        assertTrue("Expected no result set", !rs.next());

        pstmt.close();
    }

    public void testPreparedStatement0008() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0008              "
            + "  (i  integer  not null,      "
            + "   s  char(10) not null)      ");

        PreparedStatement pstmt = con.prepareStatement(
            "insert into #t0008 values (?, ?)");

        final int rowsToAdd = 8;
        final String theString = "abcdefghijklmnopqrstuvwxyz";
        int count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            pstmt.setInt(1, i);
            pstmt.setString(2, theString.substring(0, i));

            count += pstmt.executeUpdate();
        }

        assertEquals(count, rowsToAdd);
        pstmt.close();

        ResultSet rs = stmt.executeQuery("select s, i from #t0008");
        assertNotNull(rs);

        count = 0;

        while (rs.next()) {
            count++;
            assertEquals(rs.getString(1).trim().length(), rs.getInt(2));
        }
        assertTrue(count == rowsToAdd);
        stmt.close();
        pstmt.close();
    }

    public void testPreparedStatement0009() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0009 "
            + "  (i  integer  not null,      "
            + "   s  char(10) not null)      ");

        con.setAutoCommit(false);

        PreparedStatement pstmt = con.prepareStatement(
            "insert into #t0009 values (?, ?)");

        int rowsToAdd = 8;
        final String theString = "abcdefghijklmnopqrstuvwxyz";
        int count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            pstmt.setInt(1, i);
            pstmt.setString(2, theString.substring(0, i));

            count += pstmt.executeUpdate();
        }

        pstmt.close();
        assertEquals(count, rowsToAdd);
        con.rollback();

        ResultSet rs = stmt.executeQuery("select s, i from #t0009");
        assertNotNull(rs);

        count = 0;

        while (rs.next()) {
            count++;
            assertEquals(rs.getString(1).trim().length(), rs.getInt(2));
        }

        assertEquals(count, 0);
        con.commit();

        pstmt = con.prepareStatement("insert into #t0009 values (?, ?)");
        rowsToAdd = 6;
        count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            pstmt.setInt(1, i);
            pstmt.setString(2, theString.substring(0, i));

            count += pstmt.executeUpdate();
        }

        assertEquals(count, rowsToAdd);
        con.commit();
        pstmt.close();

        rs = stmt.executeQuery("select s, i from #t0009");

        count = 0;

        while (rs.next()) {
            count++;
            assertEquals(rs.getString(1).trim().length(), rs.getInt(2));
        }

        assertEquals(count, rowsToAdd);
        con.commit();
        stmt.close();
        con.setAutoCommit(true);
    }

    public void testTransactions0010() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0010 "
            + "  (i  integer  not null,      "
            + "   s  char(10) not null)      ");

        con.setAutoCommit(false);

        PreparedStatement pstmt = con.prepareStatement(
            "insert into #t0010 values (?, ?)");

        int rowsToAdd = 8;
        final String theString = "abcdefghijklmnopqrstuvwxyz";
        int count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            pstmt.setInt(1, i);
            pstmt.setString(2, theString.substring(0, i));

            count += pstmt.executeUpdate();
        }

        assertEquals(count, rowsToAdd);
        con.rollback();

        ResultSet rs = stmt.executeQuery("select s, i from #t0010");
        assertNotNull(rs);

        count = 0;

        while (rs.next()) {
            count++;
            assertEquals(rs.getString(1).trim().length(), rs.getInt(2));
        }

        assertEquals(count, 0);

        rowsToAdd = 6;

        for (int j = 1; j <= 2; j++) {
            count = 0;

            for (int i = 1; i <= rowsToAdd; i++) {
                pstmt.setInt(1, i + ((j - 1) * rowsToAdd));
                pstmt.setString(2, theString.substring(0, i));

                count += pstmt.executeUpdate();
            }

            assertEquals(count, rowsToAdd);
            con.commit();
        }

        rs = stmt.executeQuery("select s, i from #t0010");

        count = 0;

        while (rs.next()) {
            count++;

            int i = rs.getInt(2);

            if (i > rowsToAdd) {
                i -= rowsToAdd;
            }

            assertEquals(rs.getString(1).trim().length(), i);
        }

        assertEquals(count, (2 * rowsToAdd));

        stmt.close();
        pstmt.close();
        con.setAutoCommit(true);
    }

    public void testEmptyResults0011() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0011 "
            + "  (mytime  datetime not null, "
            + "   mytime2 datetime null     )");

        ResultSet rs = stmt.executeQuery("select mytime, mytime2 from #t0011");
        assertNotNull(rs);
        assertTrue("Expected no result set", !rs.next());

        rs = stmt.executeQuery("select mytime, mytime2 from #t0011");
        assertTrue("Expected no result set", !rs.next());
        stmt.close();
    }

    public void testEmptyResults0012() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0012 "
            + "  (mytime  datetime not null, "
            + "   mytime2 datetime null     )");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement(
            "select mytime, mytime2 from #t0012");

        ResultSet rs = pstmt.executeQuery();
        assertNotNull(rs);
        assertTrue("Expected no result", !rs.next());
        rs.close();

        rs = pstmt.executeQuery();
        assertTrue("Expected no result", !rs.next());
        pstmt.close();
    }

    public void testEmptyResults0013() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0013 "
            + "  (mytime  datetime not null, "
            + "   mytime2 datetime null     )");

        ResultSet rs1 = stmt.executeQuery("select mytime, mytime2 from #t0013");
        assertNotNull(rs1);
        assertTrue("Expected no result set", !rs1.next());
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement(
            "select mytime, mytime2 from #t0013");
        ResultSet rs2 = pstmt.executeQuery();
        assertNotNull(rs2);
        assertTrue("Expected no result", !rs2.next());
        pstmt.close();
    }

    public void testForBrowse0014() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0014 (i integer not null)");

        PreparedStatement pstmt = con.prepareStatement(
            "insert into #t0014 values (?)");

        final int rowsToAdd = 100;
        int count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            pstmt.setInt(1, i);
            count += pstmt.executeUpdate();
        }

        assertEquals(count, rowsToAdd);
        pstmt.close();

        pstmt = con.prepareStatement("select i from #t0014 for browse");
        ResultSet rs = pstmt.executeQuery();
        assertNotNull(rs);
        count = 0;

        while (rs.next()) {
            rs.getInt("i");
            count++;
        }

        assertEquals(count, rowsToAdd);
        pstmt.close();

        rs = stmt.executeQuery("select * from #t0014");
        assertNotNull(rs);
        count = 0;

        while (rs.next()) {
            rs.getInt("i");
            count++;
        }

        assertEquals(count, rowsToAdd);

        rs = stmt.executeQuery("select * from #t0014");
        assertNotNull(rs);
        count = 0;

        while (rs.next() && count < 5) {
            rs.getInt("i");
            count++;
        }
        assertTrue(count == 5);

        rs = stmt.executeQuery("select * from #t0014");
        assertNotNull(rs);
        count = 0;

        while (rs.next()) {
            rs.getInt("i");
            count++;
        }

        assertEquals(count, rowsToAdd);
        stmt.close();
    }

    public void testMultipleResults0015() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0015 "
            + "  (i  integer  not null,      "
            + "   s  char(10) not null)      ");

        PreparedStatement pstmt = con.prepareStatement(
            "insert into #t0015 values (?, ?)");

        int rowsToAdd = 8;
        final String theString = "abcdefghijklmnopqrstuvwxyz";
        int count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            pstmt.setInt(1, i);
            pstmt.setString(2, theString.substring(0, i));

            count += pstmt.executeUpdate();
        }

        assertEquals(count, rowsToAdd);
        pstmt.close();

		stmt.execute("select s from #t0015 select i from #t0015");
        ResultSet rs = stmt.getResultSet();
        assertNotNull(rs);
        count = 0;

        while (rs.next()) {
            count++;
        }

        assertEquals(count, rowsToAdd);

        assertTrue(stmt.getMoreResults());

        rs = stmt.getResultSet();
        assertNotNull(rs);
        count = 0;

        while (rs.next()) {
            count++;
        }

        assertEquals(count, rowsToAdd);

        rs = stmt.executeQuery("select i, s from #t0015");
        count = 0;

        while (rs.next()) {
            count++;
        }

        assertEquals(count, rowsToAdd);
        stmt.close();
    }

    public void testMissingParameter0016() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0016 "
            + "  (i  integer  not null,      "
            + "   s  char(10) not null)      ");

        final int rowsToAdd = 20;
        int count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            String sql = "insert into #t0016 values (" + i + ", 'row" + i + "')";
            count += stmt.executeUpdate(sql);
        }

        stmt.close();
        assertEquals(count, rowsToAdd);

        PreparedStatement   pstmt = con.prepareStatement(
            "select s from #t0016 where i=? and s=?");

        // see what happens if neither is set
        try {
            pstmt.executeQuery();
            assertTrue("Failed to throw exception", false);
        } catch (SQLException e) {
            assertTrue("07000".equals(e.getSQLState())
                    && (e.getMessage().indexOf('1') >= 0
                    || e.getMessage().indexOf('2') >= 0));
        }

        pstmt.clearParameters();

        try {
            pstmt.setInt(1, 7);
            pstmt.setString(2, "row7");
            pstmt.clearParameters();

            pstmt.executeQuery();
            assertTrue("Failed to throw exception", false);
        } catch (SQLException e) {
            assertTrue("07000".equals(e.getSQLState())
                    && (e.getMessage().indexOf('1') >= 0
                    || e.getMessage().indexOf('2') >= 0));
        }

        pstmt.clearParameters();

        try {
            pstmt.setInt(1, 7);
            pstmt.executeQuery();
            assertTrue("Failed to throw exception", false);
        } catch (SQLException e) {
            assertTrue("07000".equals(e.getSQLState())
                    && e.getMessage().indexOf('2') >= 0);
        }

        pstmt.clearParameters();

        try {
            pstmt.setString(2, "row7");
            pstmt.executeQuery();
            assertTrue("Failed to throw exception", false);
        } catch (SQLException e) {
            assertTrue("07000".equals(e.getSQLState())
                    && e.getMessage().indexOf('1') >= 0);
        }

        pstmt.close();
    }

    Object[][] getDatatypes() {
        return new Object[][] {
/*			{ "binary(272)",

            "0x101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f" +
            "101112131415161718191a1b1c1d1e1f",

            new byte[] {
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f
            } },
*/
            {"float(6)",      "65.4321",                new BigDecimal("65.4321")},
            {"binary(5)",     "0x1213141516",           new byte[] { 0x12, 0x13, 0x14, 0x15, 0x16}},
            {"varbinary(4)",  "0x1718191A",             new byte[] { 0x17, 0x18, 0x19, 0x1A}},
            {"varchar(8)",    "'12345678'",             "12345678"},
            {"datetime",      "'19990815 21:29:59.01'", Timestamp.valueOf("1999-08-15 21:29:59.01")},
            {"smalldatetime", "'19990215 20:45'",       Timestamp.valueOf("1999-02-15 20:45:00")},
            {"float(6)",      "65.4321",                new Float(65.4321)/* new BigDecimal("65.4321") */},
            {"float(14)",     "1.123456789",            new Double(1.123456789) /*new BigDecimal("1.123456789") */},
            {"real",          "7654321.0",              new Double(7654321.0)},
            {"int",           "4097",                   new Integer(4097)},
            {"float(6)",      "65.4321",                new BigDecimal("65.4321")},
            {"float(14)",     "1.123456789",            new BigDecimal("1.123456789")},
            {"decimal(10,3)", "1234567.089",            new BigDecimal("1234567.089")},
            {"numeric(5,4)",  "1.2345",                 new BigDecimal("1.2345")},
            {"smallint",      "4094",                   new Short((short) 4094)},
            // {"tinyint",       "127",                    new Byte((byte) 127)},
            // {"tinyint",       "-128",                   new Byte((byte) -128)},
            {"tinyint",       "127",                    new Byte((byte) 127)},
            {"tinyint",       "128",                    new Short((short) 128)},
            {"money",         "19.95",                  new BigDecimal("19.95")},
            {"smallmoney",    "9.97",                   new BigDecimal("9.97")},
            {"bit",           "1",                      Boolean.TRUE},
//			{ "text",          "'abcedefg'",             "abcdefg" },
/*			{ "char(1000)",
              "'123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890'",
               "123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890" },
                           */
//			{ "char(1000)",      "'1234567890'",           "1234567890" },
//            { "image",         "0x0a0a0b",               new byte[] { 0x0a, 0x0a, 0x0b } },

        };
    }

    public void testOutputParams() throws Exception {
        Statement stmt = con.createStatement();
        dropProcedure("#jtds_outputTest");

        Object[][] datatypes = getDatatypes();

        for (int i = 0; i < datatypes.length; i++) {
            String valueToAssign;
            boolean bImage = datatypes[i][0].equals("image");

            if (bImage) {
                valueToAssign = "";
            } else {
                valueToAssign = " = " + datatypes[i][1];
            }

            String sql = "create procedure #jtds_outputTest "
                    + "@a1 " + datatypes[i][0] + " = null out "
                    + "as select @a1" + valueToAssign;
            stmt.executeUpdate(sql);

            for (int pass = 0; (pass < 2 && !bImage) || pass < 1; pass++) {
                CallableStatement cstmt = con.prepareCall("{call #jtds_outputTest(?)}");

                int jtype = getType(datatypes[i][2]);

                if (pass == 1)
                    cstmt.setObject(1, null, jtype, 10);
                if (jtype == java.sql.Types.NUMERIC || jtype == java.sql.Types.DECIMAL) {
                    cstmt.registerOutParameter(1, jtype, 10);

                    if (pass == 0) {
                        cstmt.setObject(1, datatypes[i][2], jtype, 10);
                    }
                } else if (jtype == java.sql.Types.VARCHAR) {
                    cstmt.registerOutParameter(1, jtype);

                    if (pass == 0) {
                        cstmt.setObject(1, datatypes[i][2]);
                    }
                } else {
                    cstmt.registerOutParameter(1, jtype);

                    if (pass == 0) {
                        cstmt.setObject(1, datatypes[i][2]);
                    }
                }

                assertEquals(bImage, cstmt.execute());

                while (cstmt.getMoreResults() || cstmt.getUpdateCount() != -1) ;

                if (jtype == java.sql.Types.VARBINARY) {
                    assertTrue(compareBytes(cstmt.getBytes(1), (byte[]) datatypes[i][2]) == 0);
                } else if (datatypes[i][2] instanceof Number) {
                    Number n = (Number) cstmt.getObject(1);

                    if (n != null) {
                        assertEquals("Failed on " + datatypes[i][0], n.doubleValue(),
                                     ((Number) datatypes[i][2]).doubleValue(), 0.001);
                    } else {
                        assertEquals("Failed on " + datatypes[i][0], n, datatypes[i][2]);
                    }
                } else {
                    assertEquals("Failed on " + datatypes[i][0], cstmt.getObject(1), datatypes[i][2]);
                }

                cstmt.close();
            }  // for (pass

            stmt.executeUpdate(" drop procedure #jtds_outputTest");
        }  // for (int

        stmt.close();
    }

    public void testStatements0020() throws Exception {
        Statement  stmt    = con.createStatement();
        stmt.executeUpdate("create table #t0020a ( " +
            "  i1   int not null,     " +
            "  s1   char(10) not null " +
            ")                        " +
            "");
        stmt.executeUpdate("create table #t0020b ( " +
            "  i2a   int not null,     " +
            "  i2b   int not null,     " +
            "  s2   char(10) not null " +
            ")                        " +
            "");
        stmt.executeUpdate("create table #t0020c ( " +
            "  i3   int not null,     " +
            "  s3   char(10) not null " +
            ")                        " +
            "");

        int nextB = 1;
        int nextC = 1;

        for (int i = 1; i < 50; i++) {
            stmt.executeUpdate("insert into #t0020a " +
                "  values(" + i + ", " +
                "         'row" + i + "') " +
                "");

            for (int j = nextB; (nextB % 5) != 0; j++, nextB++) {
                stmt.executeUpdate("insert into #t0020b " +
                    " values(" + i + ", " +
                    "        " + j + ", " +
                    "        'row" + i + "." + j + "' " +
                    "        )" +
                    "");

                for (int k = nextC; (nextC % 3) != 0; k++, nextC++) {
                    stmt.executeUpdate("insert into #t0020c " +
                        " values(" + j + ", " +
                        "        'row" + i + "." + j + "." + k + "' " +
                        "        )" +
                        "");
                }
            }
        }

        Statement stmtA = con.createStatement();
        PreparedStatement stmtB = con.prepareStatement(
            "select i2b, s2 from #t0020b where i2a=?");
        PreparedStatement stmtC = con.prepareStatement(
            "select s3 from #t0020c where i3=?");

        ResultSet rs1 = stmtA.executeQuery("select i1 from #t0020a");
        assertNotNull(rs1);

        while (rs1.next()) {
            stmtB.setInt(1, rs1.getInt("i1"));
            ResultSet rs2 = stmtB.executeQuery();
            assertNotNull(rs2);

            while (rs2.next()) {
                stmtC.setInt(1, rs2.getInt(1));
                ResultSet rs3 = stmtC.executeQuery();
                assertNotNull(rs3);
                rs3.next();
            }
        }

        stmt.close();
        stmtA.close();
        stmtB.close();
        stmtC.close();
    }

    public void testBlob0021() throws Exception {
        byte smallarray[] = {
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10
        };

        byte array1[] = {
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08
        };

        String bigtext1 =
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "abcdefghijklmnop" +
            "";

        Statement stmt = con.createStatement();

        dropTable("#t0021");

        stmt.executeUpdate(
            "create table #t0021 ( " +
            " mybinary         binary(16) not null, " +
            " myimage          image not null, " +
            " mynullimage      image null, " +
            " mytext           text not null, " +
            " mynulltext       text null) ");

        // Insert a row without nulls via a Statement
        PreparedStatement insert = con.prepareStatement(
            "insert into #t0021(     " +
                " mybinary,             " +
                " myimage,              " +
                " mynullimage,          " +
                " mytext,               " +
                " mynulltext            " +
                ")                      " +
            "values(?, ?, ?, ?, ?)  ");

        insert.setBytes(1, smallarray);
        insert.setBytes(2, array1);
        insert.setBytes(3, array1);
        insert.setString(4, bigtext1);
        insert.setString(5, bigtext1);

        int count = insert.executeUpdate();
        assertEquals(count, 1);
        insert.close();

        ResultSet rs = stmt.executeQuery("select * from #t0021");
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());

        byte[] a1 = rs.getBytes("myimage");
        byte[] a2 = rs.getBytes("mynullimage");
        String s1 = rs.getString("mytext");
        String s2 = rs.getString("mynulltext");

        assertEquals(0, compareBytes(a1, array1));
        assertEquals(0, compareBytes(a2, array1));
        assertEquals(bigtext1, s1);
        assertEquals(bigtext1, s2);

        stmt.close();
    }

    public void testNestedStatements0022() throws Exception {
        Statement  stmt    = con.createStatement();
        stmt.executeUpdate("create table #t0022a "
            + "  (i   integer not null, "
            + "   str char(254) not null) ");

        stmt.executeUpdate("create table #t0022b             "
            + "  (i   integer not null,      "
            + "   t   datetime not null)     ");

        PreparedStatement  pStmtA = con.prepareStatement(
            "insert into #t0022a values (?, ?)");
        PreparedStatement  pStmtB = con.prepareStatement(
            "insert into #t0022b values (?, getdate())");

        final int rowsToAdd = 100;
        int count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            pStmtA.setInt(1, i);
            StringBuffer tmp = new StringBuffer(255);

            while (tmp.length() < 240) {
                tmp.append("row ").append(i).append(". ");
            }

            pStmtA.setString(2, tmp.toString());
            count += pStmtA.executeUpdate();

            pStmtB.setInt(1, i);
            pStmtB.executeUpdate();
        }

        pStmtA.close();
        pStmtB.close();
        assertEquals(count, rowsToAdd);

        Statement stmtA = con.createStatement();
        Statement stmtB = con.createStatement();

        count = 0;
        ResultSet rsA = stmtA.executeQuery("select * from #t0022a");
        assertNotNull(rsA);

        while (rsA.next()) {
            count++;

            ResultSet  rsB = stmtB.executeQuery(
                "select * from #t0022b where i=" + rsA.getInt("i"));

            assertNotNull(rsB);
            assertTrue("Expected a result set", rsB.next());
            assertTrue("Expected no result set", !rsB.next());
        }

        assertEquals(count, rowsToAdd);

        stmt.close();
        stmtA.close();
        stmtB.close();
    }

    public void testPrimaryKeyFloat0023() throws Exception {
        Double d[] = {
            new Double(-1.0),
            new Double(1234.543),
            new Double(0.0),
            new Double(1),
            new Double(-2.0),
            new Double(0.14),
            new Double(0.79),
            new Double(1000000.12345),
            new Double(-1000000.12345),
            new Double(1000000),
            new Double(-1000000),
            new Double(1.7E+308),
            new Double(1.7E-307)        // jikes 1.04 has a bug and can't handle 1.7E-308
        };

        Statement  stmt    = con.createStatement();
        stmt.executeUpdate(""
            + "create table #t0023 "
            + "  (pk   float not null, "
            + "   type char(30) not null, "
            + "   b    bit, "
            + "   str  char(30) not null, "
            + "   t int identity(1,1), "
            + "   primary key (pk, type))    ");

        PreparedStatement  pstmt = con.prepareStatement(
            "insert into #t0023 (pk, type, b, str) values(?, 'prepared', 0, ?)");

        for (int i = 0; i < d.length; i++) {
            pstmt.setDouble(1, d[i].doubleValue());
            pstmt.setString(2, (d[i]).toString());
            int preparedCount = pstmt.executeUpdate();

            assertEquals(preparedCount, 1);

            int adhocCount = stmt.executeUpdate(""
                + "insert into #t0023        "
                + " (pk, type, b, str)      "
                + " values("
                + "   " + d[i] + ",         "
                + "       'adhoc',          "
                + "       1,                "
                + "   '" + d[i] + "')       ");

            assertEquals(adhocCount, 1);
        }

        int count = 0;
        ResultSet rs = stmt.executeQuery("select * from #t0023 where type='prepared' order by t");
        assertNotNull(rs);

        while (rs.next()) {
            assertEquals(d[count].toString(), "" + rs.getDouble("pk"));
            count++;
        }

        assertEquals(count, d.length);

        count = 0;
        rs = stmt.executeQuery("select * from #t0023 where type='adhoc' order by t");

        while (rs.next()) {
            assertEquals(d[count].toString(), "" + rs.getDouble("pk"));
            count++;
        }

        assertEquals(count, d.length);

        stmt.close();
        pstmt.close();
    }

    public void testPrimaryKeyReal0024() throws Exception {
        Float d[] = {
            new Float(-1.0),
            new Float(1234.543),
            new Float(0.0),
            new Float(1),
            new Float(-2.0),
            new Float(0.14),
            new Float(0.79),
            new Float(1000000.12345),
            new Float(-1000000.12345),
            new Float(1000000),
            new Float(-1000000),
            new Float(3.4E+38),
            new Float(3.4E-38)
        };

        Statement stmt = con.createStatement();
        stmt.executeUpdate(""
            + "create table #t0024                  "
            + "  (pk   real not null,             "
            + "   type char(30) not null,          "
            + "   b    bit,                        "
            + "   str  char(30) not null,          "
            + "   t int identity(1,1), "
            + "    primary key (pk, type))    ");

        PreparedStatement pstmt = con.prepareStatement(
            "insert into #t0024 (pk, type, b, str) values(?, 'prepared', 0, ?)");

        for (int i=0; i < d.length; i++) {
            pstmt.setFloat(1, d[i].floatValue());
            pstmt.setString(2, (d[i]).toString());
            int preparedCount = pstmt.executeUpdate();
            assertTrue(preparedCount == 1);

            int adhocCount = stmt.executeUpdate(""
                + "insert into #t0024        "
                + " (pk, type, b, str)      "
                + " values("
                + "   " + d[i] + ",         "
                + "       'adhoc',          "
                + "       1,                "
                + "   '" + d[i] + "')       ");
            assertEquals(adhocCount, 1);
        }

        int count = 0;
        ResultSet rs = stmt.executeQuery("select * from #t0024 where type='prepared' order by t");
        assertNotNull(rs);

        while (rs.next()) {
            String s1 = d[count].toString().trim();
            String s2 = ("" + rs.getFloat("pk")).trim();

            assertTrue(s1.equalsIgnoreCase(s2));
            count++;
        }

        assertEquals(count, d.length);

        count = 0;
        rs = stmt.executeQuery("select * from #t0024 where type='adhoc' order by t");

        while (rs.next()) {
            String s1 = d[count].toString().trim();
            String s2 = ("" + rs.getFloat("pk")).trim();

            assertTrue(s1.equalsIgnoreCase(s2));
            count++;
        }

        assertEquals(count, d.length);

        stmt.close();
        pstmt.close();
    }

    public void testGetBoolean0025() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0025 " +
            "  (i      integer, " +
            "   b      bit,     " +
            "   s      char(5), " +
            "   f      float)   ");

        // @todo Check which CHAR/VARCHAR values should be true and which should be false.
        assertTrue(stmt.executeUpdate("insert into #t0025 values(0, 0, 'false', 0.0)") == 1);
        assertTrue(stmt.executeUpdate("insert into #t0025 values(0, 0, '0', 0.0)") == 1);
        assertTrue(stmt.executeUpdate("insert into #t0025 values(1, 1, 'true', 7.0)") == 1);
        assertTrue(stmt.executeUpdate("insert into #t0025 values(2, 1, '1', -5.0)") == 1);

        ResultSet rs = stmt.executeQuery("select * from #t0025 order by i");
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());

        assertTrue(!rs.getBoolean("i"));
        assertTrue(!rs.getBoolean("b"));
        assertTrue(!rs.getBoolean("s"));
        assertTrue(!rs.getBoolean("f"));

        assertTrue("Expected a result set", rs.next());

        assertTrue(!rs.getBoolean("i"));
        assertTrue(!rs.getBoolean("b"));
        assertTrue(!rs.getBoolean("s"));
        assertTrue(!rs.getBoolean("f"));

        assertTrue("Expected a result set", rs.next());

        assertTrue(rs.getBoolean("i"));
        assertTrue(rs.getBoolean("b"));
        assertTrue(rs.getBoolean("s"));
        assertTrue(rs.getBoolean("f"));

        assertTrue("Expected a result set", rs.next());

        assertTrue(rs.getBoolean("i"));
        assertTrue(rs.getBoolean("b"));
        assertTrue(rs.getBoolean("s"));
        assertTrue(rs.getBoolean("f"));

        assertTrue("Expected no result set", !rs.next());

        stmt.close();
    }

    /**
     * <b>SAfe</b> Tests whether cursor-based statements still work ok when
     * nested. Similar to <code>testNestedStatements0022</code>, which tests
     * the same with plain (non-cursor-based) statements (and unfortunately
     * fails).
     *
     * @throws Exception if an Exception occurs (very relevant, huh?)
     */
    public void testNestedStatements0026() throws Exception {
        Statement  stmt    = con.createStatement();
        stmt.executeUpdate("create table #t0026a "
            + "  (i   integer not null, "
            + "   str char(254) not null) ");

        stmt.executeUpdate("create table #t0026b             "
        + "  (i   integer not null,      "
        + "   t   datetime not null)     ");
        stmt.close();

        PreparedStatement pstmtA = con.prepareStatement(
            "insert into #t0026a values (?, ?)");
        PreparedStatement pstmtB = con.prepareStatement(
            "insert into #t0026b values (?, getdate())");

        final int rowsToAdd = 100;
        int count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            pstmtA.setInt(1, i);
            StringBuffer tmp = new StringBuffer(255);

            while (tmp.length() < 240) {
                tmp.append("row ").append(i).append(". ");
            }

            pstmtA.setString(2, tmp.toString());
            count += pstmtA.executeUpdate();

            pstmtB.setInt(1, i);
            pstmtB.executeUpdate();
        }

        assertEquals(count, rowsToAdd);
        pstmtA.close();
        pstmtB.close();

        Statement stmtA = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
        Statement stmtB = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);

        count = 0;
        ResultSet rsA = stmtA.executeQuery("select * from #t0026a");
        assertNotNull(rsA);

        while (rsA.next()) {
            count++;

            ResultSet rsB = stmtB.executeQuery(
                "select * from #t0026b where i=" + rsA.getInt("i"));

            assertNotNull(rsB);
            assertTrue("Expected a result set", rsB.next());
            assertTrue("Expected no result set", !rsB.next());
			rsB.close();
        }

        assertEquals(count, rowsToAdd);

        stmtA.close();
        stmtB.close();
    }

    public void testErrors0036() throws Exception {
        Statement  stmt = con.createStatement();

        final int numberToTest = 5;

        for (int i = 0; i < numberToTest; i++) {
            String table = "#t0036_no_create_" + i;

            try {
                stmt.executeUpdate("drop table " + table);
                fail("Did not expect to reach here");
            } catch (SQLException e) {
                assertEquals("42S02", e.getSQLState());
            }
        }

        stmt.close();
    }

    public void testTimestamps0037() throws Exception {
        Statement stmt = con.createStatement();
        ResultSet rs   = stmt.executeQuery(
                "select                                    " +
                "  convert(smalldatetime, '1999-01-02') a, " +
                "  convert(smalldatetime, null)         b, " +
                "  convert(datetime, '1999-01-02')      c, " +
                "  convert(datetime, null)              d  ");
        assertNotNull(rs);

        assertTrue("Expected a result", rs.next());

        assertNotNull(rs.getDate("a"));
        assertNull(rs.getDate("b"));
        assertNotNull(rs.getDate("c"));
        assertNull(rs.getDate("d"));

        assertNotNull(rs.getTime("a"));
        assertNull(rs.getTime("b"));
        assertNotNull(rs.getTime("c"));
        assertNull(rs.getTime("d"));

        assertNotNull(rs.getTimestamp("a"));
        assertNull(rs.getTimestamp("b"));
        assertNotNull(rs.getTimestamp("c"));
        assertNull(rs.getTimestamp("d"));

        assertTrue("Expected no more results", !rs.next());

        stmt.close();
    }

    public void testConnection0038() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0038 ("
            + " keyField char(255)     not null, "
            + " descField varchar(255)  not null) ");

        int count = stmt.executeUpdate("insert into #t0038 values ('value', 'test')");
        assertEquals(count, 1);

        con.setTransactionIsolation(Connection.TRANSACTION_READ_UNCOMMITTED);
        con.setAutoCommit(false);
        PreparedStatement ps = con.prepareStatement("update #t0038 set descField=descField where keyField=?");
        ps.setString(1, "value");
        ps.executeUpdate();
        ps.close();
        con.commit();
        // conn.rollback();

        ResultSet resultSet = stmt.executeQuery(
            "select descField from #t0038 where keyField='value'");
        assertTrue(resultSet.next());
        stmt.close();
    }

    public void testConnection0039() throws Exception {
        for (int i = 0; i < 10; i++) {
            Connection conn = getConnection();
            Statement statement = conn.createStatement();
            ResultSet resultSet = statement.executeQuery("select 5");
            assertNotNull(resultSet);

            resultSet.close();
            statement.close();
            conn.close();
        }
    }

    public void testPreparedStatement0040() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0040 ("
            + " c255 char(255)     not null, "
            + " v255 varchar(255)  not null) ");

        PreparedStatement pstmt = con.prepareStatement("insert into #t0040 values (?, ?)");

        String along = getLongString('a');
        String blong = getLongString('b');

        pstmt.setString(1, along);
        pstmt.setString(2, along);

        int count = pstmt.executeUpdate();

        assertEquals(count, 1);
        pstmt.close();

        count = stmt.executeUpdate(""
            + "insert into #t0040 values ( "
            + "'" + blong + "', "
            + "'" + blong + "')");
        assertEquals(count, 1);

        pstmt = con.prepareStatement("select c255, v255 from #t0040 order by c255");
        ResultSet rs = pstmt.executeQuery();
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());
        assertEquals(rs.getString("c255"), along);
        assertEquals(rs.getString("v255"), along);

        assertTrue("Expected a result set", rs.next());
        assertEquals(rs.getString("c255"), blong);
        assertEquals(rs.getString("v255"), blong);

        assertTrue("Expected no result set", !rs.next());
        pstmt.close();

        rs = stmt.executeQuery("select c255, v255 from #t0040 order by c255");
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());
        assertEquals(rs.getString("c255"), along);
        assertEquals(rs.getString("v255"), along);

        assertTrue("Expected a result set", rs.next());
        assertEquals(rs.getString("c255"), blong);
        assertEquals(rs.getString("v255"), blong);

        assertTrue("Expected no result set", !rs.next());
        stmt.close();
    }

    public void testPreparedStatement0041() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0041 "
            + "  (i  integer  not null, "
            + "   s  text     not null) ");

        PreparedStatement pstmt = con.prepareStatement("insert into #t0041 values (?, ?)");

        // TODO: Check values
        final int rowsToAdd = 400;
        final String theString = getLongString(400);
        int count = 0;

        for (int i = 1; i <= rowsToAdd; i++) {
            pstmt.setInt(1, i);
            pstmt.setString(2, theString.substring(0, i));

            count += pstmt.executeUpdate();
        }

        assertEquals(rowsToAdd, count);
        pstmt.close();

        ResultSet  rs = stmt.executeQuery("select s, i from #t0041");
        assertNotNull(rs);

        count = 0;

        while (rs.next()) {
            rs.getString("s");
            count++;
        }

        assertEquals(rowsToAdd, count);
        stmt.close();
    }

    public void testPreparedStatement0042() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0042 (s char(5) null, i integer null, j integer not null)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("insert into #t0042 (s, i, j) values (?, ?, ?)");

        pstmt.setString(1, "hello");
        pstmt.setNull(2, java.sql.Types.INTEGER);
        pstmt.setInt(3, 1);

        int count = pstmt.executeUpdate();
        assertEquals(count, 1);

        pstmt.setInt(2, 42);
        pstmt.setInt(3, 2);
        count = pstmt.executeUpdate();
        assertEquals(count, 1);
        pstmt.close();

        pstmt = con.prepareStatement("select i from #t0042 order by j");
        ResultSet rs = pstmt.executeQuery();
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());
        rs.getInt(1);
        assertTrue(rs.wasNull());

        assertTrue("Expected a result set", rs.next());
        assertEquals(rs.getInt(1), 42);
        assertTrue(!rs.wasNull());

        assertTrue("Expected no result set", !rs.next());
        pstmt.close();
    }

    public void testResultSet0043() throws Exception {
        Statement stmt = con.createStatement();

        try {
            ResultSet rs = stmt.executeQuery("select 1");
            assertNotNull(rs);
            rs.getInt(1);

            fail("Did not expect to reach here");
        } catch (SQLException e) {
            assertEquals("24000", e.getSQLState());
        }

        stmt.close();
    }

    public void testResultSet0044() throws Exception {
        Statement stmt = con.createStatement();

        ResultSet rs = stmt.executeQuery("select 1");
        assertNotNull(rs);
        rs.close();

        try {
            rs.next();
            fail("Was expecting ResultSet.next() to throw an exception if the ResultSet was closed");
        } catch (SQLException e) {
            assertEquals("HY010", e.getSQLState());
        }

        stmt.close();
    }

    public void testResultSet0045() throws Exception {
        Statement stmt = con.createStatement();

        ResultSet rs = stmt.executeQuery("select 1");
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());
        rs.getInt(1);

        assertTrue("Expected no result set", !rs.next());

        try {
            rs.getInt(1);
            fail("Did not expect to reach here");
        } catch (java.sql.SQLException e) {
            assertEquals("24000", e.getSQLState());
        }

        stmt.close();
    }

    public void testMetaData0046() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #t0046 ("
            + "   i integer identity, "
            + "   a integer not null, "
            + "   b integer null ) ");

        int count = stmt.executeUpdate("insert into #t0046 (a, b) values (-2, -3)");
        assertEquals(count, 1);

        ResultSet rs = stmt.executeQuery("select i, a, b, 17 c from #t0046");
        assertNotNull(rs);

        ResultSetMetaData md = rs.getMetaData();
        assertNotNull(md);

        assertTrue(md.isAutoIncrement(1));
        assertTrue(!md.isAutoIncrement(2));
        assertTrue(!md.isAutoIncrement(3));
        assertTrue(!md.isAutoIncrement(4));

        assertTrue(md.isReadOnly(1));
        assertTrue(!md.isReadOnly(2));
        assertTrue(!md.isReadOnly(3));
//        assertTrue(md.isReadOnly(4)); SQL 6.5 does not report this one correctly!

        assertEquals(md.isNullable(1),java.sql.ResultSetMetaData.columnNoNulls);
        assertEquals(md.isNullable(2),java.sql.ResultSetMetaData.columnNoNulls);
        assertEquals(md.isNullable(3),java.sql.ResultSetMetaData.columnNullable);
        // assert(md.isNullable(4) == java.sql.ResultSetMetaData.columnNoNulls);

        rs.close();
        stmt.close();
    }

    public void testTimestamps0047() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate(
            "create table #t0047 " +
            "(                               " +
            "  t1   datetime not null,       " +
            "  t2   datetime null,           " +
            "  t3   smalldatetime not null,  " +
            "  t4   smalldatetime null       " +
            ")");

        String query =
            "insert into #t0047 (t1, t2, t3, t4) " +
            " values('2000-01-02 19:35:01.333', " +
            "        '2000-01-02 19:35:01.333', " +
            "        '2000-01-02 19:35:01.333', " +
            "        '2000-01-02 19:35:01.333'  " +
            ")";
        int count = stmt.executeUpdate(query);

        assertEquals(count, 1);

        ResultSet rs = stmt.executeQuery("select t1, t2, t3, t4 from #t0047");
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());

        java.sql.Timestamp  t1 = rs.getTimestamp("t1");
        java.sql.Timestamp  t2 = rs.getTimestamp("t2");
        java.sql.Timestamp  t3 = rs.getTimestamp("t3");
        java.sql.Timestamp  t4 = rs.getTimestamp("t4");

        java.sql.Timestamp r1 = Timestamp.valueOf("2000-01-02 19:35:01.333");
        java.sql.Timestamp r2 = Timestamp.valueOf("2000-01-02 19:35:00");

        assertEquals(r1, t1);
        assertEquals(r1, t2);
        assertEquals(r2, t3);
        assertEquals(r2, t4);

        stmt.close();
    }

    public void testTimestamps0048() throws Exception {
        Statement stmt = con.createStatement();
        stmt.executeUpdate(
            "create table #t0048              " +
            "(                               " +
            "  t1   datetime not null,       " +
            "  t2   datetime null,           " +
            "  t3   smalldatetime not null,  " +
            "  t4   smalldatetime null       " +
            ")");

        java.sql.Timestamp r1;
        java.sql.Timestamp r2;
        r1 = Timestamp.valueOf("2000-01-02 19:35:01");
        r2 = Timestamp.valueOf("2000-01-02 19:35:00");

        java.sql.PreparedStatement pstmt = con.prepareStatement(
            "insert into #t0048 (t1, t2, t3, t4) values(?, ?, ?, ?)");

        pstmt.setTimestamp(1, r1);
        pstmt.setTimestamp(2, r1);
        pstmt.setTimestamp(3, r1);
        pstmt.setTimestamp(4, r1);

        int count = pstmt.executeUpdate();
        assertEquals(count, 1);
        pstmt.close();

        ResultSet rs = stmt.executeQuery("select t1, t2, t3, t4 from #t0048");
        assertNotNull(rs);

        assertTrue("Expected a result set", rs.next());
        java.sql.Timestamp  t1 = rs.getTimestamp("t1");
        java.sql.Timestamp  t2 = rs.getTimestamp("t2");
        java.sql.Timestamp  t3 = rs.getTimestamp("t3");
        java.sql.Timestamp  t4 = rs.getTimestamp("t4");

        assertEquals(r1, t1);
        assertEquals(r1, t2);
        assertEquals(r2, t3);
        assertEquals(r2, t4);

        stmt.close();
    }

    public void testDecimalConversion0058() throws Exception {
        Statement stmt = con.createStatement();

        ResultSet rs = stmt.executeQuery("select convert(DECIMAL(4,0), 0)");
        assertNotNull(rs);
        assertTrue("Expected a result set", rs.next());
        assertEquals(rs.getInt(1), 0);
        assertTrue("Expected no result set", !rs.next());

        rs = stmt.executeQuery("select convert(DECIMAL(4,0), 1)");
        assertNotNull(rs);
        assertTrue("Expected a result set", rs.next());
        assertEquals(rs.getInt(1), 1);
        assertTrue("Expected no result set", !rs.next());

        rs = stmt.executeQuery("select convert(DECIMAL(4,0), -1)");
        assertNotNull(rs);
        assertTrue("Expected a result set", rs.next());
        assertEquals(rs.getInt(1), -1);
        assertTrue("Expected no result set", !rs.next());

        stmt.close();
    }

    /**
     * Test for bug [994916] datetime decoding in TdsData.java
     */
    public void testDatetimeRounding1() throws Exception {
        // Per the SQL Server documentation
        // Send:    01/01/98 23:59:59.990
        // Receive: 01/01/98 23:59:59.990
        Calendar sendValue = Calendar.getInstance();
        Calendar receiveValue = Calendar.getInstance();

        sendValue.set(Calendar.MONTH, Calendar.JANUARY);
        sendValue.set(Calendar.DAY_OF_MONTH, 1);
        sendValue.set(Calendar.YEAR, 1998);
        sendValue.set(Calendar.HOUR_OF_DAY, 23);
        sendValue.set(Calendar.MINUTE, 59);
        sendValue.set(Calendar.SECOND, 59);
        sendValue.set(Calendar.MILLISECOND, 990);

        receiveValue.set(Calendar.MONTH, Calendar.JANUARY);
        receiveValue.set(Calendar.DAY_OF_MONTH, 1);
        receiveValue.set(Calendar.YEAR, 1998);
        receiveValue.set(Calendar.HOUR_OF_DAY, 23);
        receiveValue.set(Calendar.MINUTE, 59);
        receiveValue.set(Calendar.SECOND, 59);
        receiveValue.set(Calendar.MILLISECOND, 990);

        Statement stmt = con.createStatement();
        stmt.execute("create table #dtr1 (data datetime)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("insert into #dtr1 (data) values (?)");
        pstmt.setTimestamp(1, new Timestamp(sendValue.getTime().getTime()));
        assertEquals(pstmt.executeUpdate(), 1);
        pstmt.close();

        pstmt = con.prepareStatement("select data from #dtr1");
        ResultSet rs = pstmt.executeQuery();

        assertTrue(rs.next());
        assertEquals(receiveValue.getTime().getTime(), getTimeInMs(rs));
        assertTrue(!rs.next());

        pstmt.close();
        rs.close();
    }

    /**
     * Test for bug [994916] datetime decoding in TdsData.java
     */
    public void testDatetimeRounding2() throws Exception {
        // Per the SQL Server documentation
        // Send:    01/01/98 23:59:59.991
        // Receive: 01/01/98 23:59:59.990
        Calendar sendValue = Calendar.getInstance();
        Calendar receiveValue = Calendar.getInstance();

        sendValue.set(Calendar.MONTH, Calendar.JANUARY);
        sendValue.set(Calendar.DAY_OF_MONTH, 1);
        sendValue.set(Calendar.YEAR, 1998);
        sendValue.set(Calendar.HOUR_OF_DAY, 23);
        sendValue.set(Calendar.MINUTE, 59);
        sendValue.set(Calendar.SECOND, 59);
        sendValue.set(Calendar.MILLISECOND, 991);

        receiveValue.set(Calendar.MONTH, Calendar.JANUARY);
        receiveValue.set(Calendar.DAY_OF_MONTH, 1);
        receiveValue.set(Calendar.YEAR, 1998);
        receiveValue.set(Calendar.HOUR_OF_DAY, 23);
        receiveValue.set(Calendar.MINUTE, 59);
        receiveValue.set(Calendar.SECOND, 59);
        receiveValue.set(Calendar.MILLISECOND, 990);

        Statement stmt = con.createStatement();
        stmt.execute("create table #dtr2 (data datetime)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("insert into #dtr2 (data) values (?)");
        pstmt.setTimestamp(1, new Timestamp(sendValue.getTime().getTime()));
        assertEquals(pstmt.executeUpdate(), 1);
        pstmt.close();

        pstmt = con.prepareStatement("select data from #dtr2");
        ResultSet rs = pstmt.executeQuery();

        assertTrue(rs.next());
        assertEquals(receiveValue.getTime().getTime(), getTimeInMs(rs));
        assertTrue(!rs.next());

        pstmt.close();
        rs.close();
    }

    /**
     * Test for bug [994916] datetime decoding in TdsData.java
     */
    public void testDatetimeRounding3() throws Exception {
        // Per the SQL Server documentation
        // Send:    01/01/98 23:59:59.992
        // Receive: 01/01/98 23:59:59.993
        Calendar sendValue = Calendar.getInstance();
        Calendar receiveValue = Calendar.getInstance();

        sendValue.set(Calendar.MONTH, Calendar.JANUARY);
        sendValue.set(Calendar.DAY_OF_MONTH, 1);
        sendValue.set(Calendar.YEAR, 1998);
        sendValue.set(Calendar.HOUR_OF_DAY, 23);
        sendValue.set(Calendar.MINUTE, 59);
        sendValue.set(Calendar.SECOND, 59);
        sendValue.set(Calendar.MILLISECOND, 992);

        receiveValue.set(Calendar.MONTH, Calendar.JANUARY);
        receiveValue.set(Calendar.DAY_OF_MONTH, 1);
        receiveValue.set(Calendar.YEAR, 1998);
        receiveValue.set(Calendar.HOUR_OF_DAY, 23);
        receiveValue.set(Calendar.MINUTE, 59);
        receiveValue.set(Calendar.SECOND, 59);
        receiveValue.set(Calendar.MILLISECOND, 993);

        Statement stmt = con.createStatement();
        stmt.execute("create table #dtr3 (data datetime)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("insert into #dtr3 (data) values (?)");
        pstmt.setTimestamp(1, new Timestamp(sendValue.getTime().getTime()));
        assertEquals(pstmt.executeUpdate(), 1);
        pstmt.close();

        pstmt = con.prepareStatement("select data from #dtr3");
        ResultSet rs = pstmt.executeQuery();

        assertTrue(rs.next());
        assertEquals(receiveValue.getTime().getTime(), getTimeInMs(rs));
        assertTrue(!rs.next());

        pstmt.close();
        rs.close();
    }

    /**
     * Test for bug [994916] datetime decoding in TdsData.java
     */
    public void testDatetimeRounding4() throws Exception {
        // Per the SQL Server documentation
        // Send:    01/01/98 23:59:59.993
        // Receive: 01/01/98 23:59:59.993
        Calendar sendValue = Calendar.getInstance();
        Calendar receiveValue = Calendar.getInstance();

        sendValue.set(Calendar.MONTH, Calendar.JANUARY);
        sendValue.set(Calendar.DAY_OF_MONTH, 1);
        sendValue.set(Calendar.YEAR, 1998);
        sendValue.set(Calendar.HOUR_OF_DAY, 23);
        sendValue.set(Calendar.MINUTE, 59);
        sendValue.set(Calendar.SECOND, 59);
        sendValue.set(Calendar.MILLISECOND, 993);

        receiveValue.set(Calendar.MONTH, Calendar.JANUARY);
        receiveValue.set(Calendar.DAY_OF_MONTH, 1);
        receiveValue.set(Calendar.YEAR, 1998);
        receiveValue.set(Calendar.HOUR_OF_DAY, 23);
        receiveValue.set(Calendar.MINUTE, 59);
        receiveValue.set(Calendar.SECOND, 59);
        receiveValue.set(Calendar.MILLISECOND, 993);

        Statement stmt = con.createStatement();
        stmt.execute("create table #dtr4 (data datetime)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("insert into #dtr4 (data) values (?)");
        pstmt.setTimestamp(1, new Timestamp(sendValue.getTime().getTime()));
        assertEquals(pstmt.executeUpdate(), 1);
        pstmt.close();

        pstmt = con.prepareStatement("select data from #dtr4");
        ResultSet rs = pstmt.executeQuery();

        assertTrue(rs.next());
        assertEquals(receiveValue.getTime().getTime(), getTimeInMs(rs));
        assertTrue(!rs.next());

        pstmt.close();
        rs.close();
    }

    /**
     * Test for bug [994916] datetime decoding in TdsData.java
     */
    public void testDatetimeRounding5() throws Exception {
        // Per the SQL Server documentation
        // Send:    01/01/98 23:59:59.994
        // Receive: 01/01/98 23:59:59.993
        Calendar sendValue = Calendar.getInstance();
        Calendar receiveValue = Calendar.getInstance();

        sendValue.set(Calendar.MONTH, Calendar.JANUARY);
        sendValue.set(Calendar.DAY_OF_MONTH, 1);
        sendValue.set(Calendar.YEAR, 1998);
        sendValue.set(Calendar.HOUR_OF_DAY, 23);
        sendValue.set(Calendar.MINUTE, 59);
        sendValue.set(Calendar.SECOND, 59);
        sendValue.set(Calendar.MILLISECOND, 994);

        receiveValue.set(Calendar.MONTH, Calendar.JANUARY);
        receiveValue.set(Calendar.DAY_OF_MONTH, 1);
        receiveValue.set(Calendar.YEAR, 1998);
        receiveValue.set(Calendar.HOUR_OF_DAY, 23);
        receiveValue.set(Calendar.MINUTE, 59);
        receiveValue.set(Calendar.SECOND, 59);
        receiveValue.set(Calendar.MILLISECOND, 993);

        Statement stmt = con.createStatement();
        stmt.execute("create table #dtr5 (data datetime)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("insert into #dtr5 (data) values (?)");
        pstmt.setTimestamp(1, new Timestamp(sendValue.getTime().getTime()));
        assertEquals(pstmt.executeUpdate(), 1);
        pstmt.close();

        pstmt = con.prepareStatement("select data from #dtr5");
        ResultSet rs = pstmt.executeQuery();

        assertTrue(rs.next());
        assertEquals(receiveValue.getTime().getTime(), getTimeInMs(rs));
        assertTrue(!rs.next());

        pstmt.close();
        rs.close();
    }

    /**
     * Test for bug [994916] datetime decoding in TdsData.java
     */
    public void testDatetimeRounding6() throws Exception {
        // Per the SQL Server documentation
        // Send:    01/01/98 23:59:59.995
        // Receive: 01/01/98 23:59:59.997
        Calendar sendValue = Calendar.getInstance();
        Calendar receiveValue = Calendar.getInstance();

        sendValue.set(Calendar.MONTH, Calendar.JANUARY);
        sendValue.set(Calendar.DAY_OF_MONTH, 1);
        sendValue.set(Calendar.YEAR, 1998);
        sendValue.set(Calendar.HOUR_OF_DAY, 23);
        sendValue.set(Calendar.MINUTE, 59);
        sendValue.set(Calendar.SECOND, 59);
        sendValue.set(Calendar.MILLISECOND, 995);

        receiveValue.set(Calendar.MONTH, Calendar.JANUARY);
        receiveValue.set(Calendar.DAY_OF_MONTH, 1);
        receiveValue.set(Calendar.YEAR, 1998);
        receiveValue.set(Calendar.HOUR_OF_DAY, 23);
        receiveValue.set(Calendar.MINUTE, 59);
        receiveValue.set(Calendar.SECOND, 59);
        receiveValue.set(Calendar.MILLISECOND, 997);

        Statement stmt = con.createStatement();
        stmt.execute("create table #dtr6 (data datetime)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("insert into #dtr6 (data) values (?)");
        pstmt.setTimestamp(1, new Timestamp(sendValue.getTime().getTime()));
        assertEquals(pstmt.executeUpdate(), 1);
        pstmt.close();

        pstmt = con.prepareStatement("select data from #dtr6");
        ResultSet rs = pstmt.executeQuery();

        assertTrue(rs.next());
        assertEquals(receiveValue.getTime().getTime(), getTimeInMs(rs));
        assertTrue(!rs.next());

        pstmt.close();
        rs.close();
    }

    /**
     * Test for bug [994916] datetime decoding in TdsData.java
     */
    public void testDatetimeRounding7() throws Exception {
        // Per the SQL Server documentation
        // Send:    01/01/98 23:59:59.996
        // Receive: 01/01/98 23:59:59.997
        Calendar sendValue = Calendar.getInstance();
        Calendar receiveValue = Calendar.getInstance();

        sendValue.set(Calendar.MONTH, Calendar.JANUARY);
        sendValue.set(Calendar.DAY_OF_MONTH, 1);
        sendValue.set(Calendar.YEAR, 1998);
        sendValue.set(Calendar.HOUR_OF_DAY, 23);
        sendValue.set(Calendar.MINUTE, 59);
        sendValue.set(Calendar.SECOND, 59);
        sendValue.set(Calendar.MILLISECOND, 996);

        receiveValue.set(Calendar.MONTH, Calendar.JANUARY);
        receiveValue.set(Calendar.DAY_OF_MONTH, 1);
        receiveValue.set(Calendar.YEAR, 1998);
        receiveValue.set(Calendar.HOUR_OF_DAY, 23);
        receiveValue.set(Calendar.MINUTE, 59);
        receiveValue.set(Calendar.SECOND, 59);
        receiveValue.set(Calendar.MILLISECOND, 997);

        Statement stmt = con.createStatement();
        stmt.execute("create table #dtr7 (data datetime)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("insert into #dtr7 (data) values (?)");
        pstmt.setTimestamp(1, new Timestamp(sendValue.getTime().getTime()));
        assertEquals(pstmt.executeUpdate(), 1);
        pstmt.close();

        pstmt = con.prepareStatement("select data from #dtr7");
        ResultSet rs = pstmt.executeQuery();

        assertTrue(rs.next());
        assertEquals(receiveValue.getTime().getTime(), getTimeInMs(rs));
        assertTrue(!rs.next());

        pstmt.close();
        rs.close();
    }

    /**
     * Test for bug [994916] datetime decoding in TdsData.java
     */
    public void testDatetimeRounding8() throws Exception {
        // Per the SQL Server documentation
        // Send:    01/01/98 23:59:59.997
        // Receive: 01/01/98 23:59:59.997
        Calendar sendValue = Calendar.getInstance();
        Calendar receiveValue = Calendar.getInstance();

        sendValue.set(Calendar.MONTH, Calendar.JANUARY);
        sendValue.set(Calendar.DAY_OF_MONTH, 1);
        sendValue.set(Calendar.YEAR, 1998);
        sendValue.set(Calendar.HOUR_OF_DAY, 23);
        sendValue.set(Calendar.MINUTE, 59);
        sendValue.set(Calendar.SECOND, 59);
        sendValue.set(Calendar.MILLISECOND, 997);

        receiveValue.set(Calendar.MONTH, Calendar.JANUARY);
        receiveValue.set(Calendar.DAY_OF_MONTH, 1);
        receiveValue.set(Calendar.YEAR, 1998);
        receiveValue.set(Calendar.HOUR_OF_DAY, 23);
        receiveValue.set(Calendar.MINUTE, 59);
        receiveValue.set(Calendar.SECOND, 59);
        receiveValue.set(Calendar.MILLISECOND, 997);

        Statement stmt = con.createStatement();
        stmt.execute("create table #dtr8 (data datetime)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("insert into #dtr8 (data) values (?)");
        pstmt.setTimestamp(1, new Timestamp(sendValue.getTime().getTime()));
        assertEquals(pstmt.executeUpdate(), 1);
        pstmt.close();

        pstmt = con.prepareStatement("select data from #dtr8");
        ResultSet rs = pstmt.executeQuery();

        assertTrue(rs.next());
        assertEquals(receiveValue.getTime().getTime(), getTimeInMs(rs));
        assertTrue(!rs.next());

        pstmt.close();
        rs.close();
    }

    /**
     * Test for bug [994916] datetime decoding in TdsData.java
     */
    public void testDatetimeRounding9() throws Exception {
        // Per the SQL Server documentation
        // Send:    01/01/98 23:59:59.998
        // Receive: 01/01/98 23:59:59.997
        Calendar sendValue = Calendar.getInstance();
        Calendar receiveValue = Calendar.getInstance();

        sendValue.set(Calendar.MONTH, Calendar.JANUARY);
        sendValue.set(Calendar.DAY_OF_MONTH, 1);
        sendValue.set(Calendar.YEAR, 1998);
        sendValue.set(Calendar.HOUR_OF_DAY, 23);
        sendValue.set(Calendar.MINUTE, 59);
        sendValue.set(Calendar.SECOND, 59);
        sendValue.set(Calendar.MILLISECOND, 998);

        receiveValue.set(Calendar.MONTH, Calendar.JANUARY);
        receiveValue.set(Calendar.DAY_OF_MONTH, 1);
        receiveValue.set(Calendar.YEAR, 1998);
        receiveValue.set(Calendar.HOUR_OF_DAY, 23);
        receiveValue.set(Calendar.MINUTE, 59);
        receiveValue.set(Calendar.SECOND, 59);
        receiveValue.set(Calendar.MILLISECOND, 997);

        Statement stmt = con.createStatement();
        stmt.execute("create table #dtr9 (data datetime)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("insert into #dtr9 (data) values (?)");
        pstmt.setTimestamp(1, new Timestamp(sendValue.getTime().getTime()));
        assertEquals(pstmt.executeUpdate(), 1);
        pstmt.close();

        pstmt = con.prepareStatement("select data from #dtr9");
        ResultSet rs = pstmt.executeQuery();

        assertTrue(rs.next());
        assertEquals(receiveValue.getTime().getTime(), getTimeInMs(rs));
        assertTrue(!rs.next());

        pstmt.close();
        rs.close();
    }

    /**
     * Test for bug [994916] datetime decoding in TdsData.java
     */
    public void testDatetimeRounding10() throws Exception {
        // Per the SQL Server documentation
        // Send:    01/01/98 23:59:59.999
        // Receive: 01/02/98 00:00:00.000
        Calendar sendValue = Calendar.getInstance();
        Calendar receiveValue = Calendar.getInstance();

        sendValue.set(Calendar.MONTH, Calendar.JANUARY);
        sendValue.set(Calendar.DAY_OF_MONTH, 1);
        sendValue.set(Calendar.YEAR, 1998);
        sendValue.set(Calendar.HOUR_OF_DAY, 23);
        sendValue.set(Calendar.MINUTE, 59);
        sendValue.set(Calendar.SECOND, 59);
        sendValue.set(Calendar.MILLISECOND, 999);

        receiveValue.set(Calendar.MONTH, Calendar.JANUARY);
        receiveValue.set(Calendar.DAY_OF_MONTH, 2);
        receiveValue.set(Calendar.YEAR, 1998);
        receiveValue.set(Calendar.HOUR_OF_DAY, 0);
        receiveValue.set(Calendar.MINUTE, 0);
        receiveValue.set(Calendar.SECOND, 0);
        receiveValue.set(Calendar.MILLISECOND, 0);

        Statement stmt = con.createStatement();
        stmt.execute("create table #dtr10 (data datetime)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("insert into #dtr10 (data) values (?)");
        pstmt.setTimestamp(1, new Timestamp(sendValue.getTime().getTime()));
        assertEquals(pstmt.executeUpdate(), 1);
        pstmt.close();

        pstmt = con.prepareStatement("select data from #dtr10");
        ResultSet rs = pstmt.executeQuery();

        assertTrue(rs.next());
        assertEquals(receiveValue.getTime().getTime(), getTimeInMs(rs));
        assertTrue(!rs.next());

        pstmt.close();
        rs.close();
    }

    /**
     * Test for bug [1036059] getTimestamp with Calendar applies tzone offset
     * wrong way.
     */
    public void testTimestampTimeZone() throws SQLException {
        Statement stmt = con.createStatement();
        stmt.executeUpdate("CREATE TABLE #testTimestampTimeZone ("
                + "ref INT NOT NULL, "
                + "tstamp DATETIME NOT NULL)");
        stmt.close();

        Calendar calNY = Calendar.getInstance
                (TimeZone.getTimeZone("America/New_York"));

        Timestamp tsStart = new Timestamp(System.currentTimeMillis());

        PreparedStatement pstmt = con.prepareStatement(
                "INSERT INTO #testTimestampTimeZone (ref, tstamp) VALUES (?, ?)");
        pstmt.setInt(1, 0);
        pstmt.setTimestamp(2, tsStart, calNY);
        assertEquals(1, pstmt.executeUpdate());
        pstmt.close();

        pstmt = con.prepareStatement(
                "SELECT * FROM #testTimestampTimeZone WHERE ref = ?");
        pstmt.setInt(1, 0);
        ResultSet rs = pstmt.executeQuery();
        assertTrue(rs.next());
        Timestamp ts = rs.getTimestamp("tstamp", calNY);

        // The difference should be less than 3 milliseconds (i.e. 1 or 2)
        assertTrue(Math.abs(tsStart.getTime()-ts.getTime()) < 3);
        rs.close();
        pstmt.close();
    }

    /**
     * Test for bug [1040475] Possible bug when converting to and from
     * datetime.
     * <p>
     * jTDS seems to accept dates outside the range accepted by SQL
     * Server (i.e. 1753-9999).
     */
    public void testTimestampRange() throws SQLException {
        Statement stmt = con.createStatement();
        stmt.executeUpdate(
                "CREATE TABLE #testTimestampRange (id INT, d DATETIME)");

        PreparedStatement pstmt = con.prepareStatement(
                "INSERT INTO #testTimestampRange VALUES (?, ?)");
        pstmt.setInt(1, 1);
        try {
            pstmt.setDate(2, Date.valueOf("0012-03-03")); // This should fail
            pstmt.executeUpdate();
            fail("Expecting an exception to be thrown. Date out of range.");
        } catch (SQLException ex) {
            assertEquals("22003", ex.getSQLState());
        }
        pstmt.close();

        ResultSet rs = stmt.executeQuery("SELECT * FROM #testTimestampRange");
        assertFalse("Row was inserted even though date was out of range.", rs.next());
        rs.close();
        stmt.close();
    }

    /**
     * Test that <code>java.sql.Date</code> objects are inserted and retrieved
     * correctly (ie no time component).
     */
    public void testWriteDate() throws SQLException {
        Statement stmt = con.createStatement();
        stmt.executeUpdate(
                "CREATE TABLE #testWriteDate (d DATETIME)");
        stmt.close();

        long time = System.currentTimeMillis();

        PreparedStatement pstmt = con.prepareStatement(
                "INSERT INTO #testWriteDate VALUES (?)");
        pstmt.setDate(1, new Date(time));
        pstmt.executeUpdate();
        pstmt.close();

        pstmt = con.prepareStatement("SELECT * FROM #testWriteDate WHERE d=?");
        pstmt.setDate(1, new Date(time + 10));
        ResultSet rs = pstmt.executeQuery();
        assertTrue(rs.next());
        assertTrue(time - rs.getDate(1).getTime() < 24 * 60 * 60 * 1000);
        Calendar c1 = new GregorianCalendar(), c2 = new GregorianCalendar();
        c1.setTime(rs.getTimestamp(1));
        c2.setTime(new Timestamp(time));
        assertEquals(c2.get(Calendar.YEAR), c1.get(Calendar.YEAR));
        assertEquals(c2.get(Calendar.MONTH), c1.get(Calendar.MONTH));
        assertEquals(c2.get(Calendar.DAY_OF_MONTH), c1.get(Calendar.DAY_OF_MONTH));
        assertEquals(0, c1.get(Calendar.HOUR));
        assertEquals(0, c1.get(Calendar.MINUTE));
        assertEquals(0, c1.get(Calendar.SECOND));
        assertEquals(0, c1.get(Calendar.MILLISECOND));
        rs.close();
        pstmt.close();

        stmt = con.createStatement();
        rs = stmt.executeQuery("select datepart(hour, d), datepart(minute, d),"
                + " datepart(second, d), datepart(millisecond, d)"
                + " from #testWriteDate");
        assertTrue(rs.next());
        assertEquals(0, rs.getInt(1));
        assertEquals(0, rs.getInt(2));
        assertEquals(0, rs.getInt(3));
        assertEquals(0, rs.getInt(4));
        assertFalse(rs.next());
        rs.close();
        stmt.close();
    }

    /**
     * Test for bug [1226210] {fn dayofweek()} depends on the language.
     */
    public void testDayOfWeek() throws Exception {
        PreparedStatement pstmt =
                con.prepareStatement("SELECT {fn dayofweek({fn curdate()})}");

        // Execute and retrieve the day of week with the default @@DATEFIRST
        ResultSet rs = pstmt.executeQuery();
        assertNotNull(rs);
        assertTrue(rs.next());
        int day = rs.getInt(1);

        // Set a new (very unlikely) value for @@DATEFIRST (Thursday)
        Statement stmt = con.createStatement();
        assertEquals(0, stmt.executeUpdate("SET DATEFIRST 4"));
        stmt.close();

        // Now re-execute and compare the two values
        rs = pstmt.executeQuery();
        assertNotNull(rs);
        assertTrue(rs.next());
        assertEquals(day, rs.getInt(1));

        pstmt.close();
    }

    /**
     * Test for bug [1235845] getTimestamp() returns illegal value after
     * getString().
     */
    public void testGetString() throws SQLException {
        Statement stmt = con.createStatement();

        ResultSet rs = stmt.executeQuery("select getdate()");
        assertTrue(rs.next());
        String stringValue = rs.getString(1);
        String timestampValue = rs.getTimestamp(1).toString();
        assertEquals(stringValue, timestampValue);
        rs.close();

        stmt.close();
    }

    /**
     * Test for bug [1234531] Dates before 01/01/1900 broken due to DateTime
     * value markers.
     */
    public void test1899Date() throws Exception {
        // Per the SQL Server documentation
        // Send:    12/31/1899 23:59:59.990
        // Receive: 12/31/1899 23:59:59.990
        Calendar originalValue = Calendar.getInstance();

        originalValue.set(Calendar.MONTH, Calendar.DECEMBER);
        originalValue.set(Calendar.DAY_OF_MONTH, 31);
        originalValue.set(Calendar.YEAR, 1899);
        originalValue.set(Calendar.HOUR_OF_DAY, 23);
        originalValue.set(Calendar.MINUTE, 59);
        originalValue.set(Calendar.SECOND, 59);
        originalValue.set(Calendar.MILLISECOND, 990);

        PreparedStatement pstmt = con.prepareStatement("select ?");
        pstmt.setTimestamp(1, new Timestamp(originalValue.getTime().getTime()));
        ResultSet rs = pstmt.executeQuery();

        assertTrue(rs.next());
        final long expectedTime = originalValue.getTime().getTime();
        final long actualTime = getTimeInMs(rs);
        assertEquals(expectedTime, actualTime);
        assertFalse(rs.next());

        rs.close();
        pstmt.close();
    }

    /**
     * Java 1.3 Timestamp.getDate() does not add the nano seconds to
     * the millisecond value returned. This causes the timestamp tests
     * to fail. If running under java 1.3 we add the nanos ourselves.
     *
     * @param rs the result set returning the Timstamp value in column 1
     * @return the millisecond date value as a <code>long</code>.
     */
    public long getTimeInMs(ResultSet rs)
            throws SQLException {
        Timestamp value = rs.getTimestamp(1);
        long ms = value.getTime();
        if (!Driver.JDBC3) {
            // Not Running under 1.4 so need to add milliseconds
            ms += ((java.sql.Timestamp)value).getNanos() / 1000000;
        }
        return ms;
    }
    
    /**
     * Test for bug [2508201], date field is changed by 3 milliseconds.
     *
     * Note: This test will fail for some server types due to "DATE" and "TIME"
     * data types not being available.
     */
    public void testDateTimeDegeneration() throws Exception {
       Timestamp ts1 = Timestamp.valueOf("1970-01-01 00:00:00.000");

       String[] types = new String[] {"datetime","date","time"};

       for (int t = 0; t < types.length; t++) {
           String type = types[t];
           // create table and insert initial value
           Statement stmt = con.createStatement();
           stmt.execute("create table #t_" + type + " (id int,data " + type + ")");
           stmt.execute("insert into #t_" + type + " values (0,'" + ts1.toString() + "')");

           PreparedStatement ps1 = con.prepareStatement("update #t_" + type + " set data=? where id=0");
           PreparedStatement ps2 = con.prepareStatement("select data from #t_" + type);
   
            // read previous value
            ResultSet rs = ps2.executeQuery();
            rs.next();
            Timestamp ts2 = rs.getTimestamp(1);

            // compare current value to initial value 
            assertEquals(type + " value degenerated: ", ts1.toString(), ts2.toString());
            rs.close();

            // update DB with current value
            ps1.setTimestamp(1, ts2);
            ps1.executeUpdate();
   
            ps1.close();
            ps2.close();
            stmt.close();
        }
    }

    public void testEscaping() throws SQLException {
        Statement st = con.createStatement();
        ResultSet rs = st.executeQuery("SELECT 'a',{ts '2007-10-19 10:20:30.000'}");

        assertTrue(rs.next());
        assertEquals("2007-10-19 10:20:30.000", rs.getString(2).toString());
        assertEquals("2007-10-19 10:20:30.000", rs.getTimestamp(2).toString());

        rs.close();
        st.close();
    }

    /**
     * Test for bugs [2181003]/[2349058], an attempt to set a BC date
     * invalidates driver state/DateTime allows invalid dates through.
     */
    public void testEra() throws SQLException {
        Statement st = con.createStatement();
        st.execute("create table #testEra(data datetime)");
        st.close();

        String date = "2000-11-11";
        Date original = Date.valueOf(date);
        PreparedStatement in = con.prepareStatement("insert into #testEra values(?)");
        PreparedStatement out = con.prepareStatement("select * from #testEra");
        ResultSet rs = null;

        // insert valid value
        in.setDate(1, Date.valueOf(date));
        in.execute();

        // check timestamp
        rs = out.executeQuery();
        assertTrue(rs.next());
        assertEquals(original,rs.getDate(1));
        rs.close();

        // attempt to set invalid BC date (January 1st, 300 BC)
        try {
            GregorianCalendar gc = new GregorianCalendar();
            gc.set(GregorianCalendar.ERA, GregorianCalendar.BC);
            gc.set(GregorianCalendar.YEAR, 300);
            gc.set(GregorianCalendar.MONTH,GregorianCalendar.JANUARY);
            gc.set(GregorianCalendar.DAY_OF_MONTH, 1);
            in.setDate(1, new Date(gc.getTime().getTime()));

            assertTrue("invalid date should cause an exception", false);
        } catch( SQLException e ) {
            // expected error
        }

        // re-check timestamp
        rs = out.executeQuery();
        assertTrue(rs.next());
        assertEquals(original,rs.getDate(1));
        rs.close();

        in.close();
        out.close();
    }

}