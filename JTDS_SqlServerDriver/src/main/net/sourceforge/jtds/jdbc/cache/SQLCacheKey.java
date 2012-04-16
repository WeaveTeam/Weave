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
package net.sourceforge.jtds.jdbc.cache;

import net.sourceforge.jtds.jdbc.ConnectionJDBC2;

/**
 * Cache key for an SQL query, consisting of the query and server type, major
 * and minor version.
 *
 * @author Brett Wooldridge
 * @author Alin Sinpalean
 * @version $Id: SQLCacheKey.java,v 1.2.2.1 2009-07-29 12:10:42 ickzon Exp $
 */
public class SQLCacheKey {
    private final String sql;
    private final int serverType;
    private final int majorVersion;
    private final int minorVersion;
    private final int hashCode;

    public SQLCacheKey(String sql, ConnectionJDBC2 connection) {
        this.sql = sql;
        this.serverType = connection.getServerType();
        this.majorVersion = connection.getDatabaseMajorVersion();
        this.minorVersion = connection.getDatabaseMinorVersion();

        this.hashCode = sql.hashCode()
                ^ (serverType << 24 | majorVersion << 16 | minorVersion);
    }

    public int hashCode() {
        return hashCode;
    }

    public boolean equals(Object object) {
        try {
            SQLCacheKey key = (SQLCacheKey) object;

            return this.hashCode == key.hashCode
                    && this.majorVersion == key.majorVersion
                    && this.minorVersion == key.minorVersion
                    && this.serverType == key.serverType
                    && this.sql.equals(key.sql);
        } catch (ClassCastException e) {
            return false;
        } catch (NullPointerException e) {
            return false;
        }
    }
}
