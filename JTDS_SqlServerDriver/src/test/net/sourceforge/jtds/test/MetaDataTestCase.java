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
import java.sql.ResultSetMetaData;
import java.sql.SQLException;

/**
 * Base class for meta data test cases.
 *
 * @author David Eaves
 * @version $Id: MetaDataTestCase.java,v 1.1 2005-01-05 12:24:14 alin_sinpalean Exp $
 */
public abstract class MetaDataTestCase extends DatabaseTestCase {

    public MetaDataTestCase(String name) {
        super(name);
    }

    /**
     * Utility method to check column names and number.
     *
     * @param rs    the result set to check
     * @param names the list of column names to compare to result set
     * @return the <code>boolean</code> value true if the columns match
     */
    protected boolean checkColumnNames(ResultSet rs, String[] names)
            throws SQLException {
        ResultSetMetaData rsmd = rs.getMetaData();
        if (rsmd.getColumnCount() < names.length) {
            System.out.println("Cols=" + rsmd.getColumnCount());
            return false;
        }

        for (int i = 1; i <= names.length; i++) {
            if (names[i - 1].length() > 0
                    && !rsmd.getColumnLabel(i).equals(names[i - 1])) {
                System.out.println(
                        names[i - 1] + " = " + rsmd.getColumnLabel(i));
                return false;
            }
        }

        return true;
    }
}
