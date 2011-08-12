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
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Tests for DatabaseMetaData.getTypeInfo().
 *
 * @author David Eaves
 * @version $Id: DatabaseMetaDataTypeInfoTest.java,v 1.1 2005-01-05 12:24:14 alin_sinpalean Exp $
 */
public class DatabaseMetaDataTypeInfoTest extends MetaDataTestCase {

    private ResultSet typeInfoRs = null;


    public DatabaseMetaDataTypeInfoTest(String testName) {
        super(testName);
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(DatabaseMetaDataTypeInfoTest.class);
    }

    public void setUp() throws Exception {
        super.setUp();
        typeInfoRs = con.getMetaData().getTypeInfo();
    }

    public void tearDown() throws Exception {
        typeInfoRs.close();
        super.tearDown();
    }

    /**
     * Check types ordered by data type.
     */
    public void testOrderedByDatatype() throws Exception {
        int lastType = Integer.MIN_VALUE;

        while (typeInfoRs.next()) {
            String name = typeInfoRs.getString("TYPE_NAME");
            int type = typeInfoRs.getInt("DATA_TYPE");
            assertTrue("type " + type + " (" + name + ") less than last type "
                    + lastType, type >= lastType);
            lastType = type;
        }
    }

    /**
     * Check that types with the same JDBC data type are ordered by closest
     * match to the standard JDBC type.
     */
    public void testOrderedByTypeMapping() throws Exception {
        List typeNames = getTypeNamesInOrder();

        int sqlVariantIndex = typeNames.indexOf("sql_variant");

        // Not all versions have sql_variant
        if (sqlVariantIndex != -1) {
            checkOrder(typeNames, "varchar", "sql_variant");
        }

        checkOrder(typeNames, "varchar", "nvarchar");
        checkOrder(typeNames, "varchar", "sysname");
        checkOrder(typeNames, "bigint", "bigint identity");
    }

    public void testColumnNames() throws Exception {
        assertTrue(checkColumnNames(typeInfoRs, new String[]{
            "TYPE_NAME", "DATA_TYPE", "PRECISION", "LITERAL_PREFIX",
            "LITERAL_SUFFIX", "CREATE_PARAMS", "NULLABLE", "CASE_SENSITIVE",
            "SEARCHABLE", "UNSIGNED_ATTRIBUTE", "FIXED_PREC_SCALE",
            "AUTO_INCREMENT", "LOCAL_TYPE_NAME", "MINIMUM_SCALE",
            "MAXIMUM_SCALE", "SQL_DATA_TYPE", "SQL_DATETIME_SUB",
            "NUM_PREC_RADIX"}));
    }

    public void testNvarcharNormalized() throws Exception {
        while (typeInfoRs.next()) {
            if (typeInfoRs.getString(1).equalsIgnoreCase("nvarchar")) {
                assertEquals(java.sql.Types.VARCHAR, typeInfoRs.getInt(2));
            }
        }
    }

    private void checkOrder(List typeNames, String firstTypeName, String secondTypeName) {
        int firstIndex = typeNames.indexOf(firstTypeName);
        int secondIndex = typeNames.indexOf(secondTypeName);
        assertTrue(secondTypeName + " (index " + secondIndex + ") not greater than " +
                firstTypeName + " (index " + firstIndex + ")",
                secondIndex > firstIndex);
    }

    private List getTypeNamesInOrder() throws SQLException {
        List typeNames = new ArrayList();

        while (typeInfoRs.next()) {
            typeNames.add(typeInfoRs.getString("TYPE_NAME"));
        }

        return typeNames;
    }
}
