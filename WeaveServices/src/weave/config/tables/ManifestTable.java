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
import weave.utils.MyEntry;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;


/**
 * @author Philip Kovac
 */
public class ManifestTable extends AbstractTable
{
	public static final String FIELD_ID = "entity_id";
	public static final String FIELD_TYPE = "type_id";
	
	public ManifestTable(ConnectionConfig connectionConfig, String schemaName, String tableName) throws RemoteException
	{
		super(connectionConfig, schemaName, tableName);
	}
	protected void initTable() throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			
			// primary key is entity_id for indexing and because we don't want duplicate ids
			SQLUtils.createTable(
				conn, schemaName, tableName,
				Arrays.asList(FIELD_ID, FIELD_TYPE),
				Arrays.asList(SQLUtils.getSerialPrimaryKeyTypeString(conn), "TINYINT UNSIGNED"),
				null
			);
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to initialize manifest table.", e);
		}
	}
	public Integer addEntry(int type_id) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			return SQLUtils.insertRowReturnID(conn, schemaName, tableName, MyEntry.<String,Object>mapFromPairs(FIELD_TYPE, type_id));
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
			SQLUtils.deleteRows(conn, schemaName, tableName, MyEntry.<String,Object>mapFromPairs(FIELD_ID, id), null, true);
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to remove entry from manifest table.", e);
		}
	}
	public Integer getEntryType(int id) throws RemoteException
	{
		Integer type = getEntryTypes(Arrays.asList(id)).get(id);
		return type == null ? DataEntity.TYPE_ANY : type;
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
					idToTypeMap.put(id, DataEntity.TYPE_ANY);
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
	public Collection<Integer> getByType(Integer type_id) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> whereParams = MyEntry.mapFromPairs(FIELD_TYPE, type_id);
			List<Map<String,Object>> rows = SQLUtils.getRecordsFromQuery(conn, Arrays.asList(FIELD_ID, FIELD_TYPE), schemaName, tableName, whereParams, Object.class, null, null);
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
//	public List<Integer> getAll() throws RemoteException
//	{
//		try
//		{
//			Connection conn = connectionConfig.getAdminConnection();
//			return SQLUtils.getIntColumn(conn, schemaName, tableName, FIELD_ID);
//		}
//		catch (Exception e)
//		{
//			throw new RemoteException("Unable to get complete manifest.", e);
//		} 
//	}
}
