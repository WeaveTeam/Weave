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
public class DublinCoreUtils
{
	/**
	 * The name of the table containing a list of the datasets.
	 */
	// public static final String DATASET_TABLE_NAME = "datasets";
	/**
	 * The name of the table containing a listing of all possible metadata
	 * elements.
	 */
	// public static final String DCE_TABLE_NAME = "metadata_elements";
	/**
	 * The name of the table which applies elements to datasets with values.
	 */
	public static final String DATASET_ELEMENTS_TABLE_NAME = "weave_dataset_metadata";
	/**
	 * The name of the column of the DATASET_ELEMENTS_TABLE containing dataset
	 * names
	 */
	public static final String DATASET_ELEMENTS_DATASET_COLUMN = "dataTable";
	/**
	 * The name of the column of the DATASET_ELEMENTS_TABLE containing property
	 * keys
	 */
	public static final String DATASET_ELEMENTS_ELEMENT_COLUMN = "element";
	/**
	 * The name of the column of the DATASET_ELEMENTS_TABLE containing property
	 * values
	 */
	public static final String DATASET_ELEMENTS_VALUE_COLUMN = "value";

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
		try
		{
			ensureMetadataTableExists(conn, schema);
			Statement stmt = conn.createStatement();

			for (Map.Entry<String, Object> e : elements.entrySet())
			{
				String property = e.getKey();
				String value = e.getValue().toString();
				System.out.println("INSERT INTO " + SQLUtils.quoteSchemaTable(conn, schema, DATASET_ELEMENTS_TABLE_NAME)
						+ " values ('" + datasetName + "','" + property + "','" + value + "')");
				stmt.execute("INSERT INTO " + SQLUtils.quoteSchemaTable(conn, schema, DATASET_ELEMENTS_TABLE_NAME)
						+ " values ('" + datasetName + "','" + property + "','" + value + "')");
			}
		}
		catch (SQLException e)
		{
			throw new RemoteException(e.getMessage(), e);
		}

		// Statement stmt = conn.createStatement();
		// ResultSet rs = stmt.executeQuery("select * from "
		// + config.getDataTableNames().iterator().next());
		//
		// while (rs.next())
		// System.out.println(rs.get);
	}

	private static void ensureMetadataTableExists(Connection conn, String schema) throws SQLException
	{
		if (!SQLUtils.tableExists(conn, schema, DATASET_ELEMENTS_TABLE_NAME))
		{
			Statement stmt = conn.createStatement();
			if (SQLUtils.isOracleServer(conn))
				stmt.execute("CREATE TABLE " + SQLUtils.quoteSchemaTable(conn, schema, DATASET_ELEMENTS_TABLE_NAME) + " ("
						+ DATASET_ELEMENTS_DATASET_COLUMN + " varchar(255), " + DATASET_ELEMENTS_ELEMENT_COLUMN + " varchar(255), "
						+ DATASET_ELEMENTS_VALUE_COLUMN + " varchar(1024))");
			else
				stmt.execute("CREATE TABLE " + SQLUtils.quoteSchemaTable(conn, schema, DATASET_ELEMENTS_TABLE_NAME) + " ("
						+ DATASET_ELEMENTS_DATASET_COLUMN + " varchar(255), " + DATASET_ELEMENTS_ELEMENT_COLUMN + " varchar(255), "
						+ DATASET_ELEMENTS_VALUE_COLUMN + " text)");
		}
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
		try
		{
			Map<String,String> elements = new HashMap<String,String>();
			if (SQLUtils.tableExists(conn, schema, DATASET_ELEMENTS_TABLE_NAME))
			{
				Statement stmt = conn.createStatement();

				ResultSet rs = stmt.executeQuery("SELECT " + DATASET_ELEMENTS_ELEMENT_COLUMN + ","
						+ DATASET_ELEMENTS_VALUE_COLUMN + " FROM "
						+ SQLUtils.quoteSchemaTable(conn, schema, DATASET_ELEMENTS_TABLE_NAME) + " WHERE "
						+ DATASET_ELEMENTS_DATASET_COLUMN + " = '" + dataTableName + "'" + " ORDER BY "
						+ DATASET_ELEMENTS_ELEMENT_COLUMN);

				while (rs.next())
					elements.put(rs.getString(DATASET_ELEMENTS_ELEMENT_COLUMN), rs.getString(DATASET_ELEMENTS_VALUE_COLUMN));
			}
			return elements;
		}
		catch (SQLException e)
		{
			throw new RemoteException(e.getMessage(), e);
		}
	}

	public static void deleteDCElements(Connection conn, String schema, String dataTableName, List<Map<String, String>> elements) throws RemoteException
	{
		try
		{
			if (SQLUtils.tableExists(conn, schema, DATASET_ELEMENTS_TABLE_NAME))
			{
				Statement stmt = conn.createStatement();
				String element;
				String value;
				for (Map<String, String> e : elements)
				{
					element = e.get("element");
					value = e.get("value");

					System.out.println("element = " + element);
					System.out.println("value = " + value);

					stmt.execute("DELETE FROM " + SQLUtils.quoteSchemaTable(conn, schema, DATASET_ELEMENTS_TABLE_NAME)
							+ " WHERE " + DATASET_ELEMENTS_ELEMENT_COLUMN + "='" + element + "' and "
							+ DATASET_ELEMENTS_VALUE_COLUMN + "='" + value + "' and " + DATASET_ELEMENTS_DATASET_COLUMN + "='"
							+ dataTableName + "'");
				}
			}
			else
				throw new RemoteException("Error - metadata table does not exist!");
		}
		catch (SQLException e)
		{
			throw new RemoteException(e.getMessage(), e);
		}
	}

	public static void updateEditedDCElement(Connection conn, String schema, String dataTableName, Map<String, String> object) throws RemoteException
	{
		try
		{
			if (SQLUtils.tableExists(conn, schema, DATASET_ELEMENTS_TABLE_NAME))
			{

				Statement stmt = conn.createStatement();
				String element, newValue, oldValue;

				element = object.get("element");
				newValue = object.get("newValue");
				oldValue = object.get("oldValue");

				// Print out the query
				String query = "UPDATE " + SQLUtils.quoteSchemaTable(conn, schema, DATASET_ELEMENTS_TABLE_NAME) + " SET "
						+ DATASET_ELEMENTS_VALUE_COLUMN + "='" + newValue + "' WHERE " + DATASET_ELEMENTS_ELEMENT_COLUMN + "='"
						+ element + "' and " + DATASET_ELEMENTS_VALUE_COLUMN + "='" + oldValue + "' and "
						+ DATASET_ELEMENTS_DATASET_COLUMN + "='" + dataTableName + "'";

				System.out.println(query);

				stmt.executeUpdate(query);
			}
			else
				throw new RemoteException("Error - metadata table does not exist!");
		}
		catch (SQLException e)
		{
			throw new RemoteException(e.getMessage(), e);
		}
	}
}
