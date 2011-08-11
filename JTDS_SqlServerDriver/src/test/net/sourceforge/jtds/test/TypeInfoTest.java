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

import java.sql.Types;

import junit.framework.TestCase;

import net.sourceforge.jtds.jdbc.TypeInfo;

/**
 * Tests for the <code>TypeInfo</code> class.
 *
 * @author David Eaves
 * @version $Id: TypeInfoTest.java,v 1.1 2005-01-05 12:24:14 alin_sinpalean Exp $
 */
public class TypeInfoTest extends TestCase {

    public TypeInfoTest(String testName) {
        super(testName);
    }

    public void testCharTypes() {
        TypeInfo charType = new TypeInfo("char", Types.CHAR, false);
        // Following types are normalized to char
        TypeInfo nchar = new TypeInfo("nchar", -8, false);
        TypeInfo uniqueid = new TypeInfo("uniqueidentifier", -11, false);

        assertComparesLessThan(charType, nchar);
        assertComparesLessThan(nchar, uniqueid);
    }

    public void testVarcharTypes() {
        TypeInfo varchar = new TypeInfo("varchar", Types.VARCHAR, false);
        // Following types are normalized to varchar
        TypeInfo nvarchar = new TypeInfo("nvarchar", -9, false);
        TypeInfo sysname = new TypeInfo("sysname", -9, false);
        TypeInfo variant = new TypeInfo("sql_variant", -150, false);

        assertComparesLessThan(varchar, nvarchar);
        assertComparesLessThan(nvarchar, sysname);
        assertComparesLessThan(sysname, variant);
    }

    public void testCompareToDifferentDataType() {
        TypeInfo decimal = new TypeInfo("decimal", Types.DECIMAL /* 3 */, false);
        TypeInfo integer = new TypeInfo("integer", Types.INTEGER /* 4 */, false);

        assertComparesLessThan(decimal, integer);
    }

    public void testCompareToIdentity() {
        TypeInfo bigint = new TypeInfo("bigint", Types.BIGINT, false);
        TypeInfo bigintIdentity = new TypeInfo("bigint identity", Types.BIGINT, true);

        assertComparesLessThan(bigint, bigintIdentity);
    }

    private void assertComparesLessThan(TypeInfo t1, TypeInfo t2) {
        assertTrue(t1 + " < " + t2 + " failed", t1.compareTo(t2) < 0);
    }

    public static void main(String[] args) {
        junit.textui.TestRunner.run(TypeInfoTest.class);
    }
}
