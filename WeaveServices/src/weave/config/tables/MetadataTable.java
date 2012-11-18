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
import weave.utils.MapUtils;
import weave.utils.SQLUtils;
import weave.utils.SQLUtils.WhereClause;


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
		super(connectionConfig, schemaName, tableName, FIELD_ID, FIELD_PROPERTY, FIELD_VALUE);
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
				Arrays.asList(fieldNames),
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
	public void setProperties(Integer id, Map<String,String> diff) throws RemoteException
	{
		try 
		{
			if (!connectionConfig.migrationPending())
			{
				Connection conn = connectionConfig.getAdminConnection();
				List<Map<String,Object>> records = new Vector<Map<String,Object>>(diff.size());
				for (String property : diff.keySet())
				{
					Map<String,Object> record = MapUtils.fromPairs(FIELD_ID, id, FIELD_PROPERTY, property);
					records.add(record);
				}
				WhereClause<Object> where = new WhereClause<Object>(conn, records, caseSensitiveFields, false);
				SQLUtils.deleteRows(conn, schemaName, tableName, where);
			}
			
			for (Entry<String,String> entry : diff.entrySet())
			{
				String value = entry.getValue();
				if (value != null && value.length() > 0)
					insertRecord(id, entry.getKey(), value);
			}
		} 
		catch (SQLException e)
		{
			throw new RemoteException("Unable to set property.", e);
		}
	}

	public void removeAllProperties(Integer id) throws RemoteException
	{
		try 
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> conditions = MapUtils.fromPairs(FIELD_ID, id);
			WhereClause<Object> where = new WhereClause<Object>(conn, conditions, caseSensitiveFields, true);
			SQLUtils.deleteRows(conn, schemaName, tableName, where);
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
			Map<Integer,String> result = new HashMap<Integer,String>();
			Map<String,Object> conditions = MapUtils.fromPairs(FIELD_PROPERTY, property);
			WhereClause<Object> where = new WhereClause<Object>(conn, conditions, caseSensitiveFields, true);
			List<Map<String,Object>> rows = SQLUtils.getRecordsFromQuery(conn, Arrays.asList(FIELD_ID, FIELD_VALUE), schemaName, tableName, where, null, Object.class);
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
			Map<Integer,Map<String,String>> result = MapUtils.fromPairs();
			
			Connection conn = connectionConfig.getAdminConnection();
			List<Map<String,Object>> conditions = new Vector<Map<String,Object>>(ids.size());
			for (int id : ids)
			{
				result.put(id, new HashMap<String,String>());
				conditions.add(MapUtils.<String,Object>fromPairs(FIELD_ID, id));
			}
			WhereClause<Object> where = new WhereClause<Object>(conn, conditions, null, false);
			
			for (Map<String,Object> record : SQLUtils.getRecordsFromQuery(conn, null, schemaName, tableName, where, null, Object.class))
			{
				int id = ((Number)record.get(FIELD_ID)).intValue();
				String property = (String)record.get(FIELD_PROPERTY);
				String value = (String)record.get(FIELD_VALUE);
				
				result.get(id).put(property, value);
			}
			
			return result;
		}   
		catch (SQLException e)
		{
			throw new RemoteException("Unable to retrieve metadata", e);
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
				Map<String,String> colValPair = MapUtils.fromPairs(
					FIELD_PROPERTY, keyValPair.getKey(),
					FIELD_VALUE, keyValPair.getValue()
				);
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
