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

import net.sourceforge.jtds.jdbc.NtlmAuth;

import java.util.Arrays;

/**
 * Unit test for NTLM challenge/response calculation
 *
 * @author mdb
 * @version $Id: NtlmAuthTest.java,v 1.5.2.1 2009-08-04 10:33:54 ickzon Exp $
 */
public class NtlmAuthTest extends TestBase {
    public NtlmAuthTest(String name) {
        super(name);
    }

    public static byte[] hexToBytes(String hex)
    {
        byte[] rtn = new byte[hex.length() / 2];
        for(int i=0; i < rtn.length; i++)
        {
            rtn[i] = (byte)Integer.parseInt(hex.substring(i*2,(i+1)*2),16);
        }
        return rtn;
    }

    /**
     * Tests the NT challenge/response against a known-good value. This was captured
     * from a successful login to one of my (mdb's) test computers.
     */
    public void testChallengeResponse() throws Exception {
        final String password  = "bark";
        byte[] challenge = new byte[] {
            (byte)0xd9, (byte)0x90, (byte)0xed, (byte)0xaf,
            (byte)0x94, (byte)0x17, (byte)0x36, (byte)0xaf};

        byte[] ntResp = NtlmAuth.answerNtChallenge(password, challenge);
        byte[] lmResp = NtlmAuth.answerLmChallenge(password, challenge);

        byte[] ntExpected = new byte[] {
            (byte)0x8e, (byte)0x75, (byte)0x8e, (byte)0x79, (byte)0xe2, (byte)0xa1, (byte)0x45, (byte)0x75,
            (byte)0xb4, (byte)0x21, (byte)0x55, (byte)0x9b, (byte)0x12, (byte)0x29, (byte)0xd3, (byte)0x5a,
            (byte)0x23, (byte)0x8b, (byte)0x7d, (byte)0xa8, (byte)0x3a, (byte)0x50, (byte)0xc6, (byte)0xa7};


        byte[] lmExpected = new byte[] {
            (byte)0xe6, (byte)0x19, (byte)0x92, (byte)0xcd, (byte)0x84, (byte)0xf7, (byte)0xb8, (byte)0x49,
            (byte)0xaf, (byte)0x75, (byte)0xf9, (byte)0x37, (byte)0xd4, (byte)0x0b, (byte)0xe6, (byte)0x81,
            (byte)0xc4, (byte)0x0c, (byte)0x7c, (byte)0x3f, (byte)0x3e, (byte)0xc6, (byte)0x8b, (byte)0x7f};


        assertTrue(Arrays.equals(ntResp, ntExpected));
        assertTrue(Arrays.equals(lmResp, lmExpected));
    }


    //--------------------------------------------------------------------------
    // these tests came from the web page:
    //    http://davenport.sourceforge.net/ntlm.html
    //--------------------------------------------------------------------------

    public void testLMv2() throws Exception
    {
        byte[] answer =
            NtlmAuth.answerLmv2Challenge( "DOMAIN", "user", "SecREt01",
                hexToBytes("0123456789abcdef"),
                hexToBytes("ffffff0011223344"));

        byte[] expected = hexToBytes( "d6e6152ea25d03b7c6ba6629c2d6aaf0ffffff0011223344");

        assertTrue(Arrays.equals(answer, expected));
    }

    public void testNTLMv2() throws Exception
    {
        byte[] answer =
            NtlmAuth.answerNtlmv2Challenge( "DOMAIN", "user", "SecREt01",
                hexToBytes("0123456789abcdef"), //nonce
                //target info:
                hexToBytes("02000c0044004f004d00410049004e0001000c005300450052" +
                           "005600450052000400140064006f006d00610069006e002e00" +
                           "63006f006d00030022007300650072007600650072002e0064" +
                           "006f006d00610069006e002e0063006f006d0000000000"),
                hexToBytes("ffffff0011223344"),//client nonce
                1055844000000L); //timestamp


        byte[] expected = hexToBytes(
                "cbabbca713eb795d04c97abc01ee4983" +
                "01010000000000000090d336b734c301" +
                "ffffff00112233440000000002000c00" +
                "44004f004d00410049004e0001000c00" +
                "53004500520056004500520004001400" +
                "64006f006d00610069006e002e006300" +
                "6f006d00030022007300650072007600" +
                "650072002e0064006f006d0061006900" +
                "6e002e0063006f006d00000000000000" +
                "0000");

        assertTrue(Arrays.equals(answer, expected));
    }

    public void testTimestampConversion() throws Exception
    {
        long time = 1055844000000L;
        byte[] ts =
            NtlmAuth.createTimestamp(time);

        byte[] expected = hexToBytes("0090d336b734c301");
        assertTrue(Arrays.equals(ts, expected));
    }


    //--------------------------------------------------------------------------
    // these came from tests with real data:
    //--------------------------------------------------------------------------

    public void testLMv2CapturedData() throws Exception
    {
        byte[] answer =
            NtlmAuth.answerLmv2Challenge( "MDB-PADRE", "dog", "bark",
                hexToBytes("73f35b0fe01a5a31"),
                hexToBytes("2c66391a0a1b7881"));

        byte[] expected = hexToBytes( "4dc364696984b6e07df1a659313f277a2c66391a0a1b7881");

        assertTrue(Arrays.equals(answer, expected));
    }

    public void testNTLMv2CapturedData() throws Exception
    {
        byte[] targetInfo = hexToBytes(
        "02000c004200450041004500" +
        "4e004700010014004d00440042002d00" +
        "42005200450057004500520004002200" +
        "62006500610065006e0067002e006d00" +
        "6600650065006e0067002e006f007200" +
        "6700030038006d00640062002d006200" +
        "720065007700650072002e0062006500" +
        "610065006e0067002e006d0066006500" +
        "65006e0067002e006f00720067000500" +
        "14006d006600650065006e0067002e00" +
        "6f007200670000000000");

        byte[] answer =
            NtlmAuth.answerNtlmv2Challenge( "MDB-PADRE", "dog", "bark",
                hexToBytes("73f35b0fe01a5a31"),
                targetInfo,
                hexToBytes("2c66391a0a1b7881"),
                hexToBytes("06198e3a444dc601"));

        byte[] expected = hexToBytes(
        "5416e7ef86091320" +
        "5b652f7b3002fc7f0101000000000000" +
        "06198e3a444dc6012c66391a0a1b7881" +
        "0000000002000c004200450041004500" +
        "4e004700010014004d00440042002d00" +
        "42005200450057004500520004002200" +
        "62006500610065006e0067002e006d00" +
        "6600650065006e0067002e006f007200" +
        "6700030038006d00640062002d006200" +
        "720065007700650072002e0062006500" +
        "610065006e0067002e006d0066006500" +
        "65006e0067002e006f00720067000500" +
        "14006d006600650065006e0067002e00" +
        "6f00720067000000000000000000");

        //debug...
        /*
        //debug
        public static void dump(byte[] bytes, String fileName)
        {
            try
            {
                FileOutputStream out = new FileOutputStream(fileName);
                out.write( bytes );
                out.close();
            }
            catch(Exception e)
            {
                //don't worry about it
            }
        }

        dump(expected, "/home/brinkley/tmp/ntlm2-expected" );
        dump(answer,   "/home/brinkley/tmp/ntlm2-answer" );
        */

        assertTrue(Arrays.equals(answer, expected));
    }

}

