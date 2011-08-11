// jTDS JDBC Driver for Microsoft SQL Server and Sybase
// Copyright (C) 2005 The jTDS Project
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
package net.sourceforge.jtds.test;

import net.sourceforge.jtds.jdbc.Support;



/**
 * Unit tests for the {@link net.sourceforge.jtds.jdbc.Support} class.
 *
 * @author David D. Kilzer
 * @version $Id: SupportUnitTest.java,v 1.1 2005-09-06 23:03:21 ddkilzer Exp $
 */
public class SupportUnitTest extends UnitTestBase {

    private static final String SYSTEM_PROPRETY_OS_NAME = "os.name";
    private String osName;


    /**
     * Constructor.
     *
     * @param name The name of the test.
     */
    public SupportUnitTest(String name) {
        super(name);
    }


    protected void setUp() throws Exception {
        super.setUp();
        this.osName = System.getProperty(SYSTEM_PROPRETY_OS_NAME);
    }


    protected void tearDown() throws Exception {
        System.setProperty(SYSTEM_PROPRETY_OS_NAME, this.osName);
        super.tearDown();
    }


    public void testIsWindowsOS_Linux() {
        System.setProperty(SYSTEM_PROPRETY_OS_NAME, "Linux");
        assertFalse(Support.isWindowsOS());
    }


    public void testIsWindowsOS_MacOSX() {
        System.setProperty(SYSTEM_PROPRETY_OS_NAME, "MacOSX");
        assertFalse(Support.isWindowsOS());
    }


    public void testIsWindowsOS_windows() {
        System.setProperty(SYSTEM_PROPRETY_OS_NAME, "windows");
        assertTrue(Support.isWindowsOS());
    }


    public void testIsWindowsOS_Windows() {
        System.setProperty(SYSTEM_PROPRETY_OS_NAME, "Windows");
        assertTrue(Support.isWindowsOS());
    }


    public void testIsWindowsOS_Windows_XP() {
        System.setProperty(SYSTEM_PROPRETY_OS_NAME, "Windows XP");
        assertTrue(Support.isWindowsOS());
    }

}
