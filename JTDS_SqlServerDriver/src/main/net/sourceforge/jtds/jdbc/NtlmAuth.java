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

import net.sourceforge.jtds.util.MD4Digest;
import net.sourceforge.jtds.util.DESEngine;
import net.sourceforge.jtds.util.MD5Digest;

import java.io.UnsupportedEncodingException;
import java.util.Arrays;

/**
 * This class calculates the two "responses" to the nonce supplied by the server
 * as a part of NTLM authentication.
 *
 * Much gratitude to the authors of this page, esp. for NTLMv2 info:
 *     http://davenport.sourceforge.net/ntlm.html
 *
 * @author Matt Brinkley
 * @version $Id: NtlmAuth.java,v 1.7 2006-06-23 18:00:56 matt_brinkley Exp $
 */
public class NtlmAuth {

    //-------------------------------------------------------------------------
    // LM/NTLM - public interface
    //-------------------------------------------------------------------------

    public static byte[] answerNtChallenge(String password, byte[] nonce)
        throws UnsupportedEncodingException {
        return encryptNonce(ntHash(password), nonce);
    }

    public static byte[] answerLmChallenge(String pwd, byte[] nonce)
        throws UnsupportedEncodingException {
        byte[] password = convertPassword(pwd);

        DESEngine d1 = new DESEngine(true, makeDESkey(password,  0));
        DESEngine d2 = new DESEngine(true, makeDESkey(password,  7));
        byte[] encrypted = new byte[21];
        Arrays.fill(encrypted, (byte)0);

        d1.processBlock(nonce, 0, encrypted, 0);
        d2.processBlock(nonce, 0, encrypted, 8);

        return encryptNonce(encrypted, nonce);
    }

    //-------------------------------------------------------------------------
    // LM/NTLM v2 - public interface
    //-------------------------------------------------------------------------
    public static byte[] answerNtlmv2Challenge(
            String domain, String user, String password, byte[] nonce,
            byte[] targetInfo,
            byte[] clientNonce)
            throws UnsupportedEncodingException {
        return answerNtlmv2Challenge(
                domain, user, password, nonce, targetInfo, clientNonce,
                System.currentTimeMillis());
    }

    public static byte[] answerNtlmv2Challenge(
            String domain, String user, String password, byte[] nonce,
            byte[] targetInfo,
            byte[] clientNonce,
            byte[] timestamp)
        throws UnsupportedEncodingException {
        byte[] hash = ntv2Hash(domain, user, password);
        byte[] blob = createBlob(targetInfo, clientNonce, timestamp);
        return lmv2Response(hash,blob,nonce);
    }

    public static byte[] answerNtlmv2Challenge(
            String domain, String user, String password, byte[] nonce,
            byte[] targetInfo,
            byte[] clientNonce,
            long now)
        throws UnsupportedEncodingException {
        return answerNtlmv2Challenge(
                domain, user, password, nonce, targetInfo, clientNonce,
                createTimestamp(now));
    }


    public static byte[] answerLmv2Challenge(
            String domain, String user, String password, byte[] nonce, byte[] clientNonce)
        throws UnsupportedEncodingException {
        byte[] hash = ntv2Hash(domain, user, password);
        return lmv2Response(hash, clientNonce, nonce);
    }


    //-------------------------------------------------------------------------
    // LMv2/NTLMv2 impl helpers
    //-------------------------------------------------------------------------

    private static byte[] ntv2Hash(String domain, String user, String password)
        throws UnsupportedEncodingException {
        byte[] hash = ntHash(password);
        String identity = user.toUpperCase() + domain.toUpperCase();
        byte[] identityBytes = identity.getBytes("UnicodeLittleUnmarked");

        return hmacMD5(identityBytes, hash);
    }



    /**
     * Creates the LMv2 Response from the given hash, client data, and
     * Type 2 challenge.
     *
     * @param hash The NTLMv2 Hash.
     * @param clientData The client data (blob or client challenge).
     * @param challenge The server challenge from the Type 2 message.
     *
     * @return The response (either NTLMv2 or LMv2, depending on the
     * client data).
     */
    private static byte[] lmv2Response(byte[] hash, byte[] clientData,
                                       byte[] challenge)
    {
        byte[] data = new byte[challenge.length + clientData.length];
        System.arraycopy(challenge, 0, data, 0, challenge.length);
        System.arraycopy(clientData, 0, data, challenge.length,
                         clientData.length);
        byte[] mac = hmacMD5(data, hash);
        byte[] lmv2Response = new byte[mac.length + clientData.length];
        System.arraycopy(mac,        0, lmv2Response, 0,          mac.length);
        System.arraycopy(clientData, 0, lmv2Response, mac.length, clientData.length);
        return lmv2Response;
    }


    /**
     * Calculates the HMAC-MD5 hash of the given data using the specified
     * hashing key.
     *
     * @param data The data for which the hash will be calculated.
     * @param key The hashing key.
     *
     * @return The HMAC-MD5 hash of the given data.
     */
    private static byte[] hmacMD5(byte[] data, byte[] key)
    {
        byte[] ipad = new byte[64];
        byte[] opad = new byte[64];
        for (int i = 0; i < 64; i++) {
            ipad[i] = (byte) 0x36;
            opad[i] = (byte) 0x5c;
        }
        for (int i = key.length - 1; i >= 0; i--) {
            ipad[i] ^= key[i];
            opad[i] ^= key[i];
        }
        byte[] content = new byte[data.length + 64];
        System.arraycopy(ipad, 0, content, 0, 64);
        System.arraycopy(data, 0, content, 64, data.length);
        data = md5(content);
        content = new byte[data.length + 64];
        System.arraycopy(opad, 0, content, 0, 64);
        System.arraycopy(data, 0, content, 64, data.length);
        return md5(content);
    }

    private static byte[] md5(byte[] data)
    {
        MD5Digest md5 = new MD5Digest();
        md5.update(data, 0, data.length);
        byte[] hash = new byte[16];
        md5.doFinal(hash, 0);
        return hash;
    }


    /**
     * Implementation of HMAC-MD5 that uses the JDK's crypto API
     * We don't use this because of JTDS's support of JDK 1.3.
     */
    /*
    private static byte[] hmacMD5(byte[] data, byte[] key)
            throws NoSuchAlgorithmException, InvalidKeyException
    {
        SecretKey md5key = new SecretKeySpec( key, "HmacMD5" );
        Mac mac = Mac.getInstance(md5key.getAlgorithm());
        mac.init(md5key);
        return  mac.doFinal(data);
    }
    */

    /**
     * Creates a timestamp in the format used in NTLMv2 responses.
     * Public so it could be unit tested.
     * @param time current time, as returned from System.currentTimeMillis
     * @return little-endian byte array of number of tenths of microseconds since
     * Jan 1, 1601
     */
    public static byte[] createTimestamp(long time)
    {
        time += 11644473600000l; // milliseconds from January 1, 1601 -> epoch.
        time *= 10000;           // tenths of a microsecond.

        // convert to little-endian byte array.
        byte[] timestamp = new byte[8];
        for (int i = 0; i < 8; i++) {
            timestamp[i] = (byte) time;
            time >>>= 8;
        }

        return timestamp;
    }

    /**
     * Creates the NTLMv2 blob from the given target information block and
     * client challenge.
     *
     * @param targetInformation The target information block from the Type 2
     * message.
     * @param clientChallenge The random 8-byte client challenge.
     *
     * @return The blob, used in the calculation of the NTLMv2 Response.
     */
    private static byte[] createBlob(byte[] targetInformation,
                                     byte[] clientChallenge,
                                     byte[] timestamp) {
        byte[] blobSignature = new byte[] {
            (byte) 0x01, (byte) 0x01, (byte) 0x00, (byte) 0x00
        };
        byte[] reserved = new byte[] {
            (byte) 0x00, (byte) 0x00, (byte) 0x00, (byte) 0x00
        };
        byte[] unknown1 = new byte[] {
            (byte) 0x00, (byte) 0x00, (byte) 0x00, (byte) 0x00
        };
        byte[] unknown2 = new byte[] {
            (byte) 0x00, (byte) 0x00, (byte) 0x00, (byte) 0x00
        };

        byte[] blob = new byte[blobSignature.length + reserved.length +
                               timestamp.length + clientChallenge.length +
                               unknown1.length + targetInformation.length +
                               unknown2.length];
        int offset = 0;
        System.arraycopy(blobSignature, 0, blob, offset, blobSignature.length);
        offset += blobSignature.length;
        System.arraycopy(reserved, 0, blob, offset, reserved.length);
        offset += reserved.length;
        System.arraycopy(timestamp, 0, blob, offset, timestamp.length);
        offset += timestamp.length;
        System.arraycopy(clientChallenge, 0, blob, offset,
                         clientChallenge.length);
        offset += clientChallenge.length;
        System.arraycopy(unknown1, 0, blob, offset, unknown1.length);
        offset += unknown1.length;
        System.arraycopy(targetInformation, 0, blob, offset,
                         targetInformation.length);
        offset += targetInformation.length;
        System.arraycopy(unknown2, 0, blob, offset, unknown2.length);
        return blob;
    }

    //-------------------------------------------------------------------------
    // LM/NTLM impl helpers
    //-------------------------------------------------------------------------

    private static byte[] encryptNonce(byte[] key, byte[] nonce) {
        byte[] out = new byte[24];

        DESEngine d1 = new DESEngine(true, makeDESkey(key,  0));
        DESEngine d2 = new DESEngine(true, makeDESkey(key,  7));
        DESEngine d3 = new DESEngine(true, makeDESkey(key,  14));

        d1.processBlock(nonce, 0, out, 0);
        d2.processBlock(nonce, 0, out, 8);
        d3.processBlock(nonce, 0, out, 16);

        return out;
    }

    /**
     * Creates the md4 hash of the unicode password. This is used as the DES
     * key when encrypting the nonce for NTLM challenge-response
     */
    private static byte[] ntHash(String password)
            throws UnsupportedEncodingException {
        byte[] key = new byte[21];
        Arrays.fill(key, (byte)0);
        byte[] pwd = password.getBytes("UnicodeLittleUnmarked");

        // do the md4 hash of the unicode passphrase...
        MD4Digest md4 = new MD4Digest();
        md4.update(pwd, 0, pwd.length);
        md4.doFinal(key, 0);
        return key;
    }

    /**
     * Used by answerNtlmChallenge. We need the password converted to caps,
     * narrowed and padded/truncated to 14 chars...
     */
    private static byte[] convertPassword(String password)
        throws UnsupportedEncodingException {
        byte[] pwd = password.toUpperCase().getBytes("UTF8");

        byte[] rtn = new byte[14];
        Arrays.fill(rtn, (byte) 0);
        System.arraycopy(
            pwd, 0,                                 // src
            rtn, 0,                                 // dst
            pwd.length > 14 ? 14 : pwd.length);     // length

        return rtn;
    }

    /**
     * Turns a 7-byte DES key into an 8-byte one by adding parity bits. All
     * implementations of DES seem to want an 8-byte key.
     */
    private static byte[] makeDESkey(byte[] buf, int off) {
        byte[] ret = new byte[8];

        ret[0] = (byte) ((buf[off+0] >> 1) & 0xff);
        ret[1] = (byte) ((((buf[off+0] & 0x01) << 6) | (((buf[off+1] & 0xff)>>2) & 0xff)) & 0xff);
        ret[2] = (byte) ((((buf[off+1] & 0x03) << 5) | (((buf[off+2] & 0xff)>>3) & 0xff)) & 0xff);
        ret[3] = (byte) ((((buf[off+2] & 0x07) << 4) | (((buf[off+3] & 0xff)>>4) & 0xff)) & 0xff);
        ret[4] = (byte) ((((buf[off+3] & 0x0F) << 3) | (((buf[off+4] & 0xff)>>5) & 0xff)) & 0xff);
        ret[5] = (byte) ((((buf[off+4] & 0x1F) << 2) | (((buf[off+5] & 0xff)>>6) & 0xff)) & 0xff);
        ret[6] = (byte) ((((buf[off+5] & 0x3F) << 1) | (((buf[off+6] & 0xff)>>7) & 0xff)) & 0xff);
        ret[7] = (byte) (buf[off+6] & 0x7F);

        for (int i = 0; i < 8; i++) {
            ret[i] = (byte) (ret[i] << 1);
        }

        return ret;
    }
}

