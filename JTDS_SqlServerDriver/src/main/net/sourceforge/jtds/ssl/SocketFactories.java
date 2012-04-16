// jTDS JDBC Driver for Microsoft SQL Server and Sybase
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

import java.io.IOException;
import java.net.InetAddress;
import java.net.Socket;
import java.net.UnknownHostException;
import java.security.GeneralSecurityException;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.X509Certificate;
import javax.net.SocketFactory;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

import net.sourceforge.jtds.util.Logger;

/**
 * Used for acquiring a socket factory when SSL is enabled.
 *
 * @author Rob Worsnop
 * @author Mike Hutchinson
 * @version $Id: SocketFactories.java,v 1.8.2.1 2009-07-23 15:32:51 ickzon Exp $
 */
public class SocketFactories {
    /**
     * Returns a socket factory, the behavior of which will depend on the SSL
     * setting and whether or not the DB server supports SSL.
     *
     * @param ssl    the SSL setting
     * @param socket plain TCP/IP socket to wrap
     */
    public static SocketFactory getSocketFactory(String ssl, Socket socket) {
        return new TdsTlsSocketFactory(ssl, socket);
    }

    /**
     * The socket factory for creating sockets based on the SSL setting.
     */
    private static class TdsTlsSocketFactory extends SocketFactory {
        private static SSLSocketFactory factorySingleton;

        private final String ssl;
        private final Socket socket;

        /**
         * Constructs a TdsTlsSocketFactory.
         *
         * @param ssl      the SSL setting
         * @param socket   the TCP/IP socket to wrap
         */
        public TdsTlsSocketFactory(String ssl, Socket socket) {
            this.ssl = ssl;
            this.socket = socket;
        }

        /**
         * Create the SSL socket.
         * <p/>
         * NB. This method will actually create a connected socket over the
         * TCP/IP network socket supplied via the constructor of this factory
         * class.
         */
        public Socket createSocket(String host, int port)
                throws IOException, UnknownHostException {
            SSLSocket sslSocket = (SSLSocket) getFactory()
                    .createSocket(new TdsTlsSocket(socket), host, port, true);
            //
            // See if connecting to local server.
            // getLocalHost() will normally return the address of a real
            // local network interface so we check that one and the loopback
            // address localhost/127.0.0.1
            //
            // XXX: Disable TLS resume altogether, because the cause of local
            // server failures is unknown and it also seems to sometiles occur
            // with remote servers.
            //
//            if (socket.getInetAddress().equals(InetAddress.getLocalHost()) ||
//                host.equalsIgnoreCase("localhost") || host.startsWith("127.")) {
                // Resume session causes failures with a local server
                // Invalidate the session to prevent resumes.
                sslSocket.startHandshake(); // Any IOException thrown here
                sslSocket.getSession().invalidate();
//                Logger.println("TLS Resume disabled");
//            }

            return sslSocket;
        }

        /*
         * (non-Javadoc)
         *
         * @see javax.net.SocketFactory#createSocket(java.net.InetAddress, int)
         */
        public Socket createSocket(InetAddress host, int port)
                throws IOException {
            return null;
        }

        /*
         * (non-Javadoc)
         *
         * @see javax.net.SocketFactory#createSocket(java.lang.String, int,
         *      java.net.InetAddress, int)
         */
        public Socket createSocket(String host, int port,
                                   InetAddress localHost, int localPort) throws IOException,
                UnknownHostException {
            return null;
        }

        /*
         * (non-Javadoc)
         *
         * @see javax.net.SocketFactory#createSocket(java.net.InetAddress, int,
         *      java.net.InetAddress, int)
         */
        public Socket createSocket(InetAddress host, int port,
                                   InetAddress localHost, int localPort) throws IOException {
            return null;
        }

        /**
         * Returns an SSLSocketFactory whose behavior will depend on the SSL
         * setting.
         *
         * @return an <code>SSLSocketFactory</code>
         */
        private SSLSocketFactory getFactory() throws IOException {
            try {
                if (Ssl.SSL_AUTHENTICATE.equals(ssl)) {
                    // the default factory will produce a socket that authenticates
                    // the server using its certificate chain.
                    return (SSLSocketFactory) SSLSocketFactory.getDefault();
                } else {
                    // Our custom factory will not authenticate the server.
                    return factory();
                }
            } catch (GeneralSecurityException e) {
                Logger.logException(e);
                throw new IOException(e.getMessage());
            }
        }

        /**
         * Returns an SSLSocketFactory whose sockets will not authenticate the
         * server.
         *
         * @return an <code>SSLSocketFactory</code>
         */
        private static SSLSocketFactory factory()
                throws NoSuchAlgorithmException, KeyManagementException {
            if (factorySingleton == null) {
                SSLContext ctx = SSLContext.getInstance("TLS");
                ctx.init(null, trustManagers(), null);
                factorySingleton = ctx.getSocketFactory();
            }
            return factorySingleton;
        }

        private static TrustManager[] trustManagers() {
            X509TrustManager tm = new X509TrustManager() {
                public X509Certificate[] getAcceptedIssuers() {
                    return new X509Certificate[0];
                }

                public void checkServerTrusted(X509Certificate[] chain, String x) {
                    // Dummy method
                }

                public void checkClientTrusted(X509Certificate[] chain, String x) {
                    // Dummy method
                }

            };

            return new X509TrustManager[]{tm};
        }

    }
}