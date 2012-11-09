/*
 * Weave (Web-based Analysis and Visualization Environment) Copyright (C) 2008-2011 University of Massachusetts Lowell This file is a part of Weave.
 * Weave is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License, Version 3, as published by the
 * Free Software Foundation. Weave is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the
 * GNU General Public License along with Weave. If not, see <http://www.gnu.org/licenses/>.
 */

package weave.config.tables;

import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.SQLException;

import weave.config.ConnectionConfig;
import weave.utils.SQLUtils;


/**
 * @author Philip Kovac
 */
public abstract class AbstractTable
{
    protected ConnectionConfig connectionConfig = null;
    protected String tableName = null;
    protected String schemaName = null;
    public AbstractTable(ConnectionConfig connectionConfig, String schemaName, String tableName) throws RemoteException
    {
        this.connectionConfig = connectionConfig;
        this.tableName = tableName;
        this.schemaName = schemaName;
        if (!tableExists())
        	initTable();
    }
    protected abstract void initTable() throws RemoteException;
    private boolean tableExists() throws RemoteException
    {
        try
        {
            Connection conn = connectionConfig.getAdminConnection();
            return SQLUtils.tableExists(conn, schemaName, tableName);
        }
        catch (SQLException e)
        {
            throw new RemoteException("Unable to determine whether table exists.", e);
        }
    }
}
