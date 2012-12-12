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

package net.sourceforge.jtds.test;

import java.sql.SQLException;
import java.sql.Statement;

/**
 * @version 1.0
 */
public class StatementTest extends TestBase {

    public StatementTest(String name) {
        super(name);
    }

    /**
     * Test for bug [1694194], queryTimeout does not work on MSSQL2005 when
     * property 'useCursors' is set to 'true'. Furthermore, the test also
     * checks timeout with a query that cannot use a cursor. <p>
     *
     * This test requires property 'queryTimeout' to be set to true.
     */
    public void testQueryTimeout() throws Exception {
        Statement st = con.createStatement();
        st.setQueryTimeout(1);

        st.execute("create procedure #testTimeout as begin waitfor delay '00:00:30'; select 1; end");

        long start = System.currentTimeMillis();
        try {
            // this query doesn't use a cursor
            st.executeQuery("exec #testTimeout");
            fail("query did not time out");
        } catch (SQLException e) {
            assertEquals("HYT00", e.getSQLState());
            assertEquals(1000, System.currentTimeMillis() - start, 10);
        }

        st.execute("create table #dummy1(A varchar(200))");
        st.execute("create table #dummy2(B varchar(200))");
        st.execute("create table #dummy3(C varchar(200))");

        // create test data
        con.setAutoCommit(false);
        for(int i = 0; i < 100; i++) {
            st.execute("insert into #dummy1 values('" + i + "')");
            st.execute("insert into #dummy2 values('" + i + "')");
            st.execute("insert into #dummy3 values('" + i + "')");
        }
        con.commit();
        con.setAutoCommit(true);

        start = System.currentTimeMillis();
        try {
            // this query can use a cursor
            st.executeQuery("select * from #dummy1, #dummy2, #dummy3 order by A desc, B asc, C desc");
            fail("query did not time out");
        } catch (SQLException e) {
            assertEquals("HYT00", e.getSQLState());
            assertEquals(1000, System.currentTimeMillis() - start, 10);
        }

        st.close();
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(StatementTest.class);
    }

}