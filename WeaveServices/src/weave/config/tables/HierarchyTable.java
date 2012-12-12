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
import weave.utils.MapUtils;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import weave.utils.StringUtils;
import weave.utils.SQLUtils.WhereClause;


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
	private int migrationOrder = 0;
    
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
//			System.err.println("WARNING: Failed to create index. This may happen if the table already exists.");
//		}
	}
	public void addChild(int parent_id, int child_id, int insert_at_index) throws RemoteException
	{
		String query = null;
		Statement stmt = null;
		ResultSet rs = null;
		try
		{
			int sortOrder = 0;
			
			// during migration, do not update existing records
			if (connectionConfig.migrationPending())
			{
				// always insert at end
				sortOrder = migrationOrder++;
			}
			else // not currently migrating
			{
				Connection conn = connectionConfig.getAdminConnection();
				stmt = conn.createStatement();
				
				String quotedTable = SQLUtils.quoteSchemaTable(conn, schemaName, tableName);
				String quotedParentField = SQLUtils.quoteSymbol(conn, FIELD_PARENT);
				String quotedOrderField = SQLUtils.quoteSymbol(conn, FIELD_ORDER);
				
				// find the order value for the specified insert index
				query = String.format(
						"SELECT * FROM %s WHERE %s=%s ORDER BY %s",
						quotedTable,
						quotedParentField,
						parent_id,
						FIELD_ORDER
					);
				rs = stmt.executeQuery(query);
				boolean found = false;
				for (int i = 0; rs.next(); i++)
				{
					// avoid inserting duplicate relationships
					if (rs.getInt(FIELD_CHILD) == child_id)
						return;
					
					if (i == insert_at_index)
					{
						sortOrder = rs.getInt(FIELD_ORDER);
						found = true;
					}
					else if (!found)
					{
						sortOrder = rs.getInt(FIELD_ORDER) + 1;
					}
				}
				SQLUtils.cleanup(rs);
				
				// shift all existing children prior to insert
				query = String.format(
						"UPDATE %s SET %s=%s+1 WHERE %s=%s AND %s >= %s",
						quotedTable,
						quotedOrderField,
						quotedOrderField,
						quotedParentField,
						parent_id,
						quotedOrderField,
						sortOrder
					);
				stmt.executeUpdate(query);
			}
			
            insertRecord(parent_id, child_id, sortOrder);
		}
		catch (SQLException e)
		{
			if (query != null)
				e = new SQLException("Query failed: " + query, e);
			throw new RemoteException("Unable to add child.", e);
		}
		finally
		{
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(stmt);
		}
	}

	public Collection<Integer> getParents(int child_id) throws RemoteException
	{
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Set<Integer> parents = new HashSet<Integer>();
			Map<String,Object> conditions = MapUtils.fromPairs(FIELD_CHILD, child_id);
			WhereClause<Object> where = new WhereClause<Object>(conn, conditions, null, true);
			for (Map<String,Object> row : SQLUtils.getRecordsFromQuery(conn, null, schemaName, tableName, where, null, Object.class))
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
			Map<String,Object> conditions= MapUtils.fromPairs(FIELD_PARENT, parent_id);
			WhereClause<Object> where = new WhereClause<Object>(conn, conditions, null, true);
			List<Map<String,Object>> rows = SQLUtils.getRecordsFromQuery(conn, null, schemaName, tableName, where, FIELD_ORDER, Object.class);
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
	
	public Map<Integer,Integer> getChildCounts(Collection<Integer> ids) throws RemoteException
	{
		ResultSet rs = null;
		PreparedStatement stmt = null;
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<Integer,Integer> result = new HashMap<Integer,Integer>();
			
			// build query
			String quotedParentField = SQLUtils.quoteSymbol(conn, FIELD_PARENT);
			String query = String.format(
					"SELECT %s,count(*) FROM %s WHERE %s IN (%s) GROUP BY %s",
					quotedParentField,
					SQLUtils.quoteSchemaTable(conn, schemaName, tableName),
					quotedParentField,
					StringUtils.join(",", ids),
					quotedParentField
				);
			stmt = conn.prepareStatement(query);
			rs = stmt.executeQuery();
			rs.setFetchSize(SQLResult.FETCH_SIZE);
			while (rs.next())
				result.put(rs.getInt(1), rs.getInt(2)); // parent => count
			
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
			WhereClause<Object> where = new WhereClause<Object>(conn, whereParams, null, true);
			SQLUtils.deleteRows(conn, schemaName, tableName, where);
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
