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
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.Vector;

import org.w3c.dom.Document;

import weave.config.ISQLConfig.AttributeColumnInfo.Metadata;
import weave.config.SQLConfigUtils.InvalidParameterException;
import weave.utils.SQLUtils;

/**
 * DatabaseConfig This class reads from an SQL database and provides an interface to retrieve strings.
 * 
 * @author Andrew Wilkinson
 * @author Andy Dufilie
 * @author Philip Kovac
 */

/**
 * @author Andy
 *
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
        public boolean isConnectedToDatabase()
        {
                return true;
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
/* Private methods which handle the barebones of the entity-attribute-value system. */
        private List<Integer> getFromKeyVals(Map<String,String> constraints) throws RemoteException
        {
            return getFromKeyValsForTable(sqltable_public, constraints);
        }
        private List<Integer> getFromKeyValsForTable(String table, Map<String,String> constraints) throws RemoteException
        {
            List<Integer> ids = new LinkedList<Integer>();
            try
            {
                Connection conn = getConnection();
                List<Map<String,String>> crossRowArgs = new LinkedList<Map<String,String>>();
                for (Entry<String,String> keyValPair : constraints.entrySet())
                {
                    Map<String,String> colvalpair = new HashMap<String,String>();
                    colvalpair.put("property", keyValPair.getKey());
                    colvalpair.put("value", keyValPair.getValue());
                    crossRowArgs.add(colvalpair);
                } 

                ids = SQLUtils.crossRowSelect(conn, dbInfo.schema, table, "id", crossRowArgs);
            }
            catch (SQLException e)
            {
                throw new RemoteException("Unable to get IDs from property table.", e);
            }
            return ids;
        }
        /**
         * @param id ID of an attribute column
         * @param properties A list of metadata property names to return
         * @return A map of the requested property names to values
         * @throws RemoteException
         */
        private Map<String,String> getProperties(Integer id, Collection<String> properties) throws RemoteException
        {
            List<Integer> ids = new LinkedList<Integer>();
            Map<Integer,Map<String,String>> retval;
            ids.add(id);
            retval = getProperties(ids, properties);
            return retval.get(id);
        }
        private Map<Integer,Map<String,String>> getProperties(Collection<Integer> ids, Collection<String> properties) throws RemoteException
        {
                Map<Integer,Map<String,String>> results;
                try 
                {
                    Connection conn = getConnection();
                    results =      SQLUtils.idInSelect(conn, sqltable_private, "id", "property", "value", ids, properties);
                    results.putAll(SQLUtils.idInSelect(conn, sqltable_public, "id", "property", "value", ids, properties));
                }
                catch (Exception e)
                {
                    throw new RemoteException("Failed to get properties.", e);
                }
                return results; 
        }
        private static boolean isPublicProperty(String property)
        {
            return !(property.equals("connection") || property.equals("sqlQuery") || property.equals("tablePrefix") || property.equals("tablePrefix"));
/*
            switch (property)
            {
                case "connection":
                    return false;
                case "sqlQuery":
                    return false;
                case "tablePrefix":
                    return false;
                default:
                    return true;
            }
*/
        }
        private void setProperty(Integer id, String property, String value) throws RemoteException 
        {
            try {
            Connection conn = getConnection();
            String table = null;
            Map<String,Object> insert_args = new HashMap<String,Object>();
            insert_args.put("property", property);
            insert_args.put("value", value);
            insert_args.put("id", id);
            Map<String,Object> delete_args = new HashMap<String,Object>();
            delete_args.put("property", property);
            delete_args.put("id", id);
            if (isPublicProperty(property)) /* TODO: Add check for private-only keys here */
            {
                table = sqltable_public;
            }
            else
            {
                table = sqltable_private;
            }
            SQLUtils.deleteRows(conn, dbInfo.schema, table, delete_args);
            SQLUtils.insertRow(conn, dbInfo.schema, table, insert_args);
            }
            catch (Exception e)
            {
                throw new RemoteException("Failed to set property.", e);
            }
        }
        private void delEntry(Integer id) throws RemoteException
        {
            try {
                Connection conn = getConnection();
                Map<String,Object> whereParams = new HashMap<String,Object>();
                whereParams.put("id", id);
                SQLUtils.deleteRows(conn, dbInfo.schema, sqltable_public, whereParams);
                SQLUtils.deleteRows(conn, dbInfo.schema, sqltable_private, whereParams);
                SQLUtils.deleteRows(conn, dbInfo.schema, sqltable_desc, whereParams);
            }
            catch (Exception e)
            {
                throw new RemoteException("Failed to delete entry.", e);
            }
        }
        public Integer addEntry(String description, Map<String,String> properties) throws RemoteException
        {
            Integer uniq_id = null; 
            try {
                Connection conn = getConnection();
                Map<String,Object> dummyProp = new HashMap<String,Object>();
                dummyProp.put("description", description);
                uniq_id = SQLUtils.insertRowReturnID(conn, dbInfo.schema, sqltable_desc, dummyProp);
                // If we made it this far, we have a new unique ID in the description table. Now let's build the info we need to do the necessary row inserts...
                for (Entry<String,String> keyvalpair : properties.entrySet())
                {
                    String key = keyvalpair.getKey();
                    String val = keyvalpair.getValue();
                    setProperty(uniq_id, key, val);
                } 
            }
            catch (Exception e)
            {
                throw new RemoteException("Unable to insert description item.",e);
            }
            return uniq_id;
        }
/* ** END** Private methods which handle the barebones of the entity-attribute-value system. */
	public List<String> getGeometryCollectionNames(String connectionName) throws RemoteException
	{
            List<String> names = new LinkedList<String>();
            try
            {
                HashMap<String,String> geom_constraints = new HashMap<String,String>();
                Set<Integer> geom_ids = null;
                Set<Integer> conn_ids = null;

                geom_constraints.put("property", "dataType");
                geom_constraints.put("value", "geometry");
                geom_ids = new HashSet<Integer>(getFromKeyVals(geom_constraints));

                if (connectionName != null)
                {
                    HashMap<String,String> conn_constraints = new HashMap<String,String>();

                    conn_constraints.put("property", "connection");
                    conn_constraints.put("value", connectionName);

                    conn_ids = new HashSet<Integer>(getFromKeyVals(conn_constraints));
                    geom_ids.retainAll(conn_ids);
                }
                // TODO 
            }
            catch (Exception e)
            {
                throw new RemoteException("Unable to get GeometryCollection names", e);
            }
            return names;
	}

	public List<String> getDataTableNames(String connectionName) throws RemoteException
	{
		List<String> names = new LinkedList<String>();
        List<Map<String,String>> results = null;
		try
		{
                        Connection conn = getConnection();
                        List<String> selectColumns = new LinkedList<String>();
                        String fromSchema = dbInfo.schema;
                        String fromTable = sqltable_public;
                        Map<String,Object> whereParams = new HashMap<String,Object>();
                        whereParams.put("property", "name");
                        selectColumns.add("value");
                        results = SQLUtils.getRecordsFromQuery(conn, selectColumns, fromSchema, fromTable, whereParams);
                        
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to get DataTable names", e);
		}
                if (results != null)
                {
                    for (Map<String,String> row : results)
                    {
                        names.add(row.get("value"));
                    }
                }
                return names; 
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
			Map<String, String> valueMap = new HashMap<String, String>();
			valueMap.put(GeometryCollectionInfo.NAME, info.name);
			valueMap.put(GeometryCollectionInfo.CONNECTION, info.connection);
			valueMap.put(GeometryCollectionInfo.SCHEMA, info.schema);
			valueMap.put(GeometryCollectionInfo.TABLEPREFIX, info.tablePrefix);
			valueMap.put(GeometryCollectionInfo.KEYTYPE, info.keyType);
			valueMap.put(GeometryCollectionInfo.PROJECTION, info.projection);
			valueMap.put(GeometryCollectionInfo.IMPORTNOTES, info.importNotes);
            addEntry(info.importNotes, valueMap);
			/*
			SQLUtils.insertRow(getConnection(), dbInfo.schema, dbInfo.geometryConfigTable, valueMap);
			*/
		}
		catch (Exception e)
		{
			throw new RemoteException(String.format("Unable to add GeometryCollection \"%s\"", info.name), e);
		}
	}

	public void removeGeometryCollection(String name) throws RemoteException
	{
        List<Integer> ids;
		Map<String,String> whereParams = new HashMap<String,String>();
		whereParams.put("name", name);
        ids = getFromKeyVals(whereParams);
        for (Integer id : ids)
        {
            delEntry(id);
        }
	}

	public void removeDataTable(String name) throws RemoteException
	{
                //TODO Seems right, but doesn't seem right. Double check with andy.
		try
		{
                    removeGeometryCollection(name); // Same deal.
		}
		catch (RemoteException e)
		{
			throw new RemoteException(String.format("Unable to remove DataTable \"%s\"", name), e);
		}
	}
        public GeometryCollectionInfo getGeometryCollectionInfo(String geometryCollectionName) throws RemoteException
        {
                Map<String,String> attribParams =  new HashMap<String,String>();
                attribParams.put("name", geometryCollectionName);
                attribParams.put("dataType", "geometry");
                List<Integer> idlist = getFromKeyVals(attribParams);
                return getGeometryCollectionInfo(idlist.get(0));
        }
	public GeometryCollectionInfo getGeometryCollectionInfo(Integer id) throws RemoteException
	{
		Map<String, Object> params = new HashMap<String, Object>();
		GeometryCollectionInfo info = new GeometryCollectionInfo();
		params.put("id", id);
		try
		{
			List<Map<String, String>> records = SQLUtils.getRecordsFromQuery(getConnection(), dbInfo.schema, sqltable_public, params);
                        Map<String,String> props = new HashMap<String,String>();
			for (Map<String,String> row : records)
			{
                                String property_name = row.get("property");
                                String value = row.get("value");
                                props.put(property_name, value);
			}
			info.name = props.get(GeometryCollectionInfo.NAME);
			info.connection = props.get(GeometryCollectionInfo.CONNECTION);
			info.schema = props.get(GeometryCollectionInfo.SCHEMA);
			info.tablePrefix = props.get(GeometryCollectionInfo.TABLEPREFIX);
			info.keyType = props.get(GeometryCollectionInfo.KEYTYPE);
			info.projection = props.get(GeometryCollectionInfo.PROJECTION);
			info.importNotes = props.get(GeometryCollectionInfo.IMPORTNOTES);
		}
		catch (Exception e)
		{
			throw new RemoteException(String.format("Unable to get info for GeometryCollection \"%d\"", id), e);
		}
		return info;
	}

	public void addAttributeColumn(AttributeColumnInfo info) throws RemoteException
	{
		// make a copy of the metadata and add the sql info
		Map<String, String> valueMap = new HashMap<String, String>(info.metadata);
        valueMap.put(AttributeColumnInfo.SQLQUERY, info.sqlQuery);
        String desc = valueMap.get("desc"); // TODO: Change to AttributeColumnInfo.SQLQUERY when appropriate.
        addEntry(desc, valueMap);
		// insert all the info into the sql table
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
        Map<Integer,Map<String,String>> attr_cols;
        List<Integer> col_ids = getFromKeyVals(metadataQueryParams);
        attr_cols = getProperties(col_ids, null);
		for (Map<String,String> metadata : attr_cols.values())
		{
			String connection = metadata.remove(AttributeColumnInfo.CONNECTION);
			String sqlQuery = metadata.remove(AttributeColumnInfo.SQLQUERY);

			// special case -- derive keyType from geometryCollection if
			// keyType is missing
			if (metadata.get(Metadata.KEYTYPE.toString()).length() == 0)
			{
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

				if (geomInfo != null)
					metadata.put(Metadata.KEYTYPE.toString(), geomInfo.keyType);
			}
			results.add(new AttributeColumnInfo(connection, sqlQuery, metadata));
		}
		return results;
	}
}
