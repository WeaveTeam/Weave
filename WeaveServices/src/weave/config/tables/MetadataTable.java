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
import java.sql.PreparedStatement;
import java.sql.ResultSet;
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
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import weave.utils.SQLUtils.WhereClause;
import weave.utils.StringUtils;


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
			System.err.println("WARNING: Failed to create index. This may happen if the table already exists.");
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
	public Map<Integer, String> getPropertyMap(Collection<Integer> ids, String property) throws RemoteException
	{
		ResultSet rs = null;
		PreparedStatement stmt = null;
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<Integer,String> result = new HashMap<Integer,String>();
			
			// build query
			String quotedIdField = SQLUtils.quoteSymbol(conn, FIELD_ID);
			String query = String.format(
					"SELECT %s,%s FROM %s WHERE %s=?",
					quotedIdField,
					SQLUtils.quoteSymbol(conn, FIELD_VALUE),
					SQLUtils.quoteSchemaTable(conn, schemaName, tableName),
					SQLUtils.quoteSymbol(conn, FIELD_PROPERTY)
				);
			if (ids != null)
				query += String.format(" AND %s IN (%s)", quotedIdField, StringUtils.join(",", ids));
			
			// make query and get values
			stmt = SQLUtils.prepareStatement(conn, query, Arrays.asList(property));
			rs = stmt.executeQuery();
			rs.setFetchSize(SQLResult.FETCH_SIZE);
			while (rs.next())
				result.put(rs.getInt(FIELD_ID), rs.getString(FIELD_VALUE));
			
			return result;
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to get all instances of a property.", e);
		}
		finally
		{
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(stmt);
		}
	}
	public Map<Integer, Map<String,String>> getProperties(Collection<Integer> ids) throws RemoteException
	{
		PreparedStatement stmt = null;
		ResultSet rs = null;
		try
		{
			Map<Integer,Map<String,String>> result = MapUtils.fromPairs();
			
			if (ids.size() == 0)
				return result;
			
			for (int id : ids)
				result.put(id, new HashMap<String,String>());
			
			Connection conn = connectionConfig.getAdminConnection();
			String query = String.format(
					"SELECT * FROM %s WHERE %s IN (%s)",
					SQLUtils.quoteSchemaTable(conn, schemaName, tableName),
					SQLUtils.quoteSymbol(conn, FIELD_ID),
					StringUtils.join(",", ids)
				);
			stmt = conn.prepareStatement(query);
			rs = stmt.executeQuery();
			rs.setFetchSize(SQLResult.FETCH_SIZE);
			while (rs.next())
			{
				int id = rs.getInt(FIELD_ID);
				String property = rs.getString(FIELD_PROPERTY);
				String value = rs.getString(FIELD_VALUE);
				
				result.get(id).put(property, value);
			}
			
			return result;
		}   
		catch (SQLException e)
		{
			throw new RemoteException("Unable to retrieve metadata", e);
		}
		finally
		{
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(stmt);
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
