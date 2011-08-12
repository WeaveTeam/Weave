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

import java.sql.Savepoint;
import java.sql.SQLException;

/**
 * Savepoint implementation class.
 *
 * @author Brian Heineman
 * @version $Id: SavepointImpl.java,v 1.5 2005-04-28 14:29:27 alin_sinpalean Exp $
 */
class SavepointImpl implements Savepoint {
    private final int id;
    private final String name;

    /**
     * Constructs a savepoint with a specific identifier.
     *
     * @param id a savepoint identifier
     */
    SavepointImpl(int id) {
        this(id, null);
    }

    /**
     * Constructs a savepoint with a specific identifier and name.
     *
     * @param id a savepoint identifier
     * @param name the savepoint name
     */
    SavepointImpl(int id, String name) {
        this.id = id;
        this.name = name;
    }

    public int getSavepointId() throws SQLException {
        if (name != null) {
            throw new SQLException(Messages.get("error.savepoint.named"), "HY024");
        }

        return id;
    }

    public String getSavepointName() throws SQLException {
        if (name == null) {
            throw new SQLException(Messages.get("error.savepoint.unnamed"), "HY024");
        }

        return name;
    }

    /**
     * Returns the savepoint id.  This will not throw an exception for
     * named savepoints as would {@link #getSavepointId}.
     *
     * @return the savepoint id
     */
    int getId() {
        return id;
    }
}

