/*
 * Weave (Web-based Analysis and Visualization Environment) Copyright (C) 2008-2011 University of Massachusetts Lowell This file is a part of Weave.
 * Weave is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License, Version 3, as published by the
 * Free Software Foundation. Weave is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the
 * GNU General Public License along with Weave. If not, see <http://www.gnu.org/licenses/>.
 */

package weave.config;

import java.rmi.RemoteException;
import java.security.InvalidParameterException;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
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

import weave.config.ConnectionConfig.ConnectionInfo;
import weave.config.ConnectionConfig.DatabaseConfigInfo;
import weave.config.ConnectionConfig.ImmortalConnection;
import weave.config.tables.AttributeValueTable;
import weave.config.tables.ManifestTable;
import weave.config.tables.ParentChildTable;
import weave.utils.SQLUtils;


/**
 * DatabaseConfig This class reads from an SQL database and provides an interface to retrieve strings.
 * 
 * @author Philip Kovac
 * @author Andy Dufilie
 */
public class DataConfig
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

	/* Constants for type_id */

	private DatabaseConfigInfo dbInfo = null;
	private ConnectionConfig connectionConfig = null;
	private ImmortalConnection immortalConnection = null;
	
	private AttributeValueTable public_attributes;
	private AttributeValueTable private_attributes;
	private ManifestTable manifest;
	private ParentChildTable relationships;

	/**
	 * @param connectionConfig An ISQLConfig instance that contains connection information. This is required because the connection information is not stored in the database.
	 * @param connection The name of a connection in connectionConfig to use for storing and retrieving the data configuration.
	 * @param schema The schema that the data configuration is stored in.
	 * @param geometryConfigTable The table that stores the configuration for geometry collections.
	 * @param dataConfigTable The table that stores the configuration for data tables.
	 * @throws SQLException
	 * @throws InvalidParameterException
	 */
	public DataConfig(ConnectionConfig connectionConfig)
			throws RemoteException, SQLException, InvalidParameterException
	{
		this.connectionConfig = connectionConfig;
		this.immortalConnection = new ImmortalConnection(connectionConfig);
		// test the connection now so it will throw an exception if there is a problem.
		Connection conn = immortalConnection.getConnection();

		// attempt to create the schema and tables to store the configuration.
		try
		{
			SQLUtils.createSchema(conn, dbInfo.schema);
		}
		catch (Exception e)
		{
			// do nothing if schema creation fails -- this is a temporary workaround for postgresql issue
			// e.printStackTrace();
		}
		initSQLTables();
	}
	private void initSQLTables() throws RemoteException, SQLException
	{
		public_attributes = new AttributeValueTable(immortalConnection, dbInfo.schema, table_meta_public);
		private_attributes = new AttributeValueTable(immortalConnection, dbInfo.schema, table_meta_private);	
		relationships = new ParentChildTable(immortalConnection, dbInfo.schema, table_tags);
		manifest = new ManifestTable(immortalConnection, dbInfo.schema, table_manifest);
		/* TODO: Figure out nice way to do this from within the classes. */	
        /*	SQLUtils.addForeignKey(conn, dbInfo.schema, table_meta_private, META_ID, table_manifest, MAN_ID);
		SQLUtils.addForeignKey(conn, dbInfo.schema, table_meta_public, META_ID, table_manifest, MAN_ID);*/
	}

    public Integer addEntity(int type_id, DataEntityMetadata properties, int parentId) throws RemoteException
    {
        int id = manifest.addEntry(type_id);
        if (parentId != -1)
        	relationships.addChild(id, parentId);
        if (properties != null)
            updateEntity(id, properties);
        return id;
    }
    private void removeChildren(Integer id) throws RemoteException
    {
        for (Integer child : relationships.getChildren(id))
        {
            removeEntity(child);
        }
    }
    public void removeEntity(Integer id) throws RemoteException
    {
        /* Need to delete all attributeColumns which are children of a table. */
        if (getEntity(id).type == DataEntity.TYPE_DATATABLE)
            removeChildren(id);
        manifest.removeEntry(id);
        relationships.purge(id);
        public_attributes.clearId(id);
        private_attributes.clearId(id);
    }
    public void updateEntity(Integer id, DataEntityMetadata properties) throws RemoteException
    {
        for (Entry<String,String> propval : properties.publicMetadata.entrySet())
        {
            String key = propval.getKey();
            String value = propval.getValue();
            public_attributes.setProperty(id, key, value);
        }
        for (Entry<String,String> propval : properties.privateMetadata.entrySet())
        {
            String key = propval.getKey();
            String value = propval.getValue();
            private_attributes.setProperty(id, key, value);
        }
    }
    public Collection<Integer> getEntityIdsByMetadata(DataEntityMetadata properties, Integer type_id) throws RemoteException
    {
        Set<Integer> publicmatches = null;
        Set<Integer> privatematches = null;
        Collection<Integer> matches = null;

        if (properties != null && properties.publicMetadata != null && properties.publicMetadata.size() > 0)
            publicmatches = public_attributes.filter(properties.publicMetadata);
        if (properties != null && properties.privateMetadata != null && properties.privateMetadata.size() > 0)
            privatematches = private_attributes.filter(properties.privateMetadata);
        if ((publicmatches != null) && (privatematches != null))
        {
        	// intersection
            publicmatches.retainAll(privatematches);
            matches = publicmatches;
        }
        else if (publicmatches != null)
            matches = publicmatches;
        else if (privatematches != null)
            matches = privatematches;
        else
        	matches = manifest.getByType(type_id); // all

        if (matches == null || matches.size() < 1)
        {
            return Collections.emptyList();
        }
        else
        {
            if (type_id != -1)
                matches.retainAll(manifest.getByType(type_id));
            return matches;
        }
    }
    public DataEntity getEntity(Integer id) throws RemoteException
    {
    	for (DataEntity result : getEntitiesById(Arrays.asList(id)))
    		return result;
    	return null;
    }
    public Collection<DataEntity> getEntitiesById(Collection<Integer> ids) throws RemoteException
    {
        List<DataEntity> results = new LinkedList<DataEntity>();
        Map<Integer,Integer> typeresults = manifest.getEntryTypes(ids);
        System.out.println("ids"+ids);
        System.out.println("types"+typeresults);
        Map<Integer,Map<String,String>> publicresults = public_attributes.getProperties(ids);
        Map<Integer,Map<String,String>> privateresults = private_attributes.getProperties(ids);
        if (typeresults == null)
        	return results;
        for (Integer id : ids)
        {
            Integer type = typeresults.get(id);
            DataEntity entity = new DataEntity();
            entity.id = id; 
           	entity.type = type;
            entity.publicMetadata = publicresults.get(id);
            entity.privateMetadata = privateresults.get(id);
            results.add(entity);
        }
        return results;
    }
	/* Do a recursive copy of an entity and add it to a parent. */
    public Integer copyEntity(int id, int new_parent_id) throws RemoteException
    {
        DataEntity original = getEntity(id);
        Integer copy_id;
        
        if (original.type == DataEntity.TYPE_COLUMN)
        {
        	copy_id = id;
        	relationships.addChild(copy_id, new_parent_id);
        }
        else
        {
        	Integer copy_type = original.type;
        	// copy table as category
	    	if (copy_type == DataEntity.TYPE_DATATABLE)
	    		copy_type = DataEntity.TYPE_CATEGORY;
	    	copy_id = addEntity(copy_type, original, new_parent_id);
	    	
	    	for (Integer child_id : getChildIds(id))
	    		child_id = copyEntity(child_id, copy_id);
        }
    	
        return copy_id;
    }
    public void addChild(Integer child_id, Integer parent_id) throws RemoteException
    {
    	int childType = manifest.getEntryType(child_id);
    	
    	// if the child is not a column and has parents, make a copy.
    	if (childType != DataEntity.TYPE_COLUMN && relationships.getParents(child_id).size() > 0)
    	{
    		child_id = copyEntity(child_id, parent_id);
    	}
    	
   		relationships.addChild(child_id, parent_id);
    }
    public void removeChild(Integer child_id, Integer parent_id) throws RemoteException
    {
        /* If we're trying to remove a child from a datatable, throw a wobbly. */
        if (manifest.getEntryType(parent_id) == DataEntity.TYPE_DATATABLE)
        {
            throw new RemoteException("Can't remove children from a datatable.", null);
        }
        relationships.removeChild(child_id, parent_id);
    }
    
    public Collection<Integer> getParentIds(Integer id) throws RemoteException
    {
    	return relationships.getParents(id);
    }
    
    public List<Integer> getChildIds(Integer id) throws RemoteException
    {
    	// if id is -1, we want ids of all entities without parents
        if (id == -1)
        	id = null;
        // get all children listed in the relationships table
        List<Integer> children_ids = relationships.getChildren(id);
        if (id == null)
        {
        	// get complete list of ids and remove the children appearing in the relationships table
            List<Integer> completeSet = manifest.getAll();
            completeSet.removeAll(children_ids);
            // these are the ids with no parents
            children_ids = completeSet;
        }
        return children_ids;
    }
    public Collection<String> getUniquePublicValues(String property) throws RemoteException
    {
    	return new HashSet<String>(public_attributes.getProperty(property).values());
    }
    
    
    

    
    
    
    
    
    
    
    
    
    
    ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    
    
    
    public boolean userCanModifyEntity(String connectionName, int id) throws RemoteException
    {
        ConnectionInfo connInfo = connectionConfig.getConnectionInfo(connectionName);
        if (connInfo == null)
            return false;
        if (connInfo.is_superuser)
            return true;
        DataEntity attrInfo = getEntity(id);
        return (attrInfo == null) || (attrInfo.privateMetadata.get(PrivateMetadata.CONNECTION) == connectionName);
    }
	
	static public class PrivateMetadata
	{
		static public final String CONNECTION = "connection"; // required to retrieve data from sql, not visible to client
		static public final String SQLQUERY = "sqlQuery"; // required to retrieve data from sql, not visible to client
		static public final String SQLPARAMS = "sqlParams"; // only transmitted from client to server, never stored in the database
		static public final String SQLRESULT = "sqlResult"; // only transmitted from server to client, never stored in the database
		static public final String SCHEMA = "schema"; // used for geometry column
		static public final String TABLEPREFIX = "tablePrefix"; // used for geometry column
	}
	
	static public class PublicMetadata
	{
		static public final String TITLE = "title";
		static public final String KEYTYPE = "keyType";
		static public final String DATATYPE = "dataType";
		static public final String PROJECTION = "projection";
		static public final String MIN = "min";
		static public final String MAX = "max";
		static public final String NUMBER = "number";
		static public final String STRING = "string";
	}
	
	static public class DataType
	{
		static public final String NUMBER = "number";
		static public final String STRING = "string";
		static public final String GEOMETRY = "geometry";
		
		/**
		 * This function determines the corresponding DataType constant for a SQL type defined in java.sql.Types.
		 * @param sqlType A SQL data type defined in java.sql.Types.
		 * @return The corresponding constant NUMBER or STRING.
		 */
		static public String fromSQLType(int sqlType)
		{
			switch (sqlType)
			{
			case Types.TINYINT:
			case Types.SMALLINT:
			case Types.BIGINT:
			case Types.DECIMAL:
			case Types.INTEGER:
			case Types.FLOAT:
			case Types.DOUBLE:
			case Types.REAL:
			case Types.NUMERIC:
				/* case Types.ROWID: // produces compiler error in some environments */
				return NUMBER;
			default:
				return STRING;
			}
		}
	}
	
	
	/**
	 * This class contains public and private metadata for an entity.
	 */
	static public class DataEntityMetadata
	{
	    private static final String PUBLIC_METADATA = "publicMetadata";
	    private static final String PRIVATE_METADATA = "privateMetadata";
	    
		public static DataEntityMetadata fromMap(Map<String,Map<String,String>> object)
		{
        	DataEntityMetadata dem = new DataEntityMetadata();
        	
        	if (object.get(PRIVATE_METADATA) != null)
        		dem.privateMetadata = object.get(PRIVATE_METADATA);
        	
        	if (object.get(PUBLIC_METADATA) != null)
        		dem.publicMetadata = object.get(PUBLIC_METADATA);
        	
        	return dem;
		}
		
		public Map<String,String> privateMetadata = new HashMap<String, String>();
		public Map<String,String> publicMetadata = new HashMap<String, String>();
	}
	
	static public class DataEntityWithChildren extends DataEntity
	{
		public Integer[] childIds;
		
		public DataEntityWithChildren(DataEntity base, Integer[] childIds)
		{
			if (base != null)
			{
				this.id = base.id;
				this.type = base.type;
				this.publicMetadata = base.publicMetadata;
				this.privateMetadata = base.privateMetadata;
			}
			this.childIds = childIds;
		}
	}

	/**
	 * This class contains metadata for an attributeColumn entry.
	 */
	static public class DataEntity extends DataEntityMetadata
	{
		public static final int TYPE_ANY = -1;
		public static final int TYPE_DATATABLE = 0;
		public static final int TYPE_COLUMN = 1;
		public static final int TYPE_CATEGORY = 2;
		public int id = -1;
		public int type;
        /* For cases where the config API isn't sufficient. TODO */
        public static List<DataEntity> filterEntities(Collection<DataEntity> entities, Map<String,String> params)
        {
            return filterEntities(entities, params, -1);
        }
        public static List<DataEntity> filterEntities(Collection<DataEntity> entities, Map<String,String> params, Integer manifestType)
        {
            List<DataEntity> result = new LinkedList<DataEntity>();
            for (DataEntity entity : entities)
            {
                if (manifestType != -1 && manifestType != entity.type)
                    continue;
                boolean match = true;
                for (Entry<String,String> entry : params.entrySet())
                {
                    if (params.get(entry.getKey()) != entry.getValue())
                    {
                        match = false;
                        break;
                    }
                }
                if (match)
                    result.add(entity);
            }
            return result;
        }
        public DataEntity()
        {
        }
		public String getConnectionName()
		{
			return privateMetadata.get(PrivateMetadata.CONNECTION);
		}
		
		public String getSqlQuery()
		{
			return privateMetadata.get(PrivateMetadata.SQLQUERY);
		}
		
		public String getSqlParams()
		{
			return privateMetadata.get(PrivateMetadata.SQLPARAMS);
		}
		
		@Deprecated
		public Map<String,String> getPrivateAndPublicMetadata()
		{
			Map<String,String> result = new HashMap<String, String>();
			result.putAll(privateMetadata);
			result.putAll(publicMetadata);
			return result;
		}
	}
}
