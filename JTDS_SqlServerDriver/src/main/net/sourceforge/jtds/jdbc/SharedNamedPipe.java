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

import java.io.BufferedInputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.UnknownHostException;

import jcifs.Config;
import jcifs.smb.NtlmPasswordAuthentication;
import jcifs.smb.SmbNamedPipe;

/**
 * This class implements inter-process communication (IPC) to the
 * database server using named pipes.
 *
 * @todo Extract abstract base class SharedIpc from <code>SharedSocket</code> and this class.
 * @todo Implement connection timeouts for named pipes.
 *
 * @author David D. Kilzer
 * @version $Id: SharedNamedPipe.java,v 1.19.2.2 2009-12-10 09:54:04 ickzon Exp $
 */
public class SharedNamedPipe extends SharedSocket {
    /**
     * The shared named pipe.
     */
    private SmbNamedPipe pipe;

    /**
     * Creates a new instance of <code>SharedNamedPipe</code>.
     *
     * @param connection
     * @throws IOException if the named pipe or its input or output streams do
     *                     not open
     * @throws UnknownHostException if host cannot be found for the named pipe
     */
    public SharedNamedPipe(ConnectionJDBC2 connection) throws IOException {
        super(connection.getBufferDir(), connection.getTdsVersion(), connection.getServerType());

        // apply socketTimeout as responseTimeout
        int timeout = connection.getSocketTimeout() * 1000;
        String val = String.valueOf(timeout > 0 ? timeout : Integer.MAX_VALUE);
        Config.setProperty("jcifs.smb.client.responseTimeout", val);
        Config.setProperty("jcifs.smb.client.soTimeout", val);

        NtlmPasswordAuthentication auth = new NtlmPasswordAuthentication(
                connection.getDomainName(), connection.getUser(), connection.getPassword());

        StringBuffer url = new StringBuffer(32);

        url.append("smb://");
        url.append(connection.getServerName());
        url.append("/IPC$");

        final String instanceName = connection.getInstanceName();
        if (instanceName != null && instanceName.length() != 0) {
            url.append("/MSSQL$");
            url.append(instanceName);
        }

        String namedPipePath = DefaultProperties.getNamedPipePath(connection.getServerType());
        url.append(namedPipePath);

        setPipe(new SmbNamedPipe(url.toString(), SmbNamedPipe.PIPE_TYPE_RDWR, auth));

        setOut(new DataOutputStream(getPipe().getNamedPipeOutputStream()));

        final int bufferSize = Support.calculateNamedPipeBufferSize(
                connection.getTdsVersion(), connection.getPacketSize());
        setIn(new DataInputStream(
                new BufferedInputStream(
                        getPipe().getNamedPipeInputStream(), bufferSize)));
    }

    /**
     * Get the connected status of this socket.
     *
     * @return true if the underlying socket is connected
     */
    boolean isConnected() {
        return getPipe() != null;
    }

    /**
     * Close the socket (noop if in shared mode).
     */
    void close() throws IOException {
        super.close();
        getOut().close();
        getIn().close();
        //getPipe().close();
    }

    /**
     * Force close the socket causing any pending reads/writes to fail.
     * <p/>
     * Used by the login timer to abort a login attempt.
     */
    void forceClose() {
        try {
            getOut().close();
        }
        catch (IOException e) {
            // Ignore
        }
        finally {
            setOut(null);
        }

        try {
            getIn().close();
        }
        catch (IOException e) {
            // Ignore
        }
        finally {
            setIn(null);
        }

        setPipe(null);
    }


    /**
     * Getter for {@link SharedNamedPipe#pipe} field.
     *
     * @return {@link SmbNamedPipe} used for communication
     */
    private SmbNamedPipe getPipe() {
        return pipe;
    }


    /**
     * Setter for {@link SharedNamedPipe#pipe} field.
     *
     * @param pipe {@link SmbNamedPipe} to be used for communication
     */
    private void setPipe(SmbNamedPipe pipe) {
        this.pipe = pipe;
    }


    /**
     * Set the socket timeout.
     * <p/>
     * Noop for now; timeouts are not implemented for SMB named pipes.
     *
     * @param timeout timeout value in milliseconds
     */
    protected void setTimeout(int timeout) {
        // FIXME - implement timeout functionality
    }
}
