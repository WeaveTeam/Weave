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
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import weave.config.ConnectionConfig;
import weave.utils.MapUtils;
import weave.utils.SQLUtils;


/**
 * @author Philip Kovac
 */
public class HierarchyTable extends AbstractTable
{
	public static final String FIELD_PARENT = "parent_id";
	public static final String FIELD_CHILD = "child_id";
	public static final String FIELD_ORDER = "sort_order";
	
	private static final int NULL = -1;
	
	private ManifestTable manifest = null;
    
	public HierarchyTable(ConnectionConfig connectionConfig, String schemaName, String tableName, ManifestTable manifest) throws RemoteException
	{
		super(connectionConfig, schemaName, tableName, FIELD_PARENT, FIELD_CHILD, FIELD_ORDER);
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
			
			// primary key is (parent,child) both for indexing and for avoiding duplicate relationships
			SQLUtils.createTable(
					conn, schemaName, tableName,
					Arrays.asList(fieldNames),
					Arrays.asList("BIGINT UNSIGNED", "BIGINT UNSIGNED", "BIGINT UNSIGNED"),
					Arrays.asList(FIELD_PARENT, FIELD_CHILD)
			);

//			addForeignKey(FIELD_PARENT, manifest, ManifestTable.FIELD_ID);
//			addForeignKey(FIELD_CHILD, manifest, ManifestTable.FIELD_ID);
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to initialize parent/child table.", e);
		}
		
//		try
//		{
//			SQLUtils.createIndex(
//					conn, schemaName, tableName,
//					tableName+FIELD_PARENT+FIELD_CHILD+FIELD_ORDER,
//					new String[]{FIELD_PARENT, FIELD_CHILD, FIELD_ORDER},
//					null
//			);
//		}
//		catch (SQLException e)
//		{
//			System.out.println("WARNING: Failed to create index. This may happen if the table already exists.");
//		}
	}
	public void addChild(int parent_id, int child_id, int sortOrder) throws RemoteException
	{
		Statement stmt = null;
		try
		{
			// during migration, do not update existing records
			if (!connectionConfig.migrationPending())
			{
				// shift all existing children prior to insert
				Connection conn = connectionConfig.getAdminConnection();
				stmt = conn.createStatement();
				String orderField = SQLUtils.quoteSymbol(conn, FIELD_ORDER);
				String updateQuery = String.format(
						"update %s set %s=%s+1 where %s >= %s",
						SQLUtils.quoteSchemaTable(conn, schemaName, tableName),
						orderField,
						orderField,
						orderField,
						sortOrder
					);
				stmt.executeUpdate(updateQuery);
				SQLUtils.cleanup(stmt);
			}
			
            insertRecord(parent_id, child_id, sortOrder);
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to add child.",e);
		}
		finally
		{
			SQLUtils.cleanup(stmt);
		}
	}

	public Collection<Integer> getParents(int child_id) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> query = MapUtils.fromPairs(FIELD_CHILD, child_id);
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
			Map<String,Object> query = MapUtils.fromPairs(FIELD_PARENT, parent_id);
			List<Map<String,Object>> rows = SQLUtils.getRecordsFromQuery(conn, null, schemaName, tableName, query, Object.class, FIELD_ORDER, null);
			List<Integer> children = new Vector<Integer>(rows.size());
			for (Map<String,Object> row : rows)
			{
				Number child = (Number)row.get(FIELD_CHILD);
				children.add(child.intValue());
			}
			return children;
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to retrieve children.", e);
		}
	}
	/* passing in a NULL releases the constraint. */
	public void removeChild(int parent_id, int child_id) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<String,Object> whereParams = MapUtils.fromPairs();
			if (child_id == NULL && parent_id == NULL)
				throw new RemoteException("removeChild called with -1,-1");
			if (child_id != NULL)
				whereParams.put(FIELD_CHILD, child_id);
			if (parent_id != NULL)
				whereParams.put(FIELD_PARENT, parent_id);
			SQLUtils.deleteRows(conn, schemaName, tableName, whereParams, null, true);
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to remove child.", e);
		}
	}
	/* Remove all relationships containing a given parent */
	public void purgeByParent(int parent_id) throws RemoteException
	{
		removeChild(parent_id, NULL);
	}
	/* Remove all relationships containing a given child */
	public void purgeByChild(int child_id) throws RemoteException
	{
		removeChild(NULL, child_id);
	}
	public void purge(int id) throws RemoteException
	{
		purgeByChild(id);
		purgeByParent(id);
	}
}
