/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

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
