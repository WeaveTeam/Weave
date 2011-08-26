// jTDS JDBC Driver for Microsoft SQL Server and Sybase
// Copyright (C) 2005 The jTDS Project
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
import java.util.GregorianCalendar;
import java.util.TimeZone;

import net.sourceforge.jtds.jdbc.Support;

/**
 * Tests timezone conversions when setting and getting data to and from the
 * database.
 *
 * @author Mike Hutchinson
 */
public class TimeZoneTest extends TestBase {

    public TimeZoneTest(String name) {
        super(name);
    }

    /**
     * Test timezone calendar conversions. This test produces the same results
     * when run with both jConnect 6.0 and the MS JDBC driver.
     */
    public void testTimeZone() throws Exception {
        TimeZone zone = TimeZone.getDefault();
        try {
            Statement stmt = con.createStatement();
            stmt.execute(
                    "CREATE TABLE #TEST (d datetime, t datetime, ts datetime)");
            PreparedStatement pstmt =
                    con.prepareStatement("INSERT INTO #TEST VALUES(?, ?, ?) ");
            TimeZone tz1 = TimeZone.getTimeZone("America/New_York");
            GregorianCalendar calNY = new GregorianCalendar(tz1);
            GregorianCalendar originalCalNY = new GregorianCalendar(tz1);
            originalCalNY.setTime(calNY.getTime());
            //
            // Store date/times with local time zone
            //
            Date date = Date.valueOf("2005-04-06");
            Time time = Time.valueOf("09:55:30");
            Timestamp ts = Timestamp.valueOf("2005-04-06 09:55:30.123");
            pstmt.setDate(1, date);
            pstmt.setTime(2, time);
            pstmt.setTimestamp(3, ts);
            assertEquals(1, pstmt.executeUpdate());
            //
            // Store date/times with other time zone
            //
            pstmt.setDate(1, date, calNY);
            assertEquals(originalCalNY, calNY);
            pstmt.setTime(2, time, calNY);
            assertEquals(originalCalNY, calNY);
            pstmt.setTimestamp(3, ts, calNY);
            assertEquals(originalCalNY, calNY);
            assertEquals(1, pstmt.executeUpdate());
            assertEquals(1, pstmt.executeUpdate());
            //
            // Read back
            //
            ResultSet rs = stmt.executeQuery("SELECT * FROM #TEST");
            assertTrue(rs.next());
            //
            // Check local time zone gets back what we stored
            //
            assertEquals("2005-04-06", rs.getDate(1).toString());
            assertEquals("09:55:30", rs.getTime(2).toString());
            assertEquals("2005-04-06 09:55:30.123",
                    rs.getTimestamp(3).toString());
            assertTrue(rs.next());
            //
            // Check date/times stored with other zone are changed when read
            // back with local.
            // The date changes because the JDBC Date has time set to 0:0:0 so
            // the change of zone moves us back a day.
            // The time moves for me because the JDBC Time has the date set to
            // 1970-01-01 and in 1970 the "europe/london" time zone was
            // experimenting with permanent daylight saving time! If you are
            // running this test anywhere other than the UK you will find that
            // the time is the same as the time component of the timestamp.
            // Note both the other drivers I tested exhibit the same behaviour.
            //
            assertEquals(new Date(Support.timeFromZone(date, calNY)).toString(),
                    rs.getDate(1).toString());
            assertEquals(originalCalNY, calNY);
            assertEquals(new Time(Support.timeFromZone(time, calNY)).toString(),
                    rs.getTime(2).toString());
            assertEquals(originalCalNY, calNY);
            assertEquals(new Timestamp(Support.timeFromZone(ts, calNY)).toString(),
                    rs.getTimestamp(3).toString());
            assertEquals(originalCalNY, calNY);
            assertTrue(rs.next());
            //
            // Check date/times stored with other zone are unchanged when read
            // back with other zone
            //
            assertEquals("2005-04-05", rs.getDate(1, calNY).toString());
            assertEquals(originalCalNY, calNY);
            assertEquals("09:55:30", rs.getTime(2, calNY).toString());
            assertEquals(originalCalNY, calNY);
            assertEquals("2005-04-06 09:55:30.123", rs.getTimestamp(3, calNY).toString());
            assertEquals(originalCalNY, calNY);
        } finally {
            TimeZone.setDefault(zone);
        }
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(TimeZoneTest.class);
    }
}
