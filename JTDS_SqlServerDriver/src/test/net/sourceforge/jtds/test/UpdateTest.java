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
 * @author Alin Sinpalean
 * @version $Id: UpdateTest.java,v 1.9.2.1 2009-08-04 10:33:54 ickzon Exp $
 * @created    March 17, 2001
 */
public class UpdateTest extends TestBase {

    public UpdateTest(String name) {
        super(name);
    }

    public void testTemp() throws Exception {
        Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);

        stmt.execute("CREATE TABLE #temp (pk INT PRIMARY KEY, f_string VARCHAR(30), f_float FLOAT)");

        // populate in the traditional way
        final int count = 100;
        for (int i = 0; i < count; i++) {
            stmt.execute(
                "INSERT INTO #temp "
                + "VALUES( " + i
                + "," +  "'The String " + i + "'"
                + ", " + i + ")"
            );
        }

        dump(stmt.executeQuery("SELECT Count(*) FROM #temp"));

        //Navigate around
        ResultSet rs = stmt.executeQuery("SELECT * FROM #temp");

        assertTrue(rs.first());
        assertEquals(1, rs.getRow());
        assertTrue(rs.last());
        assertEquals(count, rs.getRow());
        assertTrue(rs.first());
        assertEquals(1, rs.getRow());

        rs.close();
        stmt.close();
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(UpdateTest.class);
    }
}
