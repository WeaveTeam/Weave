/*
 * Weave (Web-based Analysis and Visualization Environment) Copyright (C) 2008-2011 University of Massachusetts Lowell This file is a part of Weave.
 * Weave is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License, Version 3, as published by the
 * Free Software Foundation. Weave is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the
 * GNU General Public License along with Weave. If not, see <http://www.gnu.org/licenses/>.
 */

package weave.config;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;

import weave.config.ISQLConfig.AttributeColumnInfo.Metadata;
import weave.config.SQLConfigUtils.InvalidParameterException;
import weave.utils.DebugTimer;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import weave.utils.DBFUtils;
import org.w3c.dom.*;

/**
 * DatabaseConfig This class reads from an SQL database and provides an interface to retrieve strings.
 * 
 * @author Andrew Wilkinson
 * @author Andy Dufilie
 * @author Philip Kovac
 */

public class SQLConfig
		implements ISQLConfig
{
	private final String SQLTYPE_VARCHAR = "VARCHAR(256)";
	private final String SQLTYPE_LONG_VARCHAR = "VARCHAR(2048)";
	private final String SQLTYPE_INT = "INT";
	
	private final String DESCRIPTION_TABLE_SUFFIX = "attr_desc";
	private final String PRIVATE_TABLE_SUFFIX = "attr_meta_private";
	private final String PUBLIC_TABLE_SUFFIX = "attr_meta_public";
	private final String CATEGORY_TABLE_SUFFIX = "hierarchy";
	private final String WEAVE_TABLE_PREFIX = "weave_";
	
	private String sqltable_desc = WEAVE_TABLE_PREFIX + DESCRIPTION_TABLE_SUFFIX;
	private String sqltable_private = WEAVE_TABLE_PREFIX + PRIVATE_TABLE_SUFFIX;
	private String sqltable_public = WEAVE_TABLE_PREFIX + PUBLIC_TABLE_SUFFIX;
	private String sqltable_category = WEAVE_TABLE_PREFIX + CATEGORY_TABLE_SUFFIX;
	
	private DatabaseConfigInfo dbInfo = null;
	private ISQLConfig connectionConfig = null;
	private Connection _lastConnection = null; // do not use this variable
												// directly -- use
												// getConnection() instead.

	/**
	 * This function gets a connection to the database containing the configuration information. This function will reuse a previously created
	 * Connection if it is still valid.
	 * 
	 * @return A Connection to the SQL database.
	 */
	public Connection getConnection() throws RemoteException, SQLException
	{
		if (SQLUtils.connectionIsValid(_lastConnection))
			return _lastConnection;
		return _lastConnection = SQLConfigUtils.getConnection(connectionConfig, dbInfo.connection);
	}

	/**
	 * @param connectionConfig An ISQLConfig instance that contains connection information. This is required because the connection information is not
	 *            stored in the database.
	 * @param connection The name of a connection in connectionConfig to use for storing and retrieving the data configuration.
	 * @param schema The schema that the data configuration is stored in.
	 * @param geometryConfigTable The table that stores the configuration for geometry collections.
	 * @param dataConfigTable The table that stores the configuration for data tables.
	 * @throws SQLException
	 * @throws InvalidParameterException
	 */
	public SQLConfig(ISQLConfig connectionConfig)
			throws RemoteException, SQLException, InvalidParameterException
	{
		// save original db config info
		dbInfo = connectionConfig.getDatabaseConfigInfo();
		if (dbInfo == null || dbInfo.schema == null || dbInfo.schema.length() == 0)
			throw new InvalidParameterException("DatabaseConfig: Schema not specified.");
		if (dbInfo.dataConfigTable == null || dbInfo.dataConfigTable.length() == 0)
			throw new InvalidParameterException("DatabaseConfig: Column metadata table name not specified.");

		this.connectionConfig = connectionConfig;
		if (getConnection() == null)
			throw new InvalidParameterException("DatabaseConfig: Unable to connect to connection \"" + dbInfo.connection + "\"");

		// attempt to create the schema and tables to store the configuration.
		try
		{
			SQLUtils.createSchema(getConnection(), dbInfo.schema);
		}
		catch (Exception e)
		{
			// do nothing if schema creation fails -- temporary workaround for
			// postgresql issue
			// e.printStackTrace();
		}
		initSQLTables();
	}
	private void initSQLTables() throws RemoteException, SQLException
	{
		Connection conn = getConnection();
		
		// ID->Description table
		List<String> columnNames = Arrays.asList("id", "description");
		List<String> columnTypes = Arrays.asList(SQLUtils.getSerialPrimaryKeyTypeString(conn), "TEXT");
		SQLUtils.createTable(conn, dbInfo.schema, sqltable_desc, columnNames, columnTypes);
		
		// Metadata tables
		columnNames = Arrays.asList("id", "property", "value");
		columnTypes = Arrays.asList("BIGINT UNSIGNED", "TEXT", "TEXT");
		SQLUtils.createTable(conn, dbInfo.schema, sqltable_private, columnNames, columnTypes);
		SQLUtils.createTable(conn, dbInfo.schema, sqltable_public, columnNames, columnTypes);
		
		SQLUtils.addForeignKey(conn, dbInfo.schema, sqltable_private, "id", sqltable_desc, "id");
		SQLUtils.addForeignKey(conn, dbInfo.schema, sqltable_public, "id", sqltable_desc, "id");
		
		// Category table
		columnNames = Arrays.asList("id", "name", "parent_id");
		columnTypes = Arrays.asList(SQLUtils.getSerialPrimaryKeyTypeString(conn), "TEXT", "INT");
		SQLUtils.createTable(conn, dbInfo.schema, sqltable_category, columnNames, columnTypes);
	}

	synchronized public DatabaseConfigInfo getDatabaseConfigInfo() throws RemoteException
	{
		return connectionConfig.getDatabaseConfigInfo();
	}
	// these functions are just passed to the private connectionConfig
	public Document getDocument() throws RemoteException
	{
		return connectionConfig.getDocument();
	}

	public String getServerName() throws RemoteException
	{
		return connectionConfig.getServerName();
	}

	public String getAccessLogConnectionName() throws RemoteException
	{
		return connectionConfig.getAccessLogConnectionName();
	}

	public String getAccessLogSchema() throws RemoteException
	{
		return connectionConfig.getAccessLogSchema();
	}

	public String getAccessLogTable() throws RemoteException
	{
		return connectionConfig.getAccessLogTable();
	}

	public List<String> getConnectionNames() throws RemoteException
	{
		return connectionConfig.getConnectionNames();
	}

	public List<String> getGeometryCollectionNames(String connectionName) throws RemoteException
	{
		List<String> names = new LinkedList<String>();
		List<Map<String,String>> sqlRes;
		try
		{
			Connection conn = getConnection();
			if (connectionName == null)
			{
					
					String[] tables = {sqltable_public, sqltable_public};
					String[] id_cols = {"id", "id"};
					List<String> cols = Arrays.asList("value");
					HashMap<String,String> whereClauses = new HashMap<String,String>();
					whereClauses.put(SQLUtils.quoteSymbol(conn, "t2") + "." + SQLUtils.quoteSymbol(conn, "property"), "dataType");
					whereClauses.put(SQLUtils.quoteSymbol(conn, "t2") + "." + SQLUtils.quoteSymbol(conn, "value"), "geometry");
					whereClauses.put(SQLUtils.quoteSymbol(conn, "t1") + "." + SQLUtils.quoteSymbol(conn, "property"), "name");
					sqlRes = SQLUtils.joinedSelectQuery(getConnection(), dbInfo.schema, cols, tables, id_cols, whereClauses);
					
					for (Map<String,String> row : sqlRes)
					{
						names.add(row.get("value"));
					}
			}
			else
			{
				Map<String, String> whereParams = new HashMap<String, String>();
				whereParams.put(GeometryCollectionInfo.CONNECTION, connectionName);

				List<String> selectColumns = Arrays.asList(GeometryCollectionInfo.NAME.toString());
				List<Map<String, String>> columnRecords = SQLUtils.getRecordsFromQuery(
						getConnection(), selectColumns, dbInfo.schema, dbInfo.geometryConfigTable, whereParams);

				HashSet<String> hashSet = new HashSet<String>();
				for (Map<String, String> mapping : columnRecords)
				{
					String geomName = mapping.get(GeometryCollectionInfo.NAME.toString());
					hashSet.add(geomName);
				}
				names = new Vector<String>(hashSet);
			}
			Collections.sort(names, String.CASE_INSENSITIVE_ORDER);
			return names;
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to get GeometryCollection names", e);
		}
	}

	public List<String> getDataTableNames(String connectionName) throws RemoteException
	{
		List<String> names;
		try
		{
			if (connectionName == null)
			{
				names = SQLUtils.getColumn(getConnection(), dbInfo.schema, dbInfo.dataConfigTable, Metadata.DATATABLE.toString());
				// return unique names
				names = new Vector<String>(new HashSet<String>(names));
			}
			else
			{

				Map<String, String> whereParams = new HashMap<String, String>();
				whereParams.put(AttributeColumnInfo.CONNECTION, connectionName);

				List<String> selectColumns = new LinkedList<String>();
				selectColumns.add(Metadata.DATATABLE.toString());
				List<Map<String, String>> columnRecords = SQLUtils.getRecordsFromQuery(
						getConnection(), selectColumns, dbInfo.schema, dbInfo.dataConfigTable, whereParams);

				HashSet<String> hashSet = new HashSet<String>();
				for (Map<String, String> mapping : columnRecords)
				{
					String tableName = mapping.get(Metadata.DATATABLE.toString());
					hashSet.add(tableName);
				}
				names = new Vector<String>(hashSet);
			}
			Collections.sort(names, String.CASE_INSENSITIVE_ORDER);
			return names;
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to get DataTable names", e);
		}
	}

	public List<String> getKeyTypes() throws RemoteException
	{
		try
		{
			Connection conn = getConnection();
			List<String> dtKeyTypes = SQLUtils.getColumn(conn, dbInfo.schema, dbInfo.dataConfigTable, Metadata.KEYTYPE.toString());
			List<String> gcKeyTypes = SQLUtils.getColumn(conn, dbInfo.schema, dbInfo.geometryConfigTable, GeometryCollectionInfo.KEYTYPE);

			Set<String> uniqueValues = new HashSet<String>();
			uniqueValues.addAll(dtKeyTypes);
			uniqueValues.addAll(gcKeyTypes);
			Vector<String> result = new Vector<String>(uniqueValues);
			Collections.sort(result, String.CASE_INSENSITIVE_ORDER);
			return result;
		}
		catch (Exception e)
		{
			throw new RemoteException(String.format("Unable to get key types"), e);
		}
	}

	public void addConnection(ConnectionInfo info) throws RemoteException
	{
		connectionConfig.addConnection(info);
	}

	public ConnectionInfo getConnectionInfo(String connectionName) throws RemoteException
	{
		return connectionConfig.getConnectionInfo(connectionName);
	}

	public void removeConnection(String name) throws RemoteException
	{
		connectionConfig.removeConnection(name);
	}

	public void addGeometryCollection(GeometryCollectionInfo info) throws RemoteException
	{
		try
		{
			// construct a hash map to pass to the insertRow() function
			Map<String, Object> valueMap = new HashMap<String, Object>();
			valueMap.put(GeometryCollectionInfo.NAME, info.name);
			valueMap.put(GeometryCollectionInfo.CONNECTION, info.connection);
			valueMap.put(GeometryCollectionInfo.SCHEMA, info.schema);
			valueMap.put(GeometryCollectionInfo.TABLEPREFIX, info.tablePrefix);
			valueMap.put(GeometryCollectionInfo.KEYTYPE, info.keyType);
			valueMap.put(GeometryCollectionInfo.PROJECTION, info.projection);
			valueMap.put(GeometryCollectionInfo.IMPORTNOTES, info.importNotes);

			SQLUtils.insertRow(getConnection(), dbInfo.schema, dbInfo.geometryConfigTable, valueMap);
		}
		catch (Exception e)
		{
			throw new RemoteException(String.format("Unable to add GeometryCollection \"%s\"", info.name), e);
		}
	}

	public void removeGeometryCollection(String name) throws RemoteException
	{
		try
		{
			Connection conn = getConnection();
			Map<String,String> whereParams = new HashMap<String,String>();
			whereParams.put("name", name);
			SQLUtils.deleteRows(conn, dbInfo.schema, dbInfo.geometryConfigTable, whereParams);
		}
		catch (SQLException e)
		{
			throw new RemoteException(String.format("Unable to remove GeometryCollection \"%s\"", name), e);
		}
	}

	public void removeDataTable(String name) throws RemoteException
	{
		try
		{
			Connection conn = getConnection();
			Map<String,String> whereParams = new HashMap<String,String>();
			whereParams.put("dataTable", name);
			SQLUtils.deleteRows(conn, dbInfo.schema, dbInfo.dataConfigTable, whereParams);
		}
		catch (SQLException e)
		{
			throw new RemoteException(String.format("Unable to remove DataTable \"%s\"", name), e);
		}
	}

	public GeometryCollectionInfo getGeometryCollectionInfo(String geometryCollectionName) throws RemoteException
	{
		Map<String, String> params = new HashMap<String, String>();
		params.put(GeometryCollectionInfo.NAME, geometryCollectionName);
		try
		{
			List<Map<String, String>> records = SQLUtils.getRecordsFromQuery(getConnection(), dbInfo.schema, dbInfo.geometryConfigTable, params);
			if (records.size() > 0)
			{
				Map<String, String> record = records.get(0);
				GeometryCollectionInfo info = new GeometryCollectionInfo();
				info.name = record.get(GeometryCollectionInfo.NAME);
				info.connection = record.get(GeometryCollectionInfo.CONNECTION);
				info.schema = record.get(GeometryCollectionInfo.SCHEMA);
				info.tablePrefix = record.get(GeometryCollectionInfo.TABLEPREFIX);
				info.keyType = record.get(GeometryCollectionInfo.KEYTYPE);
				info.projection = record.get(GeometryCollectionInfo.PROJECTION);
				info.importNotes = record.get(GeometryCollectionInfo.IMPORTNOTES);
				return info;
			}
		}
		catch (Exception e)
		{
			throw new RemoteException(String.format("Unable to get info for GeometryCollection \"%s\"", geometryCollectionName), e);
		}
		return null;
	}

	public void addAttributeColumn(AttributeColumnInfo info) throws RemoteException
	{
		try
		{
			// make a copy of the metadata and add the sql info
			Map<String, Object> valueMap = new HashMap<String, Object>(info.metadata);
			valueMap.put(AttributeColumnInfo.CONNECTION, info.connection);
			valueMap.put(AttributeColumnInfo.SQLQUERY, info.sqlQuery);
			// insert all the info into the sql table
			SQLUtils.insertRow(getConnection(), dbInfo.schema, dbInfo.dataConfigTable, valueMap);
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to add AttributeColumn configuration", e);
		}
	}

	// shortcut for calling the Map<String,String> version of this function
	public List<AttributeColumnInfo> getAttributeColumnInfo(String dataTableName) throws RemoteException
	{
		Map<String, String> metadataQueryParams = new HashMap<String, String>(1);
		metadataQueryParams.put(Metadata.DATATABLE.toString(), dataTableName);
		return getAttributeColumnInfo(metadataQueryParams);
	}

	/**
	 * @return A list of AttributeColumnInfo objects having info that matches the given parameters.
	 */
	public List<AttributeColumnInfo> getAttributeColumnInfo(Map<String, String> metadataQueryParams) throws RemoteException
	{
		List<AttributeColumnInfo> results = new Vector<AttributeColumnInfo>();
		try
		{
			DebugTimer t = new DebugTimer();
			t.report("getAttributeColumnInfo");
			// get rows matching given parameters
			List<Map<String, String>> records = SQLUtils.getRecordsFromQuery(
					getConnection(), dbInfo.schema, dbInfo.dataConfigTable, metadataQueryParams);
			t.lap(metadataQueryParams + "; got records " + records.size());
			for (int i = 0; i < records.size(); i++)
			{
				Map<String, String> metadata = records.get(i);
				String connection = metadata.remove(AttributeColumnInfo.CONNECTION);
				String sqlQuery = metadata.remove(AttributeColumnInfo.SQLQUERY);

				// special case -- derive keyType from geometryCollection if
				// keyType is missing
				if (metadata.get(Metadata.KEYTYPE.toString()).length() == 0)
				{
					t.start();
					String geomName = metadata.get(Metadata.GEOMETRYCOLLECTION.toString());

					GeometryCollectionInfo geomInfo = null;
					// we don't care if the following line fails because we
					// still want to return as much information as possible
					try
					{
						geomInfo = getGeometryCollectionInfo(geomName);
					}
					catch (Exception e)
					{
					}

					t.lap("get geom info " + i + " " + geomName);
					if (geomInfo != null)
						metadata.put(Metadata.KEYTYPE.toString(), geomInfo.keyType);
				}

				// remove null values and empty values
				// for (String key : metadata.keySet().toArray(new String[0]))
				// {
				// String value = metadata.get(key);
				// if (value == null || value.length() == 0)
				// metadata.remove(key);
				// }

				results.add(new AttributeColumnInfo(connection, sqlQuery, metadata));
			}
			t.report();
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to get AttributeColumn info", e);
		}
		return results;
	}
}
