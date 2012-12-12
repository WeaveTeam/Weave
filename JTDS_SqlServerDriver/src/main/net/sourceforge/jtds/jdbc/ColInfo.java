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

/**
 * This class is a descriptor for result set columns.
 * <p>
 * Implementation note:
 * <p>
 *      Getter/setter methods have not been provided to avoid clutter
 *      as this class is used in many places in the driver.
 *      As the class is package private this seems reasonable.
 *
 * @author Mike Hutchinson
 * @version $Id: ColInfo.java,v 1.4 2004-11-24 06:42:01 alin_sinpalean Exp $
 */
public class ColInfo {
    /** Internal TDS data type */
    int tdsType;
    /** JDBC type constant from java.sql.Types */
    int jdbcType;
    /** Column actual table name */
    String realName;
    /** Column label / name */
    String name;
    /** Table name owning this column */
    String tableName;
    /** Database owning this column */
    String catalog;
    /** User owning this column */
    String schema;
    /** Column data type supports SQL NULL */
    int nullable;
    /** Column name is case sensitive */
    boolean isCaseSensitive;
    /** Column may be updated */
    boolean isWriteable;
    /** Column is an indentity column */
    boolean isIdentity;
    /** Column may be used as a key */
    boolean isKey;
    /** Column should be hidden */
    boolean isHidden;
    /** Database ID for UDT */
    int userType;
    /** MS SQL2000 collation */
    byte[] collation;
    /** Character set descriptor (if different from default) */
    CharsetInfo charsetInfo;
    /** Column display size */
    int displaySize;
    /** Column buffer (max) size */
    int bufferSize;
    /** Column decimal precision */
    int precision;
    /** Column decimal scale */
    int scale;
    /** The SQL type name for this column. */
    String sqlType;
}