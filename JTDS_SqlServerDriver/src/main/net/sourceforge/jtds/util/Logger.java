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
package net.sourceforge.jtds.util;

import java.sql.*;
import java.io.PrintWriter;
import java.io.FileOutputStream;
import java.io.IOException;

/**
 * Class providing static methods to log diagnostics.
 * <p>
 * There are three ways to enable logging:
 * <ol>
 * <li>Pass a valid PrintWriter to DriverManager.setLogWriter().
 * <li>Pass a valid PrintWriter to DataSource.setLogWriter().
 * <li>For backwards compatibility call Logger.setActive();
 * </ol>
 *
 * @author Mike Hutchinson
 * @version $Id: Logger.java,v 1.11.2.1 2009-08-07 14:02:11 ickzon Exp $
 */
public class Logger {
    /** PrintWriter stream set by DataSource. */
    private static PrintWriter log;

    /**
     * Set the logging PrintWriter stream.
     *
     * @param out the PrintWriter stream
     */
    public static void setLogWriter(PrintWriter out) {
        log = out;
    }

    /**
     * Get the logging PrintWriter Stream.
     *
     * @return the logging stream as a <code>PrintWriter</code>
     */
    public static PrintWriter getLogWriter() {
        return log;
    }

    /**
     * Retrieve the active status of the logger.
     *
     * @return <code>boolean</code> true if logging enabled
     */
    public static boolean isActive() {
        return(log != null || DriverManager.getLogWriter() != null);
    }

    /**
     * Print a diagnostic message to the output stream provided by
     * the DataSource or the DriverManager.
     *
     * @param message the diagnostic message to print
     */
    public static void println(String message) {
        if (log != null) {
            log.println(message);
        } else {
            DriverManager.println(message);
        }
    }
    private static final char hex[] =
    {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

    /**
     * Print a dump of the current input or output network packet.
     *
     * @param streamId the owner of this packet
     * @param in       true if this is an input packet
     * @param pkt      the packet data
     */
    public static void logPacket(int streamId, boolean in, byte[] pkt) {
        int len = ((pkt[2] & 0xFF) << 8)| (pkt[3] & 0xFF);

        StringBuffer line = new StringBuffer(80);

        line.append("----- Stream #");
        line.append(streamId);
        line.append(in ? " read" : " send");
        line.append((pkt[1] != 0) ? " last " : " ");

        switch (pkt[0]) {
            case 1:
                line.append("Request packet ");
                break;
            case 2:
                line.append("Login packet ");
                break;
            case 3:
                line.append("RPC packet ");
                break;
            case 4:
                line.append("Reply packet ");
                break;
            case 6:
                line.append("Cancel packet ");
                break;
            case 14:
                line.append("XA control packet ");
                break;
            case 15:
                line.append("TDS5 Request packet ");
                break;
            case 16:
                line.append("MS Login packet ");
                break;
            case 17:
                line.append("NTLM Authentication packet ");
                break;
            case 18:
                line.append("MS Prelogin packet ");
                break;
            default:
                line.append("Invalid packet ");
                break;
        }

        println(line.toString());
        println("");
        line.setLength(0);

        for (int i = 0; i < len; i += 16) {
            if (i < 1000) {
                line.append(' ');
            }

            if (i < 100) {
                line.append(' ');
            }

            if (i < 10) {
                line.append(' ');
            }

            line.append(i);
            line.append(':').append(' ');

            int j = 0;

            for (; j < 16 && i + j < len; j++) {
                int val = pkt[i+j] & 0xFF;

                line.append(hex[val >> 4]);
                line.append(hex[val & 0x0F]);
                line.append(' ');
            }

            for (; j < 16 ; j++) {
                line.append("   ");
            }

            line.append('|');

            for (j = 0; j < 16 && i + j < len; j++) {
                int val = pkt[i + j] & 0xFF;

                if (val > 31 && val < 127) {
                    line.append((char) val);
                } else {
                    line.append(' ');
                }
            }

            line.append('|');
            println(line.toString());
            line.setLength(0);
        }

        println("");
    }

    /**
     * Print an Exception stack trace to the log.
     *
     * @param e the exception to log
     */
    public static void logException(Exception e) {
        if (log != null) {
            e.printStackTrace(log);
        } else if (DriverManager.getLogWriter() != null) {
            e.printStackTrace(DriverManager.getLogWriter());
        }
    }

    //
    // Backward compatibility method
    //
    /**
     * Turn the logging on or off.
     *
     * @deprecated Use the JDBC standard mechanisms to enable logging.
     * @param value  true to turn on logging
     */
    public static void setActive(boolean value) {
        if (value && log == null) {
            try {
                log = new PrintWriter(new FileOutputStream("log.out"), true);
            } catch (IOException e) {
                log = null; // Sorry no logging!
            }
        }
    }
}