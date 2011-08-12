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
import java.io.*;

/**
 * Test case to illustrate use of READTEXT for text and image columns.
 *
 * @version 1.0
 */
public class ReadTextTest extends TestBase {
    public ReadTextTest(String name) {
        super(name);
    }

    public void testReadText() throws Exception {
        byte[] byteBuf = new byte[5000]; // Just enough to require more than one READTEXT

        for (int i = 0; i < byteBuf.length; i++) {
            byteBuf[i] = (byte) i;
        }

        StringBuffer strBuf = new StringBuffer(5000);

        for (int i = 0; i < 100; i++) {
            strBuf.append("This is a test line of text that is 50 chars    ");

            if (i < 10) {
                strBuf.append('0');
            }

            strBuf.append(i);
        }

        String data = strBuf.toString();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #TEST (id int, t1 text, t2 ntext, t3 image)");

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #TEST (id, t1, t2, t3) VALUES (?, ?, ?, ?)");

        pstmt.setInt(1, 1);

        try {
            pstmt.setAsciiStream(2, new ByteArrayInputStream(strBuf.toString().getBytes("US-ASCII")), strBuf.length());
            pstmt.setCharacterStream(3, new StringReader(strBuf.toString()), strBuf.length());
            pstmt.setBinaryStream(4, new ByteArrayInputStream(byteBuf), byteBuf.length);
        } catch (UnsupportedEncodingException e) {
            // Should never happen
        }

        assertEquals("First insert failed", 1, pstmt.executeUpdate());
        pstmt.setInt(1, 2);

        try {
            pstmt.setCharacterStream(2, new StringReader(strBuf.toString()), strBuf.length());
            pstmt.setAsciiStream(3, new ByteArrayInputStream(strBuf.toString().getBytes("US-ASCII")), strBuf.length());
            pstmt.setBinaryStream(4, new ByteArrayInputStream(byteBuf), byteBuf.length);
        } catch (UnsupportedEncodingException e) {
            // Should never happen
        }

        assertEquals("Second insert failed", 1, pstmt.executeUpdate());

        // Read back the normal way
        ResultSet rs = stmt.executeQuery("SELECT * FROM #TEST");
        validateReadTextResult(rs, data, byteBuf);


        // Read back using READTEXT
        // FIXME - Trigger use of READTEXT
        rs = stmt.executeQuery("SELECT * FROM #TEST");
        validateReadTextResult(rs, data, byteBuf);

        pstmt.close();
        stmt.close();
    }

    private void validateReadTextResult(ResultSet rs, String data, byte[] byteBuf)
    throws Exception {
        assertNotNull(rs);

        while (rs.next()) {
            switch (rs.getInt(1)) {
                case 1:
                    InputStream in = rs.getAsciiStream(2);
                    compareInputStreams(new ByteArrayInputStream(data.getBytes("ASCII")), in);

                    Clob clob = rs.getClob(2);

                    // Check the clob stream 3 times to ensure the stream is being
                    // reset properly
                    for (int count = 0; count < 3; count++) {
                        in = clob.getAsciiStream();
                        compareInputStreams(new ByteArrayInputStream(data.getBytes("ASCII")), in);
                    }

                    Reader rin = rs.getCharacterStream(3);
                    compareReaders(new StringReader(data), rin);

                    clob = rs.getClob(3);

                    // Check the clob stream 3 times to ensure the stream is being
                    // reset properly
                    for (int count = 0; count < 3; count++) {
                        rin = clob.getCharacterStream();
                        compareReaders(new StringReader(data), rin);
                    }

                    in = rs.getBinaryStream(4);
                    compareInputStreams(new ByteArrayInputStream(byteBuf), in);

                    Blob blob = rs.getBlob(4);

                    // Check the blob stream 3 times to ensure the stream is being
                    // reset properly
                    for (int count = 0; count < 3; count++) {
                        in = blob.getBinaryStream();
                        compareInputStreams(new ByteArrayInputStream(byteBuf), in);
                    }

                    break;
                case 2:
                    rin = rs.getCharacterStream(2);
                    compareReaders(new StringReader(data), rin);

                    clob = rs.getClob(2);

                    // Check the clob stream 3 times to ensure the stream is being
                    // reset properly
                    for (int count = 0; count < 3; count++) {
                        rin = clob.getCharacterStream();
                        compareReaders(new StringReader(data), rin);
                    }

                    in = rs.getAsciiStream(3);
                    compareInputStreams(new ByteArrayInputStream(data.getBytes("ASCII")), in);

                    clob = rs.getClob(3);

                    // Check the clob stream 3 times to ensure the stream is being
                    // reset properly
                    for (int count = 0; count < 3; count++) {
                        in = clob.getAsciiStream();
                        compareInputStreams(new ByteArrayInputStream(data.getBytes("ASCII")), in);
                    }

                    in = rs.getBinaryStream(4);
                    compareInputStreams(new ByteArrayInputStream(byteBuf), in);

                    blob = rs.getBlob(4);

                    // Check the blob stream 3 times to ensure the stream is being
                    // reset properly
                    for (int count = 0; count < 3; count++) {
                        in = blob.getBinaryStream();
                        compareInputStreams(new ByteArrayInputStream(byteBuf), in);
                    }

                    break;
            }
        }

        rs.close();
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(ReadTextTest.class);
    }
}
