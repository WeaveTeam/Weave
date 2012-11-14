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
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.Vector;

import weave.config.ConnectionConfig;
import weave.utils.MyEntry;
import weave.utils.SQLUtils;


/**
 * @author Philip Kovac
 */
public class MetadataTable extends AbstractTable
{
	public static final String FIELD_ID = "entity_id";
	public static final String FIELD_PROPERTY = "property";
	public static final String FIELD_VALUE = "value";
	
	private static final Set<String> caseSensitiveFields = new HashSet<String>(Arrays.asList(FIELD_PROPERTY, FIELD_VALUE));
	
	private ManifestTable manifest = null;
	
	public MetadataTable(ConnectionConfig connectionConfig, String schemaName, String tableName, ManifestTable manifest) throws RemoteException
	{
		super(connectionConfig, schemaName, tableName);
		this.manifest = manifest;
		if (!tableExists())
			initTable();
	}
	protected void initTable() throws RemoteException
	{
		if (manifest == null)
			return;
		
		Connection conn;
		
		try
		{
			conn = connectionConfig.getAdminConnection();
			
			// primary key is (id,property) for indexing and because
			// we don't want duplicate properties for the same id
			SQLUtils.createTable(
				conn, schemaName, tableName,
				Arrays.asList(FIELD_ID, FIELD_PROPERTY, FIELD_VALUE),
				Arrays.asList(
					"BIGINT UNSIGNED",
					SQLUtils.getVarcharTypeString(conn, 256),
					SQLUtils.getVarcharTypeString(conn, 2048)
				),
				Arrays.asList(FIELD_ID, FIELD_PROPERTY)
			);
			
//			addForeignKey(FIELD_ID, manifest, ManifestTable.FIELD_ID);
		} 
		catch (SQLException e)
		{
			throw new RemoteException("Unable to initialize attribute-value-table.", e);
		}
		
		try
		{
//			/* Index of (id) */
//			SQLUtils.createIndex(
//					conn, schemaName, tableName,
//					tableName+FIELD_ID,
//					new String[]{FIELD_ID},
//					null
//			);
			/* Index of (Property, Value), important for finding ids with metadata criteria */
			SQLUtils.createIndex(
					conn, schemaName, tableName,
					tableName+FIELD_PROPERTY+FIELD_VALUE,
					new String[]{FIELD_PROPERTY, FIELD_VALUE},
					new Integer[]{32,32}
			);
		}
		catch (SQLException e)
		{
			System.out.println("WARNING: Failed to create index. This may happen if the table already exists.");
		}
	}
	/* TODO: Add optimized methods for adding/removing multiple entries. */
	/* if it is a null or empty string, it will simply unset the property. */
	public void setProperties(Integer id, Map<String,String> diff) throws RemoteException
	{
		try 
		{
			Connection conn = connectionConfig.getAdminConnection();
			
			List<Map<String,Object>> records = new Vector<Map<String,Object>>(diff.size());
			
			if (!connectionConfig.migrationPending())
			{
				for (String property : diff.keySet())
				{
					Map<String,Object> record = MyEntry.mapFromPairs(FIELD_ID, id, FIELD_PROPERTY, property);
					records.add(record);
				}
				SQLUtils.deleteRows(conn, schemaName, tableName, records, caseSensitiveFields, false);
			}
			
			records.clear();
			for (Entry<String,String> entry : diff.entrySet())
			{
				String value = entry.getValue();
				if (value != null && value.length() > 0)
				{
					Map<String,Object> record = MyEntry.mapFromPairs(
						FIELD_ID, id,
						FIELD_PROPERTY, entry.getKey(),
						FIELD_VALUE, value
					);
					records.add(record);
				}
			}
			SQLUtils.insertRows(conn, schemaName, tableName, records);
		} 
		catch (SQLException e)
		{
			throw new RemoteException("Unable to set property.", e);
		}
	}
	/* Nuke all entries for a given id */
	public void removeAllProperties(Integer id) throws RemoteException
	{
		try 
		{
			Connection conn = connectionConfig.getAdminConnection();
			SQLUtils.deleteRows(conn, schemaName, tableName, MyEntry.<String,Object>mapFromPairs(FIELD_ID, id), caseSensitiveFields, true);
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to clear properties for a given id.", e);
		}
	}
	public Map<Integer, String> getProperty(String property) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> params = new HashMap<String,Object>();
			Map<Integer,String> result = new HashMap<Integer,String>();
			params.put(FIELD_PROPERTY, property);
			List<Map<String,Object>> rows = SQLUtils.getRecordsFromQuery(conn, Arrays.asList(FIELD_ID, FIELD_VALUE), schemaName, tableName, params, Object.class, null, caseSensitiveFields);
			for (Map<String,Object> row : rows)
			{
				Number id = (Number)row.get(FIELD_ID);
				String value = (String)row.get(FIELD_VALUE);
				result.put(id.intValue(), value);
			}
			return result;
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to get all instances of a property.", e);
		}
	}
	public Map<Integer, Map<String,String>> getProperties(Collection<Integer> ids) throws RemoteException
	{
		try 
		{
			Connection conn = connectionConfig.getAdminConnection();
			return SQLUtils.idInSelect(conn, schemaName, tableName, FIELD_ID, FIELD_PROPERTY, FIELD_VALUE, ids, null);
		}   
		catch (SQLException e)
		{
			throw new RemoteException("Unable to get properties for a list of ids.", e);
		}
	}
	public Set<Integer> filter(Map<String,String> constraints) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			List<Map<String,String>> crossRowArgs = new Vector<Map<String,String>>(constraints.size());

			for (Entry<String,String> keyValPair : constraints.entrySet())
			{
				if (keyValPair.getKey() == null || keyValPair.getValue() == null)
					continue;
				Map<String,String> colValPair = new HashMap<String,String>();
				colValPair.put(FIELD_PROPERTY, keyValPair.getKey());
				colValPair.put(FIELD_VALUE, keyValPair.getValue());
				crossRowArgs.add(colValPair);
			}
			return new HashSet<Integer>(SQLUtils.crossRowSelect(conn, schemaName, tableName, FIELD_ID, crossRowArgs, caseSensitiveFields));
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to get ids given a set of property/value pairs.", e);
		}
	}
}
