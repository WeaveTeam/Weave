/*
	Weave (Web-based Analysis and Visualization Environment)
	Copyright (C) 2008-2011 University of Massachusetts Lowell

	This file is a part of Weave.

	Weave is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License, Version 3,
	as published by the Free Software Foundation.

	Weave is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.config.tables;

import java.rmi.RemoteException;
import java.security.InvalidParameterException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

import weave.config.ConnectionConfig;
import weave.utils.BulkSQLLoader;
import weave.utils.SQLUtils;


/**
 * @author Philip Kovac
 * @author Andy Dufilie
 */
public abstract class AbstractTable
{
	protected ConnectionConfig connectionConfig = null;
	protected String tableName = null;
	protected String schemaName = null;
	protected BulkSQLLoader bulkLoader = null;
	protected String[] fieldNames = null;
	
	public AbstractTable(ConnectionConfig connectionConfig, String schemaName, String tableName, String ... fieldNames) throws RemoteException
	{
		this.connectionConfig = connectionConfig;
		this.tableName = tableName;
		this.schemaName = schemaName;
		this.fieldNames = fieldNames;
	}
	protected boolean tableExists() throws RemoteException
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
	
	protected void addForeignKey(String localColumn, AbstractTable foreignTable, String foreignColumn) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			SQLUtils.addForeignKey(conn, schemaName, tableName, localColumn, foreignTable.tableName, foreignColumn);
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to add foreign key constraint", e);
		}
	}

	protected void insertRecord(Object ... values) throws RemoteException, SQLException
	{
		if (fieldNames.length != values.length)
		{
			Exception e = new InvalidParameterException("Number of fields does not match number of values");
			throw new RemoteException("Unable to insert record", e);
		}
		
		if (connectionConfig.migrationPending())
		{
			if (bulkLoader == null)
			{
				Connection conn = connectionConfig.getAdminConnection();
				bulkLoader = BulkSQLLoader.newInstance(conn, schemaName, tableName, fieldNames);
			}
			bulkLoader.addRow(values);
		}
		else
		{
			bulkLoader = null;
			
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> record = new HashMap<String,Object>(fieldNames.length);
			for (int i = 0; i < fieldNames.length; i++)
				record.put(fieldNames[i], values[i]);
			SQLUtils.insertRow(conn, schemaName, tableName, record);
		}
	}
	
    public void flushInserts() throws RemoteException, SQLException
    {
    	if (connectionConfig.migrationPending() && bulkLoader != null)
    		bulkLoader.flush();
    	else
    		bulkLoader = null;
    }
}
