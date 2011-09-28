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
package net.sourceforge.jtds.jdbc;

import java.io.*;
import java.sql.Clob;
import java.sql.SQLException;

import net.sourceforge.jtds.util.BlobBuffer;

/**
 * An in-memory or disk based representation of character data.
 * <p/>
 * Implementation note:
 * <ol>
 *   <li>This implementation stores the CLOB data in a byte array managed by
 *     the <code>BlobBuffer</code> class. Each character is stored in 2
 *     sequential bytes using UTF-16LE encoding.
 *   <li>As a consequence of using UTF-16LE, Unicode 3.1 supplementary
 *     characters may require an additional 2 bytes of storage. This
 *     implementation assumes that character position parameters supplied to
 *     <code>getSubstring</code>, <code>position</code> and the
 *     <code>set</code> methods refer to 16 bit characters only. The presence
 *     of supplementary characters will cause the wrong characters to be
 *     accessed.
 *   <li>For the same reasons although the position method will return the
 *     correct start position for any given pattern in the array, the returned
 *     value may be different to that expected if supplementary characters
 *     exist in the text preceding the pattern.
 * </ol>
 *
 * @author Brian Heineman
 * @author Mike Hutchinson
 * @version $Id: ClobImpl.java,v 1.36.2.3 2009-12-30 08:45:34 ickzon Exp $
 */

public class ClobImpl implements Clob {
    /**
     * 0 length <code>String</code> as initial value for empty
     * <code>Clob</code>s.
     */
    private static final String EMPTY_CLOB = "";

    /** The underlying <code>BlobBuffer</code>. */
    private final BlobBuffer blobBuffer;

    /**
     * Constructs a new empty <code>Clob</code> instance.
     *
     * @param connection a reference to the parent connection object
     */
    ClobImpl(ConnectionJDBC2 connection) {
        this(connection, EMPTY_CLOB);
    }

    /**
     * Constructs a new initialized <code>Clob</code> instance.
     *
     * @param connection a reference to the parent connection object
     * @param str        the <code>String</code> object to encapsulate
     */
    ClobImpl(ConnectionJDBC2 connection, String str) {
        if (str == null) {
            throw new IllegalArgumentException("str cannot be null");
        }
        blobBuffer = new BlobBuffer(connection.getBufferDir(), connection.getLobBuffer());
        try {
            byte[] data = str.getBytes("UTF-16LE");
            blobBuffer.setBuffer(data, false);
        } catch (UnsupportedEncodingException e) {
            // This should never happen!
            throw new IllegalStateException("UTF-16LE encoding is not supported.");
        }
    }

    /**
     * Obtain this object's backing <code>BlobBuffer</code> object.
     *
     * @return the underlying <code>BlobBuffer</code>
     */
    BlobBuffer getBlobBuffer() {
        return this.blobBuffer;
    }

    //
    // ---- java.sql.Blob interface methods from here ----
    //

    public InputStream getAsciiStream() throws SQLException {
        return blobBuffer.getBinaryStream(true);
    }

    public Reader getCharacterStream() throws SQLException {
        try {
            return new BufferedReader(new InputStreamReader(
                    blobBuffer.getBinaryStream(false), "UTF-16LE"));
        } catch (UnsupportedEncodingException e) {
            // This should never happen!
            throw new IllegalStateException(
                    "UTF-16LE encoding is not supported.");
        }
    }

    public String getSubString(long pos, int length) throws SQLException {
        if (length == 0) {
            return EMPTY_CLOB;
        }
        try {
            byte data[] = blobBuffer.getBytes((pos - 1) * 2 + 1, length * 2);
            return new String(data, "UTF-16LE");
        } catch (IOException e) {
            throw new SQLException(Messages.get("error.generic.ioerror",
                    e.getMessage()),
                    "HY000");
        }
    }

    public long length() throws SQLException {
        return blobBuffer.getLength() / 2;
    }

    public long position(String searchStr, long start) throws SQLException {
        if (searchStr == null) {
            throw new SQLException(
                    Messages.get("error.clob.searchnull"), "HY009");
        }
        try {
            byte[] pattern = searchStr.getBytes("UTF-16LE");
            int pos = blobBuffer.position(pattern, (start - 1) * 2 + 1);
            return (pos < 0) ? pos : (pos - 1) / 2 + 1;
        } catch (UnsupportedEncodingException e) {
            // This should never happen!
            throw new IllegalStateException(
                    "UTF-16LE encoding is not supported.");
        }
    }

    public long position(Clob searchStr, long start) throws SQLException {
        if (searchStr == null) {
            throw new SQLException(
                    Messages.get("error.clob.searchnull"), "HY009");
        }
        BlobBuffer bbuf = ((ClobImpl) searchStr).getBlobBuffer();
        byte[] pattern = bbuf.getBytes(1, (int) bbuf.getLength());
        int pos = blobBuffer.position(pattern, (start - 1) * 2 + 1);
        return (pos < 0) ? pos : (pos - 1) / 2 + 1;
    }

    public OutputStream setAsciiStream(final long pos) throws SQLException {
        return blobBuffer.setBinaryStream((pos - 1) * 2 + 1, true);
    }

    public Writer setCharacterStream(final long pos) throws SQLException {
        try {
            return new BufferedWriter(new OutputStreamWriter(
                    blobBuffer.setBinaryStream((pos - 1) * 2 + 1, false),
                    "UTF-16LE"));
        } catch (UnsupportedEncodingException e) {
            // Should never happen
            throw new IllegalStateException("UTF-16LE encoding is not supported.");
        }
    }

    public int setString(long pos, String str) throws SQLException {
        if (str == null) {
            throw new SQLException(
                    Messages.get("error.clob.strnull"), "HY009");
        }
        return setString(pos, str, 0, str.length());
    }

    public int setString(long pos, String str, int offset, int len)
            throws SQLException {
        if (offset < 0 || offset > str.length()) {
            throw new SQLException(Messages.get(
                    "error.blobclob.badoffset"), "HY090");
        }
        if (len < 0 || offset + len > str.length()) {
            throw new SQLException(
                    Messages.get("error.blobclob.badlen"), "HY090");
        }
        try {
            byte[] data = str.substring(offset, offset + len)
                    .getBytes("UTF-16LE");
            // No need to force BlobBuffer to copy the bytes as this is a local
            // buffer and cannot be corrupted by the user.
            return blobBuffer.setBytes(
                    (pos - 1) * 2 + 1, data, 0, data.length, false);
        } catch (UnsupportedEncodingException e) {
            // This should never happen!
            throw new IllegalStateException(
                    "UTF-16LE encoding is not supported.");
        }
    }

    public void truncate(long len) throws SQLException {
        blobBuffer.truncate(len * 2);
    }

    /////// JDBC4 demarcation, do NOT put any JDBC3 code below this line ///////

    public void free() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    public Reader getCharacterStream(long pos, long length) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

}