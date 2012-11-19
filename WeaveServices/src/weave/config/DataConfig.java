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
import java.util.Vector;

import weave.config.ConnectionConfig.DatabaseConfigInfo;
import weave.config.tables.MetadataTable;
import weave.config.tables.ManifestTable;
import weave.config.tables.HierarchyTable;
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
	static private final String SUFFIX_META_PRIVATE = "_meta_private";
	static private final String SUFFIX_META_PUBLIC = "_meta_public";
	static private final String SUFFIX_MANIFEST = "_manifest";
	static private final String SUFFIX_HIERARCHY = "_hierarchy";
	
	static public final int NULL = -1;

	private MetadataTable public_metadata;
	private MetadataTable private_metadata;
	private ManifestTable manifest;
	private HierarchyTable hierarchy;
	private ConnectionConfig connectionConfig;
	private long lastModified = 0L;

	public DataConfig(ConnectionConfig connectionConfig) throws RemoteException
	{
		this.connectionConfig = connectionConfig;
		detectChange();
	}
	
	private void detectChange() throws RemoteException
	{
		long lastMod = connectionConfig.getLastModified();
		if (this.lastModified < lastMod)
		{
			if (!connectionConfig.allowDataConfigInitialize())
				throw new RemoteException("The Weave server has not been initialized yet.  Please run the Admin Console before continuing.");
			
			try
			{
				// test the connection now so it will throw an exception if there is a problem.
				Connection conn = connectionConfig.getAdminConnection();
				
				// attempt to create the schema and tables to store the configuration.
				DatabaseConfigInfo dbInfo = connectionConfig.getDatabaseConfigInfo();
				try
				{
					SQLUtils.createSchema(conn, dbInfo.schema);
				}
				catch (Exception e)
				{
					// do nothing if schema creation fails -- this is a temporary workaround for postgresql issue
					// e.printStackTrace();
				}
				
				// init SQL tables
				String tablePrefix = "weave";
				String table_meta_private = tablePrefix + SUFFIX_META_PRIVATE;
				String table_meta_public = tablePrefix + SUFFIX_META_PUBLIC;
				String table_manifest = tablePrefix + SUFFIX_MANIFEST;
				String table_tags = tablePrefix + SUFFIX_HIERARCHY;
				
				manifest = new ManifestTable(connectionConfig, dbInfo.schema, table_manifest);
				hierarchy = new HierarchyTable(connectionConfig, dbInfo.schema, table_tags, manifest);
				private_metadata = new MetadataTable(connectionConfig, dbInfo.schema, table_meta_private, manifest);
				public_metadata = new MetadataTable(connectionConfig, dbInfo.schema, table_meta_public, manifest);
			}
			catch (SQLException e)
			{
				throw new RemoteException("Unable to initialize DataConfig", e);
			}
			
			this.lastModified = lastMod;
		}
	}

    public void flushInserts() throws RemoteException
    {
        try 
        {
        	manifest.flushInserts();
        	hierarchy.flushInserts();
            private_metadata.flushInserts();
            public_metadata.flushInserts();
        }
        catch (SQLException e)
        {
            throw new RemoteException("Failed flushing inserts.", e);
        }
    }

    public int newEntity(int type_id, DataEntityMetadata properties) throws RemoteException
    {
    	detectChange();
        int id = manifest.addEntry(type_id);
        if (properties != null)
            updateEntity(id, properties);
        return id;
    }
    private void removeChildren(int id) throws RemoteException
    {
    	detectChange();
        for (int child : hierarchy.getChildren(id))
        {
            removeEntity(child);
        }
    }
    public void removeEntity(int id) throws RemoteException
    {
    	detectChange();
        /* Need to delete all attributeColumns which are children of a table. */
        if (getEntity(id).type == DataEntity.TYPE_DATATABLE)
            removeChildren(id);
        manifest.removeEntry(id);
        hierarchy.purge(id);
        public_metadata.removeAllProperties(id);
        private_metadata.removeAllProperties(id);
    }
    public void updateEntity(int id, DataEntityMetadata diff) throws RemoteException
    {
    	detectChange();
    	public_metadata.setProperties(id, diff.publicMetadata);
    	private_metadata.setProperties(id, diff.privateMetadata);
    }
    public Collection<Integer> getEntityIdsByMetadata(DataEntityMetadata properties, int type_id) throws RemoteException
    {
    	detectChange();
        Set<Integer> publicmatches = null;
        Set<Integer> privatematches = null;
        Collection<Integer> matches = null;

        if (properties != null && properties.publicMetadata != null && properties.publicMetadata.size() > 0)
            publicmatches = public_metadata.filter(properties.publicMetadata);
        if (properties != null && properties.privateMetadata != null && properties.privateMetadata.size() > 0)
            privatematches = private_metadata.filter(properties.privateMetadata);
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
        	// filter by type
            if (type_id != NULL)
                matches.retainAll(manifest.getByType(type_id));
            return matches;
        }
    }
    public DataEntity getEntity(int id) throws RemoteException
    {
    	detectChange();
    	for (DataEntity result : getEntitiesById(Arrays.asList(id)))
    		return result;
    	return null;
    }
    public Collection<DataEntity> getEntitiesById(Collection<Integer> ids) throws RemoteException
    {
    	detectChange();
        List<DataEntity> results = new LinkedList<DataEntity>();
        Map<Integer,Integer> typeresults = manifest.getEntryTypes(ids);
        Map<Integer,Map<String,String>> publicresults = public_metadata.getProperties(ids);
        Map<Integer,Map<String,String>> privateresults = private_metadata.getProperties(ids);
        for (int id : ids)
        {
            DataEntity entity = new DataEntity();
            entity.id = id;
           	entity.type = typeresults.get(id);
            entity.publicMetadata = publicresults.get(id);
            entity.privateMetadata = privateresults.get(id);
            results.add(entity);
        }
        return results;
    }
    
    /**
     * @param parentId An existing parent to add a child hierarchy to.
     * @param childId An existing child to copy the hierarchy of.
     * @param insertBeforeId Identifies a child of the parent to insert the new child before.
     * @throws RemoteException
     */
    public void buildHierarchy(int parentId, int childId, int insertAtIndex) throws RemoteException
    {
		detectChange();
		
		int newChildId;
		DataEntity child = getEntity(childId);

		if (parentId == NULL) // parent is root
		{
			if (child.type == DataEntity.TYPE_HIERARCHY) // child is a hierarchy
			{
				// make a copy of the existing hierarchy
				newChildId = newEntity(DataEntity.TYPE_HIERARCHY, child);
			}
			else // child is not a hierarchy
			{
				// create a new blank hierarchy to contain the child
				int hierarchyId = newEntity(DataEntity.TYPE_HIERARCHY, null);
				// recursive call with new parent id
				buildHierarchy(hierarchyId, childId, 0);
				return; // done
			}
		}
		else // parent is not root
        {
			DataEntity parent = getEntity(parentId);
			
			// columns cannot be parents
			if (parent.type == DataEntity.TYPE_COLUMN)
				throw new RemoteException("Cannot add children to attribute columns.");
			
			if (child.type == DataEntity.TYPE_COLUMN) // child is a column
			{
				// columns can be added directly to new parents
				newChildId = childId;
			}
			else // child is not a column
			{
				// non-columns always copy as categories
				newChildId = newEntity(DataEntity.TYPE_CATEGORY, child);
			}
		}
		
		// important to get the child list before we add a new child!
		List<Integer> childIds = hierarchy.getChildren(childId);
		
		// recursively copy each child hierarchy element
		int order = 0;
		for (int grandChildId : childIds)
			buildHierarchy(newChildId, grandChildId, order++);
		
		// add new child to parent
		if (parentId != NULL)
			hierarchy.addChild(parentId, newChildId, insertAtIndex);
    }
    
    public void addChild(int parent_id, int child_id, int insert_at_index) throws RemoteException
    {
    	detectChange();
   		hierarchy.addChild(parent_id, child_id, insert_at_index);
    }
    public void removeChild(int parent_id, int child_id) throws RemoteException
    {
    	detectChange();
        if (manifest.getEntryType(parent_id) == DataEntity.TYPE_DATATABLE)
        {
            throw new RemoteException("Can't remove children from a datatable.", null);
        }
        hierarchy.removeChild(parent_id, child_id);
    }
    
    public Collection<Integer> getParentIds(int id) throws RemoteException
    {
    	detectChange();
    	return hierarchy.getParents(id);
    }
    
    public List<Integer> getChildIds(int id) throws RemoteException
    {
    	detectChange();
    	// if id is NULL, we want ids of all entities without parents
        if (id == NULL)
        {
        	return new Vector<Integer>(manifest.getByType(DataEntity.TYPE_HIERARCHY, DataEntity.TYPE_DATATABLE));
        }
        return hierarchy.getChildren(id);
    }
    public Collection<String> getUniquePublicValues(String property) throws RemoteException
    {
    	detectChange();
    	return new HashSet<String>(public_metadata.getProperty(property).values());
    }
    
    
    

    
    
    
    
    
    
    
    
    
    
    ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////
    
    
    
	static public class PrivateMetadata
	{
		static public final String CONNECTION = "connection"; // required to retrieve data from sql, not visible to client
		static public final String SQLSCHEMA = "sqlSchema";
		static public final String SQLTABLE = "sqlTable";
		static public final String SQLCOLUMN = "sqlColumn";
		static public final String SQLQUERY = "sqlQuery"; // required to retrieve data from sql, not visible to client
		static public final String SQLPARAMS = "sqlParams"; // only transmitted from client to server, never stored in the database
		static public final String SQLRESULT = "sqlResult"; // only transmitted from server to client, never stored in the database
		static public final String SQLTABLEPREFIX = "sqlTablePrefix"; // used for geometry column
		static public final String FILENAME = "fileName";
		static public final String KEYCOLUMN = "keyColumn";
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
		public Map<String,String> privateMetadata = new HashMap<String, String>();
		public Map<String,String> publicMetadata = new HashMap<String, String>();
		
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
	}
	
	static public class DataEntityWithChildren extends DataEntity
	{
		public int[] childIds;
		
		public DataEntityWithChildren() { }
		
		public DataEntityWithChildren(DataEntity base, int[] childIds)
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
		public int id = TYPE_ANY;
		public int type;
		
		public static final int TYPE_ANY = NULL;
        public static final int TYPE_HIERARCHY = 0;
		public static final int TYPE_DATATABLE = 1;
		public static final int TYPE_CATEGORY = 2;
		public static final int TYPE_COLUMN = 3;
        /* For cases where the config API isn't sufficient. TODO */
        public static List<DataEntity> filterEntities(Collection<DataEntity> entities, Map<String,String> params)
        {
            return filterEntities(entities, params, TYPE_ANY);
        }
        public static List<DataEntity> filterEntities(Collection<DataEntity> entities, Map<String,String> params, int manifestType)
        {
            List<DataEntity> result = new LinkedList<DataEntity>();
            for (DataEntity entity : entities)
            {
                if (manifestType != TYPE_ANY && manifestType != entity.type)
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
	}
}
