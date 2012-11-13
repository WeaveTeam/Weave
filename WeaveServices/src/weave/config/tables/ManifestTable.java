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
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import weave.config.ConnectionConfig;
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
			SQLUtils.createTable(conn, schemaName, tableName,
				Arrays.asList(FIELD_ID, FIELD_TYPE),
				Arrays.asList(SQLUtils.getSerialPrimaryKeyTypeString(conn), "TINYINT UNSIGNED"));
			/* TODO: Add necessary foreign keys. */
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to initialize manifest table.", e);
		}
	}
	public Integer addEntry(Integer type_id) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> record = new HashMap<String,Object>();
			record.put(FIELD_TYPE, type_id);
			return SQLUtils.insertRowReturnID(conn, schemaName, tableName, record);
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to add entry to manifest table.", e);
		}
	}
	public void removeEntry(Integer id) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> whereParams = new HashMap<String,Object>();
			whereParams.put(FIELD_ID, id);
			SQLUtils.deleteRows(conn, schemaName, tableName, whereParams);
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to remove entry from manifest table.", e);
		}
	}
	public Integer getEntryType(Integer id) throws RemoteException
	{
		List<Integer> list = new LinkedList<Integer>();
		Map<Integer,Integer> resmap;
		list.add(id);
		resmap = getEntryTypes(list);
		for (Integer idx : resmap.values())
			return idx;
		throw new RemoteException("No entry exists for this id.", null);
	}
	public Map<Integer,Integer> getEntryTypes(Collection<Integer> ids) throws RemoteException
	{
		/* TODO: Optimize. */
		Map<Integer,Integer> result = new HashMap<Integer,Integer>();
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> whereParams = new HashMap<String,Object>();
			List<Map<String,Object>> sqlres;
			for (Integer id : ids)
			{
				whereParams.put(FIELD_ID, id);
				sqlres = SQLUtils.getRecordsFromQuery(conn, Arrays.asList(FIELD_ID, FIELD_TYPE), schemaName, tableName, whereParams, Object.class, null);
				// sqlres has one or zero rows
				if (sqlres.size() == 0)
				{
					result.put(id, -1);
				}
				else
				{
					Number type = (Number) sqlres.get(0).get(FIELD_TYPE);
					result.put(id, type.intValue());
				}
			}
			return result;
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
			List<Integer> ids = new LinkedList<Integer>();
			Map<String,Object> whereParams = new HashMap<String,Object>();
			List<Map<String,Object>> sqlres;
			Connection conn = connectionConfig.getAdminConnection();
			whereParams.put(FIELD_TYPE, type_id);
			sqlres = SQLUtils.getRecordsFromQuery(conn, Arrays.asList(FIELD_ID, FIELD_TYPE), schemaName, tableName, whereParams, Object.class, null);
			for (Map<String,Object> row : sqlres)
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
	public List<Integer> getAll() throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			return SQLUtils.getIntColumn(conn, schemaName, tableName, FIELD_ID);
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to get complete manifest.", e);
		} 
	}
}
