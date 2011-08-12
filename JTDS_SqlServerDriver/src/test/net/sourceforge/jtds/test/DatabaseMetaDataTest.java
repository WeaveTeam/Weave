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

import java.sql.*;
import java.util.Properties;

/**
 * Test <code>DatabaseMetaData</code>.
 *
 * @version $Id: DatabaseMetaDataTest.java,v 1.17.2.5 2009-12-30 13:45:25 ickzon Exp $
 */
public class DatabaseMetaDataTest extends MetaDataTestCase {

    public DatabaseMetaDataTest(String name) {
        super(name);
    }

    /**
     * Test meta data functions that return boolean values.
     * @throws Exception
     */
    public void testBooleanOptions() throws Exception {
        DatabaseMetaData dbmd = con.getMetaData();
        assertFalse("dataDefinitionCausesTransactionCommit", dbmd.dataDefinitionCausesTransactionCommit());
        assertFalse("dataDefinitionIgnoredInTransactions", dbmd.dataDefinitionIgnoredInTransactions());
        assertTrue("deletesAreDetected", dbmd.deletesAreDetected(ResultSet.TYPE_FORWARD_ONLY));
        assertTrue("deletesAreDetected", dbmd.deletesAreDetected(ResultSet.TYPE_SCROLL_INSENSITIVE));
        assertFalse("doesMaxRowSizeIncludeBlobs", dbmd.doesMaxRowSizeIncludeBlobs());
        assertFalse("insertsAreDetected", dbmd.insertsAreDetected(ResultSet.TYPE_FORWARD_ONLY));
        assertFalse("insertsAreDetected", dbmd.insertsAreDetected(ResultSet.TYPE_SCROLL_INSENSITIVE));
        assertFalse("insertsAreDetected", dbmd.insertsAreDetected(ResultSet.TYPE_SCROLL_SENSITIVE));
        assertTrue("isCatalogAtStart", dbmd.isCatalogAtStart());
        assertFalse("isReadOnly", dbmd.isReadOnly());
        assertTrue("nullPlusNonNullIsNull", dbmd.nullPlusNonNullIsNull());
        assertFalse("nullsAreSortedAtEnd", dbmd.nullsAreSortedAtEnd());
        assertFalse("nullsAreSortedAtStart", dbmd.nullsAreSortedAtStart());
        assertFalse("nullsAreSortedHigh", dbmd.nullsAreSortedHigh());
        assertTrue("nullsAreSortedLow", dbmd.nullsAreSortedLow());
        assertFalse("othersDeletesAreVisible",dbmd.othersDeletesAreVisible(ResultSet.TYPE_SCROLL_INSENSITIVE));
        assertFalse("othersInsertsAreVisible",dbmd.othersInsertsAreVisible(ResultSet.TYPE_SCROLL_INSENSITIVE));
        assertFalse("othersInsertsAreVisible",dbmd.othersInsertsAreVisible(ResultSet.TYPE_SCROLL_SENSITIVE));
        assertTrue("othersInsertsAreVisible",dbmd.othersInsertsAreVisible(ResultSet.TYPE_SCROLL_SENSITIVE + 1));
        assertFalse("othersUpdatesAreVisible",dbmd.othersUpdatesAreVisible(ResultSet.TYPE_SCROLL_INSENSITIVE));
        assertTrue("othersUpdatesAreVisible",dbmd.othersUpdatesAreVisible(ResultSet.TYPE_SCROLL_SENSITIVE));
        assertTrue("ownInsertsAreVisible", dbmd.ownInsertsAreVisible(ResultSet.TYPE_FORWARD_ONLY));
        assertTrue("ownInsertsAreVisible", dbmd.ownInsertsAreVisible(ResultSet.TYPE_SCROLL_INSENSITIVE));
        assertTrue("ownInsertsAreVisible", dbmd.ownInsertsAreVisible(ResultSet.TYPE_SCROLL_SENSITIVE));
        assertTrue("ownUpdatesAreVisible", dbmd.ownUpdatesAreVisible(ResultSet.TYPE_SCROLL_INSENSITIVE));
        assertTrue("ownUpdatesAreVisible", dbmd.ownUpdatesAreVisible(ResultSet.TYPE_SCROLL_SENSITIVE));
        assertFalse("storesLowerCaseIdentifiers", dbmd.storesLowerCaseIdentifiers());
        assertFalse("storesLowerCaseQuotedIdentifiers", dbmd.storesLowerCaseQuotedIdentifiers());
        assertFalse("storesUpperCaseIdentifiers", dbmd.storesUpperCaseIdentifiers());
        assertFalse("storesUpperCaseQuotedIdentifiers", dbmd.storesUpperCaseQuotedIdentifiers());
        assertTrue("supportsAlterTableWithAddColumn", dbmd.supportsAlterTableWithAddColumn());
        assertTrue("supportsAlterTableWithDropColumn", dbmd.supportsAlterTableWithDropColumn());
        assertTrue("supportsANSI92EntryLevelSQL", dbmd.supportsANSI92EntryLevelSQL());
        assertFalse("supportsANSI92FullSQL", dbmd.supportsANSI92FullSQL());
        assertFalse("supportsANSI92IntermediateSQL", dbmd.supportsANSI92IntermediateSQL());
        assertTrue("supportsBatchUpdates", dbmd.supportsBatchUpdates());
        assertTrue("supportsCatalogsInDataManipulation", dbmd.supportsCatalogsInDataManipulation());
        assertTrue("supportsCatalogsInIndexDefinitions", dbmd.supportsCatalogsInIndexDefinitions());
        assertTrue("supportsCatalogsInProcedureCalls", dbmd.supportsCatalogsInProcedureCalls());
        assertTrue("supportsCatalogsInTableDefinitions", dbmd.supportsCatalogsInTableDefinitions());
        assertTrue("supportsColumnAliasing", dbmd.supportsColumnAliasing());
        assertTrue("supportsConvert", dbmd.supportsConvert());
        assertTrue("supportsCorrelatedSubqueries", dbmd.supportsCorrelatedSubqueries());
        assertTrue("supportsDataDefinitionAndDataManipulationTransactions", dbmd.supportsDataDefinitionAndDataManipulationTransactions());
        assertFalse("supportsDataManipulationTransactionsOnly", dbmd.supportsDataManipulationTransactionsOnly());
        assertFalse("supportsDifferentTableCorrelationNames", dbmd.supportsDifferentTableCorrelationNames());
        assertTrue("supportsExpressionsInOrderBy", dbmd.supportsExpressionsInOrderBy());
        assertFalse("supportsExtendedSQLGrammar", dbmd.supportsExtendedSQLGrammar());
        assertTrue("supportsGroupBy", dbmd.supportsGroupBy());
        assertTrue("supportsGroupByBeyondSelect", dbmd.supportsGroupByBeyondSelect());
        assertTrue("supportsGroupByUnrelated", dbmd.supportsGroupByUnrelated());
        assertTrue("supportsLimitedOuterJoins", dbmd.supportsLimitedOuterJoins());
        assertTrue("supportsMinimumSQLGrammar", dbmd.supportsMinimumSQLGrammar());
        assertTrue("supportsMultipleResultSets", dbmd.supportsMultipleResultSets());
        assertTrue("supportsMultipleTransactions", dbmd.supportsMultipleTransactions());
        assertTrue("supportsNonNullableColumns", dbmd.supportsNonNullableColumns());
        assertTrue("supportsOpenStatementsAcrossCommit", dbmd.supportsOpenStatementsAcrossCommit());
        assertTrue("supportsOpenStatementsAcrossRollback", dbmd.supportsOpenStatementsAcrossRollback());
        assertTrue("supportsOrderByUnrelated", dbmd.supportsOrderByUnrelated());
        assertTrue("supportsOuterJoins", dbmd.supportsOuterJoins());
        assertTrue("supportsResultSetConcurrency", dbmd.supportsResultSetConcurrency(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY));
        assertTrue("supportsResultSetConcurrency", dbmd.supportsResultSetConcurrency(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE));
        assertTrue("supportsResultSetConcurrency", dbmd.supportsResultSetConcurrency(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY));
        assertTrue("supportsResultSetConcurrency", dbmd.supportsResultSetConcurrency(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE + 1));
        assertTrue("supportsResultSetConcurrency", dbmd.supportsResultSetConcurrency(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE + 2));
        assertTrue("supportsResultSetType", dbmd.supportsResultSetType(ResultSet.TYPE_FORWARD_ONLY));
        assertTrue("supportsResultSetType", dbmd.supportsResultSetType(ResultSet.TYPE_SCROLL_INSENSITIVE));
        assertTrue("supportsResultSetType", dbmd.supportsResultSetType(ResultSet.TYPE_SCROLL_SENSITIVE));
        assertTrue("supportsResultSetType", dbmd.supportsResultSetType(ResultSet.TYPE_SCROLL_SENSITIVE + 1));
        assertTrue("supportsSchemasInDataManipulation", dbmd.supportsSchemasInDataManipulation());
        assertTrue("supportsSchemasInIndexDefinitions", dbmd.supportsSchemasInIndexDefinitions());
        assertTrue("supportsSchemasInProcedureCalls", dbmd.supportsSchemasInProcedureCalls());
        assertTrue("supportsSchemasInTableDefinitions", dbmd.supportsSchemasInTableDefinitions());
        assertTrue("supportsStoredProcedures", dbmd.supportsStoredProcedures());
        assertTrue("supportsSubqueriesInComparisons", dbmd.supportsSubqueriesInComparisons());
        assertTrue("supportsSubqueriesInExists", dbmd.supportsSubqueriesInExists());
        assertTrue("supportsSubqueriesInIns", dbmd.supportsSubqueriesInIns());
        assertTrue("supportsSubqueriesInQuantifieds", dbmd.supportsSubqueriesInQuantifieds());
        assertTrue("supportsTableCorrelationNames", dbmd.supportsTableCorrelationNames());
        assertTrue("supportsTransactionIsolationLevel", dbmd.supportsTransactionIsolationLevel(Connection.TRANSACTION_READ_COMMITTED));
        assertTrue("supportsTransactionIsolationLevel", dbmd.supportsTransactionIsolationLevel(Connection.TRANSACTION_READ_UNCOMMITTED));
        assertTrue("supportsTransactionIsolationLevel", dbmd.supportsTransactionIsolationLevel(Connection.TRANSACTION_SERIALIZABLE));
        assertTrue("supportsTransactions", dbmd.supportsTransactions());
        assertTrue("supportsUnion", dbmd.supportsUnion());
        assertTrue("supportsUnionAll", dbmd.supportsUnionAll());
        assertFalse("updatesAreDetected", dbmd.updatesAreDetected(ResultSet.TYPE_FORWARD_ONLY));
        assertFalse("updatesAreDetected", dbmd.updatesAreDetected(ResultSet.TYPE_SCROLL_INSENSITIVE));
        assertFalse("updatesAreDetected", dbmd.updatesAreDetected(ResultSet.TYPE_SCROLL_SENSITIVE));
        assertFalse("usesLocalFilePerTable", dbmd.usesLocalFilePerTable());
        assertFalse("usesLocalFiles", dbmd.usesLocalFiles());
        assertTrue("deletesAreDetected", dbmd.deletesAreDetected(ResultSet.TYPE_SCROLL_SENSITIVE));
        assertTrue("othersDeletesAreVisible",dbmd.othersDeletesAreVisible(ResultSet.TYPE_SCROLL_SENSITIVE));
        assertTrue("supportsResultSetConcurrency", dbmd.supportsResultSetConcurrency(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_READ_ONLY));
        assertTrue("supportsResultSetConcurrency", dbmd.supportsResultSetConcurrency(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE));
        assertTrue("allProceduresAreCallable", dbmd.allProceduresAreCallable());
        assertFalse("othersDeletesAreVisible",dbmd.othersDeletesAreVisible(ResultSet.TYPE_FORWARD_ONLY));
        assertFalse("othersInsertsAreVisible",dbmd.othersInsertsAreVisible(ResultSet.TYPE_FORWARD_ONLY));
        assertFalse("othersUpdatesAreVisible",dbmd.othersUpdatesAreVisible(ResultSet.TYPE_FORWARD_ONLY));
        assertTrue("ownUpdatesAreVisible", dbmd.ownUpdatesAreVisible(ResultSet.TYPE_FORWARD_ONLY));
        assertTrue("storesMixedCaseIdentifiers", dbmd.storesMixedCaseIdentifiers());
        assertTrue("storesMixedCaseQuotedIdentifiers", dbmd.storesMixedCaseQuotedIdentifiers());
        assertTrue("supportsCoreSQLGrammar", dbmd.supportsCoreSQLGrammar());
        assertFalse("supportsIntegrityEnhancementFacility", dbmd.supportsIntegrityEnhancementFacility());
        assertFalse("supportsMixedCaseIdentifiers", dbmd.supportsMixedCaseIdentifiers());
        assertFalse("supportsMixedCaseQuotedIdentifiers", dbmd.supportsMixedCaseQuotedIdentifiers());
        assertTrue("supportsPositionedDelete", dbmd.supportsPositionedDelete());
        assertTrue("supportsPositionedUpdate", dbmd.supportsPositionedUpdate());
        assertFalse("supportsResultSetConcurrency", dbmd.supportsResultSetConcurrency(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE));
        assertFalse("supportsResultSetConcurrency", dbmd.supportsResultSetConcurrency(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE + 1));
        assertFalse("supportsResultSetConcurrency", dbmd.supportsResultSetConcurrency(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE + 2));
        assertTrue("supportsSchemasInPrivilegeDefinitions", dbmd.supportsSchemasInPrivilegeDefinitions());
        assertFalse("supportsSelectForUpdate", dbmd.supportsSelectForUpdate());
        assertTrue("supportsTransactionIsolationLevel", dbmd.supportsTransactionIsolationLevel(Connection.TRANSACTION_REPEATABLE_READ));

        assertTrue("ownDeletesAreVisible", dbmd.ownDeletesAreVisible(ResultSet.TYPE_FORWARD_ONLY));
        assertTrue("ownDeletesAreVisible", dbmd.ownDeletesAreVisible(ResultSet.TYPE_SCROLL_INSENSITIVE));
        assertTrue("ownDeletesAreVisible", dbmd.ownDeletesAreVisible(ResultSet.TYPE_SCROLL_SENSITIVE));
        assertTrue("supportsCatalogsInPrivilegeDefinitions", dbmd.supportsCatalogsInPrivilegeDefinitions());
        assertTrue("supportsFullOuterJoins", dbmd.supportsFullOuterJoins());
        assertTrue("supportsLikeEscapeClause", dbmd.supportsLikeEscapeClause());
        assertTrue("supportsOpenCursorsAcrossCommit", dbmd.supportsOpenCursorsAcrossCommit());
        assertFalse("supportsTransactionIsolationLevel", dbmd.supportsTransactionIsolationLevel(Connection.TRANSACTION_NONE));

        if (dbmd.getDatabaseProductName().startsWith("Microsoft")) {
            assertTrue("allTablesAreSelectable", dbmd.allTablesAreSelectable());
            assertFalse("supportsOpenCursorsAcrossRollback", dbmd.supportsOpenCursorsAcrossRollback());
        } else {
            assertFalse("allTablesAreSelectable", dbmd.allTablesAreSelectable());
            assertTrue("supportsOpenCursorsAcrossRollback", dbmd.supportsOpenCursorsAcrossRollback());
        }
    }

    /**
     * Test meta data functions that return strings.
     * @throws Exception
     */
    public void testStringOptions() throws Exception {
        DatabaseMetaData dbmd = con.getMetaData();
        assertEquals("getCatalogSeparator", ".", dbmd.getCatalogSeparator());
        assertEquals("getCatalogTerm","database", dbmd.getCatalogTerm());
        assertNotNull("getDatabaseProductName", dbmd.getDatabaseProductName());
        assertNotNull("getDatabaseProductVersion", dbmd.getDatabaseProductVersion());
        assertNotNull("getDriverName", dbmd.getDriverName());
        assertNotNull("getDriverVersion", dbmd.getDriverVersion());
        assertEquals("getExtraNameCharacters","$#@", dbmd.getExtraNameCharacters());
        assertEquals("getIdentifierQuoteString","\"", dbmd.getIdentifierQuoteString());
        assertEquals("getNumericFunctions","abs,acos,asin,atan,atan2,ceiling,cos,cot,degrees,exp,floor,log,log10,mod,pi,power,radians,rand,round,sign,sin,sqrt,tan", dbmd.getNumericFunctions());
        assertEquals("getProcedureTerm","stored procedure", dbmd.getProcedureTerm());
        assertEquals("getSchemaTerm","owner", dbmd.getSchemaTerm());
        assertEquals("getSearchStringEscape","\\", dbmd.getSearchStringEscape());
        assertEquals("getSQLKeywords","ARITH_OVERFLOW,BREAK,BROWSE,BULK,CHAR_CONVERT,CHECKPOINT,CLUSTERED,COMPUTE,CONFIRM,CONTROLROW,DATA_PGS,DATABASE,DBCC,DISK,DUMMY,DUMP,ENDTRAN,ERRLVL,ERRORDATA,ERROREXIT,EXIT,FILLFACTOR,HOLDLOCK,IDENTITY_INSERT,IF,INDEX,KILL,LINENO,LOAD,MAX_ROWS_PER_PAGE,MIRROR,MIRROREXIT,NOHOLDLOCK,NONCLUSTERED,NUMERIC_TRUNCATION,OFF,OFFSETS,ONCE,ONLINE,OVER,PARTITION,PERM,PERMANENT,PLAN,PRINT,PROC,PROCESSEXIT,RAISERROR,READ,READTEXT,RECONFIGURE,REPLACE,RESERVED_PGS,RETURN,ROLE,ROWCNT,ROWCOUNT,RULE,SAVE,SETUSER,SHARED,SHUTDOWN,SOME,STATISTICS,STRIPE,SYB_IDENTITY,SYB_RESTREE,SYB_TERMINATE,TEMP,TEXTSIZE,TRAN,TRIGGER,TRUNCATE,TSEQUAL,UNPARTITION,USE,USED_PGS,USER_OPTION,WAITFOR,WHILE,WRITETEXT", dbmd.getSQLKeywords());
        assertEquals("getSystemFunctions","database,ifnull,user,convert", dbmd.getSystemFunctions());
        assertEquals("getTimeDateFunctions","curdate,curtime,dayname,dayofmonth,dayofweek,dayofyear,hour,minute,month,monthname,now,quarter,timestampadd,timestampdiff,second,week,year", dbmd.getTimeDateFunctions());
        assertNotNull("getURL", dbmd.getURL());
        assertNotNull("getUserName", dbmd.getUserName());
        if (dbmd.getDatabaseProductName().startsWith("Microsoft")) {
            assertEquals("getStringFunctions","ascii,char,concat,difference,insert,lcase,left,length,locate,ltrim,repeat,replace,right,rtrim,soundex,space,substring,ucase", dbmd.getStringFunctions());
        } else {
            assertEquals("getStringFunctions","ascii,char,concat,difference,insert,lcase,length,ltrim,repeat,right,rtrim,soundex,space,substring,ucase", dbmd.getStringFunctions());
        }
    }

    /**
     * Test meta data function that return integer values.
     * @throws Exception
     */
    public void testIntOptions() throws Exception {
        DatabaseMetaData dbmd = con.getMetaData();
        int sysnamelen = (dbmd.getDatabaseProductName().startsWith("Microsoft"))? 128: 30;
        assertEquals("getDefaultTransactionIsolation",Connection.TRANSACTION_READ_COMMITTED, dbmd.getDefaultTransactionIsolation());
        assertTrue("getDriverMajorVersion", dbmd.getDriverMajorVersion() >= 0);
        assertTrue("getDriverMinorVersion", dbmd.getDriverMinorVersion() >=0);
        assertEquals("getMaxBinaryLiteralLength", 131072, dbmd.getMaxBinaryLiteralLength());
        assertEquals("getMaxCatalogNameLength",sysnamelen, dbmd.getMaxCatalogNameLength());
        assertEquals("getMaxCharLiteralLength", 131072, dbmd.getMaxCharLiteralLength());
        assertEquals("getMaxColumnNameLength",sysnamelen, dbmd.getMaxColumnNameLength());
        assertEquals("getMaxColumnsInIndex",16, dbmd.getMaxColumnsInIndex());
        assertEquals("getMaxColumnsInSelect",4096, dbmd.getMaxColumnsInSelect());
        assertEquals("getMaxConnections",32767, dbmd.getMaxConnections());
        assertEquals("getMaxCursorNameLength",sysnamelen, dbmd.getMaxCursorNameLength());
        assertEquals("getMaxProcedureNameLength",sysnamelen, dbmd.getMaxProcedureNameLength());
        assertEquals("getMaxSchemaNameLength",sysnamelen, dbmd.getMaxSchemaNameLength());
        assertEquals("getMaxStatementLength",0, dbmd.getMaxStatementLength());
        assertEquals("getMaxStatements", 0, dbmd.getMaxStatements());
        assertEquals("getMaxTableNameLength",sysnamelen, dbmd.getMaxTableNameLength());
        assertEquals("getMaxUserNameLength",sysnamelen, dbmd.getMaxUserNameLength());
        if (dbmd.getDatabaseProductName().startsWith("Microsoft")) {
            assertEquals("getMaxColumnsInGroupBy",0, dbmd.getMaxColumnsInGroupBy());
            assertEquals("getMaxColumnsInOrderBy",0, dbmd.getMaxColumnsInOrderBy());
            assertEquals("getMaxColumnsInTable",1024, dbmd.getMaxColumnsInTable());
            assertEquals("getMaxIndexLength", 900, dbmd.getMaxIndexLength());
            assertEquals("getMaxRowSize",8060, dbmd.getMaxRowSize());
            assertEquals("getMaxTablesInSelect",256, dbmd.getMaxTablesInSelect());
        } else {
            assertEquals("getMaxColumnsInGroupBy",16, dbmd.getMaxColumnsInGroupBy());
            assertEquals("getMaxColumnsInOrderBy",16, dbmd.getMaxColumnsInOrderBy());
            assertEquals("getMaxColumnsInTable", 250, dbmd.getMaxColumnsInTable());
            assertEquals("getMaxIndexLength", 255, dbmd.getMaxIndexLength());
            assertEquals("getMaxRowSize",1962, dbmd.getMaxRowSize());
            assertEquals("getMaxTablesInSelect",16, dbmd.getMaxTablesInSelect());
        }
    }

    /**
     * Test meta data functions that return result sets.
     * @throws Exception
     */
    public void testResultSets() throws Exception
    {
        try {
            DatabaseMetaData dbmd = con.getMetaData();
            ResultSet rs;
            Statement stmt = con.createStatement();
            dropTable("jTDS_META2");
            dropTable("jTDS_META");
            dropProcedure("jtds_spmeta");
            //
            // Create test data
            //
            stmt.execute("CREATE PROC jtds_spmeta @p1 int, @p2 varchar(30) output AS SELECT @p2 = 'test'");
            stmt.execute("CREATE TABLE jTDS_META (id int NOT NULL primary key , data nvarchar(255) NULL, ts timestamp)");
            stmt.execute("CREATE TABLE jTDS_META2 (id int NOT NULL, data2 varchar(255) NULL "+
                            ",  FOREIGN KEY (id) REFERENCES jTDS_META(id)) ");
            //
            rs = dbmd.getBestRowIdentifier(null, null, "jTDS_META", DatabaseMetaData.bestRowUnknown, true);
            assertTrue(checkColumnNames(rs, new String[]{"SCOPE", "COLUMN_NAME", "DATA_TYPE",
                                                "TYPE_NAME", "COLUMN_SIZE", "BUFFER_LENGTH",
                                                "DECIMAL_DIGITS","PSEUDO_COLUMN"}));
            assertTrue(rs.next());
            assertEquals("id", rs.getString(2));
            //
            rs = dbmd.getCatalogs();
            assertTrue(checkColumnNames(rs, new String[]{"TABLE_CAT"}));
            boolean fail = true;
            while (rs.next()) {
                if (rs.getString(1).equalsIgnoreCase("master")) {
                    fail=false;
                    break;
                }
            }
            assertTrue(!fail);
            //
            rs = dbmd.getColumnPrivileges(null, null, "jTDS_META", "id");
            assertTrue(checkColumnNames(rs, new String[]{"TABLE_CAT","TABLE_SCHEM","TABLE_NAME",
                                        "COLUMN_NAME","GRANTOR","GRANTEE","PRIVILEGE","IS_GRANTABLE"}));
            assertTrue(rs.next());
            assertTrue(rs.getString(7).equals("INSERT") ||
                       rs.getString(7).equals("UPDATE") ||
                       rs.getString(7).equals("DELETE") ||
                       rs.getString(7).equals("SELECT"));
            //
            rs = dbmd.getColumns(null, null, "jTDS_META", "%");
            assertTrue(checkColumnNames(rs, new String[]{"TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME",
                    "COLUMN_NAME", "DATA_TYPE", "TYPE_NAME", "COLUMN_SIZE", "BUFFER_LENGTH",
                    "DECIMAL_DIGITS","NUM_PREC_RADIX", "NULLABLE","REMARKS","COLUMN_DEF",
                    "SQL_DATA_TYPE","SQL_DATETIME_SUB","CHAR_OCTET_LENGTH","ORDINAL_POSITION",
                    "IS_NULLABLE","SCOPE_CATALOG","SCOPE_SCHEMA","SCOPE_TABLE","SOURCE_DATA_TYPE"}));
            assertTrue(rs.next());
            assertEquals("id", rs.getString(4));
            assertEquals(java.sql.Types.INTEGER, rs.getInt(5));
            assertTrue(rs.next());
            assertEquals("data", rs.getString(4));
            assertEquals(java.sql.Types.VARCHAR, rs.getInt(5));
            //
            rs = dbmd.getCrossReference(null, null, "jTDS_META", null, null, "jTDS_META2");
            assertTrue(checkColumnNames(rs, new String[]{"PKTABLE_CAT", "PKTABLE_SCHEM", "PKTABLE_NAME","PKCOLUMN_NAME",
                    "FKTABLE_CAT", "FKTABLE_SCHEM", "FKTABLE_NAME","FKCOLUMN_NAME",
                    "KEY_SEQ","UPDATE_RULE","DELETE_RULE","FK_NAME","PK_NAME","DEFERRABILITY"}));
            assertTrue(rs.next());
            assertEquals("id", rs.getString(4));
            //
            rs = dbmd.getExportedKeys(null, null, "jTDS_META");
            assertTrue(checkColumnNames(rs, new String[]{"PKTABLE_CAT", "PKTABLE_SCHEM", "PKTABLE_NAME","PKCOLUMN_NAME",
                    "FKTABLE_CAT", "FKTABLE_SCHEM", "FKTABLE_NAME","FKCOLUMN_NAME",
                    "KEY_SEQ","UPDATE_RULE","DELETE_RULE","FK_NAME","PK_NAME","DEFERRABILITY"}));
            assertTrue(rs.next());
            assertEquals("id", rs.getString(4));
            //
            rs = dbmd.getImportedKeys(null, null, "jTDS_META2");
            assertTrue(checkColumnNames(rs, new String[]{"PKTABLE_CAT", "PKTABLE_SCHEM", "PKTABLE_NAME","PKCOLUMN_NAME",
                    "FKTABLE_CAT", "FKTABLE_SCHEM", "FKTABLE_NAME","FKCOLUMN_NAME",
                    "KEY_SEQ","UPDATE_RULE","DELETE_RULE","FK_NAME","PK_NAME","DEFERRABILITY"}));
            assertTrue(rs.next());
            assertEquals("id", rs.getString(4));
            //
            rs = dbmd.getIndexInfo(null, null, "jTDS_META", false, true);
            assertTrue(checkColumnNames(rs, new String[]{"TABLE_CAT","TABLE_SCHEM","TABLE_NAME","NON_UNIQUE",
                      "INDEX_QUALIFIER","INDEX_NAME","TYPE","ORDINAL_POSITION", "COLUMN_NAME",
                      "ASC_OR_DESC","CARDINALITY","PAGES","FILTER_CONDITION"}));
            assertTrue(rs.next());
            assertEquals("jTDS_META", rs.getString(3));
            //
            rs = dbmd.getPrimaryKeys(null, null, "jTDS_META");
            assertTrue(checkColumnNames(rs, new String[]{"TABLE_CAT","TABLE_SCHEM","TABLE_NAME","COLUMN_NAME","KEY_SEQ", "PK_NAME"}));
            assertTrue(rs.next());
            assertEquals("id", rs.getString(4));
            //
            rs = dbmd.getProcedureColumns(null, null, "jtds_spmeta", "@p1");
            assertTrue(checkColumnNames(rs, new String[]{"PROCEDURE_CAT", "PROCEDURE_SCHEM", "PROCEDURE_NAME",
                    "COLUMN_NAME", "COLUMN_TYPE","DATA_TYPE","TYPE_NAME","PRECISION",
                    "LENGTH","SCALE","RADIX","NULLABLE","REMARKS"}));
            assertTrue(rs.next());
            assertEquals("jtds_spmeta", rs.getString(3));
            assertEquals("@p1", rs.getString(4));
            //
            rs = dbmd.getProcedures(null, null, "jtds_spmeta%");
            assertTrue(checkColumnNames(rs, new String[]{"PROCEDURE_CAT", "PROCEDURE_SCHEM", "PROCEDURE_NAME",
                    "","","","REMARKS","PROCEDURE_TYPE"}));
            assertTrue(rs.next());
            assertEquals("jtds_spmeta", rs.getString(3));
            //
            rs = dbmd.getSchemas();
            if (net.sourceforge.jtds.jdbc.Driver.JDBC3) {
                assertTrue(checkColumnNames(rs, new String[]{"TABLE_SCHEM","TABLE_CATALOG"}));
            } else {
                assertTrue(checkColumnNames(rs, new String[]{"TABLE_SCHEM"}));
            }
            assertTrue(rs.next());
            //
            rs = dbmd.getTablePrivileges(null, null, "jTDS_META");
            assertTrue(checkColumnNames(rs, new String[]{"TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME",
                        "GRANTOR", "GRANTEE","PRIVILEGE", "IS_GRANTABLE"}));
            assertTrue(rs.next());
            assertTrue(rs.getString(6).equals("INSERT") ||
                       rs.getString(6).equals("UPDATE") ||
                       rs.getString(6).equals("DELETE") ||
                       rs.getString(6).equals("SELECT"));
            //
            rs = dbmd.getTables(null, null, "jTDS_META", new String[]{"TABLE"});
            assertTrue(checkColumnNames(rs, new String[]{"TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME",
                    "TABLE_TYPE","REMARKS","TYPE_CAT","TYPE_SCHEM","TYPE_NAME",
                    "SELF_REFERENCING_COL_NAME","REF_GENERATION"}));
            assertTrue(rs.next());
            assertEquals("jTDS_META", rs.getString(3));
            //
            rs = dbmd.getTableTypes();
            assertTrue(checkColumnNames(rs, new String[]{"TABLE_TYPE"}));
            assertTrue(rs.next());
            assertEquals("SYSTEM TABLE", rs.getString(1));
            //
            rs = dbmd.getTypeInfo();
            assertTrue(checkColumnNames(rs, new String[]{"TYPE_NAME","DATA_TYPE","PRECISION","LITERAL_PREFIX",
                    "LITERAL_SUFFIX", "CREATE_PARAMS","NULLABLE","CASE_SENSITIVE","SEARCHABLE",
                    "UNSIGNED_ATTRIBUTE","FIXED_PREC_SCALE","AUTO_INCREMENT","LOCAL_TYPE_NAME",
                    "MINIMUM_SCALE","MAXIMUM_SCALE","SQL_DATA_TYPE","SQL_DATETIME_SUB","NUM_PREC_RADIX"}));
            while (rs.next()) {
                if (rs.getString(1).equalsIgnoreCase("nvarchar")) {
                    assertEquals(java.sql.Types.VARCHAR, rs.getInt(2));
                }
            }
            //
            rs = dbmd.getUDTs(null, null, "%", null);
            assertTrue(checkColumnNames(rs, new String[]{"TYPE_CAT", "TYPE_SCHEM", "TYPE_NAME", "CLASS_NAME",
                    "DATA_TYPE","REMARKS","BASE_TYPE"}));
            assertFalse(rs.next());
            //
            rs = dbmd.getVersionColumns(null, null, "jTDS_META");
            assertTrue(checkColumnNames(rs, new String[]{"SCOPE", "COLUMN_NAME","DATA_TYPE","TYPE_NAME",
                      "COLUMN_SIZE","BUFFER_LENGTH","DECIMAL_DIGITS","PSEUDO_COLUMN"}));
            assertTrue(rs.next());
            assertEquals("ts", rs.getString(2));
        } finally {
            dropTable("jTDS_META2");
            dropTable("jTDS_META");
            dropProcedure("jtds_spmeta");
        }
    }

    /**
     * Test for bug [974036] Bug in 0.8rc1 DatabaseMetaData method getTableTypes()
     */
    public void testGetTableTypesOrder() throws Exception {
        DatabaseMetaData dmd = con.getMetaData();
        ResultSet rs = dmd.getTableTypes();
        String previousType = "";

        while (rs.next()) {
            String type = rs.getString(1);

            assertTrue(type.compareTo(previousType) >= 0);
            previousType = type;
        }

        rs.close();
    }

    /**
     * Test for bug [998765] Exception with Sybase and metaData.getTables()
     */
    public void testGetTables() throws Exception {
        DatabaseMetaData dmd = con.getMetaData();
        ResultSet rs = dmd.getTables(null, null, null, null);

        assertNotNull(rs);

        rs.close();
    }

    /**
     * Test for bug [1120168] jTDS 101 - TDS data type 0 invalid.
     */
    public void testGetColumnsMetaData() throws Exception {
        DatabaseMetaData dmd = con.getMetaData();
        ResultSet rs = dmd.getColumns(null, null, "Table doesn't exist", null);

        assertNotNull(rs);

        // Obtain the ResultSetMetaData for the dummy CachedResultSet
        ResultSetMetaData rsmd = rs.getMetaData();

        // Now call all methods and make sure they don't crash
        // For some of them also make simple tests
        assertNotNull(rsmd.getCatalogName(1));
        assertNotNull(rsmd.getColumnClassName(1));
        rsmd.getColumnCount();
        assertTrue(0 != rsmd.getColumnDisplaySize(1));
        assertNotNull(rsmd.getColumnLabel(1));
        assertNotNull(rsmd.getColumnName(1));
        rsmd.getColumnType(1);
        assertNotNull(rsmd.getColumnTypeName(1));
        rsmd.getPrecision(1);
        rsmd.getScale(1);
        assertNotNull(rsmd.getSchemaName(1));
        assertNotNull(rsmd.getTableName(1));
        rsmd.isAutoIncrement(1);
        rsmd.isCaseSensitive(1);
        rsmd.isCurrency(1);
        rsmd.isDefinitelyWritable(1);
        rsmd.isNullable(1);
        rsmd.isReadOnly(1);
        rsmd.isSearchable(1);
        rsmd.isSigned(1);
        rsmd.isWritable(1);

        rs.close();
    }

    /**
     * Test for bug [1023984] Protocol error processing table meta data.
     * <p>
     * Test to demonstrate failure to process the TDS table name token
     * correctly. Must be run with TDS=8.0.
     * @throws Exception
     */
    public void testTableMetaData() throws Exception {
        // This test is supposed to select from a different database, in order to
        // force the server to return a fully qualified table name. Do not alter.
        Statement stmt = con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
        ResultSet rs = stmt.executeQuery("SELECT * FROM master.dbo.sysdatabases");

        assertNotNull(rs);
        ResultSetMetaData rsmd = rs.getMetaData();

        assertEquals("master", rsmd.getCatalogName(1));
        assertEquals("dbo", rsmd.getSchemaName(1));
        assertEquals("sysdatabases", rsmd.getTableName(1));

        stmt.close();
        rs.close();
    }

    public void testColumnClassName() throws SQLException {
        byte[] bytes = new byte[] {1, 2, 3};
        String uid = "colGuid char(38)";
        if (con.getMetaData().getDatabaseProductName().startsWith("Microsoft")) {
            uid = "colGuid UNIQUEIDENTIFIER";
        }
        // Create a table w/ pretty much all the possible types
        String tabdef = "CREATE TABLE #testColumnClassName("
                + "colByte TINYINT,"
                + "colShort SMALLINT,"
                + "colInt INTEGER,"
                + "colBigint DECIMAL(29,0),"
                + "colFloat REAL,"
                + "colDouble FLOAT,"
                + "colDecimal DECIMAL(29,10),"
                + "colBit BIT,"
                + "colByteArray VARBINARY(255),"
                + "colTimestamp DATETIME,"
                + "colBlob IMAGE,"
                + "colClob TEXT,"
                + "colString VARCHAR(255),"
                + uid
                + ")";
        Statement stmt = con.createStatement();
        stmt.executeUpdate(tabdef);

        // Insert a row into the table
        PreparedStatement pstmt = con.prepareStatement(
                "INSERT INTO #testColumnClassName ("
                + "colByte,colShort,colInt,colBigint,colFloat,colDouble,"
                + "colDecimal,colBit,colByteArray,colTimestamp,colBlob,colClob,"
                + "colString,colGuid) "
                + "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
        pstmt.setByte(1, (byte) 1);
        pstmt.setShort(2, (short) 2222);
        pstmt.setInt(3, 123456);
        pstmt.setInt(4, 123456);
        pstmt.setFloat(5, 0.111f);
        pstmt.setDouble(6, 0.111);
        pstmt.setDouble(7, 0.111111);
        pstmt.setBoolean(8, true);
        pstmt.setBytes(9, bytes);
        pstmt.setTimestamp(10, new Timestamp(System.currentTimeMillis()));
        pstmt.setBytes(11, bytes);
        pstmt.setString(12, "Test");
        pstmt.setString(13, "Test");
        pstmt.setString(14, "ebd558a0-0c68-11d9-9669-0800200c9a66");
        assertEquals("No row inserted", 1, pstmt.executeUpdate());
        pstmt.close();

        // Select the row and check that getColumnClassName matches the actual
        // class
        ResultSet rs = stmt.executeQuery("SELECT * FROM #testColumnClassName");
        assertTrue("No rows in ResultSet", rs.next());
        ResultSetMetaData meta = rs.getMetaData();
        for (int i=1; i<=meta.getColumnCount(); i++) {
            Object obj = rs.getObject(i);
            assertNotNull("Expecting non-null value", obj);
            String metaClass = meta.getColumnClassName(i);
            Class c;
            try {
                c = Class.forName(metaClass);
            } catch (ClassNotFoundException ex) {
                fail("Class returned by getColumnClassName() not found: " + metaClass);
                return;
            }
            if (!c.isAssignableFrom(obj.getClass())) {
                fail("getColumnClassName() returned " + metaClass + " but the actual class is "
                        + obj.getClass().getName());
            }
        }
        stmt.close();
    }
    /**
     * Test to check DatabaseMetaData.getColumns and ResultSetMetaData is equivalent.
     * This test also checks for bug [ 1074096 ] Incorrect data type determine on dataset meta data.
     * This is because getColumns will return a typename of timestamp which should now also be
     * returned by the result set meta data as well.
     * @throws Exception if an error condition occurs
     */
    public void testColumnMetaData() throws Exception {
        String sql = "CREATE TABLE jTDSTYPETEST (ti tinyint not null, si smallint, i int, bi bigint, " +
        " f float, r real, d decimal(28,10), n numeric(28,10), sm smallmoney, m money, " +
        "c char(10) not null, vc varchar(255), nc nchar(10) not null, nvc nvarchar(255), " +
        " txt text, ntxt ntext, b binary(8) not null, vb varbinary(8), img image, " +
        " dt datetime, sdt smalldatetime, bt bit not null, ts timestamp, sn sysname, "+
        " ui uniqueidentifier, sv sql_variant)";

        String sql7 = "CREATE TABLE jTDSTYPETEST (ti tinyint not null, si smallint, i int, " +
        " f float, r real, d decimal(28,10), n numeric(28,10), sm smallmoney, m money, " +
        "c char(10) not null, vc varchar(255), nc nchar(10) not null, nvc nvarchar(255), " +
        " txt text, ntxt ntext, b binary(8) not null, vb varbinary(8), img image, " +
        " dt datetime, sdt smalldatetime, bt bit not null, ts timestamp, sn sysname, "+
        " ui uniqueidentifier)";

        String sql65 = "CREATE TABLE jTDSTYPETEST (ti tinyint not null, si smallint, i int, " +
        " f float, r real, d decimal(28,10), n numeric(28,10), sm smallmoney, m money, " +
        "c char(10) not null, vc varchar(255), " +
        " txt text, b binary(8) not null, vb varbinary(8), img image, " +
        " dt datetime, sdt smalldatetime, bt bit not null, ts timestamp, sn sysname)";

        String sql125 = "CREATE TABLE jTDSTYPETEST (ti tinyint not null, si smallint, i int, " +
        " f float, r real, d decimal(28,10), n numeric(28,10), sm smallmoney, m money, " +
        "c char(10) not null, vc varchar(255), nc nchar(10) not null, nvc nvarchar(255), " +
        " txt text, b binary(8) not null, vb varbinary(8), img image, " +
        " dt datetime, sdt smalldatetime, bt bit not null, ts timestamp, sn sysname, "+
        " uc unichar(10), vuc univarchar(255), sydt date, syt time)";

        try {
            dropTable("jTDSTYPETEST");
            Statement stmt = con.createStatement();
            DatabaseMetaData dbmd = con.getMetaData();
            if (dbmd.getDatabaseProductName().startsWith("Microsoft")) {
                if (dbmd.getDatabaseProductVersion().startsWith("6.5"))
                    stmt.execute(sql65);
                else if (dbmd.getDatabaseProductVersion().startsWith("7"))
                    stmt.execute(sql7);
                else
                    stmt.execute(sql);
            } else {
                if (dbmd.getDatabaseProductVersion().startsWith("12"))
                    stmt.execute(sql125);
                else
                    stmt.execute(sql65);
            }
            ResultSetMetaData rsmd = stmt.executeQuery("SELECT * FROM jTDSTYPETEST").getMetaData();
            ResultSet rs = dbmd.getColumns(null, null, "jTDSTYPETEST", "%");
//            ResultSetMetaData rsmd2 = rs.getMetaData();
//            System.out.println();
            while (rs.next()) {
                String cn = rs.getString("COLUMN_NAME");
                int ord = rs.getInt("ORDINAL_POSITION");
                assertEquals(cn+" typename", rs.getString("TYPE_NAME"), rsmd.getColumnTypeName(ord));
                assertEquals(cn+" datatype", rs.getInt("DATA_TYPE"), rsmd.getColumnType(ord));
                if (rs.getInt("DATA_TYPE") != Types.REAL && rs.getInt("DATA_TYPE") != Types.DOUBLE) {
                    // Seems to be genuine disagreement between getColumns and metadata on float data!
                    assertEquals(cn+" precision", rs.getInt("COLUMN_SIZE"), rsmd.getPrecision(ord));
                }
                assertEquals(cn+" scale", rs.getInt("DECIMAL_DIGITS"), rsmd.getScale(ord));
                assertEquals(cn+" nullable", rs.getInt("NULLABLE"), rsmd.isNullable(ord));
            }
        } finally {
            dropTable("jTDSTYPETEST");
        }
    }

    /**
     * Test for bug [1833720], invalid table names for large result sets.
     */
    public void testResultSetMetadate() throws Exception {
        final int rows    = 1;
        final int tables  = 10;
        final int columns = 100;

        Statement st = con.createStatement();
        StringBuffer sb = new StringBuffer();

        try {
            // create tables
            for (int t=0; t < tables; t++) {
                sb.setLength(0);
                sb.append("create table #TABLE");
                sb.append(t);
                sb.append("(ID int primary key");
                for (int c=0; c < columns; c++) {
                    sb.append(",COLUMN");
                    sb.append(c);
                    sb.append(" int");
                }
                sb.append(")");
                st.execute(sb.toString());
            }

            // insert data
            for (int t=0; t < tables; t++) {
                sb.setLength(0);
                sb.append("insert into #TABLE");
                sb.append(t);
                sb.append(" values(?");
                for (int c=0; c < columns; c++) {
                    sb.append(",?");
                }
                sb.append(")");

                PreparedStatement pst = con.prepareStatement(sb.toString());
                for (int r = 0; r < rows; r++) {
                    for (int c=0; c <= columns; c++) {
                        pst.setInt(c + 1, r);
                    }
                    pst.addBatch();
                }
                assertEquals(rows, pst.executeBatch().length);
            }

            // create select
            sb.setLength(0);
            sb.append("select * from ");
            for (int t=0; t < tables; t++) {
                sb.append(t > 0 ? "," : "");
                sb.append("#TABLE");
                sb.append(t);
            }
            if (tables > 1) {
                sb.append(" where ");
                for (int t=1; t < tables; t++) {
                    sb.append(t > 1 ? " and " : "");
                    sb.append("#TABLE");
                    sb.append(t);
                    sb.append(".id=");
                    sb.append("#TABLE");
                    sb.append(t-1);
                    sb.append(".id");
                }
            }
    
            // get result
            ResultSet rs = st.executeQuery(sb.toString());
            ResultSetMetaData rsmd = rs.getMetaData();

            int toalColumns = rsmd.getColumnCount();
            assertEquals(tables * (columns + 1), toalColumns);

            for (int r=0; r < rows; r++) {
                assertTrue(rs.next());
            }

            int index = 0;
            for (int t=0; t < tables; t++) {
                for (int c = 1; c <= columns + 1; c++) {
                    index ++;

                    // FIXME: column names are transformed to upper case by jTDS, think that's an error
                    assertEquals(c > 1 ? ("COLUMN" + (c - 2)) : "ID", rsmd.getColumnName(index));

                    assertEquals(Types.INTEGER, rsmd.getColumnType(index));

                    // test for bug [1833720]
                    assertEquals("#TABLE" + t, rsmd.getTableName(index));
                }
            }
        } finally {
            for (int t=0; t < tables; t++) {
                dropTable("#TABLE" + t);
            }
        }
    }

    /**
     * Test for bug [1184376] Sybase getProcedureColumns bug
     */
    public void testProcedureColumns() throws Exception {
        try {
            dropProcedure("jtds_testparam");
            Statement stmt = con.createStatement();
            stmt.execute("CREATE PROC jtds_testparam @p1 int, @p2 int output as\r\n" +
                    "BEGIN\r\n" +
                    "  SELECT @p2 = @p1\r\n" +
                    "END");
            stmt.close();

            DatabaseMetaData dbmd = con.getMetaData();
            String[] columnPatterns = new String[] {null, "%"};
            for (int i = 0; i < columnPatterns.length; i++) {
                ResultSet rs = dbmd.getProcedureColumns(null, null,
                        "jtds_testparam", columnPatterns[i]);
                assertTrue(rs.next());
                assertEquals("@RETURN_VALUE", rs.getString("COLUMN_NAME"));
                assertEquals(DatabaseMetaData.procedureColumnReturn, rs.getInt("COLUMN_TYPE"));
                assertTrue(rs.next());
                assertEquals("@p1", rs.getString("COLUMN_NAME"));
                assertEquals(DatabaseMetaData.procedureColumnIn, rs.getInt("COLUMN_TYPE"));
                assertTrue(rs.next());
                assertEquals("@p2", rs.getString("COLUMN_NAME"));
                assertEquals(DatabaseMetaData.procedureColumnInOut, rs.getInt("COLUMN_TYPE"));
                rs.close();
            }
        } finally {
            dropProcedure("jtds_testparam");
        }
    }

    /**
     * Test for bug [1245775] Column type inconsistency when useLOBs=false.
     */
    public void testProcedureUseLOBsFalse() throws Exception {
        Properties props = new Properties();
        props.setProperty("useLOBs", "false");
        Connection con = getConnection(props);

        try {
            DatabaseMetaData meta = con.getMetaData();
            ResultSet rs = meta.getTypeInfo();
            while (rs.next()) {
                if ("text".equalsIgnoreCase(rs.getString(1))
                        || "ntext".equalsIgnoreCase(rs.getString(1))) {
                    assertEquals(Types.LONGVARCHAR, rs.getInt(2));
                } else if ("image".equalsIgnoreCase(rs.getString(1))) {
                    assertEquals(Types.LONGVARBINARY, rs.getInt(2));
                }
            }
        } finally {
            con.close();
        }

        DatabaseMetaData meta = this.con.getMetaData();
        ResultSet rs = meta.getTypeInfo();
        while (rs.next()) {
            if ("text".equalsIgnoreCase(rs.getString(1))
                    || "ntext".equalsIgnoreCase(rs.getString(1))) {
                assertEquals(Types.CLOB, rs.getInt(2));
            } else if ("image".equalsIgnoreCase(rs.getString(1))) {
                assertEquals(Types.BLOB, rs.getInt(2));
            }
        }

    }

    /**
     * Test for bug [1825743], default value not returned for column with
     * default value.
     */
    public void testDefaultValue() throws SQLException {
        Statement st = con.createStatement();

        // try dropping test table
        try {
            st.execute("drop TABLE testDefaultValue");
        } catch (SQLException e) {
            // ignored
        }

        String[] columns = new String[] {
                "tinyint",              "1",
                "smallint",             "2",
                "int",                  "3",
                "bigint",               "4",
                "float",                "5.0",
                "real",                 "6.0",
                "decimal(28,10)",       "0.1234567890",
                "numeric(28,10)",       "0.1234567890",
                "smallmoney",           "123.4567",
                "money",                "12345.6789",
                "bit",                  "false",
                "smalldatetime",        "1900-01-01 00:00:00.0",
                "datetime",             "1900-01-01 00:00:00.0",
                "char(10)",             "AaBbCcDdEe",
                "varchar(10)",          "FfGgHhIiJj",
                "nchar(10)",            "KkLlMmNnOo",
                "nvarchar(10)",         "PpQqRrSsTt",
//                "text",                 "CLOB",
//                "ntext",                "CLOB",
//                "image",                "BLOB",
//                "binary(10)",           "",
//                "varbinary(10)",        ""
        };

        // build and execute CREATE TABLE statement
        StringBuffer sb = new StringBuffer();
        sb.append("CREATE TABLE testDefaultValue (");
        for (int i = 0; i < columns.length/2; i++) {
            sb.append(i == 0 ? "" : ",");
            sb.append("col");
            sb.append(i);
            sb.append(" ");
            sb.append(columns[i*2]);
            sb.append(" default ");
            sb.append(i > 9 ? "'" : "");
            sb.append(columns[i*2+1]);
            sb.append(i > 9 ? "'" : "");
        }
        sb.append(")");
        st.execute(sb.toString());

        // check if meta data reports correct defaults
        ResultSet rs = con.getMetaData().getColumns(null, null, "testDefaultValue", "col%");
        for (int i = 0; i < columns.length/2; i++) {
            assertTrue(rs.next());
            assertNotNull(rs.getString("COLUMN_DEF"));
            assertTrue(rs.getString("COLUMN_DEF").indexOf(columns[i*2+1]) > 0);
        }
        rs.close();

        // test if the default values are being used
        assertEquals(1, st.executeUpdate("insert into testDefaultValue (col0) values (" + columns[1] + ")"));
        rs = st.executeQuery("select * from testDefaultValue");
        assertTrue(rs.next());
        for (int i = 0; i < columns.length/2; i++) {
            assertEquals(columns[i*2+1], rs.getObject(i+1).toString());
        }
        rs.close();

        st.close();
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(DatabaseMetaDataTest.class);
    }

}