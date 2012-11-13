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
import java.sql.Statement;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import weave.config.ConnectionConfig;
import weave.utils.SQLUtils;


/**
 * @author Philip Kovac
 */
public class HierarchyTable extends AbstractTable
{
	public static final String FIELD_CHILD = "child_id";
	public static final String FIELD_PARENT = "parent_id";
	public static final String FIELD_ORDER = "sort_order";
	
	private static final int NULL = -1;
	
	public HierarchyTable(ConnectionConfig connectionConfig, String schemaName, String tableName) throws RemoteException
	{
		super(connectionConfig, schemaName, tableName);
	}
	protected void initTable() throws RemoteException
	{
		try 
		{
			Connection conn = connectionConfig.getAdminConnection();
			SQLUtils.createTable(
					conn, schemaName, tableName,
					Arrays.asList(FIELD_CHILD, FIELD_PARENT, FIELD_ORDER),
					Arrays.asList("BIGINT UNSIGNED", "BIGINT UNSIGNED", "BIGINT UNSIGNED")
			);
			/* No indices needed. */
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to initialize parent/child table.", e);
		}
	}
	@Deprecated 
	public void addChild(int child_id, int parent_id) throws RemoteException
	{
		addChildAt(child_id, parent_id, 0);
	}
	public void addChildAt(int child_id, int parent_id, int insertAt) throws RemoteException
	{
		try 
		{
			Connection conn = connectionConfig.getAdminConnection();
			
			// shift all existing children prior to insert
			Statement stmt = conn.createStatement();
			String orderField = SQLUtils.quoteSymbol(conn, FIELD_ORDER);
			String updateQuery = String.format(
					"update %s set %s=%s+1 where %s >= %s",
					SQLUtils.quoteSchemaTable(conn, schemaName, tableName),
					orderField,
					orderField,
					orderField,
					insertAt
				);
			stmt.executeUpdate(updateQuery);
			
			Map<String, Object> sql_args = new HashMap<String,Object>();
			removeChild(child_id, parent_id);
			sql_args.put(FIELD_CHILD, child_id);
			sql_args.put(FIELD_PARENT, parent_id);
			sql_args.put(FIELD_PARENT, insertAt);
			SQLUtils.insertRow(conn, schemaName, tableName, sql_args);
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to add child.",e);
		}
	}
	public Collection<Integer> getParents(int child_id) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> query = new HashMap<String,Object>();
			query.put(FIELD_CHILD, child_id);
			Set<Integer> parents = new HashSet<Integer>();
			for (Map<String,Object> row : SQLUtils.getRecordsFromQuery(conn, null, schemaName, tableName, query, Object.class, null, null))
			{
				Number parent = (Number)row.get(FIELD_PARENT);
				parents.add(parent.intValue());
			}
			return parents;
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to retrieve parents.", e);
		}
	}
	/* getChildren(null) will return all ids that appear in the 'child' column */
	public List<Integer> getChildren(int parent_id) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
//			if (parent_id == NULL)
//			{
//				return Collections.emptyList();
//			}
//			else 
//			{
				Map<String,Object> query = new HashMap<String,Object>();
				query.put(FIELD_PARENT, parent_id);
				List<Map<String,Object>> rows = SQLUtils.getRecordsFromQuery(conn, null, schemaName, tableName, query, Object.class, FIELD_ORDER, null);
				List<Integer> children = new Vector<Integer>(rows.size());
				for (Map<String,Object> row : rows)
				{
					Number child = (Number)row.get(FIELD_CHILD);
					children.add(child.intValue());
				}
				return children;
//			}
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to retrieve children.", e);
		}
	}
	/* passing in a NULL releases the constraint. */
	public void removeChild(int child_id, int parent_id) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> sql_args = new HashMap<String,Object>();
			if (child_id == NULL && parent_id == NULL)
				throw new RemoteException("removeChild called with -1,-1");
			if (child_id != NULL)
				sql_args.put(FIELD_CHILD, child_id);
			if (parent_id != NULL)
				sql_args.put(FIELD_PARENT, parent_id);
			SQLUtils.deleteRows(conn, schemaName, tableName, sql_args, null);
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to remove child.", e);
		}
	}
	/* Remove all relationships containing a given parent */
	public void purgeByParent(Integer parent_id) throws RemoteException
	{
		removeChild(NULL, parent_id);
	}
	/* Remove all relationships containing a given child */
	public void purgeByChild(Integer child_id) throws RemoteException
	{
		removeChild(child_id, NULL);
	}
	public void purge(Integer id) throws RemoteException
	{
		purgeByChild(id);
		purgeByParent(id);
	}
}
