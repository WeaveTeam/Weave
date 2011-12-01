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

import weave.config.SQLConfigUtils.InvalidParameterException;
import weave.utils.SQLUtils;
import weave.utils.SQLResult;

/**
 * DatabaseConfig This class reads from an SQL database and provides an interface to retrieve strings.
 * 
 * @author Philip Kovac
 * @author Andy Dufilie
 */
public class SQLConfig
		implements ISQLConfig
{
//	private final String SQLTYPE_VARCHAR = "VARCHAR(256)";
//	private final String SQLTYPE_LONG_VARCHAR = "VARCHAR(2048)";
//	private final String SQLTYPE_INT = "INT";
	
	private final String SUFFIX_DESC = "attr_desc";
	private final String SUFFIX_META_PRIVATE = "attr_meta_private";
	private final String SUFFIX_META_PUBLIC = "attr_meta_public";
	private final String SUFFIX_HIERARCHY = "hierarchy";
        private final String SUFFIX_CATEGORIES = "categories";
	private final String WEAVE_TABLE_PREFIX = "weave_";
	
	private final String ID = "id";
        private final String NAME = "name";
	private final String DESCRIPTION = "description";
	private final String PROPERTY = "property";
	private final String VALUE = "value";
        private final String PARENT_ID = "parent_id";
	
	private String table_desc = WEAVE_TABLE_PREFIX + SUFFIX_DESC;
	private String table_meta_private = WEAVE_TABLE_PREFIX + SUFFIX_META_PRIVATE;
	private String table_meta_public = WEAVE_TABLE_PREFIX + SUFFIX_META_PUBLIC;
        private String table_categories = WEAVE_TABLE_PREFIX + SUFFIX_CATEGORIES;
	
	private DatabaseConfigInfo dbInfo = null;
	private ISQLConfig connectionConfig = null;
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
		return _lastConnection = SQLConfigUtils.getConnection(connectionConfig, dbInfo.connection);
	}

	/**
	 * @param connectionConfig An ISQLConfig instance that contains connection information. This is required because the connection information is not stored in the database.
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
		List<String> columnNames = Arrays.asList(ID, DESCRIPTION);
		List<String> columnTypes = Arrays.asList(SQLUtils.getSerialPrimaryKeyTypeString(conn), "TEXT");
		SQLUtils.createTable(conn, dbInfo.schema, table_desc, columnNames, columnTypes);
		
		// Metadata tables
		columnNames = Arrays.asList(ID, PROPERTY, VALUE);
		columnTypes = Arrays.asList("BIGINT UNSIGNED", "TEXT", "TEXT");
		SQLUtils.createTable(conn, dbInfo.schema, table_meta_private, columnNames, columnTypes);
		SQLUtils.createTable(conn, dbInfo.schema, table_meta_public, columnNames, columnTypes);
		
		SQLUtils.addForeignKey(conn, dbInfo.schema, table_meta_private, ID, table_desc, ID);
		SQLUtils.addForeignKey(conn, dbInfo.schema, table_meta_public, ID, table_desc, ID);
		
		// Category table
		columnNames = Arrays.asList(ID, NAME, PARENT_ID);
		columnTypes = Arrays.asList(SQLUtils.getSerialPrimaryKeyTypeString(conn), "TEXT", "BIGINT UNSIGNED");
		SQLUtils.createTable(conn, dbInfo.schema, table_categories, columnNames, columnTypes);
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
        private List<Integer> getIdsFromMetadata(String sqlTable, Map<String,String> constraints) throws RemoteException
        {
            List<Integer> ids = new LinkedList<Integer>();
            try
            {
                Connection conn = getConnection();
                List<Map<String,String>> crossRowArgs = new LinkedList<Map<String,String>>();
                for (Entry<String,String> keyValPair : constraints.entrySet())
                {
                    Map<String,String> colvalpair = new HashMap<String,String>();
                    colvalpair.put(PROPERTY, keyValPair.getKey());
                    colvalpair.put(VALUE, keyValPair.getValue());
                    crossRowArgs.add(colvalpair);
                } 

                if (crossRowArgs.size() == 0)
                {
                	ids = SQLUtils.getIntColumn(conn, dbInfo.schema, table_desc, ID);
                }
                else
                {
                	ids = SQLUtils.crossRowSelect(conn, dbInfo.schema, sqlTable, ID, crossRowArgs);
                }
            }
            catch (SQLException e)
            {
                throw new RemoteException("Unable to get IDs from property table.", e);
            }
            return ids;
        }
        /**
         * @param ids List of IDs to be queried
         * @param properties A list of metadata property names to return
         * @return A map of the requested IDs to maps of property names to values
         * @throws RemoteException
         */
        @Deprecated
        private Map<Integer,Map<String,String>> getAllMetadata(Collection<Integer> ids, Collection<String> properties) throws RemoteException
        {
                Map<Integer,Map<String,String>> results;
                Map<Integer,Map<String,String>> results2;
                try 
                {
                    Connection conn = getConnection();
                    results = SQLUtils.idInSelect(conn, dbInfo.schema, table_meta_private, ID, PROPERTY, VALUE, ids, properties);
                    results2 = SQLUtils.idInSelect(conn, dbInfo.schema, table_meta_public, ID, PROPERTY, VALUE, ids, properties);
                    results.putAll(results2);
                }
                catch (Exception e)
                {
                    throw new RemoteException("Failed to get properties.", e);
                }
                return results; 
        }
        private Map<Integer,Map<String,String>> getMetadataFromIds(String sqlTable, Collection<Integer> ids, Collection<String> properties) throws RemoteException
        {
        	Map<Integer,Map<String,String>> results;
        	try 
        	{
        		Connection conn = getConnection();
        		results = SQLUtils.idInSelect(conn, dbInfo.schema, sqlTable, ID, PROPERTY, VALUE, ids, properties);
        	}
        	catch (Exception e)
        	{
        		throw new RemoteException("Failed to get properties.", e);
        	}
        	return results; 
        }
        private void setProperty(Integer id, String property, String value) throws RemoteException 
        {
            try {
	            Connection conn = getConnection();
	            String table = null;
	            if (PrivateMetadata.isPrivate(property))
	            	table = table_meta_private;
	            else
	            	table = table_meta_public;
	            
	            // to overwrite metadata, first delete then insert
	            Map<String,Object> delete_args = new HashMap<String,Object>();
	            delete_args.put(PROPERTY, property);
	            delete_args.put(ID, id);
	            SQLUtils.deleteRows(conn, dbInfo.schema, table, delete_args);
	            
	            if (value != null && value.length() > 0)
	            {
	            	Map<String,Object> insert_args = new HashMap<String,Object>();
	            	insert_args.put(PROPERTY, property);
	            	insert_args.put(VALUE, value);
	            	insert_args.put(ID, id);
	            	SQLUtils.insertRow(conn, dbInfo.schema, table, insert_args);
	            }
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
                whereParams.put(ID, id);
                SQLUtils.deleteRows(conn, dbInfo.schema, table_meta_public, whereParams);
                SQLUtils.deleteRows(conn, dbInfo.schema, table_meta_private, whereParams);
                SQLUtils.deleteRows(conn, dbInfo.schema, table_desc, whereParams);
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
                dummyProp.put(DESCRIPTION, description);
                uniq_id = SQLUtils.insertRowReturnID(conn, dbInfo.schema, table_desc, dummyProp);
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
                Set<Integer> geom_ids = null;
                Set<Integer> conn_ids = null;

                HashMap<String,String> geom_constraints = new HashMap<String,String>();
                geom_constraints.put(PROPERTY, PublicMetadata.DATATYPE);
                geom_constraints.put(VALUE, DataType.GEOMETRY);
                geom_ids = new HashSet<Integer>(getIdsFromMetadata(table_meta_public, geom_constraints));

                // we only want to filter by connection name if it's non-null
                if (connectionName != null)
                {
                	HashMap<String,String> conn_constraints = new HashMap<String,String>();
                	conn_constraints.put(PROPERTY, PrivateMetadata.CONNECTION);
                	conn_constraints.put(VALUE, connectionName);
                	conn_ids = new HashSet<Integer>(getIdsFromMetadata(table_meta_private, conn_constraints));
                	geom_ids.retainAll(conn_ids);
                }
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
                        String fromTable = table_meta_public;
                        Map<String,Object> whereParams = new HashMap<String,Object>();
                        whereParams.put(PROPERTY, "name");
                        selectColumns.add(VALUE);
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
                        names.add(row.get(VALUE));
                    }
                }
                return names; 
	}

	public List<String> getKeyTypes() throws RemoteException
	{
		try
		{
			Connection conn = getConnection();
			List<String> dtKeyTypes = SQLUtils.getColumn(conn, dbInfo.schema, dbInfo.dataConfigTable, PublicMetadata.KEYTYPE);
			List<String> gcKeyTypes = SQLUtils.getColumn(conn, dbInfo.schema, dbInfo.geometryConfigTable, PublicMetadata.KEYTYPE);

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
			
			// private metadata
			valueMap.put(PrivateMetadata.CONNECTION, info.connection);
			valueMap.put(PrivateMetadata.SCHEMA, info.schema);
			valueMap.put(PrivateMetadata.TABLEPREFIX, info.tablePrefix);
			
			// public metadata
			valueMap.put(PublicMetadata.NAME, info.name);
			valueMap.put(PublicMetadata.KEYTYPE, info.keyType);
			valueMap.put(PublicMetadata.PROJECTION, info.projection);
			valueMap.put(PublicMetadata.DATATYPE, DataType.GEOMETRY);
			
			String description = info.importNotes;
            addEntry(description, valueMap);
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
        ids = getIdsFromMetadata(table_meta_public, whereParams);
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
                attribParams.put(PublicMetadata.NAME, geometryCollectionName);
                attribParams.put(PublicMetadata.DATATYPE, DataType.GEOMETRY);
                List<Integer> idlist = getIdsFromMetadata(table_meta_public, attribParams);
                return getGeometryCollectionInfo(idlist.get(0));
        }
	public GeometryCollectionInfo getGeometryCollectionInfo(Integer id) throws RemoteException
	{
		Map<String, Object> params = new HashMap<String, Object>();
		GeometryCollectionInfo info = new GeometryCollectionInfo();
		params.put(ID, id);
		try
		{
			List<Map<String, String>> records = SQLUtils.getRecordsFromQuery(getConnection(), dbInfo.schema, table_meta_public, params);
			Map<String,String> props = new HashMap<String,String>();
			for (Map<String,String> row : records)
			{
                String property_name = row.get(PROPERTY);
                String value = row.get(VALUE);
                props.put(property_name, value);
			}
			// public meta
			info.name = props.get(PublicMetadata.NAME);
			info.keyType = props.get(PublicMetadata.KEYTYPE);
			info.projection = props.get(PublicMetadata.PROJECTION);
			
			// private meta
			info.connection = props.get(PrivateMetadata.CONNECTION);
			info.schema = props.get(PrivateMetadata.SCHEMA);
			info.tablePrefix = props.get(PrivateMetadata.TABLEPREFIX);
			info.importNotes = props.get(PrivateMetadata.IMPORTNOTES);
		}
		catch (Exception e)
		{
			throw new RemoteException(String.format("Unable to get info for GeometryCollection \"%d\"", id), e);
		}
		return info;
	}

	/**
	 * This is a legacy interface for adding an attribute column. The id and description fields of the info object are not used.
	 */
	public void addAttributeColumn(AttributeColumnInfo info) throws RemoteException
	{
		// prepare the description of the column
		String dataTable = info.publicMetadata.get(PublicMetadata.DATATABLE);
		String name = info.publicMetadata.get(PublicMetadata.NAME);
		String description = String.format("dataTable = \"%s\", name = \"%s\"", dataTable, name);
		String year = info.publicMetadata.get(PublicMetadata.YEAR);
		if (year != null && year.length() > 0)
			description += String.format(", year = \"%s\"", year);
        // insert all the info into the sql table
        addEntry(description, info.getAllMetadata());
	}

	// shortcut for calling the Map<String,String> version of this function
	public List<AttributeColumnInfo> getAttributeColumnInfo(String dataTableName) throws RemoteException
	{
		Map<String, String> metadataQueryParams = new HashMap<String, String>(1);
		metadataQueryParams.put(PublicMetadata.DATATABLE, dataTableName);
		return getAttributeColumnInfo(metadataQueryParams);
	}

	/**
	 * @return A list of AttributeColumnInfo objects having info that matches the given parameters.
	 */
	public List<AttributeColumnInfo> getAttributeColumnInfo(Map<String, String> metadataQueryParams) throws RemoteException
	{
		List<AttributeColumnInfo> results = new Vector<AttributeColumnInfo>();
        Map<Integer,Map<String,String>> attr_cols;
        List<Integer> col_ids = getIdsFromMetadata(table_meta_public, metadataQueryParams); 
        attr_cols = getAllMetadata(col_ids, null);
		for (Entry<Integer,Map<String,String>> entry : attr_cols.entrySet())
			results.add(new AttributeColumnInfo(entry.getKey(), null, entry.getValue()));
		return results;
	}
        /* Code regarding the new category table and logic */
        public void setAttributeColumnParent(int col_id, int parent_id) throws RemoteException
        {
            setProperty(col_id, PARENT_ID, String.format("%d", parent_id));
        }
        public int addCategory(String category) throws RemoteException
        {
            return addCategory(category, null);
        }
        public int addCategory(String category, Integer parent) throws RemoteException
        {
            Connection conn;
            int id; 
            try
            {
                Map<String,Object> row = new HashMap<String,Object>();
                row.put(NAME, category);
                row.put(PARENT_ID, parent);

                conn = getConnection();
                id = SQLUtils.insertRowReturnID(conn, dbInfo.schema, table_categories, row);
            }
            catch (SQLException sql_e)
            {
                throw new RemoteException(String.format("Failed to add category %s.", category), sql_e);
            }
            return id;
        }
        public void setCategoryParent(int child_id, int parent_id) throws RemoteException
        {
            Connection conn;
            try 
            {
                conn = getConnection();
                Map<String,Object> row = new HashMap<String,Object>();
                Map<String,Object> whereParams = new HashMap<String,Object>();
                whereParams.put(ID, child_id);
                row.put(PARENT_ID, parent_id);
                SQLUtils.updateRows(conn, dbInfo.schema, table_categories, whereParams, row);
            }
            catch (SQLException sql_e)
            {
                throw new RemoteException(String.format("Failed to set child %d's parent as %d.", child_id, parent_id), sql_e);
            }
        }
        public Collection<Integer> getChildColumns(int parent_id) throws RemoteException
        {
            Map<String,String> query = new HashMap<String,String>();

            query.put(PARENT_ID, (new Integer(parent_id)).toString());
            return getIdsFromMetadata(table_categories, query);
        }
        public Map<Integer,String> getCategories() throws RemoteException
        {
            return getChildCategories(-1);
        }
        public Map<Integer,String> getChildCategories(int parent_id) throws RemoteException
        {
            Connection conn;
            Map<Integer,String> children = new HashMap<Integer,String>();
            Map<String,Object> whereParams = new HashMap<String,Object>();
            List<String> columns = Arrays.asList(ID, NAME, PARENT_ID);
            try
            {
                SQLResult sqlres;
                conn = getConnection();
                if (parent_id > -1)
                {
                    whereParams.put("parent", parent_id);
                }
                sqlres = SQLUtils.getRowSetFromQuery(conn, columns, dbInfo.schema, table_categories, whereParams);
                for (Object[] row : sqlres.rows)
                {
                    int id = SQLResult.objAsInt(row[0]);
                    String name = SQLResult.objAsString(row[1]);
                    children.put(id, name);
                }
            }
            catch (SQLException sql_e)
            {
                throw new RemoteException(String.format("Failed to retrieve children of parent %d.", parent_id), sql_e); 
            }
            return children;
        }
}
