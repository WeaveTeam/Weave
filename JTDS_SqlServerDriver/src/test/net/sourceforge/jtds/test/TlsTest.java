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
package net.sourceforge.jtds.test;

import java.sql.ResultSet;
import java.sql.Statement;

/**
 * Test for SSL TLS.
 * 
 * @author  Mike Hutchinson
 * @version $Id: TlsTest.java,v 1.1 2005-04-15 13:03:43 alin_sinpalean Exp $
 */
public class TlsTest extends DatabaseTestCase {

    public TlsTest(String name) {
        super(name);
    }

    /**
     * Test for problem resuming TLS session with SQL Server (bug [1102505] SSL
     * TLS resume failure).
     */
    public void testTLSResume() throws Exception {
        // This connection will have established the session key
        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT 'Hello'");
        rs.next();
        assertEquals("Hello", rs.getString(1));
        con.close();
        // This connection will attempt to resume the TLS session
        con = getConnection();
        stmt = con.createStatement();
        rs = stmt.executeQuery("SELECT 'World'");
        rs.next();
        assertEquals("World", rs.getString(1));
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(TlsTest.class);
    }
}
