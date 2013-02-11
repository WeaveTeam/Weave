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

import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.io.UnsupportedEncodingException;
import net.sourceforge.jtds.util.*;

/**
 * Implements an input stream for the server response.
 * <p/>
 * Implementation note:
 * <ol>
 *   <li>This class contains methods to read different types of data from the
 *     server response stream in TDS format.
 *   <li>Character translation of String items is carried out.
 * </ol>
 *
 * @author Mike Hutchinson.
 * @version $Id: ResponseStream.java,v 1.20 2005-10-27 13:22:33 alin_sinpalean Exp $
 */
public class ResponseStream {
    /** The shared network socket. */
    private final SharedSocket socket;
    /** The Input packet buffer. */
    private byte[] buffer;
    /** The offset of the next byte to read. */
    private int bufferPtr;
    /** The length of current input packet. */
    private int bufferLen;
    /** The unique stream id. */
    private final int streamId;
    /** True if stream is closed. */
    private boolean isClosed;
    /** A shared byte buffer. */
    private final byte[] byteBuffer = new byte[255];
    /** A shared char buffer. */
    private final char[] charBuffer = new char[255];

    /**
     * Constructs a <code>RequestStream</code> object.
     *
     * @param socket     the shared socket object to write to
     * @param streamId   the unique id for this stream (from ResponseStream)
     * @param bufferSize the initial buffer size
     */
    ResponseStream(SharedSocket socket, int streamId, int bufferSize){
        this.streamId = streamId;
        this.socket = socket;
        this.buffer = new byte[bufferSize];
        this.bufferLen = bufferSize;
        this.bufferPtr = bufferSize;
    }

    /**
     * Retrieves the unique stream id.
     *
     * @return the unique stream id as an <code>int</code>
     */
    int getStreamId() {
        return this.streamId;
    }

    /**
     * Retrieves the next input byte without reading forward.
     *
     * @return the next byte in the input stream as an <code>int</code>
     * @throws IOException if an I/O error occurs
     */
    int peek() throws IOException {
        int b = read();

        bufferPtr--; // Backup one

        return b;
    }

    /**
     * Reads the next input byte from the server response stream.
     *
     * @return the next byte in the input stream as an <code>int</code>
     * @throws IOException if an I/O error occurs
     */
    int read() throws IOException {
        if (bufferPtr >= bufferLen) {
            getPacket();
        }

        return (int) buffer[bufferPtr++] & 0xFF;
    }

    /**
     * Reads a byte array from the server response stream.
     *
     * @param b the byte array to read into
     * @return the number of bytes read as an <code>int</code>
     * @throws IOException if an I/O error occurs
     */
    int read(byte[] b) throws IOException {
        return read(b, 0, b.length);
    }

    /**
     * Reads a byte array from the server response stream, specifying a start
     * offset and length.
     *
     * @param b   the byte array
     * @param off the starting offset in the array
     * @param len the number of bytes to read
     * @return the number of bytes read as an <code>int</code>
     * @throws IOException if an I/O error occurs
     */
    int read(byte[] b, int off, int len) throws IOException {
        int bytesToRead = len;

        while (bytesToRead > 0) {
            if (bufferPtr >= bufferLen) {
                getPacket();
            }

            int available = bufferLen - bufferPtr;
            int bc = (available > bytesToRead) ? bytesToRead : available;

            System.arraycopy(buffer, bufferPtr, b, off, bc);
            off += bc;
            bytesToRead -= bc;
            bufferPtr += bc;
        }

        return len;
    }

    /**
     * Reads a char array from the server response stream.
     *
     * @param c the char array
     * @return the byte array as a <code>byte[]</code>
     * @throws IOException if an I/O error occurs
     */
    int read(char[] c) throws IOException {
        for (int i = 0; i < c.length; i++) {
            if (bufferPtr >= bufferLen) {
                getPacket();
            }

            int b1 = buffer[bufferPtr++] & 0xFF;

            if (bufferPtr >= bufferLen) {
                getPacket();
            }

            int b2 = buffer[bufferPtr++] << 8;

            c[i] = (char) (b2 | b1);
        }

        return c.length;
    }

    /**
     * Reads a <code>String</code> object from the server response stream. If
     * the TDS protocol version is 4.2 or 5.0 decode the string use the default
     * server charset, otherwise use UCS2-LE (Unicode).
     *
     * @param len the length of the string to read <b>in bytes</b> in the case
     *            of TDS 4.2/5.0 and <b>in characters</b> for TDS 7.0+
     *            (UCS2-LE encoded strings)
     * @return the result as a <code>String</code>
     * @throws IOException if an I/O error occurs
     */
    String readString(int len) throws IOException {
        if (socket.getTdsVersion() >= Driver.TDS70) {
            return readUnicodeString(len);
        }

        return readNonUnicodeString(len);
    }

    /**
     * Skips a <code>String</code> from the server response stream. If the TDS
     * protocol version is 4.2 or 5.0 <code>len</code> is the length in bytes,
     * otherwise it's the length in UCS2-LE characters (length in bytes == 2 *
     * <code>len</code>).
     *
     * @param len the length of the string to skip <b>in bytes</b> in the case
     *            of TDS 4.2/5.0 and <b>in characters</b> for TDS 7.0+
     *            (UCS2-LE encoded strings)
     * @throws IOException if an I/O error occurs
     */
    void skipString(int len) throws IOException {
        if (len <= 0) {
            return;
        }

        if (socket.getTdsVersion() >= Driver.TDS70) {
            skip(len * 2);
        } else {
            skip(len);
        }
    }

    /**
     * Reads a UCS2-LE (Unicode) encoded String object from the server response
     * stream.
     *
     * @param len the length of the string to read <b>in characters</b>
     * @return the result as a <code>String</code>
     * @throws IOException if an I/O error occurs
     */
    String readUnicodeString(int len) throws IOException {
        char[] chars = (len > charBuffer.length) ? new char[len] : charBuffer;

        for (int i = 0; i < len; i++) {
            if (bufferPtr >= bufferLen) {
                getPacket();
            }

            int b1 = buffer[bufferPtr++] & 0xFF;

            if (bufferPtr >= bufferLen) {
                getPacket();
            }

            int b2 = buffer[bufferPtr++] << 8;

            chars[i] = (char) (b2 | b1);
        }

        return new String(chars, 0, len);
    }

    /**
     * Reads a non Unicode <code>String</code> from the server response stream,
     * creating the <code>String</code> from a translated <code>byte</code>
     * array.
     *
     * @param len the length of the string to read <b>in bytes</b>
     * @return the result as a <code>String</code>
     * @throws IOException if an I/O error occurs
     */
    String readNonUnicodeString(int len) throws IOException {
        CharsetInfo info = socket.getCharsetInfo();

        return readString(len, info);
    }

    /**
     * Reads a <code>String</code> from the server response stream, translating
     * it from a <code>byte</code> array using the specified character set.
     *
     * @param len the length of the string to read <b>in bytes</b>
     * @return the result as a <code>String</code>
     * @throws IOException if an I/O error occurs
     */
    String readNonUnicodeString(int len, CharsetInfo charsetInfo)
            throws IOException {
        return readString(len, charsetInfo);
    }

    /**
     * Reads a <code>String</code> from the server response stream, creating
     * it from a translated <code>byte</code> array.
     *
     * @param len  the length of the string to read <b>in bytes</b>
     * @param info descriptor of the charset to use
     * @return the result as a <code>String</code>
     * @throws IOException if an I/O error occurs
     */
    String readString(int len, CharsetInfo info) throws IOException {
        String charsetName = info.getCharset();
        byte[] bytes = (len > byteBuffer.length) ? new byte[len] : byteBuffer;

        read(bytes, 0, len);

        try {
            return new String(bytes, 0, len, charsetName);
        } catch (UnsupportedEncodingException e) {
            return new String(bytes, 0, len);
        }
    }

    /**
     * Reads a <code>short</code> value from the server response stream.
     *
     * @return the result as a <code>short</code>
     * @throws IOException if an I/O error occurs
     */
    short readShort() throws IOException {
        int b1 = read();

        return (short) (b1 | (read() << 8));
    }

    /**
     * Reads an <code>int</code> value from the server response stream.
     *
     * @return the result as a <code>int</code>
     * @throws IOException if an I/O error occurs
     */
    int readInt() throws IOException {
        int b1 = read();
        int b2 = read() << 8;
        int b3 = read() << 16;
        int b4 = read() << 24;

        return b4 | b3 | b2 | b1;
    }

    /**
     * Reads a <code>long</code> value from the server response stream.
     *
     * @return the result as a <code>long</code>
     * @throws IOException if an I/O error occurs
     */
    long readLong() throws IOException {
        long b1 = ((long) read());
        long b2 = ((long) read()) << 8;
        long b3 = ((long) read()) << 16;
        long b4 = ((long) read()) << 24;
        long b5 = ((long) read()) << 32;
        long b6 = ((long) read()) << 40;
        long b7 = ((long) read()) << 48;
        long b8 = ((long) read()) << 56;

        return b1 | b2 | b3 | b4 | b5 | b6 | b7 | b8;
    }

    /**
     * Reads an <code>unsigned long</code> value from the server response stream.
     *
     * @return the result as a <code>BigDecimal</code>
     * @throws IOException if an I/O error occurs
     */
    BigDecimal readUnsignedLong() throws IOException {
        int  b1 = ((int) read() & 0xFF);
        long b2 = ((long) read());
        long b3 = ((long) read()) << 8;
        long b4 = ((long) read()) << 16;
        long b5 = ((long) read()) << 24;
        long b6 = ((long) read()) << 32;
        long b7 = ((long) read()) << 40;
        long b8 = ((long) read()) << 48;
        // Convert via String as BigDecimal(long) is actually BigDecimal(double)
        // on older versions of java
        return new BigDecimal(Long.toString(b2 | b3 | b4 | b5 | b6 | b7 | b8))
                        .multiply(new BigDecimal(256))
                        .add(new BigDecimal(b1));
    }

    /**
     * Discards bytes from the server response stream.
     *
     * @param skip the number of bytes to discard
     * @return the number of bytes skipped
     */
    int skip(int skip) throws IOException {
        int tmp = skip;

        while (skip > 0) {
            if (bufferPtr >= bufferLen) {
                getPacket();
            }

            int available = bufferLen - bufferPtr;

            if (skip > available) {
                skip -= available;
                bufferPtr = bufferLen;
            } else {
                bufferPtr += skip;
                skip = 0;
            }
        }

        return tmp;
    }

    /**
     * Consumes the rest of the server response, without parsing it.
     * <p/>
     * <b>Note:</b> Use only in extreme cases, packets will not be parsed and
     * could leave the connection in an inconsistent state.
     */
    void skipToEnd() {
        try {
            // No more data to read.
            bufferPtr = bufferLen;
            // Now consume all data until we get an exception.
            while (true) {
                buffer = socket.getNetPacket(streamId, buffer);
            }
        } catch (IOException ex) {
            // Ignore it. Probably no more packets.
        }
    }

    /**
     * Closes this response stream. The stream id is unlinked from the
     * underlying shared socket as well.
     */
    void close() {
        isClosed = true;
        socket.closeStream(streamId);
    }

    /**
     * Retrieves the TDS version number.
     *
     * @return the TDS version as an <code>int</code>
     */
    int getTdsVersion() {
        return socket.getTdsVersion();
    }

    /**
     * Retrieves the server type.
     *
     * @return the server type as an <code>int</code>
     */
    int getServerType() {
        return socket.serverType;
    }

    /**
     * Creates a simple <code>InputStream</code> over the server response.
     * <p/>
     * This method can be used to obtain a stream which can be passed to
     * <code>InputStreamReader</code>s to assist in reading multi byte
     * character sets.
     *
     * @param len the number of bytes available in the server response
     * @return the <code>InputStream</code> built over the server response
     */
    InputStream getInputStream(int len) {
        return new TdsInputStream(this, len);
    }

    /**
     * Read the next TDS packet from the network.
     *
     * @throws IOException if an I/O error occurs
     */
    private void getPacket() throws IOException {
        while (bufferPtr >= bufferLen) {
            if (isClosed) {
                throw new IOException("ResponseStream is closed");
            }

            buffer = socket.getNetPacket(streamId, buffer);
            bufferLen = (((int) buffer[2] & 0xFF) << 8) | ((int) buffer[3] & 0xFF);
            bufferPtr = TdsCore.PKT_HDR_LEN;

            if (Logger.isActive()) {
                Logger.logPacket(streamId, true, buffer);
            }
        }
    }

    /**
     * Simple inner class implementing an <code>InputStream</code> over the
     * server response.
     */
    private static class TdsInputStream extends InputStream {
        /** The underlying <code>ResponseStream</code>. */
        ResponseStream tds;
        /** The maximum amount of data to make available. */
        int maxLen;

        /**
         * Creates a <code>TdsInputStream</code> instance.
         *
         * @param tds    the underlying <code>ResponseStream</code>
         * @param maxLen the maximum amount of data that will be available
         */
        public TdsInputStream(ResponseStream tds, int maxLen) {
            this.tds = tds;
            this.maxLen = maxLen;
        }

        public int read() throws IOException {
            return (maxLen-- > 0)? tds.read(): -1;
        }

        public int read(byte[] bytes, int offset, int len) throws IOException {
            if (maxLen < 1) {
                return -1;
            } else {
                int bc = Math.min(maxLen, len);
                if (bc > 0) {
                    bc = tds.read(bytes, offset, bc);
                    maxLen -= (bc == -1) ? 0 : bc;
                }
                return bc;
            }
        }
    }
}
