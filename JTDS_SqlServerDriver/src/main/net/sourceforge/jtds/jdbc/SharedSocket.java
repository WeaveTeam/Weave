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

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.EOFException;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.net.Socket;
import java.net.SocketException;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.LinkedList;

import javax.net.SocketFactory;

import net.sourceforge.jtds.ssl.*;
import net.sourceforge.jtds.util.Logger;

/**
 * This class mananges the physical connection to the SQL Server and
 * serialises its use amongst a number of virtual sockets.
 * This allows one physical connection to service a number of concurrent
 * statements.
 * <p>
 * Constraints and assumptions:
 * <ol>
 * <li>Callers will not attempt to read from the server without issuing a request first.
 * <li>The end of a server reply can be identified as byte 2 of the header is non zero.
 * </ol>
 * </p>
 * Comments:
 * <ol>
 * <li>This code will discard unread server data if a new request is issued.
 *    Currently the higher levels of the driver attempt to do this but may be
 *    we can just rely on this code instead.
 * <li>A cancel can be issued by a caller only if the server is currently sending
 *    data for the caller otherwise the cancel is ignored.
 * <li>Cancel packets on their own are returned as extra records appended to the
 *     previous packet so that the TdsCore module can process them.
 * </ol>
 * This version of the class will start to cache results to disk once a predetermined
 * maximum buffer memory threshold has been passed. Small result sets that will fit
 * within a specified limit (default 8 packets) will continue to be held in memory
 * (even if the memory threshold has been passed) in the interests of efficiency.
 *
 * @author Mike Hutchinson.
 * @version $Id: SharedSocket.java,v 1.39.2.4 2009-12-30 14:37:00 ickzon Exp $
 */
class SharedSocket {
    /**
     * This inner class contains the state information for the virtual socket.
     */
    private static class VirtualSocket {
        /**
         * The stream ID of the stream objects owning this state.
         */
        final int owner;
        /**
         * Memory resident packet queue.
         */
        final LinkedList pktQueue;
        /**
         * True to discard network data.
         */
        boolean flushInput;
        /**
         * True if output is complete TDS packet.
         */
        boolean complete;
        /**
         * File object for disk packet queue.
         */
        File queueFile;
        /**
         * I/O Stream for disk packet queue.
         */
        RandomAccessFile diskQueue;
        /**
         * Number of packets cached to disk.
         */
        int pktsOnDisk;
        /**
         * Total of input packets in memory or disk.
         */
        int inputPkts;
        /**
         * Constuct object to hold state information for each caller.
         * @param streamId the Response/Request stream id.
         */
        VirtualSocket(int streamId) {
            this.owner = streamId;
            this.pktQueue = new LinkedList();
            this.flushInput = false;
            this.complete = false;
            this.queueFile = null;
            this.diskQueue = null;
            this.pktsOnDisk = 0;
            this.inputPkts = 0;
        }
    }

    /**
     * The shared network socket.
     */
    private Socket socket;
    /**
     * The shared SSL network socket;
     */
    private Socket sslSocket;
    /**
     * Output stream for network socket.
     */
    private DataOutputStream out;
    /**
     * Input stream for network socket.
     */
    private DataInputStream in;
    /**
     * Current maxium input buffer size.
     */
    private int maxBufSize = TdsCore.MIN_PKT_SIZE;
    /**
     * Table of stream objects sharing this socket.
     */
    private final ArrayList socketTable = new ArrayList();
    /**
     * The Stream ID of the object that is expecting a response from the server.
     */
    private int responseOwner = -1;
    /**
     * Buffer for packet header.
     */
    private final byte hdrBuf[] = new byte[TDS_HDR_LEN];
    /**
     * The directory to buffer data to.
     */
    private final File bufferDir;
    /**
     * Total memory usage in all instances of the driver
     * NB. Access to this field should probably be synchronized
     * but in practice lost updates will not matter much and I think
     * all VMs tend to do atomic saves to integer variables.
     */
    private static int globalMemUsage;
    /**
     * Peak memory usage for debug purposes.
     */
    private static int peakMemUsage;
    /**
     * Max memory limit to use for buffers.
     * Only when this limit is exceeded will the driver
     * start caching to disk.
     */
    private static int memoryBudget = 100000; // 100K
    /**
     * Minimum number of packets that will be cached in memory
     * before the driver tries to write to disk even if
     * memoryBudget has been exceeded.
     */
    private static int minMemPkts = 8;
    /**
     * Global flag to indicate that security constraints mean
     * that attempts to create work files will fail.
     */
    private static boolean securityViolation;
    /**
     * Tds protocol version
     */
    private int tdsVersion;
    /**
     * The servertype one of Driver.SQLSERVER or Driver.SYBASE
     */
    protected final int serverType;
    /**
     * The character set to use for converting strings to/from bytes.
     */
    private CharsetInfo charsetInfo;
    /**
     * Count of packets received.
     */
    private int packetCount;
    /**
     * The server host name.
     */
    private String host;
    /**
     * The server port number.
     */
    private int port;
    /**
     * A cancel packet is pending.
     */
    private boolean cancelPending;
    /**
     * Synchronization monitor for {@link #cancelPending} and
     * {@link #responseOwner}.
     */
    private Object cancelMonitor = new Object();
    /**
     * Buffer for TDS_DONE packets
     */
    private byte doneBuffer[] = new byte[TDS_DONE_LEN];
    /**
     * TDS done token.
     */
    private static final int TDS_DONE_TOKEN = 253;
    /**
     * Length of a TDS_DONE token.
     */
    private static final int TDS_DONE_LEN  = 9;
    /**
     * Length of TDS packet header.
     */
    private static final int TDS_HDR_LEN   = 8;

    protected SharedSocket(File bufferDir, int tdsVersion, int serverType) {
    	this.bufferDir = bufferDir;
        this.tdsVersion = tdsVersion;
        this.serverType = serverType;
    }

    /**
     * Construct a <code>SharedSocket</code> object specifying host name and
     * port.
     *
     * @param connection the connection object
     * @throws IOException if socket open fails
     */
    SharedSocket(ConnectionJDBC2 connection) throws IOException, UnknownHostException {
        this(connection.getBufferDir(), connection.getTdsVersion(), connection.getServerType());
        this.host = connection.getServerName();
        this.port = connection.getPortNumber();
        if (Driver.JDBC3) {
            this.socket = createSocketForJDBC3(connection);
        } else {
            this.socket = new Socket(this.host, this.port);
        }
        setOut(new DataOutputStream(socket.getOutputStream()));
        setIn(new DataInputStream(socket.getInputStream()));
        this.socket.setTcpNoDelay(connection.getTcpNoDelay());
        this.socket.setSoTimeout(connection.getSocketTimeout() * 1000);
        this.socket.setKeepAlive(connection.getSocketKeepAlive());
    }

    /**
     * Creates a {@link Socket} through reflection when {@link Driver#JDBC3}
     * is <code>true</code>.  Reflection must be used to stay compatible
     * with JDK 1.3.
     *
     * @param connection the connection object
     * @return a socket open to the host and port with the given timeout
     * @throws IOException if socket open fails
     */
    private Socket createSocketForJDBC3(ConnectionJDBC2 connection) throws IOException {
        final String host = connection.getServerName();
        final int port = connection.getPortNumber();
        final int loginTimeout = connection.getLoginTimeout();
        final String bindAddress = connection.getBindAddress();
        try {
            // Create the Socket
            Constructor socketConstructor =
                    Socket.class.getConstructor(new Class[] {});
            Socket socket =
                    (Socket) socketConstructor.newInstance(new Object[] {});

            // Create the InetSocketAddress
            Constructor constructor = Class.forName("java.net.InetSocketAddress")
                    .getConstructor(new Class[] {String.class, int.class});
            Object address = constructor.newInstance(
                            new Object[] {host, new Integer(port)});

            // Call Socket.bind(SocketAddress) if bindAddress parameter is set
            if (bindAddress != null && bindAddress.length() > 0) {
                Object localBindAddress = constructor.newInstance(
                        new Object[]{bindAddress, new Integer(0)});
                Method bind = Socket.class.getMethod(
                        "bind", new Class[]{Class.forName("java.net.SocketAddress")});
                bind.invoke(socket, new Object[]{localBindAddress});
            }

            // Call Socket.connect(InetSocketAddress, int)
            Method connect = Socket.class.getMethod("connect", new Class[]
                    {Class.forName("java.net.SocketAddress"), int.class});
            connect.invoke(socket,
                    new Object[] {address, new Integer(loginTimeout * 1000)});

            return socket;
        } catch (InvocationTargetException ite) {
            // Reflection was OK but invocation of socket.bind() or socket.connect()
            // has failed. Try to report the underlying reason
            Throwable cause = ite.getTargetException();
            if (cause instanceof IOException) {
                // OK was an IOException or subclass so just throw it
                throw (IOException) cause;
            }
            // Something else so return invocation exception anyway
            // (This should not normally occur)
            throw (IOException) Support.linkException(
                    new IOException("Could not create socket"), cause);
        } catch (Exception e) {
            // Reflection has failed for some reason e.g. security so
            // try to create a socket in the old way.
            return new Socket(host, port);
        }
    }

    /**
     * Enable TLS encryption by creating a TLS socket over the
     * existing TCP/IP network socket.
     *
     * @param ssl the SSL URL property value
     * @throws IOException if an I/O error occurs
     */
    void enableEncryption(String ssl) throws IOException {
        Logger.println("Enabling TLS encryption");
        SocketFactory sf = Driver.JDBC3 ? 
                 SocketFactories.getSocketFactory(ssl, socket)
               : SocketFactoriesSUN.getSocketFactory(ssl, socket);
        sslSocket = sf.createSocket(getHost(), getPort());
        setOut(new DataOutputStream(sslSocket.getOutputStream()));
        setIn(new DataInputStream(sslSocket.getInputStream()));
    }

    /**
     * Disable TLS encryption and switch back to raw TCP/IP socket.
     *
     * @throws IOException if an I/O error occurs
     */
    void disableEncryption() throws IOException {
        Logger.println("Disabling TLS encryption");
        sslSocket.close();
        sslSocket = null;
        setOut(new DataOutputStream(socket.getOutputStream()));
        setIn(new DataInputStream(socket.getInputStream()));
    }

    /**
     * Set the character set descriptor to be used to translate byte arrays to
     * or from Strings.
     *
     * @param charsetInfo the character set descriptor
     */
    void setCharsetInfo(CharsetInfo charsetInfo) {
        this.charsetInfo = charsetInfo;
    }

    /**
     * Retrieve the character set descriptor used to translate byte arrays to
     * or from Strings.
     */
    CharsetInfo getCharsetInfo() {
        return charsetInfo;
    }

    /**
     * Retrieve the character set name used to translate byte arrays to
     * or from Strings.
     *
     * @return the character set name as a <code>String</code>
     */
    String getCharset() {
        return charsetInfo.getCharset();
    }

    /**
     * Obtain an instance of a server request stream for this socket.
     *
     * @param bufferSize the initial buffer size to be used by the
     *                   <code>RequestStream</code>
     * @param maxPrecision the maximum precision for numeric/decimal types
     * @return the server request stream as a <code>RequestStream</code>
     */
    RequestStream getRequestStream(int bufferSize, int maxPrecision) {
        synchronized (socketTable) {
            int id;
            for (id = 0; id < socketTable.size(); id++) {
                if (socketTable.get(id) == null) {
                    break;
                }
            }

            VirtualSocket vsock = new VirtualSocket(id);

            if (id >= socketTable.size()) {
                socketTable.add(vsock);
            } else {
                socketTable.set(id, vsock);
            }

            return new RequestStream(this, id, bufferSize, maxPrecision);
        }
    }

    /**
     * Obtain an instance of a server response stream for this socket.
     * NB. getRequestStream() must be used first to obtain the RequestStream
     * needed as a parameter for this method.
     *
     * @param requestStream an existing server request stream object obtained
     *                      from this <code>SharedSocket</code>
     * @param bufferSize    the initial buffer size to be used by the
     *                      <code>RequestStream</code>
     * @return the server response stream as a <code>ResponseStream</code>
     */
    ResponseStream getResponseStream(RequestStream requestStream, int bufferSize) {
        return new ResponseStream(this, requestStream.getStreamId(), bufferSize);
    }

    /**
     * Retrieve the TDS version that is active on the connection
     * supported by this socket.
     *
     * @return the TDS version as an <code>int</code>
     */
    int getTdsVersion() {
        return tdsVersion;
    }

    /**
     * Set the TDS version field.
     *
     * @param tdsVersion the TDS version as an <code>int</code>
     */
    protected void setTdsVersion(int tdsVersion) {
        this.tdsVersion = tdsVersion;
    }

    /**
     * Set the global buffer memory limit for all instances of this driver.
     *
     * @param memoryBudget the global memory budget
     */
    static void setMemoryBudget(int memoryBudget) {
        SharedSocket.memoryBudget = memoryBudget;
    }

    /**
     * Get the global buffer memory limit for all instancs of this driver.
     *
     * @return the memory limit as an <code>int</code>
     */
    static int getMemoryBudget() {
        return SharedSocket.memoryBudget;
    }

    /**
     * Set the minimum number of packets to cache in memory before
     * writing to disk.
     *
     * @param minMemPkts the minimum number of packets to cache
     */
    static void setMinMemPkts(int minMemPkts) {
        SharedSocket.minMemPkts = minMemPkts;
    }

    /**
     * Get the minimum number of memory cached packets.
     *
     * @return minimum memory packets as an <code>int</code>
     */
    static int getMinMemPkts() {
        return SharedSocket.minMemPkts;
    }

    /**
     * Get the connected status of this socket.
     *
     * @return <code>true</code> if the underlying socket is connected
     */
    boolean isConnected() {
        return this.socket != null;
    }

    /**
     * Send a TDS cancel packet to the server.
     *
     * @param streamId the <code>RequestStream</code> id
     * @return <code>boolean</code> true if a cancel is actually
     * issued by this method call.
     */
    boolean cancel(int streamId) {
        //
        // Need to synchronize packet send to avoid race conditions on
        // responsOwner and cancelPending
        //
        synchronized (cancelMonitor) {
            //
            // Only send if response pending for the caller.
            // Caller must have aquired connection mutex first.
            // NB. This method will not work with local named pipes
            // as this thread will be blocked in the write until the
            // reading thread has returned from the read.
            //
            if (responseOwner == streamId && !cancelPending) {
                try {
                    //
                    // Send a cancel packet.
                    //
                    cancelPending = true;
                    byte[] cancel = new byte[TDS_HDR_LEN];
                    cancel[0] = TdsCore.CANCEL_PKT;
                    cancel[1] = 1;
                    cancel[2] = 0;
                    cancel[3] = 8;
                    cancel[4] = 0;
                    cancel[5] = 0;
                    cancel[6] = (tdsVersion >= Driver.TDS70) ? (byte) 1 : 0;
                    cancel[7] = 0;
                    getOut().write(cancel, 0, TDS_HDR_LEN);
                    getOut().flush();
                    if (Logger.isActive()) {
                        Logger.logPacket(streamId, false, cancel);
                    }
                    return true;
                } catch (IOException e) {
                    // Ignore error as network is probably dead anyway
                }
            }
        }
        return false;
    }

    /**
     * Close the socket and release all resources.
     *
     * @throws IOException if the socket close fails
     */
    void close() throws IOException {
        if (Logger.isActive()) {
            Logger.println("TdsSocket: Max buffer memory used = " + (peakMemUsage / 1024) + "KB");
        }

        synchronized (socketTable) {
            // See if any temporary files need deleting
            for (int i = 0; i < socketTable.size(); i++) {
                VirtualSocket vsock = (VirtualSocket) socketTable.get(i);

                if (vsock != null && vsock.diskQueue != null) {
                    try {
                        vsock.diskQueue.close();
                        vsock.queueFile.delete();
                    } catch (IOException ioe) {
                        // Ignore errors
                    }
                }
            }
            try {
                if (sslSocket != null) {
                    sslSocket.close();
                    sslSocket = null;
                }
            } finally {
                // Close physical socket
                if (socket != null) {
                    socket.close();
                }
            }
        }
    }

    /**
     * Force close the socket causing any pending reads/writes to fail.
     * <p>
     * Used by the login timer to abort a login attempt.
     */
    void forceClose() {
        if (socket != null) {
            try {
                socket.close();
            } catch (IOException ioe) {
                // Ignore
            } finally {
                sslSocket = null;
                socket = null;
            }
        }
    }

    /**
     * Deallocate a stream linked to this socket.
     *
     * @param streamId the <code>ResponseStream</code> id
     */
    void closeStream(int streamId) {
        synchronized (socketTable) {
            VirtualSocket vsock = lookup(streamId);

            if (vsock.diskQueue != null) {
                try {
                    vsock.diskQueue.close();
                    vsock.queueFile.delete();
                } catch (IOException ioe) {
                    // Ignore errors
                }
            }

            socketTable.set(streamId, null);
        }
    }

    /**
     * Send a network packet. If output for another virtual socket is
     * in progress this packet will be sent later.
     *
     * @param streamId the originating <code>RequestStream</code> object
     * @param buffer   the data to send
     * @return the same buffer received if emptied or another buffer w/ the
     *         same size if the incoming buffer is cached (to avoid copying)
     * @throws IOException if an I/O error occurs
     */
    byte[] sendNetPacket(int streamId, byte buffer[])
            throws IOException {
        synchronized (socketTable) {

            VirtualSocket vsock = lookup(streamId);

            while (vsock.inputPkts > 0) {
                //
                // There is unread data in the input buffers.
                // As we are sending another packet we can just discard it now.
                //
                if (Logger.isActive()) {
                    Logger.println("TdsSocket: Unread data in input packet queue");
                }
                dequeueInput(vsock);
            }

            if (responseOwner != -1) {
                //
                // Complex case there is another stream's data in the network pipe
                // or we had our own incomplete request to discard first
                // Read and store other stream's data or flush our own.
                //
                VirtualSocket other = (VirtualSocket)socketTable.get(responseOwner);
                byte[] tmpBuf = null;
                boolean ourData = (other.owner == streamId);
                do {
                    // Reuse the buffer if it's our data; we don't need it
                    tmpBuf = readPacket(ourData ? tmpBuf : null);

                    if (!ourData) {
                        // We need to save this input as it belongs to
                        // Another thread.
                        enqueueInput(other, tmpBuf);
                    }   // Any of our input is discarded.

                } while (tmpBuf[1] == 0); // Read all data to complete TDS packet
            }
            //
            // At this point we know that we are able to send the first
            // or subsequent packet of a new request.
            //
            getOut().write(buffer, 0, getPktLen(buffer));

            if (buffer[1] != 0) {
                getOut().flush();
                // We are the response owner now
                responseOwner = streamId;
            }

            return buffer;
        }
    }

    /**
     * Get a network packet. This may be read from the network directly or from
     * previously cached buffers.
     *
     * @param streamId the originating ResponseStream object
     * @param buffer   the data buffer to receive the object (may be replaced)
     * @return the data in a <code>byte[]</code> buffer
     * @throws IOException if an I/O error occurs
     */
    byte[] getNetPacket(int streamId, byte buffer[]) throws IOException {
        synchronized (socketTable) {
            VirtualSocket vsock = lookup(streamId);

            //
            // Return any cached input
            //
            if (vsock.inputPkts > 0) {
                return dequeueInput(vsock);
            }

            //
            // Nothing cached see if we are expecting network data
            //
            if (responseOwner == -1) {
                throw new IOException("Stream " + streamId +
                                " attempting to read when no request has been sent");
            }
            //
            // OK There should be data, check that it is for this stream
            //
            if (responseOwner != streamId) {
                // Error we are trying to read another thread's request.
                throw new IOException("Stream " + streamId +
                                " is trying to read data that belongs to stream " +
                                    responseOwner);
            }
            //
            // Simple case we are reading our input directly from the server
            //
            return readPacket(buffer);
        }
    }

    /**
     * Save a packet buffer in a memory queue or to a disk queue if the global
     * memory limit for the driver has been exceeded.
     *
     * @param vsock  the virtual socket owning this data
     * @param buffer the data to queue
     */
    private void enqueueInput(VirtualSocket vsock, byte[] buffer)
            throws IOException {
        //
        // Check to see if we should start caching to disk
        //
        if (globalMemUsage + buffer.length > memoryBudget &&
                vsock.pktQueue.size() >= minMemPkts &&
                !securityViolation &&
                vsock.diskQueue == null) {
            // Try to create a disk file for the queue
            try {
                vsock.queueFile = File.createTempFile("jtds", ".tmp", bufferDir);
                // vsock.queueFile.deleteOnExit(); memory leak, see http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=6664633
                vsock.diskQueue = new RandomAccessFile(vsock.queueFile, "rw");

                // Write current cache contents to disk and free memory
                byte[] tmpBuf;

                while (vsock.pktQueue.size() > 0) {
                    tmpBuf = (byte[]) vsock.pktQueue.removeFirst();
                    vsock.diskQueue.write(tmpBuf, 0, getPktLen(tmpBuf));
                    vsock.pktsOnDisk++;
                }
            } catch (java.lang.SecurityException se) {
                // Not allowed to cache to disk so carry on in memory
                securityViolation = true;
                vsock.queueFile = null;
                vsock.diskQueue = null;
            }
        }

        if (vsock.diskQueue != null) {
            // Cache file exists so append buffer to it
            vsock.diskQueue.write(buffer, 0, getPktLen(buffer));
            vsock.pktsOnDisk++;
        } else {
            // Will cache in memory
            vsock.pktQueue.addLast(buffer);
            globalMemUsage += buffer.length;

            if (globalMemUsage > peakMemUsage) {
                peakMemUsage = globalMemUsage;
            }
        }

        vsock.inputPkts++;
    }

    /**
     * Read a cached packet from the in memory queue or from a disk based queue.
     *
     * @param vsock the virtual socket owning this data
     * @return a buffer containing the packet
     */
    private byte[] dequeueInput(VirtualSocket vsock)
            throws IOException {
        byte[] buffer = null;

        if (vsock.pktsOnDisk > 0) {
            // Data is cached on disk
            if (vsock.diskQueue.getFilePointer() == vsock.diskQueue.length()) {
                // First read so rewind() file
                vsock.diskQueue.seek(0L);
            }

            vsock.diskQueue.readFully(hdrBuf, 0, TDS_HDR_LEN);

            int len = getPktLen(hdrBuf);

            buffer = new byte[len];
            System.arraycopy(hdrBuf, 0, buffer, 0, TDS_HDR_LEN);
            vsock.diskQueue.readFully(buffer, TDS_HDR_LEN, len - TDS_HDR_LEN);
            vsock.pktsOnDisk--;

            if (vsock.pktsOnDisk < 1) {
                // File now empty so close and delete it
                try {
                    vsock.diskQueue.close();
                    vsock.queueFile.delete();
                } finally {
                    vsock.queueFile = null;
                    vsock.diskQueue = null;
                }
            }
        } else if (vsock.pktQueue.size() > 0) {
            buffer = (byte[]) vsock.pktQueue.removeFirst();
            globalMemUsage -= buffer.length;
        }

        if (buffer != null) {
            vsock.inputPkts--;
        }

        return buffer;
    }

    /**
     * Read a physical TDS packet from the network.
     *
     * @param buffer a buffer to read the data into (if it fits) or null
     * @return either the incoming buffer if it was large enough or a newly
     *         allocated buffer with the read packet
     */
    private byte[] readPacket(byte buffer[])
            throws IOException {
        //
        // Read rest of header
        try {
            getIn().readFully(hdrBuf);
        } catch (EOFException e) {
            throw new IOException("DB server closed connection.");
        }

        byte packetType = hdrBuf[0];

        if (packetType != TdsCore.LOGIN_PKT
                && packetType != TdsCore.QUERY_PKT
                && packetType != TdsCore.SYBQUERY_PKT // required to connect IBM/Netcool Omnibus, see patch [1844846]
                && packetType != TdsCore.REPLY_PKT) {
            throw new IOException("Unknown packet type 0x" +
                                    Integer.toHexString(packetType & 0xFF));
        }

        // figure out how many bytes are remaining in this packet.
        int len = getPktLen(hdrBuf);

        if (len < TDS_HDR_LEN || len > 65536) {
            throw new IOException("Invalid network packet length " + len);
        }

        if (buffer == null || len > buffer.length) {
            // Create or expand the buffer as required
            buffer = new byte[len];

            if (len > maxBufSize) {
                maxBufSize = len;
            }
        }

        // Preserve the packet header in the buffer
        System.arraycopy(hdrBuf, 0, buffer, 0, TDS_HDR_LEN);

        try {
            getIn().readFully(buffer, TDS_HDR_LEN, len - TDS_HDR_LEN);
        } catch (EOFException e) {
            throw new IOException("DB server closed connection.");
        }

        //
        // SQL Server 2000 < SP3 does not set the last packet
        // flag in the NT challenge packet.
        // If this is the first packet and the length is correct
        // force the last packet flag on.
        //
        if (++packetCount == 1 && serverType == Driver.SQLSERVER
                && "NTLMSSP".equals(new String(buffer, 11, 7))) {
            buffer[1] = 1;
        }

        synchronized (cancelMonitor) {
            //
            // If a cancel request is outstanding check that the last TDS packet
            // is a TDS_DONE with the "cancek ACK" flag set. If it isn't set the
            // "more packets" flag; this will ensure that the stream keeps
            // processing until the "cancel ACK" is processed.
            //
            if (cancelPending) {
                //
                // Move what we assume to be the TDS_DONE packet into doneBuffer
                //
                if (len >= TDS_DONE_LEN + TDS_HDR_LEN) {
                    System.arraycopy(buffer, len - TDS_DONE_LEN, doneBuffer, 0,
                            TDS_DONE_LEN);
                } else {
                    // Packet too short so TDS_DONE record was split over
                    // two packets. Need to reassemble.
                    int frag = len - TDS_HDR_LEN;
                    System.arraycopy(doneBuffer, frag, doneBuffer, 0,
                            TDS_DONE_LEN - frag);
                    System.arraycopy(buffer, TDS_HDR_LEN, doneBuffer,
                            TDS_DONE_LEN - frag, frag);
                }
                //
                // If this is the last packet and there is a cancel pending see
                // if the last packet contains a TDS_DONE token with the cancel
                // ACK set. If not reset the last packet flag so that the dedicated
                // cancel packet is also read and processed.
                //
                if (buffer[1] == 1) {
                    if ((doneBuffer[0] & 0xFF) < TDS_DONE_TOKEN) {
                        throw new IOException("Expecting a TDS_DONE or TDS_DONEPROC.");
                    }

                    if ((doneBuffer[1] & TdsCore.DONE_CANCEL) != 0) {
                        // OK have a cancel ACK packet
                        cancelPending = false;
                    } else {
                        // Must be in next packet so
                        // force client to read next packet
                        buffer[1] = 0;
                    }
                }
            }

            if (buffer[1] != 0) {
                // End of response; connection now free
                responseOwner = -1;
            }
        }

        return buffer;
    }

    /**
     * Retrieves the virtual socket with the given id.
     *
     * @param streamId id of the virtual socket to retrieve
     */
    private VirtualSocket lookup(int streamId) {
        if (streamId < 0 || streamId > socketTable.size()) {
            throw new IllegalArgumentException("Invalid parameter stream ID "
            		+ streamId);
        }

        VirtualSocket vsock = (VirtualSocket)socketTable.get(streamId);

        if (vsock.owner != streamId) {
            throw new IllegalStateException("Internal error: bad stream ID "
            		+ streamId);
        }

        return vsock;
    }

    /**
     * Convert two bytes (in network byte order) in a byte array into a Java
     * short integer.
     *
     * @param buf    array of data
     * @return the 16 bit unsigned value as an <code>int</code>
     */
    static int getPktLen(byte buf[]) {
        int lo = ((int) buf[3] & 0xff);
        int hi = (((int) buf[2] & 0xff) << 8);

        return hi | lo;
    }

    /**
     * Set the socket timeout.
     *
     * @param timeout the timeout value in milliseconds
     */
    protected void setTimeout(int timeout) throws SocketException {
        socket.setSoTimeout(timeout);
    }

    /**
     * Set the socket keep alive.
     *
     * @param keepAlive <code>true</code> to turn on socket keep alive
     */
    protected void setKeepAlive(boolean keepAlive) throws SocketException {
        socket.setKeepAlive(keepAlive);
    }

    /**
     * Getter for {@link SharedSocket#in} field.
     *
     * @return {@link InputStream} used for communication
     */
    protected DataInputStream getIn() {
        return in;
    }

    /**
     * Setter for {@link SharedSocket#in} field.
     *
     * @param in the {@link InputStream} to be used for communication
     */
    protected void setIn(DataInputStream in) {
        this.in = in;
    }

    /**
     * Getter for {@link SharedSocket#out} field.
     *
     * @return {@link OutputStream} used for communication
     */
    protected DataOutputStream getOut() {
        return out;
    }

    /**
     * Setter for {@link SharedSocket#out} field.
     *
     * @param out the {@link OutputStream} to be used for communication
     */
    protected void setOut(DataOutputStream out) {
        this.out = out;
    }

    /**
     * Get the server host name.
     *
     * @return the host name as a <code>String</code>
     */
    protected String getHost() {
        return this.host;
    }

    /**
     * Get the server port number.
     *
     * @return the host port as an <code>int</code>
     */
    protected int getPort() {
        return this.port;
    }

    /**
     * Finalize this object by releasing its resources.
     */
    protected void finalize() throws Throwable {
        close();
        super.finalize();
    }

}