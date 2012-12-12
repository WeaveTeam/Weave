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
package net.sourceforge.jtds.test;

import net.sourceforge.jtds.jdbc.Driver;
import net.sourceforge.jtds.jdbc.SharedNamedPipe;
import net.sourceforge.jtds.jdbc.Support;
import net.sourceforge.jtds.jdbc.TdsCore;



/**
 * Unit tests for the {@link SharedNamedPipe} class.
 *
 * @author David D. Kilzer
 * @version $Id: NamedPipeUnitTest.java,v 1.9 2007-07-08 18:08:54 bheineman Exp $
 */
public class NamedPipeUnitTest extends UnitTestBase {

    /**
     * Constructor.
     *
     * @param name The name of the test.
     */
    public NamedPipeUnitTest(final String name) {
        super(name);
    }


    /**
     * Test that <code>Support.calculateNamedPipeBufferSize(int, int)</code>
     * sets the buffer size appropriately for TDS 4.2 when the packet
     * size is set to 0.
     */
    public void testCalculateBufferSize_TDS42() {
        int length = invoke_calculateBufferSize(Driver.TDS42, 0);
        assertEquals(TdsCore.MIN_PKT_SIZE, length);
    }


    /**
     * Test that <code>Support.calculateNamedPipeBufferSize(int, int)</code>
     * sets the buffer size appropriately for TDS 5.0 when the packet
     * size is set to 0.
     */
    public void testCalculateBufferSize_TDS50() {
        int length = invoke_calculateBufferSize(Driver.TDS50, 0);
        assertEquals(TdsCore.MIN_PKT_SIZE, length);
    }


    /**
     * Test that <code>Support.calculateNamedPipeBufferSize(int, int)</code>
     * sets the buffer size appropriately for TDS 7.0 when the packet
     * size is set to 0.
     */
    public void testCalculateBufferSize_TDS70() {
        int length = invoke_calculateBufferSize(Driver.TDS70, 0);
        assertEquals(TdsCore.DEFAULT_MIN_PKT_SIZE_TDS70, length);
    }


    /**
     * Test that <code>Support.calculateNamedPipeBufferSize(int, int)</code>
     * sets the buffer size appropriately for TDS 8.0 when the packet
     * size is set to 0.
     */
    public void testCalculateBufferSize_TDS80() {
        int length = invoke_calculateBufferSize(Driver.TDS80, 0);
        assertEquals(TdsCore.DEFAULT_MIN_PKT_SIZE_TDS70, length);
    }


    /**
     * Helper method to invoke {@link Support#calculateNamedPipeBufferSize(int, int)}
     * using reflection.
     *
     * @param tdsVersion The TDS version as an <code>int</code>.
     * @param packetSize The packet size as an <code>int</code>.
     * @return Result of calling {@link Support#calculateNamedPipeBufferSize(int, int)}.
     */
    private int invoke_calculateBufferSize(int tdsVersion, int packetSize) {
        Class[] classes = new Class[]{int.class, int.class};
        Object[] objects = new Object[]{new Integer(tdsVersion), new Integer(packetSize)};

        return ((Integer) invokeStaticMethod(Support.class,
                "calculateNamedPipeBufferSize", classes, objects)).intValue();
    }
}
