/*
 * Weave (Web-based Analysis and Visualization Environment) Copyright (C) 2008-2011 University of Massachusetts Lowell This file is a part of Weave.
 * Weave is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License, Version 3, as published by the
 * Free Software Foundation. Weave is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the
 * GNU General Public License along with Weave. If not, see <http://www.gnu.org/licenses/>.
 */

package weave.config.tables;

import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import weave.config.ISQLConfig.ImmortalConnection;
import weave.utils.SQLUtils;


/**
 * @author Philip Kovac
 */
public class ParentChildTable extends AbstractTable
{
	private final String TAG_CHILD = "child_id";
	private final String TAG_PARENT = "parent_id";
	
    public ParentChildTable(ImmortalConnection conn, String schemaName, String tableName) throws RemoteException
    {
        super(conn, schemaName, tableName);
    }
    public void initTable() throws RemoteException
    {
        try 
        {
			Connection conn = this.conn.getConnection();
			SQLUtils.createTable(
					conn, schemaName, tableName,
					Arrays.asList(TAG_CHILD, TAG_PARENT),
					Arrays.asList("BIGINT UNSIGNED", "BIGINT UNSIGNED")
			);
			/* No indices needed. */
        }
        catch (SQLException e)
        {
            throw new RemoteException("Unable to initialize parent/child table.", e);
        }
    }
    public void addChild(Integer child_id, Integer parent_id) throws RemoteException
    {
        try 
        {
            Connection conn = this.conn.getConnection();
            Map<String, Object> sql_args = new HashMap<String,Object>();
            removeChild(child_id, parent_id);
            sql_args.put(TAG_CHILD, child_id);
            sql_args.put(TAG_PARENT, parent_id);
            SQLUtils.insertRow(conn, schemaName, tableName, sql_args);
        }
        catch (SQLException e)
        {
            throw new RemoteException("Unable to add child.",e);
        }
    }
    /* getChildren(null) will return all ids that appear in the 'child' column */
    public Collection<Integer> getChildren(Integer parent_id) throws RemoteException
    {
        try
        {
            Connection conn = this.conn.getConnection();
            if (parent_id == null)
            {
                return new HashSet<Integer>(SQLUtils.getIntColumn(conn, schemaName, tableName, TAG_CHILD));
            }
            else 
            {
                Map<String,Object> query = new HashMap<String,Object>();
                query.put(TAG_PARENT, parent_id);
                Set<Integer> children = new HashSet<Integer>();
                for (Map<String,Object> row : SQLUtils.getRecordsFromQuery(conn, null, schemaName, tableName, query, Object.class))
                {
                	Number child = (Number)row.get(TAG_CHILD);
                    children.add(child.intValue());
                }
                return children;
            }
        }
        catch (SQLException e)
        {
            throw new RemoteException("Unable to retrieve children.");
        }
    }
    /* passing in a null releases the constraint. */
    public void removeChild(Integer child_id, Integer parent_id) throws RemoteException
    {
        try
        {
            Connection conn = this.conn.getConnection();
            Map<String,Object> sql_args = new HashMap<String,Object>();
            if (child_id == null && parent_id == null)
                throw new RemoteException("removeChild called with two nulls. This is not what you want.", null);
            if (child_id != null)
                sql_args.put(TAG_CHILD, child_id);
            if (parent_id != null) 
                sql_args.put(TAG_PARENT, parent_id);
            SQLUtils.deleteRows(conn, schemaName, tableName, sql_args);
        }
        catch (SQLException e)
        {
            throw new RemoteException("Unable to remove child.", e);
        }
    }
    /* Remove all relationships containing a given parent */
    public void purgeByParent(Integer parent_id) throws RemoteException
    {
        removeChild(null, parent_id);
    }
    /* Remove all relationships containing a given child */
    public void purgeByChild(Integer child_id) throws RemoteException
    {
        removeChild(child_id, null);
    }
    public void purge(Integer id) throws RemoteException
    {
        purgeByChild(id);
        purgeByParent(id);
    }
}
