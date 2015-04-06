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
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

import weave.config.ConnectionConfig;
import weave.config.DataConfig.Relationship;
import weave.config.DataConfig.RelationshipList;
import weave.utils.MapUtils;
import weave.utils.SQLExceptionWithQuery;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import weave.utils.SQLUtils.WhereClause;
import weave.utils.SQLUtils.WhereClauseBuilder;
import weave.utils.Strings;


/**
 * @author Philip Kovac
 * @author Andy Dufilie
 */
public class HierarchyTable extends AbstractTable
{
	public static final String FIELD_PARENT = "parent_id";
	public static final String FIELD_CHILD = "child_id";
	public static final String FIELD_ORDER = "sort_order";
	
	private static final int NULL = -1;
	
	private int migrationOrder = 0;
    
	public HierarchyTable(ConnectionConfig connectionConfig, String schemaName, String tableName) throws RemoteException
	{
		super(connectionConfig, schemaName, tableName, FIELD_PARENT, FIELD_CHILD, FIELD_ORDER);
		if (!tableExists())
			initTable();
	}

	protected void initTable() throws RemoteException
	{
		Connection conn;
		try
		{
			conn = connectionConfig.getAdminConnection();
			String BIGINT = SQLUtils.getBigIntTypeString(conn);
			
			// primary key is (parent,child) both for indexing and for avoiding duplicate relationships
			SQLUtils.createTable(
					conn, schemaName, tableName,
					Arrays.asList(fieldNames),
					Arrays.asList(BIGINT, BIGINT, SQLUtils.getIntTypeString(conn)),
					Arrays.asList(FIELD_PARENT, FIELD_CHILD)
			);

			// index speeds up purgeByChild()
			SQLUtils.createIndex(conn, schemaName, tableName, new String[]{FIELD_CHILD});
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to initialize hierarchy table.", e);
		}
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
						quotedOrderField
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
				query = null;
			}
			
            insertRecord(parent_id, child_id, sortOrder);
		}
		catch (SQLException e)
		{
			if (query != null)
				e = new SQLExceptionWithQuery(query, e);
			throw new RemoteException("Unable to add child.", e);
		}
		finally
		{
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(stmt);
		}
	}
	
	/**
	 * Gets a list of parent-child relationships for a set of entities.
	 * @param ids A collection of entity IDs.
	 * @return An ordered list of parent-child relationships involving the specified entities.
	 */
	public RelationshipList getRelationships(Collection<Integer> ids) throws RemoteException
	{
		ResultSet rs = null;
		PreparedStatement stmt = null;
		String query = null;
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			RelationshipList result = new RelationshipList();
			if (ids.size() == 0)
				return result;
			
			// build query
			String idList = Strings.join(",", ids);
			query = String.format(
					"SELECT * FROM %s WHERE %s IN (%s) OR %s IN (%s) ORDER BY %s",
					SQLUtils.quoteSchemaTable(conn, schemaName, tableName),
					SQLUtils.quoteSymbol(conn, FIELD_PARENT), idList,
					SQLUtils.quoteSymbol(conn, FIELD_CHILD), idList,
					SQLUtils.quoteSymbol(conn, FIELD_ORDER)
				);
			stmt = conn.prepareStatement(query);
			rs = stmt.executeQuery();
			rs.setFetchSize(SQLResult.FETCH_SIZE);
			while (rs.next())
				result.add(new Relationship(rs.getInt(FIELD_PARENT), rs.getInt(FIELD_CHILD)));
			return result;
		}
		catch (SQLException e)
		{
			if (query != null)
				e = new SQLExceptionWithQuery(query, e);
			throw new RemoteException("Unable to retrieve relationships.", e);
		}
		finally
		{
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(stmt);
		}
	}
	
	public Map<Integer,Integer> getChildCounts(Collection<Integer> ids) throws RemoteException
	{
		ResultSet rs = null;
		PreparedStatement stmt = null;
		String query = null;
		try
		{
			Connection conn = connectionConfig.getAdminConnection();
			Map<Integer,Integer> result = new HashMap<Integer,Integer>();
			if (ids.size() == 0)
				return result;
			
			// Note: This query is built dynamically based on the ids.  This is ok as long as they are Integers and not Strings.
			String quotedParentField = SQLUtils.quoteSymbol(conn, FIELD_PARENT);
			query = String.format(
					"SELECT %s,count(*) FROM %s WHERE %s IN (%s) GROUP BY %s",
					quotedParentField,
					SQLUtils.quoteSchemaTable(conn, schemaName, tableName),
					quotedParentField,
					Strings.join(",", ids),
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
			if (query != null)
				e = new SQLExceptionWithQuery(query, e);
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
			WhereClause<Object> where = new WhereClauseBuilder<Object>(false)
				.addGroupedConditions(whereParams, null)
				.build(conn);
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
