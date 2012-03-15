/*
 * Weave (Web-based Analysis and Visualization Environment) Copyright (C) 2008-2011 University of Massachusetts Lowell This file is a part of Weave.
 * Weave is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License, Version 3, as published by the
 * Free Software Foundation. Weave is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the
 * GNU General Public License along with Weave. If not, see <http://www.gnu.org/licenses/>.
 */

package weave.config;

import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Collections;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import org.w3c.dom.Document;

import weave.utils.DebugTimer;
import weave.utils.ListUtils;
import weave.utils.SQLUtils;

/**
 * DatabaseConfig This class reads from an SQL database and provides an interface to retrieve strings.
 * 
 * @author Andrew Wilkinson
 * @author Andy Dufilie
 */

public class DatabaseConfig
		extends IDeprecatedSQLConfig
{
	private DeprecatedDatabaseConfigInfo dbInfo = null;

	private Connection _lastConnection = null; // do not use this variable directly -- use getConnection() instead.

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
		return _lastConnection = connectionConfig.getNamedConnection(dbInfo.connection);
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
	public DatabaseConfig(IDeprecatedSQLConfig connectionConfig)
			throws RemoteException, SQLException, InvalidParameterException
	{
		// save original db config info
		dbInfo = (DeprecatedDatabaseConfigInfo)connectionConfig.getDatabaseConfigInfo();
		if (dbInfo == null || dbInfo.schema == null || dbInfo.schema.length() == 0)
			throw new InvalidParameterException("DatabaseConfig: Schema not specified.");
		if (dbInfo.geometryConfigTable == null || dbInfo.geometryConfigTable.length() == 0)
			throw new InvalidParameterException("DatabaseConfig: Geometry metadata table name not specified.");
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
		initGeometryCollectionSQLTable();
		initAttributeColumnSQLTable();
	}

	private final String SQLTYPE_VARCHAR = "VARCHAR(256)";
	private final String SQLTYPE_LONG_VARCHAR = "VARCHAR(2048)";

	public boolean isConnectedToDatabase()
	{
		return true; // since this ISQLConfig object got past the constructor, it is connected to the database.
	}

	synchronized public DatabaseConfigInfo getDatabaseConfigInfo() throws RemoteException
	{
		return connectionConfig.getDatabaseConfigInfo();
	}

	private void initGeometryCollectionSQLTable() throws SQLException, RemoteException
	{
		// list column names
		List<String> columnNames = Arrays.asList(
				PublicMetadata.NAME, PrivateMetadata.CONNECTION, PrivateMetadata.SCHEMA, PrivateMetadata.TABLEPREFIX,
				PublicMetadata.KEYTYPE, PublicMetadata.PROJECTION, PrivateMetadata.IMPORTNOTES);

		// list corresponding column types
		List<String> columnTypes = new Vector<String>();
		for (int i = 0; i < columnNames.size(); i++)
		{
			if (columnNames.get(i).equals(PrivateMetadata.IMPORTNOTES))
				columnTypes.add(SQLTYPE_LONG_VARCHAR);
			else
				columnTypes.add(SQLTYPE_VARCHAR);
		}
		Connection conn = getConnection();
		// BACKWARDS COMPATIBILITY WITH OLD VERSION OF WEAVE
		if (SQLUtils.tableExists(conn, dbInfo.schema, dbInfo.geometryConfigTable))
		{
			try
			{
				// add column to existing table
				SQLUtils.addColumn(conn, dbInfo.schema, dbInfo.geometryConfigTable, PublicMetadata.PROJECTION, SQLTYPE_VARCHAR);
			}
			catch (SQLException e)
			{
				// we don't care if this fails -- assume the table has the column already.
			}
		}
		else
		{
			// create new table
			SQLUtils.createTable(conn, dbInfo.schema, dbInfo.geometryConfigTable, columnNames, columnTypes);
		}
		// add index on name
		try
		{
			SQLUtils.createIndex(conn, dbInfo.schema, dbInfo.geometryConfigTable, new String[]{PublicMetadata.NAME});
		}
		catch (SQLException e)
		{
			// ignore sql errors
		}
	}
	private void initAttributeColumnSQLTable() throws SQLException, RemoteException
	{
		// list column names
		List<String> columnNames = new Vector<String>();
		for (String value : IDeprecatedSQLConfig.PUBLIC_METADATA_NAMES)
			columnNames.add(value);
		columnNames.add(PrivateMetadata.CONNECTION);
		// list corresponding column types
		List<String> columnTypes = new Vector<String>();
		for (int i = 0; i < columnNames.size(); i++)
			columnTypes.add(SQLTYPE_VARCHAR);
		// add column with special type for sqlQuery
		columnNames.add(PrivateMetadata.SQLQUERY);
		columnTypes.add(SQLTYPE_LONG_VARCHAR);
		// create table
		Connection conn = getConnection();
		SQLUtils.createTable(conn, dbInfo.schema, dbInfo.dataConfigTable, columnNames, columnTypes);
		// add (possibly) missing columns
		for (String columnName : new String[]{PublicMetadata.TITLE, PublicMetadata.NUMBER, PublicMetadata.STRING})
		{
			try
			{
				// add column to existing table
				SQLUtils.addColumn(conn, dbInfo.schema, dbInfo.dataConfigTable, columnName, SQLTYPE_VARCHAR);
			}
			catch (SQLException e)
			{
				// if the column is missing, throw the error
				List<String> existingColumnNames = SQLUtils.getColumns(conn, dbInfo.schema, dbInfo.dataConfigTable);
				if (ListUtils.findIgnoreCase(columnName, existingColumnNames) < 0)
					throw new RemoteException(String.format("Unable to add column %s to config table", columnName), e);
			}
		}
		
		try
		{
			SQLUtils.createIndex(conn, dbInfo.schema, dbInfo.dataConfigTable, new String[]{PublicMetadata.NAME});
			SQLUtils.createIndex(conn, dbInfo.schema, dbInfo.dataConfigTable, new String[]{PublicMetadata.DATATABLE});
		}
		catch (SQLException e)
		{
			e.printStackTrace();
			// If the indices already exist, we don't care.
		}
	}

	// This private ISQLConfig is for managing connections because
	// the connection info shouldn't be stored in the database.
	private IDeprecatedSQLConfig connectionConfig = null;

	// these functions are just passed to the private connectionConfig
	public Document getDocument() throws RemoteException
	{
		return connectionConfig.getDocument();
	}

	public String getServerName() throws RemoteException
	{
		return connectionConfig.getServerName();
	}

	public List<String> getConnectionNames() throws RemoteException
	{
		return connectionConfig.getConnectionNames();
	}

	public String[] getGeometryCollectionNames(String connectionName) throws RemoteException
	{
		List<String> names;
		try
		{
			if (connectionName == null)
			{
				names = SQLUtils.getColumn(getConnection(), dbInfo.schema, dbInfo.geometryConfigTable, PublicMetadata.NAME);
			}
			else
			{
				Map<String, String> whereParams = new HashMap<String, String>();
				whereParams.put(PrivateMetadata.CONNECTION, connectionName);

				List<String> selectColumns = Arrays.asList(PublicMetadata.NAME);
				List<Map<String, String>> columnRecords = SQLUtils.getRecordsFromQuery(
					getConnection(), selectColumns, dbInfo.schema, dbInfo.geometryConfigTable, whereParams
				);

				HashSet<String> hashSet = new HashSet<String>();
				for (Map<String, String> mapping : columnRecords)
				{
					String geomName = mapping.get(PublicMetadata.NAME);
					hashSet.add(geomName);
				}
				names = new Vector<String>(hashSet);
			}
			Collections.sort(names, String.CASE_INSENSITIVE_ORDER);
			return names.toArray(new String[0]);
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to get GeometryCollection names", e);
		}
	}

	public String[] getDataTableNames(String connectionName) throws RemoteException
	{
		List<String> names;
		try
		{
			if (connectionName == null)
			{
				names = SQLUtils.getColumn(getConnection(), dbInfo.schema, dbInfo.dataConfigTable, PublicMetadata.DATATABLE);
				// return unique names
				names = new Vector<String>(new HashSet<String>(names));
			}
			else
			{

				Map<String, String> whereParams = new HashMap<String, String>();
				whereParams.put(PrivateMetadata.CONNECTION, connectionName);

				List<String> selectColumns = new LinkedList<String>();
				selectColumns.add(PublicMetadata.DATATABLE);
				List<Map<String, String>> columnRecords = SQLUtils.getRecordsFromQuery(
					getConnection(), selectColumns, dbInfo.schema, dbInfo.dataConfigTable, whereParams
				);

				HashSet<String> hashSet = new HashSet<String>();
				for (Map<String, String> mapping : columnRecords)
				{
					String tableName = mapping.get(PublicMetadata.DATATABLE);
					hashSet.add(tableName);
				}
				names = new Vector<String>(hashSet);
			}
			Collections.sort(names, String.CASE_INSENSITIVE_ORDER);
			return names.toArray(new String[0]);
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to get DataTable names", e);
		}
	}

	public String[] getKeyTypes() throws RemoteException
	{
		try
		{
			Connection conn = getConnection();
			List<String> dtKeyTypes = SQLUtils.getColumn(conn, dbInfo.schema, dbInfo.dataConfigTable, PublicMetadata.KEYTYPE);
			List<String> gcKeyTypes = SQLUtils.getColumn(conn, dbInfo.schema, dbInfo.geometryConfigTable, PublicMetadata.KEYTYPE);

			Set<String> uniqueValues = new HashSet<String>();
			uniqueValues.addAll(dtKeyTypes);
			uniqueValues.addAll(gcKeyTypes);
                        uniqueValues.remove(null);
			Vector<String> result = new Vector<String>(uniqueValues);
			Collections.sort(result, String.CASE_INSENSITIVE_ORDER);
			return result.toArray(new String[0]);
		}
		catch (Exception e)
		{
			throw new RemoteException(String.format("Unable to get key types"), e);
		}
	}

	public void addConnection(ConnectionInfo info) throws RemoteException
	{
		throw new RemoteException("Not implemented");
	}

	public ConnectionInfo getConnectionInfo(String connectionName) throws RemoteException
	{
		return connectionConfig.getConnectionInfo(connectionName);
	}

	public void removeConnection(String name) throws RemoteException
	{
		throw new RemoteException("Not implemented");
	}

	public void addGeometryCollection(GeometryCollectionInfo info) throws RemoteException
	{
		throw new RemoteException("Not implemented");
	}

	public void removeGeometryCollection(String name) throws RemoteException
	{
		throw new RemoteException("Not implemented");
	}

	public void removeDataTable(String name) throws RemoteException
	{
		throw new RemoteException("Not implemented");
	}

	public GeometryCollectionInfo getGeometryCollectionInfo(String geometryCollectionName) throws RemoteException
	{
		Map<String, String> params = new HashMap<String, String>();
		params.put(PublicMetadata.NAME, geometryCollectionName);
		try
		{
			List<Map<String, String>> records = SQLUtils.getRecordsFromQuery(getConnection(), dbInfo.schema, dbInfo.geometryConfigTable, params);
			if (records.size() > 0)
			{
				Map<String, String> record = records.get(0);
				GeometryCollectionInfo info = new GeometryCollectionInfo();
				info.name = record.get(PublicMetadata.NAME);
				info.connection = record.get(PrivateMetadata.CONNECTION);
				info.schema = record.get(PrivateMetadata.SCHEMA);
				info.tablePrefix = record.get(PrivateMetadata.TABLEPREFIX);
				info.keyType = record.get(PublicMetadata.KEYTYPE);
				info.projection = record.get(PublicMetadata.PROJECTION);
				info.importNotes = record.get(PrivateMetadata.IMPORTNOTES);
				return info;
			}
		}
		catch (Exception e)
		{
			throw new RemoteException(String.format("Unable to get info for GeometryCollection \"%s\"", geometryCollectionName), e);
		}
		return null;
	}

	public int addAttributeColumnInfo(AttributeColumnInfo info) throws RemoteException
	{
		throw new RemoteException("Not implemented");
	}

	public void overwriteAttributeColumnInfo(AttributeColumnInfo info) throws RemoteException
	{
		throw new RemoteException("Not implemented");
	}
	
	// shortcut for calling the Map<String,String> version of this function
	@SuppressWarnings("unchecked")
	public List<AttributeColumnInfo> getAttributeColumnInfo(String dataTableName) throws RemoteException
	{
		Map<String, String> metadataQueryParams = new HashMap<String, String>(1);
		metadataQueryParams.put(PublicMetadata.DATATABLE, dataTableName);
                AttributeColumnInfo info = new AttributeColumnInfo();
                info.publicMetadata = metadataQueryParams;
		return findAttributeColumnInfo(info);
	}

	synchronized public AttributeColumnInfo getAttributeColumnInfo(int _) throws RemoteException
	{
		throw new RemoteException("Not implemented");
	}
	synchronized public void removeAttributeColumnInfo(int _) throws RemoteException
	{
		throw new RemoteException("Not implemented");
	}
	synchronized public List<AttributeColumnInfo> findAttributeColumnInfo(AttributeColumnInfo filterinfo) throws RemoteException
	{
		Map<String, String> metadataQueryParams = new HashMap<String, String>();
		metadataQueryParams.putAll(filterinfo.privateMetadata);
		metadataQueryParams.putAll(filterinfo.publicMetadata);
		
		List<AttributeColumnInfo> results = new Vector<AttributeColumnInfo>();
		try
		{
			// get rows matching given parameters
			List<Map<String, String>> records = SQLUtils.getRecordsFromQuery(getConnection(), dbInfo.schema, dbInfo.dataConfigTable, metadataQueryParams);
			for (int i = 0; i < records.size(); i++)
			{
				Map<String, String> metadata = records.get(i);
				String geomName = metadata.remove(IDeprecatedSQLConfig.GEOMETRYCOLLECTION); // remove deprecated property from metadata
				// special case -- derive keyType from geometryCollection if keyType is missing
				if (metadata.get(PublicMetadata.KEYTYPE).length() == 0)
				{
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

					if (geomInfo != null)
						metadata.put(PublicMetadata.KEYTYPE, geomInfo.keyType);
				}
				
				Map<String, String> privateMetadata = new HashMap<String,String>();
				privateMetadata.put(PrivateMetadata.CONNECTION, metadata.remove(PrivateMetadata.CONNECTION));
				privateMetadata.put(PrivateMetadata.SQLQUERY, metadata.remove(PrivateMetadata.SQLQUERY));

				AttributeColumnInfo info = new AttributeColumnInfo();
				info.privateMetadata = privateMetadata;
				info.publicMetadata = metadata;
				
				results.add(info);
			}
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to get AttributeColumn info", e);
		}
		return results;
	}
        public void addChild(int parent, int child) throws RemoteException
        {
        }
        public void removeChild(int parent, int child) throws RemoteException
        {
        }
        public int addTag(String tagtitle) throws RemoteException
        {
            return 0;
        }
        public void removeTag(int tag_id) throws RemoteException
        {
        }
        public Collection<Integer> getChildren(Integer parent_id) throws RemoteException
        {
            return null;
        }
        public Collection<Integer> getRoots() throws RemoteException
        {
            return null;
        }
}
