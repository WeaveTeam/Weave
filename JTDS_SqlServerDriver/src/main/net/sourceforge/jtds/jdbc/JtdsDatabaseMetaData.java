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

import java.sql.*;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;

/**
 * jTDS implementation of the java.sql.DatabaseMetaData interface.
 * <p>
 * Implementation note:
 * <p>
 * This is basically the code from the original jTDS driver.
 * Main changes relate to the need to support the new ResultSet
 * implementation.
 * <p>
 * TODO: Many of the system limits need to be revised to more accurately
 * reflect the target database constraints. In many cases limits are soft
 * and determined by bytes per column for example. Probably more of these
 * functions should be altered to return 0 but for now the original jTDS
 * values are returned.
 *
 * @author   Craig Spannring
 * @author   The FreeTDS project
 * @author   Alin Sinpalean
 *  created  17 March 2001
 * @version $Id: JtdsDatabaseMetaData.java,v 1.37.2.4 2009-12-30 08:45:34 ickzon Exp $
 */
public class JtdsDatabaseMetaData implements java.sql.DatabaseMetaData {
    static final int sqlStateXOpen = 1;

    // Internal data needed by this implemention.
    private final int tdsVersion;
    private final int serverType;
    private final ConnectionJDBC2 connection;

    /**
     * Length of a sysname object (table name, catalog name etc.) -- 128 for
     * TDS 7.0, 30 for earlier versions.
     */
    int sysnameLength = 30;

    /**
     * <code>Boolean.TRUE</code> if identifiers are case sensitive (the server
     * was installed that way). Initially <code>null</code>, set the first time
     * any of the methods that check this are called.
     */
    Boolean caseSensitive;

    public JtdsDatabaseMetaData(ConnectionJDBC2 connection) {
        this.connection = connection;
        tdsVersion = connection.getTdsVersion();
        serverType = connection.getServerType();
        if (tdsVersion >= Driver.TDS70) {
            sysnameLength = 128;
        }
    }

    //----------------------------------------------------------------------
    // First, a variety of minor information about the target database.

    /**
     * Can all the procedures returned by getProcedures be called by the
     * current user?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean allProceduresAreCallable() throws SQLException {
        // Sybase - if accessible_sproc = Y in server info (normal case) return true
        return true; // per "Programming ODBC for SQLServer" Appendix A
    }

    /**
     * Can all the tables returned by getTable be SELECTed by the
     * current user?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean allTablesAreSelectable() throws SQLException {
        // Sybase sp_tables may return tables that you are not able to access.
        return connection.getServerType() == Driver.SQLSERVER;
    }

    /**
     * Does a data definition statement within a transaction force the
     * transaction to commit?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean dataDefinitionCausesTransactionCommit() throws SQLException {
        return false;
    }

    /**
     * Is a data definition statement within a transaction ignored?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean dataDefinitionIgnoredInTransactions() throws SQLException {
        return false;
    }

    /**
     * Did getMaxRowSize() include LONGVARCHAR and LONGVARBINARY blobs?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean doesMaxRowSizeIncludeBlobs() throws SQLException {
        return false;
    }

    /**
     * Get a description of a table's optimal set of columns that
     * uniquely identifies a row. They are ordered by SCOPE.
     *
     * <P>Each column description has the following columns:
     *  <OL>
     *    <LI> <B>SCOPE</B> short =>actual scope of result
     *    <UL>
     *      <LI> bestRowTemporary - very temporary, while using row
     *      <LI> bestRowTransaction - valid for remainder of current transaction
     *
     *      <LI> bestRowSession - valid for remainder of current session
     *    </UL>
     *
     *    <LI> <B>COLUMN_NAME</B> String =>column name
     *    <LI> <B>DATA_TYPE</B> short =>SQL data type from java.sql.Types
     *    <LI> <B>TYPE_NAME</B> String =>Data source dependent type name
     *    <LI> <B>COLUMN_SIZE</B> int =>precision
     *    <LI> <B>BUFFER_LENGTH</B> int =>not used
     *    <LI> <B>DECIMAL_DIGITS</B> short =>scale
     *    <LI> <B>PSEUDO_COLUMN</B> short =>is this a pseudo column like an
     *    Oracle ROWID
     *    <UL>
     *      <LI> bestRowUnknown - may or may not be pseudo column
     *      <LI> bestRowNotPseudo - is NOT a pseudo column
     *      <LI> bestRowPseudo - is a pseudo column
     *    </UL>
     *
     *  </OL>
     *
     *
     * @param catalog a catalog name; "" retrieves those without a catalog;
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schema a schema name; "" retrieves those without a schema
     * @param table a table name
     * @param scope the scope of interest; use same values as SCOPE
     * @param nullable include columns that are nullable?
     * @return ResultSet - each row is a column description
     * @throws SQLException if a database-access error occurs.
     */
    public java.sql.ResultSet getBestRowIdentifier(String catalog,
                                                   String schema,
                                                   String table,
                                                   int scope,
                                                   boolean nullable)
    throws SQLException {
        String colNames[] = {"SCOPE",           "COLUMN_NAME",
                             "DATA_TYPE",       "TYPE_NAME",
                             "COLUMN_SIZE",     "BUFFER_LENGTH",
                             "DECIMAL_DIGITS",  "PSEUDO_COLUMN"};
        int    colTypes[] = {Types.SMALLINT,    Types.VARCHAR,
                             Types.INTEGER,     Types.VARCHAR,
                             Types.INTEGER,     Types.INTEGER,
                             Types.SMALLINT,    Types.SMALLINT};

        String query = "sp_special_columns ?, ?, ?, ?, ?, ?, ?";

        CallableStatement s = connection.prepareCall(syscall(catalog, query));

        s.setString(1, table);
        s.setString(2, schema);
        s.setString(3, catalog);
        s.setString(4, "R");
        s.setString(5, "T");
        s.setString(6, "U");
        s.setInt(7, 3); // ODBC version 3

        JtdsResultSet rs = (JtdsResultSet)s.executeQuery();
        CachedResultSet rsTmp = new CachedResultSet((JtdsStatement)s, colNames, colTypes);
        rsTmp.moveToInsertRow();
        int colCnt = rs.getMetaData().getColumnCount();
        while (rs.next()) {
            for (int i = 1; i <= colCnt; i++) {
                if (i == 3) {
                    int type = TypeInfo.normalizeDataType(rs.getInt(i), connection.getUseLOBs());
                    rsTmp.updateInt(i, type);
                } else {
                    rsTmp.updateObject(i, rs.getObject(i));
                }
            }
            rsTmp.insertRow();
        }
        rs.close();
        // Do not close the statement, rsTmp is also built from it
        rsTmp.moveToCurrentRow();
        rsTmp.setConcurrency(ResultSet.CONCUR_READ_ONLY);
        return rsTmp;
    }

    /**
     * Get the catalog names available in this database. The results are
     * ordered by catalog name. <P>
     *
     * The catalog column is:
     * <OL>
     *   <LI> <B>TABLE_CAT</B> String =>catalog name
     * </OL>
     *
     *
     * @return ResultSet - each row has a single String column
     *      that is a catalog name
     * @throws SQLException if a database-access error occurs.
     */
    public java.sql.ResultSet getCatalogs() throws SQLException {
        String query = "exec sp_tables '', '', '%', NULL";
        Statement s = connection.createStatement();
        JtdsResultSet rs = (JtdsResultSet)s.executeQuery(query);

        rs.setColumnCount(1);
        rs.setColLabel(1, "TABLE_CAT");

        upperCaseColumnNames(rs);

        return rs;
    }

    /**
     * What's the separator between catalog and table name?
     *
     * @return the separator string
     * @throws SQLException if a database-access error occurs.
     */
    public String getCatalogSeparator() throws SQLException {
        return ".";
    }

    /**
     * What's the database vendor's preferred term for "catalog"?
     *
     * @return the vendor term
     * @throws SQLException if a database-access error occurs.
     */
    public String getCatalogTerm() throws SQLException {
        return "database";
    }

    /**
     * Get a description of the access rights for a table's columns. <P>
     *
     * Only privileges matching the column name criteria are returned. They are
     * ordered by COLUMN_NAME and PRIVILEGE. <P>
     *
     * Each privilige description has the following columns:
     * <OL>
     *   <LI> <B>TABLE_CAT</B> String =>table catalog (may be null)
     *   <LI> <B>TABLE_SCHEM</B> String =>table schema (may be null)
     *   <LI> <B>TABLE_NAME</B> String =>table name
     *   <LI> <B>COLUMN_NAME</B> String =>column name
     *   <LI> <B>GRANTOR</B> =>grantor of access (may be null)
     *   <LI> <B>GRANTEE</B> String =>grantee of access
     *   <LI> <B>PRIVILEGE</B> String =>name of access (SELECT, INSERT, UPDATE,
     *   REFRENCES, ...)
     *   <LI> <B>IS_GRANTABLE</B> String =>"YES" if grantee is permitted to
     *   grant to others; "NO" if not; null if unknown
     * </OL>
     *
     * @param catalog a catalog name; "" retrieves those without a catalog;
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schema a schema name; "" retrieves those without a schema
     *      schema
     * @param table a table name
     * @param columnNamePattern a column name pattern
     * @return ResultSet - each row is a column privilege description
     * @throws SQLException if a database-access error occurs.
     *
     * @see #getSearchStringEscape
     */
    public java.sql.ResultSet getColumnPrivileges(String catalog,
                                                  String schema,
                                                  String table,
                                                  String columnNamePattern)
    throws SQLException {
        String query = "sp_column_privileges ?, ?, ?, ?";

        CallableStatement s = connection.prepareCall(syscall(catalog, query));

        s.setString(1, table);
        s.setString(2, schema);
        s.setString(3, catalog);
        s.setString(4, processEscapes(columnNamePattern));

        JtdsResultSet rs = (JtdsResultSet)s.executeQuery();

        rs.setColLabel(1, "TABLE_CAT");
        rs.setColLabel(2, "TABLE_SCHEM");

        upperCaseColumnNames(rs);

        return rs;
    }

    /**
     * Get a description of table columns available in a catalog. <P>
     *
     * Only column descriptions matching the catalog, schema, table and column
     * name criteria are returned. They are ordered by TABLE_SCHEM, TABLE_NAME
     * and ORDINAL_POSITION. <P>
     *
     * Each column description has the following columns:
     * <OL>
     *   <LI> <B>TABLE_CAT</B> String =>table catalog (may be null)
     *   <LI> <B>TABLE_SCHEM</B> String =>table schema (may be null)
     *   <LI> <B>TABLE_NAME</B> String =>table name
     *   <LI> <B>COLUMN_NAME</B> String =>column name
     *   <LI> <B>DATA_TYPE</B> short =>SQL type from java.sql.Types
     *   <LI> <B>TYPE_NAME</B> String =>Data source dependent type name
     *   <LI> <B>COLUMN_SIZE</B> int =>column size. For char or date types this
     *   is the maximum number of characters, for numeric or decimal types this
     *   is precision.
     *   <LI> <B>BUFFER_LENGTH</B> is not used.
     *   <LI> <B>DECIMAL_DIGITS</B> int =>the number of fractional digits
     *   <LI> <B>NUM_PREC_RADIX</B> int =>Radix (typically either 10 or 2)
     *   <LI> <B>NULLABLE</B> int =>is NULL allowed?
     *   <UL>
     *     <LI> columnNoNulls - might not allow NULL values
     *     <LI> columnNullable - definitely allows NULL values
     *     <LI> columnNullableUnknown - nullability unknown
     *   </UL>
     *
     *   <LI> <B>REMARKS</B> String =>comment describing column (may be null)
     *
     *   <LI> <B>COLUMN_DEF</B> String =>default value (may be null)
     *   <LI> <B>SQL_DATA_TYPE</B> int =>unused
     *   <LI> <B>SQL_DATETIME_SUB</B> int =>unused
     *   <LI> <B>CHAR_OCTET_LENGTH</B> int =>for char types the maximum number
     *   of bytes in the column
     *   <LI> <B>ORDINAL_POSITION</B> int =>index of column in table (starting
     *   at 1)
     *   <LI> <B>IS_NULLABLE</B> String =>"NO" means column definitely does not
     *   allow NULL values; "YES" means the column might allow NULL values. An
     *   empty string means nobody knows.
     * </OL>
     *
     *
     * @param catalog a catalog name; "" retrieves those without a catalog;
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schemaPattern a schema name pattern; "" retrieves those without a schema
     * @param tableNamePattern a table name pattern
     * @param columnNamePattern a column name pattern
     * @return ResultSet - each row is a column description
     * @throws SQLException if a database-access error occurs.
     *
     * @see #getSearchStringEscape
     */
    public java.sql.ResultSet getColumns(String catalog,
                                         String schemaPattern,
                                         String tableNamePattern,
                                         String columnNamePattern)
    throws SQLException {
        String colNames[] = {"TABLE_CAT",           "TABLE_SCHEM",
                             "TABLE_NAME",          "COLUMN_NAME",
                             "DATA_TYPE",           "TYPE_NAME",
                             "COLUMN_SIZE",         "BUFFER_LENGTH",
                             "DECIMAL_DIGITS",      "NUM_PREC_RADIX",
                             "NULLABLE",            "REMARKS",
                             "COLUMN_DEF",          "SQL_DATA_TYPE",
                             "SQL_DATETIME_SUB",    "CHAR_OCTET_LENGTH",
                             "ORDINAL_POSITION",    "IS_NULLABLE",
                             "SCOPE_CATALOG",       "SCOPE_SCHEMA",
                             "SCOPE_TABLE",         "SOURCE_DATA_TYPE"};

       int colTypes[]     = {Types.VARCHAR,         Types.VARCHAR,
                             Types.VARCHAR,         Types.VARCHAR,
                             Types.INTEGER,         Types.VARCHAR,
                             Types.INTEGER,         Types.INTEGER,
                             Types.INTEGER,         Types.INTEGER,
                             Types.INTEGER,         Types.VARCHAR,
                             Types.VARCHAR,         Types.INTEGER,
                             Types.INTEGER,         Types.INTEGER,
                             Types.INTEGER,         Types.VARCHAR,
                             Types.VARCHAR,         Types.VARCHAR,
                             Types.VARCHAR,         Types.SMALLINT};
        String query = "sp_columns ?, ?, ?, ?, ?";

        CallableStatement s = connection.prepareCall(syscall(catalog, query));

        s.setString(1, processEscapes(tableNamePattern));
        s.setString(2, processEscapes(schemaPattern));
        s.setString(3, catalog);
        s.setString(4, processEscapes(columnNamePattern));
        s.setInt(5, 3); // ODBC version 3

        JtdsResultSet rs = (JtdsResultSet)s.executeQuery();

        CachedResultSet rsTmp = new CachedResultSet((JtdsStatement)s, colNames, colTypes);
        rsTmp.moveToInsertRow();
        int colCnt = rs.getMetaData().getColumnCount();
        //
        // Neither type of server returns exactly the data required by the JDBC3 standard.
        // The result data is copied to a cached result set and modified on the fly.
        //
        while (rs.next()) {
            if (serverType == Driver.SYBASE) {
                // Sybase servers (older versions only return 14 columns)
                for (int i = 1; i <= 4; i++) {
                    rsTmp.updateObject(i, rs.getObject(i));
                }
                rsTmp.updateInt(5, TypeInfo.normalizeDataType(rs.getInt(5), connection.getUseLOBs()));
                String typeName = rs.getString(6);
                rsTmp.updateString(6, typeName);
                for (int i = 8; i <= 12; i++) {
                    rsTmp.updateObject(i, rs.getObject(i));
                }
                if (colCnt >= 20) {
                    // SYBASE 11.92, 12.5
                    for (int i = 13; i <= 18; i++) {
                        rsTmp.updateObject(i, rs.getObject(i + 2));
                    }
                } else {
                    // SYBASE 11.03
                    rsTmp.updateObject(16, rs.getObject(8));
                    rsTmp.updateObject(17, rs.getObject(14));
                }
                if ("image".equals(typeName) || "text".equals(typeName)) {
                    rsTmp.updateInt(7, Integer.MAX_VALUE);
                    rsTmp.updateInt(16, Integer.MAX_VALUE);
                } else
                if ("univarchar".equals(typeName) || "unichar".equals(typeName)) {
                    rsTmp.updateInt(7, rs.getInt(7) / 2);
                    rsTmp.updateObject(16, rs.getObject(7));
                } else {
                    rsTmp.updateInt(7, rs.getInt(7));
                }
            } else {
                // MS SQL Server - Mainly OK but we need to fix some data types.
                for (int i = 1; i <= colCnt; i++) {
                    if (i == 5) {
                        int type = TypeInfo.normalizeDataType(rs.getInt(i), connection.getUseLOBs());
                        rsTmp.updateInt(i, type);
                    } else
                    if (i == 19) {
                        // This is the SS_DATA_TYPE column and contains the TDS
                        // data type constant. We can use this to distinguish
                        // varchar(max) from text on SQL2005.
                        rsTmp.updateString(6, TdsData.getMSTypeName(rs.getString(6), rs.getInt(19)));
                    } else {
                        rsTmp.updateObject(i, rs.getObject(i));
                    }
                }
            }
            rsTmp.insertRow();
        }
        rs.close();
        rsTmp.moveToCurrentRow();
        rsTmp.setConcurrency(ResultSet.CONCUR_READ_ONLY);

        return rsTmp;
    }

    /**
     * Get a description of the foreign key columns in the foreign key table
     * that reference the primary key columns of the primary key table
     * (describe how one table imports another's key). This should normally
     * return a single foreign key/primary key pair (most tables only import a
     * foreign key from a table once.) They are ordered by FKTABLE_CAT,
     * FKTABLE_SCHEM, FKTABLE_NAME, and KEY_SEQ. <P>
     *
     * Each foreign key column description has the following columns:
     * <OL>
     *   <LI> <B>PKTABLE_CAT</B> String =>primary key table catalog (may be
     *   null)
     *   <LI> <B>PKTABLE_SCHEM</B> String =>primary key table schema (may be
     *   null)
     *   <LI> <B>PKTABLE_NAME</B> String =>primary key table name
     *   <LI> <B>PKCOLUMN_NAME</B> String =>primary key column name
     *   <LI> <B>FKTABLE_CAT</B> String =>foreign key table catalog (may be
     *   null) being exported (may be null)
     *   <LI> <B>FKTABLE_SCHEM</B> String =>foreign key table schema (may be
     *   null) being exported (may be null)
     *   <LI> <B>FKTABLE_NAME</B> String =>foreign key table name being
     *   exported
     *   <LI> <B>FKCOLUMN_NAME</B> String =>foreign key column name being
     *   exported
     *   <LI> <B>KEY_SEQ</B> short =>sequence number within foreign key
     *   <LI> <B>UPDATE_RULE</B> short =>What happens to foreign key when
     *   primary is updated:
     *   <UL>
     *     <LI> importedNoAction - do not allow update of primary key if it has
     *     been imported
     *     <LI> importedKeyCascade - change imported key to agree with primary
     *     key update
     *     <LI> importedKeySetNull - change imported key to NULL if its primary
     *     key has been updated
     *     <LI> importedKeySetDefault - change imported key to default values
     *     if its primary key has been updated
     *     <LI> importedKeyRestrict - same as importedKeyNoAction (for ODBC 2.x
     *     compatibility)
     *   </UL>
     *
     *   <LI> <B>DELETE_RULE</B> short =>What happens to the foreign key when
     *   primary is deleted.
     *   <UL>
     *     <LI> importedKeyNoAction - do not allow delete of primary key if it
     *     has been imported
     *     <LI> importedKeyCascade - delete rows that import a deleted key
     *     <LI> importedKeySetNull - change imported key to NULL if its primary
     *     key has been deleted
     *     <LI> importedKeyRestrict - same as importedKeyNoAction (for ODBC 2.x
     *     compatibility)
     *     <LI> importedKeySetDefault - change imported key to default if its
     *     primary key has been deleted
     *   </UL>
     *
     *   <LI> <B>FK_NAME</B> String =>foreign key name (may be null)
     *   <LI> <B>PK_NAME</B> String =>primary key name (may be null)
     *   <LI> <B>DEFERRABILITY</B> short =>can the evaluation of foreign key
     *   constraints be deferred until commit
     *   <UL>
     *     <LI> importedKeyInitiallyDeferred - see SQL92 for definition
     *     <LI> importedKeyInitiallyImmediate - see SQL92 for definition
     *     <LI> importedKeyNotDeferrable - see SQL92 for definition
     *   </UL>
     *
     * </OL>
     *
     * @param primaryCatalog a catalog name; "" retrieves those without a
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param primarySchema a schema name pattern; "" retrieves those without a schema
     * @param primaryTable the table name that exports the key
     * @param foreignCatalog a catalog name; "" retrieves those without a
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param foreignSchema a schema name pattern; "" retrieves those without a schema
     * @param foreignTable the table name that imports the key
     * @return ResultSet - each row is a foreign key column description
     * @throws SQLException if a database-access error occurs.
     *
     * @see #getImportedKeys
     */
    public java.sql.ResultSet getCrossReference(String primaryCatalog,
                                                String primarySchema,
                                                String primaryTable,
                                                String foreignCatalog,
                                                String foreignSchema,
                                                String foreignTable)
    throws SQLException {
        String colNames[] = {"PKTABLE_CAT",  "PKTABLE_SCHEM",
                             "PKTABLE_NAME", "PKCOLUMN_NAME",
                             "FKTABLE_CAT",  "FKTABLE_SCHEM",
                             "FKTABLE_NAME", "FKCOLUMN_NAME",
                             "KEY_SEQ",      "UPDATE_RULE",
                             "DELETE_RULE",  "FK_NAME",
                             "PK_NAME",      "DEFERRABILITY"};
        int colTypes[]    = {Types.VARCHAR,  Types.VARCHAR,
                             Types.VARCHAR,  Types.VARCHAR,
                             Types.VARCHAR,  Types.VARCHAR,
                             Types.VARCHAR,  Types.VARCHAR,
                             Types.SMALLINT, Types.SMALLINT,
                             Types.SMALLINT, Types.VARCHAR,
                             Types.VARCHAR,  Types.SMALLINT};

        String query = "sp_fkeys ?, ?, ?, ?, ?, ?";

        if (primaryCatalog != null) {
            query = syscall(primaryCatalog, query);
        } else if (foreignCatalog != null) {
            query = syscall(foreignCatalog, query);
        } else {
            query = syscall(null, query);
        }

        CallableStatement s = connection.prepareCall(query);

        s.setString(1, primaryTable);
        s.setString(2, processEscapes(primarySchema));
        s.setString(3, primaryCatalog);
        s.setString(4, foreignTable);
        s.setString(5, processEscapes(foreignSchema));
        s.setString(6, foreignCatalog);

        JtdsResultSet rs = (JtdsResultSet)s.executeQuery();
        int colCnt = rs.getMetaData().getColumnCount();
        CachedResultSet rsTmp = new CachedResultSet((JtdsStatement)s, colNames, colTypes);
        rsTmp.moveToInsertRow();
        while (rs.next()) {
            for (int i = 1; i <= colCnt; i++) {
                rsTmp.updateObject(i, rs.getObject(i));
            }
            if (colCnt < 14) {
                rsTmp.updateShort(14, (short)DatabaseMetaData.importedKeyNotDeferrable);
            }
            rsTmp.insertRow();
        }
        rs.close();
        rsTmp.moveToCurrentRow();
        rsTmp.setConcurrency(ResultSet.CONCUR_READ_ONLY);

        return rsTmp;
    }

    /**
     * Returns the name of this database product.
     *
     * @return database product name
     * @throws SQLException if a database-access error occurs.
     */
    public String getDatabaseProductName() throws SQLException {
        return connection.getDatabaseProductName();
    }

    /**
     * Returns the version of this database product.
     *
     * @return database version
     * @throws SQLException if a database-access error occurs.
     */
    public String getDatabaseProductVersion() throws SQLException {
        return connection.getDatabaseProductVersion();
    }

    //----------------------------------------------------------------------

    /**
     * Returns the database's default transaction isolation level. The values
     * are defined in java.sql.Connection.
     *
     * @return the default isolation level
     * @throws SQLException if a database-access error occurs.
     *
     * @see Connection
     */
    public int getDefaultTransactionIsolation() throws SQLException {
        return Connection.TRANSACTION_READ_COMMITTED;
    }

    /**
     * Returns this JDBC driver's major version number.
     *
     * @return JDBC driver major version
     */
    public int getDriverMajorVersion() {
        return Driver.MAJOR_VERSION;
    }

    /**
     * Returns this JDBC driver's minor version number.
     *
     * @return JDBC driver minor version number
     */
    public int getDriverMinorVersion() {
        return Driver.MINOR_VERSION;
    }

    /**
     * Returns the name of this JDBC driver.
     *
     * @return JDBC driver name
     * @throws SQLException if a database-access error occurs.
     */
    public String getDriverName() throws SQLException {
        return "jTDS Type 4 JDBC Driver for MS SQL Server and Sybase";
    }

    /**
     * Returns the version of this JDBC driver.
     *
     * @return JDBC driver version
     * @throws SQLException if a database-access error occurs.
     */
    public String getDriverVersion() throws SQLException {
        return Driver.getVersion();
    }

    /**
     * Get a description of the foreign key columns that reference a table's
     * primary key columns (the foreign keys exported by a table). They are
     * ordered by FKTABLE_CAT, FKTABLE_SCHEM, FKTABLE_NAME, and KEY_SEQ.
     * <p>
     * Each foreign key column description has the following columns:
     * <OL>
     *   <LI> <B>PKTABLE_CAT</B> String =>primary key table catalog (may be
     *   null)
     *   <LI> <B>PKTABLE_SCHEM</B> String =>primary key table schema (may be
     *   null)
     *   <LI> <B>PKTABLE_NAME</B> String =>primary key table name
     *   <LI> <B>PKCOLUMN_NAME</B> String =>primary key column name
     *   <LI> <B>FKTABLE_CAT</B> String =>foreign key table catalog (may be
     *   null) being exported (may be null)
     *   <LI> <B>FKTABLE_SCHEM</B> String =>foreign key table schema (may be
     *   null) being exported (may be null)
     *   <LI> <B>FKTABLE_NAME</B> String =>foreign key table name being
     *   exported
     *   <LI> <B>FKCOLUMN_NAME</B> String =>foreign key column name being
     *   exported
     *   <LI> <B>KEY_SEQ</B> short =>sequence number within foreign key
     *   <LI> <B>UPDATE_RULE</B> short =>What happens to foreign key when
     *   primary is updated:
     *   <UL>
     *     <LI> importedNoAction - do not allow update of primary key if it has
     *     been imported
     *     <LI> importedKeyCascade - change imported key to agree with primary
     *     key update
     *     <LI> importedKeySetNull - change imported key to NULL if its primary
     *     key has been updated
     *     <LI> importedKeySetDefault - change imported key to default values
     *     if its primary key has been updated
     *     <LI> importedKeyRestrict - same as importedKeyNoAction (for ODBC 2.x
     *     compatibility)
     *   </UL>
     *
     *   <LI> <B>DELETE_RULE</B> short =>What happens to the foreign key when
     *   primary is deleted.
     *   <UL>
     *     <LI> importedKeyNoAction - do not allow delete of primary key if it
     *     has been imported
     *     <LI> importedKeyCascade - delete rows that import a deleted key
     *     <LI> importedKeySetNull - change imported key to NULL if its primary
     *     key has been deleted
     *     <LI> importedKeyRestrict - same as importedKeyNoAction (for ODBC 2.x
     *     compatibility)
     *     <LI> importedKeySetDefault - change imported key to default if its
     *     primary key has been deleted
     *   </UL>
     *
     *   <LI> <B>FK_NAME</B> String =>foreign key name (may be null)
     *   <LI> <B>PK_NAME</B> String =>primary key name (may be null)
     *   <LI> <B>DEFERRABILITY</B> short =>can the evaluation of foreign key
     *   constraints be deferred until commit
     *   <UL>
     *     <LI> importedKeyInitiallyDeferred - see SQL92 for definition
     *     <LI> importedKeyInitiallyImmediate - see SQL92 for definition
     *     <LI> importedKeyNotDeferrable - see SQL92 for definition
     *   </UL>
     *
     * </OL>
     *
     *
     * @param catalog a catalog name; "" retrieves those without a
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schema a schema name; "" retrieves those without a schema
     * @param table a table name
     * @return ResultSet - each row is a foreign key column description
     * @throws SQLException if a database-access error occurs.
     *
     * @see #getImportedKeys
     */
    public java.sql.ResultSet getExportedKeys(String catalog,
                                              String schema,
                                              String table)
    throws SQLException {
        return getCrossReference(catalog, schema, table, null, null, null);
    }

    /**
     * Get all the "extra" characters that can be used in unquoted identifier
     * names (those beyond a-z, A-Z, 0-9 and _).
     *
     * @return the string containing the extra characters
     * @throws SQLException if a database-access error occurs.
     */
    public String getExtraNameCharacters() throws SQLException {
        // MS driver returns "$#@" Sybase JConnect returns "@#$ге"
        return "$#@";
    }

    /**
     * Returns the string used to quote SQL identifiers. This returns a space "
     * " if identifier quoting isn't supported. A JDBC-Compliant driver always
     * uses a double quote character.
     *
     * @return the quoting string
     * @throws SQLException if a database-access error occurs.
     */
    public String getIdentifierQuoteString() throws SQLException {
        return "\"";
    }

    /**
     * Get a description of the primary key columns that are referenced by a
     * table's foreign key columns (the primary keys imported by a table). They
     * are ordered by PKTABLE_CAT, PKTABLE_SCHEM, PKTABLE_NAME, and KEY_SEQ.
     * <p>
     * Each primary key column description has the following columns:
     * <OL>
     *   <LI> <B>PKTABLE_CAT</B> String =>primary key table catalog being
     *   imported (may be null)
     *   <LI> <B>PKTABLE_SCHEM</B> String =>primary key table schema being
     *   imported (may be null)
     *   <LI> <B>PKTABLE_NAME</B> String =>primary key table name being
     *   imported
     *   <LI> <B>PKCOLUMN_NAME</B> String =>primary key column name being
     *   imported
     *   <LI> <B>FKTABLE_CAT</B> String =>foreign key table catalog (may be
     *   null)
     *   <LI> <B>FKTABLE_SCHEM</B> String =>foreign key table schema (may be
     *   null)
     *   <LI> <B>FKTABLE_NAME</B> String =>foreign key table name
     *   <LI> <B>FKCOLUMN_NAME</B> String =>foreign key column name
     *   <LI> <B>KEY_SEQ</B> short =>sequence number within foreign key
     *   <LI> <B>UPDATE_RULE</B> short =>What happens to foreign key when
     *   primary is updated:
     *   <UL>
     *     <LI> importedNoAction - do not allow update of primary key if it has
     *     been imported
     *     <LI> importedKeyCascade - change imported key to agree with primary
     *     key update
     *     <LI> importedKeySetNull - change imported key to NULL if its primary
     *     key has been updated
     *     <LI> importedKeySetDefault - change imported key to default values
     *     if its primary key has been updated
     *     <LI> importedKeyRestrict - same as importedKeyNoAction (for ODBC 2.x
     *     compatibility)
     *   </UL>
     *
     *   <LI> <B>DELETE_RULE</B> short =>What happens to the foreign key when
     *   primary is deleted.
     *   <UL>
     *     <LI> importedKeyNoAction - do not allow delete of primary key if it
     *     has been imported
     *     <LI> importedKeyCascade - delete rows that import a deleted key
     *     <LI> importedKeySetNull - change imported key to NULL if its primary
     *     key has been deleted
     *     <LI> importedKeyRestrict - same as importedKeyNoAction (for ODBC 2.x
     *     compatibility)
     *     <LI> importedKeySetDefault - change imported key to default if its
     *     primary key has been deleted
     *   </UL>
     *
     *   <LI> <B>FK_NAME</B> String =>foreign key name (may be null)
     *   <LI> <B>PK_NAME</B> String =>primary key name (may be null)
     *   <LI> <B>DEFERRABILITY</B> short =>can the evaluation of foreign key
     *   constraints be deferred until commit
     *   <UL>
     *     <LI> importedKeyInitiallyDeferred - see SQL92 for definition
     *     <LI> importedKeyInitiallyImmediate - see SQL92 for definition
     *     <LI> importedKeyNotDeferrable - see SQL92 for definition
     *   </UL>
     *
     * </OL>
     *
     * @param catalog a catalog name; "" retrieves those without a
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schema a schema name; "" retrieves those without a schema
     * @param table a table name
     * @return ResultSet - each row is a primary key column description
     * @throws SQLException if a database-access error occurs.
     *
     * @see #getExportedKeys
     */
    public java.sql.ResultSet getImportedKeys(String catalog,
                                              String schema,
                                              String table)
    throws SQLException {
        return getCrossReference(null, null, null, catalog, schema, table);
    }

    /**
     * Get a description of a table's indices and statistics. They are ordered
     * by NON_UNIQUE, TYPE, INDEX_NAME, and ORDINAL_POSITION. <P>
     *
     * Each index column description has the following columns:
     * <OL>
     *   <LI> <B>TABLE_CAT</B> String =>table catalog (may be null)
     *   <LI> <B>TABLE_SCHEM</B> String =>table schema (may be null)
     *   <LI> <B>TABLE_NAME</B> String =>table name
     *   <LI> <B>NON_UNIQUE</B> boolean =>Can index values be non-unique? false
     *   when TYPE is tableIndexStatistic
     *   <LI> <B>INDEX_QUALIFIER</B> String =>index catalog (may be null); null
     *   when TYPE is tableIndexStatistic
     *   <LI> <B>INDEX_NAME</B> String =>index name; null when TYPE is
     *   tableIndexStatistic
     *   <LI> <B>TYPE</B> short =>index type:
     *   <UL>
     *     <LI> tableIndexStatistic - this identifies table statistics that are
     *     returned in conjuction with a table's index descriptions
     *     <LI> tableIndexClustered - this is a clustered index
     *     <LI> tableIndexHashed - this is a hashed index
     *     <LI> tableIndexOther - this is some other style of index
     *   </UL>
     *
     *   <LI> <B>ORDINAL_POSITION</B> short =>column sequence number within
     *   index; zero when TYPE is tableIndexStatistic
     *   <LI> <B>COLUMN_NAME</B> String =>column name; null when TYPE is
     *   tableIndexStatistic
     *   <LI> <B>ASC_OR_DESC</B> String =>column sort sequence, "A" =>
     *   ascending, "D" =>descending, may be null if sort sequence is not
     *   supported; null when TYPE is tableIndexStatistic
     *   <LI> <B>CARDINALITY</B> int =>When TYPE is tableIndexStatistic, then
     *   this is the number of rows in the table; otherwise, it is the number
     *   of unique values in the index.
     *   <LI> <B>PAGES</B> int =>When TYPE is tableIndexStatisic then this is
     *   the number of pages used for the table, otherwise it is the number of
     *   pages used for the current index.
     *   <LI> <B>FILTER_CONDITION</B> String =>Filter condition, if any. (may
     *   be null)
     * </OL>
     *
     * @param catalog a catalog name; "" retrieves those without a
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schema a schema name; "" retrieves those without a schema
     * @param table a table name
     * @param unique when <code>true</code>, return only indices for unique
     *        values; when <code>false</code>, return indices regardless of
     *        whether unique or not
     * @param approximate when <code>true</code>, result is allowed to reflect
     *        approximate or out of data values; when <code>false</code>, results
     *        are requested to be accurate
     * @return ResultSet - each row is an index column description
     * @throws SQLException if a database-access error occurs.
     */
    public java.sql.ResultSet getIndexInfo(String catalog,
                                           String schema,
                                           String table,
                                           boolean unique,
                                           boolean approximate)
    throws SQLException {
        String colNames[] = {"TABLE_CAT",       "TABLE_SCHEM",
                             "TABLE_NAME",      "NON_UNIQUE",
                             "INDEX_QUALIFIER", "INDEX_NAME",
                             "TYPE",            "ORDINAL_POSITION",
                             "COLUMN_NAME",     "ASC_OR_DESC",
                             "CARDINALITY",     "PAGES",
                             "FILTER_CONDITION"};
        int    colTypes[] = {Types.VARCHAR,     Types.VARCHAR,
                             Types.VARCHAR,     Types.BIT,
                             Types.VARCHAR,     Types.VARCHAR,
                             Types.SMALLINT,    Types.SMALLINT,
                             Types.VARCHAR,     Types.VARCHAR,
                             Types.INTEGER,     Types.INTEGER,
                             Types.VARCHAR};
        String query = "sp_statistics ?, ?, ?, ?, ?, ?";

        CallableStatement s = connection.prepareCall(syscall(catalog, query));

        s.setString(1, table);
        s.setString(2, schema);
        s.setString(3, catalog);
        s.setString(4, "%");
        s.setString(5, unique ? "Y" : "N");
        s.setString(6, approximate ? "Q" : "E");

        JtdsResultSet rs = (JtdsResultSet) s.executeQuery();
        int colCnt = rs.getMetaData().getColumnCount();
        CachedResultSet rsTmp = new CachedResultSet((JtdsStatement)s, colNames, colTypes);
        rsTmp.moveToInsertRow();
        while (rs.next()) {
            for (int i = 1; i <= colCnt; i++) {
                rsTmp.updateObject(i, rs.getObject(i));
            }
            rsTmp.insertRow();
        }
        rs.close();
        rsTmp.moveToCurrentRow();
        rsTmp.setConcurrency(ResultSet.CONCUR_READ_ONLY);

        return rsTmp;
    }

    //----------------------------------------------------------------------
    // The following group of methods exposes various limitations
    // based on the target database with the current driver.
    // Unless otherwise specified, a result of zero means there is no
    // limit, or the limit is not known.

    /**
     * How many hex characters can you have in an inline binary literal?
     *
     * @return max literal length
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxBinaryLiteralLength() throws SQLException {
        // Sybase jConnect says 255
        // Actual value is 16384 for Sybase 12.5
        // MS JDBC says 0
        // Probable maximum size for MS is 65,536 * network packet size
        return 131072;
        // per "Programming ODBC for SQLServer" Appendix A
    }

    /**
     * What's the maximum length of a catalog name?
     *
     * @return max name length in bytes
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxCatalogNameLength() throws SQLException {
        return sysnameLength;
    }

    /**
     * What's the max length for a character literal?
     *
     * @return max literal length
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxCharLiteralLength() throws SQLException {
        // Sybase jConnect says 255
        // Actual value is 16384 for Sybase 12.5
        // MS JDBC says 0
        // Probable maximum size for MS is 65,536 * network packet size
        return 131072;
        // per "Programming ODBC for SQLServer" Appendix A
    }

    /**
     * What's the limit on column name length?
     *
     * @return max literal length
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxColumnNameLength() throws SQLException {
        // per "Programming ODBC for SQLServer" Appendix A
        return sysnameLength;
    }

    /**
     * What's the maximum number of columns in a "GROUP BY" clause?
     *
     * @return max number of columns
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxColumnsInGroupBy() throws SQLException {
        // Sybase jConnect says 16
        // MS JDBC says 16
        // per "Programming ODBC for SQLServer" Appendix A
        // Actual MS value is 8060 / average bytes per column
        return (tdsVersion >= Driver.TDS70) ? 0 : 16;
    }

    /**
     * What's the maximum number of columns allowed in an index?
     *
     * @return max columns
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxColumnsInIndex() throws SQLException {
        // per SQL Server Books Online "Administrator's Companion",
        // Part 1, Chapter 1.
        // Sybase 12.5 is 31
        return 16;
    }

    /**
     * What's the maximum number of columns in an "ORDER BY" clause?
     *
     * @return max columns
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxColumnsInOrderBy() throws SQLException {
        // per "Programming ODBC for SQLServer" Appendix A
        // Sybase 12.5 is 31
        // Actual MS value is 8060 / average bytes per column
        return (tdsVersion >= Driver.TDS70) ? 0 : 16;
    }

    /**
     * What's the maximum number of columns in a "SELECT" list?
     *
     * @return max columns
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxColumnsInSelect() throws SQLException {
        // Sybase jConnect says 0
        // per "Programming ODBC for SQLServer" Appendix A
        return 4096;
    }

    /**
     * What's the maximum number of columns in a table?
     *
     * @return max columns
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxColumnsInTable() throws SQLException {
        // Sybase jConnect says 250
        // per "Programming ODBC for SQLServer" Appendix A
        // MS 2000 should be 4096
        // Sybase 12.5 is now 1024
        return (tdsVersion >= Driver.TDS70) ? 1024 : 250;
    }

    /**
     * How many active connections can we have at a time to this database?
     *
     * @return max connections
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxConnections() throws SQLException {
        // Sybase - could query syscurconfigs to get actual value
        // which in practice will be a lot less than 32767!
        // per SQL Server Books Online "Administrator's Companion",
        // Part 1, Chapter 1.
        return 32767;
    }

    /**
     * What's the maximum cursor name length?
     *
     * @return max cursor name length in bytes
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxCursorNameLength() throws SQLException {
        // per "Programming ODBC for SQLServer" Appendix A
        return sysnameLength;
    }

    /**
     * What's the maximum length of an index (in bytes)?
     *
     * @return max index length in bytes
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxIndexLength() throws SQLException {
        // Sybase JConnect says 255
        // Actual Sybase 12.5 is 600 - 5300 depending on page size
        // per "Programming ODBC for SQLServer" Appendix A
        return (tdsVersion >= Driver.TDS70) ? 900 : 255;
    }

    /**
     * What's the maximum length of a procedure name?
     *
     * @return max name length in bytes
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxProcedureNameLength() throws SQLException {
        // per "Programming ODBC for SQLServer" Appendix A
        return sysnameLength;
    }

    /**
     * What's the maximum length of a single row?
     *
     * @return max row size in bytes
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxRowSize() throws SQLException {
        // Sybase jConnect says 1962 but this can be more with wide tables.
        // per SQL Server Books Online "Administrator's Companion",
        // Part 1, Chapter 1.
        return (tdsVersion >= Driver.TDS70) ? 8060 : 1962;
    }

    /**
     * What's the maximum length allowed for a schema name?
     *
     * @return max name length in bytes
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxSchemaNameLength() throws SQLException {
        return sysnameLength;
    }

    /**
     * What's the maximum length of a SQL statement?
     *
     * @return max length in bytes
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxStatementLength() throws SQLException {
        // I think this should return 0 (no limit)
        // actual limit for SQL 7/2000 is 65536 * packet size!
        // Sybase JConnect says 0
        // MS JDBC says 0
        // per "Programming ODBC for SQLServer" Appendix A
        return 0;
    }

    /**
     * How many active statements can we have open at one time to this
     * database?
     *
     * @return the maximum
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxStatements() throws SQLException {
        return 0;
    }

    /**
     * What's the maximum length of a table name?
     *
     * @return max name length in bytes
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxTableNameLength() throws SQLException {
        // per "Programming ODBC for SQLServer" Appendix A
        return sysnameLength;
    }

    /**
     * What's the maximum number of tables in a SELECT?
     *
     * @return the maximum
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxTablesInSelect() throws SQLException {
        // Sybase JConnect says 256
        // MS JDBC says 32!
        // Actual Sybase 12.5 is 50
        // per "Programming ODBC for SQLServer" Appendix A
        return (tdsVersion > Driver.TDS50) ? 256 : 16;
    }

    /**
     *   What's the maximum length of a user name?
     *
     * @return max name length in bytes
     * @throws SQLException if a database-access error occurs.
     */
    public int getMaxUserNameLength() throws SQLException {
        return sysnameLength;
    }

    /**
     * Get a comma separated list of math functions.
     *
     * @return the list
     * @throws SQLException if a database-access error occurs.
     */
    public String getNumericFunctions() throws SQLException {
        // I don't think either Sybase or SQL have a truncate maths function
        // so I have removed it from the list.
        // Also all other drivers return this list in lower case. Should we?
        return "abs,acos,asin,atan,atan2,ceiling,cos,cot,degrees,exp,floor,log,"
            + "log10,mod,pi,power,radians,rand,round,sign,sin,sqrt,tan";
    }

    /**
     * Get a description of a table's primary key columns. They are ordered by
     * COLUMN_NAME. <P>
     *
     * Each primary key column description has the following columns:
     * <OL>
     *   <LI> <B>TABLE_CAT</B> String =>table catalog (may be null)
     *   <LI> <B>TABLE_SCHEM</B> String =>table schema (may be null)
     *   <LI> <B>TABLE_NAME</B> String =>table name
     *   <LI> <B>COLUMN_NAME</B> String =>column name
     *   <LI> <B>KEY_SEQ</B> short =>sequence number within primary key
     *   <LI> <B>PK_NAME</B> String =>primary key name (may be null)
     * </OL>
     *
     * @param catalog a catalog name; "" retrieves those without a
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schema a schema name; "" retrieves those without a schema
     * @param table a table name
     * @return ResultSet - each row is a primary key column description
     * @throws SQLException if a database-access error occurs.
     */
    public java.sql.ResultSet getPrimaryKeys(String catalog,
                                             String schema,
                                             String table)
    throws SQLException {
        String colNames[] = {"TABLE_CAT",    "TABLE_SCHEM",
                             "TABLE_NAME",   "COLUMN_NAME",
                             "KEY_SEQ",      "PK_NAME"};
        int    colTypes[] = {Types.VARCHAR,  Types.VARCHAR,
                             Types.VARCHAR,  Types.VARCHAR,
                             Types.SMALLINT, Types.VARCHAR};
        String query = "sp_pkeys ?, ?, ?";

        CallableStatement s = connection.prepareCall(syscall(catalog, query));

        s.setString(1, table);
        s.setString(2, schema);
        s.setString(3, catalog);

        JtdsResultSet rs = (JtdsResultSet)s.executeQuery();
        CachedResultSet rsTmp = new CachedResultSet((JtdsStatement)s, colNames, colTypes);
        rsTmp.moveToInsertRow();
        int colCnt = rs.getMetaData().getColumnCount();
        while (rs.next()) {
            for (int i = 1; i <= colCnt; i++) {
                rsTmp.updateObject(i, rs.getObject(i));
            }
            rsTmp.insertRow();
        }
        rs.close();
        rsTmp.moveToCurrentRow();
        rsTmp.setConcurrency(ResultSet.CONCUR_READ_ONLY);

        return rsTmp;
    }

    /**
     * Get a description of a catalog's stored procedure parameters and result
     * columns. <P>
     *
     * Only descriptions matching the schema, procedure and parameter name
     * criteria are returned. They are ordered by PROCEDURE_SCHEM and
     * PROCEDURE_NAME. Within this, the return value, if any, is first. Next
     * are the parameter descriptions in call order. The column descriptions
     * follow in column number order. <P>
     *
     * Each row in the ResultSet is a parameter description or column
     * description with the following fields:
     * <OL>
     *   <LI> <B>PROCEDURE_CAT</B> String =>procedure catalog (may be null)
     *
     *   <LI> <B>PROCEDURE_SCHEM</B> String =>procedure schema (may be null)
     *
     *   <LI> <B>PROCEDURE_NAME</B> String =>procedure name
     *   <LI> <B>COLUMN_NAME</B> String =>column/parameter name
     *   <LI> <B>COLUMN_TYPE</B> Short =>kind of column/parameter:
     *   <UL>
     *     <LI> procedureColumnUnknown - nobody knows
     *     <LI> procedureColumnIn - IN parameter
     *     <LI> procedureColumnInOut - INOUT parameter
     *     <LI> procedureColumnOut - OUT parameter
     *     <LI> procedureColumnReturn - procedure return value
     *     <LI> procedureColumnResult - result column in ResultSet
     *   </UL>
     *
     *   <LI> <B>DATA_TYPE</B> short =>SQL type from java.sql.Types
     *   <LI> <B>TYPE_NAME</B> String =>SQL type name
     *   <LI> <B>PRECISION</B> int =>precision
     *   <LI> <B>LENGTH</B> int =>length in bytes of data
     *   <LI> <B>SCALE</B> short =>scale
     *   <LI> <B>RADIX</B> short =>radix
     *   <LI> <B>NULLABLE</B> short =>can it contain NULL?
     *   <UL>
     *     <LI> procedureNoNulls - does not allow NULL values
     *     <LI> procedureNullable - allows NULL values
     *     <LI> procedureNullableUnknown - nullability unknown
     *   </UL>
     *
     *   <LI> <B>REMARKS</B> String =>comment describing parameter/column
     * </OL>
     * <P>
     *
     * <B>Note:</B> Some databases may not return the column descriptions for a
     * procedure. Additional columns beyond REMARKS can be defined by the
     * database.
     *
     * @param catalog a catalog name; "" retrieves those without a
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schemaPattern a schema name pattern; "" retrieves those
     *        without a schema
     * @param procedureNamePattern a procedure name pattern
     * @param columnNamePattern a column name pattern
     * @return ResultSet - each row is a stored procedure parameter or column description
     * @throws SQLException if a database-access error occurs.
     * @see #getSearchStringEscape
     */
    public java.sql.ResultSet getProcedureColumns(String catalog,
                                                  String schemaPattern,
                                                  String procedureNamePattern,
                                                  String columnNamePattern)
    throws SQLException {
        String colNames[] = {"PROCEDURE_CAT",   "PROCEDURE_SCHEM",
                             "PROCEDURE_NAME",  "COLUMN_NAME",
                             "COLUMN_TYPE",     "DATA_TYPE",
                             "TYPE_NAME",       "PRECISION",
                             "LENGTH",          "SCALE",
                             "RADIX",           "NULLABLE",
                             "REMARKS"};
        int   colTypes[]  = {Types.VARCHAR,     Types.VARCHAR,
                             Types.VARCHAR,     Types.VARCHAR,
                             Types.SMALLINT,    Types.INTEGER,
                             Types.VARCHAR,     Types.INTEGER,
                             Types.INTEGER,     Types.SMALLINT,
                             Types.SMALLINT,    Types.SMALLINT,
                             Types.VARCHAR};

        String query = "sp_sproc_columns ?, ?, ?, ?, ?";

        CallableStatement s = connection.prepareCall(syscall(catalog,query));

        s.setString(1, processEscapes(procedureNamePattern));
        s.setString(2, processEscapes(schemaPattern));
        s.setString(3, catalog);
        s.setString(4, processEscapes(columnNamePattern));
        s.setInt(5, 3); // ODBC version 3

        JtdsResultSet rs = (JtdsResultSet)s.executeQuery();
        ResultSetMetaData rsmd = rs.getMetaData();
        CachedResultSet rsTmp = new CachedResultSet((JtdsStatement)s, colNames, colTypes);
        rsTmp.moveToInsertRow();
        while (rs.next()) {
            int offset = 0;
            for (int i = 1; i + offset <= colNames.length; i++) {
                if (i == 5 && !"column_type".equalsIgnoreCase(rsmd.getColumnName(i))) {
                    // With Sybase 11.92 despite what the documentation says, the
                    // column_type column is missing!
                    // Set the output value to 0 and shift the rest along by one.
                    String colName = rs.getString(4);
                    if ("RETURN_VALUE".equals(colName)) {
                        rsTmp.updateInt(i, DatabaseMetaData.procedureColumnReturn);
                    } else {
                        rsTmp.updateInt(i, DatabaseMetaData.procedureColumnUnknown);
                    }
                    offset = 1;
                }
                if (i == 3) {
                    String name = rs.getString(i);
                    if (name != null && name.length() > 0) {
                        int pos = name.lastIndexOf(';');
                        if (pos >= 0) {
                            name = name.substring(0, pos);
                        }
                    }
                    rsTmp.updateString(i + offset, name);
                } else if ("data_type".equalsIgnoreCase(rsmd.getColumnName(i))) {
                    int type = TypeInfo.normalizeDataType(rs.getInt(i), connection.getUseLOBs());
                    rsTmp.updateInt(i + offset, type);
                } else {
                    rsTmp.updateObject(i + offset, rs.getObject(i));
                }
            }
            if (serverType == Driver.SYBASE && rsmd.getColumnCount() >= 22) {
                //
                // For Sybase 12.5+ we can obtain column in/out status from
                // the mode column.
                //
                String mode = rs.getString(22);
                if (mode != null) {
                    if (mode.equalsIgnoreCase("in")) {
                        rsTmp.updateInt(5, DatabaseMetaData.procedureColumnIn);
                    } else
                    if (mode.equalsIgnoreCase("out")) {
                        rsTmp.updateInt(5, DatabaseMetaData.procedureColumnInOut);
                    }
                }
             }
             if (serverType == Driver.SYBASE
                 || tdsVersion == Driver.TDS42
                 || tdsVersion == Driver.TDS70) {
                //
                // Standardise the name of the return_value column as
                // @RETURN_VALUE for Sybase and SQL < 2000
                //
                String colName = rs.getString(4);
                if ("RETURN_VALUE".equals(colName)) {
                    rsTmp.updateString(4, "@RETURN_VALUE");
                }
            }
            rsTmp.insertRow();
        }
        rs.close();
        rsTmp.moveToCurrentRow();
        rsTmp.setConcurrency(ResultSet.CONCUR_READ_ONLY);
        return rsTmp;
    }

    /**
     * Get a description of stored procedures available in a catalog. <P>
     *
     * Only procedure descriptions matching the schema and procedure name
     * criteria are returned. They are ordered by PROCEDURE_SCHEM, and
     * PROCEDURE_NAME. <P>
     *
     * Each procedure description has the the following columns:
     * <OL>
     *   <LI> <B>PROCEDURE_CAT</B> String =>procedure catalog (may be null)
     *
     *   <LI> <B>PROCEDURE_SCHEM</B> String =>procedure schema (may be null)
     *
     *   <LI> <B>PROCEDURE_NAME</B> String =>procedure name
     *   <LI> reserved for future use
     *   <LI> reserved for future use
     *   <LI> reserved for future use
     *   <LI> <B>REMARKS</B> String =>explanatory comment on the procedure
     *   <LI> <B>PROCEDURE_TYPE</B> short =>kind of procedure:
     *   <UL>
     *     <LI> procedureResultUnknown - May return a result
     *     <LI> procedureNoResult - Does not return a result
     *     <LI> procedureReturnsResult - Returns a result
     *   </UL>
     * </OL>
     *
     * @param catalog a catalog name; "" retrieves those without a
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schemaPattern a schema name pattern; "" retrieves those
     *        without a schema
     * @param procedureNamePattern a procedure name pattern
     * @return ResultSet - each row is a procedure description
     * @throws SQLException if a database-access error occurs.
     *
     * @see #getSearchStringEscape
     */
    public java.sql.ResultSet getProcedures(String catalog,
                                            String schemaPattern,
                                            String procedureNamePattern)
    throws SQLException {
        String colNames[] = {"PROCEDURE_CAT",   "PROCEDURE_SCHEM",
                             "PROCEDURE_NAME",  "RESERVED_1",
                             "RESERVED_2",      "RESERVED_3",
                             "REMARKS",         "PROCEDURE_TYPE"};
        int colTypes[]    = {Types.VARCHAR,     Types.VARCHAR,
                             Types.VARCHAR,     Types.INTEGER,
                             Types.INTEGER,     Types.INTEGER,
                             Types.VARCHAR,     Types.SMALLINT};

        String query = "sp_stored_procedures ?, ?, ?";

        CallableStatement s = connection.prepareCall(syscall(catalog, query));

        s.setString(1, processEscapes(procedureNamePattern));
        s.setString(2, processEscapes(schemaPattern));
        s.setString(3, catalog);

        JtdsResultSet rs = (JtdsResultSet)s.executeQuery();

        CachedResultSet rsTmp = new CachedResultSet((JtdsStatement)s, colNames, colTypes);
        rsTmp.moveToInsertRow();
        int colCnt = rs.getMetaData().getColumnCount();
        //
        // Copy results to local result set.
        //
        while (rs.next()) {
            rsTmp.updateString(1, rs.getString(1));
            rsTmp.updateString(2, rs.getString(2));
            String name = rs.getString(3);
            if (name != null) {
                // Remove grouping integer
                if (name.endsWith(";1")) {
                    name = name.substring(0, name.length() - 2);
                }
            }
            rsTmp.updateString(3, name);
            // Copy over rest of fields
            for (int i = 4; i <= colCnt; i++) {
                rsTmp.updateObject(i, rs.getObject(i));
            }
            if (colCnt < 8) {
                // Sybase does not return this column so fake it now.
                rsTmp.updateShort(8, (short)DatabaseMetaData.procedureReturnsResult);
            }
            rsTmp.insertRow();
        }
        rsTmp.moveToCurrentRow();
        rsTmp.setConcurrency(ResultSet.CONCUR_READ_ONLY);
        rs.close();
        return rsTmp;
    }

    /**
     * What's the database vendor's preferred term for "procedure"?
     *
     * @return the vendor term
     * @throws SQLException if a database-access error occurs.
     */
    public String getProcedureTerm() throws SQLException {
        // per "Programming ODBC for SQLServer" Appendix A
        return "stored procedure";
    }

    /**
     * Get the schema names available in this database. The results are ordered
     * by schema name. <P>
     *
     * The schema column is:
     * <OL>
     *   <LI> <B>TABLE_SCHEM</B> String => schema name
     *   <LI> <B>TABLE_CATALOG</B> String => catalog name (may be <code>null</code>, JDBC 3.0)
     * </OL>
     *
     * @return a <code>ResultSet</code> object in which each row is a schema description
     * @throws SQLException if a database access error occurs
     */
    public java.sql.ResultSet getSchemas() throws SQLException {
        java.sql.Statement statement = connection.createStatement();

        String sql;

        if (connection.getServerType() == Driver.SQLSERVER && connection.getDatabaseMajorVersion() >= 9) {
            sql = Driver.JDBC3
                ? "SELECT name AS TABLE_SCHEM, NULL as TABLE_CATALOG FROM sys.schemas"
                : "SELECT name AS TABLE_SCHEM FROM sys.schemas";
        } else {
            sql = Driver.JDBC3
                ? "SELECT name AS TABLE_SCHEM, NULL as TABLE_CATALOG FROM dbo.sysusers"
                : "SELECT name AS TABLE_SCHEM FROM dbo.sysusers";

            //
            // MJH - isLogin column only in MSSQL >= 7.0
            //
            if (tdsVersion >= Driver.TDS70) {
                sql += " WHERE islogin=1";
            } else {
                sql += " WHERE uid>0";
            }
        }

        sql += " ORDER BY TABLE_SCHEM";

        return statement.executeQuery(sql);
    }

    /**
     * What's the database vendor's preferred term for "schema"?
     *
     * @return the vendor term
     * @throws SQLException if a database-access error occurs.
     */
    public String getSchemaTerm() throws SQLException {
        return "owner";
    }

    /**
     * This is the string that can be used to escape '_' or '%' in the string
     * pattern style catalog search parameters. <P>
     *
     * The '_' character represents any single character. <P>
     *
     * The '%' character represents any sequence of zero or more characters.
     *
     * @return the string used to escape wildcard characters
     * @throws SQLException if a database-access error occurs.
     */
    public String getSearchStringEscape() throws SQLException {
        // per "Programming ODBC for SQLServer" Appendix A
        return "\\";
    }

    /**
     * Get a comma separated list of all a database's SQL keywords that are NOT
     * also SQL92 keywords.
     *
     * @return the list
     * @throws SQLException  if a database-access error occurs.
     */
    public String getSQLKeywords() throws SQLException {
        //
        // This is a superset of the SQL keywords in SQL Server and Sybase
        //
        return "ARITH_OVERFLOW,BREAK,BROWSE,BULK,CHAR_CONVERT,CHECKPOINT,"
                + "CLUSTERED,COMPUTE,CONFIRM,CONTROLROW,DATA_PGS,DATABASE,DBCC,"
                + "DISK,DUMMY,DUMP,ENDTRAN,ERRLVL,ERRORDATA,ERROREXIT,EXIT,"
                + "FILLFACTOR,HOLDLOCK,IDENTITY_INSERT,IF,INDEX,KILL,LINENO,"
                + "LOAD,MAX_ROWS_PER_PAGE,MIRROR,MIRROREXIT,NOHOLDLOCK,NONCLUSTERED,"
                + "NUMERIC_TRUNCATION,OFF,OFFSETS,ONCE,ONLINE,OVER,PARTITION,PERM,"
                + "PERMANENT,PLAN,PRINT,PROC,PROCESSEXIT,RAISERROR,READ,READTEXT,"
                + "RECONFIGURE,REPLACE,RESERVED_PGS,RETURN,ROLE,ROWCNT,ROWCOUNT,"
                + "RULE,SAVE,SETUSER,SHARED,SHUTDOWN,SOME,STATISTICS,STRIPE,"
                + "SYB_IDENTITY,SYB_RESTREE,SYB_TERMINATE,TEMP,TEXTSIZE,TRAN,"
                + "TRIGGER,TRUNCATE,TSEQUAL,UNPARTITION,USE,USED_PGS,USER_OPTION,"
                + "WAITFOR,WHILE,WRITETEXT";
    }

    /**
     * Get a comma separated list of string functions.
     *
     * @return the list
     * @throws SQLException  if a database-access error occurs.
     */
    public String getStringFunctions() throws SQLException {
        if (connection.getServerType() == Driver.SQLSERVER) {
            return "ascii,char,concat,difference,insert,lcase,left,length,locate,"
                 + "ltrim,repeat,replace,right,rtrim,soundex,space,substring,ucase";
        } else {
            return "ascii,char,concat,difference,insert,lcase,length,"
                 + "ltrim,repeat,right,rtrim,soundex,space,substring,ucase";
        }
    }

    /**
     * Get a comma separated list of system functions.
     *
     * @return the list
     * @throws SQLException if a database-access error occurs.
     */
    public String getSystemFunctions() throws SQLException {
        return "database,ifnull,user,convert";
    }

    /**
     * Get a description of the access rights for each table available in a
     * catalog. Note that a table privilege applies to one or more columns in
     * the table. It would be wrong to assume that this priviledge applies to
     * all columns (this may be true for some systems but is not true for all.)
     * <P>
     *
     * Only privileges matching the schema and table name criteria are
     * returned. They are ordered by TABLE_SCHEM, TABLE_NAME, and PRIVILEGE.
     * <P>
     *
     * Each privilige description has the following columns:
     * <OL>
     *   <LI> <B>TABLE_CAT</B> String =>table catalog (may be null)
     *   <LI> <B>TABLE_SCHEM</B> String =>table schema (may be null)
     *   <LI> <B>TABLE_NAME</B> String =>table name
     *   <LI> <B>GRANTOR</B> =>grantor of access (may be null)
     *   <LI> <B>GRANTEE</B> String =>grantee of access
     *   <LI> <B>PRIVILEGE</B> String =>name of access (SELECT, INSERT, UPDATE,
     *   REFRENCES, ...)
     *   <LI> <B>IS_GRANTABLE</B> String =>"YES" if grantee is permitted to
     *   grant to others; "NO" if not; null if unknown
     * </OL>
     *
     * @param catalog a catalog name; "" retrieves those without a
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schemaPattern a schema name pattern; "" retrieves those
     *        without a schema
     * @param tableNamePattern a table name pattern
     * @return ResultSet - each row is a table privilege description
     * @throws SQLException if a database-access error occurs.
     *
     * @see #getSearchStringEscape
     */
    public java.sql.ResultSet getTablePrivileges(String catalog,
                                                 String schemaPattern,
                                                 String tableNamePattern)
    throws SQLException {
        String query = "sp_table_privileges ?, ?, ?";

        CallableStatement s = connection.prepareCall(syscall(catalog, query));

        s.setString(1, processEscapes(tableNamePattern));
        s.setString(2, processEscapes(schemaPattern));
        s.setString(3, catalog);

        JtdsResultSet rs = (JtdsResultSet)s.executeQuery();

        rs.setColLabel(1, "TABLE_CAT");
        rs.setColLabel(2, "TABLE_SCHEM");

        upperCaseColumnNames(rs);

        return rs;
    }

    /**
     * Get a description of tables available in a catalog. <P>
     *
     * Only table descriptions matching the catalog, schema, table name and
     * type criteria are returned. They are ordered by TABLE_TYPE, TABLE_SCHEM
     * and TABLE_NAME. <P>
     *
     * Each table description has the following columns:
     * <OL>
     *   <LI> <B>TABLE_CAT</B> String =>table catalog (may be null)
     *   <LI> <B>TABLE_SCHEM</B> String =>table schema (may be null)
     *   <LI> <B>TABLE_NAME</B> String =>table name
     *   <LI> <B>TABLE_TYPE</B> String =>table type. Typical types are "TABLE",
     *     "VIEW", "SYSTEM TABLE", "GLOBAL TEMPORARY", "LOCAL TEMPORARY",
     *     "ALIAS", "SYNONYM".
     *   <LI> <B>REMARKS</B> String =>explanatory comment on the table
     *   <LI> <B>TYPE_CAT</B> String => the types catalog (may be
     *     <code>null</code>)
     *   <LI> <B>TYPE_SCHEM</B> String => the types schema (may be
     *     <code>null</code>)
     *   <LI> <B>TYPE_NAME</B> String => type name (may be <code>null</code>)
     *   <LI> <B>SELF_REFERENCING_COL_NAME</B> String => name of the designated
     *     "identifier" column of a typed table (may be <code>null</code>)
     *	 <LI> <B>REF_GENERATION</B> String => specifies how values in
     *     SELF_REFERENCING_COL_NAME are created. Values are "SYSTEM", "USER",
     *     "DERIVED". (may be <code>null</code>)
     * </OL>
     * <P>
     *
     * <B>Note:</B> Some databases may not return information for all tables.
     *
     * @param catalog a catalog name; "" retrieves those without a
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schemaPattern a schema name pattern; "" retrieves those
     *        without a schema
     * @param tableNamePattern  a table name pattern
     * @param types a list of table types to include; null returns all types
     * @return ResultSet - each row is a table description
     * @throws SQLException if a database-access error occurs.
     *
     * @see #getSearchStringEscape
     */
    public java.sql.ResultSet getTables(String catalog,
                                        String schemaPattern,
                                        String tableNamePattern,
                                        String types[])
    throws SQLException {
        String colNames[] = {"TABLE_CAT",                   "TABLE_SCHEM",
                             "TABLE_NAME",                  "TABLE_TYPE",
                             "REMARKS",                     "TYPE_CAT",
                             "TYPE_SCHEM",                  "TYPE_NAME",
                             "SELF_REFERENCING_COL_NAME",   "REF_GENERATION"};
        int    colTypes[] = {Types.VARCHAR,                 Types.VARCHAR,
                             Types.VARCHAR,                 Types.VARCHAR,
                             Types.VARCHAR,                 Types.VARCHAR,
                             Types.VARCHAR,                 Types.VARCHAR,
                             Types.VARCHAR,                 Types.VARCHAR};
        String query = "sp_tables ?, ?, ?, ?";

        CallableStatement cstmt = connection.prepareCall(syscall(catalog, query));

        cstmt.setString(1, processEscapes(tableNamePattern));
        cstmt.setString(2, processEscapes(schemaPattern));
        cstmt.setString(3, catalog);

        if (types == null) {
            cstmt.setString(4, null);
        } else {
            StringBuffer buf = new StringBuffer(64);

            buf.append('"');

            for (int i = 0; i < types.length; i++) {
                buf.append('\'').append(types[i]).append("',");
            }

            if (buf.length() > 1) {
                buf.setLength(buf.length() - 1);
            }

            buf.append('"');
            cstmt.setString(4, buf.toString());
        }

        JtdsResultSet rs = (JtdsResultSet) cstmt.executeQuery();
        CachedResultSet rsTmp = new CachedResultSet((JtdsStatement)cstmt, colNames, colTypes);
        rsTmp.moveToInsertRow();
        int colCnt = rs.getMetaData().getColumnCount();
        //
        // Copy results to local result set.
        //
        while (rs.next()) {
            for (int i = 1; i <= colCnt; i++) {
                rsTmp.updateObject(i, rs.getObject(i));
            }
            rsTmp.insertRow();
        }
        rsTmp.moveToCurrentRow();
        rsTmp.setConcurrency(ResultSet.CONCUR_READ_ONLY);
        rs.close();
        return rsTmp;
    }

    /**
     * Get the table types available in this database. The results are ordered
     * by table type. <P>
     *
     * The table type is:
     * <OL>
     *   <LI> <B>TABLE_TYPE</B> String => table type. Typical types are "TABLE",
     *   "VIEW", "SYSTEM TABLE", "GLOBAL TEMPORARY", "LOCAL TEMPORARY",
     *   "ALIAS", "SYNONYM".
     * </OL>
     *
     * @return ResultSet - each row has a single String column that is a table type
     * @throws SQLException if a database-access error occurs.
     */
    public java.sql.ResultSet getTableTypes() throws SQLException {
        String sql = "select 'SYSTEM TABLE' TABLE_TYPE "
                     + "union select 'TABLE' TABLE_TYPE "
                     + "union select 'VIEW' TABLE_TYPE "
                     + "order by TABLE_TYPE";
        java.sql.Statement stmt = connection.createStatement();

        return stmt.executeQuery(sql);
    }

    /**
     * Get a comma separated list of time and date functions.
     *
     * @return the list
     * @throws SQLException if a database-access error occurs.
     */
    public String getTimeDateFunctions() throws SQLException {
        return "curdate,curtime,dayname,dayofmonth,dayofweek,dayofyear,hour,"
            + "minute,month,monthname,now,quarter,timestampadd,timestampdiff,"
            + "second,week,year";
    }

    /**
     * Get a description of all the standard SQL types supported by this
     * database. They are ordered by DATA_TYPE and then by how closely the data
     * type maps to the corresponding JDBC SQL type. <P>
     *
     * Each type description has the following columns:
     * <OL>
     *   <LI> <B>TYPE_NAME</B> String =>Type name
     *   <LI> <B>DATA_TYPE</B> short =>SQL data type from java.sql.Types
     *   <LI> <B>PRECISION</B> int =>maximum precision
     *   <LI> <B>LITERAL_PREFIX</B> String =>prefix used to quote a literal
     *   (may be null)
     *   <LI> <B>LITERAL_SUFFIX</B> String =>suffix used to quote a literal
     *   (may be null)
     *   <LI> <B>CREATE_PARAMS</B> String =>parameters used in creating the
     *   type (may be null)
     *   <LI> <B>NULLABLE</B> short =>can you use NULL for this type?
     *   <UL>
     *     <LI> typeNoNulls - does not allow NULL values
     *     <LI> typeNullable - allows NULL values
     *     <LI> typeNullableUnknown - nullability unknown
     *   </UL>
     *
     *   <LI> <B>CASE_SENSITIVE</B> boolean=>is it case sensitive?
     *   <LI> <B>SEARCHABLE</B> short =>can you use "WHERE" based on this type:
     *
     *   <UL>
     *     <LI> typePredNone - No support
     *     <LI> typePredChar - Only supported with WHERE .. LIKE
     *     <LI> typePredBasic - Supported except for WHERE .. LIKE
     *     <LI> typeSearchable - Supported for all WHERE ..
     *   </UL>
     *
     *   <LI> <B>UNSIGNED_ATTRIBUTE</B> boolean =>is it unsigned?
     *   <LI> <B>FIXED_PREC_SCALE</B> boolean =>can it be a money value?
     *   <LI> <B>AUTO_INCREMENT</B> boolean =>can it be used for an
     *   auto-increment value?
     *   <LI> <B>LOCAL_TYPE_NAME</B> String =>localized version of type name
     *   (may be null)
     *   <LI> <B>MINIMUM_SCALE</B> short =>minimum scale supported
     *   <LI> <B>MAXIMUM_SCALE</B> short =>maximum scale supported
     *   <LI> <B>SQL_DATA_TYPE</B> int =>unused
     *   <LI> <B>SQL_DATETIME_SUB</B> int =>unused
     *   <LI> <B>NUM_PREC_RADIX</B> int =>usually 2 or 10
     * </OL>
     *
     * @return ResultSet - each row is a SQL type description
     * @throws SQLException if a database-access error occurs.
     */
    public java.sql.ResultSet getTypeInfo() throws SQLException {
        Statement s = connection.createStatement();
        JtdsResultSet rs;

        try {
            rs = (JtdsResultSet) s.executeQuery("exec sp_datatype_info @ODBCVer=3");
        } catch (SQLException ex) {
            s.close();
            throw ex;
        }

        try {
            return createTypeInfoResultSet(rs, connection.getUseLOBs());
        } finally {
            // CachedResultSet retains reference to same statement as rs, so don't close statement
            rs.close();
        }
    }

    /**
     * JDBC 2.0 Gets a description of the user-defined types defined in a
     * particular schema. Schema-specific UDTs may have type JAVA_OBJECT,
     * STRUCT, or DISTINCT. <P>
     *
     * Only types matching the catalog, schema, type name and type criteria are
     * returned. They are ordered by DATA_TYPE, TYPE_SCHEM and TYPE_NAME. The
     * type name parameter may be a fully-qualified name. In this case, the
     * catalog and schemaPattern parameters are ignored. <P>
     *
     * Each type description has the following columns:
     * <OL>
     *   <LI> <B>TYPE_CAT</B> String =>the type's catalog (may be null)
     *   <LI> <B>TYPE_SCHEM</B> String =>type's schema (may be null)
     *   <LI> <B>TYPE_NAME</B> String =>type name
     *   <LI> <B>CLASS_NAME</B> String =>Java class name
     *   <LI> <B>DATA_TYPE</B> String =>type value defined in java.sql.Types.
     *   One of JAVA_OBJECT, STRUCT, or DISTINCT
     *   <LI> <B>REMARKS</B> String =>explanatory comment on the type
     * </OL>
     * <P>
     *
     * <B>Note:</B> If the driver does not support UDTs, an empty result set is
     * returned.
     *
     * @param catalog a catalog name; "" retrieves those without a
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schemaPattern a schema name pattern; "" retrieves those
     *        without a schema
     * @param typeNamePattern a type name pattern; may be a fully-qualified
     *        name
     * @param types a list of user-named types to include
     *        (JAVA_OBJECT, STRUCT, or DISTINCT); null returns all types
     * @return ResultSet - each row is a type description
     * @throws SQLException if a database access error occurs
     */
    public java.sql.ResultSet getUDTs(String catalog,
                                      String schemaPattern,
                                      String typeNamePattern,
                                      int[] types)
            throws SQLException {
        String colNames[] = {"TYPE_CAT",    "TYPE_SCHEM",
                             "TYPE_NAME",   "CLASS_NAME",
                             "DATA_TYPE",   "REMARKS",
                             "BASE_TYPE"};
        int    colTypes[] = {Types.VARCHAR, Types.VARCHAR,
                             Types.VARCHAR, Types.VARCHAR,
                             Types.INTEGER, Types.VARCHAR,
                             Types.SMALLINT};
        //
        // Return an empty result set
        //
        JtdsStatement dummyStmt = (JtdsStatement) connection.createStatement();
        CachedResultSet rs = new CachedResultSet(dummyStmt, colNames, colTypes);
        rs.setConcurrency(ResultSet.CONCUR_READ_ONLY);
        return rs;
    }

    /**
     * What's the URL for this database?
     *
     * @return the URL or null if it can't be generated
     * @throws SQLException if a database-access error occurs
     */
    public String getURL() throws SQLException {
        return connection.getURL();
    }

    /**
     * What's our user name as known to the database?
     *
     * @return our database user name
     * @throws SQLException if a database-access error occurs.
     */
    public String getUserName() throws SQLException {
        java.sql.Statement s = null;
        java.sql.ResultSet rs = null;
        String result = "";

        try {
            s = connection.createStatement();

            // MJH Sybase does not support system_user
            if (connection.getServerType() == Driver.SYBASE) {
                rs = s.executeQuery("select suser_name()");
            } else {
                rs = s.executeQuery("select system_user");
            }

            if (!rs.next()) {
                throw new SQLException(Messages.get("error.dbmeta.nouser"), "HY000");
            }

            result = rs.getString(1);
        } finally {
            if (rs != null) {
                rs.close();
            }

            if (s != null) {
                s.close();
            }
        }
        return result;
    }

    /**
     * Get a description of a table's columns that are automatically updated
     * when any value in a row is updated. They are unordered. <P>
     *
     * Each column description has the following columns:
     * <OL>
     *   <LI> <B>SCOPE</B> short =>is not used
     *   <LI> <B>COLUMN_NAME</B> String =>column name
     *   <LI> <B>DATA_TYPE</B> short =>SQL data type from java.sql.Types
     *   <LI> <B>TYPE_NAME</B> String =>Data source dependent type name
     *   <LI> <B>COLUMN_SIZE</B> int =>precision
     *   <LI> <B>BUFFER_LENGTH</B> int =>length of column value in bytes
     *   <LI> <B>DECIMAL_DIGITS</B> short =>scale
     *   <LI> <B>PSEUDO_COLUMN</B> short =>is this a pseudo column like an
     *   Oracle ROWID
     *   <UL>
     *     <LI> versionColumnUnknown - may or may not be pseudo column
     *     <LI> versionColumnNotPseudo - is NOT a pseudo column
     *     <LI> versionColumnPseudo - is a pseudo column
     *   </UL>
     * </OL>
     *
     * @param catalog a catalog name; "" retrieves those without a
     *        <code>null</code> means drop catalog name from the selection criteria
     * @param schema a schema name; "" retrieves those without a schema
     * @param table a table name
     * @return ResultSet - each row is a column description
     * @throws SQLException if a database-access error occurs.
     */
    public java.sql.ResultSet getVersionColumns(String catalog,
                                                String schema,
                                                String table)
    throws SQLException {
        String colNames[] = {"SCOPE", "COLUMN_NAME","DATA_TYPE",
                             "TYPE_NAME","COLUMN_SIZE",
                             "BUFFER_LENGTH","DECIMAL_DIGITS",
                             "PSEUDO_COLUMN"};
        int    colTypes[] = {Types.SMALLINT,Types.VARCHAR,
                             Types.INTEGER, Types.VARCHAR,
                             Types.INTEGER, Types.INTEGER,
                             Types.SMALLINT,Types.SMALLINT};

        String query = "sp_special_columns ?, ?, ?, ?, ?, ?, ?";

        CallableStatement s = connection.prepareCall(syscall(catalog, query));

        s.setString(1, table);
        s.setString(2, schema);
        s.setString(3, catalog);
        s.setString(4, "V");
        s.setString(5, "C");
        s.setString(6, "O");
        s.setInt(7, 3); // ODBC version 3

        JtdsResultSet rs = (JtdsResultSet) s.executeQuery();
        CachedResultSet rsTmp = new CachedResultSet((JtdsStatement)s, colNames, colTypes);
        rsTmp.moveToInsertRow();
        int colCnt = rs.getMetaData().getColumnCount();
        //
        // Copy results to local result set.
        //
        while (rs.next()) {
            for (int i = 1; i <= colCnt; i++) {
                rsTmp.updateObject(i, rs.getObject(i));
            }
            rsTmp.insertRow();
        }
        rsTmp.moveToCurrentRow();
        rsTmp.setConcurrency(ResultSet.CONCUR_READ_ONLY);
        rs.close();
        return rsTmp;
    }

    /**
     * Retrieves whether a catalog appears at the start of a fully qualified
     * table name.  If not, the catalog appears at the end.
     *
     * @return true if it appears at the start
     * @throws SQLException if a database-access error occurs.
     */
    public boolean isCatalogAtStart() throws SQLException {
        return true;
    }

    /**
     * Is the database in read-only mode?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean isReadOnly() throws SQLException {
        return false;
    }

    /**
     * JDBC 2.0 Retrieves the connection that produced this metadata object.
     *
     * @return the connection that produced this metadata object
     * @throws  SQLException if a database-access error occurs.
     */
    public java.sql.Connection getConnection() throws SQLException {
        return connection;
    }

    /**
     * Retrieves whether this database supports concatenations between
     * <code>NULL</code> and non-<code>NULL</code> values being
     * <code>NULL</code>.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean nullPlusNonNullIsNull() throws SQLException {
        // Sybase 11.92 says true
        // MS SQLServer seems to break with the SQL standard here.
        // maybe there is an option to make null behavior comply
        //
        // SAfe: Nope, it seems to work fine in SQL Server 7.0
        return true;
    }

    /**
     * Are NULL values sorted at the end regardless of sort order?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean nullsAreSortedAtEnd() throws SQLException {
        return false;
    }

    /**
     * Are NULL values sorted at the start regardless of sort order?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean nullsAreSortedAtStart() throws SQLException {
        return false;
    }

    /**
     * Are NULL values sorted high?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean nullsAreSortedHigh() throws SQLException {
        return false;
    }

    /**
     * Are NULL values sorted low?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean nullsAreSortedLow() throws SQLException {
        return true;
    }

    /**
     * Does the database treat mixed case unquoted SQL identifiers as case
     * insensitive and store them in lower case?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean storesLowerCaseIdentifiers() throws SQLException {
        return false;
    }

    /**
     * Does the database treat mixed case quoted SQL identifiers as case
     * insensitive and store them in lower case?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean storesLowerCaseQuotedIdentifiers() throws SQLException {
        return false;
    }

    /**
     * Does the database treat mixed case unquoted SQL identifiers as case
     * insensitive and store them in mixed case?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean storesMixedCaseIdentifiers() throws SQLException {
        setCaseSensitiveFlag();

        return !caseSensitive.booleanValue();
    }

    /**
     * Does the database treat mixed case quoted SQL identifiers as case
     * insensitive and store them in mixed case?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean storesMixedCaseQuotedIdentifiers() throws SQLException {
        setCaseSensitiveFlag();

        return !caseSensitive.booleanValue();
    }

    /**
     * Does the database treat mixed case unquoted SQL identifiers as case
     * insensitive and store them in upper case?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean storesUpperCaseIdentifiers() throws SQLException {
        return false;
    }

    /**
     * Does the database treat mixed case quoted SQL identifiers as case
     * insensitive and store them in upper case?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean storesUpperCaseQuotedIdentifiers() throws SQLException {
        return false;
    }

    //--------------------------------------------------------------------
    // Functions describing which features are supported.

    /**
     * Is "ALTER TABLE" with add column supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsAlterTableWithAddColumn() throws SQLException {
        return true;
    }

    /**
     * Is "ALTER TABLE" with drop column supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsAlterTableWithDropColumn() throws SQLException {
        return true;
    }

    /**
     * Retrieves whether this database supports the ANSI92 entry level SQL
     * grammar.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsANSI92EntryLevelSQL() throws SQLException {
        return true;
    }

    /**
     * Is the ANSI92 full SQL grammar supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsANSI92FullSQL() throws SQLException {
        return false;
    }

    /**
     * Is the ANSI92 intermediate SQL grammar supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsANSI92IntermediateSQL() throws SQLException {
        return false;
    }

    /**
     * Can a catalog name be used in a data manipulation statement?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsCatalogsInDataManipulation() throws SQLException {
        return true;
    }

    /**
     * Can a catalog name be used in an index definition statement?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsCatalogsInIndexDefinitions() throws SQLException {
        return true;
    }

    /**
     * Can a catalog name be used in a privilege definition statement?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsCatalogsInPrivilegeDefinitions() throws SQLException {
        return true;
    }

    /**
     * Can a catalog name be used in a procedure call statement?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsCatalogsInProcedureCalls() throws SQLException {
        return true;
    }

    /**
     * Can a catalog name be used in a table definition statement?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsCatalogsInTableDefinitions() throws SQLException {
        return true;
    }

    /**
     * Retrieves whether this database supports column aliasing.
     * <p>
     * If so, the SQL AS clause can be used to provide names for computed
     * columns or to provide alias names for columns as required. A
     * JDBC-Compliant driver always returns true.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsColumnAliasing() throws SQLException {
        return true;
    }

    /**
     * Is the CONVERT function between SQL types supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsConvert() throws SQLException {
        return true;
    }

    /**
     * Is CONVERT between the given SQL types supported?
     *
     * @param fromType the type to convert from
     * @param toType the type to convert to
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsConvert(int fromType, int toType)
            throws SQLException {
        if (fromType == toType) {
            return true;
        }

        switch (fromType) {
            // SAfe Most types will convert to anything but IMAGE and
            //      TEXT/NTEXT (and UNIQUEIDENTIFIER, but that's not a standard
            //      type).
            case Types.BIT:
            case Types.TINYINT:
            case Types.SMALLINT:
            case Types.INTEGER:
            case Types.BIGINT:
            case Types.FLOAT:
            case Types.REAL:
            case Types.DOUBLE:
            case Types.NUMERIC:
            case Types.DECIMAL:
            case Types.DATE:
            case Types.TIME:
            case Types.TIMESTAMP:
                return toType != Types.LONGVARCHAR && toType != Types.LONGVARBINARY
                        && toType != Types.BLOB && toType != Types.CLOB;

            case Types.BINARY:
            case Types.VARBINARY:
                return toType != Types.FLOAT && toType != Types.REAL
                    && toType != Types.DOUBLE;

            // IMAGE
            case Types.BLOB:
            case Types.LONGVARBINARY:
                return toType == Types.BINARY || toType == Types.VARBINARY
                        || toType == Types.BLOB || toType == Types.LONGVARBINARY;

            // TEXT and NTEXT
            case Types.CLOB:
            case Types.LONGVARCHAR:
                return toType == Types.CHAR || toType == Types.VARCHAR
                        || toType == Types.CLOB || toType == Types.LONGVARCHAR;

            // These types can be converted to anything
            case Types.NULL:
            case Types.CHAR:
            case Types.VARCHAR:
                return true;

            // We can't tell for sure what will happen with other types, so...
            case Types.OTHER:
            default:
                return false;
        }
    }

    /**
     * Is the ODBC Core SQL grammar supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsCoreSQLGrammar() throws SQLException {
        return true;
    }

    /**
     * Retrieves whether this database supports correlated subqueries.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsCorrelatedSubqueries() throws SQLException {
        return true;
    }

    /**
     * Are both data definition and data manipulation statements within a
     * transaction supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsDataDefinitionAndDataManipulationTransactions()
    throws SQLException {
        // Sybase requires the 'DDL IN TRAN' db option to be set for
        // This to be strictly true.
        return true;
    }

    /**
     * Are only data manipulation statements within a transaction supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsDataManipulationTransactionsOnly()
    throws SQLException {
        return false;
    }

    /**
     * If table correlation names are supported, are they restricted to be
     * different from the names of the tables?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsDifferentTableCorrelationNames() throws SQLException {
        return false;
    }

    /**
     * Are expressions in "ORDER BY" lists supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsExpressionsInOrderBy() throws SQLException {
        return true;
    }

    /**
     * Is the ODBC Extended SQL grammar supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsExtendedSQLGrammar() throws SQLException {
        return false;
    }

    /**
     * Are full nested outer joins supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsFullOuterJoins() throws SQLException {
        if (connection.getServerType() == Driver.SYBASE) {
            // Supported since version 12
            return getDatabaseMajorVersion() >= 12;
        }
        return true;
    }

    /**
     * Is some form of "GROUP BY" clause supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsGroupBy() throws SQLException {
        return true;
    }

    /**
     * Can a "GROUP BY" clause add columns not in the SELECT provided it
     * specifies all the columns in the SELECT?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsGroupByBeyondSelect() throws SQLException {
        // per "Programming ODBC for SQLServer" Appendix A
        return true;
    }

    /**
     * Can a "GROUP BY" clause use columns not in the SELECT?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsGroupByUnrelated() throws SQLException {
        return true;
    }

    /**
     * Is the SQL Integrity Enhancement Facility supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsIntegrityEnhancementFacility() throws SQLException {
        return false;
    }

    /**
     * Retrieves whether this database supports specifying a <code>LIKE</code>
     * escape clause.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsLikeEscapeClause() throws SQLException {
        // per "Programming ODBC for SQLServer" Appendix A
        return true;
    }

    /**
     * Retrieves whether this database provides limited support for outer
     * joins.  (This will be <code>true</code> if the method
     * <code>supportsFullOuterJoins</code> returns <code>true</code>).
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsLimitedOuterJoins() throws SQLException {
        return true;
    }

    /**
     * Retrieves whether this database supports the ODBC Minimum SQL grammar.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsMinimumSQLGrammar() throws SQLException {
        return true;
    }

    /**
     * Retrieves whether this database treats mixed case unquoted SQL identifiers as
     * case sensitive and as a result stores them in mixed case.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsMixedCaseIdentifiers() throws SQLException {
        setCaseSensitiveFlag();

        return caseSensitive.booleanValue();
    }

    /**
     * Retrieves whether this database treats mixed case quoted SQL identifiers as
     * case sensitive and as a result stores them in mixed case.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsMixedCaseQuotedIdentifiers() throws SQLException {
        setCaseSensitiveFlag();

        return caseSensitive.booleanValue();
    }

    /**
     * Are multiple ResultSets from a single execute supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsMultipleResultSets() throws SQLException {
        return true;
    }

    /**
     * Can we have multiple transactions open at once (on different
     * connections)?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsMultipleTransactions() throws SQLException {
        return true;
    }

    /**
     * Retrieves whether columns in this database may be defined as non-nullable.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsNonNullableColumns() throws SQLException {
        return true;
    }

    /**
     * Can cursors remain open across commits?
     *
     * @return <code>true</code> if cursors always remain open;
     *         <code>false</code> if they might not remain open
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsOpenCursorsAcrossCommit() throws SQLException {
        // MS JDBC says false
        return true;
    }

    /**
     * Can cursors remain open across rollbacks?
     *
     * @return <code>true</code> if cursors always remain open;
     *         <code>false</code> if they might not remain open
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsOpenCursorsAcrossRollback() throws SQLException {
        // JConnect says true
        return connection.getServerType() == Driver.SYBASE;
    }

    /**
     * Can statements remain open across commits?
     *
     * @return <code>true</code> if statements always remain open;
     *         <code>false</code> if they might not remain open
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsOpenStatementsAcrossCommit() throws SQLException {
        return true;
    }

    /**
     * Can statements remain open across rollbacks?
     *
     * @return <code>true</code> if statements always remain open;
     *         <code>false</code> if they might not remain open
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsOpenStatementsAcrossRollback() throws SQLException {
        return true;
    }

    /**
     * Can an "ORDER BY" clause use columns not in the SELECT?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsOrderByUnrelated() throws SQLException {
        return true;
    }

    /**
     * Is some form of outer join supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsOuterJoins() throws SQLException {
        return true;
    }

    /**
     * Is positioned DELETE supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsPositionedDelete() throws SQLException {
        return true;
    }

    /**
     * Is positioned UPDATE supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsPositionedUpdate() throws SQLException {
        return true;
    }

    /**
     * Can a schema name be used in a data manipulation statement?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsSchemasInDataManipulation() throws SQLException {
        return true;
    }

    /**
     * Can a schema name be used in an index definition statement?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsSchemasInIndexDefinitions() throws SQLException {
        return true;
    }

    /**
     * Can a schema name be used in a privilege definition statement?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsSchemasInPrivilegeDefinitions() throws SQLException {
        return true;
    }

    /**
     * Can a schema name be used in a procedure call statement?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsSchemasInProcedureCalls() throws SQLException {
        return true;
    }

    /**
     * Can a schema name be used in a table definition statement?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsSchemasInTableDefinitions() throws SQLException {
        return true;
    }

    /**
     * Is SELECT for UPDATE supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsSelectForUpdate() throws SQLException {
        // XXX Server supports it driver doesn't currently
        // As far as I know the SQL Server FOR UPDATE is not the same as the
        // standard SQL FOR UPDATE
        return false;
    }

    /**
     * Are stored procedure calls using the stored procedure escape syntax
     * supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsStoredProcedures() throws SQLException {
        return true;
    }

    /**
     * Retrieves whether this database supports subqueries in comparison
     * expressions.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsSubqueriesInComparisons() throws SQLException {
        return true;
    }

    /**
     * Retrieves whether this database supports subqueries in
     * <code>EXISTS</code> expressions.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsSubqueriesInExists() throws SQLException {
        return true;
    }

    /**
     * Retrieves whether this database supports subqueries in
     * <code>IN</code> statements.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsSubqueriesInIns() throws SQLException {
        return true;
    }

    /**
     * Retrieves whether this database supports subqueries in quantified
     * expressions.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsSubqueriesInQuantifieds() throws SQLException {
        return true;
    }

    /**
     * Retrieves whether this database supports table correlation names.
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsTableCorrelationNames() throws SQLException {
        return true;
    }

    /**
     * Does the database support the given transaction isolation level?
     *
     * @param level the values are defined in java.sql.Connection
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     *
     * @see Connection
     */
    public boolean supportsTransactionIsolationLevel(int level)
    throws SQLException {
        switch (level) {
            case Connection.TRANSACTION_READ_UNCOMMITTED:
            case Connection.TRANSACTION_READ_COMMITTED:
            case Connection.TRANSACTION_REPEATABLE_READ:
            case Connection.TRANSACTION_SERIALIZABLE:
                return true;

            // TRANSACTION_NONE not supported. It means there is no support for
            // transactions
            case Connection.TRANSACTION_NONE:
            default:
                return false;
        }
    }

    /**
     * Retrieves whether this database supports transactions. If not, invoking the
     * method <code>commit</code> is a noop, and the isolation level is
     * <code>TRANSACTION_NONE</code>.
     *
     * @return <code>true</code> if transactions are supported
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsTransactions() throws SQLException {
        return true;
    }

    /**
     * Is SQL UNION supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsUnion() throws SQLException {
        return true;
    }

    /**
     * Is SQL UNION ALL supported?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean supportsUnionAll() throws SQLException {
        return true;
    }

    /**
     * Does the database use a file for each table?
     *
     * @return <code>true</code> if the database uses a local file for each
     *         table
     * @throws SQLException if a database-access error occurs.
     */
    public boolean usesLocalFilePerTable() throws SQLException {
        return false;
    }

    /**
     * Does the database store tables in a local file?
     *
     * @return <code>true</code> if so
     * @throws SQLException if a database-access error occurs.
     */
    public boolean usesLocalFiles() throws SQLException {
        return false;
    }

    //--------------------------JDBC 2.0-----------------------------

    /**
     * Does the database support the given result set type?
     * <p/>
     * Supported types for SQL Server:
     * <table>
     *   <tr>
     *     <td valign="top">JDBC type</td>
     *     <td valign="top">SQL Server cursor type</td>
     *     <td valign="top">Server load</td>
     *     <td valign="top">Description</td>
     *   </tr>
     *   <tr>
     *     <td valign="top">TYPE_FORWARD_ONLY</td>
     *     <td valign="top">Forward-only, dynamic (fast forward-only, static with <code>useCursors=true</code>)</td>
     *     <td valign="top">Light</td>
     *     <td valign="top">Fast, will read all data (less fast, doesn't read all data with <code>useCursors=true</code>). Forward only.</td>
     *   </tr>
     *   <tr>
     *     <td valign="top">TYPE_SCROLL_INSENSITIVE</td>
     *     <td valign="top">Static cursor</td>
     *     <td valign="top">Heavy</td>
     *     <td valign="top">Only use with CONCUR_READ_ONLY. SQL Server generates a temporary table, so changes made by others are not visible. Scrollable.</td>
     *   </tr>
     *   <tr>
     *     <td valign="top">TYPE_SCROLL_SENSITIVE</td>
     *     <td valign="top">Keyset cursor</td>
     *     <td valign="top">Medium</td>
     *     <td valign="top">Others' updates or deletes visible, but not others' inserts. Scrollable.</td>
     *   </tr>
     *   <tr>
     *     <td valign="top">TYPE_SCROLL_SENSITIVE + 1</td>
     *     <td valign="top">Dynamic cursor</td>
     *     <td valign="top">Heavy</td>
     *     <td valign="top">Others' updates, deletes and inserts visible. Scrollable.</td>
     *   </tr>
     * </table>
     *
     * @param type defined in <code>java.sql.ResultSet</code>
     * @return <code>true</code> if so; <code>false</code> otherwise
     * @throws SQLException if a database access error occurs
     *
     * @see Connection
     * @see #supportsResultSetConcurrency
     */
    public boolean supportsResultSetType(int type) throws SQLException {
        // jTDS supports all standard ResultSet types plus
        // TYPE_SCROLL_SENSITIVE + 1
        return type >= ResultSet.TYPE_FORWARD_ONLY
                && type <= ResultSet.TYPE_SCROLL_SENSITIVE + 1;
    }

    /**
     * Does the database support the concurrency type in combination with the
     * given result set type?
     * <p/>
     * Supported concurrencies for SQL Server:
     * <table>
     *   <tr>
     *     <td>JDBC concurrency</td>
     *     <td>SQL Server concurrency</td>
     *     <td>Row locks</td>
     *     <td>Description</td>
     *   </tr>
     *   <tr>
     *     <td>CONCUR_READ_ONLY</td>
     *     <td>Read only</td>
     *     <td>No</td>
     *     <td>Read-only.</td>
     *   </tr>
     *   <tr>
     *     <td>CONCUR_UPDATABLE</td>
     *     <td>Optimistic concurrency, updatable</td>
     *     <td>No</td>
     *     <td>Row integrity checked with timestamp comparison or, when not available, value comparison (except text and image fields).</td>
     *   </tr>
     *   <tr>
     *     <td>CONCUR_UPDATABLE+1</td>
     *     <td>Pessimistic concurrency, updatable</td>
     *     <td>Yes</td>
     *     <td>Row integrity is ensured by locking rows.</td>
     *   </tr>
     *   <tr>
     *     <td>CONCUR_UPDATABLE+2</td>
     *     <td>Optimistic concurrency, updatable</td>
     *     <td>No</td>
     *     <td>Row integrity checked with value comparison (except text and image fields).</td>
     *   </tr>
     * </table>
     *
     * @param type defined in <code>java.sql.ResultSet</code>
     * @param concurrency type defined in <code>java.sql.ResultSet</code>
     * @return <code>true</code> if so; <code>false</code> otherwise
     * @throws SQLException if a database access error occurs
     *
     * @see Connection
     * @see #supportsResultSetType
     */
    public boolean supportsResultSetConcurrency(int type, int concurrency)
            throws SQLException {
        // jTDS supports both all standard ResultSet concurencies plus
        // CONCUR_UPDATABLE + 1 and CONCUR_UPDATABLE + 2, except the
        // TYPE_SCROLL_INSENSITIVE/CONCUR_UPDATABLE combination on SQL Server
        if (!supportsResultSetType(type)) {
            return false;
        }

        if (concurrency < ResultSet.CONCUR_READ_ONLY
                || concurrency > ResultSet.CONCUR_UPDATABLE + 2) {
            return false;
        }

        return type != ResultSet.TYPE_SCROLL_INSENSITIVE
                || concurrency == ResultSet.CONCUR_READ_ONLY;
    }

    /**
     * JDBC 2.0 Indicates whether a result set's own updates are visible.
     *
     * @param type <code>ResultSet</code> type
     * @return <code>true</code> if updates are visible for the
     *         result set type; <code>false</code> otherwise
     * @throws SQLException if a database access error occurs
     */
    public boolean ownUpdatesAreVisible(int type) throws SQLException {
        return true;
    }

    /**
     * JDBC 2.0 Indicates whether a result set's own deletes are visible.
     *
     * @param type <code>ResultSet</code> type
     * @return <code>true</code> if deletes are visible for the
     *         result set type; <code>false</code> otherwise
     * @throws SQLException if a database access error occurs
     */
    public boolean ownDeletesAreVisible(int type) throws SQLException {
        return true;
    }

    /**
     * JDBC 2.0 Indicates whether a result set's own inserts are visible.
     *
     * @param type <code>ResultSet</code> type
     * @return <code>true</code> if inserts are visible for the
     *         result set type; <code>false</code> otherwise
     * @throws SQLException if a database access error occurs
     */
    public boolean ownInsertsAreVisible(int type) throws SQLException {
        return true;
    }

    /**
     * JDBC 2.0 Indicates whether updates made by others are visible.
     *
     * @param type <code>ResultSet</code> type
     * @return <code>true</code> if updates made by others are
     *         visible for the result set type; <code>false</code> otherwise
     * @throws SQLException if a database access error occurs
     */
    public boolean othersUpdatesAreVisible(int type) throws SQLException {
        // Updates are visibile in scroll sensitive ResultSets
        return type >= ResultSet.TYPE_SCROLL_SENSITIVE;
    }

    /**
     * JDBC 2.0 Indicates whether deletes made by others are visible.
     *
     * @param type <code>ResultSet</code> type
     * @return <code>true</code> if deletes made by others are
     *         visible for the result set type; <code>false</code> otherwise
     * @throws SQLException if a database access error occurs
     */
    public boolean othersDeletesAreVisible(int type) throws SQLException {
        // Deletes are visibile in scroll sensitive ResultSets
        return type >= ResultSet.TYPE_SCROLL_SENSITIVE;
    }

    /**
     * JDBC 2.0 Indicates whether inserts made by others are visible.
     *
     * @param type <code>ResultSet</code> type
     * @return <code>true</code> if inserts made by others are visible
     *         for the result set type; <code>false</code> otherwise
     * @throws SQLException if a database access error occurs
     */
    public boolean othersInsertsAreVisible(int type) throws SQLException {
        // Inserts are only visibile with dynamic cursors
        return type == ResultSet.TYPE_SCROLL_SENSITIVE + 1;
    }

    /**
     * JDBC 2.0 Indicates whether or not a visible row update can be detected
     * by calling the method <code>ResultSet.rowUpdated</code> .
     *
     * @param type <code>ResultSet</code> type
     * @return <code>true</code> if changes are detected by the
     *         result set type; <code>false</code> otherwise
     * @throws SQLException if a database access error occurs
     */
    public boolean updatesAreDetected(int type) throws SQLException {
        // Seems like there's no support for this in SQL Server
        return false;
    }

    /**
     * JDBC 2.0 Indicates whether or not a visible row delete can be detected
     * by calling ResultSet.rowDeleted(). If deletesAreDetected() returns
     * false, then deleted rows are removed from the result set.
     *
     * @param type <code>ResultSet</code> type
     * @return <code>true</code> if changes are detected by the result set type
     * @throws SQLException if a database access error occurs
     */
    public boolean deletesAreDetected(int type) throws SQLException {
        return true;
    }

    /**
     * JDBC 2.0 Indicates whether or not a visible row insert can be detected
     * by calling ResultSet.rowInserted().
     *
     * @param type <code>ResultSet</code> type
     * @return <code>true</code> if changes are detected by the result set type
     * @throws SQLException if a database access error occurs
     */
    public boolean insertsAreDetected(int type) throws SQLException {
        // Seems like there's no support for this in SQL Server
        return false;
    }

    /**
     * JDBC 2.0 Indicates whether the driver supports batch updates.
     *
     * @return <code>true</code> if the driver supports batch updates;
     *         <code>false</code> otherwise
     * @throws SQLException if a database access error occurs
     */
    public boolean supportsBatchUpdates() throws SQLException {
        return true;
    }

    private void setCaseSensitiveFlag() throws SQLException {
        if (caseSensitive == null) {
            Statement s = connection.createStatement();
            ResultSet rs = s.executeQuery("sp_server_info 16");

            rs.next();

            caseSensitive = "MIXED".equalsIgnoreCase(rs.getString(3)) ?
                            Boolean.FALSE : Boolean.TRUE;
            s.close();
        }
    }

    public java.sql.ResultSet getAttributes(String catalog,
                                            String schemaPattern,
                                            String typeNamePattern,
                                            String attributeNamePattern)
            throws SQLException {
        String colNames[] = {"TYPE_CAT",        "TYPE_SCHEM",
                             "TYPE_NAME",       "ATTR_NAME",
                             "DATA_TYPE",       "ATTR_TYPE_NAME",
                             "ATTR_SIZE",       "DECIMAL_DIGITS",
                             "NUM_PREC_RADIX",  "NULLABLE",
                             "REMARKS",         "ATTR_DEF",
                             "SQL_DATA_TYPE",   "SQL_DATETIME_SUB",
                             "CHAR_OCTET_LENGTH","ORDINAL_POSITION",
                             "IS_NULLABLE",     "SCOPE_CATALOG",
                             "SCOPE_SCHEMA",    "SCOPE_TABLE",
                             "SOURCE_DATA_TYPE"};
        int colTypes[]    = {Types.VARCHAR,     Types.VARCHAR,
                             Types.VARCHAR,     Types.VARCHAR,
                             Types.INTEGER,     Types.VARCHAR,
                             Types.INTEGER,     Types.INTEGER,
                             Types.INTEGER,     Types.INTEGER,
                             Types.VARCHAR,     Types.VARCHAR,
                             Types.INTEGER,     Types.INTEGER,
                             Types.INTEGER,     Types.INTEGER,
                             Types.VARCHAR,     Types.VARCHAR,
                             Types.VARCHAR,     Types.VARCHAR,
                             Types.SMALLINT};
        //
        // Return an empty result set
        //
        JtdsStatement dummyStmt = (JtdsStatement) connection.createStatement();
        CachedResultSet rs = new CachedResultSet(dummyStmt, colNames, colTypes);
        rs.setConcurrency(ResultSet.CONCUR_READ_ONLY);

        return rs;
    }

    /**
     * Returns the database major version.
     */
    public int getDatabaseMajorVersion() throws SQLException {
        return connection.getDatabaseMajorVersion();
    }

    /**
     * Returns the database minor version.
     */
    public int getDatabaseMinorVersion() throws SQLException {
        return connection.getDatabaseMinorVersion();
    }

    /**
     * Returns the JDBC major version.
     */
    public int getJDBCMajorVersion() throws SQLException {
        return 3;
    }

    /**
     * Returns the JDBC minor version.
     */
    public int getJDBCMinorVersion() throws SQLException {
        return 0;
    }

    public int getResultSetHoldability() throws SQLException {
        return JtdsResultSet.HOLD_CURSORS_OVER_COMMIT;
    }

    public int getSQLStateType() throws SQLException {
        return sqlStateXOpen;
    }

    public java.sql.ResultSet getSuperTables(String catalog,
                                             String schemaPattern,
                                             String tableNamePattern)
            throws SQLException {
        String colNames[] = {"TABLE_CAT",   "TABLE_SCHEM",
                             "TABLE_NAME",  "SUPERTABLE_NAME"};
        int    colTypes[] = {Types.VARCHAR, Types.VARCHAR,
                             Types.VARCHAR, Types.VARCHAR};
        //
        // Return an empty result set
        //
        JtdsStatement dummyStmt = (JtdsStatement) connection.createStatement();
        CachedResultSet rs = new CachedResultSet(dummyStmt, colNames, colTypes);
        rs.setConcurrency(ResultSet.CONCUR_READ_ONLY);
        return rs;
    }

    public java.sql.ResultSet getSuperTypes(String catalog,
                                            String schemaPattern,
                                            String typeNamePattern)
            throws SQLException {
        String colNames[] = {"TYPE_CAT",        "TYPE_SCHEM",
                             "TYPE_NAME",       "SUPERTYPE_CAT",
                             "SUPERTYPE_SCHEM", "SUPERTYPE_NAME"};
        int    colTypes[] = {Types.VARCHAR,     Types.VARCHAR,
                             Types.VARCHAR,     Types.VARCHAR,
                             Types.VARCHAR,     Types.VARCHAR};
        //
        // Return an empty result set
        //
        JtdsStatement dummyStmt = (JtdsStatement) connection.createStatement();
        CachedResultSet rs = new CachedResultSet(dummyStmt, colNames, colTypes);
        rs.setConcurrency(ResultSet.CONCUR_READ_ONLY);
        return rs;
    }

    /**
     * Returns <code>true</code> if updates are made to a copy of the LOB; returns
     * <code>false</code> if LOB updates are made directly to the database.
     * <p>
     * NOTE: Since SQL Server / Sybase do not support LOB locators as Oracle does (AFAIK);
     * this method always returns <code>true</code>.
     */
    public boolean locatorsUpdateCopy() throws SQLException {
        return true;
    }

    /**
     * Returns <code>true</code> if getting auto-generated keys is supported after a
     * statment is executed; returns <code>false</code> otherwise
     */
    public boolean supportsGetGeneratedKeys() throws SQLException {
        return true;
    }

    /**
     * Returns <code>true</code> if Callable statements can return multiple result sets;
     * returns <code>false</code> if they can only return one result set.
     */
    public boolean supportsMultipleOpenResults() throws SQLException {
        return true;
    }

    /**
     * Returns <code>true</code> if the database supports named parameters;
     * returns <code>false</code> if the database does not support named parameters.
     */
    public boolean supportsNamedParameters() throws SQLException {
        return true;
    }

    public boolean supportsResultSetHoldability(int param) throws SQLException {
        // Not really sure about this one!
        return false;
    }

    /**
     * Returns <code>true</code> if savepoints are supported; returns
     * <code>false</code> otherwise
     */
    public boolean supportsSavepoints() throws SQLException {
        return true;
    }

    /**
     * Returns <code>true</code> if the database supports statement pooling;
     * returns <code>false</code> otherwise.
     */
    public boolean supportsStatementPooling() throws SQLException {
        return true;
    }

    /**
     * Format the supplied search pattern to transform the escape \x into [x].
     *
     * @param pattern the pattern to tranform
     * @return the transformed pattern as a <code>String</code>
     */
    private static String processEscapes(String pattern) {
        final char escChar = '\\';

        if (pattern == null || pattern.indexOf(escChar) == -1) {
            return pattern;
        }

        int len = pattern.length();
        StringBuffer buf = new StringBuffer(len + 10);

        for (int i = 0; i < len; i++) {
            if (pattern.charAt(i) != escChar) {
                buf.append(pattern.charAt(i));
            } else if (i < len - 1) {
                buf.append('[');
                buf.append(pattern.charAt(++i));
                buf.append(']');
            } else {
                // Ignore final \
            }

        }

        return buf.toString();
    }

    /**
     * Format the supplied procedure call as a valid JDBC call escape.
     *
     * @param catalog the database name or null
     * @param call the stored procedure call to format
     * @return the formatted call escape as a <code>String</code>
     */
    private String syscall(String catalog, String call) {
        StringBuffer sql = new StringBuffer(30 + call.length());
        sql.append("{call ");
        if (catalog != null) {
            if (tdsVersion >= Driver.TDS70) {
                sql.append('[').append(catalog).append(']');
            } else {
                sql.append(catalog);
            }
            sql.append("..");
        }
        sql.append(call).append('}');
        return sql.toString();
    }

    /**
     * Uppercase all column names.
     * <p>
     * Sybase returns column names in lowecase while the JDBC standard suggests
     * they should be uppercase.
     *
     * @param results the result set to modify
     * @throws SQLException
     */
    private static void upperCaseColumnNames(JtdsResultSet results)
            throws SQLException {
        ResultSetMetaData rsmd = results.getMetaData();
        int cnt = rsmd.getColumnCount();

        for (int i = 1; i <= cnt; i++) {
            String name = rsmd.getColumnLabel(i);
            if (name != null && name.length() > 0) {
                results.setColLabel(i, name.toUpperCase());
            }
        }
    }

    private static CachedResultSet createTypeInfoResultSet(JtdsResultSet rs, boolean useLOBs) throws SQLException {
        CachedResultSet result = new CachedResultSet(rs, false);
        if (result.getMetaData().getColumnCount() > TypeInfo.NUM_COLS) {
            result.setColumnCount(TypeInfo.NUM_COLS);
        }
        result.setColLabel(3, "PRECISION");
        result.setColLabel(11, "FIXED_PREC_SCALE");
        upperCaseColumnNames(result);
        result.setConcurrency(ResultSet.CONCUR_UPDATABLE);
        result.moveToInsertRow();

        for (Iterator iter = getSortedTypes(rs, useLOBs).iterator(); iter.hasNext();) {
            TypeInfo ti = (TypeInfo) iter.next();
            ti.update(result);
            result.insertRow();
        }

        result.moveToCurrentRow();
        result.setConcurrency(ResultSet.CONCUR_READ_ONLY);

        return result;
    }

    private static Collection getSortedTypes(ResultSet rs, boolean useLOBs) throws SQLException {
        List types = new ArrayList(40);  // 40 should be enough capacity to hold all types

        while (rs.next()) {
            types.add(new TypeInfo(rs, useLOBs));
        }

        Collections.sort(types);

        return types;
    }

    /////// JDBC4 demarcation, do NOT put any JDBC3 code below this line ///////

    /* (non-Javadoc)
     * @see java.sql.DatabaseMetaData#autoCommitFailureClosesAllResultSets()
     */
    public boolean autoCommitFailureClosesAllResultSets() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.DatabaseMetaData#getClientInfoProperties()
     */
    public ResultSet getClientInfoProperties() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.DatabaseMetaData#getFunctionColumns(java.lang.String, java.lang.String, java.lang.String, java.lang.String)
     */
    public ResultSet getFunctionColumns(String catalog, String schemaPattern,
            String functionNamePattern, String columnNamePattern)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.DatabaseMetaData#getFunctions(java.lang.String, java.lang.String, java.lang.String)
     */
    public ResultSet getFunctions(String catalog, String schemaPattern,
            String functionNamePattern) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.DatabaseMetaData#getRowIdLifetime()
     */
    public RowIdLifetime getRowIdLifetime() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.DatabaseMetaData#getSchemas(java.lang.String, java.lang.String)
     */
    public ResultSet getSchemas(String catalog, String schemaPattern)
            throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.DatabaseMetaData#supportsStoredFunctionsUsingCallSyntax()
     */
    public boolean supportsStoredFunctionsUsingCallSyntax() throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Wrapper#isWrapperFor(java.lang.Class)
     */
    public boolean isWrapperFor(Class arg0) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Wrapper#unwrap(java.lang.Class)
     */
    public Object unwrap(Class arg0) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

}