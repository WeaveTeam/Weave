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
        //private final Integer MAN_TYPE_DATATABLE = 0;
        private final Integer MAN_TYPE_COLUMN = 1;
        private final Integer MAN_TYPE_TAG = 2;

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
			// do nothing if schema creation fails -- temporary workaround for postgresql issue
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
        private void setMetadataProperty(String sqlTable, Integer id, String property, String value) throws RemoteException 
        {
        	try
        	{
        		Connection conn = getConnection();
		        
		        // to overwrite metadata, first delete then insert
		        Map<String,Object> delete_args = new HashMap<String,Object>();
		        delete_args.put(META_PROPERTY, property);
		        delete_args.put(META_ID, id);
		        SQLUtils.deleteRows(conn, dbInfo.schema, sqlTable, delete_args);
		        
		        if (value != null && value.length() > 0)
		        {
			        Map<String,Object> insert_args = new HashMap<String,Object>();
			        insert_args.put(META_PROPERTY, property);
			        insert_args.put(META_VALUE, value);
			        insert_args.put(META_ID, id);
			        SQLUtils.insertRow(conn, dbInfo.schema, sqlTable, insert_args);
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
        private Integer addEntry(Integer type_val, Map<String,String> privateMetadata, Map<String,String> publicMetadata) throws RemoteException
        {
            Integer uniq_id = null; 
            try
            {
                Connection conn = getConnection();
                
                Map<String,Object> record = new HashMap<String,Object>();
                record.put(MAN_TYPE, type_val);
                uniq_id = SQLUtils.insertRowReturnID(conn, dbInfo.schema, table_manifest, record);
                // If we made it this far, we have a new unique ID in the manifest table. Now insert the metadata.
                if (privateMetadata != null)
                	for (Entry<String,String> entry : privateMetadata.entrySet())
                		setMetadataProperty(table_meta_private, uniq_id, entry.getKey(), entry.getValue());
                if (publicMetadata != null)
                	for (Entry<String,String> entry : publicMetadata.entrySet())
                		setMetadataProperty(table_meta_public, uniq_id, entry.getKey(), entry.getValue());
            }
            catch (Exception e)
            {
                throw new RemoteException("Unable to create Weave config entry.",e);
            }
            return uniq_id;
        }
/* ** END** Private methods which handle the barebones of the entity-attribute-value system. */

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

	/**
	 * This creates an attribute column entry in the configuration.
	 * @param privateMetadata Private metadata for the attribute column.
	 * @param publicMetadata Public metadata for the attribute column.
	 * @return A new ID for the attribute column.
	 */
	public int addAttributeColumnInfo(AttributeColumnInfo info) throws RemoteException
	{
		return addEntry(MAN_TYPE_COLUMN, info.privateMetadata, info.publicMetadata);
	} 
	
	// shortcut for calling the Map<String,String> version of this function
	@SuppressWarnings("unchecked")
	public List<AttributeColumnInfo> getAttributeColumnInfo(String dataTableName) throws RemoteException
	{
		Map<String, String> metadataQueryParams = new HashMap<String, String>(1);
		metadataQueryParams.put(PublicMetadata.DATATABLE, dataTableName);
		return findAttributeColumnInfoFromPrivateAndPublicMetadata(Collections.EMPTY_MAP, metadataQueryParams);
	}
	
	public void overwriteAttributeColumnInfo(AttributeColumnInfo info) throws RemoteException
	{
		throw new RemoteException("Not implemented");
		
		//TODO if id does not exist, throw exception
		
		//TODO remove all existing metadata for specified id
		
		/*
        if (privateMetadata != null)
        	for (Entry<String,String> entry : info.privateMetadata.entrySet())
        		setMetadataProperty(table_meta_private, id, entry.getKey(), entry.getValue());
        if (publicMetadata != null)
        	for (Entry<String,String> entry : info.publicMetadata.entrySet())
        		setMetadataProperty(table_meta_public, id, entry.getKey(), entry.getValue());
		 */
	}

	/**
	 * @return A list of AttributeColumnInfo objects having info that matches the given parameters.
	 */
	public List<AttributeColumnInfo> findAttributeColumnInfoFromPrivateAndPublicMetadata(Map<String, String> privateMetadataFilter, Map<String,String> publicMetadataFilter) throws RemoteException
	{
		List<Integer> idList = getIdsFromMetadata(table_meta_public, publicMetadataFilter);
		if (privateMetadataFilter != null)
		{
			List<Integer> privateIdList = getIdsFromMetadata(table_meta_private, privateMetadataFilter);
			idList.retainAll(privateIdList); 
		}
		
		List<AttributeColumnInfo> results = new Vector<AttributeColumnInfo>();
		Map<Integer, Map<String, String>> idToPrivateMeta = getMetadataFromIds(table_meta_private, idList, null);
		Map<Integer, Map<String, String>> idToPublicMeta = getMetadataFromIds(table_meta_public, idList, null);
		for (Integer id : idList)
		{
			AttributeColumnInfo info = new AttributeColumnInfo();
			info.id = id;
			
			if (idToPrivateMeta.containsKey(id))
				info.privateMetadata = idToPrivateMeta.get(id);
			else
				info.privateMetadata = new HashMap<String,String>();
			
			if (idToPublicMeta.containsKey(id))
				info.publicMetadata = idToPublicMeta.get(id);
			else
				info.publicMetadata = new HashMap<String,String>();
			
			results.add(info); 
		}
		return results;
	}
	
	/**
	 * @return AttributeColumnInfo for a given attribute column id.
	 */
	public AttributeColumnInfo getAttributeColumnInfo(int id) throws RemoteException
	{
		List<Integer> idList = new Vector<Integer>();
		idList.add(id);
		
		Map<Integer, Map<String, String>> idToPrivateMeta = getMetadataFromIds(table_meta_private, idList, null);
		Map<Integer, Map<String, String>> idToPublicMeta = getMetadataFromIds(table_meta_public, idList, null);

		AttributeColumnInfo info = new AttributeColumnInfo();
		info.id = id;
			
		if (idToPrivateMeta.containsKey(id))
			info.privateMetadata = idToPrivateMeta.get(id);
		else
			info.privateMetadata = new HashMap<String,String>();
		
		if (idToPublicMeta.containsKey(id))
			info.publicMetadata = idToPublicMeta.get(id);
		else
			info.publicMetadata = new HashMap<String,String>();
		
		return info;
	}
	public void removeAttributeColumnInfo(int id) throws RemoteException
	{
		delEntry(id);
	}
	
        /* Code regarding the new category table and logic */
        public int addTag(String tagTitle) throws RemoteException
        {
            /* Add to the manifest. */
            Map<String,String> pubMeta = new HashMap<String,String>();
            pubMeta.put(PublicMetadata.TITLE, tagTitle);
            return addEntry(MAN_TYPE_TAG, null, pubMeta);
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
            Connection conn = null;
            Map<Integer,Boolean> entityIsCategory = new HashMap<Integer,Boolean>();
            try
            {
                conn = getConnection();
                //TODO
            }
            catch (SQLException sql_e)
            {
                throw new RemoteException("Failed to retrieve entity information.", sql_e);
            }
            return entityIsCategory;
        }
        public Map<Integer,String> getEntityTitles(Collection<Integer> id_list) throws RemoteException
        {
            List<String> properties = Arrays.asList(PublicMetadata.TITLE);
            Map<Integer,String> entityNames = new HashMap<Integer,String>();
            Map<Integer,Map<String,String>> nameMap = getMetadataFromIds(table_meta_public, id_list, properties);

            for (Entry<Integer,Map<String,String>> entry: nameMap.entrySet())
            {
                Integer id = entry.getKey();
                String name = entry.getValue().get(PublicMetadata.TITLE);
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
