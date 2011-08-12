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
import java.util.*;

//
// MJH - Changes for new jTDS version
// Amended many lines such as those in testBlobSetNull6
// where ResultSet variable rs was used when rs2 is actually required.
// Amazed old version did not fail also as rs was closed!
// Changed get / set UnicodeStream tests to align with standard.
//
/**
 * @version $Id: LOBTest.java,v 1.27.2.1 2009-07-25 12:57:37 ickzon Exp $
 */
public class LOBTest extends TestBase {
    private static final int LOB_LENGTH = 8000;
    private static final byte[] blobData = new byte[LOB_LENGTH];
    private static final byte[] newBlobData = new byte[LOB_LENGTH];
    private static final String clobData;
    private static final String newClobData;

    static {
        for (int i = 0; i < blobData.length; i++) {
            blobData[i] = (byte) (Math.random() * 255);
            newBlobData[i] = (byte) (Math.random() * 255);
        }

        StringBuffer data = new StringBuffer();
        StringBuffer newData = new StringBuffer();

        for (int i = 0; i < LOB_LENGTH; i++) {
            data.append((char) (Math.random() * 58) + 32);
            newData.append((char) (Math.random() * 58) + 32);
        }

        clobData = data.toString();
        newClobData = newData.toString();
    }

    public LOBTest(String name) {
        super(name);
    }

    /*************************************************************************
     *************************************************************************
     **                          BLOB TESTS                                 **
     *************************************************************************
     *************************************************************************/

    public void testBlobGet1() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobget1 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobget1 (data) VALUES (?)");

        // Test PreparedStatement.setBytes()
        pstmt.setBytes(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobget1");

        assertTrue(rs.next());

        // Test ResultSet.getBytes()
        assertTrue(Arrays.equals(data, rs.getBytes(1)));

        // Test ResultSet.getBinaryStream()
        InputStream is = rs.getBinaryStream(1);
        byte[] isTmpData = new byte[data.length];

        assertEquals(data.length, is.read(isTmpData));
        assertEquals(-1, is.read());
        assertTrue(Arrays.equals(data, isTmpData));

        // Test ResultSet.getBlob()
        Blob blob = rs.getBlob(1);

        assertNotNull(blob);

        // Test Blob.length()
        assertEquals(blob.length(), data.length);

        // Test Blob.getBytes(0, length); should fail
        try {
            blob.getBytes(0L, (int) blob.length());
            fail("Blob.getBytes(0, length) should fail.");
        } catch (SQLException ex) {
            assertEquals("HY090", ex.getSQLState());
        }

        // Test Blob.getBytes()
        byte[] tmpData2 = blob.getBytes(1L, (int) blob.length());

        assertTrue(Arrays.equals(data, tmpData2));

        // Test Blob.getBinaryStream()
        InputStream is2 = blob.getBinaryStream();
        compareInputStreams(new ByteArrayInputStream(data), is2);

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobGet2() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobget2 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobget2 (data) VALUES (?)");

        // Test PreparedStatement.setBinaryStream()
        pstmt.setBinaryStream(1, new ByteArrayInputStream(data), data.length);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobget2");

        assertTrue(rs.next());

        // Test ResultSet.getObject() - Blob
        Object result = rs.getObject(1);

        assertTrue(result instanceof Blob);

        Blob blob = (Blob) result;

        assertEquals(data.length, blob.length());

        // Test Blob.getBytes()
        assertTrue(Arrays.equals(data, blob.getBytes(1L, (int) blob.length())));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobSet1() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobset1 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobset1 (data) VALUES (?)");

        // Test PreparedStatement.setBinaryStream()
        pstmt.setBinaryStream(1, new ByteArrayInputStream(data), data.length);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobset1");

        assertTrue(rs.next());

        // Test ResultSet.getBytes()
        assertTrue(Arrays.equals(data, rs.getBytes(1)));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobSet2() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobset2 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobset2 (data) VALUES (?)");

        // Test PreparedStatement.setBytes()
        pstmt.setBytes(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobset2");

        assertTrue(rs.next());

        Blob blob = rs.getBlob(1);

        data = getNewBlobTestData();

        // Test Blob.setBytes()
        blob.setBytes(1, data);

        assertTrue(Arrays.equals(data, blob.getBytes(1L, (int) blob.length())));

        assertFalse(rs.next());

        PreparedStatement pstmt2 = con.prepareStatement("UPDATE #blobset2 SET data = ?");

        // Test PreparedStatement.setBlob()
        pstmt2.setBlob(1, blob);
        assertEquals(1, pstmt2.executeUpdate());

        pstmt2.close();

        stmt2.close();
        rs.close();

        Statement stmt3 = con.createStatement();
        ResultSet rs2 = stmt3.executeQuery("SELECT data FROM #blobset2");

        assertTrue(rs2.next());

        // Test ResultSet.getBytes()
        assertTrue(Arrays.equals(data, rs2.getBytes(1)));

        assertFalse(rs2.next());
        stmt3.close();
        rs2.close();
    }

    public void testBlobSet3() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobset3 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobset3 (data) VALUES (?)");

        // Test PreparedStatement.setObject(int,byte[])
        pstmt.setObject(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobset3");

        assertTrue(rs.next());

        // Test ResultSet.getBytes()
        assertTrue(Arrays.equals(data, rs.getBytes(1)));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobSet4() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobset4 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobset4 (data) VALUES (?)");

        // Test PreparedStatement.setBytes()
        pstmt.setBytes(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobset4");

        assertTrue(rs.next());

        Blob blob = rs.getBlob(1);

        data = getNewBlobTestData();

        // Test Blob.setBytes()
        blob.setBytes(1, data);

        assertTrue(Arrays.equals(data, blob.getBytes(1L, (int) blob.length())));

        assertFalse(rs.next());

        PreparedStatement pstmt2 = con.prepareStatement("UPDATE #blobset4 SET data = ?");

        // Test PreparedStatement.setObject(int,Blob)
        pstmt2.setObject(1, blob);
        assertEquals(1, pstmt2.executeUpdate());

        pstmt2.close();

        stmt2.close();
        rs.close();

        Statement stmt3 = con.createStatement();
        ResultSet rs2 = stmt3.executeQuery("SELECT data FROM #blobset4");

        assertTrue(rs2.next());

        // Test ResultSet.getBytes()
        assertTrue(Arrays.equals(data, rs2.getBytes(1)));

        assertFalse(rs2.next());
        stmt3.close();
        rs2.close();
    }

    public void testBlobSet5() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobset5 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobset5 (data) VALUES (?)");

        // Test PreparedStatement.setObject(int,byte[],int)
        pstmt.setObject(1, data, Types.BINARY);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobset5");

        assertTrue(rs.next());

        // Test ResultSet.getBytes()
        assertTrue(Arrays.equals(data, rs.getBytes(1)));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobSet6() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobset6 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobset6 (data) VALUES (?)");

        // Test PreparedStatement.setObject(int,byte[],int)
        pstmt.setObject(1, data, Types.VARBINARY);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobset6");

        assertTrue(rs.next());

        // Test ResultSet.getBytes()
        assertTrue(Arrays.equals(data, rs.getBytes(1)));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobSet7() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobset7 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobset7 (data) VALUES (?)");

        // Test PreparedStatement.setBytes()
        pstmt.setBytes(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobset7");

        assertTrue(rs.next());

        Blob blob = rs.getBlob(1);

        data = getNewBlobTestData();

        // Test Blob.setBytes()
        blob.setBytes(1, data);

        assertTrue(Arrays.equals(data, blob.getBytes(1L, (int) blob.length())));

        assertFalse(rs.next());

        PreparedStatement pstmt2 = con.prepareStatement("UPDATE #blobset7 SET data = ?");

        // Test PreparedStatement.setObject(int,Blob,int)
        pstmt2.setObject(1, blob, Types.BLOB);
        assertEquals(1, pstmt2.executeUpdate());

        pstmt2.close();

        stmt2.close();
        rs.close();

        Statement stmt3 = con.createStatement();
        ResultSet rs2 = stmt3.executeQuery("SELECT data FROM #blobset7");

        assertTrue(rs2.next());

        // Test ResultSet.getBytes()
        assertTrue(Arrays.equals(data, rs2.getBytes(1)));

        assertFalse(rs2.next());
        stmt3.close();
        rs2.close();
    }

    /**
     * Test inserting from an <code>InputStream</code> that doesn't fill the
     * buffer on <code>read()</code>.
     * <p>
     * For bug #1008816 - "More data in stream ..." error when inserting an image.
     *
     * @throws Exception if an error condition occurs
     */
    public void testBlobSet8() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobset8 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobset8 (data) VALUES (?)");

        // Test PreparedStatement.setBinaryStream()
        pstmt.setBinaryStream(1, new RealInputStream(), RealInputStream.LENGTH);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobset8");

        assertTrue(rs.next());

        // Test ResultSet.getBinaryStream()
        compareInputStreams(new RealInputStream(), rs.getBinaryStream(1));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobUpdate1() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobupdate1 (id NUMERIC IDENTITY, data IMAGE, "
                     + "CONSTRAINT pk_blobupdate1 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #blobupdate1");

        rs.moveToInsertRow();

        // Test ResultSet.updateBytes()
        rs.updateBytes(2, data);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #blobupdate1");

        assertTrue(rs2.next());

        // Test ResultSet.getBytes()
        assertTrue(Arrays.equals(data, rs2.getBytes(1)));

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testBlobUpdate2() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobupdate2 (id NUMERIC IDENTITY, data IMAGE, "
                     + "CONSTRAINT pk_blobupdate2 PRIMARY KEY CLUSTERED (id))");
        stmt.close();


        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #blobupdate2");

        rs.moveToInsertRow();

        // Test ResultSet.updateBinaryStream()
        rs.updateBinaryStream(2, new ByteArrayInputStream(data), data.length);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #blobupdate2");

        assertTrue(rs2.next());

        // Test ResultSet.getBytes()
        assertTrue(Arrays.equals(data, rs2.getBytes(1)));

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testBlobUpdate3() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobupdate3 (id NUMERIC IDENTITY, data IMAGE, "
                     + "CONSTRAINT pk_blobupdate3 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobupdate3 (data) VALUES (?)");

        // Test PreparedStatement.setBytes()
        pstmt.setBytes(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobupdate3");

        assertTrue(rs.next());

        Blob blob = rs.getBlob(1);

        data = getNewBlobTestData();

        // Test Blob.setBytes()
        blob.setBytes(1, data);

        assertTrue(Arrays.equals(data, blob.getBytes(1L, (int) blob.length())));

        assertFalse(rs.next());

        Statement stmt3 = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs2 = stmt3.executeQuery("SELECT id, data FROM #blobupdate3");

        assertTrue(rs2.next());

        // Test ResultSet.updateBlob()
        rs2.updateBlob(2, blob);

        rs2.updateRow();

        assertFalse(rs2.next());

        stmt2.close();
        rs.close();

        stmt3.close();
        rs2.close();

        Statement stmt4 = con.createStatement();
        ResultSet rs3 = stmt4.executeQuery("SELECT data FROM #blobupdate3");

        assertTrue(rs3.next());

        // Test ResultSet.getBytes()
        assertTrue(Arrays.equals(data, rs3.getBytes(1)));

        assertFalse(rs3.next());
        stmt4.close();
        rs3.close();
    }

    public void testBlobUpdate4() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobupdate4 (id NUMERIC IDENTITY, data IMAGE, "
                     + "CONSTRAINT pk_blobupdate4 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobupdate4 (data) VALUES (?)");

        // Test PreparedStatement.setBytes()
        pstmt.setBytes(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobupdate4");

        assertTrue(rs.next());

        Blob blob = rs.getBlob(1);

        data = getNewBlobTestData();

        // Test Blob.setBytes()
        blob.setBytes(1, data);

        assertTrue(Arrays.equals(data, blob.getBytes(1L, (int) blob.length())));

        assertFalse(rs.next());

        Statement stmt3 = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs2 = stmt3.executeQuery("SELECT id, data FROM #blobupdate4");

        assertTrue(rs2.next());

        // Test ResultSet.updateBlob()
        rs2.updateObject(2, blob);

        rs2.updateRow();

        assertFalse(rs2.next());

        stmt2.close();
        rs.close();

        stmt3.close();
        rs2.close();

        Statement stmt4 = con.createStatement();
        ResultSet rs3 = stmt4.executeQuery("SELECT data FROM #blobupdate4");

        assertTrue(rs3.next());

        // Test ResultSet.getBytes()
        assertTrue(Arrays.equals(data, rs3.getBytes(1)));

        assertFalse(rs3.next());
        stmt4.close();
        rs3.close();
    }

    /**
     * Test Long blob manipulation including updates to the middle of the
     * <code>Blob</code>.
     */
    public void testBlobUpdate5() throws Exception {
        byte[] data = new byte[100000];
        for (int i = 0; i < data.length; i++) {
            data[i] = (byte)('A'+i%10);
        }
        //
        // Construct a blob
        //
        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT 0x00");
        assertNotNull(rs);
        assertTrue(rs.next());
        Blob blob = rs.getBlob(1);
        blob.setBytes(1, data);
        byte[] tmp = blob.getBytes(1, (int)blob.length());
        assertTrue(compare(data, tmp));
        blob.setBytes(1, data);
        tmp = blob.getBytes(1, (int)blob.length());
        assertTrue(compare(data, tmp));
        data[100] = 'a';
        data[101] = 'b';
        blob.setBytes(101, data, 100, 2);
        tmp = blob.getBytes(1, (int)blob.length());
        assertTrue(compare(data, tmp));
        InputStream is = blob.getBinaryStream();
        tmp = new byte[data.length];
        int b;
        int p = 0;
        while ((b = is.read()) >= 0) {
            tmp[p++] = (byte)b;
        }
        is.close();
        assertTrue(compare(data, tmp));
        tmp = blob.getBytes(101, 2);
        assertTrue(compare(new byte[]{'a','b'}, tmp));
        blob = rs.getBlob(1);
        OutputStream os = blob.setBinaryStream(1);
        for (int i = 0; i < data.length; i++) {
            os.write(('A'+i%10));
        }
        os.close();
        os = blob.setBinaryStream(101);
        os.write('a');
        os.write('b');
        os.close();
        tmp = blob.getBytes(1, (int)blob.length());
        assertTrue(compare(data, tmp));
        tmp = new byte[5000];
        for (int i = 0; i < 5000; i++) {
            tmp[i] = (byte)(0x80 + (i % 10));
        }
        blob.setBytes(100000-5000, tmp);
        assertTrue(compare(tmp, blob.getBytes(100000-5000, 5000)));
        assertEquals(100000L, blob.length());
        assertEquals(100000-5000, blob.position(tmp, 100000-5000));
        Blob blob2 = rs.getBlob(1);
        blob2.setBytes(1, tmp);
        assertEquals(100000-5000, blob.position(blob2, 1));
        assertEquals(101, blob.position(new byte[]{'a','b'}, 1));
        blob.truncate(10);
        assertEquals(10L, blob.length());
        tmp = new byte[10];
        System.arraycopy(data, 0, tmp, 0, 10);
        assertTrue(compare(tmp, blob.getBytes(1, (int)blob.length())));
    }

    public void testBlobSetNull1() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobsetnull1 (data IMAGE NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobsetnull1 (data) VALUES (?)");

        // Test PreparedStatement.setBinaryStream()
        pstmt.setBinaryStream(1, null, 0);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobsetnull1");

        assertTrue(rs.next());

        // Test ResultSet.getBinaryStream()
        assertNull(rs.getBinaryStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getBlob()
        assertNull(rs.getBlob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getBytes()
        assertNull(rs.getBytes(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobSetNull2() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobsetnull2 (data IMAGE NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobsetnull2 (data) VALUES (?)");

        // Test PreparedStatement.setBlob()
        pstmt.setBlob(1, (Blob)null);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobsetnull2");

        assertTrue(rs.next());

        // Test ResultSet.getBinaryStream()
        assertNull(rs.getBinaryStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getBlob()
        assertNull(rs.getBlob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getBytes()
        assertNull(rs.getBytes(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobSetNull3() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobsetnull3 (data IMAGE NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobsetnull3 (data) VALUES (?)");

        // Test PreparedStatement.setBytes()
        pstmt.setBytes(1, null);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobsetnull3");

        assertTrue(rs.next());

        // Test ResultSet.getBinaryStream()
        assertNull(rs.getBinaryStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getBlob()
        assertNull(rs.getBlob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getBytes()
        assertNull(rs.getBytes(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    /**
     * Test for bug [985956] Cannot setObject(null) on image.
     */
    public void testBlobSetNull4() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobsetnull4 (data IMAGE NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobsetnull4 (data) VALUES (?)");

        // Test PreparedStatement.setObject(int,Object)
        pstmt.setObject(1, null);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobsetnull4");

        assertTrue(rs.next());

        // Test ResultSet.getBinaryStream()
        assertNull(rs.getBinaryStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getBlob()
        assertNull(rs.getBlob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getBytes()
        assertNull(rs.getBytes(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobSetNull5() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobsetnull5 (data IMAGE NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobsetnull5 (data) VALUES (?)");

        // Test PreparedStatement.setObject(int,Object,int)
        pstmt.setObject(1, null, Types.BLOB);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobsetnull5");

        assertTrue(rs.next());

        // Test ResultSet.getBinaryStream()
        assertNull(rs.getBinaryStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getBlob()
        assertNull(rs.getBlob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getBytes()
        assertNull(rs.getBytes(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobSetNull6() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobsetnull6 (data IMAGE NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobsetnull6 (data) VALUES (?)");

        // Test PreparedStatement.setNull()
        pstmt.setNull(1, Types.BLOB);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobsetnull6");

        assertTrue(rs.next());

        // Test ResultSet.getBinaryStream()
        assertNull(rs.getBinaryStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getBlob()
        assertNull(rs.getBlob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getBytes()
        assertNull(rs.getBytes(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobSetNull7() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobsetnull7 (id NUMERIC IDENTITY, data IMAGE NULL, "
                     + "CONSTRAINT pk_blobsetnull7 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #blobsetnull7");

        rs.moveToInsertRow();

        // Test ResultSet.updateBinaryStream()
        rs.updateBinaryStream(2, null, 0);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #blobsetnull7");

        assertTrue(rs2.next());

        // Test ResultSet.getBinaryStream()
        assertNull(rs2.getBinaryStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getBlob()
        assertNull(rs2.getBlob(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getBytes()
        assertNull(rs2.getBytes(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs2.getObject(1));
        assertTrue(rs2.wasNull());

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testBlobSetNull8() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobsetnull8 (id NUMERIC IDENTITY, data IMAGE NULL, "
                     + "CONSTRAINT pk_blobsetnull8 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #blobsetnull8");

        rs.moveToInsertRow();

        // Test ResultSet.updateBlob()
        rs.updateBlob(2, (Blob)null);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #blobsetnull8");

        assertTrue(rs2.next());

        // Test ResultSet.getBinaryStream()
        assertNull(rs2.getBinaryStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getBlob()
        assertNull(rs2.getBlob(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getBytes()
        assertNull(rs2.getBytes(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs2.getObject(1));
        assertTrue(rs2.wasNull());

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testBlobSetNull9() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobsetnull9 (id NUMERIC IDENTITY, data IMAGE NULL, "
                     + "CONSTRAINT pk_blobsetnull9 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #blobsetnull9");

        rs.moveToInsertRow();

        // Test ResultSet.updateBytes()
        rs.updateBytes(2, null);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #blobsetnull9");

        assertTrue(rs2.next());

        // Test ResultSet.getBinaryStream()
        assertNull(rs2.getBinaryStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getBlob()
        assertNull(rs2.getBlob(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getBytes()
        assertNull(rs2.getBytes(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs2.getObject(1));
        assertTrue(rs2.wasNull());

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testBlobSetNull10() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobsetnull10 (id NUMERIC IDENTITY, data IMAGE NULL, "
                     + "CONSTRAINT pk_blobsetnull10 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #blobsetnull10");

        rs.moveToInsertRow();

        // Test ResultSet.updateObject()
        rs.updateObject(2,  null);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #blobsetnull10");

        assertTrue(rs2.next());

        // Test ResultSet.getBinaryStream()
        assertNull(rs2.getBinaryStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getBlob()
        assertNull(rs2.getBlob(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getBytes()
        assertNull(rs2.getBytes(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs2.getObject(1));
        assertTrue(rs2.wasNull());

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testBlobSetNull11() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobsetnull11 (id NUMERIC IDENTITY, data IMAGE NULL, "
                     + "CONSTRAINT pk_blobsetnull11 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #blobsetnull11");

        rs.moveToInsertRow();

        // Test ResultSet.updateNull()
        rs.updateNull(2);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #blobsetnull11");

        assertTrue(rs2.next());

        // Test ResultSet.getBinaryStream()
        assertNull(rs2.getBinaryStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getBlob()
        assertNull(rs2.getBlob(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getBytes()
        assertNull(rs2.getBytes(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs2.getObject(1));
        assertTrue(rs2.wasNull());

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    /**
     * Test for bug [989399] blob.getBytes() from 0.
     */
    public void testBlobGetBytes1() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobgetbytes1 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobgetbytes1 (data) VALUES (?)");

        // Test PreparedStatement.setBytes()
        pstmt.setBytes(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobgetbytes1");

        assertTrue(rs.next());

        // Test ResultSet.getBlob()
        Blob blob = rs.getBlob(1);

        assertNotNull(blob);

        // Test Blob.getBytes()
        assertTrue(Arrays.equals(data, blob.getBytes(1L, (int) blob.length())));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobGetBytes2() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobgetbytes2 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobgetbytes2 (data) VALUES (?)");

        // Test PreparedStatement.setBytes()
        pstmt.setBytes(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobgetbytes2");

        assertTrue(rs.next());

        // Test ResultSet.getBlob()
        Blob blob = rs.getBlob(1);

        assertNotNull(blob);

        byte[] tmpData = new byte[data.length / 2];

        System.arraycopy(data, 0, tmpData, 0, tmpData.length);

        // Test Blob.getBytes()
        assertTrue(Arrays.equals(tmpData, blob.getBytes(1L, tmpData.length)));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobGetBytes3() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobgetbytes3 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobgetbytes3 (data) VALUES (?)");

        // Test PreparedStatement.setBytes()
        pstmt.setBytes(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobgetbytes3");

        assertTrue(rs.next());

        // Test ResultSet.getBlob()
        Blob blob = rs.getBlob(1);

        assertNotNull(blob);

        byte[] tmpData = new byte[data.length / 2];

        // Offset data copy by 1
        System.arraycopy(data, 1, tmpData, 0, tmpData.length);

        // Test Blob.getBytes()
        assertTrue(Arrays.equals(tmpData, blob.getBytes(2L, tmpData.length)));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobLength1() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #bloblength1 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #bloblength1 (data) VALUES (?)");

        // Test PreparedStatement.setBytes()
        pstmt.setBytes(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #bloblength1");

        assertTrue(rs.next());

        // Test ResultSet.getBlob()
        Blob blob = rs.getBlob(1);

        assertNotNull(blob);

        // Test Blob.length()
        assertEquals(data.length, blob.length());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testBlobTruncate1() throws Exception {
        byte[] data = getBlobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #blobtruncate1 (data IMAGE)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #blobtruncate1 (data) VALUES (?)");

        // Test PreparedStatement.setBytes()
        pstmt.setBytes(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #blobtruncate1");

        assertTrue(rs.next());

        // Test ResultSet.getBlob()
        Blob blob = rs.getBlob(1);

        assertNotNull(blob);

        byte[] tmpData = new byte[data.length / 2];

        System.arraycopy(data, 0, tmpData, 0, tmpData.length);

        // Test Blob.truncate()
        blob.truncate(tmpData.length);
        assertEquals(tmpData.length, blob.length());

        // Test Blob.getBytes()
        assertTrue(Arrays.equals(tmpData, blob.getBytes(1L, (int) blob.length())));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    /**
     * Test for bug [1062395] Empty (but not null) blobs should return byte[0].
     */
    public void testBlobEmpty() throws Exception {
        Statement stmt = con.createStatement();

        assertEquals(0,
                stmt.executeUpdate("CREATE TABLE #blobEmpty (data IMAGE)"));
        assertEquals(1,
                stmt.executeUpdate("INSERT INTO #blobEmpty (data) values ('')"));

        ResultSet rs = stmt.executeQuery("SELECT * FROM #blobEmpty");
        assertTrue(rs.next());
        Blob blob = rs.getBlob(1);
        assertEquals(0, blob.length());
        assertEquals(0, blob.getBytes(1, 0).length);

        rs.close();
        stmt.close();
    }

    /*************************************************************************
     *************************************************************************
     **                          CLOB TESTS                                 **
     *************************************************************************
     *************************************************************************/

    public void testClobGet1() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobget1 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobget1 (data) VALUES (?)");

        pstmt.setString(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobget1");

        assertTrue(rs.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs.getString(1)));

        // Test ResultSet.getAsciiStream()
        InputStream is = rs.getAsciiStream(1);
        compareInputStreams(new ByteArrayInputStream(data.getBytes("ASCII")), is);

        // Test ResultSet.getUnicodeStream(()
        InputStream is2 = rs.getUnicodeStream(1);
        compareInputStreams(new ByteArrayInputStream(data.getBytes("UTF-16BE")), is2);

        // Test ResultSet.getCharacterStream()
        Reader rdr = rs.getCharacterStream(1);
        compareReaders(new StringReader(data), rdr);

        // Test ResultSet.getClob()
        Clob clob = rs.getClob(1);

        assertNotNull(clob);

        // Test Clob.length()
        assertEquals(clob.length(), data.length());

        // Test Clob.getSubString(0, length); should fail
        try {
            clob.getSubString(0L, (int) clob.length());
            fail("Clob.getSubString(0, length) should fail.");
        } catch (SQLException ex) {
            assertEquals("HY090", ex.getSQLState());
        }

        // Test Clob.getSubString()
        assertTrue(data.equals(clob.getSubString(1L, (int) clob.length())));

        // Test Clob.getAsciiStream()
        InputStream is3 = clob.getAsciiStream();
        compareInputStreams(new ByteArrayInputStream(data.getBytes("ASCII")), is3);

        // Test Clob.getCharacterStream()
        Reader rdr2 = rs.getCharacterStream(1);
        compareReaders(new StringReader(data), rdr2);

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobGet2() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobget2 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobget2 (data) VALUES (?)");

        // Test PreparedStatement.setCharacterStream()
        pstmt.setCharacterStream(1, new StringReader(data), data.length());
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobget2");

        assertTrue(rs.next());

        // Test ResultSet.getObject() - Clob
        Object result = rs.getObject(1);

        assertTrue(result instanceof Clob);

        Clob clob = (Clob) result;

        assertEquals(data.length(), clob.length());

        // Test Clob.getSubString()
        assertTrue(data.equals(clob.getSubString(1L, (int) clob.length())));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSet1() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobset1 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobset1 (data) VALUES (?)");

        // Test PreparedStatement.setAsciiStream()
        pstmt.setAsciiStream(1, new ByteArrayInputStream(data.getBytes("ASCII")), data.length());
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobset1");

        assertTrue(rs.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs.getString(1)));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSet2() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobset2 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobset2 (data) VALUES (?)");

        // Test PreparedStatement.setCharacterStream()
        pstmt.setCharacterStream(1, new StringReader(data), data.length());
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobset2");

        assertTrue(rs.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs.getString(1)));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSet3() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobset3 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobset3 (data) VALUES (?)");

        // Test PreparedStatement.setString()
        pstmt.setString(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobset3");

        assertTrue(rs.next());

        Clob clob = rs.getClob(1);

        data = getNewClobTestData();

        // Test Clob.setBytes()
        clob.setString(1, data);

        assertTrue(data.equals(clob.getSubString(1L, (int) clob.length())));

        assertFalse(rs.next());

        PreparedStatement pstmt2 = con.prepareStatement("UPDATE #clobset3 SET data = ?");

        // Test PreparedStatement.setClob()
        pstmt2.setClob(1, clob);
        assertEquals(1, pstmt2.executeUpdate());

        pstmt2.close();

        stmt2.close();
        rs.close();

        Statement stmt3 = con.createStatement();
        ResultSet rs2 = stmt3.executeQuery("SELECT data FROM #clobset3");

        assertTrue(rs2.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs2.getString(1)));

        assertFalse(rs2.next());
        stmt3.close();
        rs2.close();
    }

    public void testClobSet4() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobset4 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobset4 (data) VALUES (?)");

        // Test PreparedStatement.setUnicodeStream()
        pstmt.setUnicodeStream(1, new ByteArrayInputStream(data.getBytes("UTF-16BE")), data.length() * 2);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobset4");

        assertTrue(rs.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs.getString(1)));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSet5() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobset5 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobset5 (data) VALUES (?)");

        // Test PreparedStatement.setObject(int,String)
        pstmt.setObject(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobset5");

        assertTrue(rs.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs.getString(1)));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSet6() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobset6 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobset6 (data) VALUES (?)");

        // Test PreparedStatement.setString()
        pstmt.setString(1, data);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobset6");

        assertTrue(rs.next());

        Clob clob = rs.getClob(1);

        data = getNewClobTestData();

        // Test Clob.setBytes()
        clob.setString(1, data);

        assertTrue(data.equals(clob.getSubString(1L, (int) clob.length())));

        assertFalse(rs.next());

        PreparedStatement pstmt2 = con.prepareStatement("UPDATE #clobset6 SET data = ?");

        // Test PreparedStatement.setObject(int,Clob)
        pstmt2.setObject(1, clob);
        assertEquals(1, pstmt2.executeUpdate());

        pstmt2.close();

        stmt2.close();
        rs.close();

        Statement stmt3 = con.createStatement();
        ResultSet rs2 = stmt3.executeQuery("SELECT data FROM #clobset6");

        assertTrue(rs2.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs2.getString(1)));

        assertFalse(rs2.next());
        stmt3.close();
        rs2.close();
    }

    public void testClobSet7() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobset7 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobset7 (data) VALUES (?)");

        // Test PreparedStatement.setObject(int,String,int)
        pstmt.setObject(1, data, Types.LONGVARCHAR);
        assertEquals(pstmt.executeUpdate(), 1);

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobset7");

        assertTrue(rs.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs.getString(1)));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSet8() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobset8 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobset8 (data) VALUES (?)");

        // Test PreparedStatement.setString()
        pstmt.setString(1, data);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobset8");

        assertTrue(rs.next());

        Clob clob = rs.getClob(1);

        data = getNewClobTestData();

        // Test Clob.setBytes()
        clob.setString(1, data);

        assertTrue(data.equals(clob.getSubString(1L, (int) clob.length())));

        assertFalse(rs.next());

        PreparedStatement pstmt2 = con.prepareStatement("UPDATE #clobset8 SET data = ?");

        // Test PreparedStatement.setObject(int,Clob,int)
        pstmt2.setObject(1, clob, Types.CLOB);
        assertEquals(1, pstmt2.executeUpdate());

        pstmt2.close();

        stmt2.close();
        rs.close();

        Statement stmt3 = con.createStatement();
        ResultSet rs2 = stmt3.executeQuery("SELECT data FROM #clobset8");

        assertTrue(rs2.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs2.getString(1)));

        assertFalse(rs2.next());
        stmt3.close();
        rs2.close();
    }

    public void testClobUpdate1() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobupdate1 (id NUMERIC IDENTITY, data TEXT, "
                     + "CONSTRAINT pk_clobupdate1 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #clobupdate1");

        rs.moveToInsertRow();

        // Test ResultSet.updateString()
        rs.updateString(2, data);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #clobupdate1");

        assertTrue(rs2.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs2.getString(1)));

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testClobUpdate2() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobupdate2 (id NUMERIC IDENTITY, data TEXT, "
                     + "CONSTRAINT pk_clobupdate2 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #clobupdate2");

        rs.moveToInsertRow();

        // Test ResultSet.updateAsciiStream()
        rs.updateAsciiStream(2, new ByteArrayInputStream(data.getBytes("ASCII")), data.length());

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #clobupdate2");

        assertTrue(rs2.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs2.getString(1)));

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testClobUpdate3() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobupdate3 (id NUMERIC IDENTITY, data TEXT, "
                     + "CONSTRAINT pk_clobupdate3 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #clobupdate3");

        rs.moveToInsertRow();

        // Test ResultSet.updateCharacterStream()
        rs.updateCharacterStream(2, new StringReader(data), data.length());

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #clobupdate3");

        assertTrue(rs2.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs2.getString(1)));

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testClobUpdate4() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobupdate4 (id NUMERIC IDENTITY, data TEXT, "
                     + "CONSTRAINT pk_clobupdate4 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobupdate4 (data) VALUES (?)");

        // Test PreparedStatement.setString()
        pstmt.setString(1, data);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobupdate4");

        assertTrue(rs.next());

        Clob clob = rs.getClob(1);

        data = getNewClobTestData();

        // Test Clob.setBytes()
        clob.setString(1, data);

        assertTrue(data.equals(clob.getSubString(1, (int) clob.length())));

        assertFalse(rs.next());

        Statement stmt3 = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs2 = stmt3.executeQuery("SELECT id, data FROM #clobupdate4");

        assertTrue(rs2.next());

        // Test ResultSet.updateClob()
        rs2.updateClob(2, clob);

        rs2.updateRow();

        assertFalse(rs2.next());

        stmt2.close();
        rs.close();

        stmt3.close();
        rs2.close();

        Statement stmt4 = con.createStatement();
        ResultSet rs3 = stmt4.executeQuery("SELECT data FROM #clobupdate4");

        assertTrue(rs3.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs3.getString(1)));

        assertFalse(rs3.next());
        stmt4.close();
        rs3.close();
    }

    public void testClobUpdate5() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobupdate5 (id NUMERIC IDENTITY, data TEXT, "
                     + "CONSTRAINT pk_clobupdate5 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobupdate5 (data) VALUES (?)");

        // Test PreparedStatement.setString()
        pstmt.setString(1, data);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobupdate5");

        assertTrue(rs.next());

        Clob clob = rs.getClob(1);

        data = getNewClobTestData();

        // Test Clob.setBytes()
        clob.setString(1, data);

        assertTrue(data.equals(clob.getSubString(1, (int) clob.length())));

        assertFalse(rs.next());

        Statement stmt3 = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs2 = stmt3.executeQuery("SELECT id, data FROM #clobupdate5");

        assertTrue(rs2.next());

        // Test ResultSet.updateClob()
        rs2.updateClob(2, clob);

        rs2.updateRow();

        assertFalse(rs2.next());

        stmt2.close();
        rs.close();

        stmt3.close();
        rs2.close();

        Statement stmt4 = con.createStatement();
        ResultSet rs3 = stmt4.executeQuery("SELECT data FROM #clobupdate5");

        assertTrue(rs3.next());

        // Test ResultSet.getString()
        assertTrue(data.equals(rs3.getString(1)));

        assertFalse(rs3.next());
        stmt4.close();
        rs3.close();
    }

    /**
     * Test long <code>Clob</code> manipulation including indexed writes.
     */
    public void testClobUpdate6() throws Exception {
        int size = 100000;
        StringBuffer data = new StringBuffer(size);
        for (int i = 0; i < size; i++) {
            data.append((char)('A'+i%10));
        }
        //
        // Construct a clob
        //
        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT ''");
        assertNotNull(rs);
        assertTrue(rs.next());
        Clob clob = rs.getClob(1);
        clob.setString(1, data.toString());
        assertEquals((long)size, clob.length());
        assertTrue(data.toString().equals(clob.getSubString(1, (int)clob.length())));
        clob.setString(10, "THIS IS A TEST");
        data.replace(9, 23, "THIS IS A TEST");
        assertEquals("THIS IS A TEST", clob.getSubString(10, 14));
        assertTrue(compare(data.toString(), clob.getSubString(1, (int)clob.length())));
        clob.truncate(23);
        assertEquals("ABCDEFGHITHIS IS A TEST", clob.getSubString(1, 23));
        OutputStream os = clob.setAsciiStream(1);
        for (int i = 0; i < size; i++) {
            os.write(data.charAt(i));
        }
        os.close();
        assertEquals((long)size, clob.length());
        assertTrue(data.toString().equals(clob.getSubString(1, (int)clob.length())));
        InputStream is = clob.getAsciiStream();
        int b;
        int p = 0;
        while ((b = is.read()) >= 0) {
            if ((char)b != data.charAt(p++)) {
                fail("Mismatch at " + p);
            }
        }
        is.close();
        assertTrue(p == size);
        Reader rdr = clob.getCharacterStream();
        p = 0;
        while ((b = rdr.read()) >= 0) {
            if ((char)b != data.charAt(p++)) {
                fail("Mismatch at " + p);
            }
        }
        rdr.close();
        assertTrue(p == size);
        clob.truncate(0);
        Writer wtr = clob.setCharacterStream(1);
        for (int i = 0; i < size; i++) {
            wtr.write(data.charAt(i));
        }
        wtr.close();
        assertTrue(p == size);
        assertTrue(data.toString().equals(clob.getSubString(1, (int)clob.length())));
        wtr = clob.setCharacterStream(10000);
        for (int i = 0; i < 8; i++) {
            wtr.write('X');
        }
        wtr.close();
        data.replace(10000-1, 10000-1+8, "XXXXXXXX");
        assertTrue(data.toString().equals(clob.getSubString(1, (int)clob.length())));
        clob.setString(100001, "XTESTX", 1, 4);
        assertEquals((long)100000+4, clob.length());
        assertEquals("JTEST", clob.getSubString(100000, 8));
        assertEquals(100000, clob.position("JTEST", 100000));
        Clob clob2 = rs.getClob(1);
        clob.setString(1, "XXXXXXXX");
        assertEquals(10000, clob.position("XXXXXXXX", 10000));
        assertFalse(10000 == clob.position("XXXXXXXX", 10001));
    }

    public void testClobSetNull1() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull1 (data TEXT NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobsetnull1 (data) VALUES (?)");

        // Test PreparedStatement.setAsciiStream()
        pstmt.setAsciiStream(1, null, 0);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobsetnull1");

        assertTrue(rs.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs.getAsciiStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs.getCharacterStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs.getClob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getString()
        assertNull(rs.getString(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs.getUnicodeStream(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSetNull2() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull2 (data TEXT NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobsetnull2 (data) VALUES (?)");

        // Test PreparedStatement.setCharacterStream()
        pstmt.setCharacterStream(1, null, 0);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobsetnull2");

        assertTrue(rs.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs.getAsciiStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs.getCharacterStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs.getClob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getString()
        assertNull(rs.getString(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs.getUnicodeStream(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSetNull3() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull3 (data TEXT NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobsetnull3 (data) VALUES (?)");

        // Test PreparedStatement.setClob()
        pstmt.setClob(1, (Clob)null);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobsetnull3");

        assertTrue(rs.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs.getAsciiStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs.getCharacterStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs.getClob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getString()
        assertNull(rs.getString(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs.getUnicodeStream(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSetNull4() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull4 (data TEXT NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobsetnull4 (data) VALUES (?)");

        // Test PreparedStatement.setObject(int,Object)
        pstmt.setObject(1, null);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobsetnull4");

        assertTrue(rs.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs.getAsciiStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs.getCharacterStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs.getClob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getString()
        assertNull(rs.getString(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs.getUnicodeStream(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSetNull5() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull5 (data TEXT NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobsetnull5 (data) VALUES (?)");

        // Test PreparedStatement.setObject(int,Object,int)
        pstmt.setObject(1, null, Types.CLOB);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobsetnull5");

        assertTrue(rs.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs.getAsciiStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs.getCharacterStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs.getClob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getString()
        assertNull(rs.getString(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs.getUnicodeStream(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSetNull6() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull6 (data TEXT NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobsetnull6 (data) VALUES (?)");

        // Test PreparedStatement.setString()
        pstmt.setString(1, null);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobsetnull6");

        assertTrue(rs.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs.getAsciiStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs.getCharacterStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs.getClob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getString()
        assertNull(rs.getString(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs.getUnicodeStream(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSetNull7() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull7 (data TEXT NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobsetnull7 (data) VALUES (?)");

        // Test PreparedStatement.setUnicodeStream()
        pstmt.setUnicodeStream(1, null, 0);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobsetnull7");

        assertTrue(rs.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs.getAsciiStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs.getCharacterStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs.getClob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getString()
        assertNull(rs.getString(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs.getUnicodeStream(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSetNull8() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull8 (data TEXT NULL)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobsetnull8 (data) VALUES (?)");

        // Test PreparedStatement.setNull()
        pstmt.setNull(1, Types.CLOB);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobsetnull8");

        assertTrue(rs.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs.getAsciiStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs.getCharacterStream(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs.getClob(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs.getObject(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getString()
        assertNull(rs.getString(1));
        assertTrue(rs.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs.getUnicodeStream(1));
        assertTrue(rs.wasNull());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobSetNull9() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull9 (id NUMERIC IDENTITY, data TEXT NULL, "
                     + "CONSTRAINT pk_clobsetnull9 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #clobsetnull9");

        rs.moveToInsertRow();

        // Test ResultSet.updateAsciiStream()
        rs.updateAsciiStream(2, null, 0);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #clobsetnull9");

        assertTrue(rs2.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs2.getAsciiStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs2.getCharacterStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs2.getClob(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs2.getObject(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getString()
        assertNull(rs2.getString(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs2.getUnicodeStream(1));
        assertTrue(rs2.wasNull());

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testClobSetNull10() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull10 (id NUMERIC IDENTITY, data TEXT NULL, "
                     + "CONSTRAINT pk_clobsetnull10 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #clobsetnull10");

        rs.moveToInsertRow();

        // Test ResultSet.updateCharacterStream()
        rs.updateCharacterStream(2, null, 0);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #clobsetnull10");

        assertTrue(rs2.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs2.getAsciiStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs2.getCharacterStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs2.getClob(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs2.getObject(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getString()
        assertNull(rs2.getString(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs2.getUnicodeStream(1));
        assertTrue(rs2.wasNull());

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testClobSetNull11() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull11 (id NUMERIC IDENTITY, data TEXT NULL, "
                     + "CONSTRAINT pk_clobsetnull11 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #clobsetnull11");

        rs.moveToInsertRow();

        // Test ResultSet.updateClob()
        rs.updateClob(2, (Clob)null);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #clobsetnull11");

        assertTrue(rs2.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs2.getAsciiStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs2.getCharacterStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs2.getClob(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs2.getObject(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getString()
        assertNull(rs2.getString(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs2.getUnicodeStream(1));
        assertTrue(rs2.wasNull());

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testClobSetNull12() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull12 (id NUMERIC IDENTITY, data TEXT NULL, "
                     + "CONSTRAINT pk_clobsetnull12 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #clobsetnull12");

        rs.moveToInsertRow();

        // Test ResultSet.updateObject()
        rs.updateObject(2, null);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #clobsetnull12");

        assertTrue(rs2.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs2.getAsciiStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs2.getCharacterStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs2.getClob(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs2.getObject(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getString()
        assertNull(rs2.getString(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs2.getUnicodeStream(1));
        assertTrue(rs2.wasNull());

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testClobSetNull13() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull13 (id NUMERIC IDENTITY, data TEXT NULL, "
                     + "CONSTRAINT pk_clobsetnull13 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #clobsetnull13");

        rs.moveToInsertRow();

        // Test ResultSet.updateString()
        rs.updateString(2, null);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #clobsetnull13");

        assertTrue(rs2.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs2.getAsciiStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs2.getCharacterStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs2.getClob(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs2.getObject(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getString()
        assertNull(rs2.getString(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs2.getUnicodeStream(1));
        assertTrue(rs2.wasNull());

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testClobSetNull14() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobsetnull14 (id NUMERIC IDENTITY, data TEXT NULL, "
                     + "CONSTRAINT pk_clobsetnull14 PRIMARY KEY CLUSTERED (id))");
        stmt.close();

        stmt = con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs = stmt.executeQuery("SELECT id, data FROM #clobsetnull14");

        rs.moveToInsertRow();

        // Test ResultSet.updateNull()
        rs.updateNull(2);

        rs.insertRow();

        stmt.close();
        rs.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs2 = stmt2.executeQuery("SELECT data FROM #clobsetnull14");

        assertTrue(rs2.next());

        // Test ResultSet.getAsciiStream()
        assertNull(rs2.getAsciiStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getCharacterStream()
        assertNull(rs2.getCharacterStream(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getClob()
        assertNull(rs2.getClob(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getObject()
        assertNull(rs2.getObject(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getString()
        assertNull(rs2.getString(1));
        assertTrue(rs2.wasNull());

        // Test ResultSet.getUnicodeStream()
        assertNull(rs2.getUnicodeStream(1));
        assertTrue(rs2.wasNull());

        assertFalse(rs2.next());
        stmt2.close();
        rs2.close();
    }

    public void testClobGetSubString1() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobgetsubstring1 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobgetsubstring1 (data) VALUES (?)");

        pstmt.setString(1, data);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobgetsubstring1");

        assertTrue(rs.next());

        // Test ResultSet.getClob()
        Clob clob = rs.getClob(1);

        assertNotNull(clob);

        // Test Clob.getSubString()
        assertTrue(data.equals(clob.getSubString(1L, (int) clob.length())));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobGetSubString2() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobgetsubstring2 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobgetsubstring2 (data) VALUES (?)");

        pstmt.setString(1, data);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobgetsubstring2");

        assertTrue(rs.next());

        // Test ResultSet.getClob()
        Clob clob = rs.getClob(1);

        assertNotNull(clob);

        String tmpData = data.substring(0, data.length() / 2);

        // Test Clob.getSubString()
        assertTrue(tmpData.equals(clob.getSubString(1L, tmpData.length())));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobGetSubString3() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobgetsubstring3 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobgetsubstring3 (data) VALUES (?)");

        pstmt.setString(1, data);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobgetsubstring3");

        assertTrue(rs.next());

        // Test ResultSet.getClob()
        Clob clob = rs.getClob(1);

        assertNotNull(clob);

        // Offset data by 1
        String tmpData = data.substring(1, data.length() / 2);

        // Test Clob.getSubString()
        assertTrue(tmpData.equals(clob.getSubString(2L, tmpData.length())));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobLength1() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #cloblength1 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #cloblength1 (data) VALUES (?)");

        pstmt.setString(1, data);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #cloblength1");

        assertTrue(rs.next());

        // Test ResultSet.getClob()
        Clob clob = rs.getClob(1);

        assertNotNull(clob);

        // Test Clob.length()
        assertEquals(data.length(), clob.length());

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    public void testClobTruncate1() throws Exception {
        String data = getClobTestData();

        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #clobtruncate1 (data TEXT)");
        stmt.close();

        PreparedStatement pstmt = con.prepareStatement("INSERT INTO #clobtruncate1 (data) VALUES (?)");

        pstmt.setString(1, data);
        assertEquals(1, pstmt.executeUpdate());

        pstmt.close();

        Statement stmt2 = con.createStatement();
        ResultSet rs = stmt2.executeQuery("SELECT data FROM #clobtruncate1");

        assertTrue(rs.next());

        // Test ResultSet.getClob()
        Clob clob = rs.getClob(1);

        assertNotNull(clob);

        String tmpData = data.substring(0, data.length() / 2);

        // Test Clob.truncate()
        clob.truncate(tmpData.length());
        assertEquals(tmpData.length(), clob.length());

        // Test Clob.getSubString()
        assertTrue(tmpData.equals(clob.getSubString(1L, (int) clob.length())));

        assertFalse(rs.next());
        stmt2.close();
        rs.close();
    }

    /**
     * Test for bug [1062395] Empty (but not null) blobs should return byte[0].
     */
    public void testClobEmpty() throws Exception {
        Statement stmt = con.createStatement();

        assertEquals(0,
                stmt.executeUpdate("CREATE TABLE #clobEmpty (data TEXT)"));
        assertEquals(1,
                stmt.executeUpdate("INSERT INTO #clobEmpty (data) values ('')"));

        ResultSet rs = stmt.executeQuery("SELECT * FROM #clobEmpty");
        assertTrue(rs.next());
        Clob clob = rs.getClob(1);
        assertEquals(0, clob.length());
        assertEquals("", clob.getSubString(1, 0));

        rs.close();
        stmt.close();
    }

    public void testClobCaching() throws Exception {
        // Create a Clob large enough to need caching to disk
        char[] in = new char[100000];
        for (int i = 0; i < in.length; i++) {
            // Store non-Cp1252 characters into it
            in[i] = 0x2032;
        }

        Statement stmt = con.createStatement();
        stmt.executeUpdate("create table #testClobCaching (val ntext)");

        PreparedStatement pstmt = con.prepareStatement(
                "insert into #testClobCaching values (?)");
        pstmt.setCharacterStream(1, new CharArrayReader(in), in.length);
        pstmt.executeUpdate();
        pstmt.close();

        ResultSet rs = stmt.executeQuery("select * from #testClobCaching");
        assertTrue(rs.next());
        String out = rs.getString(1);
        assertEquals(in.length, out.length());
        for (int i = 0; i < in.length; i++) {
            if (in[i] != out.charAt(i)) {
                fail("Result differs at position " + i);
            }
        }
        assertFalse(rs.next());
        rs.close();
        stmt.close();
    }

    /**
     * Test for incorrect handling of zero length streams (bug [1096086] Zero
     * length streams generate null values).
     */
    public void testZeroLengthStreams() throws Exception {
        Statement stmt = con.createStatement(ResultSet.TYPE_FORWARD_ONLY,
                ResultSet.CONCUR_UPDATABLE);
        stmt.execute("create table #test (id int primary key, s_ascii text," +
                "s_char text, s_unicode text, s_bytes image)");
        PreparedStatement pstmt =
                con.prepareStatement("insert into #test values(?,?,?,?,?)");

        // Write zero length fields
        pstmt.setInt(1, 1);
        pstmt.setAsciiStream(2, new ByteArrayInputStream(new byte[0]), 0);
        pstmt.setCharacterStream(3, new StringReader(""), 0);
        pstmt.setUnicodeStream(4, new ByteArrayInputStream(new byte[0]), 0);
        pstmt.setBinaryStream(5, new ByteArrayInputStream(new byte[0]), 0);
        assertEquals(1, pstmt.executeUpdate());

        // Write non zero fields
        pstmt.setInt(1, 2);
        pstmt.setAsciiStream(2, new ByteArrayInputStream(new byte[1]), 1);
        pstmt.setCharacterStream(3, new StringReader("TEST"), 4);
        pstmt.setCharacterStream(4, new StringReader(""), 0);
        pstmt.setUnicodeStream(4, new ByteArrayInputStream(new byte[2]), 2);
        pstmt.setBinaryStream(5, new ByteArrayInputStream(new byte[1]), 1);
        assertEquals(1, pstmt.executeUpdate());
        pstmt.close();

        ResultSet rs = stmt.executeQuery("select * from #test order by id");
        assertTrue(rs.next());
        assertTrue(rs.next());

        // Update non zero length fields to zero
        rs.updateAsciiStream(2, new ByteArrayInputStream(new byte[0]), 0);
        rs.updateCharacterStream(3, new StringReader(""), 0);
        Clob clob = rs.getClob(4);
        clob.truncate(0);
        rs.updateClob(4, clob);
        rs.updateBinaryStream(5, new ByteArrayInputStream(new byte[0]), 0);
        rs.updateRow();
        rs.close();

        // Test all fields now zero length
        rs = stmt.executeQuery("select * from #test order by id");
        while (rs.next()) {
            assertEquals("AsciiStream", "", rs.getString(2));
            assertEquals("Reader", "", rs.getString(3));
            assertEquals("UnicodeStream", "", rs.getString(4));
            assertEquals("byteStream", 0, rs.getBytes(5).length);
        }
        rs.close();
        stmt.close();
    }

    /**
     * Test for bug [1172405] BLOB/CLOB position methods fail.
     */
    public void testBlobMethods() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #TESTBLOB (id int, blob image null)");
        assertEquals(1, stmt.executeUpdate(
                "INSERT INTO #TESTBLOB (id) VALUES (1)"));
        assertEquals(1, stmt.executeUpdate(
                "INSERT INTO #TESTBLOB (id, blob) VALUES (2, 0x4445)"));
        assertEquals(1, stmt.executeUpdate(
                "INSERT INTO #TESTBLOB (id, blob) VALUES (3, 0x4142434445464748)"));
        ResultSet rs = stmt.executeQuery("SELECT * FROM #TESTBLOB");
        assertNotNull(rs);
        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));
        Blob blob = rs.getBlob(2);
        assertNull(blob);
        assertTrue(rs.next());
        assertEquals(2, rs.getInt(1));
        Blob pattern = rs.getBlob(2);
        assertNotNull(pattern);
        assertTrue(rs.next());
        assertEquals(3, rs.getInt(1));
        blob  = rs.getBlob(2);
        assertEquals(8, blob.length());
        assertEquals("ABCDEFGH", new String(blob.getBytes(1, 8)));
        assertEquals(4, blob.position(pattern, 1));
        assertEquals(-1, blob.position(pattern, 8));
        assertEquals(3, blob.position(new byte[]{0x43,0x44}, 1));
        assertEquals(-1, blob.position(new byte[]{0x43,0x44}, 8));
        byte buf[] = new byte[(int)blob.length()];
        InputStream is = blob.getBinaryStream();
        assertEquals((int)blob.length(), is.read(buf));
        assertEquals(-1, is.read());
        assertEquals("ABCDEFGH", new String(buf));
    }

    /**
     * Test for bug [1172405] BLOB/CLOB position methods fail.
     */
    public void testClobMethods() throws Exception {
        Statement stmt = con.createStatement();
        stmt.execute("CREATE TABLE #TESTCLOB (id int, clob text null)");
        assertEquals(1, stmt.executeUpdate(
                "INSERT INTO #TESTCLOB (id) VALUES (1)"));
        assertEquals(1, stmt.executeUpdate(
                "INSERT INTO #TESTCLOB (id, clob) VALUES (2, 'CD')"));
        assertEquals(1, stmt.executeUpdate(
                "INSERT INTO #TESTCLOB (id, clob) VALUES (3, 'ABCDEFGH')"));
        ResultSet rs = stmt.executeQuery("SELECT * FROM #TESTCLOB");
        assertNotNull(rs);
        assertTrue(rs.next());
        assertEquals(1, rs.getInt(1));
        Clob clob = rs.getClob(2);
        assertNull(clob);
        assertTrue(rs.next());
        assertEquals(2, rs.getInt(1));
        Clob pattern = rs.getClob(2);
        assertNotNull(pattern);
        assertTrue(rs.next());
        assertEquals(3, rs.getInt(1));
        clob  = rs.getClob(2);
        assertEquals(8, clob.length());
        assertEquals("ABCDEFGH", clob.getSubString(1, 8));
        assertEquals(3, clob.position(pattern, 1));
        assertEquals(-1, clob.position(pattern, 8));
        assertEquals(3, clob.position("CD", 1));
        assertEquals(-1, clob.position("CD", 8));
        Reader rdr = clob.getCharacterStream();
        char buf[] = new char[(int)clob.length()];
        assertEquals((int)clob.length(), rdr.read(buf));
        assertEquals(-1, rdr.read());
        assertEquals("ABCDEFGH", new String(buf));
        byte bbuf[] = new byte[(int)clob.length()];
        InputStream is = clob.getAsciiStream();
        assertEquals((int)clob.length(), is.read(bbuf));
        assertEquals(-1, is.read());
        assertEquals("ABCDEFGH", new String(bbuf));
    }

    private byte[] getBlobTestData() {
        return blobData;
    }

    private byte[] getNewBlobTestData() {
        return newBlobData;
    }

    private String getClobTestData() {
        return clobData;
    }

    private String getNewClobTestData() {
        return newClobData;
    }

    /**
     * Implements an <code>InputStream</code> that only returns a limited
     * number of bytes on read (less than the requested number of bytes).
     * <p>
     * Used for testing <code>Blob</code> insert behavior.
     */
    static class RealInputStream extends InputStream {
        /**
         * Length of the stream.
         */
        static final int LENGTH = 10000;

        /**
         * Current position in the stream.
         */
        private int pos = 0;

        public int read() {
            if (++pos > LENGTH) {
                return -1;
            }
            return pos % 256;
        }

        public int read(byte[] b) {
            return read(b, 0, b.length);
        }

        public int read(byte[] b, int off, int len) {
            int res = read();
            if (res == -1) {
                return -1;
            } else {
                b[off] = (byte) res;
                return 1;
            }
        }
    }

    /**
     * Compares long byte arrays.
     */
    private boolean compare(byte []b1, byte[] b2) {
        if (b1.length != b2.length) {
            System.out.println("Compare failed: lengths differ");
            return false;
        }
        for (int i = 0; i < b1.length; i++) {
            if (b1[i] != b2[i]) {
                System.out.println("Compare failed: bytes at " + i + " differ ["
                        + b1[i] + "] [" + b2[i] + "]");
                return false;
            }
        }
        return true;
    }

    /**
     * Compare long <code>String</code>s.
     */
    public boolean compare(String s1, String s2) {
        if (s1.length() != s2.length()) {
            System.out.println("Compare failed: lengths differ");
            return false;
        }
        for (int i = 0; i < s1.length(); i++) {
            if (s1.charAt(i) != s2.charAt(i)) {
                System.out.println("Compare failed: bytes at " + i + " differ ["
                        + s1.charAt(i) + "] [" + s2.charAt(i) + "]");
                return false;
            }
        }
        return true;
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(LOBTest.class);
    }
}