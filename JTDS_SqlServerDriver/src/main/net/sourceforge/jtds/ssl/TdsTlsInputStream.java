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
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
//Lesser General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public
//License along with this library; if not, write to the Free Software
//Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
//
package net.sourceforge.jtds.ssl;

import java.io.ByteArrayInputStream;
import java.io.FilterInputStream;
import java.io.IOException;
import java.io.InputStream;

import net.sourceforge.jtds.jdbc.TdsCore;

/**
 * An input stream that filters out TDS headers so they are not returned to
 * JSSE (which will not recognize them).
 *
 * @author Rob Worsnop
 * @author Mike Hutchinson
 * @version $Id: TdsTlsInputStream.java,v 1.5 2005-10-20 09:46:38 alin_sinpalean Exp $
 */
class TdsTlsInputStream extends FilterInputStream {

    int bytesOutstanding;

    /**
     * Temporary buffer used to de-encapsulate inital TLS packets.
     * Initial size should be enough for login phase after which no
     * buffering is required.
     */
    final byte[] readBuffer = new byte[6144];

    InputStream bufferStream;

    /** False if TLS packets are encapsulated in TDS packets. */
    boolean pureSSL;

    /**
     * Constructs a TdsTlsInputStream and bases it on an underlying stream.
     *
     * @param in the underlying stream
     */
    public TdsTlsInputStream(InputStream in) {
        super(in);
    }

    /*
     * (non-Javadoc)
     *
     * @see java.io.InputStream#read(byte[], int, int)
     */
    public int read(byte[] b, int off, int len) throws IOException {

        //
        // If we have read past the TDS encapsulated TLS records
        // Just read directly from the input stream.
        //
        if (pureSSL && bufferStream == null) {
            return in.read(b, off, len);
        }

        // If this is the start of a new TLS record or
        // TDS packet we need to read in entire record/packet.
        if (!pureSSL && bufferStream == null) {
            primeBuffer();
        }

        // Feed the client code bytes from the buffer
        int ret = bufferStream.read(b, off, len);
        bytesOutstanding -= ret < 0 ? 0 : ret;
        if (bytesOutstanding == 0) {
            // All bytes in the buffer have been read.
            // The next read will prime it again.
            bufferStream = null;
        }

        return ret;
    }

    /**
     * Read in entire TLS record or TDS packet and store the TLS record in the
     * buffer. (TDS packets will always contain a TLS record.)
     */
    private void primeBuffer() throws IOException {
        // first read the type (first byte for TDS and TLS).
        // TLS packet hdr size = 5 TDS = 8
        readFully(readBuffer, 0, Ssl.TLS_HEADER_SIZE);
        int len;
        if (readBuffer[0] == TdsCore.REPLY_PKT
                || readBuffer[0] == TdsCore.PRELOGIN_PKT) {
            len = ((readBuffer[2] & 0xFF) << 8) | (readBuffer[3] & 0xFF);
            // Read rest of header to skip
            readFully(readBuffer, Ssl.TLS_HEADER_SIZE, TdsCore.PKT_HDR_LEN - Ssl.TLS_HEADER_SIZE );
            len -= TdsCore.PKT_HDR_LEN;
            readFully(readBuffer, 0, len); // Now get inner packet
        } else {
            len = ((readBuffer[3] & 0xFF) << 8) | (readBuffer[4] & 0xFF);
            readFully(readBuffer, Ssl.TLS_HEADER_SIZE, len - Ssl.TLS_HEADER_SIZE);
            pureSSL = true;
        }

        bufferStream = new ByteArrayInputStream(readBuffer, 0, len);
        bytesOutstanding = len;
    }

    /**
     * Reads <code>len</code> bytes or throws an <code>IOException</code> if
     * there aren't that many bytes available.
     *
     * @param b   buffer to read into
     * @param off offset in the buffer where to start storing
     * @param len amount of data to read
     * @throws IOException if an I/O error occurs or not enough data is
     *                     available
     */
    private void readFully(byte[] b, int off, int len) throws IOException {
        int res = 0;
        while (len > 0 && (res = in.read(b, off, len)) >= 0) {
            off += res;
            len -= res;
        }

        if (res < 0) {
            throw new IOException();
        }
    }
}
