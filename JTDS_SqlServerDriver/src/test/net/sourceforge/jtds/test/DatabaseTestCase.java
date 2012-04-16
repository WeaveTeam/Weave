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
import java.util.Map;
import java.math.BigDecimal;

/**
 * @author Alin Sinpalean
 * @version $Id: DatabaseTestCase.java,v 1.8.6.1 2009-08-04 10:33:54 ickzon Exp $
 */
public abstract class DatabaseTestCase extends TestBase {
    private static Map typemap = null;

    public DatabaseTestCase(String name) {
        super(name);
    }


    protected void dropTable(String tableName) throws SQLException {
        String sobName = "sysobjects";
        String tableLike = tableName;

        if (tableName.startsWith("#")) {
            sobName = "tempdb.dbo.sysobjects";
            tableLike = tableName + "%";
        }

        Statement stmt = con.createStatement();
        stmt.executeUpdate(
                          "if exists (select * from " + sobName + " where name like '" + tableLike + "' and type = 'U') "
                          + "drop table " + tableName);
        stmt.close();
    }

    protected void dropProcedure(String procname) throws SQLException {
        Statement stmt = con.createStatement();
        dropProcedure(stmt, procname);
        stmt.close();
    }

    protected void dropProcedure(Statement stmt, String procname) throws SQLException {
        String sobName = "sysobjects";
        if (procname.startsWith("#")) {
            sobName = "tempdb.dbo.sysobjects";
        }
        stmt.executeUpdate(
                          "if exists (select * from " + sobName + " where name like '" + procname + "%' and type = 'P') "
                          + "drop procedure " + procname);
    }

    protected void dropFunction(String procname) throws SQLException {
        String sobName = "sysobjects";
        Statement stmt = con.createStatement();
        stmt.executeUpdate(
                          "if exists (select * from " + sobName + " where name like '" + procname + "%' and type = 'FN') "
                          + "drop function " + procname);
        stmt.close();
    }

    // return -1 if a1<a2, 0 if a1==a2, 1 if a1>a2
    static int compareBytes(byte a1[], byte a2[]) {
        if (a1 == a2) {
            return 0;
        }

        if (a1 == null) {
            return -1;
        }

        if (a2 == null) {
            return 1;
        }

        int  length = (a1.length < a2.length ? a1.length : a2.length);

        for (int i = 0; i < length; i++) {
            if (a1[i] != a2[i]) {
                return((a1[i] & 0xff) > (a2[i] & 0xff) ? 1 : -1);
            }
        }

        if (a1.length == a2.length) {
            return 0;
        }

        if (a1.length < a2.length) {
            return -1;
        }

        return 1;
    }

    protected static Map getTypemap() {
        if (typemap != null) {
            return typemap;
        }

        Map map = new java.util.HashMap(15);
        map.put(BigDecimal.class,         new Integer(java.sql.Types.DECIMAL));
        map.put(Boolean.class,            new Integer(java.sql.Types.BIT));
        map.put(Byte.class,               new Integer(java.sql.Types.TINYINT));
        map.put(byte[].class,             new Integer(java.sql.Types.VARBINARY));
        map.put(java.sql.Date.class,      new Integer(java.sql.Types.DATE));
        map.put(double.class,             new Integer(java.sql.Types.DOUBLE));
        map.put(Double.class,             new Integer(java.sql.Types.DOUBLE));
        map.put(float.class,              new Integer(java.sql.Types.REAL));
        map.put(Float.class,              new Integer(java.sql.Types.REAL));
        map.put(Integer.class,            new Integer(java.sql.Types.INTEGER));
        map.put(Long.class,               new Integer(java.sql.Types.NUMERIC));
        map.put(Short.class,              new Integer(java.sql.Types.SMALLINT));
        map.put(String.class,             new Integer(java.sql.Types.VARCHAR));
        map.put(java.sql.Timestamp.class, new Integer(java.sql.Types.TIMESTAMP));

        typemap = map;
        return typemap;
    }

    protected static int getType(Object o) throws SQLException {
        if (o == null) {
            throw new SQLException("You must specify a type for a null parameter");
        }

        Map map = getTypemap();
        Object ot = map.get(o.getClass());

        if (ot == null) {
            throw new SQLException("Support for this type is not implemented");
        }

        return((Integer)ot).intValue();
    }

    protected String getLongString(int length) {
        StringBuffer result = new StringBuffer(length);

        for (int i = 0; i < length; i++) {
            result.append('a');
        }

        return result.toString();
    }

    protected String getLongString(char ch)  {
        StringBuffer str255 = new StringBuffer(255);

        for (int i = 0; i < 255; i++) {
            str255.append(ch);
        }

        return str255.toString();
    }
}
