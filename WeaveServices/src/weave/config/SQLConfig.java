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
import java.util.Collection;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import org.w3c.dom.Document;

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
public class SQLConfig
		extends ISQLConfig
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
	private ISQLConfig connectionConfig = null;
	private Connection _lastConnection = null; // do not use this variable directly -- use getConnection() instead.
        
		protected AttributeValueTable public_attributes;
		protected AttributeValueTable private_attributes;
		protected ManifestTable manifest;
		protected ParentChildTable relationships;
		protected ImmortalConnection connection = null;

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
                connection = new ImmortalConnection(connectionConfig);
		initSQLTables();
	}
	private void initSQLTables() throws RemoteException, SQLException
	{
		public_attributes = new AttributeValueTable(connection, dbInfo.schema, table_meta_public);
		private_attributes = new AttributeValueTable(connection, dbInfo.schema, table_meta_private);	
		relationships = new ParentChildTable(connection, dbInfo.schema, table_tags);
		manifest = new ManifestTable(connection, dbInfo.schema, table_manifest);
		/* TODO: Figure out nice way to do this from within the classes. */	
        /*	SQLUtils.addForeignKey(conn, dbInfo.schema, table_meta_private, META_ID, table_manifest, MAN_ID);
		SQLUtils.addForeignKey(conn, dbInfo.schema, table_meta_public, META_ID, table_manifest, MAN_ID);*/
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

    public Integer addEntity(Integer type_id, DataEntityMetadata properties) throws RemoteException
    {
        Integer id = manifest.addEntry(type_id);
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
        if (getEntity(id).type == ISQLConfig.DataEntity.MAN_TYPE_DATATABLE)
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
    public Collection<DataEntity> getEntitiesByType(Integer type_id) throws RemoteException
    {
        return getEntities(manifest.getByType(type_id));
    }
    public Collection<DataEntity> findEntities(DataEntityMetadata properties, Integer type_id) throws RemoteException
    {
        Set<Integer> publicmatches = null;
        Set<Integer> privatematches = null;
        Set<Integer> matches = null;

        if (properties.publicMetadata != null && properties.publicMetadata.size() > 0)
            publicmatches = public_attributes.filter(properties.publicMetadata);
        if (properties.privateMetadata != null && properties.privateMetadata.size() > 0)
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

        if (matches == null || matches.size() < 1)
            return new LinkedList<DataEntity>(); /* return an empty list */
        else
        {
            if (type_id != -1)
                matches.retainAll(getEntitiesByType(type_id));
            return getEntities(matches);
        }
    }
    public Collection<DataEntity> getEntities(Collection<Integer> ids) throws RemoteException
    {
        List<DataEntity> results = new LinkedList<DataEntity>();
        Map<Integer,Integer> typeresults = manifest.getEntryTypes(ids);
        Map<Integer,Map<String,String>> publicresults = public_attributes.getProperties(ids);
        Map<Integer,Map<String,String>> privateresults = private_attributes.getProperties(ids);
        if (typeresults == null)
        	return results;
        for (Integer id : ids)
        {
            Integer type = typeresults.get(id);
            if (type == null)
            	continue;
            DataEntity tmp = new DataEntity();
            tmp.id = id; 
            tmp.type = type;
            tmp.publicMetadata = publicresults.get(id);
            tmp.privateMetadata = privateresults.get(id);
            results.add(tmp);
        }
        return results;
    }
    public Integer copyEntity(Integer id) throws RemoteException
    {
        /* Do a recursive copy of an entity. */
        Integer new_id;
        DataEntity old_data = getEntity(id);
        Integer new_type = old_data.type;
        // copy table as tag
        if (new_type == DataEntity.MAN_TYPE_DATATABLE)
        	new_type = DataEntity.MAN_TYPE_TAG;
        new_id = addEntity(new_type, old_data);

        Collection<Integer> old_children = getChildIds(id);
        for (Integer child_id : old_children)
        {
            if (manifest.getEntryType(child_id) != ISQLConfig.DataEntity.MAN_TYPE_COLUMN)
            {
                child_id = copyEntity(child_id);
            }
            addChild(child_id, new_id);
        }
        return new_id;
    }
    public void addChild(Integer child_id, Integer parent_id) throws RemoteException
    {
        relationships.addChild(child_id, parent_id);
    }
    public void removeChild(Integer child_id, Integer parent_id) throws RemoteException
    {
        /* If we're trying to remove a child from a datatable, throw a wobbly. */
        if (manifest.getEntryType(parent_id) == ISQLConfig.DataEntity.MAN_TYPE_DATATABLE)
        {
            throw new RemoteException("Can't remove children from a datatable.", null);
        }
        relationships.removeChild(child_id, parent_id);
    }
    public Collection<DataEntity> getChildEntities(Integer id) throws RemoteException
    {
    	return getEntities(getChildIds(id));
    }
    
    public Collection<Integer> getParentIds(Integer id) throws RemoteException
    {
    	return relationships.getParents(id);
    }
    
    public Collection<Integer> getChildIds(Integer id) throws RemoteException
    {
    	// if id is -1, we want ids of all entities without parents
        if (id == -1)
        	id = null;
        // get all children listed in the relationships table
        Collection<Integer> children_ids = relationships.getChildren(id);
        if (id == null)
        {
        	// get complete list of ids and remove the children appearing in the relationships table
            Collection<Integer> completeSet = manifest.getAll();
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
}
