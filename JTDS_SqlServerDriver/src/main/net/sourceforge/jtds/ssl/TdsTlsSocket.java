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
package net.sourceforge.jtds.ssl;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.net.SocketException;

/**
 * A socket that mediates between JSSE and the DB server.
 *
 * @author Rob Worsnop
 * @author Mike Hutchinson
 * @version $Id: TdsTlsSocket.java,v 1.3.2.1 2009-08-07 14:02:11 ickzon Exp $
 */
class TdsTlsSocket extends Socket {
    private final Socket delegate;
    private final InputStream istm;
    private final OutputStream ostm;

    /**
     * Constructs a TdsTlsSocket around an underlying socket.
     *
     * @param delegate the underlying socket
     */
    TdsTlsSocket(Socket delegate) throws IOException {
        this.delegate = delegate;
        istm = new TdsTlsInputStream(delegate.getInputStream());
        ostm = new TdsTlsOutputStream(delegate.getOutputStream());
    }

    /*
     * (non-Javadoc)
     *
     * @see java.net.Socket#close()
     */
    public synchronized void close() throws IOException {
        // Do nothing. Underlying socket closed elsewhere
    }

    /*
     * (non-Javadoc)
     *
     * @see java.net.Socket#getInputStream()
     */
    public InputStream getInputStream() throws IOException {
        return istm;
    }

    /*
     * (non-Javadoc)
     *
     * @see java.net.Socket#getOutputStream()
     */
    public OutputStream getOutputStream() throws IOException {
        return ostm;
    }

    /*
     * (non-Javadoc)
     *
     * @see java.net.Socket#isConnected()
     */
    public boolean isConnected() {
        return true;
    }

    /*
     * (non-Javadoc)
     *
     * @see java.net.Socket#setSoTimeout(int)
     */
    public synchronized void setSoTimeout(int timeout) throws SocketException {
        delegate.setSoTimeout(timeout);
    }

    /*
     * (non-Javadoc)
     *
     * @see java.net.Socket#setKeepAlive(boolean)
     */
    public synchronized void setKeepAlive(boolean keepAlive) throws SocketException {
        delegate.setKeepAlive(keepAlive);
    }

    /*
     * (non-Javadoc)
     *
     * @see java.net.Socket#setTcpNoDelay(boolean)
     */
    public void setTcpNoDelay(boolean on) throws SocketException {
        delegate.setTcpNoDelay(on);
    }
}