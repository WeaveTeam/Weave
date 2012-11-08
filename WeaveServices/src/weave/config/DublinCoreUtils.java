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
package weave.config;

import java.rmi.RemoteException;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import weave.utils.SQLUtils;

/**
 * A utility class for managing metadata properties for data sets.
 * 
 * @author Curran Kelleher
 * 
 */
@Deprecated public class DublinCoreUtils
{
	public static void migrate(Connection conn, Map<String,Integer> dataTableIdLookup, DataConfig dataConfig)
	{
		//TODO
	}
	
	/**
	 * The name of the table which applies elements to datasets with values.
	 */
	private static final String TABLE_NAME = "weave_dataset_metadata";
	/**
	 * The name of the column of the TABLE containing dataset names
	 */
	private static final String DATASET_COLUMN = "dataTable";
	/**
	 * The name of the column of the TABLE containing property keys
	 */
	private static final String ELEMENT_COLUMN = "element";
	/**
	 * The name of the column of the TABLE containing property values
	 */
	private static final String VALUE_COLUMN = "value";

	/**
	 * Adds the given Dublin Core elements to the given data set.
	 * 
	 * @param conn
	 * @param schema
	 * @param datasetName
	 * @param elements
	 * @return
	 * @throws RemoteException
	 *             Thrown if the operation failed.
	 */
	public static void addDCElements(Connection conn, String schema, String datasetName, Map<String, Object> elements) throws RemoteException
	{
		CallableStatement cstmt = null;
		try
		{
			ensureMetadataTableExists(conn, schema);

			for (Map.Entry<String, Object> e : elements.entrySet())
			{
				String property = e.getKey();
				String value = e.getValue().toString();
				String query = String.format(
						"INSERT INTO %s values (?,?,?)",
						SQLUtils.quoteSchemaTable(conn, schema, TABLE_NAME)
					);
				cstmt = conn.prepareCall(query);
				cstmt.setString(1, datasetName);
				cstmt.setString(2, property);
				cstmt.setString(3, value);
				cstmt.execute();
			}
		}
		catch (SQLException e)
		{
			throw new RemoteException(e.getMessage(), e);
		}
		finally
		{
			SQLUtils.cleanup(cstmt);
		}

		// Statement stmt = conn.createStatement();
		// ResultSet rs = stmt.executeQuery("select * from "
		// + config.getDataTableNames().iterator().next());
		//
		// while (rs.next())
		// System.out.println(rs.get);
	}

	private static boolean _exists = false;
	
	private static void ensureMetadataTableExists(Connection conn, String schema) throws SQLException
	{
		if (_exists) // only do this stuff once
			return;
		
		if (!SQLUtils.tableExists(conn, schema, TABLE_NAME))
		{
			Statement stmt = null;
			try
			{
				stmt = conn.createStatement();
				String varChar = SQLUtils.getVarcharTypeString(conn, 255);
				String longVarChar = SQLUtils.isOracleServer(conn) ? SQLUtils.getVarcharTypeString(conn, 1024) : "text";
				String query = String.format(
						"CREATE TABLE %s (%s %s, %s %s, %s %s)",
						SQLUtils.quoteSchemaTable(conn, schema, TABLE_NAME),
						DATASET_COLUMN, varChar,
						ELEMENT_COLUMN, varChar,
						VALUE_COLUMN, longVarChar
					);
				stmt.execute(query);
			}
			finally
			{
				SQLUtils.cleanup(stmt);
			}
		}
		
		// add index
		try
		{
			SQLUtils.createIndex(conn, schema, TABLE_NAME, new String[]{DATASET_COLUMN});
		}
		catch (SQLException e)
		{
			// ignore sql errors
		}
		
		_exists = true;
	}

	/**
	 * Queries the database for the Dublin Core metadata elements associated
	 * with the data set with the given name. The result is returned as a Map
	 * whose keys are Dublin Core property names and whose values are the values
	 * for those properties (for the given data set) stored in the metadata
	 * store.
	 * 
	 * If an error occurs, a map is returned with a single key-value pair whose
	 * key is "error".
	 * 
	 * @throws RemoteException
	 *             when the operation fails.
	 */
	public static Map<String,String> listDCElements(Connection conn, String schema, String dataTableName) throws RemoteException
	{
		CallableStatement cstmt = null;
		try
		{
			Map<String,String> elements = new HashMap<String,String>();
			if (SQLUtils.tableExists(conn, schema, TABLE_NAME))
			{
				String query = String.format(
						"SELECT %s,%s FROM %s WHERE %s = ?",
						ELEMENT_COLUMN,
						VALUE_COLUMN,
						SQLUtils.quoteSchemaTable(conn, schema, TABLE_NAME),
						DATASET_COLUMN
					);
				
				cstmt = conn.prepareCall(query);
				cstmt.setString(1, dataTableName);
				ResultSet rs = cstmt.executeQuery();
				while (rs.next())
					elements.put(rs.getString(ELEMENT_COLUMN), rs.getString(VALUE_COLUMN));
			}
			return elements;
		}
		catch (SQLException e)
		{
			throw new RemoteException(e.getMessage(), e);
		}
		finally
		{
			SQLUtils.cleanup(cstmt);
		}
	}
	// temporary hack
	@SuppressWarnings("unchecked")
	public static Map<String,String>[] listDCElements(Connection conn, String schema, String[] tableNames) throws RemoteException
	{
		Statement stmt = null;
		try
		{
			Map<String,Map<String,String>> map = new HashMap<String,Map<String,String>>();
			Map<String,String>[] result = new Map[tableNames.length];
			for (int i = 0; i < tableNames.length; i++)
			{
				String name = tableNames[i];
				Map<String,String> metadata = new HashMap<String,String>();
				metadata.put("name", name);
				map.put(name, metadata);
				result[i] = metadata;
			}
			
			if (SQLUtils.tableExists(conn, schema, TABLE_NAME))
			{
				String query = String.format(
						"SELECT %s,%s,%s FROM %s",
						DATASET_COLUMN,
						ELEMENT_COLUMN,
						VALUE_COLUMN,
						SQLUtils.quoteSchemaTable(conn, schema, TABLE_NAME)
				);
				
				stmt = conn.createStatement();
				ResultSet rs = stmt.executeQuery(query);
				while (rs.next())
				{
					String name = rs.getString(DATASET_COLUMN);
					Map<String,String> metadata = map.get(name);
					if (metadata != null)
						metadata.put(rs.getString(ELEMENT_COLUMN), rs.getString(VALUE_COLUMN));
				}
			}
			return result;
		}
		catch (SQLException e)
		{
			throw new RemoteException(e.getMessage(), e);
		}
		finally
		{
			SQLUtils.cleanup(stmt);
		}
	}

	public static void deleteDCElements(Connection conn, String schema, String dataTableName, List<Map<String, String>> elements) throws RemoteException
	{
		CallableStatement cstmt = null;
		try
		{
			if (SQLUtils.tableExists(conn, schema, TABLE_NAME))
			{
				String element;
				String value;
				for (Map<String, String> e : elements)
				{
					element = e.get("element");
					value = e.get("value");

					String query = String.format(
						"DELETE FROM %s WHERE %s = ? and %s = ? and %s = ?",
						SQLUtils.quoteSchemaTable(conn, schema, TABLE_NAME),
						ELEMENT_COLUMN,
						VALUE_COLUMN,
						DATASET_COLUMN
					);
					cstmt = conn.prepareCall(query);
					cstmt.setString(1, element);
					cstmt.setString(2, value);
					cstmt.setString(3, dataTableName);
					cstmt.execute();
				}
			}
			else
				throw new RemoteException("Error - metadata table does not exist!");
		}
		catch (SQLException e)
		{
			throw new RemoteException(e.getMessage(), e);
		}
		finally
		{
			SQLUtils.cleanup(cstmt);
		}
	}

	public static void updateEditedDCElement(Connection conn, String schema, String dataTableName, Map<String, String> object) throws RemoteException
	{
		CallableStatement cstmt = null;
		try
		{
			if (SQLUtils.tableExists(conn, schema, TABLE_NAME))
			{
				String element, newValue, oldValue;

				element = object.get("element");
				newValue = object.get("newValue");
				oldValue = object.get("oldValue");

				String query = String.format(
						"update %s set %s = ? where %s = ? and %s = ? and %s = ?",
						SQLUtils.quoteSchemaTable(conn, schema, TABLE_NAME),
						VALUE_COLUMN,
						ELEMENT_COLUMN,
						VALUE_COLUMN,
						DATASET_COLUMN
					);
				cstmt = conn.prepareCall(query);
				cstmt.setString(1, newValue);
				cstmt.setString(2, element);
				cstmt.setString(3, oldValue);
				cstmt.setString(4, dataTableName);
				cstmt.execute();
			}
			else
				throw new RemoteException("Error - metadata table does not exist!");
		}
		catch (SQLException e)
		{
			throw new RemoteException(e.getMessage(), e);
		}
		finally
		{
			SQLUtils.cleanup(cstmt);
		}
	}
}
