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
package net.sourceforge.jtds.jdbc;

/**
 * Stores information about a cached stored procedure or statement handle.
 *
 * @version $Id: ProcEntry.java,v 1.1 2005-05-25 09:24:03 alin_sinpalean Exp $
 */
public class ProcEntry {
    /** The entry references a stored procedure. */
    public static final int PROCEDURE   = 1;
    /** The entry references a prepared statement handle. */
    public static final int PREPARE     = 2;
    /** The entry references a prepared cursor handle. */
    public static final int CURSOR      = 3;
    /** The entry references a failed prepare. */
    public static final int PREP_FAILED = 4;

    /** Stored procedure name or statement handle. */
    private String name;
    /** Column meta data (Sybase only). */
    private ColInfo[] colMetaData;
    /** Parameter meta data (Sybase only). */
    private ParamInfo[] paramMetaData;
    /** Type of statement referenced by this entry. */
    private int type;
    /** Usage count for this statement. */
    private int refCount;

    /**
     * Retrieves the procedure or handle name.
     *
     * @return the statement or handle name as a <code>String</code>
     */
    public final String toString() {
        return name;
    }

    /**
     * Sets the procedure name.
     *
     * @param name the procedure name
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Sets the prepared statement handle.
     *
     * @param handle the <code>sp_prepare</code> handle value
     */
    public void setHandle(int handle) {
        this.name = Integer.toString(handle);
    }

    /**
     * Retrieves the column meta data array.
     *
     * @return the column meta data as <code>ColInfo[]</code>
     */
    public ColInfo[] getColMetaData() {
        return this.colMetaData;
    }

    /**
     * Sets the column meta data.
     *
     * @param colMetaData the column meta data
     */
    public void setColMetaData(ColInfo[] colMetaData) {
        this.colMetaData = colMetaData;
    }

    /**
     * Retrieves the parameter meta data array.
     *
     * @return the parameter meta data as a <code>ParamInfo[]</code>
     */
    public ParamInfo[] getParamMetaData() {
        return this.paramMetaData;
    }

    /**
     * Sets the parameter meta data.
     *
     * @param paramMetaData the parameter meta data array
     */
    public void setParamMetaData(ParamInfo[] paramMetaData) {
        this.paramMetaData = paramMetaData;
    }

    /**
     * Sets the statement implementation type.
     *
     * @param type the type code (one of PROCEDURE,PREPARE,CURSOR)
     */
    public void setType(int type) {
        this.type = type;
    }

    /**
     * Retrieves the statement implementation type.
     *
     * @return the statement type as an <code>int</code>
     */
    public int getType() {
        return this.type;
    }

    /**
     * Retrieves the SQL to drop this statement.
     */
    public void appendDropSQL(StringBuffer sql) {
        switch (type) {
            case PROCEDURE:
                sql.append("DROP PROC ").append(name).append('\n');
                break;
            case PREPARE:
                sql.append("EXEC sp_unprepare ").append(name).append('\n');
                break;
            case CURSOR:
                sql.append("EXEC sp_cursorunprepare ").append(name).append('\n');
                break;
            case PREP_FAILED:
                break;
            default:
                throw new IllegalStateException("Invalid cached statement type " + type);
        }
    }

    /**
     * Increments the usage count.
     */
    public void addRef() {
        refCount++;
    }

    /**
     * Decrements the usage count.
     */
    public void release() {
        if (refCount > 0) {
            refCount--;
        }
    }

    /**
     * Retreives the usage count.
     *
     * @return the usage count as an <code>int</code>
     */
    public int getRefCount() {
        return refCount;
    }
}
