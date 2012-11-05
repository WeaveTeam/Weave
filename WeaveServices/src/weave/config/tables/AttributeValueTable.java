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
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import weave.config.ISQLConfig.ImmortalConnection;
import weave.utils.SQLUtils;


/**
 * @author Philip Kovac
 */
public class AttributeValueTable extends AbstractTable
{
	private final String FIELD_ID = "id";
	private final String FIELD_PROPERTY = "property";
	private final String FIELD_VALUE = "value";
	
    public AttributeValueTable(ImmortalConnection conn, String schemaName, String tableName) throws RemoteException
    {
        super(conn, schemaName, tableName);
    }
    protected void initTable() throws RemoteException
    {
		try 
		{
			Connection conn = this.conn.getConnection();
			SQLUtils.createTable(
				conn, schemaName, tableName,
				Arrays.asList(FIELD_ID, FIELD_PROPERTY, FIELD_VALUE),
				Arrays.asList("BIGINT UNSIGNED", "TEXT", "TEXT")
			);

        } 
        catch (SQLException e)
        {
            throw new RemoteException("Unable to initialize attribute-value-table.", e);
        }
        try
        {
            Connection conn = this.conn.getConnection();
            /* Index of (ID, Property) */
            SQLUtils.createIndex(
            		conn, schemaName, tableName,
                    tableName+FIELD_ID+FIELD_PROPERTY,
                    new String[]{FIELD_ID, FIELD_PROPERTY},
                    new Integer[]{0, 255}
            );

            /* Index of (Property, Value) */
            SQLUtils.createIndex(
            		conn, schemaName, tableName,
                    tableName+FIELD_PROPERTY+FIELD_VALUE,
                    new String[]{FIELD_PROPERTY, FIELD_VALUE},
                    new Integer[]{255,255}
            );
        }
        catch (SQLException e)
        {
            System.out.println("WARNING: Failed to create index. This may happen if the table already exists.");
        }
    }
    /* TODO: Add optimized methods for adding/removing multiple entries. */
    /* if it is a null or empty string, it will simply unset the property. */
    public void setProperty(Integer id, String property, String value) throws RemoteException
    {
        try 
        {
            Connection conn = this.conn.getConnection();
            Map<String, Object> sql_args = new HashMap<String,Object>();
            sql_args.put(FIELD_PROPERTY, property);
            sql_args.put(FIELD_ID, id);
            SQLUtils.deleteRows(conn, schemaName, tableName, sql_args);
            if (value != null && value.length() > 0)
            {
                sql_args.clear();
                sql_args.put(FIELD_VALUE, value);
                sql_args.put(FIELD_PROPERTY, property);
                sql_args.put(FIELD_ID, id);
                SQLUtils.insertRow(conn, schemaName, tableName, sql_args);
            }
        } 
        catch (SQLException e)
        {
            throw new RemoteException("Unable to set property.", e);
        }
    }
    /* Nuke all entries for a given id */
    public void clearId(Integer id) throws RemoteException
    {
        try 
        {
            Connection conn = this.conn.getConnection();
            Map<String, Object> sql_args  = new HashMap<String,Object>();
            sql_args.put(FIELD_ID, id);
            SQLUtils.deleteRows(conn, schemaName, tableName, sql_args);
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
            Connection conn = this.conn.getConnection();
            Map<String,Object> params = new HashMap<String,Object>();
            Map<Integer,String> result = new HashMap<Integer,String>();
            params.put(FIELD_PROPERTY, property);
            List<Map<String,Object>> rows = SQLUtils.getRecordsFromQuery(conn, Arrays.asList(FIELD_ID, FIELD_VALUE), schemaName, tableName, params, Object.class);
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
            Connection conn = this.conn.getConnection();
            return SQLUtils.idInSelect(conn, schemaName, tableName, FIELD_ID, FIELD_PROPERTY, FIELD_VALUE, ids, null);
        }   
        catch (SQLException e)
        {
            throw new RemoteException("Unable to get properties for a list of ids.", e);
        }
    }
    public Set<Integer> filter(Map<String,String> constraints) throws RemoteException
    {
        try
        {
            Connection conn = this.conn.getConnection();
            List<Map<String,String>> crossRowArgs = new LinkedList<Map<String,String>>();

            for (Entry<String,String> keyValPair : constraints.entrySet())
            {
                if (keyValPair.getKey() == null || keyValPair.getValue() == null)
                	continue;
                Map<String,String> colValPair = new HashMap<String,String>();
                colValPair.put(FIELD_PROPERTY, keyValPair.getKey());
                colValPair.put(FIELD_VALUE, keyValPair.getValue());
                crossRowArgs.add(colValPair);
            }
            return new HashSet<Integer>(SQLUtils.crossRowSelect(conn, schemaName, tableName, FIELD_ID, crossRowArgs));
        }
        catch (SQLException e)
        {
            throw new RemoteException("Unable to get ids given a set of property/value pairs.", e);
        }
    }
}
