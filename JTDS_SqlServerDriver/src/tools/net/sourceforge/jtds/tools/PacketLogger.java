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

import java.io.*;

/**
 * @author Alin Sinpalean
 * @version $Id: PacketLogger.java,v 1.2.6.1 2009-08-04 10:33:50 ickzon Exp $
 */
public class PacketLogger
{
    PrintStream out;

    static String hexstring = "0123456789ABCDEF";
    static String hex(byte b)
    {
        int ln = (int)(b & 0xf);
        int hn = (int)((b & 0xf0) >> 4);
        return "" + hexstring.charAt(hn) + hexstring.charAt(ln);
    }
    static String hex(short b)
    {
        byte lb = (byte)(b & 0x00ff);
        byte hb = (byte)((b & 0xff00) >> 8);
        return hex(hb) + hex(lb);
    }
    public PacketLogger(String filename) throws IOException
    {
        out = new PrintStream(new FileOutputStream(new File(filename)));
    }

    public void log(byte[] packet)
    {
        short pos = 0;
        while (pos < packet.length)
        {
            out.print(hex(pos) + ": ");
            short startpos = pos;
            pos += 16;
            if (pos > packet.length)
                pos = (short)packet.length;
            for (short i = startpos; i < pos; i++)
            {
                out.print(hex(packet[i]) + " ");
            }
            for (short i = pos; i < startpos + 16; i++)
                out.print("   ");
            out.print("    ");
            for (short i = startpos; i < startpos + 16; i++)
            {
                if (i >= pos)
                    out.print(" ");
                else if (packet[i] < 32)
                    out.print(".");
                else
                    out.print((char)packet[i]);
            }
            out.println("");
        }
        out.println("");
    }
}
