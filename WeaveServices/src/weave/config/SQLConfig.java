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
	/* Table name parts */
	private final String SUFFIX_META_PRIVATE = "meta_private";
	private final String SUFFIX_META_PUBLIC = "meta_public";
        private final String SUFFIX_MANIFEST = "manifest";
        private final String SUFFIX_TAGS = "entity_tags";
	private final String WEAVE_TABLE_PREFIX = "weave_";

        /* Complete Table Names */	
	private String table_meta_private = WEAVE_TABLE_PREFIX + SUFFIX_META_PRIVATE;
	private String table_meta_public = WEAVE_TABLE_PREFIX + SUFFIX_META_PUBLIC;
        private String table_manifest = WEAVE_TABLE_PREFIX + SUFFIX_MANIFEST;
        private String table_tags = WEAVE_TABLE_PREFIX + SUFFIX_TAGS;

        /* Column Names */	
	private final String META_ID = "id";
	private final String META_PROPERTY = "property";
	private final String META_VALUE = "value";

        private final String MAN_ID = "unique_id";
        private final String MAN_TYPE = "type_id";
        
        private final String TAG_CHILD = "child_id";
        private final String TAG_PARENT = "parent_id";
        
        /* Constants for type_id */
        private final Integer MAN_TYPE_DATATABLE = 0;
        private final Integer MAN_TYPE_COLUMN = 1;
        private final Integer MAN_TYPE_TAG = 2;

        /* Constants for system-reserved properties */
        private final String META_PROPERTY_NAME = "sys_name";
        private final String META_PROPERTY_DESC = "sys_desc";

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
		
		// Manifest table
		List<String> columnNames = Arrays.asList(MAN_ID, MAN_TYPE);
		List<String> columnTypes = Arrays.asList(SQLUtils.getSerialPrimaryKeyTypeString(conn), "TINYINT UNSIGNED");
		SQLUtils.createTable(conn, dbInfo.schema, table_manifest, columnNames, columnTypes);
		
		// Metadata tables
		columnNames = Arrays.asList(META_ID, META_PROPERTY, META_VALUE);
		columnTypes = Arrays.asList("BIGINT UNSIGNED", "TEXT", "TEXT");
		SQLUtils.createTable(conn, dbInfo.schema, table_meta_private, columnNames, columnTypes);
		SQLUtils.createTable(conn, dbInfo.schema, table_meta_public, columnNames, columnTypes);
		
		SQLUtils.addForeignKey(conn, dbInfo.schema, table_meta_private, META_ID, table_manifest, MAN_ID);
		SQLUtils.addForeignKey(conn, dbInfo.schema, table_meta_public, META_ID, table_manifest, MAN_ID);
	        
                SQLUtils.createIndex(conn, dbInfo.schema, table_meta_private, table_meta_private+META_ID+META_PROPERTY, new String[]{META_ID, META_PROPERTY}, new Integer[]{0,255});
                SQLUtils.createIndex(conn, dbInfo.schema, table_meta_private, table_meta_private+META_PROPERTY+META_VALUE, new String[]{META_PROPERTY, META_VALUE}, new Integer[]{255,255});
                SQLUtils.createIndex(conn, dbInfo.schema, table_meta_public, table_meta_public+META_ID+META_PROPERTY, new String[]{META_ID, META_PROPERTY}, new Integer[]{0,255});
                SQLUtils.createIndex(conn, dbInfo.schema, table_meta_public, table_meta_public+META_PROPERTY+META_VALUE, new String[]{META_PROPERTY, META_VALUE}, new Integer[]{255,255});
	
		// Category table
		columnNames = Arrays.asList(TAG_CHILD, TAG_PARENT);
		columnTypes = Arrays.asList("BIGINT UNSIGNED", "BIGINT UNSIGNED");
		SQLUtils.createTable(conn, dbInfo.schema, table_tags, columnNames, columnTypes);
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
                    colvalpair.put(META_PROPERTY, keyValPair.getKey());
                    colvalpair.put(META_VALUE, keyValPair.getValue());
                    crossRowArgs.add(colvalpair);
                } 

                if (crossRowArgs.size() == 0)
                {
                	ids = SQLUtils.getIntColumn(conn, dbInfo.schema, table_manifest, MAN_ID);
                }
                else
                {
                	ids = SQLUtils.crossRowSelect(conn, dbInfo.schema, sqlTable, META_ID, crossRowArgs);
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
                    results = SQLUtils.idInSelect(conn, dbInfo.schema, table_meta_private, META_ID, META_PROPERTY, META_VALUE, ids, properties);
                    results2 = SQLUtils.idInSelect(conn, dbInfo.schema, table_meta_public, META_ID, META_PROPERTY, META_VALUE, ids, properties);
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
        		results = SQLUtils.idInSelect(conn, dbInfo.schema, sqlTable, META_ID, META_PROPERTY, META_VALUE, ids, properties);
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
	            delete_args.put(META_PROPERTY, property);
	            delete_args.put(META_ID, id);
	            SQLUtils.deleteRows(conn, dbInfo.schema, table, delete_args);
	            
	            if (value != null && value.length() > 0)
	            {
	            	Map<String,Object> insert_args = new HashMap<String,Object>();
	            	insert_args.put(META_PROPERTY, property);
	            	insert_args.put(META_VALUE, value);
	            	insert_args.put(META_ID, id);
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

                /* Wipe id's metadata */
                whereParams.put(META_ID, id);
                SQLUtils.deleteRows(conn, dbInfo.schema, table_meta_public, whereParams);
                SQLUtils.deleteRows(conn, dbInfo.schema, table_meta_private, whereParams);

                /* Wipe id from the manifest table. */
                whereParams.clear();
                whereParams.put(MAN_ID, id);
                SQLUtils.deleteRows(conn, dbInfo.schema, table_manifest, whereParams);
                /* Wipe id from the tag table. */
                whereParams.clear();
                whereParams.put(TAG_CHILD, id); 
                SQLUtils.deleteRows(conn, dbInfo.schema, table_tags, whereParams);
                /* Wipe id's children from the tag table. They will become uncategorized. */
                whereParams.clear();
                whereParams.put(TAG_PARENT, id);
                SQLUtils.deleteRows(conn, dbInfo.schema, table_tags, whereParams);
            }
            catch (Exception e)
            {
                throw new RemoteException("Failed to delete entry.", e);
            }
        }
        public Integer addEntry(Integer type_val, Map<String,String> properties) throws RemoteException
        {
            Integer uniq_id = null; 
            try {
                Connection conn = getConnection();
                Map<String,Object> dummyProp = new HashMap<String,Object>();
                dummyProp.put(MAN_TYPE, type_val);
                uniq_id = SQLUtils.insertRowReturnID(conn, dbInfo.schema, table_manifest, dummyProp);
                // If we made it this far, we have a new unique ID in the manifest table. Now let's build the info we need to do the necessary row inserts...
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
                geom_constraints.put(META_PROPERTY, PublicMetadata.DATATYPE);
                geom_constraints.put(META_VALUE, DataType.GEOMETRY);
                geom_ids = new HashSet<Integer>(getIdsFromMetadata(table_meta_public, geom_constraints));

                // we only want to filter by connection name if it's non-null
                if (connectionName != null)
                {
                	HashMap<String,String> conn_constraints = new HashMap<String,String>();
                	conn_constraints.put(META_PROPERTY, PrivateMetadata.CONNECTION);
                	conn_constraints.put(META_VALUE, connectionName);
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
                        whereParams.put(META_PROPERTY, "name");
                        selectColumns.add(META_VALUE);
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
                        names.add(row.get(META_VALUE));
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
                        addEntry(MAN_TYPE_COLUMN, valueMap);
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
		params.put(META_ID, id);
		try
		{
			List<Map<String, String>> records = SQLUtils.getRecordsFromQuery(getConnection(), dbInfo.schema, table_meta_public, params);
			Map<String,String> props = new HashMap<String,String>();
			for (Map<String,String> row : records)
			{
                            String property_name = row.get(META_PROPERTY);
                            String value = row.get(META_VALUE);
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
                addEntry(MAN_TYPE_COLUMN, info.getAllMetadata());
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
        public int addTag(String tagTitle) throws RemoteException
        {
            Connection conn;
            int id;
            try
            {
                /* Add to the manifest. */
                Map<String,String> attrs = new HashMap<String,String>();
                conn = getConnection();

                attrs.put(META_PROPERTY_NAME, tagTitle);
                id = addEntry(MAN_TYPE_TAG, attrs);
            }
            catch (SQLException sql_e)
            {
                throw new RemoteException(String.format("Failed to add category %s.", tagTitle), sql_e);
            }
            return id;
        }
        public void addChild(int parent, int child) throws RemoteException
        {
            Connection conn;
            Map<String,Object> columns = new HashMap<String,Object>();
            columns.put(TAG_PARENT, parent);
            columns.put(TAG_CHILD, child);
            try
            {
                conn = getConnection();
                SQLUtils.insertRow(conn, dbInfo.schema, table_tags, columns);
            }
            catch (SQLException sql_e)
            {
                throw new RemoteException(String.format("Failed to add child %d to %d.", child, parent), sql_e);
            }
            return;
        }
        public void removeChild(int parent, int child) throws RemoteException
        {
            Connection conn;
            Map<String,Object> columns = new HashMap<String,Object>();
            columns.put(TAG_PARENT, parent);
            columns.put(TAG_CHILD, child);
            try
            {
                conn = getConnection();
                SQLUtils.deleteRows(conn, dbInfo.schema, table_tags, columns);
            }
            catch (SQLException sql_e)
            {
                throw new RemoteException(String.format("Failed to remove child %d from %d.", child, parent), sql_e);
            }
            return;
        }
        public Map<Integer,Boolean> getEntityIsCategory(Collection<Integer> id_list) throws RemoteException
        {
            Connection conn;
            Map<Integer,Boolean> entityIsCategory = new HashMap<Integer,Boolean>();
            try
            {
                SQLResult sqlres;
                conn = getConnection();
            }
            catch (SQLException sql_e)
            {
                throw new RemoteException("Failed to retrieve entity information.", sql_e);
            }
            return entityIsCategory;
        }
        public Map<Integer,String> getEntityName(Collection<Integer> id_list) throws RemoteException
        {
            List<String> meta = Arrays.asList(META_PROPERTY_NAME);
            Map<Integer,String> entityNames = new HashMap<Integer,String>();
            Map<Integer,Map<String,String>> nameMap = getAllMetadata(id_list, meta);

            for (Entry<Integer,Map<String,String>> entry: nameMap.entrySet())
            {
                Integer id = entry.getKey();
                String name = entry.getValue().get(META_PROPERTY_NAME);
                entityNames.put(id, name);
            }
            return entityNames;
        }
        public Collection<Integer> getChildren(Integer parent_id) throws RemoteException
        {
            Connection conn;
            Map<String,Object> query = new HashMap<String,Object>();
            List<String> columns = new LinkedList<String>();
            List<Integer> children = new LinkedList<Integer>();
            columns.add(TAG_CHILD);
            query.put(TAG_PARENT, parent_id);

            try
            {
                List<Map<String,String>> results;
                conn = getConnection();
                results = SQLUtils.getRecordsFromQuery(conn, columns, dbInfo.schema, table_tags, query);
                for (Map<String,String> row : results)
                {
                    children.add(Integer.parseInt(row.get(TAG_CHILD)));
                }
            }
            catch (SQLException sql_e)
            {
                throw new RemoteException("Failed to retrieve all categories.", sql_e);
            }
            return children;
        }
        public Collection<Integer> getRoots() throws RemoteException
        {
            Collection<Integer> roots = new LinkedList<Integer>();
            Set<Integer> manifest_ids;
            Set<Integer> child_ids;
            Connection conn;
            try
            {
                conn = getConnection();

                child_ids = new HashSet<Integer>(SQLUtils.getIntColumn(conn, dbInfo.schema, table_tags, TAG_CHILD));
                manifest_ids = new HashSet<Integer>(SQLUtils.getIntColumn(conn, dbInfo.schema, table_manifest, MAN_ID));
                
                manifest_ids.removeAll(child_ids);

            }
            catch (SQLException sql_e)
            {
                throw new RemoteException("Failed to retrieve all categories.", sql_e); 
            }
            return manifest_ids;
        }
}
