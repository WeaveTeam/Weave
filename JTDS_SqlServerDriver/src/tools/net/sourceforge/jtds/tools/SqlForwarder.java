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

package net.sourceforge.jtds.tools;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;

/**
 * @author Alin Sinpalean
 * @version $Id: SqlForwarder.java,v 1.2.6.1 2009-08-04 10:33:50 ickzon Exp $
 */
public class SqlForwarder {
    String host = "localhost";
    String logfile = null;
    int port = 1433;
    int listenPort = 1444;
    int lognum = 0;

    byte[] readPacket(InputStream input) throws IOException {
        byte[] hdr = new byte[8];
        int len = input.read(hdr);
        if (len < 8) {
            return null;
        }
        int packetlen = ((((int) hdr[2]) & 0xff) << 8) + (((int) hdr[3]) & 0xff);
        byte[] data = new byte[packetlen];
        while (len < packetlen) {
            len += input.read(data, len, packetlen - len);
        }
        for (int i = 0; i < 8; i++) {
            data[i] = hdr[i];
        }
        return data;
    }

    class ConnectionThread extends Thread {
        Socket client;
        Socket server;

        ConnectionThread(Socket client, Socket server) {
            this.client = client;
            this.server = server;
        }

        public void run() {
            try {
                InputStream input[] = new InputStream[2];
                input[0] = client.getInputStream();
                input[1] = server.getInputStream();

                OutputStream output[] = new OutputStream[2];
                output[0] = server.getOutputStream();
                output[1] = client.getOutputStream();

                PacketLogger log;
                if (logfile == null) {
                    log = new PacketLogger("filter" + lognum++ + ".log");
                } else {
                    log = new PacketLogger(logfile + lognum++ + ".log");
                }

                int direction = 0;
                while (true) {
                    byte[] data = readPacket(input[direction]);
                    if (data == null) {
                        break;
                    }
                    output[direction].write(data);
                    log.log(data);
                    if (data[1] != 0) {
                        direction = 1 - direction;
                    }
                }
                client.close();
                server.close();
            } catch (IOException unused) {
            }
        }
    }

    SqlForwarder() {
    }

    void run() throws IOException {
        System.out.println("Listening on port " + listenPort + "; Connecting to " + host + " at port " + port);
        ServerSocket srv = new ServerSocket(listenPort);
        while (true) {
            Socket client = srv.accept();
            Socket server = new Socket(host, port);
            ConnectionThread t = new ConnectionThread(client, server);
            t.start();
        }
    }

    void parseArgs(String args[]) throws NumberFormatException {
        for (int i = 0; i < args.length; i++) {
            String arg = args[i];
            if (arg.equals("-server")) {
                i++;
                host = args[i];
            } else if (arg.equals("-port")) {
                i++;
                port = Integer.parseInt(args[i]);
            } else if (arg.equals("-listen")) {
                i++;
                listenPort = Integer.parseInt(args[i]);
            } else if (arg.equals("-log")) {
                i++;
                logfile = args[i];
            }
        }
    }

    public static void main(String args[])
            throws IOException {
        SqlForwarder app = new SqlForwarder();
        app.parseArgs(args);
        app.run();
    }
}
