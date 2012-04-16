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

/**
 * This class implements inter-process communication (IPC) to the database
 * server using local named pipes (will only work on Windows).
 *
 * @author  Adam Etheredge
 * @version $Id: SharedLocalNamedPipe.java,v 1.12 2007-07-08 21:38:13 bheineman Exp $
 */
public class SharedLocalNamedPipe extends SharedSocket {
    /**
     * The named pipe as a file.
     */
    RandomAccessFile pipe;

    /**
     * Creates a new instance of <code>SharedLocalNamedPipe</code>.
     *
     * @param connection the connection object
     * @throws IOException if an I/O error occurs
     */
    public SharedLocalNamedPipe(ConnectionJDBC2 connection) throws IOException {
        super(connection.getBufferDir(), connection.getTdsVersion(), connection.getServerType());

        final String serverName = connection.getServerName();
        final String instanceName = connection.getInstanceName();

        final StringBuffer pipeName = new StringBuffer(64);
        pipeName.append("\\\\");
        if (serverName == null || serverName.length() == 0) {
            pipeName.append( '.' );
        } else {
            pipeName.append(serverName);
        }
        pipeName.append("\\pipe");
        if (instanceName != null && instanceName.length() != 0) {
            pipeName.append("\\MSSQL$").append(instanceName);
        }
        String namedPipePath = DefaultProperties.getNamedPipePath(connection.getServerType());
        pipeName.append(namedPipePath.replace('/', '\\'));

        this.pipe = new RandomAccessFile(pipeName.toString(), "rw");

        final int bufferSize = Support.calculateNamedPipeBufferSize(
                connection.getTdsVersion(), connection.getPacketSize());
        setOut(new DataOutputStream(
                new BufferedOutputStream(
                        new FileOutputStream(this.pipe.getFD()), bufferSize)));
        setIn(new DataInputStream(
                new BufferedInputStream(
                        new FileInputStream(this.pipe.getFD()), bufferSize)));
    }

    /**
     * Get the connected status of this socket.
     *
     * @return <code>true</code> if the underlying named pipe is connected
     */
    boolean isConnected() {
        return pipe != null;
    }

    /**
     * Send an network packet. If output for another virtual socket is in
     * progress this packet will be sent later.
     *
     * @param streamId the originating <code>RequestStream</code> object
     * @param buffer   the data to send
     * @exception java.io.IOException if an I/O error occurs
     */
    byte[] sendNetPacket(int streamId, byte buffer[])
            throws IOException {
        byte[] ret = super.sendNetPacket(streamId, buffer);
        getOut().flush();
        return ret;
    }

    /**
     * Close the named pipe and virtual sockets and release any resources.
     */
    void close() throws IOException {
        try {
            // Close virtual sockets
            super.close();

            getOut().close();
            setOut(null);
            getIn().close();
            setIn(null);

            if (pipe != null) {
                pipe.close();
            }
        } finally {
            pipe = null;
        }
    }

    /**
     * Force close the socket causing any pending reads/writes to fail.
     * <p>
     * Used by the login timer to abort a login attempt.
     */
    void forceClose() {
        try {
            getOut().close();
        }
        catch (Exception e) {
            // Ignore
        }
        finally {
            setOut(null);
        }

        try {
            getIn().close();
        }
        catch (Exception e) {
            // Ignore
        }
        finally {
            setIn(null);
        }

        try {
            if (pipe != null) {
                pipe.close();
            }
        } catch (IOException ex) {
        } finally {
            pipe = null;
        }
    }

    /**
     * Set the socket timeout.
     *
     * @param timeout the timeout value in milliseconds
     */
    protected void setTimeout(int timeout) {
        // FIXME - implement timeout functionality
    }
}
