//jTDS JDBC Driver for Microsoft SQL Server and Sybase
//Copyright (C) 2004 The jTDS Project
//
//This library is free software; you can redistribute it and/or
//modify it under the terms of the GNU Lesser General Public
 //License as published by the Free Software Foundation; either
//version 2.1 of the License, or (at your option) any later version.
//
//This library is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//Lesser General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public
//License along with this library; if not, write to the Free Software
//Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
package net.sourceforge.jtds.test;

import java.io.*;
import java.sql.*;

import junit.framework.Test;
import junit.framework.TestSuite;

/**
 * @version 1.0
 */
public class LargeLOBTest extends TestBase {
    private static final int LOB_LENGTH = 100000000;

    /**
     * Only run the test suite if the "jTDS.runLargeLOBTest" system property is defined, as the test takes A LOT of time
     * to execute.
     */
    public static Test suite() {
        if (System.getProperty("jTDS.runLargeLOBTest") == null) {
            return new TestSuite();
        }

        return new TestSuite(LargeLOBTest.class);
    }

    public LargeLOBTest(String name) {
        super(name);
    }

    /*************************************************************************
     *************************************************************************
     **                          BLOB TESTS                                 **
     *************************************************************************
     *************************************************************************/

    /**
     * Test for bug [945507] closing statement after selecting a large IMAGE - Exception
     */
    public void testLargeBlob1() throws Exception {
    	File data = File.createTempFile("blob", ".tmp");
        data.deleteOnExit();

    	FileOutputStream fos = new FileOutputStream(data);
    	BufferedOutputStream bos = new BufferedOutputStream(fos);

        byte buf[] = new byte[256];

        for (int i = 0; i < 256; i++) {
            buf[i] = (byte) i;
        }

    	for (int i = 0; i < LOB_LENGTH; i += buf.length) {
    		bos.write(buf);
    	}
        bos.write(buf, 0, LOB_LENGTH % buf.length);

    	bos.close();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #largeblob1 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #largeblob1 (data) VALUES (?)");
    	FileInputStream fis = new FileInputStream(data);
    	BufferedInputStream bis = new BufferedInputStream(fis);

        // Test PreparedStatement.setBinaryStream()
        pstmt.setBinaryStream(1, bis, LOB_LENGTH);
        assertTrue(pstmt.executeUpdate() == 1);

        pstmt.close();
        bis.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #largeblob1");

        assertTrue(rs.next());

    	fis = new FileInputStream(data);
    	bis = new BufferedInputStream(fis);

        // Test ResultSet.getBinaryStream()
        compareInputStreams(bis, rs.getBinaryStream(1));
        bis.close();

        assertFalse(rs.next());
        stmt2.close();
        rs.close();

        assertTrue(data.delete());
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(LOBTest.class);
    }
}