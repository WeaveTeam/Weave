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
import java.util.List;
import java.util.Map;
import java.util.Vector;

import weave.config.ConnectionConfig;
import weave.config.DataConfig.DataEntity;
import weave.utils.MapUtils;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import weave.utils.SQLUtils.WhereClause;


/**
 * @author Philip Kovac
 */
public class ManifestTable extends AbstractTable
{
	public static final String FIELD_ID = "entity_id";
	public static final String FIELD_TYPE = "type_id";

    private int currentId = -1;
	public ManifestTable(ConnectionConfig connectionConfig, String schemaName, String tableName) throws RemoteException
	{
		super(connectionConfig, schemaName, tableName, FIELD_ID, FIELD_TYPE);
	}
	protected void initTable() throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			
			// primary key is entity_id for indexing and because we don't want duplicate ids
			SQLUtils.createTable(
				conn, schemaName, tableName,
				Arrays.asList(fieldNames),
				Arrays.asList(SQLUtils.getSerialPrimaryKeyTypeString(conn), "TINYINT UNSIGNED"),
				null
			);
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to initialize manifest table.", e);
		}
	}
	public Integer newEntry(int type_id) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
            if (!connectionConfig.migrationPending())
            {
			    return SQLUtils.insertRowReturnID(conn, schemaName, tableName, MapUtils.<String,Object>fromPairs(FIELD_TYPE, type_id));
            }
            else
            {
                if (currentId == -1)
                {
                    /* TODO: Find the current maximum ID number in the table. */
                    currentId = 1;
                }
                else
                {
                    currentId++;
                }
                insertRecord(currentId, type_id);
                return currentId; 
            }
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to add entry to manifest table.", e);
		}
	}
    
	public void removeEntry(int id) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> conditions = MapUtils.fromPairs(FIELD_ID, id);
			WhereClause<Object> where = new WhereClause<Object>(conn, conditions, null, true);
			SQLUtils.deleteRows(conn, schemaName, tableName, where);
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to remove entry from manifest table.", e);
		}
	}
	public int getEntryType(int id) throws RemoteException
	{
		Integer type = getEntryTypes(Arrays.asList(id)).get(id);
		return type == null ? DataEntity.TYPE_UNSPECIFIED: type;
	}
	public Map<Integer,Integer> getEntryTypes(Collection<Integer> ids) throws RemoteException
	{
		/* TODO: Optimize. */
		Map<Integer,Integer> idToTypeMap = new HashMap<Integer,Integer>();
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> whereParams = new HashMap<String,Object>();
			for (int id : ids)
			{
				whereParams.put(FIELD_ID, id);
				SQLResult result = SQLUtils.getResultFromQuery(conn, Arrays.asList(FIELD_TYPE), schemaName, tableName, whereParams, null);
				// either zero or one records
				
				if (result.rows.length == 1)
				{
					Number type = (Number) result.rows[0][0];
					idToTypeMap.put(id, type.intValue());
				}
				else if (result.rows.length == 0)
				{
					idToTypeMap.put(id, DataEntity.TYPE_UNSPECIFIED);
				}
				else
					throw new RemoteException(String.format("Multiple rows in manifest table with %s=%s", FIELD_ID, id));
			}
			return idToTypeMap;
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to get entry types.", e);
		}
	}
	public Collection<Integer> getByType(int ... types) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			List<Map<String,Object>> conditions = new Vector<Map<String,Object>>(types.length);
			for (int type : types)
			{
				if (type == DataEntity.TYPE_UNSPECIFIED)
				{
					conditions.clear();
					break;
				}
				conditions.add(MapUtils.<String,Object>fromPairs(FIELD_TYPE, type));
			}
			WhereClause<Object> where = new WhereClause<Object>(conn, conditions, null, false);
			List<Map<String,Object>> rows = SQLUtils.getRecordsFromQuery(conn, Arrays.asList(FIELD_ID, FIELD_TYPE), schemaName, tableName, where, null, Object.class);
			List<Integer> ids = new Vector<Integer>(rows.size());
			for (Map<String,Object> row : rows)
			{
				Number id = (Number) row.get(FIELD_ID);
				ids.add(id.intValue());
			}
			return ids;
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to get by type.", e);
		}
	}
}
