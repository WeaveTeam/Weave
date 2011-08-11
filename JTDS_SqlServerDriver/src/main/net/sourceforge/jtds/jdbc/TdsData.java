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

import java.io.*;
import java.math.BigInteger;
import java.math.BigDecimal;
import java.sql.SQLException;

import net.sourceforge.jtds.util.BlobBuffer;

/**
 * Implement TDS data types and related I/O logic.
 * <p>
 * Implementation notes:
 * <bl>
 * <li>This class encapsulates all the knowledge about reading and writing
 *     TDS data descriptors and related application data.
 * <li>There are four key methods supplied here:
 * <ol>
 * <li>readType() - Reads the column and parameter meta data.
 * <li>readData() - Reads actual data values.
 * <li>writeParam() - Write parameter descriptors and data.
 * <li>getNativeType() - knows how to map JDBC data types to the equivalent TDS type.
 * </ol>
 * </bl>
 *
 * @author Mike Hutchinson
 * @author Alin Sinpalean
 * @author freeTDS project
 * @version $Id: TdsData.java,v 1.60.2.3 2009-11-05 10:42:18 ickzon Exp $
 */
public class TdsData {
    /**
     * This class implements a descriptor for TDS data types;
     *
     * @author Mike Hutchinson.
     */
    private static class TypeInfo {
        /** The SQL type name. */
        public final String sqlType;
        /**
         * The size of this type or &lt; 0 for variable sizes.
         * <p> Special values as follows:
         * <ol>
         * <li> -5 sql_variant type.
         * <li> -4 text, image or ntext types.
         * <li> -2 SQL Server 7+ long char and var binary types.
         * <li> -1 varchar, varbinary, null types.
         * </ol>
         */
        public final int size;
        /**
         * The precision of the type.
         * <p>If this is -1 precision must be calculated from buffer size
         * eg for varchar fields.
         */
        public final int precision;
        /**
         * The display size of the type.
         * <p>-1 If the display size must be calculated from the buffer size.
         */
        public final int displaySize;
        /** true if type is a signed numeric. */
        public final boolean isSigned;
        /** true if type requires TDS80 collation. */
        public final boolean isCollation;
        /** The java.sql.Types constant for this data type. */
        public final int jdbcType;

        /**
         * Construct a new TDS data type descriptor.
         *
         * @param sqlType   SQL type name.
         * @param size Byte size for this type or &lt; 0 for variable length types.
         * @param precision Decimal precision or -1
         * @param displaySize Printout size for this type or special values -1,-2.
         * @param isSigned True if signed numeric type.
         * @param isCollation True if type has TDS 8 collation information.
         * @param jdbcType The java.sql.Type constant for this type.
         */
        TypeInfo(String sqlType, int size, int precision, int displaySize,
                 boolean isSigned, boolean isCollation, int jdbcType) {
            this.sqlType = sqlType;
            this.size = size;
            this.precision = precision;
            this.displaySize = displaySize;
            this.isSigned = isSigned;
            this.isCollation = isCollation;
            this.jdbcType = jdbcType;
        }

    }

    /*
     * Constants for TDS data types
     */
    private static final int SYBCHAR               = 47; // 0x2F
    private static final int SYBVARCHAR            = 39; // 0x27
    private static final int SYBINTN               = 38; // 0x26
    private static final int SYBINT1               = 48; // 0x30
    private static final int SYBDATE               = 49; // 0x31 Sybase 12
    private static final int SYBTIME               = 51; // 0x33 Sybase 12
    private static final int SYBINT2               = 52; // 0x34
    private static final int SYBINT4               = 56; // 0x38
    private static final int SYBINT8               = 127;// 0x7F
    private static final int SYBFLT8               = 62; // 0x3E
    private static final int SYBDATETIME           = 61; // 0x3D
    private static final int SYBBIT                = 50; // 0x32
    private static final int SYBTEXT               = 35; // 0x23
    private static final int SYBNTEXT              = 99; // 0x63
    private static final int SYBIMAGE              = 34; // 0x22
    private static final int SYBMONEY4             = 122;// 0x7A
    private static final int SYBMONEY              = 60; // 0x3C
    private static final int SYBDATETIME4          = 58; // 0x3A
    private static final int SYBREAL               = 59; // 0x3B
    private static final int SYBBINARY             = 45; // 0x2D
    private static final int SYBVOID               = 31; // 0x1F
    private static final int SYBVARBINARY          = 37; // 0x25
    private static final int SYBNVARCHAR           = 103;// 0x67
    private static final int SYBBITN               = 104;// 0x68
    private static final int SYBNUMERIC            = 108;// 0x6C
    private static final int SYBDECIMAL            = 106;// 0x6A
    private static final int SYBFLTN               = 109;// 0x6D
    private static final int SYBMONEYN             = 110;// 0x6E
    private static final int SYBDATETIMN           = 111;// 0x6F
    private static final int SYBDATEN              = 123;// 0x7B SYBASE 12
    private static final int SYBTIMEN              = 147;// 0x93 SYBASE 12
    private static final int XSYBCHAR              = 175;// 0xAF
    private static final int XSYBVARCHAR           = 167;// 0xA7
    private static final int XSYBNVARCHAR          = 231;// 0xE7
    private static final int XSYBNCHAR             = 239;// 0xEF
    private static final int XSYBVARBINARY         = 165;// 0xA5
    private static final int XSYBBINARY            = 173;// 0xAD
    private static final int SYBUNITEXT            = 174;// 0xAE SYBASE 15
    private static final int SYBLONGBINARY         = 225;// 0xE1 SYBASE 12
    private static final int SYBSINT1              = 64; // 0x40
    private static final int SYBUINT2              = 65; // 0x41 SYBASE 15
    private static final int SYBUINT4              = 66; // 0x42 SYBASE 15
    private static final int SYBUINT8              = 67; // 0x43 SYBASE 15
    private static final int SYBUINTN              = 68; // 0x44 SYBASE 15
    private static final int SYBUNIQUE             = 36; // 0x24
    private static final int SYBVARIANT            = 98; // 0x62
    private static final int SYBSINT8              = 191;// 0xBF SYBASE 15

    /*
     * Special case for Sybase 12.5+
     * This long data type is used to send text and image
     * data as statement parameters as a replacement for
     * writetext.
     * As far as I can tell this data type is only sent not
     * received.
     */
    static final int SYBLONGDATA                   = 36; // 0x24 SYBASE 12

    /*
     * Constants for Sybase User Defined data types used to
     * qualify the new longchar and longbinary types.
     */
    // Common to Sybase and SQL Server
    private static final int UDT_CHAR              =  1; // 0x01
    private static final int UDT_VARCHAR           =  2; // 0x02
    private static final int UDT_BINARY            =  3; // 0x03
    private static final int UDT_VARBINARY         =  4; // 0x04
    private static final int UDT_SYSNAME           = 18; // 0x12
    // Sybase only
    private static final int UDT_NCHAR             = 24; // 0x18
    private static final int UDT_NVARCHAR          = 25; // 0x19
    private static final int UDT_UNICHAR           = 34; // 0x22
    private static final int UDT_UNIVARCHAR        = 35; // 0x23
    private static final int UDT_UNITEXT           = 36; // 0x24
    private static final int UDT_LONGSYSNAME       = 42; // 0x2A
    private static final int UDT_TIMESTAMP         = 80; // 0x50
    // SQL Server 7+
    private static final int UDT_NEWSYSNAME        =256; // 0x100

    /*
     * Constants for variable length data types
     */
    private static final int VAR_MAX               = 255;
    private static final int SYB_LONGVAR_MAX       = 16384;
    private static final int MS_LONGVAR_MAX        = 8000;
    private static final int SYB_CHUNK_SIZE        = 8192;

    /**
     * Array of TDS data type descriptors.
     */
    private final static TypeInfo types[] = new TypeInfo[256];

    /**
     * Static block to initialise TDS data type descriptors.
     */
    static {//                             SQL Type       Size Prec  DS signed TDS8 Col java Type
        types[SYBCHAR]      = new TypeInfo("char",          -1, -1,  1, false, false, java.sql.Types.CHAR);
        types[SYBVARCHAR]   = new TypeInfo("varchar",       -1, -1,  1, false, false, java.sql.Types.VARCHAR);
        types[SYBINTN]      = new TypeInfo("int",           -1, 10, 11, true,  false, java.sql.Types.INTEGER);
        types[SYBINT1]      = new TypeInfo("tinyint",        1,  3,  4, false, false, java.sql.Types.TINYINT);
        types[SYBINT2]      = new TypeInfo("smallint",       2,  5,  6, true,  false, java.sql.Types.SMALLINT);
        types[SYBINT4]      = new TypeInfo("int",            4, 10, 11, true,  false, java.sql.Types.INTEGER);
        types[SYBINT8]      = new TypeInfo("bigint",         8, 19, 20, true,  false, java.sql.Types.BIGINT);
        types[SYBFLT8]      = new TypeInfo("float",          8, 15, 24, true,  false, java.sql.Types.DOUBLE);
        types[SYBDATETIME]  = new TypeInfo("datetime",       8, 23, 23, false, false, java.sql.Types.TIMESTAMP);
        types[SYBBIT]       = new TypeInfo("bit",            1,  1,  1, false, false, java.sql.Types.BIT);
        types[SYBTEXT]      = new TypeInfo("text",          -4, -1, -1, false, true,  java.sql.Types.CLOB);
        types[SYBNTEXT]     = new TypeInfo("ntext",         -4, -1, -1, false, true,  java.sql.Types.CLOB);
        types[SYBUNITEXT]   = new TypeInfo("unitext",       -4, -1, -1, false, true,  java.sql.Types.CLOB);
        types[SYBIMAGE]     = new TypeInfo("image",         -4, -1, -1, false, false, java.sql.Types.BLOB);
        types[SYBMONEY4]    = new TypeInfo("smallmoney",     4, 10, 12, true,  false, java.sql.Types.DECIMAL);
        types[SYBMONEY]     = new TypeInfo("money",          8, 19, 21, true,  false, java.sql.Types.DECIMAL);
        types[SYBDATETIME4] = new TypeInfo("smalldatetime",  4, 16, 19, false, false, java.sql.Types.TIMESTAMP);
        types[SYBREAL]      = new TypeInfo("real",           4,  7, 14, true,  false, java.sql.Types.REAL);
        types[SYBBINARY]    = new TypeInfo("binary",        -1, -1,  2, false, false, java.sql.Types.BINARY);
        types[SYBVOID]      = new TypeInfo("void",          -1,  1,  1, false, false, 0);
        types[SYBVARBINARY] = new TypeInfo("varbinary",     -1, -1, -1, false, false, java.sql.Types.VARBINARY);
        types[SYBNVARCHAR]  = new TypeInfo("nvarchar",      -1, -1, -1, false, false, java.sql.Types.VARCHAR);
        types[SYBBITN]      = new TypeInfo("bit",           -1,  1,  1, false, false, java.sql.Types.BIT);
        types[SYBNUMERIC]   = new TypeInfo("numeric",       -1, -1, -1, true,  false, java.sql.Types.NUMERIC);
        types[SYBDECIMAL]   = new TypeInfo("decimal",       -1, -1, -1, true,  false, java.sql.Types.DECIMAL);
        types[SYBFLTN]      = new TypeInfo("float",         -1, 15, 24, true,  false, java.sql.Types.DOUBLE);
        types[SYBMONEYN]    = new TypeInfo("money",         -1, 19, 21, true,  false, java.sql.Types.DECIMAL);
        types[SYBDATETIMN]  = new TypeInfo("datetime",      -1, 23, 23, false, false, java.sql.Types.TIMESTAMP);
        types[SYBDATE]      = new TypeInfo("date",           4, 10, 10, false, false, java.sql.Types.DATE);
        types[SYBTIME]      = new TypeInfo("time",           4,  8,  8, false, false, java.sql.Types.TIME);
        types[SYBDATEN]     = new TypeInfo("date",          -1, 10, 10, false, false, java.sql.Types.DATE);
        types[SYBTIMEN]     = new TypeInfo("time",          -1,  8,  8, false, false, java.sql.Types.TIME);
        types[XSYBCHAR]     = new TypeInfo("char",          -2, -1, -1, false, true,  java.sql.Types.CHAR);
        types[XSYBVARCHAR]  = new TypeInfo("varchar",       -2, -1, -1, false, true,  java.sql.Types.VARCHAR);
        types[XSYBNVARCHAR] = new TypeInfo("nvarchar",      -2, -1, -1, false, true,  java.sql.Types.VARCHAR);
        types[XSYBNCHAR]    = new TypeInfo("nchar",         -2, -1, -1, false, true,  java.sql.Types.CHAR);
        types[XSYBVARBINARY]= new TypeInfo("varbinary",     -2, -1, -1, false, false, java.sql.Types.VARBINARY);
        types[XSYBBINARY]   = new TypeInfo("binary",        -2, -1, -1, false, false, java.sql.Types.BINARY);
        types[SYBLONGBINARY]= new TypeInfo("varbinary",     -5, -1,  2, false, false, java.sql.Types.BINARY);
        types[SYBSINT1]     = new TypeInfo("tinyint",        1,  2,  3, false, false, java.sql.Types.TINYINT);
        types[SYBUINT2]     = new TypeInfo("unsigned smallint", 2,  5,  6, false, false, java.sql.Types.INTEGER);
        types[SYBUINT4]     = new TypeInfo("unsigned int",   4, 10, 11, false, false, java.sql.Types.BIGINT);
        types[SYBUINT8]     = new TypeInfo("unsigned bigint",8, 20, 20, false, false, java.sql.Types.DECIMAL);
        types[SYBUINTN]     = new TypeInfo("unsigned int",  -1, 10, 11, true,  false, java.sql.Types.BIGINT);
        types[SYBUNIQUE]    = new TypeInfo("uniqueidentifier",-1,36,36, false, false, java.sql.Types.CHAR);
        types[SYBVARIANT]   = new TypeInfo("sql_variant",   -5,  0, 8000, false, false, java.sql.Types.VARCHAR);
        types[SYBSINT8]     = new TypeInfo("bigint",         8, 19, 20, true,  false, java.sql.Types.BIGINT);
    }

    /** Default Decimal Scale. */
    static final int DEFAULT_SCALE = 10;
    /** Default precision for SQL Server 6.5 and 7. */
    static final int DEFAULT_PRECISION_28 = 28;
    /** Default precision for Sybase and SQL Server 2000 and newer. */
    static final int DEFAULT_PRECISION_38 = 38;

    /**
     * TDS 8 supplies collation information for character data types.
     *
     * @param in the server response stream
     * @param ci the column descriptor
     * @return the number of bytes read from the stream as an <code>int</code>
     */
    static int getCollation(ResponseStream in, ColInfo ci) throws IOException {
        if (TdsData.isCollation(ci)) {
            // Read TDS8 collation info
            ci.collation = new byte[5];
            in.read(ci.collation);

            return 5;
        }

        return 0;
    }

    /**
     * Set the <code>charsetInfo</code> field of <code>ci</code> according to
     * the value of its <code>collation</code> field.
     * <p>
     * The <code>Connection</code> is used to find out whether a specific
     * charset was requested. In this case, the column charset will be ignored.
     *
     * @param ci         the <code>ColInfo</code> instance to update
     * @param connection a <code>Connection</code> instance to check whether it
     *                   has a fixed charset or not
     * @throws SQLException if a <code>CharsetInfo</code> is not found for this
     *                      particular column collation
     */
    static void setColumnCharset(ColInfo ci, ConnectionJDBC2 connection)
            throws SQLException {
        if (connection.isCharsetSpecified()) {
            // If a charset was requested on connection creation, ignore the
            // column collation and use default
            ci.charsetInfo = connection.getCharsetInfo();
        } else if (ci.collation != null) {
            // TDS version will be 8.0 or higher in this case and connection
            // collation will be non-null
            byte[] collation = ci.collation;
            byte[] defaultCollation = connection.getCollation();
            int i;

            for (i = 0; i < 5; ++i) {
                if (collation[i] != defaultCollation[i]) {
                    break;
                }
            }

            if (i == 5) {
                ci.charsetInfo = connection.getCharsetInfo();
            } else {
                ci.charsetInfo = CharsetInfo.getCharset(collation);
            }
        }
    }

    /**
     * Read the TDS datastream and populate the ColInfo parameter with
     * data type and related information.
     * <p>The type infomation conforms to one of the following formats:
     * <ol>
     * <li> [int1 type]  - eg SYBINT4.
     * <li> [int1 type] [int1 buffersize]  - eg VARCHAR &lt; 256
     * <li> [int1 type] [int2 buffersize]  - eg VARCHAR &gt; 255.
     * <li> [int1 type] [int4 buffersize] [int1 tabnamelen] [int1*n tabname] - eg text.
     * <li> [int1 type] [int4 buffersize] - eg sql_variant.
     * <li> [int1 type] [int1 buffersize] [int1 precision] [int1 scale] - eg decimal.
     * </ol>
     * For TDS 8 large character types include a 5 byte collation field after the buffer size.
     *
     * @param in The server response stream.
     * @param ci The ColInfo column descriptor object.
     * @return The number of bytes read from the input stream.
     * @throws IOException
     * @throws ProtocolException
     */
    static int readType(ResponseStream in, ColInfo ci)
            throws IOException, ProtocolException {
        int tdsVersion = in.getTdsVersion();
        boolean isTds8 = tdsVersion >= Driver.TDS80;
        boolean isTds7 = tdsVersion >= Driver.TDS70;
        boolean isTds5 = tdsVersion == Driver.TDS50;
        boolean isTds42 = tdsVersion == Driver.TDS42;
        int bytesRead = 1;
        // Get the TDS data type code
        int type = in.read();

        if (types[type] == null || (isTds5 && type == SYBLONGDATA)) {
            // Trap invalid type or 0x24 received from a Sybase server!
            throw new ProtocolException("Invalid TDS data type 0x" + Integer.toHexString(type & 0xFF));
        }

        ci.tdsType     = type;
        ci.jdbcType    = types[type].jdbcType;
        ci.bufferSize  = types[type].size;

        // Now get the buffersize if required
        if (ci.bufferSize == -5) {
            // sql_variant
            // Sybase long binary
            ci.bufferSize = in.readInt();
            bytesRead += 4;
        } else if (ci.bufferSize == -4) {
            // text or image
            ci.bufferSize = in.readInt();

            if (isTds8) {
                bytesRead += getCollation(in, ci);
            }

            int lenName = in.readShort();

            ci.tableName = in.readString(lenName);
            bytesRead += 6 + ((in.getTdsVersion() >= Driver.TDS70) ? lenName * 2 : lenName);
        } else if (ci.bufferSize == -2) {
            // longvarchar longvarbinary
            if (isTds5 && ci.tdsType == XSYBCHAR) {
                ci.bufferSize = in.readInt();
                bytesRead += 4;
            } else {
                ci.bufferSize = in.readShort();
                bytesRead += 2;
            }

            if (isTds8) {
                bytesRead += getCollation(in, ci);
            }

        } else if (ci.bufferSize == -1) {
            // varchar varbinary decimal etc
            bytesRead += 1;
            ci.bufferSize = in.read();
        }

        // Set default displaySize and precision
        ci.displaySize = types[type].displaySize;
        ci.precision   = types[type].precision;
        ci.sqlType     = types[type].sqlType;

        // Now fine tune sizes for specific types
        switch (type) {
            //
            // long datetime has scale of 3 smalldatetime has scale of 0
            //
            case  SYBDATETIME:
                ci.scale = 3;
                break;
            // Establish actual size of nullable datetime
            case SYBDATETIMN:
                if (ci.bufferSize == 8) {
                    ci.displaySize = types[SYBDATETIME].displaySize;
                    ci.precision   = types[SYBDATETIME].precision;
                    ci.scale       = 3;
                } else {
                    ci.displaySize = types[SYBDATETIME4].displaySize;
                    ci.precision   = types[SYBDATETIME4].precision;
                    ci.sqlType     = types[SYBDATETIME4].sqlType;
                    ci.scale       = 0;
                }
                break;
            // Establish actual size of nullable float
            case SYBFLTN:
                if (ci.bufferSize == 8) {
                    ci.displaySize = types[SYBFLT8].displaySize;
                    ci.precision   = types[SYBFLT8].precision;
                } else {
                    ci.displaySize = types[SYBREAL].displaySize;
                    ci.precision   = types[SYBREAL].precision;
                    ci.jdbcType    = java.sql.Types.REAL;
                    ci.sqlType     = types[SYBREAL].sqlType;
                }
                break;
            // Establish actual size of nullable int
            case SYBINTN:
                if (ci.bufferSize == 8) {
                    ci.displaySize = types[SYBINT8].displaySize;
                    ci.precision   = types[SYBINT8].precision;
                    ci.jdbcType    = java.sql.Types.BIGINT;
                    ci.sqlType     = types[SYBINT8].sqlType;
                } else if (ci.bufferSize == 4) {
                    ci.displaySize = types[SYBINT4].displaySize;
                    ci.precision   = types[SYBINT4].precision;
                } else if (ci.bufferSize == 2) {
                    ci.displaySize = types[SYBINT2].displaySize;
                    ci.precision   = types[SYBINT2].precision;
                    ci.jdbcType    = java.sql.Types.SMALLINT;
                    ci.sqlType     = types[SYBINT2].sqlType;
                } else {
                    ci.displaySize = types[SYBINT1].displaySize;
                    ci.precision   = types[SYBINT1].precision;
                    ci.jdbcType    = java.sql.Types.TINYINT;
                    ci.sqlType     = types[SYBINT1].sqlType;
                }
                break;
                // Establish actual size of nullable unsigned int
            case SYBUINTN:
                if (ci.bufferSize == 8) {
                    ci.displaySize = types[SYBUINT8].displaySize;
                    ci.precision   = types[SYBUINT8].precision;
                    ci.jdbcType    = types[SYBUINT8].jdbcType;
                    ci.sqlType     = types[SYBUINT8].sqlType;
                } else if (ci.bufferSize == 4) {
                    ci.displaySize = types[SYBUINT4].displaySize;
                    ci.precision   = types[SYBUINT4].precision;
                } else if (ci.bufferSize == 2) {
                    ci.displaySize = types[SYBUINT2].displaySize;
                    ci.precision   = types[SYBUINT2].precision;
                    ci.jdbcType    = types[SYBUINT2].jdbcType;
                    ci.sqlType     = types[SYBUINT2].sqlType;
                } else {
                    throw new ProtocolException("unsigned int null (size 1) not supported");
                }
                break;
            //
            // Money types have a scale of 4
            //
            case  SYBMONEY:
            case  SYBMONEY4:
                ci.scale = 4;
                break;
            // Establish actual size of nullable money
            case SYBMONEYN:
                if (ci.bufferSize == 8) {
                    ci.displaySize = types[SYBMONEY].displaySize;
                    ci.precision   = types[SYBMONEY].precision;
                } else {
                    ci.displaySize = types[SYBMONEY4].displaySize;
                    ci.precision   = types[SYBMONEY4].precision;
                    ci.sqlType     = types[SYBMONEY4].sqlType;
                }
                ci.scale = 4;
                break;

            // Read in scale and precision for decimal types
            case SYBDECIMAL:
            case SYBNUMERIC:
                ci.precision   = in.read();
                ci.scale       = in.read();
                ci.displaySize = ((ci.scale > 0) ? 2 : 1) + ci.precision;
                bytesRead     += 2;
                ci.sqlType     = types[type].sqlType;
                break;

            // Although a binary type force displaysize to MAXINT
            case SYBIMAGE:
                ci.precision   = Integer.MAX_VALUE;
                ci.displaySize = Integer.MAX_VALUE;
                break;
            // Normal binaries have a display size of 2 * precision 0x0A0B etc
            case SYBLONGBINARY:
            case SYBVARBINARY:
            case SYBBINARY:
            case XSYBBINARY:
            case XSYBVARBINARY:
                ci.precision   = ci.bufferSize;
                ci.displaySize = ci.precision * 2;
                break;

            // SQL Server unicode text can only display half as many chars
            case SYBNTEXT:
                ci.precision   = Integer.MAX_VALUE / 2;
                ci.displaySize = Integer.MAX_VALUE / 2;
                break;

            // ASE 15+ unicode text can only display half as many chars
            case SYBUNITEXT:
                ci.precision   = Integer.MAX_VALUE / 2;
                ci.displaySize = Integer.MAX_VALUE / 2;
                break;

            // SQL Server unicode chars can only display half as many chars
            case XSYBNCHAR:
            case XSYBNVARCHAR:
                ci.displaySize = ci.bufferSize / 2;
                ci.precision   = ci.displaySize;
                break;

            // Normal characters display size = precision = buffer size.
            case SYBTEXT:
            case SYBCHAR:
            case XSYBCHAR:
            case XSYBVARCHAR:
            case SYBVARCHAR:
            case SYBNVARCHAR:
                ci.precision = ci.bufferSize;
                ci.displaySize = ci.precision;
                break;
        }

        // For numeric types add 'identity' for auto inc data type
        if (ci.isIdentity) {
            ci.sqlType += " identity";
        }
        
        // Fine tune Sybase or SQL 6.5 data types
        if (isTds42 || isTds5) {
            switch (ci.userType) {
                case  UDT_CHAR:
                    ci.sqlType      = "char";
                    ci.displaySize = ci.bufferSize;
                    ci.jdbcType    = java.sql.Types.CHAR;
                    break;
                case  UDT_VARCHAR:
                    ci.sqlType     = "varchar";
                    ci.displaySize = ci.bufferSize;
                    ci.jdbcType    = java.sql.Types.VARCHAR;
                    break;
                case  UDT_BINARY:
                    ci.sqlType     = "binary";
                    ci.displaySize = ci.bufferSize * 2;
                    ci.jdbcType    = java.sql.Types.BINARY;
                    break;
                case  UDT_VARBINARY:
                    ci.sqlType     = "varbinary";
                    ci.displaySize = ci.bufferSize * 2;
                    ci.jdbcType    = java.sql.Types.VARBINARY;
                    break;
                case UDT_SYSNAME:
                    ci.sqlType = "sysname";
                    ci.displaySize = ci.bufferSize;
                    ci.jdbcType    = java.sql.Types.VARCHAR;
                    break;
                case UDT_TIMESTAMP:
                    ci.sqlType = "timestamp";
                    ci.displaySize = ci.bufferSize * 2;
                    ci.jdbcType    = java.sql.Types.VARBINARY;
                    break;
            }
        }
        
        // Fine tune Sybase data types
        if (isTds5) {
            switch (ci.userType) {
                case UDT_NCHAR:
                    ci.sqlType     = "nchar";
                    ci.displaySize = ci.bufferSize;
                    ci.jdbcType    = java.sql.Types.CHAR;
                    break;
                case UDT_NVARCHAR:
                    ci.sqlType     = "nvarchar";
                    ci.displaySize = ci.bufferSize;
                    ci.jdbcType    = java.sql.Types.VARCHAR;
                    break;
                case UDT_UNICHAR:
                    ci.sqlType     = "unichar";
                    ci.displaySize = ci.bufferSize / 2;
                    ci.precision   = ci.displaySize;
                    ci.jdbcType    = java.sql.Types.CHAR;
                    break;
                case UDT_UNIVARCHAR:
                    ci.sqlType     = "univarchar";
                    ci.displaySize = ci.bufferSize / 2;
                    ci.precision   = ci.displaySize;
                    ci.jdbcType    = java.sql.Types.VARCHAR;
                    break;            
                case UDT_LONGSYSNAME:
                    ci.sqlType = "longsysname";
                    ci.jdbcType    = java.sql.Types.VARCHAR;
                    ci.displaySize = ci.bufferSize;
                    break;
            }
        }
        // Fine tune SQL Server 7+ datatypes
        if (isTds7) {
            switch (ci.userType) {
                case UDT_TIMESTAMP:
                    ci.sqlType = "timestamp";
                    ci.jdbcType    = java.sql.Types.BINARY;
                    break;
                case UDT_NEWSYSNAME:
                    ci.sqlType = "sysname";
                    ci.jdbcType    = java.sql.Types.VARCHAR;
                    break;
            }
        }
        

        return bytesRead;
    }

    /**
     * Read the TDS data item from the Response Stream.
     * <p> The data size is either implicit in the type for example
     * fixed size integers, or a count field precedes the actual data.
     * The size of the count field varies with the data type.
     *
     * @param connection an object reference to the caller of this method;
     *        must be a <code>Connection</code>, <code>Statement</code> or
     *        <code>ResultSet</code>
     * @param in The server ResponseStream.
     * @param ci The ColInfo column descriptor object.
     * @return The data item Object or null.
     * @throws IOException
     * @throws ProtocolException
     */
    static Object readData(ConnectionJDBC2 connection, ResponseStream in, ColInfo ci)
            throws IOException, ProtocolException {
        int len;

        switch (ci.tdsType) {
            case SYBINTN:
                switch (in.read()) {
                    case 1:
                        return new Integer(in.read() & 0xFF);
                    case 2:
                        return new Integer(in.readShort());
                    case 4:
                        return new Integer(in.readInt());
                    case 8:
                        return new Long(in.readLong());
                }

                break;

            // Sybase ASE 15+ supports unsigned null smallint, int and bigint
            case SYBUINTN:
                switch (in.read()) {
                    case 1:
                        return new Integer(in.read() & 0xFF);
                    case 2:
                        return new Integer((int)in.readShort() & 0xFFFF);
                    case 4:
                        return new Long((long)in.readInt() & 0xFFFFFFFFL );
                    case 8:
                        return in.readUnsignedLong();
                }
                break;

            case SYBINT1:
                return new Integer(in.read() & 0xFF);

            case SYBINT2:
                return new Integer(in.readShort());

            case SYBINT4:
                return new Integer(in.readInt());

            // SQL Server bigint
            case SYBINT8:
                return new Long(in.readLong());

            // Sybase ASE 15+ bigint
            case SYBSINT8:
                return new Long(in.readLong());

            // Sybase ASE 15+ unsigned smallint
            case SYBUINT2:
                return new Integer((int)in.readShort() & 0xFFFF);

            // Sybase ASE 15+ unsigned int
            case SYBUINT4:
                return new Long((long)in.readInt() & 0xFFFFFFFFL);

            // Sybase ASE 15+ unsigned bigint
            case SYBUINT8:
                return in.readUnsignedLong();

            case SYBIMAGE:
                len = in.read();

                if (len > 0) {
                    in.skip(24); // Skip textptr and timestamp
                    int dataLen = in.readInt();
                    BlobImpl blob;
                    if (dataLen == 0 && in.getTdsVersion() <= Driver.TDS50) {
                        // Length of zero may indicate an initialized image 
                        // column that has been updated to null.
                        break;
                    }
                    if (dataLen <= connection.getLobBuffer()) {
                        //
                        // OK Small enough to load into memory
                        //
                        byte[] data = new byte[dataLen];
                        in.read(data);
                        blob = new BlobImpl(connection, data);
                    } else {
                        // Too big, need to write straight to disk
                        try {
                            blob = new BlobImpl(connection);
                            OutputStream out = blob.setBinaryStream(1);
                            byte[] buffer = new byte[1024];
                            int result;
                            while ((result = in.read(buffer, 0,
                                             Math.min(dataLen, buffer.length)))
                                             != -1 && dataLen != 0) {
                                out.write(buffer, 0, result);
                                dataLen -= result;
                            }
                            out.close();
                        } catch (SQLException e) {
                            // Transform setBinaryStream SQLException
                            throw new IOException(e.getMessage());
                        }
                    }
                    return blob;
                }

                break;

            case SYBTEXT:
                len = in.read();

                if (len > 0) {
                    String charset;
                    if (ci.charsetInfo != null) {
                        charset = ci.charsetInfo.getCharset();
                    } else {
                        charset = connection.getCharset();
                    }
                    in.skip(24); // Skip textptr and timestamp
                    int dataLen = in.readInt();
                    if (dataLen == 0 && in.getTdsVersion() <= Driver.TDS50) {
                        // Length of zero may indicate an initialized text 
                        // column that has been updated to null.
                        break;
                    }
                    ClobImpl clob = new ClobImpl(connection);
                    BlobBuffer blobBuffer = clob.getBlobBuffer();
                    if (dataLen <= connection.getLobBuffer()) {
                        //
                        // OK Small enough to load into memory
                        //
                        BufferedReader rdr =
                            new BufferedReader(
                                 new InputStreamReader(in.getInputStream(dataLen),
                                                                         charset),
                                                                         1024);
                        byte[] data = new byte[dataLen * 2];
                        int p = 0;
                        int c;
                        while ((c = rdr.read()) >= 0) {
                            data[p++] = (byte)c;
                            data[p++] = (byte)(c >> 8);
                        }
                        rdr.close();
                        blobBuffer.setBuffer(data, false);
                        if (p == 2 && data[0] == 0x20 && data[1] == 0
                            && in.getTdsVersion() < Driver.TDS70) {
                            // Single space with Sybase equates to empty string
                            p = 0;
                        }
                        // Explicitly set length as multi byte character sets
                        // may not fill array completely.
                        blobBuffer.setLength(p);
                    } else {
                        // Too big, need to write straight to disk
                        BufferedReader rdr =
                            new BufferedReader(
                                 new InputStreamReader(in.getInputStream(dataLen),
                                                                         charset),
                                                                         1024);
                        try {
                            OutputStream out = blobBuffer.setBinaryStream(1, false);
                            int c;
                            while ((c = rdr.read()) >= 0) {
                                out.write(c);
                                out.write(c >> 8);
                            }
                            out.close();
                            rdr.close();
                        } catch (SQLException e) {
                            // Turn back into an IOException
                            throw new IOException(e.getMessage());
                        }
                    }
                    return clob;
                }

                break;

            case SYBUNITEXT: // ASE 15+ unicode text type
            case SYBNTEXT:
                len = in.read();

                if (len > 0) {
                    in.skip(24); // Skip textptr and timestamp
                    int dataLen = in.readInt();
                    if (dataLen == 0 && in.getTdsVersion() <= Driver.TDS50) {
                        // Length of zero may indicate an initialized unitext 
                        // column that has been updated to null.
                        break;
                    }
                    ClobImpl clob = new ClobImpl(connection);
                    BlobBuffer blobBuffer = clob.getBlobBuffer();
                    if (dataLen <= connection.getLobBuffer()) {
                        //
                        // OK Small enough to load into memory
                        //
                        byte[] data = new byte[dataLen];
                        in.read(data);
                        blobBuffer.setBuffer(data, false);
                        if (dataLen == 2 && data[0] == 0x20 && data[1] == 0
                                && in.getTdsVersion() == Driver.TDS50) {
                                // Single space with Sybase equates to empty string
                                dataLen = 0;
                            }
                            // Explicitly set length as multi byte character sets
                            // may not fill array completely.
                            blobBuffer.setLength(dataLen);
                    } else {
                        // Too big, need to write straight to disk
                        try {
                            OutputStream out = blobBuffer.setBinaryStream(1, false);
                            byte[] buffer = new byte[1024];
                            int result;
                            while ((result = in.read(buffer, 0,
                                             Math.min(dataLen, buffer.length)))
                                             != -1 && dataLen != 0) {
                                out.write(buffer, 0, result);
                                dataLen -= result;
                            }
                            out.close();
                        } catch (SQLException e) {
                            // Transform setBinaryStream SQLException
                            throw new IOException(e.getMessage());
                        }
                    }
                    return clob;
                }

                break;

            case SYBCHAR:
            case SYBVARCHAR:
                len = in.read();

                if (len > 0) {
                    String value = in.readNonUnicodeString(len,
                            ci.charsetInfo == null ? connection.getCharsetInfo() : ci.charsetInfo);

                    if (len == 1 && ci.tdsType == SYBVARCHAR &&
                            in.getTdsVersion() < Driver.TDS70) {
                        // In TDS 4/5 zero length varchars are stored as a
                        // single space to distinguish them from nulls.
                        return (" ".equals(value)) ? "" : value;
                    }

                    return value;
                }

                break;

            case SYBNVARCHAR:
                len = in.read();

                if (len > 0) {
                    return in.readUnicodeString(len / 2);
                }

                break;

            case XSYBCHAR:
            case XSYBVARCHAR:
                if (in.getTdsVersion() == Driver.TDS50) {
                    // This is a Sybase wide table String
                    len = in.readInt();
                    if (len > 0) {
                        String tmp = in.readNonUnicodeString(len);
                        if (" ".equals(tmp) && !"char".equals(ci.sqlType)) {
                            tmp = "";
                        }
                        return tmp;
                    }
                } else {
                    // This is a TDS 7+ long string
                    len = in.readShort();
                    if (len != -1) {
                        return in.readNonUnicodeString(len,
                                ci.charsetInfo == null ? connection.getCharsetInfo() : ci.charsetInfo);
                    }
                }

                break;

            case XSYBNCHAR:
            case XSYBNVARCHAR:
                len = in.readShort();

                if (len != -1) {
                    return in.readUnicodeString(len / 2);
                }

                break;

            case SYBVARBINARY:
            case SYBBINARY:
                len = in.read();

                if (len > 0) {
                    byte[] bytes = new byte[len];

                    in.read(bytes);

                    return bytes;
                }

                break;

            case XSYBVARBINARY:
            case XSYBBINARY:
                len = in.readShort();

                if (len != -1) {
                    byte[] bytes = new byte[len];

                    in.read(bytes);

                    return bytes;
                }

                break;

            case SYBLONGBINARY:
                len = in.readInt();
                if (len != 0) {
                    if ("unichar".equals(ci.sqlType) ||
                    		"univarchar".equals(ci.sqlType)) {
                        char[] buf = new char[len / 2];
                        in.read(buf);
                        if ((len & 1) != 0) {
                            // Bad length should be divisible by 2
                            in.skip(1); // Deal with it anyway.
                        }
                        if (len == 2 && buf[0] == ' ') {
                            return "";
                        } else {
                            return new String(buf);
                        }
                    } else {
                        byte[] bytes = new byte[len];
                        in.read(bytes);
                        return bytes;
                    }
                }
                break;

            case SYBMONEY4:
            case SYBMONEY:
            case SYBMONEYN:
                return getMoneyValue(in, ci.tdsType);

            case SYBDATETIME4:
            case SYBDATETIMN:
            case SYBDATETIME:
                return getDatetimeValue(in, ci.tdsType);

            case SYBDATEN:
            case SYBDATE:
                len = (ci.tdsType == SYBDATEN)? in.read(): 4;
                if (len == 4) {
                    return new DateTime(in.readInt(), DateTime.TIME_NOT_USED);
                } else {
                    // Invalid length or 0 for null
                    in.skip(len);
                }
                break;

            case SYBTIMEN:
            case SYBTIME:
                len = (ci.tdsType == SYBTIMEN)? in.read(): 4;
                if (len == 4) {
                    return new DateTime(DateTime.DATE_NOT_USED, in.readInt());
                } else {
                    // Invalid length or 0 for null
                    in.skip(len);
                }
                break;

            case SYBBIT:
                return (in.read() != 0) ? Boolean.TRUE : Boolean.FALSE;

            case SYBBITN:
                len = in.read();

                if (len > 0) {
                    return (in.read() != 0) ? Boolean.TRUE : Boolean.FALSE;
                }

                break;

            case SYBREAL:
                return new Float(Float.intBitsToFloat(in.readInt()));

            case SYBFLT8:
                return new Double(Double.longBitsToDouble(in.readLong()));

            case SYBFLTN:
                len = in.read();

                if (len == 4) {
                    return new Float(Float.intBitsToFloat(in.readInt()));
                } else if (len == 8) {
                    return new Double(Double.longBitsToDouble(in.readLong()));
                }

                break;

            case SYBUNIQUE:
                len = in.read();

                if (len > 0) {
                    byte[] bytes = new byte[len];

                    in.read(bytes);

                    return new UniqueIdentifier(bytes);
                }

                break;

            case SYBNUMERIC:
            case SYBDECIMAL:
                len = in.read();

                if (len > 0) {
                    int sign = in.read();

                    len--;
                    byte[] bytes = new byte[len];
                    BigInteger bi;

                    if (in.getServerType() == Driver.SYBASE) {
                        // Sybase order is MSB first!
                        for (int i = 0; i < len; i++) {
                            bytes[i] = (byte) in.read();
                        }

                        bi = new BigInteger((sign == 0) ? 1 : -1, bytes);
                    } else {
                        while (len-- > 0) {
                            bytes[len] = (byte)in.read();
                        }

                        bi = new BigInteger((sign == 0) ? -1 : 1, bytes);
                    }

                    return new BigDecimal(bi, ci.scale);
                }

                break;

            case SYBVARIANT:
                return getVariant(connection, in);

            default:
                throw new ProtocolException("Unsupported TDS data type 0x"
                        + Integer.toHexString(ci.tdsType & 0xFF));
        }

        return null;
    }

    /**
     * Retrieve the signed status of the column.
     *
     * @param ci the column meta data
     * @return <code>true</code> if the column is a signed numeric.
     */
    static boolean isSigned(ColInfo ci) {
        int type = ci.tdsType;

        if (type < 0 || type > 255 || types[type] == null) {
            throw new IllegalArgumentException("TDS data type " + type
                    + " invalid");
        }
        if (type == TdsData.SYBINTN && ci.bufferSize == 1) {
            type = TdsData.SYBINT1; // Tiny int is not signed!
        }
        return types[type].isSigned;
    }

    /**
     * Retrieve the collation status of the column.
     * <p/>
     * TDS 8.0 character columns include collation information.
     *
     * @param ci the column meta data
     * @return <code>true</code> if the column requires collation data.
     */
    static boolean isCollation(ColInfo ci) {
        int type = ci.tdsType;

        if (type < 0 || type > 255 || types[type] == null) {
            throw new IllegalArgumentException("TDS data type " + type
                    + " invalid");
        }

        return types[type].isCollation;
    }

    /**
     * Retrieve the currency status of the column.
     *
     * @param ci The column meta data.
     * @return <code>boolean</code> true if the column is a currency type.
     */
    static boolean isCurrency(ColInfo ci) {
        int type = ci.tdsType;

        if (type < 0 || type > 255 || types[type] == null) {
            throw new IllegalArgumentException("TDS data type " + type
                    + " invalid");
        }

        return type == SYBMONEY || type == SYBMONEY4 || type == SYBMONEYN;
    }

    /**
     * Retrieve the searchable status of the column.
     *
     * @param ci the column meta data
     * @return <code>true</code> if the column is not a text or image type.
     */
    static boolean isSearchable(ColInfo ci) {
        int type = ci.tdsType;

        if (type < 0 || type > 255 || types[type] == null) {
            throw new IllegalArgumentException("TDS data type " + type
                    + " invalid");
        }

        return types[type].size != -4;
    }

    /**
     * Determines whether the column is Unicode encoded.
     *
     * @param ci the column meta data
     * @return <code>true</code> if the column is Unicode encoded
     */
    static boolean isUnicode(ColInfo ci) {
        int type = ci.tdsType;

        if (type < 0 || type > 255 || types[type] == null) {
            throw new IllegalArgumentException("TDS data type " + type
                    + " invalid");
        }

        switch (type) {
            case SYBNVARCHAR:
            case SYBNTEXT:
            case XSYBNCHAR:
            case XSYBNVARCHAR:
            case XSYBCHAR:     // Not always
            case SYBVARIANT:   // Not always
                return true;

            default:
                return false;
        }
    }

    /**
     * Fill in the TDS native type code and all other fields for a
     * <code>ColInfo</code> instance with the JDBC type set.
     *
     * @param ci the <code>ColInfo</code> instance
     */
    static void fillInType(ColInfo ci)
            throws SQLException {
        switch (ci.jdbcType) {
            case java.sql.Types.VARCHAR:
                ci.tdsType = SYBVARCHAR;
                ci.bufferSize = MS_LONGVAR_MAX;
                ci.displaySize = MS_LONGVAR_MAX;
                ci.precision = MS_LONGVAR_MAX;
                break;
            case java.sql.Types.INTEGER:
                ci.tdsType = SYBINT4;
                ci.bufferSize = 4;
                ci.displaySize = 11;
                ci.precision = 10;
                break;
            case java.sql.Types.SMALLINT:
                ci.tdsType = SYBINT2;
                ci.bufferSize = 2;
                ci.displaySize = 6;
                ci.precision = 5;
                break;
            case java.sql.Types.BIT:
                ci.tdsType = SYBBIT;
                ci.bufferSize = 1;
                ci.displaySize = 1;
                ci.precision = 1;
                break;
            default:
                throw new SQLException(Messages.get(
                        "error.baddatatype",
                        Integer.toString(ci.jdbcType)), "HY000");
        }
        ci.sqlType = types[ci.tdsType].sqlType;
        ci.scale = 0;
    }

    /**
     * Retrieve the TDS native type code for the parameter.
     *
     * @param connection the connectionJDBC object
     * @param pi         the parameter descriptor
     */
    static void getNativeType(ConnectionJDBC2 connection, ParamInfo pi)
            throws SQLException {
        int len;
        int jdbcType = pi.jdbcType;

        if (jdbcType == java.sql.Types.OTHER) {
            jdbcType = Support.getJdbcType(pi.value);
        }

        switch (jdbcType) {
            case java.sql.Types.CHAR:
            case java.sql.Types.VARCHAR:
            case java.sql.Types.LONGVARCHAR:
            case java.sql.Types.CLOB:
                if (pi.value == null) {
                    len = 0;
                } else {
                    len = pi.length;
                }
                if (connection.getTdsVersion() < Driver.TDS70) {
                    String charset = connection.getCharset();
                    if (len > 0
                        && (len <= SYB_LONGVAR_MAX / 2 || connection.getSybaseInfo(TdsCore.SYB_UNITEXT))
                        && connection.getSybaseInfo(TdsCore.SYB_UNICODE)
                        && connection.getUseUnicode()
                        && !"UTF-8".equals(charset)) {
                        // Sybase can send values as unicode if conversion to the
                        // server charset fails.
                        // One option to determine if conversion will fail is to use
                        // the CharSetEncoder class but this is only available from
                        // JDK 1.4.
                        // For now we will call a local method to see if the string
                        // should be sent as unicode.
                        // This behaviour can be disabled by setting the connection
                        // property sendParametersAsUnicode=false.
                        // TODO: Find a better way of testing for convertable charset.
                        // With ASE 15 this code will read a CLOB into memory just to
                        // check for unicode characters. This is wasteful if no unicode
                        // data is present and we are targetting a text column. The option
                        // of always sending unicode does not work as the server will
                        // complain about image to text conversions unless the target
                        // column actually is unitext.
                        try {
                            String tmp = pi.getString(charset);
                            if (!canEncode(tmp, charset)) {
                                // Conversion fails need to send as unicode.
                                pi.length  = tmp.length();
                                if (pi.length > SYB_LONGVAR_MAX / 2) {
                                    pi.sqlType = "unitext";
                                    pi.tdsType = SYBLONGDATA;
                                } else {
                                    pi.sqlType = "univarchar("+pi.length+')';
                                    pi.tdsType = SYBLONGBINARY;
                                }
                                break;
                            }
                        } catch (IOException e) {
                            throw new SQLException(
                                    Messages.get("error.generic.ioerror", e.getMessage()), "HY000");
                        }
                    }
                    //
                    // If the client character set is wide then we need to ensure that the size
                    // is within bounds even after conversion from Unicode
                    //
                    if (connection.isWideChar() && len <= SYB_LONGVAR_MAX) {
                        try {
                            byte tmp[] = pi.getBytes(charset);
                            len = (tmp == null) ? 0 : tmp.length;
                        } catch (IOException e) {
                            throw new SQLException(
                                    Messages.get("error.generic.ioerror", e.getMessage()), "HY000");
                        }
                    }
                    if (len <= VAR_MAX) {
                        pi.tdsType = SYBVARCHAR;
                        pi.sqlType = "varchar(255)";
                    } else {
                        if (connection.getSybaseInfo(TdsCore.SYB_LONGDATA)) {
                            if (len > SYB_LONGVAR_MAX) {
                                // Use special Sybase long data type which
                                // allows text data to be sent as a statement parameter
                                // (although not as a SP parameter).
                                pi.tdsType = SYBLONGDATA;
                                pi.sqlType = "text";
                            } else {
                                // Use Sybase 12.5+ long varchar type which
                                // is limited to 16384 bytes.
                                pi.tdsType = XSYBCHAR;
                                pi.sqlType = "varchar(" + len + ')';
                            }
                        } else {
                            pi.tdsType = SYBTEXT;
                            pi.sqlType = "text";
                        }
                    }
                } else {
                    if (pi.isUnicode && len <= MS_LONGVAR_MAX / 2) {
                        pi.tdsType = XSYBNVARCHAR;
                        pi.sqlType = "nvarchar(4000)";
                    } else if (!pi.isUnicode && len <= MS_LONGVAR_MAX) {
                        CharsetInfo csi = connection.getCharsetInfo();
                        try {
                            if (len > 0 && csi.isWideChars() && pi.getBytes(csi.getCharset()).length > MS_LONGVAR_MAX) {
                                pi.tdsType = SYBTEXT;
                                pi.sqlType = "text";
                            } else {
                                pi.tdsType = XSYBVARCHAR;
                                pi.sqlType = "varchar(8000)";
                            }
                        } catch (IOException e) {
                            throw new SQLException(
                                    Messages.get("error.generic.ioerror", e.getMessage()), "HY000");
                        }
                    } else {
                        if (pi.isOutput) {
                            throw new SQLException(
                                                  Messages.get("error.textoutparam"), "HY000");
                        }

                        if (pi.isUnicode) {
                            pi.tdsType = SYBNTEXT;
                            pi.sqlType = "ntext";
                        } else {
                            pi.tdsType = SYBTEXT;
                            pi.sqlType = "text";
                        }
                    }
                }
                break;

            case java.sql.Types.TINYINT:
            case java.sql.Types.SMALLINT:
            case java.sql.Types.INTEGER:
                pi.tdsType = SYBINTN;
                pi.sqlType = "int";
                break;

            case JtdsStatement.BOOLEAN:
            case java.sql.Types.BIT:
                if (connection.getTdsVersion() >= Driver.TDS70 ||
                        connection.getSybaseInfo(TdsCore.SYB_BITNULL)) {
                    pi.tdsType = SYBBITN;
                } else {
                    pi.tdsType = SYBBIT;
                }

                pi.sqlType = "bit";
                break;

            case java.sql.Types.REAL:
                pi.tdsType = SYBFLTN;
                pi.sqlType = "real";
                break;

            case java.sql.Types.FLOAT:
            case java.sql.Types.DOUBLE:
                pi.tdsType = SYBFLTN;
                pi.sqlType = "float";
                break;

            case java.sql.Types.DATE:
                if (connection.getSybaseInfo(TdsCore.SYB_DATETIME)) {
                    pi.tdsType = SYBDATEN;
                    pi.sqlType = "date";
                } else {
                    pi.tdsType = SYBDATETIMN;
                    pi.sqlType = "datetime";
                }
                break;
            case java.sql.Types.TIME:
                if (connection.getSybaseInfo(TdsCore.SYB_DATETIME)) {
                    pi.tdsType = SYBTIMEN;
                    pi.sqlType = "time";
                } else {
                    pi.tdsType = SYBDATETIMN;
                    pi.sqlType = "datetime";
                }
                break;
            case java.sql.Types.TIMESTAMP:
                pi.tdsType = SYBDATETIMN;
                pi.sqlType = "datetime";
                break;

            case java.sql.Types.BINARY:
            case java.sql.Types.VARBINARY:
            case java.sql.Types.BLOB:
            case java.sql.Types.LONGVARBINARY:
                if (pi.value == null) {
                    len = 0;
                } else {
                    len = pi.length;
                }

                if (connection.getTdsVersion() < Driver.TDS70) {
                    if (len <= VAR_MAX) {
                        pi.tdsType = SYBVARBINARY;
                        pi.sqlType = "varbinary(255)";
                    } else {
                        if (connection.getSybaseInfo(TdsCore.SYB_LONGDATA)) {
                            if (len > SYB_LONGVAR_MAX) {
                                // Need to use special Sybase long binary type
                                pi.tdsType = SYBLONGDATA;
                                pi.sqlType = "image";
                            } else {
                                // Sybase long binary that can be used as a SP parameter
                                pi.tdsType = SYBLONGBINARY;
                                pi.sqlType = "varbinary(" + len + ')';
                            }
                        } else {
                            // Sybase < 12.5 or SQL Server 6.5
                            pi.tdsType = SYBIMAGE;
                            pi.sqlType = "image";
                        }
                    }
                } else {
                    if (len <= MS_LONGVAR_MAX) {
                        pi.tdsType = XSYBVARBINARY;
                        pi.sqlType = "varbinary(8000)";
                    } else {
                        if (pi.isOutput) {
                            throw new SQLException(
                                                  Messages.get("error.textoutparam"), "HY000");
                        }

                        pi.tdsType = SYBIMAGE;
                        pi.sqlType = "image";
                    }
                }

                break;

            case java.sql.Types.BIGINT:
                if (connection.getTdsVersion() >= Driver.TDS80 ||
                    connection.getSybaseInfo(TdsCore.SYB_BIGINT)) {
                    pi.tdsType = SYBINTN;
                    pi.sqlType = "bigint";
                } else {
                    // int8 not supported send as a decimal field
                    pi.tdsType  = SYBDECIMAL;
                    pi.sqlType = "decimal(" + connection.getMaxPrecision() + ')';
                    pi.scale = 0;
                }

                break;

            case java.sql.Types.DECIMAL:
            case java.sql.Types.NUMERIC:
                pi.tdsType  = SYBDECIMAL;
                int prec = connection.getMaxPrecision();
                int scale = DEFAULT_SCALE;
                if (pi.value instanceof BigDecimal) {
                    scale = ((BigDecimal)pi.value).scale();
                } else if (pi.scale >= 0 && pi.scale <= prec) {
                    scale = pi.scale;
                }
                pi.sqlType = "decimal(" + prec + ',' + scale + ')';

                break;

            case java.sql.Types.OTHER:
            case java.sql.Types.NULL:
                // Send a null String in the absence of anything better
                pi.tdsType = SYBVARCHAR;
                pi.sqlType = "varchar(255)";
                break;

            default:
                throw new SQLException(Messages.get(
                        "error.baddatatype",
                        Integer.toString(pi.jdbcType)), "HY000");
        }
    }

    /**
     * Calculate the size of the parameter descriptor array for TDS 5 packets.
     *
     * @param charset The encoding character set.
     * @param isWideChar True if multi byte encoding.
     * @param pi The parameter to describe.
     * @param useParamNames True if named parameters should be used.
     * @return The size of the parameter descriptor as an <code>int</code>.
     */
    static int getTds5ParamSize(String charset,
                                boolean isWideChar,
                                ParamInfo pi,
                                boolean useParamNames) {
        int size = 8;
        if (pi.name != null && useParamNames) {
            // Size of parameter name
            if (isWideChar) {
                byte[] buf = Support.encodeString(charset, pi.name);

                size += buf.length;
            } else {
                size += pi.name.length();
            }
        }

        switch (pi.tdsType) {
            case SYBVARCHAR:
            case SYBVARBINARY:
            case SYBINTN:
            case SYBFLTN:
            case SYBDATETIMN:
            case SYBDATEN:
            case SYBTIMEN:
                size += 1;
                break;
            case SYBDECIMAL:
            case SYBLONGDATA:
                size += 3;
                break;
            case XSYBCHAR:
            case SYBLONGBINARY:
                size += 4;
                break;
            case SYBBIT:
                break;
            default:
                throw new IllegalStateException("Unsupported output TDS type 0x"
                        + Integer.toHexString(pi.tdsType));
        }

        return size;
    }

    /**
     * Write a TDS 5 parameter format descriptor.
     *
     * @param out The server RequestStream.
     * @param charset The encoding character set.
     * @param isWideChar True if multi byte encoding.
     * @param pi The parameter to describe.
     * @param useParamNames True if named parameters should be used.
     * @throws IOException
     */
    static void writeTds5ParamFmt(RequestStream out,
                                  String charset,
                                  boolean isWideChar,
                                  ParamInfo pi,
                                  boolean useParamNames)
    throws IOException {
        if (pi.name != null && useParamNames) {
            // Output parameter name.
            if (isWideChar) {
                byte[] buf = Support.encodeString(charset, pi.name);

                out.write((byte) buf.length);
                out.write(buf);
            } else {
                out.write((byte) pi.name.length());
                out.write(pi.name);
            }
        } else {
            out.write((byte)0);
        }

        out.write((byte) (pi.isOutput ? 1 : 0)); // Output param
        if (pi.sqlType.startsWith("univarchar")) {
            out.write((int) UDT_UNIVARCHAR);
        } else if ("unitext".equals(pi.sqlType)) {
            out.write((int) UDT_UNITEXT);
        } else {
            out.write((int) 0); // user type
        }
        out.write((byte) pi.tdsType); // TDS data type token

        // Output length fields
        switch (pi.tdsType) {
            case SYBVARCHAR:
            case SYBVARBINARY:
                out.write((byte) VAR_MAX);
                break;
            case XSYBCHAR:
                out.write((int)0x7FFFFFFF);
                break;
            case SYBLONGDATA:
                // It appears that type 3 = send text data
                // and type 4 = send image or unitext data
                // No idea if there is a type 1/2 or what they are.
                out.write("text".equals(pi.sqlType) ? (byte) 3 : (byte) 4);
                out.write((byte)0);
                out.write((byte)0);
                break;
            case SYBLONGBINARY:
                out.write((int)0x7FFFFFFF);
                break;
            case SYBBIT:
                break;
            case SYBINTN:
                out.write("bigint".equals(pi.sqlType) ? (byte) 8: (byte) 4);
                break;
            case SYBFLTN:
                if (pi.value instanceof Float) {
                    out.write((byte) 4);
                } else {
                    out.write((byte) 8);
                }
                break;
            case SYBDATETIMN:
                out.write((byte) 8);
                break;
            case SYBDATEN:
            case SYBTIMEN:
                out.write((byte)4);
                break;
            case SYBDECIMAL:
                out.write((byte) 17);
                out.write((byte) 38);

                if (pi.jdbcType == java.sql.Types.BIGINT) {
                    out.write((byte) 0);
                } else {
                    if (pi.value instanceof BigDecimal) {
                        out.write((byte) ((BigDecimal) pi.value).scale());
                    } else {
                        if (pi.scale >= 0 && pi.scale <= TdsData.DEFAULT_PRECISION_38) {
                            out.write((byte) pi.scale);
                        } else {
                            out.write((byte) DEFAULT_SCALE);
                        }
                    }
                }

                break;
            default:
                throw new IllegalStateException(
                        "Unsupported output TDS type " + Integer.toHexString(pi.tdsType));
        }

        out.write((byte) 0); // Locale information
    }

    /**
     * Write the actual TDS 5 parameter data.
     *
     * @param out         the server RequestStream
     * @param charsetInfo the encoding character set
     * @param pi          the parameter to output
     * @throws IOException
     * @throws SQLException
     */
    static void writeTds5Param(RequestStream out,
                               CharsetInfo charsetInfo,
                               ParamInfo pi)
    throws IOException, SQLException {

        if (pi.charsetInfo == null) {
            pi.charsetInfo = charsetInfo;
        }
        switch (pi.tdsType) {

            case SYBVARCHAR:
                if (pi.value == null) {
                    out.write((byte) 0);
                } else {
                    byte buf[] = pi.getBytes(pi.charsetInfo.getCharset());

                    if (buf.length == 0) {
                        buf = new byte[1];
                        buf[0] = ' ';
                    }

                    if (buf.length > VAR_MAX) {
                        throw new SQLException(
                                              Messages.get("error.generic.truncmbcs"), "HY000");
                    }

                    out.write((byte) buf.length);
                    out.write(buf);
                }

                break;

            case SYBVARBINARY:
                if (pi.value == null) {
                    out.write((byte) 0);
                } else {
                    byte buf[] = pi.getBytes(pi.charsetInfo.getCharset());
                    if (out.getTdsVersion() < Driver.TDS70 && buf.length == 0) {
                        // Sybase and SQL 6.5 do not allow zero length binary
                        out.write((byte) 1); out.write((byte) 0);
                    } else {
                        out.write((byte) buf.length);
                        out.write(buf);
                    }
                }

                break;

            case XSYBCHAR:
                if (pi.value == null) {
                    out.write((byte) 0);
                } else {
                    byte buf[] = pi.getBytes(pi.charsetInfo.getCharset());

                    if (buf.length == 0) {
                        buf = new byte[1];
                        buf[0] = ' ';
                    }
                    out.write((int) buf.length);
                    out.write(buf);
                }
                break;

            case SYBLONGDATA:
                //
                // Write a three byte prefix usage unknown
                //
                out.write((byte)0);
                out.write((byte)0);
                out.write((byte)0);
                //
                // Write BLOB direct from input stream
                //
                if (pi.value instanceof InputStream) {
                    byte buffer[] = new byte[SYB_CHUNK_SIZE];
                    int len = ((InputStream) pi.value).read(buffer);
                    while (len > 0) {
                        out.write((byte) len);
                        out.write((byte) (len >> 8));
                        out.write((byte) (len >> 16));
                        out.write((byte) ((len >> 24) | 0x80)); // 0x80 means more to come
                        out.write(buffer, 0, len);
                        len = ((InputStream) pi.value).read(buffer);
                    }
                } else
                //
                // Write CLOB direct from input Reader
                //
                if (pi.value instanceof Reader && !pi.charsetInfo.isWideChars()) {
                    // For ASE 15+ the getNativeType() routine will already have
                    // read the data from the reader so this code will not be
                    // reached unless sendStringParametersAsUnicode=false.
                    char buffer[] = new char[SYB_CHUNK_SIZE];
                    int len = ((Reader) pi.value).read(buffer);
                    while (len > 0) {
                        out.write((byte) len);
                        out.write((byte) (len >> 8));
                        out.write((byte) (len >> 16));
                        out.write((byte) ((len >> 24) | 0x80)); // 0x80 means more to come
                        out.write(Support.encodeString(
                                pi.charsetInfo.getCharset(),
                                new String(buffer, 0, len)));
                        len = ((Reader) pi.value).read(buffer);
                    }
                } else
                //
                // Write data from memory buffer
                //
                if (pi.value != null) {
                    //
                    // Actual data needs to be written out in chunks of
                    // 8192 bytes.
                    //
                    if ("unitext".equals(pi.sqlType)) {
                        // Write out String as unicode bytes
                        String buf = pi.getString(pi.charsetInfo.getCharset());
                        int pos = 0;
                        while (pos < buf.length()) {
                            int clen = (buf.length() - pos >= SYB_CHUNK_SIZE / 2)?
                                                SYB_CHUNK_SIZE / 2: buf.length() - pos;
                            int len = clen * 2;
                            out.write((byte) len);
                            out.write((byte) (len >> 8));
                            out.write((byte) (len >> 16));
                            out.write((byte) ((len >> 24) | 0x80)); // 0x80 means more to come
                            // Write data
                            out.write(buf.substring(pos, pos+clen).toCharArray(), 0, clen);
                            pos += clen;
                        }
                    } else {
                        // Write text as bytes
                        byte buf[] = pi.getBytes(pi.charsetInfo.getCharset());
                        int pos = 0;
                        while (pos < buf.length) {
                            int len = (buf.length - pos >= SYB_CHUNK_SIZE)
                                    ? SYB_CHUNK_SIZE : buf.length - pos;
                            out.write((byte) len);
                            out.write((byte) (len >> 8));
                            out.write((byte) (len >> 16));
                            out.write((byte) ((len >> 24) | 0x80)); // 0x80 means more to come
                            // Write data
                            for (int i = 0; i < len; i++) {
                                out.write(buf[pos++]);
                            }
                        }
                    }
                }
                // Write terminator
                out.write((int) 0);
                break;

            case SYBLONGBINARY:
                // Sybase data <= 16284 bytes long
                if (pi.value == null) {
                    out.write((int) 0);
                } else {
                    if (pi.sqlType.startsWith("univarchar")){
                        String tmp = pi.getString(pi.charsetInfo.getCharset());
                        if (tmp.length() == 0) {
                            tmp = " ";
                        }
                        out.write((int)tmp.length() * 2);
                        out.write(tmp.toCharArray(), 0, tmp.length());
                    } else {
                        byte buf[] = pi.getBytes(pi.charsetInfo.getCharset());
                        if (buf.length > 0) {
                            out.write((int) buf.length);
                            out.write(buf);
                        } else {
                            out.write((int) 1);
                            out.write((byte) 0);
                        }
                    }
                }
                break;

            case SYBINTN:
                if (pi.value == null) {
                    out.write((byte) 0);
                } else {
                    if ("bigint".equals(pi.sqlType)) {
                        out.write((byte) 8);
                        out.write((long) ((Number) pi.value).longValue());
                    } else {
                        out.write((byte) 4);
                        out.write((int) ((Number) pi.value).intValue());
                    }
                }

                break;

            case SYBFLTN:
                if (pi.value == null) {
                    out.write((byte) 0);
                } else {
                    if (pi.value instanceof Float) {
                        out.write((byte) 4);
                        out.write(((Number) pi.value).floatValue());
                    } else {
                        out.write((byte) 8);
                        out.write(((Number) pi.value).doubleValue());
                    }
                }

                break;

            case SYBDATETIMN:
                putDateTimeValue(out, (DateTime) pi.value);
                break;

            case SYBDATEN:
                if (pi.value == null) {
                    out.write((byte)0);
                } else {
                    out.write((byte)4);
                    out.write((int)((DateTime) pi.value).getDate());
                }
                break;

           case SYBTIMEN:
               if (pi.value == null) {
                   out.write((byte)0);
               } else {
                   out.write((byte)4);
                   out.write((int)((DateTime) pi.value).getTime());
               }
               break;

            case SYBBIT:
                if (pi.value == null) {
                    out.write((byte) 0);
                } else {
                    out.write((byte) (((Boolean) pi.value).booleanValue() ? 1 : 0));
                }

                break;

            case SYBNUMERIC:
            case SYBDECIMAL:
                BigDecimal value = null;

                if (pi.value != null) {
                    if (pi.value instanceof Long) {
                        // Long to BigDecimal conversion is buggy. It's actually
                        // long to double to BigDecimal.
                        value = new BigDecimal(pi.value.toString());
                    } else {
                        value = (BigDecimal) pi.value;
                    }
                }

                out.write(value);
                break;

            default:
                throw new IllegalStateException(
                        "Unsupported output TDS type " + Integer.toHexString(pi.tdsType));
        }
    }

    /**
     * TDS 8 requires collation information for char data descriptors.
     *
     * @param out The Server request stream.
     * @param pi The parameter descriptor.
     * @throws IOException
     */
    static void putCollation(RequestStream out, ParamInfo pi)
            throws IOException {
        //
        // For TDS 8 write a collation string
        // I am assuming this can be all zero for now if none is known
        //
        if (types[pi.tdsType].isCollation) {
            if (pi.collation != null) {
                out.write(pi.collation);
            } else {
                byte collation[] = {0x00, 0x00, 0x00, 0x00, 0x00};

                out.write(collation);
            }
        }
    }

    /**
     * Write a parameter to the server request stream.
     *
     * @param out         the server request stream
     * @param charsetInfo the default character set
     * @param collation   the default SQL Server 2000 collation
     * @param pi          the parameter descriptor
     */
    static void writeParam(RequestStream out,
                           CharsetInfo charsetInfo,
                           byte[] collation,
                           ParamInfo pi)
            throws IOException {
        int len;
        String tmp;
        byte[] buf;
        boolean isTds8 = out.getTdsVersion() >= Driver.TDS80;

        if (isTds8) {
            if (pi.collation == null) {
                pi.collation = collation;
            }
        }
        if (pi.charsetInfo == null) {
            pi.charsetInfo = charsetInfo;
        }

        switch (pi.tdsType) {

            case XSYBVARCHAR:
                if (pi.value == null) {
                    out.write((byte) pi.tdsType);
                    out.write((short) MS_LONGVAR_MAX);

                    if (isTds8) {
                        putCollation(out, pi);
                    }

                    out.write((short) 0xFFFF);
                } else {
                    buf = pi.getBytes(pi.charsetInfo.getCharset());

                    if (buf.length > MS_LONGVAR_MAX) {
                        out.write((byte) SYBTEXT);
                        out.write((int) buf.length);

                        if (isTds8) {
                            putCollation(out, pi);
                        }

                        out.write((int) buf.length);
                        out.write(buf);
                    } else {
                        out.write((byte) pi.tdsType);
                        out.write((short) MS_LONGVAR_MAX);

                        if (isTds8) {
                            putCollation(out, pi);
                        }

                        out.write((short) buf.length);
                        out.write(buf);
                    }
                }

                break;

            case SYBVARCHAR:
                if (pi.value == null) {
                    out.write((byte) pi.tdsType);
                    out.write((byte) VAR_MAX);
                    out.write((byte) 0);
                } else {
                    buf = pi.getBytes(pi.charsetInfo.getCharset());

                    if (buf.length > VAR_MAX) {
                        if (buf.length <= MS_LONGVAR_MAX && out.getTdsVersion() >= Driver.TDS70) {
                            out.write((byte) XSYBVARCHAR);
                            out.write((short) MS_LONGVAR_MAX);

                            if (isTds8) {
                                putCollation(out, pi);
                            }

                            out.write((short) buf.length);
                            out.write(buf);
                        } else {
                            out.write((byte) SYBTEXT);
                            out.write((int) buf.length);

                            if (isTds8) {
                                putCollation(out, pi);
                            }

                            out.write((int) buf.length);
                            out.write(buf);
                        }
                    } else {
                        if (buf.length == 0) {
                            buf = new byte[1];
                            buf[0] = ' ';
                        }

                        out.write((byte) pi.tdsType);
                        out.write((byte) VAR_MAX);
                        out.write((byte) buf.length);
                        out.write(buf);
                    }
                }

                break;

            case XSYBNVARCHAR:
                out.write((byte) pi.tdsType);
                out.write((short) MS_LONGVAR_MAX);

                if (isTds8) {
                    putCollation(out, pi);
                }

                if (pi.value == null) {
                    out.write((short) 0xFFFF);
                } else {
                    tmp = pi.getString(pi.charsetInfo.getCharset());
                    out.write((short) (tmp.length() * 2));
                    out.write(tmp);
                }

                break;

            case SYBTEXT:
                if (pi.value == null) {
                    len = 0;
                } else {
                    len = pi.length;

                    if (len == 0 && out.getTdsVersion() < Driver.TDS70) {
                        pi.value = " ";
                        len = 1;
                    }
                }

                out.write((byte) pi.tdsType);

                if (len > 0) {
                    if (pi.value instanceof InputStream) {
                        // Write output directly from stream
                        out.write((int) len);

                        if (isTds8) {
                            putCollation(out, pi);
                        }

                        out.write((int) len);
                        out.writeStreamBytes((InputStream) pi.value, len);
                    } else if (pi.value instanceof Reader && !pi.charsetInfo.isWideChars()) {
                        // Write output directly from stream with character translation
                        out.write((int) len);

                        if (isTds8) {
                            putCollation(out, pi);
                        }

                        out.write((int) len);
                        out.writeReaderBytes((Reader) pi.value, len);
                    } else {
                        buf = pi.getBytes(pi.charsetInfo.getCharset());
                        out.write((int) buf.length);

                        if (isTds8) {
                            putCollation(out, pi);
                        }

                        out.write((int) buf.length);
                        out.write(buf);
                    }
                } else {
                    out.write((int) len); // Zero length

                    if (isTds8) {
                        putCollation(out, pi);
                    }

                    out.write((int)len);
                }

                break;

            case SYBNTEXT:
                if (pi.value == null) {
                    len = 0;
                } else {
                    len = pi.length;
                }

                out.write((byte)pi.tdsType);

                if (len > 0) {
                    if (pi.value instanceof Reader) {
                        out.write((int) len);

                        if (isTds8) {
                            putCollation(out, pi);
                        }

                        out.write((int) len * 2);
                        out.writeReaderChars((Reader) pi.value, len);
                    } else if (pi.value instanceof InputStream && !pi.charsetInfo.isWideChars()) {
                        out.write((int) len);

                        if (isTds8) {
                            putCollation(out, pi);
                        }

                        out.write((int) len * 2);
                        out.writeReaderChars(new InputStreamReader(
                                (InputStream) pi.value, pi.charsetInfo.getCharset()), len);
                    } else {
                        tmp = pi.getString(pi.charsetInfo.getCharset());
                        len = tmp.length();
                        out.write((int) len);

                        if (isTds8) {
                            putCollation(out, pi);
                        }

                        out.write((int) len * 2);
                        out.write(tmp);
                    }
                } else {
                    out.write((int) len);

                    if (isTds8) {
                        putCollation(out, pi);
                    }

                    out.write((int) len);
                }

                break;

            case XSYBVARBINARY:
                out.write((byte) pi.tdsType);
                out.write((short) MS_LONGVAR_MAX);

                if (pi.value == null) {
                    out.write((short)0xFFFF);
                } else {
                    buf = pi.getBytes(pi.charsetInfo.getCharset());
                    out.write((short) buf.length);
                    out.write(buf);
                }

                break;

            case SYBVARBINARY:
                out.write((byte) pi.tdsType);
                out.write((byte) VAR_MAX);

                if (pi.value == null) {
                    out.write((byte) 0);
                } else {
                    buf = pi.getBytes(pi.charsetInfo.getCharset());
                    if (out.getTdsVersion() < Driver.TDS70 && buf.length == 0) {
                        // Sybase and SQL 6.5 do not allow zero length binary
                        out.write((byte) 1); out.write((byte) 0);
                    } else {
                        out.write((byte) buf.length);
                        out.write(buf);
                    }
                }

                break;

            case SYBIMAGE:
                if (pi.value == null) {
                    len = 0;
                } else {
                    len = pi.length;
                }

                out.write((byte) pi.tdsType);

                if (len > 0) {
                    if (pi.value instanceof InputStream) {
                        out.write((int) len);
                        out.write((int) len);
                        out.writeStreamBytes((InputStream) pi.value, len);
                    } else {
                        buf = pi.getBytes(pi.charsetInfo.getCharset());
                        out.write((int) buf.length);
                        out.write((int) buf.length);
                        out.write(buf);
                    }
                } else {
                    if (out.getTdsVersion() < Driver.TDS70) {
                        // Sybase and SQL 6.5 do not allow zero length binary
                        out.write((int) 1);
                        out.write((int) 1);
                        out.write((byte) 0);
                    } else {
                        out.write((int) len);
                        out.write((int) len);
                    }
                }

                break;

            case SYBINTN:
                out.write((byte) pi.tdsType);

                if (pi.value == null) {
                    out.write(("bigint".equals(pi.sqlType))? (byte)8: (byte)4);
                    out.write((byte) 0);
                } else {
                    if ("bigint".equals(pi.sqlType)) {
                        out.write((byte) 8);
                        out.write((byte) 8);
                        out.write((long) ((Number) pi.value).longValue());
                    } else {
                        out.write((byte) 4);
                        out.write((byte) 4);
                        out.write((int) ((Number) pi.value).intValue());
                    }
                }

                break;

            case SYBFLTN:
                out.write((byte) pi.tdsType);
                if (pi.value instanceof Float) {
                    out.write((byte) 4);
                    out.write((byte) 4);
                    out.write(((Number) pi.value).floatValue());
                } else {
                    out.write((byte) 8);
                    if (pi.value == null) {
                        out.write((byte) 0);
                    } else {
                        out.write((byte) 8);
                        out.write(((Number) pi.value).doubleValue());
                    }
                }

                break;

            case SYBDATETIMN:
                out.write((byte) SYBDATETIMN);
                out.write((byte) 8);
                putDateTimeValue(out, (DateTime) pi.value);
                break;

            case SYBBIT:
                out.write((byte) pi.tdsType);

                if (pi.value == null) {
                    out.write((byte) 0);
                } else {
                    out.write((byte) (((Boolean) pi.value).booleanValue() ? 1 : 0));
                }

                break;

            case SYBBITN:
                out.write((byte) SYBBITN);
                out.write((byte) 1);

                if (pi.value == null) {
                    out.write((byte) 0);
                } else {
                    out.write((byte) 1);
                    out.write((byte) (((Boolean) pi.value).booleanValue() ? 1 : 0));
                }

                break;

            case SYBNUMERIC:
            case SYBDECIMAL:
                out.write((byte) pi.tdsType);
                BigDecimal value = null;
                int prec = out.getMaxPrecision();
                int scale;

                if (pi.value == null) {
                    if (pi.jdbcType == java.sql.Types.BIGINT) {
                        scale = 0;
                    } else {
                        if (pi.scale >= 0 && pi.scale <= prec) {
                            scale = pi.scale;
                        } else {
                            scale = DEFAULT_SCALE;
                        }
                    }
                } else {
                    if (pi.value instanceof Long) {
                        value = new BigDecimal(((Long) pi.value).toString());
                        scale = 0;
                    } else {
                        value = (BigDecimal) pi.value;
                        scale = value.scale();
                    }
                }

                out.write((byte) out.getMaxDecimalBytes());
                out.write((byte) prec);
                out.write((byte) scale);
                out.write(value);
                break;

            default:
                throw new IllegalStateException("Unsupported output TDS type "
                        + Integer.toHexString(pi.tdsType));
        }
    }
//
// ---------------------- Private methods from here -----------------------
//

    /**
     * Private constructor to prevent users creating an
     * actual instance of this class.
     */
    private TdsData() {
    }

    /**
     * Get a DATETIME value from the server response stream.
     *
     * @param in The server response stream.
     * @param type The TDS data type.
     * @return The java.sql.Timestamp value or null.
     * @throws java.io.IOException
     */
    private static Object getDatetimeValue(ResponseStream in, final int type)
            throws IOException, ProtocolException {
        int len;
        int daysSince1900;
        int time;
        int minutes;

        if (type == SYBDATETIMN) {
            len = in.read(); // No need to & with 0xff
        } else if (type == SYBDATETIME4) {
            len = 4;
        } else {
            len = 8;
        }

        switch (len) {
            case 0:
                return null;

            case 8:
                // A datetime is made of of two 32 bit integers
                // The first one is the number of days since 1900
                // The second integer is the number of seconds*300
                // Negative days indicate dates earlier than 1900.
                // The full range is 1753-01-01 to 9999-12-31.
                daysSince1900 = in.readInt();
                time = in.readInt();
                return new DateTime(daysSince1900, time);
            case 4:
                // A smalldatetime is two 16 bit integers.
                // The first is the number of days past January 1, 1900,
                // the second smallint is the number of minutes past
                // midnight.
                // The full range is 1900-01-01 to 2079-06-06.
                daysSince1900 = ((int) in.readShort()) & 0xFFFF;
                minutes = in.readShort();
                return new DateTime((short) daysSince1900, (short) minutes);
            default:
                throw new ProtocolException("Invalid DATETIME value with size of "
                                            + len + " bytes.");
        }
    }

    /**
     * Output a java.sql.Date/Time/Timestamp value to the server
     * as a Sybase datetime value.
     *
     * @param out   the server request stream
     * @param value the date value to write
     */
    private static void putDateTimeValue(RequestStream out, DateTime value)
            throws IOException {
        if (value == null) {
            out.write((byte) 0);
            return;
        }
        out.write((byte) 8);
        out.write((int)value.getDate());
        out.write((int)value.getTime());
    }

    /**
     * Read a MONEY value from the server response stream.
     *
     * @param in The server response stream.
     * @param type The TDS data type.
     * @return The java.math.BigDecimal value or null.
     * @throws IOException
     * @throws ProtocolException
     */
    private static Object getMoneyValue(ResponseStream in, final int type)
    throws IOException, ProtocolException {
        final int len;

        if (type == SYBMONEY) {
            len = 8;
        } else if (type == SYBMONEYN) {
            len = in.read();
        } else {
            len = 4;
        }

        BigInteger x = null;

        if (len == 4) {
            x = BigInteger.valueOf(in.readInt());
        } else if (len == 8) {
            final byte b4 = (byte) in.read();
            final byte b5 = (byte) in.read();
            final byte b6 = (byte) in.read();
            final byte b7 = (byte) in.read();
            final byte b0 = (byte) in.read();
            final byte b1 = (byte) in.read();
            final byte b2 = (byte) in.read();
            final byte b3 = (byte) in.read();
            final long l = (long) (b0 & 0xff) + ((long) (b1 & 0xff) << 8)
                           + ((long) (b2 & 0xff) << 16) + ((long) (b3 & 0xff) << 24)
                           + ((long) (b4 & 0xff) << 32) + ((long) (b5 & 0xff) << 40)
                           + ((long) (b6 & 0xff) << 48) + ((long) (b7 & 0xff) << 56);

            x = BigInteger.valueOf(l);
        } else if (len != 0) {
            throw new ProtocolException("Invalid money value.");
        }

        return (x == null) ? null : new BigDecimal(x, 4);
    }

    /**
     * Read a MSQL 2000 sql_variant data value from the input stream.
     * <p>SQL_VARIANT has the following structure:
     * <ol>
     * <li>INT4 total size of data
     * <li>INT1 TDS data type (text/image/ntext/sql_variant not allowed)
     * <li>INT1 Length of extra type descriptor information
     * <li>Optional additional type info required by some types
     * <li>byte[0...n] the actual data
     * </ol>
     *
     * @param connection used to obtain collation/charset information
     * @param in         the server response stream
     * @return the SQL_VARIANT data
     */
    private static Object getVariant(ConnectionJDBC2 connection,
                                     ResponseStream in)
            throws IOException, ProtocolException {
        byte[] bytes;
        int len = in.readInt();

        if (len == 0) {
            // Length of zero means item is null
            return null;
        }

        ColInfo ci = new ColInfo();
        len -= 2;
        ci.tdsType = in.read(); // TDS Type
        len -= in.read(); // Size of descriptor

        switch (ci.tdsType) {
            case SYBINT1:
                return new Integer(in.read() & 0xFF);

            case SYBINT2:
                return new Integer(in.readShort());

            case SYBINT4:
                return new Integer(in.readInt());

            case SYBINT8:
                return new Long(in.readLong());

            case XSYBCHAR:
            case XSYBVARCHAR:
                // FIXME Use collation for reading
                getCollation(in, ci);
                try {
                    setColumnCharset(ci, connection);
                } catch (SQLException ex) {
                    // Skip the buffer size and value
                    in.skip(2 + len);
                    throw new ProtocolException(ex.toString() + " [SQLState: "
                            + ex.getSQLState() + ']');
                }

                in.skip(2); // Skip buffer size
                return in.readNonUnicodeString(len);

            case XSYBNCHAR:
            case XSYBNVARCHAR:
                // XXX Why do we need collation for Unicode strings?
                in.skip(7); // Skip collation and buffer size

                return in.readUnicodeString(len / 2);

            case XSYBVARBINARY:
            case XSYBBINARY:
                in.skip(2); // Skip buffer size
                bytes = new byte[len];
                in.read(bytes);

                return bytes;

            case SYBMONEY4:
            case SYBMONEY:
                return getMoneyValue(in, ci.tdsType);

            case SYBDATETIME4:
            case SYBDATETIME:
                return getDatetimeValue(in, ci.tdsType);

            case SYBBIT:
                return (in.read() != 0) ? Boolean.TRUE : Boolean.FALSE;

            case SYBREAL:
                return new Float(Float.intBitsToFloat(in.readInt()));

            case SYBFLT8:
                return new Double(Double.longBitsToDouble(in.readLong()));

            case SYBUNIQUE:
                bytes = new byte[len];
                in.read(bytes);

                return new UniqueIdentifier(bytes);

            case SYBNUMERIC:
            case SYBDECIMAL:
                ci.precision = in.read();
                ci.scale = in.read();
                int sign = in.read();
                len--;
                bytes = new byte[len];
                BigInteger bi;

                while (len-- > 0) {
                    bytes[len] = (byte)in.read();
                }

                bi = new BigInteger((sign == 0) ? -1 : 1, bytes);

                return new BigDecimal(bi, ci.scale);

            default:
                throw new ProtocolException("Unsupported TDS data type 0x"
                                            + Integer.toHexString(ci.tdsType)
                                            + " in sql_variant");
        }
        //
        // For compatibility with the MS driver convert to String.
        // Change the data type for sql_variant from OTHER to VARCHAR
        // Without this code the actual Object type can be retrieved
        // by using getObject(n).
        //
//        try {
//            value = Support.convert(value, java.sql.Types.VARCHAR, in.getCharset());
//        } catch (SQLException e) {
//            // Conversion failed just try toString();
//            value = value.toString();
//        }
    }

    /**
     * For SQL 2005 This routine will modify the meta data to allow the
     * caller to distinguish between varchar(max) and text or varbinary(max)
     * and image or nvarchar(max) and ntext.
     *
     * @param typeName the SQL type returned by sp_columns
     * @param tdsType the TDS type returned by sp_columns
     * @return the (possibly) modified SQL type name as a <code>String</code>
     */
    public static String getMSTypeName(String typeName, int tdsType) {
        if (typeName.equalsIgnoreCase("text") && tdsType != SYBTEXT) {
            return "varchar";
        } else if (typeName.equalsIgnoreCase("ntext") && tdsType != SYBTEXT) {
            return "nvarchar";
        } else if (typeName.equalsIgnoreCase("image") && tdsType != SYBIMAGE) {
            return "varbinary";
        } else {
            return typeName;
        }
    }

    /**
     * Extract the TDS protocol version from the value returned by the server in the LOGINACK
     * packet.
     *
     * @param rawTdsVersion the TDS protocol version as returned by the server
     * @return the jTDS internal value for the protocol version (i.e one of the
     *         <code>Driver.TDS<i>XX</i></code> values)
     */
    public static int getTdsVersion(int rawTdsVersion) {
        if (rawTdsVersion >= 0x71000001) {
            return Driver.TDS81;
        } else if (rawTdsVersion >= 0x07010000) {
            return Driver.TDS80;
        } else if (rawTdsVersion >= 0x07000000) {
            return Driver.TDS70;
        } else if (rawTdsVersion >= 0x05000000) {
            return Driver.TDS50;
        } else {
            return Driver.TDS42;
        }
    }

    /**
     * Establish if a String can be converted to a byte based character set.
     *
     * @param value The String to test.
     * @param charset The server character set in force.
     * @return <code>boolean</code> true if string can be converted.
     */
    private static boolean canEncode(String value, String charset)
    {
        if (value == null) {
            return true;
        }
        if ("UTF-8".equals(charset)) {
            // Should be no problem with UTF-8
            return true;
        }
        if ("ISO-8859-1".equals(charset)) {
            // ISO_1 = lower byte of unicode
            for (int i = value.length() - 1; i >= 0; i--) {
                if (value.charAt(i) > 255) {
                    return false; // Outside range
                }
            }
            return true;
        }
        if ("ISO-8859-15".equals(charset) || "Cp1252".equals(charset)) {
            // These will accept euro symbol
            for (int i = value.length() - 1; i >= 0; i--) {
                // FIXME This is not correct! Cp1252 also contains other characters.
                // No: I think it is OK the point is to ensure that all characters are either
                // < 256 in which case the sets are the same or the euro which is convertable.
                // Any other combination will cause the string to be sent as unicode.
                char c = value.charAt(i);
                if (c > 255 && c != 0x20AC) {
                    return false; // Outside range
                }
            }
            return true;
        }
        if ("US-ASCII".equals(charset)) {
            for (int i = value.length() - 1; i >= 0; i--) {
                if (value.charAt(i) > 127) {
                    return false; // Outside range
                }
            }
            return true;
        }
        // OK need to do an expensive check
        try {
            return new String(value.getBytes(charset), charset).equals(value);
        } catch (UnsupportedEncodingException e) {
            return false;
        }
    }
}
